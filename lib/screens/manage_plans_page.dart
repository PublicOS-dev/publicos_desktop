import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// Owner-side management of a channel's paid PLANS.
///
/// **Tier 1 port from publicos_client** (`lib/pages/manage_plans_page.dart`) —
/// imports repointed, body byte-identical. It costs zero re-shell because the
/// page is already hosted on a nested navigator: desktop reaches it through
/// `create_channel_page`, which `FeedsPane` opens via `AppNav.openFlow` /
/// `InlineFlowHost`, so the `Navigator.push` inside `_MonetizationSection`
/// lands on that nested Navigator and `Navigator.pop(context, _dirty)` returns
/// its result exactly as on mobile. Keep it that way.
///
/// A "plan" is one entry on the channel: a price and a period on a paywall
/// ledger, which a reader pays into to unlock the feed. The word deliberately
/// differs from the contract's own `Plan`/`feedId` vocabulary only in casing —
/// what it must NOT be called in UI is a "feed", which already means a channel.
///
/// **This page owns the channel's access entries and saves them itself.** The
/// channel edit form never sends `access_entries` at all: on the wire an absent
/// key means "leave the paywall alone", so editing a description can never wipe
/// a paywall, and this page can never clobber a name change.
///
/// Two states an owner needs explained rather than just shown:
///
///   OUTDATED — the entry names a ledger the server has since replaced. It is
///              still honoured (the gate calls whatever address the row holds),
///              but no new subscription should go there. One tap moves it.
///
///   NOT FOR SALE — a retired plan id kept alongside a newer one on the same
///              chain, so people who already paid keep reading. The server
///              decides this (`payable`), never the client.
class ManagePlansPage extends StatefulWidget {
  final Channel channel;

  const ManagePlansPage({super.key, required this.channel});

  @override
  State<ManagePlansPage> createState() => _ManagePlansPageState();
}

class _ManagePlansPageState extends State<ManagePlansPage> {
  List<ChannelAccessEntry> _entries = const [];
  List<PaidFeedServerChain> _chains = const [];
  final Map<String, PaidFeedPlan> _plans = {}; // "chain:contract:id" → terms

  bool _loading = true;
  bool _busy = false;
  String? _busyLabel;
  bool _dirty = false;

  String _key(ChannelAccessEntry e) =>
      '${e.chainId}:${e.contract.toLowerCase()}:${e.feedId}';

  @override
  void initState() {
    super.initState();
    _entries = List.of(widget.channel.accessEntries);
    _load();
  }

  Future<void> _load() async {
    // The server is the authority on which chains exist and which ledger is
    // current — never PaidFeedChains.all. Offering our own list would let an
    // owner enable a chain their host cannot check, which gates every reader
    // forever while reporting "you never paid".
    final chains = await PublicOSPaidFeeds.supportedChains();
    for (final e in _entries) {
      final plan = await PublicOSPaidFeeds.planFor(e);
      if (plan != null) _plans[_key(e)] = plan;
    }
    if (!mounted) return;
    setState(() {
      _chains = chains;
      _loading = false;
    });
  }

