import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:publicos_desktop/widgets/key_lifetime_line.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/protocol_agreement_dialog.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Three-state Link Device dialog (the new-device side of the
/// client_consent_signatures cross-device flow).
///
/// State 1 (Pre-sign): toggle (New account ↔ Add session) + input field
///   (username | sponsor account address) + "Sign" primary.
/// State 2 (Signed, counting): QR renders the `publicos://...` deep link
///   carrying the signed consent; toggle disabled; countdown shown.
/// State 3 (Expired): QR re-blurred; primary flips to "Refresh" which
///   re-signs with a new deadline.
///
/// This widget is pure UI. All key handling, EIP-712 signing, and claim
/// persistence live in Core (`PublicOSAccounts.signTemporaryLinkClaim` /
/// `loadTemporaryLinkClaim`) so the same flow works for any client
/// (publicos_client, publicos_desktop). The dialog only renders the QR +
/// countdown and wraps the `publicos-claim:` message in a `publicos://`
/// deep link for OS-level dispatch.
Future<void> showLinkDeviceDialog(
  BuildContext context, {
  required String tempAddress,
}) async {
  // Load any saved claim BEFORE showing so the dialog opens straight into
  // its final state (pre-sign vs QR + countdown) — no empty→QR jump.
  LinkDeviceClaim? saved;
  Object? loadErr;
  try {
    saved = await PublicOSAccounts.loadTemporaryLinkClaim();
  } catch (e) {
    loadErr = e;
  }

  if (!context.mounted) return;
  final loadError = loadErr == null
      ? null
      : localizedError(context.l10n, loadErr,
          fallback: context.l10n.linkDeviceDialogLoadFailed);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _LinkDeviceDialog(
      tempAddress: tempAddress,
      saved: saved,
      loadError: loadError,
    ),
  );
}

class _LinkDeviceDialog extends StatefulWidget {
  final String tempAddress;
  final LinkDeviceClaim? saved;
  final String? loadError;
  const _LinkDeviceDialog({
    required this.tempAddress,
    required this.saved,
    required this.loadError,
  });

  @override
  State<_LinkDeviceDialog> createState() => _LinkDeviceDialogState();
}

enum _LinkVariant { newAccount, addSession }

class _LinkDeviceDialogState extends State<_LinkDeviceDialog> {
  _LinkVariant _variant = _LinkVariant.newAccount;
  final TextEditingController _inputController = TextEditingController();

  String? _loadError;

  // State machine
  bool _isSigning = false;
  LinkDeviceClaim? _signedClaim; // populated in State 2/3
  /// Key lifetime in seconds for an add-to-account claim; 0 = permanent.
  int _ttlSeconds = 0;
  Timer? _ticker;
  int _remainingSec = 0;

  // Validator state for the new-account variant (UI-only — display + enable).
  NameValidationResult? _nameValidation;
  NameTierLimits? _tierLimits;

