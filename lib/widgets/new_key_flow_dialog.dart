import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/account_resolve_field.dart';
import 'package:publicos_desktop/widgets/key_lifetime_line.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/protocol_agreement_dialog.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// What the new key is for: joining an existing account, or a new account.
enum NewKeyIntent { addDevice, newAccount }

/// Port of publicos_client's `components/new_key_flow_dialog.dart`. Same
/// flow, same Core calls, same strings; the only desktop deltas are the
/// protocol agreement as a dialog (`showProtocolAgreementDialog`, the desktop
/// shell of the client's sheet) and the words step,
/// [showRecoveryWordsDialog] below, standing in for the client's
/// `showSecretRevealDialog`.
///
/// The select-account screen's new-key flow:
/// intent first, then the inputs, then the recovery words, then the signed
/// claim. Returns the temp key's address once the claim is signed and saved
/// (the caller opens the QR straight away), or null when the user backed out.
///
/// Nothing stays on the device unless the flow reaches the signed claim: the
/// key is generated only after the inputs are confirmed, and any failure
/// before the claim is saved deletes it again.
Future<String?> showNewKeyFlowDialog(
  BuildContext context, {
  required NewKeyIntent intent,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _NewKeyFlowDialog(intent: intent),
  );
}

class _NewKeyFlowDialog extends StatefulWidget {
  final NewKeyIntent intent;
  const _NewKeyFlowDialog({required this.intent});

  @override
  State<_NewKeyFlowDialog> createState() => _NewKeyFlowDialogState();
}

class _NewKeyFlowDialogState extends State<_NewKeyFlowDialog> {
  final _input = TextEditingController();
  Timer? _debounce;
  String? _error;
  bool _busy = false;

  // Add device: the account the input resolves to, and its contact (if known).
  String? _resolvedAccount;
  Contact? _resolvedContact;
  bool _resolving = false;
  bool _notFound = false;
  int _ttlSeconds = 0; // 0 = permanent

  // New account: naming rules + availability.
  NameTierLimits? _limits;
  bool? _available; // null = not checked yet
  bool _checking = false;

  bool get _isAdd => widget.intent == NewKeyIntent.addDevice;

