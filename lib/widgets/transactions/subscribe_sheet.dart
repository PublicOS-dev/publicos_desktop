import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:wallet/wallet.dart' show EtherAmount;
import 'package:web3dart/web3dart.dart' show Transaction, EthPrivateKey;

import 'package:publicos_desktop/widgets/pixel_rain_loading_label.dart';
import 'package:publicos_desktop/widgets/transactions/wallet_sources.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/widgets/error/write_error_dispatcher.dart';

/// Pay for a paid channel — from the user's Safe, crediting their account.
///
/// **The money path, as the ecosystem does it.** The reader's OX lives in their
/// MainSafe, so the Safe is the payer: two transactions through
/// `PublicOSSafe.sendTransactionFromSafe` (individual → `SafeAuth.executeCall`
/// signed by the session key) — an exact-amount `approve(manager, cost)` when
/// the Safe has no allowance yet, then `subscribe(plan, beneficiary: account,
/// periods, token)`. The second is the "pay for": `beneficiary` is the PublicOS
/// account, so every device of that identity reads what was paid for once.
/// Both calls sit behind ONE Confirm, and the button says both.
///
/// **Why two calls.** `subscribe()`'s ERC-20 leg is a standard pull
/// (`safeTransferFrom(msg.sender → payout)`), which the token refuses without
/// an allowance — the only PublicOS fee that works this way, because the
/// contract is ecosystem-blind by design (same bytecode on Base). Every other
/// fee moves via `TreasuryManager.transferTokens`, which is why nothing else
/// in these apps has ever called `approve`.
///
/// **The entry dictates the chain** (the send sheet's `lockChainToken` idea):
/// the chain/token row is read-only, and PAYING FROM lists only wallets that
/// can pay on that chain — a Safe exists only on 4489 (the send sheet's
/// lost-funds guard), a keychain key can sign on any chain with an RPC. A new
/// chain arriving from the server therefore needs no client change.
///
/// Org Safes are hidden: a group spend is a vote, and two votes for one
/// subscription is the wrong shape. An org transfers to a member and the
/// member pays.
///
/// ⚠ **Same edit twice** — twin of
/// `publicos_client/lib/components/transactions/subscribe_sheet.dart`.
Future<bool> showSubscribeSheet({
  required BuildContext context,
  required ChannelAccessEntry entry,
  required String channelName,
  DateTime? lapsedAt,
}) async {
  final paid = await showGlassSheetDialog<bool>(
    context: context,
    width: DialogWidth.m,
    builder: (_) => SubscribeSheet(
      entry: entry,
      channelName: channelName,
      lapsedAt: lapsedAt,
    ),
  );
  return paid == true;
}

class SubscribeSheet extends StatefulWidget {
  final ChannelAccessEntry entry;
  final String channelName;

  /// Set when the server said `lapsed_at`: the sheet reads as a renewal.
  final DateTime? lapsedAt;

  const SubscribeSheet({
    super.key,
    required this.entry,
    required this.channelName,
    this.lapsedAt,
  });

  @override
  State<SubscribeSheet> createState() => _SubscribeSheetState();
}

class _SubscribeSheetState extends State<SubscribeSheet> {
  static const _maxPeriods = 12;

  List<Map<String, dynamic>> _sources = const [];
  Map<String, dynamic>? _selected;
  bool _loadingSources = true;

  PaidFeedPlan? _plan;
  PlanPrice? _price;
  PaidFeedQuote? _quote;
  bool _loadingQuote = true;
  bool _quoteFailed = false;

  int _periods = 1;
  bool _sending = false;

  /// "Approving… (1 of 2)" / "Sending… (2 of 2)" while the txs are in flight.
  String? _step;
  String? _error;

  int get _chainId => widget.entry.chainId;
  bool get _isOxChain => _chainId == PublicOS.CHAIN_ID;

  @override
  void initState() {
    super.initState();
    _loadSources();
    _loadPlan();
  }

  // ─────────────────────────── loading ───────────────────────────

  Future<void> _loadSources() async {
    final me = AppStateNotifier.currentMyContact?.publicosAddress;
    if (me == null) {
      if (mounted) setState(() => _loadingSources = false);
      return;
    }
    final rows = await loadWalletRows(me);
    if (!mounted) return;
    final usable = rows.where(_canPayOnThisChain).toList();
    setState(() {
      _sources = usable;
      _selected = _defaultSource(usable);
      _loadingSources = false;
    });
    _refreshQuote();
  }

