import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/network_access_sheets.dart';
import 'package:publicos_desktop/widgets/send_notice_dialog.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';

/// Treasury — the money center under the domain-rights economy.
///
/// The economy is three INDEPENDENT goods plus one unified pull:
///   1. Domain  — a recurring, name-length-priced fee that holds your name and
///                gates your write access to the chain (the consensus instrument).
///                Citizens on a 5+ char name hold it free forever (NEVER).
///   2. BSP     — an independent subscription that routes you to the chain.
///   3. SSP     — an independent subscription that hosts your social data.
///   + Claim    — one `claim()` from the Accumulator pool pays everything the
///                economy owes you in a single tx: the Citizen Stipend and your
///                provider earnings, net of any fine garnishment. (The welcome
///                bonus is credited at citizenship grant and rides the direct leg.)
///
/// This page answers, in order: who am I (citizen/private) · what can I claim ·
/// what do I owe for my name (domain) · my BSP · my SSP · parameters · grants.
class TreasuryPage extends StatefulWidget {
  const TreasuryPage({super.key});

  @override
  State<TreasuryPage> createState() => _TreasuryPageState();
}

class _TreasuryPageState extends State<TreasuryPage> {
  bool _isLoading = true;

  // Network-wide parameters
  DomainInfo? _domainInfo;
  ServiceInfo? _bspServiceInfo;
  ServiceInfo? _sspServiceInfo;
  BigInt? _treasuryBalance;
  BigInt? _totalSupply;

  // Identity + unified claim
  bool _isCitizen = false;
  // Penalties owed or the court's blacklist: subscriptions revert while true.
  bool _servicesBlocked = false;
  ClaimInfo? _claimInfo;

  // Owned providers — earnings are folded into claim(); we list them so a
  // provider knows their earnings are included.
  List<String> _ownedBsps = const [];
  List<String> _ownedSsps = const [];

  // BSP / SSP state for the active account. The slug is the
  // assignment (it survives a lapse); `live` is the contract's own
  // `isActive(axis, a)`; ONE balance and ONE coveredUntil cover both axes.
  String _assignedBspSlug = '';
  String _assignedSspSlug = '';
  String _bspTitle = '';
  String _sspTitle = '';
  bool _bspLive = false;
  bool _sspLive = false;
  BigInt _coveredUntil = BigInt.zero; // 0 = never subscribed
  BigInt _subsBalance = BigInt.zero;
  BigInt _subsDue = BigInt.zero; // accrued to the providers, not yet settled (0 for a citizen)
  BigInt _subsSponsored = BigInt.zero; // added by someone else (SubsManager.fund); pays providers only, never withdrawn
  BigInt _subsWithdrawable = BigInt.zero; // what `withdraw` would let out right now (SubsManager.withdrawable)
  bool _subsEverSubscribed = false;

  // Single-flight write guard. Values:
  //   'claim', 'domain', 'pick-bsp', 'pick-ssp', 'switch-bsp', 'switch-ssp',
  //   'leave-bsp', 'leave-ssp', 'topup', 'withdraw', 'resume'.
  String? _busyKey;

  /// Which group is open — one at a time, the Settings accordion.
  /// Starts on the claim, the page's main job.
  String? _openGroup = 'claim';

  @override
  void initState() {
    super.initState();
    _loadTreasuryData();
  }

  // ──────────────────────────────────────────────────────────────────────
  // Load — parallel-fetch everything; full reload after any write.
  // ──────────────────────────────────────────────────────────────────────