  @override
  void initState() {
    super.initState();
    if (!_isAdd) {
      PublicOSAccounts.getNameTierLimits().then((l) {
        if (mounted) setState(() => _limits = l);
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  int get _minLen => _limits?.minPrivate ?? 8;
  int get _maxLen => _limits?.maxChars ?? 32;

  void _onChanged(String _) {
    _debounce?.cancel();
    setState(() {
      _error = null;
      if (_isAdd) {
        _resolvedAccount = null;
        _resolvedContact = null;
        _notFound = false;
      } else {
        _available = null;
      }
    });
    final v = _input.text.trim();
    if (v.isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_isAdd) {
        _resolve(v);
      } else if (_rulesOk(v)) {
        _checkAvailable(v);
      }
    });
  }

  Future<void> _resolve(String v) async {
    setState(() => _resolving = true);
    String? addr;
    if (v.startsWith('0x')) {
      try {
        addr = EthereumAddress.fromHex(v).eip55With0x;
      } catch (_) {
        addr = null;
      }
    } else {
      addr = await resolveAccountInput(v);
    }
    Contact? contact;
    if (addr != null) {
      try {
        contact = await PublicOSContacts.fetchContact(EthereumAddress.fromHex(addr));
      } catch (_) {}
    }
    if (!mounted || _input.text.trim() != v) return;
    setState(() {
      _resolving = false;
      _resolvedAccount = addr;
      _resolvedContact = contact;
      _notFound = addr == null;
    });
  }

  Future<void> _checkAvailable(String v) async {
    setState(() => _checking = true);
    bool? free;
    try {
      // The contract's own verdict, which also reads the reserved and cooldown
      // list. Only 0 is free here: creating an account never evicts a holder.
      final status = await PublicOSAccounts.getNameClaimStatus(
        v,
        account: EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'),
      );
      free = status == 0;
    } catch (_) {
      free = null; // unknown: don't block, the sponsor's tx is the final check
    }
    if (!mounted || _input.text.trim() != v) return;
    setState(() {
      _checking = false;
      _available = free;
    });
  }

  // --- naming rules, one line each (mirrors Core's DisplayNameValidator) ---
  static bool _alpha(int c) => (c >= 0x61 && c <= 0x7A) || (c >= 0x41 && c <= 0x5A);
  static bool _alnum(int c) => _alpha(c) || (c >= 0x30 && c <= 0x39);
  static bool _allowed(int c) => _alnum(c) || c == 0x2D || c == 0x5F;

  bool _ruleLength(String v) => v.length >= _minLen && v.length <= _maxLen;
  bool _ruleStart(String v) => v.isNotEmpty && _alpha(v.codeUnitAt(0));
  bool _ruleEnd(String v) => v.isNotEmpty && _alnum(v.codeUnitAt(v.length - 1));
  bool _ruleChars(String v) => v.isNotEmpty && v.codeUnits.every(_allowed);
  bool _ruleDoubles(String v) => v.isNotEmpty && !v.contains('--') && !v.contains('__');

  bool _rulesOk(String v) =>
      DisplayNameValidator.validate(v, minLength: _minLen, maxLength: _maxLen).ok;

  bool get _canContinue {
    if (_busy) return false;
    final v = _input.text.trim();
    if (_isAdd) return _resolvedAccount != null && !_resolving;
    return _rulesOk(v) && _available != false && !_checking;
  }

  /// Inputs confirmed: make the key, show the words, sign the claim. The key
  /// is deleted again if anything fails before the claim is saved.
  Future<void> _continue() async {
    if (!_canContinue) return;
    final l10n = context.l10n;
    final v = _input.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    // NEW ACCOUNT only: the account accepts the protocol agreement when it is
    // made (the consent carries the current version), so show it first and
    // make nothing if the user doesn't accept. ADD THIS DEVICE shows nothing:
    // that account accepted it at creation.
    if (!_isAdd) {
      final ({BigInt version, String text})? agreement;
      try {
        agreement =
            await PublicOSAgreements.currentText(PublicOSAgreements.kindProtocol);
      } catch (e) {
        Log.e('NewKeyFlow', 'Protocol agreement load failed: $e');
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = l10n.protocolAgreementLoadFailed;
        });
        return;
      }
      // No version published: the contract treats that as accepted.
      if (agreement != null) {
        if (!mounted) return;
        final accepted =
            await showProtocolAgreementDialog(context, agreement: agreement);
        if (!accepted) {
          if (mounted) setState(() => _busy = false);
          return;
        }
      }
    }
    var keyMade = false;
    try {
      final keyData = await PublicOSKeychain.generateTemporaryBlockchainKey();
      keyMade = true;
      await PublicOSKeychain.loadTemporaryBlockchainKey();
      final mnemonic = keyData['mnemonic'] as String;
      final address = keyData['address'] as String;
      if (!mounted) throw StateError('closed');
      await showRecoveryWordsDialog(
        context,
        title: l10n.selectAccountScreenRecoveryPhraseTitle,
        warning: l10n.newKeyFlowWordsWarning,
        mnemonic: mnemonic,
      );
      if (_isAdd) {
        await PublicOSAccounts.signTemporaryLinkClaim(
          kind: ConsentKind.addSession,
          account: EthereumAddress.fromHex(_resolvedAccount!),
          ttlSeconds: _ttlSeconds,
        );
      } else {
        await PublicOSAccounts.signTemporaryLinkClaim(
          kind: ConsentKind.newAccount,
          displayName: v,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(address);
    } catch (e) {
      if (keyMade) {
        try {
          await PublicOSAccounts.deleteTemporarySession();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = localizedError(l10n, e, fallback: l10n.linkDeviceDialogSignFailed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
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
              constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Icon(_isAdd ? Icons.devices_rounded : Icons.person_add_alt_1_rounded,
                          color: tokens.starkWhite, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isAdd ? l10n.newKeyFlowAddDeviceTitle : l10n.newKeyFlowNewAccountTitle,
                          style: TextStyle(
                              color: tokens.starkWhite, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      _isAdd ? l10n.newKeyFlowAddDeviceSubtitle : l10n.newKeyFlowNewAccountSubtitle,
                      style: TextStyle(color: tokens.textDim, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    _field(tokens),
                    const SizedBox(height: 12),
                    if (_isAdd) ..._addDeviceExtras(tokens) else ..._rules(tokens),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: TextStyle(color: tokens.softDanger, fontSize: 12)),
                    ],
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: tokens.starkWhite,
                            side: BorderSide(color: tokens.borderSubtle),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _busy ? null : () => Navigator.of(context).pop(),
                          child: Text(l10n.newKeyFlowCancel,
                              style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tokens.starkWhite,
                            foregroundColor: tokens.background,
                            disabledBackgroundColor: tokens.starkWhite.withValues(alpha: 0.25),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _canContinue ? _continue : null,
                          child: _busy
                              ? SizedBox(
                                  height: 18,
                                  child: Center(
                                    child: PhigitalLoadingWidget(
                                        size: 16, showShadows: false, color: tokens.background),
                                  ),
                                )
                              : Text(l10n.newKeyFlowContinue,
                                  style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(GlassTokens tokens) {
    final l10n = context.l10n;
    OutlineInputBorder b(Color c) =>
        OutlineInputBorder(borderSide: BorderSide(color: c), borderRadius: BorderRadius.circular(12));
    return TextField(
      controller: _input,
      enabled: !_busy,
      autofocus: true,
      autocorrect: false,
      style: TextStyle(color: tokens.starkWhite, fontSize: 14),
      onChanged: _onChanged,
      decoration: InputDecoration(
        labelText: _isAdd ? l10n.newKeyFlowAccountLabel : l10n.linkDeviceDialogLabelUsername,
        hintText: _isAdd ? null : l10n.linkDeviceDialogHintUsername,
        labelStyle: TextStyle(color: tokens.textDim),
        hintStyle: TextStyle(color: tokens.textDim),
        filled: true,
        fillColor: tokens.glassFillHover,
        border: b(tokens.borderSubtle),
        enabledBorder: b(tokens.borderSubtle),
        focusedBorder: b(tokens.starkWhite),
        suffixIcon: (_resolving || _checking)
            ? Padding(
                padding: const EdgeInsets.all(14),
                child: PhigitalLoadingWidget(size: 14, showShadows: false, color: tokens.textDim),
              )
            : null,
      ),
    );
  }

  List<Widget> _addDeviceExtras(GlassTokens tokens) {
    final l10n = context.l10n;
    final out = <Widget>[];
    if (_notFound) {
      out.add(Text(l10n.newKeyFlowAccountNotFound,
          style: TextStyle(color: tokens.fallbackAccent, fontSize: 12)));
    } else if (_resolvedAccount != null) {
      final name = _resolvedContact?.publicosDisplayName ?? _resolvedContact?.displayName;
      out.add(Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.glassFillHover,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.connectedAccent.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Icon(Icons.check_circle_rounded, color: tokens.connectedAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.newKeyFlowIsThisYou,
                  style: TextStyle(color: tokens.textDim, fontSize: 11)),
              if (name != null && name.isNotEmpty)
                Text(name,
                    style: TextStyle(
                        color: tokens.starkWhite, fontSize: 15, fontWeight: FontWeight.w800)),
              Text(_resolvedAccount!,
                  style: TextStyle(color: tokens.textDim, fontSize: 10, fontFamily: 'monospace')),
            ]),
          ),
        ]),
      ));
    }
    out.add(const SizedBox(height: 14));
    out.add(Text(l10n.keyLifetimeTitle,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: tokens.textDim)));
    out.add(const SizedBox(height: 6));
    out.add(Wrap(spacing: 6, runSpacing: 6, children: [
      for (final s in kKeyLifetimeChoices)
        GestureDetector(
          onTap: _busy ? null : () => setState(() => _ttlSeconds = s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _ttlSeconds == s ? tokens.starkWhite.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _ttlSeconds == s ? tokens.starkWhite : tokens.borderSubtle),
            ),
            child: Text(formatKeyLifetime(l10n, s),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _ttlSeconds == s ? tokens.starkWhite : tokens.textDim)),
          ),
        ),
    ]));
    out.add(const SizedBox(height: 6));
    out.add(Text(
        _ttlSeconds == 0 ? l10n.keyLifetimePermanentHint : l10n.keyLifetimeExpiringHint,
        style: TextStyle(fontSize: 11, height: 1.4, color: tokens.textDim)));
    return out;
  }

