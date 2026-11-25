import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/utils/own_wallets.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// An asset the recipient can be asked to pay. Modeled as a list so more
/// chains/tokens drop in later with no flow change; for now just OX on chain
/// 4489. (chainIdHex is the EIP-5792 hex form used in the WalletSendCalls.)
class RequestableAsset {
  final int chainId;
  final String chainIdHex;
  final String tokenAddress; // ERC-20 contract (hex, 0x-prefixed)
  final String symbol;
  final int decimals;

  const RequestableAsset({
    required this.chainId,
    required this.chainIdHex,
    required this.tokenAddress,
    required this.symbol,
    required this.decimals,
  });
}

/// The currently requestable assets. Add chains/tokens here later — the sheet
/// already renders a picker when there's more than one.
List<RequestableAsset> requestableAssets() {
  final ox = PublicOSBsp.publicOSTokenAddress;
  return [
    if (ox != null)
      RequestableAsset(
        chainId: 4489,
        chainIdHex: '0x1189', // 4489
        tokenAddress: ox.eip55With0x,
        symbol: 'OX',
        decimals: 18,
      ),
  ];
}

/// Called with the request details on confirm: which of the requester's own
/// wallets should receive [amountWei] of [asset]. The caller builds + sends the
/// WalletSendCalls invoice. Throw to keep the sheet open with an error.
typedef RequestSubmit = Future<void> Function(
  String payToAddress,
  BigInt amountWei,
  RequestableAsset asset,
);

Future<void> showRequestPaymentSheet({
  required BuildContext context,
  required RequestSubmit onRequest,
}) {
  // DELTA(desktop): centered glass dialog instead of a bottom sheet (the
  // standing sheets→dialogs convention; same shape as send_sheet's presenter).
  return showDialog<void>(
    context: context,
    builder: (dialogCtx) => Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: DialogWidth.m,
          maxHeight: MediaQuery.of(dialogCtx).size.height * 0.85,
        ),
        child: RequestPaymentSheet(onRequest: onRequest),
      ),
    ),
  );
}

class RequestPaymentSheet extends StatefulWidget {
  final RequestSubmit onRequest;
  const RequestPaymentSheet({super.key, required this.onRequest});

  @override
  State<RequestPaymentSheet> createState() => _RequestPaymentSheetState();
}

class _RequestPaymentSheetState extends State<RequestPaymentSheet> {
  final TextEditingController _amountController = TextEditingController();

  List<RequestableAsset> _assets = const [];
  RequestableAsset? _asset;

