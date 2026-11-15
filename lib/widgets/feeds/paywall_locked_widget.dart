import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/feeds/gate_locked_shell.dart';
import 'package:publicos_desktop/widgets/feeds/private_feed_locked_widget.dart';
import 'package:publicos_desktop/widgets/transactions/subscribe_sheet.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// The body for a `PAYWALL_DENIED` refusal — "this channel costs money and
/// you have not paid (or your payment lapsed)".
///
/// **It never trusts the stub.** `channelStubFromFeedUrl` hardcodes
/// `isPrivate: true` (it is written for the private case), so trusting it
/// would show a public paid channel with a Private badge and "Request
/// access". This widget re-reads the live channel the same way the
/// private body does (`getChannelsByAddress`, signed) and takes `isPrivate`,
/// `followStatus`, `payableEntries`, name and description from that.
///
/// **Private + paid is sequenced by the server, not here.** The read ladder
/// runs lists before the paywall, so a private paid channel refuses with
/// `PRIVATE_FEED_NOT_APPROVED` until the owner approves, and only then can a
/// read reach `PAYWALL_DENIED`. If the live row nonetheless says
/// private-and-not-approved (a race with a revoke), this body hands off to
/// [PrivateFeedLockedWidget] rather than offering a payment that cannot
/// unlock anything.
///
/// States: resolving → subscribe / **renew** (server sent `lapsed_at`) →
/// confirming (a receipt landed but the server's re-check has not caught
/// up — the read still 403s for a moment; never a second bounce).
///
/// ⚠ **Same edit twice** — twin of
/// `publicos_client/lib/components/feeds/paywall_locked_widget.dart`.
class PaywallLockedWidget extends StatefulWidget {
  /// The URL-derived stub: owner + slug + serverAddress. Nothing else on it
  /// is trusted.
  final Channel channel;

  /// The typed refusal, when the fetch surfaced it. Carries the payable
  /// entries and `lapsedAt`; both are re-read live anyway.
  final PaywallException? paywall;

  /// The channel object the server attached to the refusal (`error.channel`)
  /// or embedded on the feed — when present, no listing call is made.
  final Channel? live;

  /// Fired after a payment's receipts landed — the host reloads the feed.
  final Future<void> Function()? onPaid;
  final Color? accentColor;

  const PaywallLockedWidget({
    super.key,
    required this.channel,
    this.paywall,
    this.live,
    this.onPaid,
    this.accentColor,
  });

  @override
  State<PaywallLockedWidget> createState() => _PaywallLockedWidgetState();
}

class _PaywallLockedWidgetState extends State<PaywallLockedWidget> {
  bool _resolving = true;
  bool _confirming = false;
  bool _handOffToPrivate = false;
  Channel? _live;
  List<ChannelAccessEntry> _entries = const [];
  PaidFeedPlan? _plan;
  String? _error;

  DateTime? get _lapsedAt => widget.paywall?.lapsedAt;