  List<Widget> _rules(GlassTokens tokens) {
    final l10n = context.l10n;
    final v = _input.text.trim();
    Widget row(bool? ok, String label) {
      final color = ok == null
          ? tokens.textDim
          : ok
              ? tokens.connectedAccent
              : tokens.softDanger;
      final icon = ok == null
          ? Icons.radio_button_unchecked_rounded
          : ok
              ? Icons.check_circle_rounded
              : Icons.cancel_rounded;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 12))),
        ]),
      );
    }

    final empty = v.isEmpty;
    bool? r(bool Function(String) f) => empty ? null : f(v);
    return [
      row(r(_ruleLength), l10n.newKeyFlowRuleLength(_minLen, _maxLen)),
      row(r(_ruleStart), l10n.newKeyFlowRuleStart),
      row(r(_ruleEnd), l10n.newKeyFlowRuleEnd),
      row(r(_ruleChars), l10n.newKeyFlowRuleChars),
      row(r(_ruleDoubles), l10n.newKeyFlowRuleNoDoubles),
      row(empty || !_rulesOk(v) ? null : _available, l10n.newKeyFlowRuleAvailable),
      const SizedBox(height: 8),
      Text(l10n.newKeyFlowFreeNote,
          style: TextStyle(color: tokens.textDim, fontSize: 11, height: 1.4)),
    ];
  }
}