  Future<void> _loadTreasuryData({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _isLoading = true);

    try {
      final myHex = PublicOS.myPublicosAddress;
      final myAddress = myHex != null ? EthereumAddress.fromHex(myHex) : null;

      final baseResults = await Future.wait<dynamic>([
        PublicOSTreasury.getDomainInfo(),
        PublicOSTreasury.getBspServiceInfo(),
        PublicOSTreasury.getSspServiceInfo(),
        PublicOSTreasury.getTokenBalance(PublicOSBsp.treasuryManagerAddress),
        PublicOSTreasury.getTokenTotalSupply(),
      ]);

      final domainInfo = baseResults[0] as DomainInfo;
      final bspServiceInfo = baseResults[1] as ServiceInfo;
      final sspServiceInfo = baseResults[2] as ServiceInfo;
      final treasuryBalance = baseResults[3] as BigInt;
      final totalSupply = baseResults[4] as BigInt;

      bool isCitizen = false;
      ClaimInfo? claimInfo;
      List<String> ownedBsps = const [];
      List<String> ownedSsps = const [];
      String assignedBspSlug = '';
      String assignedSspSlug = '';
      String bspTitle = '';
      String sspTitle = '';
      bool bspLive = false;
      bool sspLive = false;
      BigInt coveredUntil = BigInt.zero;
      BigInt subsBalance = BigInt.zero;
      BigInt subsDue = BigInt.zero;
      BigInt subsSponsored = BigInt.zero;
      BigInt subsWithdrawable = BigInt.zero;
      bool everSubscribed = false;
      bool servicesBlocked = false;

      if (myAddress != null) {
        // Identity is read on its own — the identity summary (and the citizen
        // BSP/SSP panels behind it) must never flip to "private" just because
        // the claim preview failed. (Domain status lives in the Account
        // Center; Treasury does not show it.)
        try {
          isCitizen = await PublicOSAccounts.isCitizen(myAddress);
        } catch (_) {}
        try {
          claimInfo = await PublicOSTreasury.getClaimInfo(myAddress);
        } catch (_) {}
        try {
          servicesBlocked =
              await PublicOSCommunityStandards.servicesBlocked(myAddress);
        } catch (_) {}

        final subsMem = PublicOSBsp.subsMemoryContract;
        final subsMgr = PublicOSBsp.subsManagerContract;
        final bspAxis = PublicOSTreasury.bspAxis;
        final sspAxis = PublicOSTreasury.sspAxis;

        final perAccount = await Future.wait<dynamic>([
          PublicOSBsp.bspRegistryMemoryContract
              .getBSPsByOwner((owner: myAddress)),
          PublicOSBsp.socialServerRegistryMemoryContract
              .getSocialServersByOwner((owner: myAddress)),
          subsMem.slugOf((axis: bspAxis, a: myAddress)),
          subsMem.slugOf((axis: sspAxis, a: myAddress)),
          subsMgr.isActive((axis: bspAxis, a: myAddress)),
          subsMgr.isActive((axis: sspAxis, a: myAddress)),
          subsMgr.coveredUntil((a: myAddress)),
        ]);

        ownedBsps = List<String>.from(perAccount[0] as List);
        ownedSsps = List<String>.from(perAccount[1] as List);
        assignedBspSlug = perAccount[2] as String;
        assignedSspSlug = perAccount[3] as String;
        bspLive = perAccount[4] as bool;
        sspLive = perAccount[5] as bool;
        coveredUntil = perAccount[6] as BigInt;

        // The shared balance and what has accrued to the providers since the
        // last settle — best-effort: the service cards stand without them.
        try {
          final acct = await PublicOSTreasury.getSubsAccount(myAddress);
          final due = await PublicOSTreasury.previewSettle(myAddress);
          final withdrawable = await PublicOSTreasury.withdrawable(myAddress);
          subsBalance = acct.balance;
          subsDue = due.minted ? BigInt.zero : due.toBsp + due.toSsp;
          subsSponsored = acct.sponsored;
          subsWithdrawable = withdrawable;
          everSubscribed = !acct.neverSubscribed;
        } catch (_) {}

        // Resolve titles for the assigned providers (best-effort).
        if (assignedBspSlug.isNotEmpty) {
          try {
            final data = await PublicOSBsp.bspRegistryMemoryContract
                .getBSPBySlug((slug: assignedBspSlug));
            if (data != null && data[0] as bool) {
              bspTitle = data[2] as String;
            }
          } catch (_) {}
        }
        if (assignedSspSlug.isNotEmpty) {
          try {
            final data = await PublicOSBsp.socialServerRegistryMemoryContract
                .getSocialServerBySlug((slug: assignedSspSlug));
            if (data != null && data[0] as bool) {
              sspTitle = data[2] as String;
            }
          } catch (_) {}
        }
      }

      if (!mounted) return;
      setState(() {
        _domainInfo = domainInfo;
        _bspServiceInfo = bspServiceInfo;
        _sspServiceInfo = sspServiceInfo;
        _treasuryBalance = treasuryBalance;
        _totalSupply = totalSupply;
        _isCitizen = isCitizen;
        _servicesBlocked = servicesBlocked;
        _claimInfo = claimInfo;
        _ownedBsps = ownedBsps;
        _ownedSsps = ownedSsps;
        _assignedBspSlug = assignedBspSlug;
        _assignedSspSlug = assignedSspSlug;
        _bspTitle = bspTitle;
        _sspTitle = sspTitle;
        _bspLive = bspLive;
        _sspLive = sspLive;
        _coveredUntil = coveredUntil;
        _subsBalance = subsBalance;
        _subsDue = subsDue;
        _subsSponsored = subsSponsored;
        _subsWithdrawable = subsWithdrawable;
        _subsEverSubscribed = everSubscribed;
        if (!silent) _isLoading = false;
      });
    } catch (_) {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // Tx contract: every write → await receipt → on success, full reload.
  // ──────────────────────────────────────────────────────────────────────

  Future<void> _awaitConfirmAndReload({
    required String busyKey,
    required String label,
    required Future<String?> Function() send,
    String? successMessage,
  }) async {
    if (_busyKey != null) return;
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() => _busyKey = busyKey);

    try {
      await HapticFeedback.lightImpact();
      final txHash = await send();
      if (txHash == null) {
        _snack(l10n.treasuryPageActionFailedToSend(label));
        return;
      }
      final ok = await TxUtils.waitForReceipt(txHash, label: label);
      if (!mounted) return;
      if (ok) {
        _snack(successMessage ?? l10n.treasuryPageActionConfirmed(label));
        await _loadTreasuryData();
      } else {
        _snack(l10n.treasuryPageActionFailedOnChain(label));
      }
    } catch (e) {
      _snack(localizedError(l10n, e));
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ──────────────────────────────────────────────────────────────────────
  // Write actions
  // ──────────────────────────────────────────────────────────────────────

  Future<void> _claim() => _awaitConfirmAndReload(
        busyKey: 'claim',
        label: 'claim',
        send: PublicOSTreasury.claim,
        successMessage: context.l10n.treasuryPageClaimedSuccess,
      );

  // ── Service-sub actions — every path opens a sheet from
  // network_access_sheets.dart, awaits its result, and full-reloads on success.
  // The sheet owns the contract call + receipt wait.

  Future<void> _pickAndSubscribe(ProviderKind kind) async {
    if (_busyKey != null) return;
    final tag = kind == ProviderKind.bsp ? 'bsp' : 'ssp';
    final l10n = context.l10n;
    setState(() => _busyKey = 'pick-$tag');
    try {
      final exclude =
          kind == ProviderKind.bsp ? _assignedBspSlug : _assignedSspSlug;
      final slug = await pickProvider(
        context,
        kind: kind,
        excludeSlug: exclude.isEmpty ? null : exclude,
      );
      if (slug == null || !mounted) return;
      final ok = await confirmSubscribe(
        context,
        kind: kind,
        slug: slug,
        isCitizen: _isCitizen,
        isSwitch: false,
      );
      if (ok && mounted) {
        await _loadTreasuryData();
        _snack(l10n.treasuryPageSubscribedTo(
            kind == ProviderKind.bsp ? 'BSP' : 'SSP'));
      }
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _switchProvider(ProviderKind kind) async {
    if (_busyKey != null) return;
    final tag = kind == ProviderKind.bsp ? 'bsp' : 'ssp';
    final l10n = context.l10n;
    setState(() => _busyKey = 'switch-$tag');
    try {
      final exclude =
          kind == ProviderKind.bsp ? _assignedBspSlug : _assignedSspSlug;
      final slug = await pickProvider(
        context,
        kind: kind,
        excludeSlug: exclude.isEmpty ? null : exclude,
      );
      if (slug == null || !mounted) return;
      final ok = await confirmSubscribe(
        context,
        kind: kind,
        slug: slug,
        isCitizen: _isCitizen,
        isSwitch: true,
      );
      if (ok && mounted) {
        await _loadTreasuryData();
        _snack(l10n.treasuryPageProviderSwitched(
            kind == ProviderKind.bsp ? 'BSP' : 'SSP'));
      }
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _topUp() async {
    if (_busyKey != null) return;
    final l10n = context.l10n;
    setState(() => _busyKey = 'topup');
    try {
      final ok = await confirmTopUp(context);
      if (ok && mounted) {
        await _loadTreasuryData();
        _snack(l10n.treasuryPageToppedUp);
      }
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _withdraw() async {
    if (_busyKey != null) return;
    final l10n = context.l10n;
    setState(() => _busyKey = 'withdraw');
    try {
      final ok = await confirmWithdraw(context);
      if (ok && mounted) {
        await _loadTreasuryData();
        _snack(l10n.treasuryPageWithdrawn);
      }
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  /// Inactive usually means dormant — 60 days without a signed "seen" ping —
  /// and the way out is a write that re-stamps today. Until the clients send
  /// the daily ping, this button is that write (`PublicOSTreasury.touch`).
  Future<void> _resume() async {
    if (_busyKey != null) return;
    final l10n = context.l10n;
    await _awaitConfirmAndReload(
      busyKey: 'resume',
      label: 'resume',
      send: PublicOSTreasury.touch,
      successMessage: l10n.treasuryPageResumed,
    );
  }

  Future<void> _leave(ProviderKind kind) async {
    if (_busyKey != null) return;
    final slug =
        kind == ProviderKind.bsp ? _assignedBspSlug : _assignedSspSlug;
    if (slug.isEmpty) return;
    final tag = kind == ProviderKind.bsp ? 'bsp' : 'ssp';
    final l10n = context.l10n;
    setState(() => _busyKey = 'leave-$tag');
    try {
      final ok = await confirmLeave(context, kind: kind, slug: slug);
      if (ok && mounted) {
        await _loadTreasuryData();
        _snack(l10n.treasuryPageProviderLeft(
            kind == ProviderKind.bsp ? 'BSP' : 'SSP'));
      }
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  void _becomeProvider() {
    _snack(context.l10n.treasuryPageProviderOnboardingSoon);
  }

  // ──────────────────────────────────────────────────────────────────────
  // Formatting helpers
  // ──────────────────────────────────────────────────────────────────────

  String _formatBalance(double tokens) {
    if (tokens >= 1e12) return '${(tokens / 1e12).toStringAsFixed(2)}T';
    if (tokens >= 1e9) return '${(tokens / 1e9).toStringAsFixed(2)}B';
    if (tokens >= 1e6) return '${(tokens / 1e6).toStringAsFixed(2)}M';
    if (tokens >= 1e3) return '${(tokens / 1e3).toStringAsFixed(2)}K';
    return _withCommas(tokens, 2);
  }

  String _withCommas(double value, int decimals) {
    final fixed = value.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '$buf$decPart';
  }

  String _formatBalanceWithCommas(double tokens) => _withCommas(tokens, 2);

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  /// Render a period in seconds as "30 days" (or hours for short test periods).
  String _periodLabel(BigInt seconds) {
    final s = seconds.toInt();
    if (s <= 0) return context.l10n.treasuryPagePeriodFallback;
    final days = s ~/ (24 * 60 * 60);
    if (days >= 1) return context.l10n.treasuryPagePeriodDays(days);
    final hours = s ~/ 3600;
    if (hours >= 1) return context.l10n.treasuryPagePeriodHours(hours);
    return context.l10n.treasuryPagePeriodMinutes(s ~/ 60);
  }

  BigInt get _nowSec =>
      BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000);

  // ──────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SystemAppScaffold(
      // DESKTOP DELTA: centre in a 720px column instead of
      // stretching to the window edge — same width as `settings_pane`.
      maxContentWidth: 720,
      // DESKTOP DELTA: the body's RefreshIndicator is a PULL
      // gesture — a mouse cannot trigger it, so without this button the page
      // has no way to refresh at all. Mirrors the refresh action bsp_dialog
      // uses.
      actions: [
        Builder(
          builder: (context) => IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded,
                size: 19, color: GlassTokens.of(context).textDim),
            onPressed: () => _loadTreasuryData(silent: true),
          ),
        ),
      ],
      title: context.l10n.treasuryPageTitle,
      icon: Icons.account_balance_rounded,
      asset: 'assets/system_apps/treasury.png',
      pinHeader: true,
      builder: (context, scrollController, tokens) {
        return Stack(
          children: [
            if (!_isLoading)
              RefreshIndicator(
                onRefresh: () => _loadTreasuryData(silent: true),
                color: tokens.starkWhite,
                backgroundColor: tokens.surfaceElevated,
                edgeOffset:
                    MediaQuery.of(context).padding.top + kToolbarHeight,
                child: _buildLoaded(scrollController, tokens),
              ),
            if (_isLoading)
              const Positioned(
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: PhigitalLoadingWidget(size: 28, showShadows: false),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLoaded(ScrollController c, GlassTokens tokens) {
    return ListView(
      controller: c,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: kToolbarHeight + 60),
        // The Settings language (collapsible groups, borderless tiles). No
        // explainer sections on purpose: the Users Manual app explains the
        // economy.
        for (final section in [
          _buildIdentityCard(tokens),
          _buildClaimCard(tokens),
          _buildServiceBalanceCard(tokens),
          _buildServiceCard(tokens, ProviderKind.bsp),
          _buildServiceCard(tokens, ProviderKind.ssp),
          _buildNodesCard(tokens),
          _buildNoticeCard(tokens),
          _buildParametersCard(tokens),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: section,
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // Card 1 — Identity
  // ──────────────────────────────────────────────────────────────────────

  /// Who you are in the economy, always visible above the groups: your own
  /// avatar and a short summary for your class. User-facing vocabulary: a
  /// citizen is a "socially verified PublicOS Domain", a private one is
  /// "private"; and the copy never says "stipend".
  Widget _buildIdentityCard(GlassTokens tokens) {
    // The verified summary names private accounts and shows their ghost badge
    // right after the words: the l10n placeholder carries a marker character
    // that is swapped for the badge here, so translations can move it.
    const iconMarker = '\uFFFC';
    final summary = _isCitizen
        ? context.l10n.treasuryPageCitizenSummary(iconMarker)
        : context.l10n.treasuryPagePrivateSummary;
    final parts = summary.split(iconMarker);
    final me = AppStateNotifier.currentMyContact;
    final myHex = PublicOS.myPublicosAddress;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassContactIcon(
            contact: me,
            address: me == null ? myHex : null,
            size: 52,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  for (var i = 0; i < parts.length; i++) ...[
                    TextSpan(text: parts[i]),
                    if (i < parts.length - 1)
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: PhantomBadge(size: 15),
                      ),
                  ],
                ],
              ),
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 13,
                color: tokens.textDim,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ──────────────────────────────────────────────────────────────────────
  // Card 2 — Claim (the unified Accumulator pull)
  // ──────────────────────────────────────────────────────────────────────

  Widget _buildClaimCard(GlassTokens tokens) {
    final info = _claimInfo;
    final hasClaimable = info?.hasClaimable ?? false;
    final totalTokens = info?.totalTokens ?? 0;
    final canClaim = hasClaimable && _busyKey == null;
    final isClaiming = _busyKey == 'claim';

    final stipend = (info?.stipendPart.toDouble() ?? 0) / 1e18;
    final direct = (info?.directPart.toDouble() ?? 0) / 1e18;
    final garnished = (info?.garnished.toDouble() ?? 0) / 1e18;
    final hasProviders = _ownedBsps.isNotEmpty || _ownedSsps.isNotEmpty;
    final breakdown = <(String, String)>[
      if (hasClaimable && stipend > 0)
        (context.l10n.treasuryPageStipend, '${stipend.toStringAsFixed(2)} OX'),
      if (hasClaimable && direct > 0)
        (context.l10n.treasuryPageEarnings, '${direct.toStringAsFixed(2)} OX'),
      if (garnished > 0)
        (context.l10n.treasuryPageGarnished,
            '-${garnished.toStringAsFixed(2)} OX'),
    ];

    return _group(
      tokens,
      id: 'claim',
      icon: Icons.move_to_inbox_rounded,
      title: context.l10n.treasuryPageWhatYouCanClaim,
      children: [
        Text(
          context.l10n.treasuryPageClaimExplainer,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            color: tokens.textDim,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        // Full-width ledger: the
        // total on the right of its label, the breakdown under it in the
        // Parameters row shape, so every amount lines up on the right edge.
        _tile(
          tokens,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _miniLabel(tokens,
                        context.l10n.treasuryPageClaimable.toUpperCase()),
                  ),
                  Text(
                    '${totalTokens.toStringAsFixed(2)} OX',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: hasClaimable
                          ? tokens.connectedAccent
                          : tokens.textDim,
                    ),
                  ),
                ],
              ),
              if (breakdown.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (var i = 0; i < breakdown.length; i++)
                  _paramRow(tokens, breakdown[i].$1, breakdown[i].$2,
                      isLast: i == breakdown.length - 1),
              ],
            ],
          ),
        ),
        // Only when there is something to claim: a disabled "Nothing to
        // claim" button would repeat what the grey 0.00 OX total already
        // says.
        if (hasClaimable) ...[
          const SizedBox(height: 12),
          SystemAppActionButton(
            label: isClaiming
                ? context.l10n.treasuryPageClaiming
                : context.l10n.treasuryPageClaimAmount(
                    totalTokens.toStringAsFixed(2)),
            icon: Icons.download_rounded,
            onTap: canClaim ? _claim : null,
          ),
        ],
        if (hasProviders) ...[
          const SizedBox(height: 10),
          _infoChip(
            tokens,
            Icons.hub_rounded,
            context.l10n.treasuryPageRunProviders(
                _ownedBsps.length + _ownedSsps.length),
          ),
        ] else ...[
          const SizedBox(height: 18),
          _buildBecomeProviderSubpanel(tokens),
        ],
      ],
    );
  }

  Widget _buildBecomeProviderSubpanel(GlassTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.hub_outlined, size: 14, color: tokens.textDim),
            const SizedBox(width: 8),
            Text(
              context.l10n.treasuryPageBecomeProvider,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: tokens.textDim,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.treasuryPageBecomeProviderBlurb,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            color: tokens.textDim,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        SystemAppActionButton(
          label: context.l10n.treasuryPageBecomeProviderButton,
          icon: Icons.open_in_new_rounded,
          onTap: _busyKey == null ? _becomeProvider : null,
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // Cards 4 & 5 — BSP / SSP independent service subscriptions
  // ──────────────────────────────────────────────────────────────────────

  Widget _buildServiceCard(GlassTokens tokens, ProviderKind kind) {
    final state = _computeSub(kind);
    final upper = kind == ProviderKind.bsp ? 'BSP' : 'SSP';
    final icon = kind == ProviderKind.bsp
        ? Icons.hub_rounded
        : Icons.cloud_outlined;
    final blurb = kind == ProviderKind.bsp
        ? context.l10n.treasuryPageBspBlurb
        : context.l10n.treasuryPageSspBlurb;

    return _group(
      tokens,
      id: upper.toLowerCase(),
      icon: icon,
      title: upper,
      trailing: _subPill(tokens, state),
      children: [
        Text(blurb, style: _bodyStyle(tokens)),
        if (_servicesBlocked) ...[
          const SizedBox(height: 10),
          Text(
            context.l10n.treasuryPageServicesBlocked,
            style: _bodyStyle(tokens).copyWith(color: tokens.softDanger),
          ),
        ],
        const SizedBox(height: 14),
        ..._subBody(tokens, kind, state),
        const SizedBox(height: 12),
        ..._subActions(tokens, kind, state),
      ],
    );
  }

  _SubState _computeSub(ProviderKind kind) {
    final assigned =
        kind == ProviderKind.bsp ? _assignedBspSlug : _assignedSspSlug;
    if (assigned.isEmpty) return _SubState.none;
    final live = kind == ProviderKind.bsp ? _bspLive : _sspLive;
    return live ? _SubState.active : _SubState.inactive;
  }

  Widget _subPill(GlassTokens tokens, _SubState state) {
    switch (state) {
      case _SubState.none:
        return _pillBadge(
            tokens, context.l10n.treasuryPageSubNone, tokens.fallbackAccent);
      case _SubState.inactive:
        return _pillBadge(tokens, context.l10n.treasuryPageSubInactive,
            tokens.fallbackAccent);
      case _SubState.active:
        return _pillBadge(
            tokens, context.l10n.treasuryPageSubActive, tokens.connectedAccent);
    }
  }

  /// The one date the page shows: `coveredUntil`, shared by both axes. A
  /// citizen is "covered while you use the app" (dormancy is the only clock
  /// that applies to them), so the date is not shown for them.
  String _coveredLabel() {
    if (_isCitizen) return context.l10n.treasuryPageCoveredWhileUsed;
    if (_coveredUntil <= BigInt.zero) return '—';
    return _formatDate(
        DateTime.fromMillisecondsSinceEpoch(_coveredUntil.toInt() * 1000));
  }

  List<Widget> _subBody(
    GlassTokens tokens,
    ProviderKind kind,
    _SubState state,
  ) {
    final upper = kind == ProviderKind.bsp ? 'BSP' : 'SSP';
    final assigned =
        kind == ProviderKind.bsp ? _assignedBspSlug : _assignedSspSlug;
    final title = kind == ProviderKind.bsp ? _bspTitle : _sspTitle;
    final providerLabel = title.isNotEmpty ? title : assigned;

    switch (state) {
      case _SubState.none:
        return [
          Text(
            _isCitizen
                ? context.l10n.treasuryPageSubNoneCitizen(upper)
                : context.l10n.treasuryPageSubNonePrivate(upper),
            style: _bodyStyle(tokens),
          ),
        ];
      case _SubState.active:
        return [
          _tile(
            tokens,
            child: Column(
              children: [
                _kvRow(tokens, context.l10n.treasuryPageProvider, providerLabel),
                const SizedBox(height: 8),
                _kvRow(tokens, context.l10n.treasuryPageCoveredUntil,
                    _coveredLabel()),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isCitizen
                ? context.l10n.treasuryPageSubActiveCitizenBody(upper)
                : context.l10n.treasuryPageSubActivePrivateBody(upper),
            style: _bodyStyle(tokens),
          ),
        ];
      case _SubState.inactive:
        return [
          _tile(
            tokens,
            child: Column(
              children: [
                _kvRow(tokens, context.l10n.treasuryPageLastProvider(upper),
                    providerLabel),
                const SizedBox(height: 8),
                _kvRow(tokens, context.l10n.treasuryPageCoveredUntil,
                    _coveredLabel()),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.treasuryPageSubInactiveBody,
            style: _bodyStyle(tokens),
          ),
        ];
    }
  }

  List<Widget> _subActions(
    GlassTokens tokens,
    ProviderKind kind,
    _SubState state,
  ) {
    final upper = kind == ProviderKind.bsp ? 'BSP' : 'SSP';
    final tag = kind == ProviderKind.bsp ? 'bsp' : 'ssp';
    final globallyBusy = _busyKey != null;

    switch (state) {
      case _SubState.none:
        final busy = _busyKey == 'pick-$tag';
        return [
          SystemAppActionButton(
            label: busy
                ? context.l10n.treasuryPageOpening
                : context.l10n.treasuryPagePickProvider(upper),
            icon: Icons.add_circle_outline_rounded,
            onTap: globallyBusy ? null : () => _pickAndSubscribe(kind),
          ),
        ];
      case _SubState.inactive:
        // The slug is still assigned, so "subscribe again" would be the same
        // slug the picker hides: the real exits are RESUME (re-stamp today,
        // ends a dormancy), SWITCH, or — for a private whose balance ran out —
        // TOP UP in the balance card above.
        final resumeBusy = _busyKey == 'resume';
        return [
          SystemAppActionButton(
            label: resumeBusy
                ? context.l10n.treasuryPageOpening
                : context.l10n.treasuryPageResume,
            icon: Icons.play_arrow_rounded,
            onTap: globallyBusy ? null : _resume,
          ),
          const SizedBox(height: 8),
          _switchButton(tokens, kind, tag, globallyBusy),
          const SizedBox(height: 8),
          _leaveButton(tokens, kind, tag, globallyBusy),
        ];
      case _SubState.active:
        return [
          _switchButton(tokens, kind, tag, globallyBusy),
          const SizedBox(height: 8),
          _leaveButton(tokens, kind, tag, globallyBusy),
        ];
    }
  }

  Widget _leaveButton(
      GlassTokens tokens, ProviderKind kind, String tag, bool globallyBusy) {
    final upper = kind == ProviderKind.bsp ? 'BSP' : 'SSP';
    final busy = _busyKey == 'leave-$tag';
    return SystemAppActionButton(
      label: busy
          ? context.l10n.treasuryPageOpening
          : context.l10n.treasuryPageLeaveProvider(upper),
      icon: Icons.logout_rounded,
      onTap: globallyBusy ? null : () => _leave(kind),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // Card — Service balance. ONE balance pays both providers, by
  // the second; top up and withdraw live here, the provider choice lives
  // in the two cards below.
  // ──────────────────────────────────────────────────────────────────────

  Widget _buildServiceBalanceCard(GlassTokens tokens) {
    // Citizens never need a balance; they see the card only when one is
    // there to take back (deposited as a private, then claimed citizenship).
    if (_isCitizen && _subsBalance == BigInt.zero) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final globallyBusy = _busyKey != null;
    final topUpBusy = _busyKey == 'topup';
    final withdrawBusy = _busyKey == 'withdraw';
    final balanceTokens = _subsBalance.toDouble() / 1e18;
    final dueTokens = _subsDue.toDouble() / 1e18;
    final hasBalance = _subsBalance > BigInt.zero;

    final rows = <Widget>[
      _kvRow(tokens, l10n.treasuryPageBalance,
          '${balanceTokens.toStringAsFixed(2)} OX',
          emphasize: hasBalance),
    ];
    if (_subsDue > BigInt.zero) {
      rows.add(const SizedBox(height: 8));
      rows.add(_kvRow(tokens, l10n.treasuryPageAccrued,
          '${dueTokens.toStringAsFixed(2)} OX'));
    }
    // The part someone else put in (the sign-up sponsor, a friend): it is
    // credit for the providers only, so it gets its own row and a plain line.
    final sponsoredStr = (_subsSponsored.toDouble() / 1e18).toStringAsFixed(2);
    if (_subsSponsored > BigInt.zero) {
      rows.add(const SizedBox(height: 8));
      rows.add(_kvRow(tokens, l10n.treasuryPageAddedForYou, '$sponsoredStr OX'));
    }
    if (!_isCitizen && _coveredUntil > BigInt.zero) {
      rows.add(const SizedBox(height: 8));
      rows.add(_kvRow(tokens, l10n.treasuryPageRunsOut,
          '${_coveredLabel()}  ·  ${_describeUntil(_coveredUntil)}'));
    }

    return _group(
      tokens,
      id: 'balance',
      icon: Icons.account_balance_wallet_outlined,
      title: l10n.treasuryPageServiceBalance,
      trailing: _pillBadge(
        tokens,
        '${balanceTokens.toStringAsFixed(2)} OX',
        hasBalance ? tokens.connectedAccent : tokens.fallbackAccent,
      ),
      children: [
        Text(l10n.treasuryPageServiceBalanceBlurb, style: _bodyStyle(tokens)),
        const SizedBox(height: 14),
        if (_subsEverSubscribed)
          _tile(tokens, child: Column(children: rows))
        else
          Text(l10n.treasuryPageNeverSubscribed, style: _bodyStyle(tokens)),
        if (_subsSponsored > BigInt.zero) ...[
          const SizedBox(height: 10),
          Text(l10n.treasuryPageAddedForYouNote(sponsoredStr),
              style: _bodyStyle(tokens)),
        ],
        const SizedBox(height: 12),
        SystemAppActionButton(
          label: topUpBusy ? l10n.treasuryPageOpening : l10n.treasuryPageTopUp,
          icon: Icons.add_card_rounded,
          onTap: globallyBusy ? null : _topUp,
        ),
        // WITHDRAW only when the contract would let something out: a balance
        // that is all accrued, or all added-for-you, has nothing to take back.
        if (hasBalance && _subsWithdrawable > BigInt.zero) ...[
          const SizedBox(height: 8),
          SystemAppActionButton(
            label: withdrawBusy
                ? l10n.treasuryPageOpening
                : l10n.treasuryPageWithdraw,
            icon: Icons.undo_rounded,
            onTap: globallyBusy ? null : _withdraw,
          ),
        ],
      ],
    );
  }

  Widget _switchButton(
      GlassTokens tokens, ProviderKind kind, String tag, bool globallyBusy) {
    final upper = kind == ProviderKind.bsp ? 'BSP' : 'SSP';
    final busy = _busyKey == 'switch-$tag';
    return SystemAppActionButton(
      label: busy
          ? context.l10n.treasuryPageOpening
          : context.l10n.treasuryPageSwitchProvider(upper),
      icon: Icons.swap_horiz_rounded,
      onTap: globallyBusy ? null : () => _switchProvider(kind),
    );
  }

  TextStyle _bodyStyle(GlassTokens tokens) => TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 12,
        color: tokens.textDim,
        height: 1.45,
      );

  /// Render a future timestamp (seconds) as "in 6d", "in 4h". For past/now,
  /// returns "now".
  String _describeUntil(BigInt targetSec) {
    final l10n = context.l10n;
    final nowSec = _nowSec;
    if (targetSec <= nowSec) return l10n.treasuryPageRelativeNow;
    final diff = (targetSec - nowSec).toInt();
    if (diff < 60) return l10n.treasuryPageRelativeSeconds(diff);
    if (diff < 60 * 60) return l10n.treasuryPageRelativeMinutes(diff ~/ 60);
    if (diff < 24 * 60 * 60) return l10n.treasuryPageRelativeHours(diff ~/ 3600);
    final days = diff ~/ (24 * 60 * 60);
    return l10n.treasuryPageRelativeDays(days);
  }

  // ──────────────────────────────────────────────────────────────────────
  // Card 6 — Parameters (how the network runs)
  // ──────────────────────────────────────────────────────────────────────

  Widget _buildParametersCard(GlassTokens tokens) {
    final domain = _domainInfo;
    final bsp = _bspServiceInfo;
    final ssp = _sspServiceInfo;
    final totalSupplyTokens =
        _totalSupply != null ? _totalSupply!.toDouble() / 1e18 : null;
    final treasuryTokens = _treasuryBalance != null
        ? _treasuryBalance!.toDouble() / 1e18
        : null;
    final period = domain?.domainPeriod ?? BigInt.from(30 * 24 * 60 * 60);
    final per = _periodLabel(period);

    String tier(double v) => '${v.toStringAsFixed(2)} OX / $per';

    return _group(
      tokens,
      id: 'parameters',
      icon: Icons.tune_rounded,
      title: context.l10n.treasuryPageParameters,
      children: [
        _tile(
          tokens,
          child: Column(
            children: [
              _paramRow(
                tokens,
                context.l10n.treasuryPageDomainPrice,
                domain != null
                    ? context.l10n
                        .treasuryPageDomainTier3(tier(domain.priceTier3Tokens))
                    : '...',
              ),
              _paramRow(
                tokens,
                context.l10n.treasuryPageBspFee,
                bsp != null ? tier(bsp.feeTokens) : '...',
              ),
              _paramRow(
                tokens,
                context.l10n.treasuryPageSspFee,
                ssp != null ? tier(ssp.feeTokens) : '...',
              ),
              if (domain != null && domain.discountBps > BigInt.zero)
                _paramRow(
                  tokens,
                  context.l10n.treasuryPageMultiMonthDiscount,
                  context.l10n.treasuryPageDiscountValue(
                      domain.discountPercent.toStringAsFixed(0)),
                ),
              _paramRow(
                tokens,
                context.l10n.treasuryPageTotalSupply,
                totalSupplyTokens != null
                    ? '${_formatBalance(totalSupplyTokens)} OX'
                    : '...',
              ),
              _paramRow(
                tokens,
                context.l10n.treasuryPageTreasuryBalance,
                treasuryTokens != null
                    ? '${_formatBalanceWithCommas(treasuryTokens)} OX'
                    : '...',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // Card — Network nodes. Services holds your subscriptions and the
  // directory of the nodes behind them. Tapping opens the NodePage.
  // ──────────────────────────────────────────────────────────────────────

  Widget _buildNodesCard(GlassTokens tokens) {
    // A link, not a group: the group header's look with a chevron that never
    // turns, and no explainer body.
    return _GroupHeader(
      icon: Icons.hub_rounded,
      title: context.l10n.appsViewSystemNodes,
      trailing: null,
      open: false,
      onTap: _openNodes,
    );
  }


  // DESKTOP DELTA: Nodes is a shell pane (destination 8), not a
  // pushed route, so the card switches panes like the BSP dialog's hand-off.
  // Send an SSP notice: a link
  // row like Nodes; the dialog does the search, the kind, the text and the send.
  Widget _buildNoticeCard(GlassTokens tokens) {
    return _GroupHeader(
      icon: Icons.mark_email_unread_rounded,
      title: context.l10n.noticeServicesRow,
      trailing: null,
      open: false,
      onTap: () => showSendNoticeDialog(context),
    );
  }

  void _openNodes() {
    AppNav.onOpenDestination?.call(8);
  }

  // ──────────────────────────────────────────────────────────────────────
  // Leaf helpers
  // ──────────────────────────────────────────────────────────────────────

  Widget _miniLabel(GlassTokens tokens, String text, {Color? color}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: color ?? tokens.textDim,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  /// Collapsible settings group.
  /// Borrows `channel_settings_page`'s accordion drawers: one group open at a
  /// time, the whole header row toggles, the chevron turns 90°, the first group
  /// starts open. Shell deltas: no divider line (borderless), and the header's
  /// glyphs brighten on hover or while open, the way a rail row does.
  Widget _group(
    GlassTokens tokens, {
    required String id,
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onHeaderTap,
    required List<Widget> children,
  }) {
    final open = _openGroup == id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GroupHeader(
          icon: icon,
          title: title,
          trailing: trailing,
          open: open,
          onTap: () {
            setState(() => _openGroup = open ? null : id);
            onHeaderTap?.call();
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: open
              ? Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Borderless settings tile — the desktop shell's surface grammar: a
  /// `glassFill` tone step carries the edge, no hairline, radius 12 like the
  /// rail's icon box. **Tiles hold ROWS** (toggles, key/value groups). Chips
  /// and buttons sit on the stage beside them, never inside one: a filled
  /// control in a filled tile is a box in a box. A tile with
  /// [onTap] brightens on hover.
  Widget _tile(GlassTokens tokens, {required Widget child, VoidCallback? onTap}) {
    return Material(
      color: tokens.glassFill,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: tokens.glassFill,
        highlightColor: tokens.glassFill,
        splashColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: child,
        ),
      ),
    );
  }

  Widget _pillBadge(GlassTokens tokens, String label, Color color) {
    // No ring: the tint already says it (the borderless rule).
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: color,
        ),
      ),
    );
  }

  Widget _kvRow(
    GlassTokens tokens,
    String label,
    String value, {
    bool emphasize = false,
  }) {
    // Field label in the caps eyebrow voice, as on the Settings page.
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: _miniLabel(tokens, label.toUpperCase()),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 13,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: emphasize ? tokens.connectedAccent : tokens.starkWhite,
            ),
          ),
        ),
      ],
    );
  }

  /// One network parameter: caps label left, value right. No explanation
  /// paragraph — the Users Manual explains the economy.
  Widget _paramRow(
    GlassTokens tokens,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          Expanded(child: _miniLabel(tokens, label.toUpperCase())),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tokens.starkWhite,
            ),
          ),
        ],
      ),
    );
  }


  Widget _infoChip(GlassTokens tokens, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: tokens.textDim),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 11,
                color: tokens.textDim,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Group header ──────────────────────────────────────────────────────────────

/// The tappable header of a [_TreasuryPageState._group]. Grey glyphs that turn
/// white on hover or while open (the rail's selected/hovered grammar); the
/// title stays white. Teal is never used here: open is a place, not a state.
class _GroupHeader extends StatefulWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool open;
  final VoidCallback onTap;

  const _GroupHeader({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.open,
    required this.onTap,
  });

  @override
  State<_GroupHeader> createState() => _GroupHeaderState();
}

class _GroupHeaderState extends State<_GroupHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final fg = (_hovered || widget.open) ? tokens.starkWhite : tokens.textDim;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        // Open = a really light `glassFill` wash so it stands out; a hovered
        // closed header gets half of that, so hover never reads as open. The
        // 14 px inset matches the tiles below, so the wash's edge lines up
        // with theirs and the glyph lines up with their text.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.open
                ? tokens.glassFill
                : _hovered
                    ? tokens.glassFill.withValues(alpha: tokens.glassFill.a / 2)
                    : tokens.glassFill.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: fg, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (widget.trailing != null) ...[
                widget.trailing!,
                const SizedBox(width: 10),
              ],
              AnimatedRotation(
                turns: widget.open ? 0.25 : 0,
                duration: const Duration(milliseconds: 180),
                child: Icon(Icons.chevron_right_rounded, size: 18, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// State of one BSP/SSP subscription ("pay as served"): the
/// slug is the assignment and survives a lapse; `live` is the contract's own
/// `isActive(axis, a)`. No citizen windows, no private expiry — one balance,
/// one `coveredUntil`, nothing to renew by hand.
enum _SubState {
  none,
  active,
  inactive,
}