  /// Org Safes never; a Safe only on 4489 (it has no contract elsewhere);
  /// a keychain key anywhere Core has an RPC for.
  bool _canPayOnThisChain(Map<String, dynamic> row) {
    if (row['isGroup'] == true) return false;
    if (row['isKeychain'] == true) {
      return PublicOSPaidFeeds.clientFor(_chainId) != null;
    }
    return _isOxChain;
  }

  Map<String, dynamic>? _defaultSource(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return null;
    final safe = rows.where((r) => r['isKeychain'] != true).firstOrNull;
    return safe ?? rows.first;
  }

  Future<void> _loadPlan() async {
    final plan = await PublicOSPaidFeeds.planFor(widget.entry);
    if (!mounted) return;
    if (plan == null || !plan.isPurchasable) {
      setState(() {
        _plan = plan;
        _loadingQuote = false;
        _quoteFailed = true;
      });
      return;
    }
    // Prefer the chain's native/OX price; the plan on 4489 is priced in the
    // OX ERC-20, so "first accepted token" is the honest default.
    setState(() {
      _plan = plan;
      _price = plan.prices.first;
    });
    _refreshQuote();
  }

  Future<void> _refreshQuote() async {
    final price = _price;
    final src = _selected;
    if (price == null || src == null) return;
    setState(() {
      _loadingQuote = true;
      _quoteFailed = false;
    });
    final q = await PublicOSPaidFeeds.quote(
      widget.entry,
      token: price.token,
      periods: _periods,
      beneficiary: PublicOSPaidFeeds.defaultBeneficiary(),
      payer: src['address'] as String,
    );
    if (!mounted) return;
    setState(() {
      _quote = q;
      _loadingQuote = false;
      _quoteFailed = q == null;
    });
  }

  // ─────────────────────────── the two transactions ───────────────────────────