  // The requester's own receiving wallets — which one should be paid. The full
  // set (personal + orgs + linked/keychain), same sources as the Send sheet.
  List<OwnWallet> _wallets = const [];
  String? _payToName;
  String? _payToAddress;
  Contact? _payToContact; // avatar for the selection (orgs); null → identicon
  bool _payToIsManual = false; // selection is a manually-typed address
  bool _walletExpanded = false;
  final TextEditingController _manualController = TextEditingController();
  String? _manualError;

  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _assets = requestableAssets();
    _asset = _assets.isNotEmpty ? _assets.first : null;
    _loadWallets();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    try {
      final myAccount = AppStateNotifier.currentMyContact?.publicosAddress;
      if (myAccount == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final wallets = await loadOwnReceivingWallets(myAccount);
      // Nothing resolved → my main Safe, never my account address (OX paid to
      // an account address is stuck).
      final mainSafe =
          wallets.isEmpty ? await PublicOSSafe.getMainSafeAddress(myAccount) : null;
      if (!mounted) return;
      setState(() {
        _wallets = wallets;
        if (wallets.isNotEmpty) {
          // Default to the personal main Safe, else the first.
          final def = wallets.firstWhere(
            (w) => !w.isGroup && w.name == 'main',
            orElse: () => wallets.first,
          );
          _payToName = def.name;
          _payToAddress = def.address;
          _payToContact = def.contact;
        } else {
          // Nothing resolved: the main Safe, or no address at all (the
          // request can't be made) — never the account address.
          _payToName = 'main';
          _payToAddress = mainSafe;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _short(String a) =>
      a.length > 12 ? '${a.substring(0, 6)}…${a.substring(a.length - 4)}' : a;

  void _selectWallet(OwnWallet w) {
    setState(() {
      _payToName = w.name;
      _payToAddress = w.address;
      _payToContact = w.contact;
      _payToIsManual = false;
      _manualController.clear();
      _manualError = null;
      _walletExpanded = false;
    });
  }

  /// Manual ("any target") entry — a raw ETH address to be paid at. Validated
  /// via EthereumAddress.fromHex; a valid one becomes the selected target.
  void _onManualChanged(String v) {
    final trimmed = v.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _manualError = null;
        if (_payToIsManual) {
          _payToAddress = null;
          _payToName = null;
          _payToContact = null;
          _payToIsManual = false;
        }
      });
      return;
    }
    try {
      final addr = EthereumAddress.fromHex(trimmed);
      setState(() {
        _payToAddress = addr.eip55With0x;
        _payToName = null;
        _payToContact = null;
        _payToIsManual = true;
        _manualError = null;
      });
    } catch (_) {
      setState(() {
        _manualError = context.l10n.requestPaymentInvalidAddress;
        if (_payToIsManual) {
          _payToAddress = null;
          _payToIsManual = false;
        }
      });
    }
  }

  void _validate(String v) {
    if (v.isEmpty) {
      setState(() => _error = null);
      return;
    }
    final d = double.tryParse(v);
    if (d == null) {
      setState(() => _error = context.l10n.unifiedSendSheetInvalidAmount);
    } else if (d <= 0) {
      setState(() => _error = context.l10n.unifiedSendSheetAmountGreaterThanZero);
    } else {
      setState(() => _error = null);
    }
  }

  bool get _canSend {
    final d = double.tryParse(_amountController.text);
    return !_sending &&
        _error == null &&
        d != null &&
        d > 0 &&
        _asset != null &&
        _payToAddress != null;
  }

  /// The typed amount in the asset's smallest unit, with no rounding: digits
  /// past [decimals] are dropped. null when the text is not plain digits with
  /// at most one dot (the caller then scales the parsed number instead).
  static BigInt? _toBaseUnits(String text, int decimals) {
    final t = text.trim();
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(t) || !t.contains(RegExp(r'\d'))) {
      return null;
    }
    final parts = t.split('.');
    final whole = parts[0].isEmpty ? '0' : parts[0];
    var frac = parts.length > 1 ? parts[1] : '';
    if (frac.length > decimals) frac = frac.substring(0, decimals);
    return BigInt.parse('$whole${frac.padRight(decimals, '0')}');
  }

  Future<void> _submit() async {
    final asset = _asset;
    final payTo = _payToAddress;
    final amt = double.tryParse(_amountController.text);
    if (asset == null || payTo == null || amt == null || amt <= 0) return;

    setState(() => _sending = true);
    // Exact, from the typed digits. Scaling through a double loses the amount:
    // 1000000 * 1e18 is not a number a double can hold, and the request went out
    // as 999999.999999999983 OX.
    final amountWei = _toBaseUnits(_amountController.text, asset.decimals) ??
        BigInt.from(amt * math.pow(10, asset.decimals));
    try {
      await widget.onRequest(payTo, amountWei, asset);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.unifiedSendSheetTransactionFailed;
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceDeep,
        // DELTA(desktop): full radius — centered dialog, not bottom-docked.
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // DELTA(desktop): drag handle dropped — dialog, nothing to drag.
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child:
                            Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _header(tokens, l10n),
                          const SizedBox(height: 4),
                          _assetRow(tokens),
                          const SizedBox(height: 14),
                          Text(l10n.requestPaymentPayTo, style: _label(tokens)),
                          const SizedBox(height: 6),
                          _payToCard(tokens),
                          if (_walletExpanded) _walletList(tokens),
                          const SizedBox(height: 14),
                          Text(l10n.requestPaymentAmount, style: _label(tokens)),
                          const SizedBox(height: 6),
                          _amountField(tokens),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!,
                                style: TextStyle(
                                    color: Colors.red.shade300, fontSize: 12)),
                          ],
                          const SizedBox(height: 20),
                          SystemAppActionButton(
                            label: _sending
                                ? l10n.requestPaymentSending
                                : l10n.requestPaymentSend,
                            icon: _sending
                                ? Icons.hourglass_empty_rounded
                                : Icons.request_quote_rounded,
                            onTap: _canSend ? _submit : null,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(GlassTokens t, dynamic l10n) => Row(
        children: [
          const SizedBox(width: 40),
          Expanded(
            child: Text(
              l10n.requestPaymentTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: t.starkWhite,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: t.starkWhite),
          ),
        ],
      );

  // The asset being requested. One asset today → a fixed chip; the picker is
  // ready for when requestableAssets() returns more.
  Widget _assetRow(GlassTokens t) {
    final asset = _asset;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.toll_outlined, size: 18, color: t.connectedAccent),
          const SizedBox(width: 8),
          Text(asset?.symbol ?? '—', style: _title(t)),
          const Spacer(),
          if (_assets.length > 1)
            Icon(Icons.expand_more_rounded, size: 18, color: t.textDim),
        ],
      ),
    );
  }

  Widget _payToCard(GlassTokens t) {
    final displayName = _payToIsManual
        ? context.l10n.requestPaymentCustomLabel
        : (_payToName ?? '—');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          if (_payToAddress != null) ...[
            _payToContact != null
                ? GlassContactIcon(contact: _payToContact!, size: 32)
                : GlassContactIcon(address: _payToAddress!, size: 32),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: _title(t)),
                if (_payToAddress != null) ...[
                  const SizedBox(height: 2),
                  Text(_short(_payToAddress!), style: _smallDim(t)),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _walletExpanded = !_walletExpanded),
            child: Text(_walletExpanded
                ? context.l10n.requestPaymentDone
                : context.l10n.requestPaymentChange),
          ),
        ],
      ),
    );
  }

  Widget _walletList(GlassTokens t) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        children: [
          ..._wallets.map((w) {
            final selected = !_payToIsManual && w.address == _payToAddress;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _selectWallet(w),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: t.glassFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? t.connectedAccent : t.borderSubtle,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        w.contact != null
                            ? GlassContactIcon(contact: w.contact!, size: 30)
                            : GlassContactIcon(address: w.address, size: 30),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w.name,
                                  style: _smallStyle(t),
                                  overflow: TextOverflow.ellipsis),
                              Text(_short(w.address), style: _smallDim(t)),
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(Icons.check_circle_rounded,
                              size: 18, color: t.connectedAccent),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          // "Any target" — a manually-typed ETH address.
          _manualField(t),
        ],
      ),
    );
  }

  Widget _manualField(GlassTokens t) {
    final active = _payToIsManual;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: t.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? t.connectedAccent : t.borderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded, size: 18, color: t.textDim),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _manualController,
              onChanged: _onManualChanged,
              style: TextStyle(color: t.starkWhite, fontSize: 13),
              decoration: InputDecoration(
                hintText: context.l10n.requestPaymentCustomAddress,
                hintStyle: TextStyle(color: t.textDim, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                errorText: _manualError,
                errorStyle:
                    TextStyle(color: Colors.red.shade300, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountField(GlassTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _amountController,
              onChanged: _validate,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: TextStyle(color: t.starkWhite, fontSize: 18),
              decoration: InputDecoration(
                hintText: '0.0',
                hintStyle: TextStyle(color: t.textDim),
                border: InputBorder.none,
              ),
            ),
          ),
          Text(_asset?.symbol ?? '', style: _smallDim(t)),
        ],
      ),
    );
  }

  TextStyle _label(GlassTokens t) => TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: t.textDim,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      );
  TextStyle _title(GlassTokens t) => TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: t.starkWhite,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      );
  TextStyle _smallStyle(GlassTokens t) => TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: t.starkWhite,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      );
  TextStyle _smallDim(GlassTokens t) => TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: t.textDim,
        fontSize: 12,
      );
}