  /// Persist the entry list. Replace-not-merge: what we send IS the channel's
  /// whole paywall, which is also the only way to express "remove it" (`[]`).
  Future<bool> _persist(List<ChannelAccessEntry> next, String label) async {
    setState(() {
      _busy = true;
      _busyLabel = label;
    });
    try {
      final res = await PublicOSChannels.updateChannel(
        slug: widget.channel.slug,
        accessEntries: next,
      );
      if (!mounted) return false;
      if (res.success) {
        setState(() {
          _entries = List.of(res.data?.accessEntries ?? next);
          _dirty = true;
          _busy = false;
          _busyLabel = null;
        });
        return true;
      }
      final msg = res.error?['message']?.toString() ?? '';
      final details = res.error?['details']?.toString();
      _toast(details == null || details.isEmpty ? msg : '$msg — $details');
    } catch (e) {
      if (mounted) _toast(localizedError(context.l10n, e));
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _busyLabel = null;
      });
    }
    return false;
  }

  void _toast(String msg) {
    if (!mounted || msg.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  /// Move an outdated entry onto the ledger this server uses today.
  ///
  /// The PLAN ID does not carry across: ids are per contract, so plan 4 on the
  /// old ledger is unrelated to plan 4 on the new one. Moving therefore means
  /// registering a fresh plan with the same terms and listing it ALONGSIDE the
  /// old entry — which is exactly the retired-id shape the server already
  /// understands, and it keeps existing subscribers reading.
  Future<void> _moveToCurrent(ChannelAccessEntry old) async {
    final l10n = context.l10n;
    final chain = PublicOSPaidFeeds.currentChain(old.chainId, _chains);
    final plan = _plans[_key(old)];
    if (chain == null || plan == null) return;

    final ok = await _confirm(
      title: l10n.managePlansMoveToCurrent,
      body: l10n.managePlansOutdatedNote,
    );
    if (!ok) return;

    final created = await _registerPlan(
      chain: chain,
      payout: plan.payout,
      periodDays: plan.period.inDays,
      price: plan.prices.isEmpty ? BigInt.one : plan.prices.first.price,
      token: plan.prices.isEmpty ? null : plan.prices.first.token,
    );
    if (created == null) return;

    // Keep the old entry: readers who paid into it must not lose access.
    await _persist([..._entries, created], l10n.managePlansAttaching);
    await _refreshPlans();
  }

  /// Register on chain, wait for the receipt, decode the id.
  ///
  /// `register()` returns the id as a RETURN VALUE, which an EOA transaction
  /// cannot read — so the id comes out of the PlanRegistered log, never from
  /// the call itself.
  Future<ChannelAccessEntry?> _registerPlan({
    required PaidFeedServerChain chain,
    required String payout,
    required int periodDays,
    required BigInt price,
    String? token,
  }) async {
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _busyLabel = l10n.managePlansCreating;
    });
    try {
      final tx = await PublicOSPaidFeeds.register(
        chainId: chain.chainId,
        contract: chain.contract,
        payout: payout,
        period: Duration(days: periodDays),
        prices: {token: price},
      );
      if (tx == null) {
        _toast(PublicOS.lastError ?? '');
        return null;
      }
      final planId = await PublicOSPaidFeeds.planIdFromTx(
          chain.chainId, chain.contract, tx);
      if (planId == null) {
        _toast(PublicOS.lastError ?? '');
        return null;
      }
      return chain.entryFor(planId);
    } catch (e) {
      if (mounted) _toast(localizedError(context.l10n, e));
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshPlans() async {
    _plans.clear();
    for (final e in _entries) {
      final p = await PublicOSPaidFeeds.planFor(e);
      if (p != null) _plans[_key(e)] = p;
    }
    if (mounted) setState(() {});
  }

  Future<void> _remove(ChannelAccessEntry e) async {
    final l10n = context.l10n;
    if (!await _confirm(
      title: l10n.managePlansRemove,
      body: l10n.managePlansRemoveConfirm,
    )) {
      return;
    }
    final next = _entries.where((x) => x != e).toList();
    await _persist(next, l10n.managePlansAttaching);
  }

  Future<bool> _confirm({required String title, required String body}) async {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        backgroundColor: tokens.surfaceElevated,
        title: Text(title, style: TextStyle(color: tokens.starkWhite, fontSize: 16)),
        content: Text(body, style: TextStyle(color: tokens.textDim, fontSize: 13, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel,
                style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(title, style: TextStyle(color: tokens.connectedAccent)),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _addPlan() async {
    final chain = await showGlassSheetDialog<_NewPlan>(
      context: context,
      width: DialogWidth.m,
      builder: (_) => _AddPlanSheet(chains: _chains),
    );
    if (chain == null || !mounted) return;

    // Resolve the label HERE, between the sheet closing and the chain call —
    // guarded by the `mounted` check above. A register + receipt round trip can
    // easily outlive this widget, and reaching for context afterwards is how a
    // disposed-State crash gets shipped.
    final attachingLabel = context.l10n.managePlansAttaching;

    final entry = await _registerPlan(
      chain: chain.chain,
      payout: chain.payout,
      periodDays: chain.periodDays,
      price: chain.price,
    );
    if (entry == null || !mounted) return;
    await _persist([..._entries, entry], attachingLabel);
    await _refreshPlans();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: PopScope(
        canPop: !_busy,
        onPopInvokedWithResult: (didPop, _) {
          // Hand the dirty flag back so the caller reloads its channel.
          if (didPop) return;
        },
        child: Scaffold(
          backgroundColor: tokens.background,
          appBar: AppBar(
            backgroundColor: tokens.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: tokens.starkWhite),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _busy ? null : () => Navigator.pop(context, _dirty),
            ),
            title: Text(
              l10n.managePlansTitle,
              style: TextStyle(
                color: tokens.starkWhite,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            centerTitle: false,
          ),
          body: _loading
              ? const Center(child: PhigitalLoadingWidget())
              : _body(tokens, l10n),
        ),
      ),
    );
  }

  Widget _body(GlassTokens tokens, dynamic l10n) {
    if (_busy) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PhigitalLoadingWidget(),
            if (_busyLabel != null) ...[
              const SizedBox(height: 16),
              Text(_busyLabel!,
                  style: TextStyle(color: tokens.textDim, fontSize: 13)),
            ],
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(l10n.managePlansSubtitle,
            style: TextStyle(color: tokens.textDim, fontSize: 12, height: 1.4)),
        const SizedBox(height: 20),
        if (_chains.isEmpty)
          _Note(text: l10n.managePlansNoChains, tokens: tokens)
        else ...[
          if (_entries.isEmpty)
            _Note(text: l10n.managePlansNone, tokens: tokens)
          else
            for (final e in _entries)
              _PlanCard(
                entry: e,
                plan: _plans[_key(e)],
                isCurrent: PublicOSPaidFeeds.isCurrentContract(e, _chains),
                chains: _chains,
                onMove: () => _moveToCurrent(e),
                onRemove: () => _remove(e),
              ),
          const SizedBox(height: 16),
          _AddButton(label: l10n.managePlansAdd, onPressed: _addPlan),
        ],
      ],
    );
  }
}

/// One plan on the channel, as the owner sees it.
class _PlanCard extends StatelessWidget {
  final ChannelAccessEntry entry;
  final PaidFeedPlan? plan;
  final bool isCurrent;
  final List<PaidFeedServerChain> chains;
  final VoidCallback onMove;
  final VoidCallback onRemove;

  const _PlanCard({
    required this.entry,
    required this.plan,
    required this.isCurrent,
    required this.chains,
    required this.onMove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final chainName = PaidFeedChains.nameFor(entry.chainId,
        serverName: entry.chainName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? tokens.borderSubtle : tokens.fallbackAccent.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$chainName · #${entry.feedId}',
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!entry.payable)
                _Badge(text: l10n.managePlansRetired, tone: tokens.textDim),
              if (!isCurrent) ...[
                const SizedBox(width: 6),
                _Badge(text: l10n.managePlansOutdated, tone: tokens.fallbackAccent),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Prices — one row per accepted token, which is what a reader picks
          // between at the pay sheet.
          if (plan == null)
            Text('…', style: TextStyle(color: tokens.textDim, fontSize: 12))
          else if (plan!.prices.isEmpty)
            Text(l10n.managePlansRetiredNote,
                style: TextStyle(color: tokens.textDim, fontSize: 11, height: 1.4))
          else
            for (final p in plan!.prices)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${PublicOSWallets.formatTokenAmount(p.price, p.meta?.decimals ?? 18, symbol: p.meta?.symbol)} '
                  '${l10n.managePlansPerPeriod(plan!.period.inDays)}',
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          const SizedBox(height: 8),
          Text(
            entry.contract,
            style: TextStyle(
              color: tokens.textDim,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          if (!entry.payable) ...[
            const SizedBox(height: 6),
            Text(l10n.managePlansRetiredNote,
                style: TextStyle(color: tokens.textDim, fontSize: 11, height: 1.4)),
          ],
          if (!isCurrent) ...[
            const SizedBox(height: 10),
            Text(l10n.managePlansOutdatedNote,
                style: TextStyle(color: tokens.textDim, fontSize: 11, height: 1.4)),
            const SizedBox(height: 8),
            _AddButton(label: l10n.managePlansMoveToCurrent, onPressed: onMove),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onRemove,
              child: Text(l10n.managePlansRemove,
                  style: TextStyle(color: tokens.textDim, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

/// What [_AddPlanSheet] returns.
class _NewPlan {
  final PaidFeedServerChain chain;
  final String payout;
  final BigInt price;
  final int periodDays;
  const _NewPlan({
    required this.chain,
    required this.payout,
    required this.price,
    required this.periodDays,
  });
}

/// Chain + price + period, with a live payout check.
class _AddPlanSheet extends StatefulWidget {
  final List<PaidFeedServerChain> chains;
  const _AddPlanSheet({required this.chains});

  @override
  State<_AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<_AddPlanSheet> {
  PaidFeedServerChain? _chain;
  final _priceCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(text: '30');
  late final TextEditingController _payoutCtrl;

  bool _checking = false;
  bool? _payoutOk;
  String? _resolved;

  @override
  void initState() {
    super.initState();
    _chain = widget.chains.isEmpty ? null : widget.chains.first;
    // Default the payout to the owner's account. On our chain that resolves to
    // their Safe; the check below proves it before they can submit.
    _payoutCtrl = TextEditingController(
        text: PublicOS.myPublicosAddress ?? PublicOS.sessionBlockchainAddress ?? '');
    _checkPayout();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _daysCtrl.dispose();
    _payoutCtrl.dispose();
    super.dispose();
  }

  /// Ask the CONTRACT what it will do with this payout, rather than guessing.
  ///
  /// A PublicOS account has no payable receive, so naming one unchecked would
  /// register cleanly and then revert every reader's payment. On a chain with
  /// a resolver
  /// the account is turned into its Safe; without one it is refused. Either way
  /// the owner learns here, not a stranger later.
  Future<void> _checkPayout() async {
    final chain = _chain;
    final addr = _payoutCtrl.text.trim();
    if (chain == null || addr.length != 42) {
      setState(() => _payoutOk = null);
      return;
    }
    setState(() => _checking = true);
    final res = await PublicOSPaidFeeds.resolvePayout(
        chain.chainId, chain.contract, addr);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _payoutOk = res?.reachable;
      _resolved = res?.resolved;
    });
  }

  bool get _canCreate {
    final price = BigInt.tryParse(_priceCtrl.text.trim());
    final days = int.tryParse(_daysCtrl.text.trim());
    return _chain != null &&
        price != null &&
        price > BigInt.zero &&
        days != null &&
        days > 0 &&
        _payoutOk == true;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.managePlansAdd,
                style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text(l10n.managePlansChain,
                style: TextStyle(color: tokens.textDim, fontSize: 11)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final c in widget.chains)
                  ChoiceChip(
                    label: Text(c.displayName),
                    selected: _chain?.chainId == c.chainId,
                    onSelected: (_) {
                      setState(() => _chain = c);
                      _checkPayout();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _Field(
              label: '${l10n.managePlansPrice} (${_chain?.symbol ?? ''})',
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _Field(
              label: l10n.managePlansPeriodDays,
              controller: _daysCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _Field(
              label: l10n.managePlansPayout,
              controller: _payoutCtrl,
              onChanged: (_) => _checkPayout(),
            ),
            const SizedBox(height: 6),
            if (_checking)
              Text('…', style: TextStyle(color: tokens.textDim, fontSize: 11))
            else if (_payoutOk == false)
              Text(l10n.managePlansPayoutUnreachable,
                  style: TextStyle(color: tokens.fallbackAccent, fontSize: 11))
            else if (_payoutOk == true && _resolved != null)
              Text(
                _resolved!.toLowerCase() == _payoutCtrl.text.trim().toLowerCase()
                    ? ''
                    : '${l10n.managePlansPayoutHint}\n$_resolved',
                style: TextStyle(color: tokens.textDim, fontSize: 11, height: 1.4),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canCreate
                    ? () => Navigator.pop(
                          context,
                          _NewPlan(
                            chain: _chain!,
                            payout: _payoutCtrl.text.trim(),
                            price: BigInt.parse(_priceCtrl.text.trim()),
                            periodDays: int.parse(_daysCtrl.text.trim()),
                          ),
                        )
                    : null,
                child: Text(l10n.managePlansCreate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: tokens.textDim, fontSize: 11)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(color: tokens.starkWhite, fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: tokens.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.borderSubtle),
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color tone;
  const _Badge({required this.text, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(color: tone, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  final GlassTokens tokens;
  const _Note({required this.text, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Text(text,
          style: TextStyle(color: tokens.textDim, fontSize: 12, height: 1.4)),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _AddButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: tokens.borderSubtle),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label,
            style: TextStyle(color: tokens.starkWhite, fontSize: 13)),
      ),
    );
  }
}