  Future<void> _confirm() async {
    final q = _quote;
    final src = _selected;
    final price = _price;
    if (q == null || src == null || price == null || _sending) return;

    final beneficiary = PublicOSPaidFeeds.defaultBeneficiary();
    if (beneficiary == null) return;

    final mgr = await PublicOSPaidFeeds.managerFor(
        widget.entry.chainId, widget.entry.contract);
    if (mgr == null || !mounted) return;

    final l10n = context.l10n;
    setState(() {
      _sending = true;
      _error = null;
    });

    final total = q.needsApproval ? 2 : 1;
    var n = 0;
    try {
      final managerAddr = mgr.self.address;

      if (q.needsApproval) {
        n++;
        setState(() => _step = l10n.subscribeSheetStepApproving(n, total));
        // Encoded through the token binding's OWN abi, never a hand-kept
        // selector — same rule quote() follows for subscribe().
        final approveData = PublicOSBsp.publicOSTokenContract.self
            .function('approve')
            .encodeCall([managerAddr, q.cost]);
        final ok = await _execute(
          src,
          to: EthereumAddress.fromHex(price.token!),
          data: approveData,
          value: BigInt.zero,
        );
        if (!ok) throw Exception('approve');
      }

      n++;
      setState(() => _step = l10n.subscribeSheetStepSending(n, total));
      final subscribeData = mgr.self.function('subscribe').encodeCall([
        BigInt.from(widget.entry.feedId),
        EthereumAddress.fromHex(beneficiary),
        BigInt.from(_periods),
        EthereumAddress.fromHex(
            price.token ?? '0x0000000000000000000000000000000000000000'),
      ]);
      final ok = await _execute(
        src,
        to: managerAddr,
        data: subscribeData,
        value: price.isNative ? q.cost : BigInt.zero,
      );
      if (!ok) throw Exception('subscribe');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.subscribeSheetDone(_fmtDate(q.expiresAt))),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _step = null;
        _error = PublicOS.lastError ?? e.toString();
      });
      handleWriteError(context, e, fallbackMessage: l10n.subscribeSheetFailed);
    }
  }

  /// One call from the selected source. Safe → through SafeAuth, signed by the
  /// session key; keychain → signed by that key directly on the entry's chain.
  /// Waits for the receipt on the entry's own chain.
  Future<bool> _execute(
    Map<String, dynamic> src, {
    required EthereumAddress to,
    required Uint8List data,
    required BigInt value,
  }) async {
    String? hash;
    if (src['isKeychain'] == true) {
      final client = PublicOSPaidFeeds.clientFor(_chainId);
      if (client == null) return false;
      final key = EthPrivateKey.fromHex(src['privateKey'] as String);
      final tx = Transaction(
        from: key.address,
        to: to,
        data: data,
        value: EtherAmount.inWei(value),
        // Gas is free on 4489; elsewhere let the node price it.
        gasPrice: _isOxChain ? EtherAmount.zero() : null,
      );
      hash = await client.sendTransaction(key, tx, chainId: _chainId);
    } else {
      hash = await PublicOSSafe.sendTransactionFromSafe(
        accountAddress: src['accountAddress'] as EthereumAddress,
        safeAddress: EthereumAddress.fromHex(src['address'] as String),
        to: to.eip55With0x,
        valueWei: value,
        data: '0x${_hex(data)}',
      );
    }
    if (hash == null) return false;
    return PublicOSPaidFeeds.waitForTx(_chainId, hash,
        timeout: const Duration(seconds: 90));
  }

  static String _hex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  // ─────────────────────────── formatting ───────────────────────────

  String _fmtAmount(BigInt raw) => PublicOSWallets.formatTokenAmount(
        raw,
        _price?.meta?.decimals ?? 18,
        symbol: _price?.meta?.symbol ?? 'OX',
      );

  String _fmtDate(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
  }

  String _fmtPeriod(Duration p) {
    final days = p.inDays;
    if (days >= 1) return context.l10n.subscribeSheetPeriodDays(days);
    return context.l10n.subscribeSheetPeriodHours(p.inHours);
  }

  // ─────────────────────────── build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          borderRadius: BorderRadius.circular(24),
          border: Border(top: BorderSide(color: tokens.borderSubtle)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(tokens, l10n),
                const SizedBox(height: 18),
                _sectionLabel(tokens, l10n.subscribeSheetPayingFrom),
                const SizedBox(height: 8),
                _sourcesList(tokens, l10n),
                const SizedBox(height: 20),
                _planCard(tokens, l10n),
                const SizedBox(height: 18),
                _confirmArea(tokens, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(GlassTokens tokens, AppLocalizations l10n) {
    final renew = widget.lapsedAt != null;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                renew
                    ? l10n.subscribeSheetTitleRenew
                    : l10n.subscribeSheetTitle,
                style: TextStyle(
                  color: tokens.starkWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.channelName,
                style: TextStyle(color: tokens.textDim, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close_rounded, color: tokens.textDim),
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }

  Widget _sectionLabel(GlassTokens tokens, String text) => Text(
        text,
        style: TextStyle(
          color: tokens.textDim,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      );

  Widget _sourcesList(GlassTokens tokens, AppLocalizations l10n) {
    if (_loadingSources) {
      return const SizedBox(
        height: 64,
        child: Center(child: PixelRainLoadingLabel(size: 24)),
      );
    }
    if (_sources.isEmpty) {
      final chain = widget.entry.chainName ??
          PaidFeedChains.forId(_chainId)?.name ??
          '#$_chainId';
      return _note(tokens, l10n.subscribeSheetNoSource(chain), warn: true);
    }
    return Column(
      children: [
        for (final row in _sources) _sourceRow(tokens, row),
      ],
    );
  }

  Widget _sourceRow(GlassTokens tokens, Map<String, dynamic> row) {
    final selected = identical(row, _selected);
    final isKey = row['isKeychain'] == true;
    final label = isKey
        ? '${row['emoji']} ${row['name']}'
        : context.l10n.subscribeSheetMainSafe;
    final addr = row['address'] as String;
    final short = '${addr.substring(0, 6)}…${addr.substring(addr.length - 4)}';
    final bal = (row['balance'] as double).toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? tokens.glassFillHover : tokens.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? tokens.starkWhite : tokens.borderSubtle,
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _sending
              ? null
              : () {
                  setState(() => _selected = row);
                  _refreshQuote();
                },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: row['color'] as Color? ?? tokens.textDim,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              color: tokens.starkWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      Text(short,
                          style: TextStyle(
                              color: tokens.textDim,
                              fontSize: 11,
                              fontFamily: 'monospace')),
                    ],
                  ),
                ),
                Text('$bal OX',
                    style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _planCard(GlassTokens tokens, AppLocalizations l10n) {
    final plan = _plan;
    final price = _price;
    if (_quoteFailed && (plan == null || price == null)) {
      return _note(tokens, l10n.subscribeSheetQuoteFailed, warn: true);
    }
    if (plan == null || price == null) {
      return const SizedBox(
        height: 64,
        child: Center(child: PixelRainLoadingLabel(size: 24)),
      );
    }
    final q = _quote;
    final chain = widget.entry.chainName ??
        PaidFeedChains.forId(_chainId)?.name ??
        '#$_chainId';
    final insufficient = q != null &&
        _selected != null &&
        ((_selected!['balance'] as double) * 1e18) < q.cost.toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kv(tokens, l10n.subscribeSheetNetwork, chain),
          const SizedBox(height: 8),
          _kv(
            tokens,
            l10n.subscribeSheetPrice,
            '${_fmtAmount(price.price)} / ${_fmtPeriod(plan.period)}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _sectionLabel(tokens, l10n.subscribeSheetPeriods)),
              _stepBtn(tokens, Icons.remove_rounded,
                  _periods > 1 ? () => _setPeriods(_periods - 1) : null),
              SizedBox(
                width: 40,
                child: Text(
                  '$_periods',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: tokens.starkWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w800),
                ),
              ),
              _stepBtn(tokens, Icons.add_rounded,
                  _periods < _maxPeriods ? () => _setPeriods(_periods + 1) : null),
            ],
          ),
          const Divider(height: 22),
          if (_loadingQuote || q == null)
            const SizedBox(
              height: 40,
              child: Center(child: PixelRainLoadingLabel(size: 20)),
            )
          else ...[
            _kv(tokens, l10n.subscribeSheetTotal, _fmtAmount(q.cost),
                strong: true),
            const SizedBox(height: 6),
            _kv(tokens, l10n.subscribeSheetAccessUntil, _fmtDate(q.expiresAt)),
            if (widget.lapsedAt != null) ...[
              const SizedBox(height: 6),
              _kv(tokens, l10n.subscribeSheetLapsedOn,
                  _fmtDate(widget.lapsedAt!)),
            ],
            if (q.needsApproval) ...[
              const SizedBox(height: 12),
              _note(tokens, l10n.subscribeSheetApproveNote),
            ],
            if (insufficient) ...[
              const SizedBox(height: 12),
              _note(
                tokens,
                l10n.subscribeSheetInsufficient(
                    _price?.meta?.symbol ?? 'OX'),
                warn: true,
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _setPeriods(int n) {
    setState(() => _periods = n.clamp(1, _maxPeriods));
    _refreshQuote();
  }

  Widget _stepBtn(GlassTokens tokens, IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _sending ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: onTap == null ? 0.03 : 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              color: onTap == null ? tokens.textDim : tokens.starkWhite,
              size: 18),
        ),
      ),
    );
  }

  Widget _kv(GlassTokens tokens, String k, String v, {bool strong = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(k,
              style: TextStyle(color: tokens.textDim, fontSize: 12)),
        ),
        Text(
          v,
          style: TextStyle(
            color: tokens.starkWhite,
            fontSize: strong ? 16 : 13,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _note(GlassTokens tokens, String text, {bool warn = false}) {
    final c = warn ? Colors.orangeAccent : tokens.connectedAccent;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: c, height: 1.4)),
    );
  }

  Widget _confirmArea(GlassTokens tokens, AppLocalizations l10n) {
    final q = _quote;
    if (_sending) {
      return Column(
        children: [
          const PixelRainLoadingLabel(size: 28),
          const SizedBox(height: 8),
          Text(_step ?? '',
              style: TextStyle(color: tokens.textDim, fontSize: 12)),
        ],
      );
    }
    final insufficient = q != null &&
        _selected != null &&
        ((_selected!['balance'] as double) * 1e18) < q.cost.toDouble();
    final canSend = q != null &&
        _selected != null &&
        !_loadingQuote &&
        !_quoteFailed &&
        !insufficient;
    final label = q == null
        ? l10n.subscribeSheetConfirmSend('…')
        : (q.needsApproval
            ? l10n.subscribeSheetConfirmApproveAndSend(_fmtAmount(q.cost))
            : l10n.subscribeSheetConfirmSend(_fmtAmount(q.cost)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.fallbackAccent, fontSize: 11)),
          const SizedBox(height: 10),
        ],
        Material(
          color: canSend ? tokens.starkWhite : tokens.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: tokens.borderMedium),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: canSend ? _confirm : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium_rounded,
                      size: 16,
                      color: canSend ? tokens.background : tokens.textDim),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: canSend ? tokens.background : tokens.textDim,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