/// The twelve recovery words, shown once before the claim is signed. This is
/// desktop's words dialog, with the client's title + warning as parameters.
Future<void> showRecoveryWordsDialog(
  BuildContext context, {
  required String title,
  required String warning,
  required String mnemonic,
}) async {
  final tokens = GlassTokens.of(context);
  final words = mnemonic.split(' ');
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      backgroundColor: tokens.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: DialogWidth.m),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: tokens.fallbackAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        // Warning tier: icon + title both fallbackAccent.
                        color: tokens.fallbackAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                warning,
                style: TextStyle(color: tokens.textDim, fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < words.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.glassFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tokens.borderSubtle),
                      ),
                      child: Text(
                        '${i + 1}. ${words[i]}',
                        style: TextStyle(
                          color: tokens.starkWhite,
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: mnemonic));
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        SnackBar(
                          content: Text(
                            context.l10n.desktopRecoveryPhraseCopied,
                            style: TextStyle(color: tokens.starkWhite),
                          ),
                          backgroundColor: tokens.surfaceElevated,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: tokens.textDim,
                    ),
                    label: Text(
                      context.l10n.walletActionCopy,
                      style: TextStyle(color: tokens.textDim),
                    ),
                  ),
                  const Spacer(),
                  // DONE — the white emphasis pill rescued from mobile's
                  // showSecretRevealDialog (_DialogActions).
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.starkWhite,
                      foregroundColor: tokens.background,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      context.l10n.onbDone,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