  @override
  void initState() {
    super.initState();
    // First load reads context.l10n, which is not allowed inside initState.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final owner = widget.channel.ownerAddress;
    if (owner == null || owner.isEmpty) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _error = context.l10n.privateFeedLockedWidgetNoOwnerAddress;
      });
      return;
    }
    setState(() {
      _resolving = true;
      _error = null;
    });

    // The refusal already carried the object; only an older server
    // makes us ask — and then it is the channel OBJECT, per channel, never
    // the owner listing.
    Channel? live = widget.live ?? widget.paywall?.channel;
    if (live == null) {
      try {
        final resp = await PublicOSChannels.getChannel(
          ownerAddress: owner,
          slug: widget.channel.slug,
          serverAddress: widget.channel.serverAddress,
        );
        if (resp.success) live = resp.data;
      } catch (_) {
        live = null;
      }
    }
    if (!mounted) return;

    // Belt and braces: the server sequences private-before-paid, so this
    // only fires on a race. Hand off rather than sell a lock that stays shut.
    if (live != null && live.isPrivate && live.followStatus != 'approved') {
      setState(() {
        _live = live;
        _handOffToPrivate = true;
        _resolving = false;
      });
      return;
    }

    final entries = <ChannelAccessEntry>[
      if (live != null) ...live.payableEntries,
      if (live == null || live.payableEntries.isEmpty)
        ...?widget.paywall?.entries,
    ];

    // Already entitled on-chain but still refused: the server's re-check has
    // not caught up. Show "confirming", never a second paywall.
    var confirming = false;
    if (entries.isNotEmpty) {
      try {
        final ent = await PublicOSPaidFeeds.entitlement(entries);
        confirming = ent.isActive;
      } catch (_) {}
    }

    PaidFeedPlan? plan;
    if (entries.isNotEmpty) {
      plan = await PublicOSPaidFeeds.planFor(entries.first);
    }
    if (!mounted) return;
    setState(() {
      _live = live;
      _entries = entries;
      _plan = plan;
      _confirming = confirming;
      _resolving = false;
    });
    if (confirming) widget.onPaid?.call();
  }

  Future<void> _subscribe() async {
    final entry = _entries.firstOrNull;
    if (entry == null) return;
    final paid = await showSubscribeSheet(
      context: context,
      entry: entry,
      channelName: _live?.name ?? widget.channel.name,
      lapsedAt: _lapsedAt,
    );
    if (!paid || !mounted) return;
    setState(() => _confirming = true);
    await widget.onPaid?.call();
  }

  String _priceLine(BuildContext context, PaidFeedPlan plan) {
    final p = plan.prices.firstOrNull;
    if (p == null) return '';
    final amount = PublicOSWallets.formatTokenAmount(
      p.price,
      p.meta?.decimals ?? 18,
      symbol: p.meta?.symbol ?? 'OX',
    );
    final days = plan.period.inDays;
    final period = days >= 1
        ? context.l10n.subscribeSheetPeriodDays(days)
        : context.l10n.subscribeSheetPeriodHours(plan.period.inHours);
    return '$amount / $period';
  }

  @override
  Widget build(BuildContext context) {
    if (_handOffToPrivate) {
      return PrivateFeedLockedWidget(
        channel: _live ?? widget.channel,
        accentColor: widget.accentColor,
        onApproved: () => widget.onPaid?.call(),
      );
    }

    final l10n = context.l10n;
    final name = _live?.name ?? widget.channel.name;
    final desc = _live?.description ?? widget.channel.description;
    final plan = _plan;
    final lapsed = _lapsedAt;

    if (_confirming) {
      return GateLockedShell(
        icon: Icons.hourglass_top_rounded,
        title: name,
        description: desc,
        badge: l10n.paywallLockedWidgetBadge,
        blurb: l10n.paywallLockedWidgetBlurbConfirming,
        onRefresh: () async {
          await widget.onPaid?.call();
          await _resolve();
        },
        action: GatePrimaryButton(
          label: l10n.paywallLockedWidgetRetry,
          icon: Icons.refresh_rounded,
          onPressed: () async {
            await widget.onPaid?.call();
            await _resolve();
          },
          accentColor: widget.accentColor,
        ),
      );
    }

    final noPlan = !_resolving && (plan == null || !plan.isPurchasable);

    return GateLockedShell(
      resolving: _resolving,
      icon: Icons.workspace_premium_rounded,
      title: name,
      description: desc,
      badge: l10n.paywallLockedWidgetBadge,
      blurb: lapsed != null
          ? l10n.paywallLockedWidgetBlurbRenew(_fmtDate(lapsed))
          : l10n.paywallLockedWidgetBlurbSubscribe,
      errorText: _error ?? (noPlan ? l10n.paywallLockedWidgetNoPlan : null),
      detail: plan != null && plan.isPurchasable
          ? _PriceChip(text: _priceLine(context, plan))
          : null,
      onRefresh: _resolve,
      action: noPlan
          ? null
          : GatePrimaryButton(
              label: lapsed != null
                  ? l10n.paywallLockedWidgetRenew
                  : l10n.paywallLockedWidgetSubscribe,
              icon: Icons.workspace_premium_rounded,
              onPressed: _subscribe,
              accentColor: widget.accentColor,
            ),
    );
  }

  static String _fmtDate(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
  }
}

class _PriceChip extends StatelessWidget {
  final String text;
  const _PriceChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        border: Border.all(color: tokens.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tokens.starkWhite,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