  // 1 hour matches the publicos_client UX default.
  static const Duration _signValidity = Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    _loadError = widget.loadError;
    final saved = widget.saved;
    if (saved != null) {
      _variant = saved.kind == ConsentKind.addSession
          ? _LinkVariant.addSession
          : _LinkVariant.newAccount;
      _inputController.text = saved.input;
      _signedClaim = saved;
      _ttlSeconds = saved.ttlSeconds;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _remainingSec = (saved.deadline.toInt() - now).clamp(0, 1 << 30);
      if (_remainingSec > 0) _startTicker();
    }
    _loadTierLimits();
  }

  Future<void> _loadTierLimits() async {
    try {
      final limits = await PublicOSAccounts.getNameTierLimits();
      if (mounted) setState(() => _tierLimits = limits);
    } catch (_) {/* preview validation tolerates this */}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  bool get _inputValid {
    final v = _inputController.text.trim();
    if (v.isEmpty) return false;
    if (_variant == _LinkVariant.newAccount) {
      final minLen = _tierLimits?.minPrivate ?? 8;
      final maxLen = _tierLimits?.maxChars ?? 32;
      return DisplayNameValidator.validate(v,
              minLength: minLen, maxLength: maxLen)
          .ok;
    } else {
      // Sponsor account address: 0x + 40 hex chars.
      if (!v.startsWith('0x') || v.length != 42) return false;
      try {
        EthereumAddress.fromHex(v);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  void _onInputChanged(String value) {
    if (_variant == _LinkVariant.newAccount) {
      final minLen = _tierLimits?.minPrivate ?? 8;
      final maxLen = _tierLimits?.maxChars ?? 32;
      setState(() {
        _nameValidation = DisplayNameValidator.validate(
          value.trim(),
          minLength: minLen,
          maxLength: maxLen,
        );
      });
    } else {
      setState(() {});
    }
  }

  void _onToggle(_LinkVariant next) {
    if (_signedClaim != null) return; // locked once signed
    setState(() {
      _variant = next;
      _inputController.clear();
      _nameValidation = null;
    });
  }

  /// Build the QR payload: wrap Core's `publicos-claim:` consent message in a
  /// `publicos://<route>/…` deep link so the sponsor's OS dispatches it into
  /// the app. The deep-link scheme/route is the one client-side concern.
  String _qrPayload(LinkDeviceClaim c) {
    final route =
        c.kind == ConsentKind.addSession ? 'add_session' : 'new_account';
    return 'publicos://$route/${Uri.encodeComponent(c.consentUri)}';
  }

  Future<void> _sign() async {
    if (!_inputValid) return;
    final l10n = context.l10n;
    // NEW ACCOUNT only: the account accepts the protocol agreement when it is
    // made (the consent carries the current version), so show it before
    // signing; nothing is signed if the user doesn't accept. Adding a session
    // shows nothing: that account accepted it at creation.
    if (_variant == _LinkVariant.newAccount) {
      final ({BigInt version, String text})? agreement;
      try {
        agreement =
            await PublicOSAgreements.currentText(PublicOSAgreements.kindProtocol);
      } catch (e) {
        Log.e('LinkDevice', 'Protocol agreement load failed: $e');
        if (!mounted) return;
        setState(() => _loadError = l10n.protocolAgreementLoadFailed);
        return;
      }
      // No version published: the contract treats that as accepted.
      if (agreement != null) {
        if (!mounted) return;
        final accepted =
            await showProtocolAgreementDialog(context, agreement: agreement);
        if (!accepted || !mounted) return;
      }
    }
    setState(() => _isSigning = true);
    final input = _inputController.text.trim();
    try {
      final claim = _variant == _LinkVariant.newAccount
          ? await PublicOSAccounts.signTemporaryLinkClaim(
              kind: ConsentKind.newAccount,
              displayName: input,
              validFor: _signValidity,
            )
          : await PublicOSAccounts.signTemporaryLinkClaim(
              kind: ConsentKind.addSession,
              account: EthereumAddress.fromHex(input),
              validFor: _signValidity,
              ttlSeconds: _ttlSeconds,
            );
      if (!mounted) return;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      setState(() {
        _signedClaim = claim;
        _remainingSec = (claim.deadline.toInt() - now).clamp(0, 1 << 30);
        _isSigning = false;
      });
      _startTicker();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSigning = false;
        _loadError = localizedError(l10n, e,
            fallback: l10n.linkDeviceDialogSignFailed);
      });
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final d = _signedClaim?.deadline.toInt() ?? now;
      setState(() => _remainingSec = (d - now).clamp(0, 1 << 30));
      if (_remainingSec <= 0) _ticker?.cancel();
    });
  }

  void _refresh() {
    _ticker?.cancel();
    setState(() {
      _signedClaim = null;
      _remainingSec = 0;
    });
    _sign();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
                    color: tokens.surfaceDeep,
                    borderRadius: BorderRadius.circular(16),
                  ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: DialogWidth.s),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(tokens),
                  const SizedBox(height: 18),
                  if (_loadError != null) _errorPill(tokens, _loadError!),
                  if (_loadError != null) const SizedBox(height: 12),
                  _toggle(tokens),
                  const SizedBox(height: 14),
                  _inputField(tokens),
                  if (_variant == _LinkVariant.addSession) ...[
                    const SizedBox(height: 14),
                    _lifetimePicker(tokens),
                  ],
                  const SizedBox(height: 18),
                  _qrArea(tokens),
                  const SizedBox(height: 18),
                  _tempAddressChip(tokens),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: _closeButton(tokens)),
                      const SizedBox(width: 12),
                      Expanded(child: _primaryButton(tokens)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(GlassTokens tokens) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2, color: tokens.starkWhite, size: 22),
            const SizedBox(width: 10),
            Text(
              context.l10n.linkDeviceDialogTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: tokens.starkWhite,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _variant == _LinkVariant.newAccount
              ? context.l10n.linkDeviceDialogSubtitleNewAccount
              : context.l10n.linkDeviceDialogSubtitleAddSession,
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.textDim, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  Widget _toggle(GlassTokens tokens) {
    final locked = _signedClaim != null;
    Widget seg({required _LinkVariant v, required String label}) {
      final active = _variant == v;
      return Expanded(
        child: GestureDetector(
          onTap: locked ? null : () => _onToggle(v),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? tokens.starkWhite.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: locked
                    ? tokens.textDim.withValues(alpha: 0.5)
                    : (active ? tokens.starkWhite : tokens.textDim),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          seg(
              v: _LinkVariant.newAccount,
              label: context.l10n.linkDeviceDialogToggleNewAccount),
          seg(
              v: _LinkVariant.addSession,
              label: context.l10n.linkDeviceDialogToggleAddSession),
        ],
      ),
    );
  }

  /// Key lifetime: how long the key this device
  /// adds to the account lasts. Signed into the consent, so it locks with the
  /// QR; the sponsor sees it before approving. A new account's first key is
  /// always permanent, so this shows only on "add to my account".
  Widget _lifetimePicker(GlassTokens tokens) {
    final l10n = context.l10n;
    final locked = _signedClaim != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.keyLifetimeTitle,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: tokens.textDim,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in kKeyLifetimeChoices)
              GestureDetector(
                onTap: locked ? null : () => setState(() => _ttlSeconds = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _ttlSeconds == s
                        ? tokens.starkWhite.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _ttlSeconds == s ? tokens.starkWhite : tokens.borderSubtle,
                    ),
                  ),
                  child: Text(
                    formatKeyLifetime(l10n, s),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: locked && _ttlSeconds != s
                          ? tokens.textDim.withValues(alpha: 0.5)
                          : (_ttlSeconds == s ? tokens.starkWhite : tokens.textDim),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _ttlSeconds == 0 ? l10n.keyLifetimePermanentHint : l10n.keyLifetimeExpiringHint,
          style: TextStyle(fontSize: 11, height: 1.4, color: tokens.textDim),
        ),
      ],
    );
  }

  Widget _inputField(GlassTokens tokens) {
    final locked = _signedClaim != null;
    final isNewAccount = _variant == _LinkVariant.newAccount;
    final minLen = _tierLimits?.minPrivate ?? 8;
    final maxLen = _tierLimits?.maxChars ?? 32;
    String? error;
    if (isNewAccount && _nameValidation != null && !_nameValidation!.ok) {
      switch (_nameValidation!.reason!) {
        case NameValidationError.empty:
          error = null;
          break;
        case NameValidationError.tooShort:
          error = context.l10n.linkDeviceDialogErrMinChars(minLen);
          break;
        case NameValidationError.tooLong:
          error = context.l10n.linkDeviceDialogErrMaxChars(maxLen);
          break;
        case NameValidationError.leadingNonAlpha:
          error = context.l10n.linkDeviceDialogErrLeadingNonAlpha;
          break;
        case NameValidationError.trailingNonAlphanumeric:
          error = context.l10n.linkDeviceDialogErrTrailing;
          break;
        case NameValidationError.illegalChar:
          error = context.l10n.linkDeviceDialogErrIllegalChar;
          break;
        case NameValidationError.consecutiveDash:
          error = context.l10n.linkDeviceDialogErrConsecutiveDash;
          break;
        case NameValidationError.consecutiveUnderscore:
          error = context.l10n.linkDeviceDialogErrConsecutiveUnderscore;
          break;
      }
    }
    return TextField(
      controller: _inputController,
      enabled: !locked,
      style: TextStyle(
        color: tokens.starkWhite,
        fontFamily: isNewAccount ? null : 'monospace',
        fontSize: isNewAccount ? 14 : 12,
      ),
      onChanged: _onInputChanged,
      decoration: InputDecoration(
        labelText: isNewAccount
            ? context.l10n.linkDeviceDialogLabelUsername
            : context.l10n.linkDeviceDialogLabelAccountAddress,
        hintText: isNewAccount
            ? context.l10n.linkDeviceDialogHintUsername
            : '0x…',
        errorText: error,
        labelStyle: TextStyle(color: tokens.textDim),
        hintStyle: TextStyle(color: tokens.textDim),
        filled: true,
        fillColor: tokens.glassFillHover,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: tokens.borderSubtle),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tokens.borderSubtle),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tokens.starkWhite),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _qrArea(GlassTokens tokens) {
    final claim = _signedClaim;
    final expired = claim != null && _remainingSec <= 0;
    final showQr = claim != null && !expired;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: tokens.starkWhite.withValues(alpha: showQr ? 0.10 : 0.04),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SizedBox(
          width: 180,
          height: 180,
          child: showQr
              ? QrImageView(
                  data: _qrPayload(claim),
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.transparent,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: tokens.starkWhite,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: tokens.starkWhite,
                  ),
                )
              : _blurredPlaceholder(tokens, expired: expired),
        ),
      ),
    );
  }

  Widget _blurredPlaceholder(GlassTokens tokens, {required bool expired}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Decorative grid (purely visual — never decodes to anything).
        Opacity(
          opacity: 0.18,
          child: GridView.count(
            crossAxisCount: 11,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            children: List.generate(
              121,
              (i) => Container(
                color: i % 3 == 0 ? tokens.starkWhite : Colors.transparent,
              ),
            ),
          ),
        ),
        Icon(
          expired ? Icons.timer_off_rounded : Icons.lock_outline_rounded,
          color: expired
              ? tokens.fallbackAccent
              : tokens.textDim.withValues(alpha: 0.6),
          size: 28,
        ),
      ],
    );
  }

  Widget _tempAddressChip(GlassTokens tokens) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: widget.tempAddress));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.linkDeviceDialogAddressCopied),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.tempAddress,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: tokens.textDim,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.copy, size: 12, color: tokens.textDim),
          ],
        ),
      ),
    );
  }

  Widget _closeButton(GlassTokens tokens) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.starkWhite,
        side: BorderSide(color: tokens.borderMedium),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => Navigator.of(context).pop(),
      child: Text(
        context.l10n.linkDeviceDialogClose,
        style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2),
      ),
    );
  }

  Widget _primaryButton(GlassTokens tokens) {
    final expired = _signedClaim != null && _remainingSec <= 0;
    final counting = _signedClaim != null && !expired;

    if (_isSigning) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.starkWhite,
          foregroundColor: tokens.background,
          disabledBackgroundColor: tokens.starkWhite,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Always laid out (invisible while signing) so the button keeps
            // the label's height — the loader's larger footprint doesn't grow
            // it past the resting button size.
            Opacity(
              opacity: 0,
              child: Text(
                context.l10n.linkDeviceDialogSign,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, letterSpacing: 2),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: PhigitalLoadingWidget(
                    size: 16,
                    showShadows: false,
                    color: tokens.background,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (counting) {
      final mins = (_remainingSec ~/ 60).clamp(0, 9999);
      final secs = (_remainingSec % 60).clamp(0, 59);
      final stale = _remainingSec <= 60;
      final color = stale ? tokens.fallbackAccent : tokens.connectedAccent;
      // Same button shape/place as the sign/signing states (disabled, tinted
      // to keep the amber/green expiry signal) so the timer doesn't jump.
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: color.withValues(alpha: 0.1),
          disabledForegroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule_rounded, color: color, size: 16),
            const SizedBox(width: 8),
            // "QR expires in mm:ss". Half the dialog's
            // width, so it shrinks rather than overflows on a narrow phone.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.l10n.linkDeviceDialogQrExpiresIn(
                      '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'),
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (expired) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.fallbackAccent,
          foregroundColor: tokens.background,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _refresh,
        child: Text(
          context.l10n.linkDeviceDialogRefresh,
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: tokens.starkWhite,
        foregroundColor: tokens.background,
        disabledBackgroundColor: tokens.starkWhite.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _inputValid ? _sign : null,
      child: Text(
        context.l10n.linkDeviceDialogSign,
        style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2),
      ),
    );
  }

  Widget _errorPill(GlassTokens tokens, String message) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '> $message',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: errorColor,
        ),
      ),
    );
  }
}
