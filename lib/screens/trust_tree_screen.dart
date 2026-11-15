import 'dart:math' as math;
import '../widgets/contact_banner.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

// Ported from publicos_client/lib/pages/trust_tree_screen.dart.
// Verbatim port, import swaps only, plus one desktop delta marked below:
// no AppBar back button (this is an embedded shell pane, not a pushed route).
import '../l10n/l10n_ext.dart';
import '../router.dart';
import '../router_helpers.dart';
import '../theme/glass_tokens.dart';
import '../widgets/constellation_background.dart';
import '../widgets/error/error_l10n.dart';
import '../widgets/glass_contact_icon.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/vouch_dialogs.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

class TrustTreeScreen extends StatefulWidget {
  final EthereumAddress initialAddress;

  const TrustTreeScreen({super.key, required this.initialAddress});

  @override
  State<TrustTreeScreen> createState() => _TrustTreeScreenState();
}

class _TrustTreeScreenState extends State<TrustTreeScreen>
    with TickerProviderStateMixin {
  /// DESKTOP DELTA: max width of the centered search + account-card column.
  static const double _desktopCardMaxWidth = 520;

  bool _isLoading = true;
  bool _isVouching = false;

  // Current profile data
  EthereumAddress? _currentAddress;
  Contact? _profileContact;
  bool _isCitizen = false;
  BigInt _vouchCount = BigInt.zero;
  BigInt _vouchThreshold = BigInt.zero;
  List<EthereumAddress> _vouchers = [];
  List<EthereumAddress> _vouchees = [];
  bool _isGroup = false;
  EthereumAddress? _groupCreator;

  // Resolved voucher/vouchee contacts (batch-loaded)
  final Map<String, Contact?> _resolvedVouchers = {};
  final Map<String, Contact?> _resolvedVouchees = {};
  int _resolveGen = 0; // bumped per applied load; see _resolveColumn

  // Search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool _searchFocused = false;
  bool _searchHasText = false;

  // Can current user vouch for viewed profile?
  bool _currentUserIsCitizen = false;
  bool _hasAlreadyVouched = false;

  // Transition animation
  late final AnimationController _transitionController;
  _TransitionData? _transition;

  // Profile data fetched during a transition — parked here until the
  // animation has landed, then applied atomically. Keeps the tree showing
  // old data for the full crossfade so we never dup or flicker.
  _PendingProfileData? _pendingData;

  // Pin the last-visited account to the TOP of the column it flies into, so the
  // outgoing fly-out lands exactly where the freshly-rendered column will draw
  // it (no mid-list snap). Set on a tap navigation; the relationship guarantees
  // the address is present in that column (a tapped vouchee's vouchers include
  // the old center, and vice versa). Null = no pin (direct loads / search).
  // _pinToLeft picks the column: true = left/vouchers, false = right/vouchees.
  EthereumAddress? _pinAddress;
  bool _pinToLeft = false;

  // Column entrance: when a column is freshly populated with >1 contact, the
  // rows below the top one accordion-open from the top (staggered), pushing each
  // other down. While [_unfolding] the ListViews drop their fixed itemExtent so
  // rows can grow, and connector lines fade in only over the animation's tail.
  late final AnimationController _unfoldController;
  bool _unfolding = false;
  // Accordion timing (real milliseconds, decoupled): each row takes _rowOpenMs
  // to open, and the next row starts _rowStaggerMs after the previous one. The
  // controller's total duration is computed per load from the visible row count
  // (_unfoldTotalMs). Bump either constant to slow the cascade down.
  static const double _rowOpenMs = 420;
  static const double _rowStaggerMs = 130;
  double _unfoldTotalMs = 1;

  // Repeating sweep that drives the profile-card loading shimmer. Runs only
  // while a fresh contact is resolving (started in _loadProfile, stopped in
  // _applyProfileData) so the screen goes idle once loaded.
  late final AnimationController _shimmerController;

  // Scroll controllers for left/right columns
  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();

  // Layout dimensions (captured from LayoutBuilder for use in tap handlers)
  double _treeWidth = 0;
  double _treeHeight = 0;

  // Column item dimensions
  static const double _avatarSize = 48.0;
  static const double _centerAvatarSize = 72.0;
  static const double _itemExtent = 71.0;
  static const double _columnWidth = 76.0;
  static const double _scrollPadding = 28.0;
  static const double _centerYFraction = 0.45;

  /// Per-navigation horizontal parallax step for the starfield (px). The far
  /// background nudges this far in the graph's flow direction on each fly and
  /// stays there (accumulates; the painter wraps so it never seams or drifts).
  static const double _bgParallaxStep = 40.0;
  // Starfield scroll: displayed value is lerp(from→target) over the fly's
  // easing; target persists after landing and seeds the next fly's `from`.
  double _bgScrollFrom = 0;
  double _bgScrollTarget = 0;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _transitionController.addStatusListener(_onTransitionStatus);
    _unfoldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420), // reset per load
    );
    _unfoldController.addListener(_onUnfoldTick);
    _unfoldController.addStatusListener(_onUnfoldStatus);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _leftScrollController.addListener(_onScrollChanged);
    _rightScrollController.addListener(_onScrollChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _searchController.addListener(_onSearchTextChanged);
    _loadProfile(widget.initialAddress);
    _checkCurrentUserCitizenship();
  }

  @override
  void dispose() {
    _transitionController.removeStatusListener(_onTransitionStatus);
    _transitionController.dispose();
    _unfoldController.removeListener(_onUnfoldTick);
    _unfoldController.removeStatusListener(_onUnfoldStatus);
    _unfoldController.dispose();
    _shimmerController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _leftScrollController.removeListener(_onScrollChanged);
    _rightScrollController.removeListener(_onScrollChanged);
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    setState(() {}); // Repaint lines + overflow indicators
  }

  void _onSearchFocusChanged() {
    if (!mounted) return;
    final focused = _searchFocusNode.hasFocus;
    if (focused != _searchFocused) {
      setState(() => _searchFocused = focused);
    }
  }

  void _onSearchTextChanged() {
    if (!mounted) return;
    final hasText = _searchController.text.isNotEmpty;
    if (hasText != _searchHasText) {
      setState(() => _searchHasText = hasText);
    }
  }

  void _onTransitionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _transition == null) return;
    // Animation has landed. If the fetch already resolved, the pending
    // payload is waiting — apply it now and both the tree swap and the
    // overlay removal happen in a single setState. If the fetch is still
    // running, leave the overlays frozen at their final pose; the fetch
    // path will call _applyProfileData directly when it resolves.
    if (_pendingData != null) {
      _applyProfileData(_pendingData!);
    }
  }

  void _onUnfoldTick() {
    if (mounted) setState(() {}); // drive the accordion + line-reveal fade
  }

  void _onUnfoldStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _unfolding) {
      // Snap back to fixed-extent rows once everything is open.
      setState(() => _unfolding = false);
    }
  }

  /// How far row [index] has accordion-opened (0 = closed, 1 = full), staggered
  /// top→bottom. Row 0 (the top contact) is the anchor and is always fully open.
  double _openFactor(int index) {
    if (!_unfolding || index == 0) return 1.0;
    final elapsedMs = _unfoldController.value * _unfoldTotalMs;
    final startMs = (index - 1) * _rowStaggerMs; // each row starts a bit later
    final raw = ((elapsedMs - startMs) / _rowOpenMs).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(raw);
  }

  Future<void> _checkCurrentUserCitizenship() async {
    final myAddress = AppStateNotifier.currentMyContact?.publicosAddress;
    if (myAddress == null) return;
    try {
      final citizen = await PublicOSAccounts.isCitizen(myAddress);
      if (mounted) setState(() => _currentUserIsCitizen = citizen);
    } catch (e) {
      debugPrint('TrustTree: Error checking citizenship: $e');
    }
  }

  Future<void> _loadProfile(EthereumAddress address,
      {bool asTransition = false}) async {
    // Direct load (first boot, search, MY TREE, vouch-reload) clears the
    // tree and shows the spinner. Transition load keeps the old tree
    // visible under the flying overlays — the swap is deferred until
    // _applyProfileData fires.
    setState(() {
      _isLoading = true;
      if (!asTransition) {
        _currentAddress = address;
        _vouchers = [];
        _vouchees = [];
        _resolvedVouchers.clear();
        _resolvedVouchees.clear();
        _profileContact = null;
        _transition = null;
        _pendingData = null;
        _pinAddress = null;
      }
    });

    // Fresh load (no old contact under the overlays) → run the card shimmer.
    if (!asTransition && !_shimmerController.isAnimating) {
      _shimmerController.repeat();
    }

    try {
      final results = await Future.wait([
        PublicOSAccounts.isCitizen(address),
        PublicOSAccounts.getVouchCount(address),
        PublicOSAccounts.getVouchersOf(address),
        PublicOSAccounts.getVoucheesOf(address),
        PublicOSGovernance.isOrgAccount(address),
        _resolveContact(address),
        PublicOSAccounts.getVouchThreshold(),
      ]);

      final isCitizen = results[0] as bool;
      final vouchCount = results[1] as BigInt;
      final vouchers = results[2] as List<EthereumAddress>;
      final vouchees = results[3] as List<EthereumAddress>;
      final isGroup = results[4] as bool;
      final contact = results[5] as Contact?;
      final vouchThreshold = results[6] as BigInt;

      bool hasVouched = false;
      final myAddress = AppStateNotifier.currentMyContact?.publicosAddress;
      if (myAddress != null &&
          address.eip55With0x.toLowerCase() !=
              myAddress.eip55With0x.toLowerCase()) {
        try {
          hasVouched = await PublicOSAccounts.hasVouched(myAddress, address);
        } catch (e) {
          debugPrint('TrustTree: Error checking vouch status: $e');
        }
      }

      EthereumAddress? groupCreator;
      if (isGroup) {
        try {
          groupCreator = await PublicOSGovernance.getOrgCreator(address);
        } catch (e) {
          debugPrint('TrustTree: Error getting group creator: $e');
        }
      }

      if (!mounted) return;

      final pending = _PendingProfileData(
        currentAddress: address,
        profileContact: contact,
        isCitizen: isCitizen,
        vouchCount: vouchCount,
        vouchThreshold: vouchThreshold,
        vouchers: vouchers,
        vouchees: vouchees,
        isGroup: isGroup,
        groupCreator: groupCreator,
        hasAlreadyVouched: hasVouched,
      );

      if (asTransition &&
          _transition != null &&
          !_transitionController.isCompleted) {
        // Animation still flying — stash and let the controller's completion
        // listener apply the payload. Guarantees the data swap and the
        // overlay removal land in the same frame.
        setState(() => _pendingData = pending);
      } else {
        _applyProfileData(pending);
      }
    } catch (e) {
      debugPrint('TrustTree: Error loading profile: $e');
      _shimmerController.stop();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _transition = null;
          _pendingData = null;
        });
      }
    }
  }

  void _applyProfileData(_PendingProfileData data) {
    if (!mounted) return;
    _shimmerController.stop(); // contact resolved — card shimmer off

    var vouchers = data.vouchers;
    var vouchees = data.vouchees;

    // Pin the last-visited account to the top of the column it flew into. Found
    // for every tap navigation (the relationship guarantees it); absent only via
    // the search box, which doesn't animate — in that case we just skip the pin.
    final pin = _pinAddress;
    // The pinned node is the old center that just flew into the column. We still
    // hold its resolved contact on the (about-to-be-cleared) transition — keep it
    // so the landed node stays resolved instead of flashing skeleton + address
    // while the column re-resolves from scratch.
    final pinContact = _transition?.outContact;
    if (pin != null) {
      final pinKey = pin.eip55With0x.toLowerCase();
      final target = _pinToLeft ? vouchers : vouchees;
      final idx =
          target.indexWhere((a) => a.eip55With0x.toLowerCase() == pinKey);
      if (idx > 0) {
        final reordered = List<EthereumAddress>.from(target)
          ..insert(0, target[idx])
          ..removeAt(idx + 1);
        if (_pinToLeft) {
          vouchers = reordered;
        } else {
          vouchees = reordered;
        }
      }
    }
    _pinAddress = null;

    setState(() {
      _currentAddress = data.currentAddress;
      _profileContact = data.profileContact;
      _isCitizen = data.isCitizen;
      _vouchCount = data.vouchCount;
      _vouchThreshold = data.vouchThreshold;
      _vouchers = vouchers;
      _vouchees = vouchees;
      _isGroup = data.isGroup;
      _groupCreator = data.groupCreator;
      _hasAlreadyVouched = data.hasAlreadyVouched;
      _resolvedVouchers.clear();
      _resolvedVouchees.clear();
      // Re-seed the just-animated node so it paints resolved on the landing
      // frame (no skeleton, no address flash). _resolveVouchers/_resolveVouchees
      // skip it since the key is now present.
      if (pin != null) {
        final m = _pinToLeft ? _resolvedVouchers : _resolvedVouchees;
        m[pin.eip55With0x.toLowerCase()] = pinContact;
      }
      _isLoading = false;
      _transition = null;
      _pendingData = null;
    });

    // Land both columns at the top so index 0 (the pinned avatar) sits exactly
    // where the fly-out ended. Only on a tap navigation (pin != null); direct
    // loads / search keep whatever scroll they had.
    if (pin != null) {
      if (_leftScrollController.hasClients) _leftScrollController.jumpTo(0);
      if (_rightScrollController.hasClients) _rightScrollController.jumpTo(0);
    }

    // Accordion-open the freshly loaded column(s) when there's more than one row
    // to fan out. The top contact is the anchor; the rest unfold from it.
    if (vouchers.length > 1 || vouchees.length > 1) {
      // Rows after the anchor, capped to the realistically visible count so a
      // huge column doesn't drag. Total run = all the stagger gaps + one open.
      final rows = (math.max(vouchers.length, vouchees.length) - 1).clamp(1, 9);
      _unfoldTotalMs = (rows - 1) * _rowStaggerMs + _rowOpenMs;
      _unfolding = true;
      _unfoldController.duration =
          Duration(milliseconds: _unfoldTotalMs.round());
      _unfoldController.forward(from: 0.0);
    } else {
      _unfolding = false;
      _unfoldController.value = 1.0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });

    final gen = ++_resolveGen;
    _resolveVouchers(vouchers, gen);
    _resolveVouchees(vouchees, gen);
  }

  Future<Contact?> _resolveContact(EthereumAddress address) async {
    try {
      final local = await PublicOSContacts.searchContacts(address.eip55With0x);
      if (local != null) return local;
      return await PublicOSContacts.fetchContact(address);
    } catch (e) {
      debugPrint('TrustTree: Error resolving contact: $e');
      return null;
    }
  }

  // Each contact lands on screen as soon as it resolves, so a column never
  // waits for its slowest contact. `gen` drops answers from a load that has
  // since been replaced (the maps are cleared and refilled for the new
  // center).
  void _resolveVouchers(List<EthereumAddress> vouchers, int gen) =>
      _resolveColumn(vouchers, _resolvedVouchers, gen);

  void _resolveVouchees(List<EthereumAddress> vouchees, int gen) =>
      _resolveColumn(vouchees, _resolvedVouchees, gen);

  void _resolveColumn(List<EthereumAddress> addrs,
      Map<String, Contact?> resolved, int gen) {
    for (final addr in addrs) {
      final key = addr.eip55With0x.toLowerCase();
      if (resolved.containsKey(key)) continue;
      _resolveContact(addr).then((contact) {
        if (!mounted || gen != _resolveGen) return;
        setState(() => resolved[key] = contact);
      });
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    final l10n = context.l10n;

    setState(() => _isSearching = true);

    try {
      EthereumAddress? address;

      if (query.startsWith('0x') && query.length == 42) {
        address = EthereumAddress.fromHex(query);
      } else {
        address =
            await PublicOSContacts.getPublicosAddressByPublicosDisplayName(
                query);
      }

      if (address != null && mounted) {
        _searchController.clear();
        FocusScope.of(context).unfocus();
        _loadProfile(address);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.trustTreeScreenAccountNotFound)),
        );
      }
    } catch (e) {
      debugPrint('TrustTree: Error searching: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(l10n, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _vouch() async {
    if (_isVouching || _currentAddress == null) return;
    final l10n = context.l10n;

    // A vouch is the one responsibility a citizen carries and it cannot be
    // taken back, so it is asked twice, the first time behind a countdown.
    final confirmed = await confirmVouch(
      context,
      _displayName(_profileContact, _currentAddress),
    );
    if (!confirmed || !mounted) return;

    setState(() => _isVouching = true);

    try {
      await HapticFeedback.lightImpact();
      final txHash = await PublicOSAccounts.vouch(_currentAddress!);

      // vouch() now waits for the tx receipt internally, so a non-null txHash
      // means the chain has committed. Reload reads the settled state — same
      // as a fresh landing on the subject (count + voucher list + badge).
      if (txHash != null && mounted) {
        await _loadProfile(_currentAddress!);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.trustTreeScreenVouchNotConfirmed)),
        );
      }
    } catch (e) {
      debugPrint('TrustTree: Error vouching: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(l10n, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isVouching = false);
    }
  }

  bool get _isViewingSelf {
    final myAddress = AppStateNotifier.currentMyContact?.publicosAddress;
    if (myAddress == null || _currentAddress == null) return true;
    return myAddress.eip55With0x.toLowerCase() ==
        _currentAddress!.eip55With0x.toLowerCase();
  }

  bool get _canVouch {
    // Gate on the viewed profile's *citizenship*, not their vouch count: a
    // citizen never needs another vouch, and count is decoupled from status
    // (a citizen can have 0 vouches).
    // Hide the button once they're already a citizen.
    return !_isViewingSelf &&
        _currentUserIsCitizen &&
        !_isCitizen &&
        !_hasAlreadyVouched;
  }

  String _truncateAddress(String address) {
    if (address.length < 12) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
  }

  String _displayName(Contact? contact, EthereumAddress? address) {
    if (contact != null) {
      final name = contact.publicosDisplayName ?? contact.displayName;
      if (name.isNotEmpty) return name;
    }
    if (address != null) return _truncateAddress(address.eip55With0x);
    return context.l10n.trustTreeScreenUnknown;
  }

  void _navigateToNode(
    EthereumAddress address,
    Contact? contact, {
    required double fromX,
    required double fromY,
    required bool fromLeft,
  }) {
    if (_transition != null) return; // already animating

    final centerX = _treeWidth / 2;
    final centerY = _treeHeight * _centerYFraction;
    // Outgoing flies to the OPPOSITE column from where the tap came — the old
    // center is guaranteed to live there (a tapped vouchee's vouchers include
    // the old center, and vice versa). We pin it to the TOP slot of that column
    // and aim the fly-out there, so when the new column renders the avatar is
    // already sitting exactly where it lands — no snap.
    final oppositeX =
        fromLeft ? (_treeWidth - _columnWidth / 2) : (_columnWidth / 2);
    const topSlotY = _scrollPadding + _avatarSize / 2;

    _pinAddress = _currentAddress;
    _pinToLeft = !fromLeft;

    setState(() {
      _transition = _TransitionData(
        inAddress: address,
        inContact: contact,
        inFromX: fromX,
        inFromY: fromY,
        inToX: centerX,
        inToY: centerY,
        outAddress: _currentAddress,
        outContact: _profileContact,
        outFromX: centerX,
        outFromY: centerY,
        outToX: oppositeX,
        outToY: topSlotY,
        fromLeft: fromLeft,
      );
      _pendingData = null;
    });
    // Parallax: the whole graph flows toward the side opposite the tapped
    // column (tap left → everything shifts right, and vice versa). Nudge the far
    // starfield the same way and let it stay — seeds from the last reached spot.
    _bgScrollFrom = _bgScrollTarget;
    _bgScrollTarget =
        _bgScrollFrom + (fromLeft ? _bgParallaxStep : -_bgParallaxStep);

    _transitionController.forward(from: 0.0);
    _loadProfile(address, asTransition: true);
  }

  /// Opens the focused account's full profile in the in-app browser — the same
  /// destination tapping a contact in the contacts view lands on
  /// (`AppNav.toContact` → `/profile/<address>`). Wired to the centered node and
  /// the top detail card. No-op mid-fly or before a profile has loaded; falls
  /// back to a by-address push while the contact is still resolving.
  void _openProfile() {
    final address = _currentAddress;
    if (address == null || _transition != null) return;
    HapticFeedback.lightImpact();
    final contact = _profileContact;
    if (contact != null) {
      AppNav.toContact(context, contact);
    } else {
      AppNav.toProfile(context, address.eip55With0x);
    }
  }

  // ---- Overflow & position helpers ----

  _OverflowCounts _getOverflowCounts(
      ScrollController controller, int totalItems) {
    if (!controller.hasClients || totalItems == 0) {
      return const _OverflowCounts(0, 0);
    }
    final offset = controller.offset;
    final viewport = controller.position.viewportDimension;

    final aboveCount =
        math.max(0, ((offset - _scrollPadding) / _itemExtent).floor());
    final belowStartIndex =
        ((offset + viewport - _scrollPadding) / _itemExtent).ceil();
    final belowCount = math.max(0, totalItems - belowStartIndex);

    return _OverflowCounts(
      aboveCount.clamp(0, totalItems),
      belowCount.clamp(0, totalItems),
    );
  }

  List<Offset> _getVisibleItemPositions(
    ScrollController controller,
    int totalItems,
    double columnCenterX,
    double areaHeight,
  ) {
    if (totalItems == 0) return [];
    final offset = controller.hasClients ? controller.offset : 0.0;
    final positions = <Offset>[];

    for (int i = 0; i < totalItems; i++) {
      final y = _scrollPadding + i * _itemExtent + _avatarSize / 2 - offset;
      if (y > -_avatarSize / 2 && y < areaHeight + _avatarSize / 2) {
        positions.add(Offset(columnCenterX, y));
      }
    }
    return positions;
  }

  // ---- Build methods ----

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    // Show the card as soon as we have an address — while the contact resolves
    // it renders a shimmer skeleton (see _buildDetailCard) instead of nothing.
    final showDetailCard = _currentAddress != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: tokens.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          // DESKTOP DELTA: no back button — this is an embedded shell pane
          // (rail → Social Graph), not a pushed route; there is nothing to pop.
          automaticallyImplyLeading: false,
          // The page's papercraft art beside the title, the same picture the
          // Apps tile shows (`SystemAppScaffold.asset`
          // does this for the pages built on the scaffold). Radius 9 at 28 px
          // like the rail's art; a failed decode just drops the picture.
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset(
                  'assets/system_apps/social_graph.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  cacheWidth: (28 * MediaQuery.devicePixelRatioOf(context)).round(),
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                context.l10n.trustTreeScreenAppBarTitle,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _transitionController,
                builder: (context, _) {
                  // Drift the starfield in sync with the fly easing; at rest the
                  // controller holds at its end so scrollX stays where it landed.
                  final scrollX = lerpDouble(
                    _bgScrollFrom,
                    _bgScrollTarget,
                    Curves.easeInOutCubic.transform(_transitionController.value),
                  )!;
                  return ConstellationBackground(scrollX: scrollX);
                },
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // DESKTOP DELTA: the search field + account card are phone-
                  // width elements; on a wide pane they'd stretch edge to
                  // edge, so both share one centered max-width column (the
                  // reading-column idea from the feeds pane).
                  Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _desktopCardMaxWidth),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: _buildSearchField(tokens),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: showDetailCard
                                ? Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(16, 0, 16, 4),
                                    // Tapping the account card opens its full
                                    // profile in the browser, same as the
                                    // centered node. The copy button + info
                                    // pills keep their own gestures; other taps
                                    // fall through to here.
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: _openProfile,
                                      child: _buildDetailCard(tokens),
                                    ),
                                  )
                                : const SizedBox(width: double.infinity),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _isLoading && _transition == null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: tokens.starkWhite,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  context.l10n.trustTreeScreenLoading,
                                  style: TextStyle(
                                    fontFamily: 'SpaceGrotesk',
                                    color: tokens.textDim,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            children: [
                              _buildTreeArea(tokens),
                              if (_transition != null)
                                _buildTransitionOverlay(tokens),
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom:
                                    12 + MediaQuery.of(context).padding.bottom,
                                child: AnimatedOpacity(
                                  opacity: _transition == null && !_isLoading
                                      ? 1.0
                                      : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: IgnorePointer(
                                    ignoring: _transition != null || _isLoading,
                                    child: _buildBottomActions(tokens),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(GlassTokens tokens) {
    final borderColor =
        _searchFocused ? tokens.borderMedium : tokens.borderSubtle;
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      onSubmitted: (_) => _performSearch(),
      textInputAction: TextInputAction.search,
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 14,
        color: tokens.starkWhite,
      ),
      cursorColor: tokens.starkWhite,
      decoration: InputDecoration(
        filled: true,
        fillColor: tokens.surfaceElevated,
        isDense: true,
        hintText: context.l10n.trustTreeScreenSearchHint,
        hintStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.textDim,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: tokens.textDim,
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIcon: _isSearching
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: tokens.starkWhite,
                  ),
                ),
              )
            : (_searchHasText
                ? InkResponse(
                    radius: 18,
                    onTap: () => _searchController.clear(),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: tokens.textDim,
                      ),
                    ),
                  )
                : null),
        suffixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderMedium, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDetailCard(GlassTokens tokens) {
    // First arrival / fresh load: contact not resolved yet → shimmer skeleton.
    // (During a tap transition _profileContact holds the old contact, so the
    // real card stays up — no shimmer there.)
    if (_isLoading && _profileContact == null) {
      return _buildDetailCardSkeleton(tokens);
    }

    final name = _displayName(_profileContact, _currentAddress);
    final address = _currentAddress?.eip55With0x ?? '';
    final shortAddress = _truncateAddress(address);
    // "count/threshold". Vouching stops at eligibility (VouchManager
    // "Target already eligible"), so a citizen's count IS what was needed when
    // they claimed — show it against itself. Anyone else: live count against
    // the current threshold. Orgs can't be vouched, so no pill.
    final vouchLabel = _isCitizen
        ? '$_vouchCount/$_vouchCount'
        : '$_vouchCount/$_vouchThreshold';
    final showVouchPill = !_isGroup;
    final showGroupChip = _isGroup && _groupCreator != null;
    final showVouchedChip = !_isViewingSelf && _hasAlreadyVouched;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: GlassTheme.glassBox(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 88,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ContactBanner(
                      contact: _profileContact,
                      fallback: _bannerFallback(tokens, _profileContact),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 10,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GlassContactIcon(
                            contact: _profileContact,
                            address: address.isNotEmpty ? address : null,
                            size: 44,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontFamily: 'SpaceGrotesk',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: tokens.starkWhite,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  shortAddress,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: tokens.starkWhite,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Row(
                  children: [
                    _buildSlimIconAction(
                      tokens,
                      icon: Icons.copy_rounded,
                      tooltip: context.l10n.trustTreeScreenCopyAddress,
                      onTap: address.isEmpty
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: address));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      context.l10n.trustTreeScreenAddressCopied),
                                ),
                              );
                            },
                    ),
                    const SizedBox(width: 8),
                    // Copy stays left; the pills hug the right edge with the
                    // vouch count last.
                    Expanded(
                      child: HorizontalWheel(child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Row(
                          children: [
                            if (showGroupChip) ...[
                              _infoPill(
                                tokens,
                                label: context.l10n.trustTreeScreenCreatedBy(
                                    _truncateAddress(
                                            _groupCreator!.eip55With0x)
                                        .toUpperCase()),
                                icon: Icons.group_rounded,
                              ),
                            ],
                            if (showVouchedChip) ...[
                              const SizedBox(width: 6),
                              _infoPill(
                                tokens,
                                label: context.l10n.trustTreeScreenVouched,
                                icon: Icons.check_circle_rounded,
                                color: tokens.connectedAccent,
                              ),
                            ],
                            if (showVouchPill) ...[
                              const SizedBox(width: 6),
                              _infoPill(
                                tokens,
                                label: vouchLabel,
                                bordered: false,
                                trailingIcon:
                                    _isCitizen ? Icons.check_rounded : null,
                                trailingColor: tokens.connectedAccent,
                              ),
                            ],
                          ],
                        ),
                      )),
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

  /// Loading state for the profile card — mirrors [_buildDetailCard]'s layout
  /// with shimmering placeholders so the card is present from first arrival and
  /// doesn't jump when the real data lands.
  Widget _buildDetailCardSkeleton(GlassTokens tokens) {
    final base = tokens.surfaceElevated;
    final highlight = Color.alphaBlend(
      tokens.starkWhite.withValues(alpha: 0.10),
      tokens.surfaceElevated,
    );
    Widget box(double h, {double w = double.infinity, double r = 8}) =>
        ShimmerBox(
          progress: _shimmerController,
          height: h,
          width: w,
          radius: r,
          base: base,
          highlight: highlight,
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: GlassTheme.glassBox(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 88,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    box(88, r: 0),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 10,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          box(44, w: 44, r: 44 * 0.40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                box(16, w: 120, r: 5),
                                const SizedBox(height: 6),
                                box(11, w: 90, r: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Row(
                  children: [
                    box(32, w: 32, r: 6),
                    const Spacer(),
                    box(32, w: 64, r: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bannerFallback(GlassTokens tokens, Contact? contact) {
    final base = contact?.iconColor ?? tokens.connectedAccent;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base.withValues(alpha: 0.25), tokens.surfaceDeep],
        ),
      ),
    );
  }

  Widget _infoPill(
    GlassTokens tokens, {
    required String label,
    IconData? icon,
    Color? color,
    bool bordered = true,
    IconData? trailingIcon,
    Color? trailingColor,
  }) {
    final fg = color ?? tokens.textDim;
    // Same 32px height as the copy button beside it.
    return Container(
      height: 32,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: tokens.glassFillHover,
        borderRadius: BorderRadius.circular(6),
        border: bordered
            ? Border.all(
                color: color != null
                    ? color.withValues(alpha: 0.4)
                    : tokens.borderSubtle,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: fg,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 4),
            Icon(trailingIcon, size: 13, color: trailingColor ?? fg),
          ],
        ],
      ),
    );
  }

  Widget _buildSlimIconAction(
    GlassTokens tokens, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.glassFillHover,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: tokens.borderMedium),
          ),
          child: Icon(icon, color: tokens.starkWhite, size: 14),
        ),
      ),
    );
  }

  Widget _buildTreeArea(GlassTokens tokens) {
    return LayoutBuilder(builder: (context, constraints) {
      final W = constraints.maxWidth;
      final H = constraints.maxHeight;
      _treeWidth = W;
      _treeHeight = H;

      final centerX = W / 2;
      final centerY = H * _centerYFraction;

      final leftPositions = _getVisibleItemPositions(
        _leftScrollController,
        _vouchers.length,
        _columnWidth / 2,
        H,
      );
      final rightPositions = _getVisibleItemPositions(
        _rightScrollController,
        _vouchees.length,
        W - _columnWidth / 2,
        H,
      );

      final inTransition = _transition != null;

      // While a column is unfolding, its rows are mid-flight and don't match the
      // fixed-extent positions the painter uses — so hold the lines back and
      // fade them in only over the tail of the unfold, once rows are near home.
      final lineReveal = _unfolding
          ? ((_unfoldController.value - 0.55) / 0.45).clamp(0.0, 1.0)
          : 1.0;

      return Stack(
        children: [
          // Layer 1: bezier connector lines — suppressed during transition
          // (trust graph is mid-rewrite; overlays carry the motion instead).
          if (!inTransition &&
              lineReveal > 0 &&
              (_vouchers.isNotEmpty || _vouchees.isNotEmpty))
            CustomPaint(
              size: Size(W, H),
              painter: _TrustLinePainter(
                center: Offset(centerX, centerY),
                leftPositions: leftPositions,
                rightPositions: rightPositions,
                color: tokens.starkWhite,
                reveal: lineReveal,
              ),
            ),

          // Layer 2: left column (vouchers)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _columnWidth,
            child: _buildScrollColumn(
              tokens,
              items: _vouchers,
              resolvedContacts: _resolvedVouchers,
              scrollController: _leftScrollController,
              isLeft: true,
            ),
          ),

          // Layer 3: right column (vouchees)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: _columnWidth,
            child: _buildScrollColumn(
              tokens,
              items: _vouchees,
              resolvedContacts: _resolvedVouchees,
              scrollController: _rightScrollController,
              isLeft: false,
            ),
          ),

          // Layer 4: center avatar + name — hidden during transition, the
          // outgoing overlay flies out from this same spot (carrying its name).
          if (!inTransition)
            Positioned(
              left: centerX - _columnWidth / 2,
              top: centerY - _centerAvatarSize / 2,
              width: _columnWidth,
              // Tapping the focal node opens its full profile in the browser —
              // same as tapping a contact in the contacts view. (Column items
              // re-center the tree via _navigateToNode; the center node is
              // already centered, so its tap is the "open profile" action.)
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openProfile,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCenterAvatar(tokens),
                    const SizedBox(height: 4),
                    _nodeName(
                      tokens,
                      _displayName(_profileContact, _currentAddress),
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildScrollColumn(
    GlassTokens tokens, {
    required List<EthereumAddress> items,
    required Map<String, Contact?> resolvedContacts,
    required ScrollController scrollController,
    required bool isLeft,
  }) {
    if (items.isEmpty) {
      return Center(
        child: RotatedBox(
          quarterTurns: isLeft ? 3 : 1,
          child: Text(
            isLeft
                ? context.l10n.trustTreeScreenNoVouchers
                : context.l10n.trustTreeScreenNoVouchees,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: tokens.textDim.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    final overflow = _getOverflowCounts(scrollController, items.length);

    return Stack(
      children: [
        ListView.builder(
          controller: scrollController,
          itemCount: items.length,
          // Fixed extent normally; null while unfolding so rows can grow and
          // push each other down (each row pins itself back to _itemExtent).
          itemExtent: _unfolding ? null : _itemExtent,
          padding: const EdgeInsets.symmetric(vertical: _scrollPadding),
          itemBuilder: (context, index) {
            final addr = items[index];
            final key = addr.eip55With0x.toLowerCase();
            final contact = resolvedContacts[key];
            final isResolved = resolvedContacts.containsKey(key);

            return _buildColumnItem(
              tokens,
              index: index,
              address: addr,
              contact: contact,
              isResolved: isResolved,
              onTap: () {
                final fromX =
                    isLeft ? _columnWidth / 2 : _treeWidth - _columnWidth / 2;
                final fromY = _scrollPadding +
                    index * _itemExtent +
                    _avatarSize / 2 -
                    (scrollController.hasClients ? scrollController.offset : 0);
                _navigateToNode(
                  addr,
                  contact,
                  fromX: fromX,
                  fromY: fromY,
                  fromLeft: isLeft,
                );
              },
            );
          },
        ),
        // Overflow counts are transient while rows are still growing — show the
        // pills only once the unfold has settled.
        if (!_unfolding && overflow.above > 0)
          Positioned(
            top: 2,
            left: 0,
            right: 0,
            child: Center(child: _buildOverflowPill(tokens, overflow.above)),
          ),
        if (!_unfolding && overflow.below > 0)
          Positioned(
            bottom: 2,
            left: 0,
            right: 0,
            child: Center(child: _buildOverflowPill(tokens, overflow.below)),
          ),
      ],
    );
  }

  Widget _buildColumnItem(
    GlassTokens tokens, {
    required int index,
    required EthereumAddress address,
    required Contact? contact,
    required bool isResolved,
    required VoidCallback onTap,
  }) {
    // Hide the tapped item while its overlay flies to center — prevents the
    // "avatar visible in two places at once" flicker during the handoff.
    final isFlying = _transition != null &&
        _transition!.inAddress.eip55With0x.toLowerCase() ==
            address.eip55With0x.toLowerCase();

    Widget content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _avatarSize,
            height: _avatarSize,
            child: isResolved
                ? GlassContactIcon(
                    contact: contact,
                    address: address.eip55With0x,
                    size: _avatarSize,
                  )
                : _buildAvatarSkeleton(tokens, _avatarSize),
          ),
          const SizedBox(height: 4),
          _nodeName(tokens, _displayName(contact, address)),
        ],
      ),
    );

    if (_unfolding) {
      // Pin each row back to the slot extent (the ListView's itemExtent is null
      // while unfolding) and accordion-open it from the top — clipping the row
      // open downward so it pushes the rows beneath it down.
      content = SizedBox(height: _itemExtent, child: content);
      final o = _openFactor(index);
      if (o < 1.0) {
        content = ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: o,
            child: Opacity(opacity: o, child: content),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isFlying ? 0.0 : 1.0,
        child: content,
      ),
    );
  }

  Widget _buildAvatarSkeleton(GlassTokens tokens, double size) {
    final radius = size * (14 / 44);
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: tokens.textDim,
        ),
      ),
    );
  }

  Widget _buildOverflowPill(GlassTokens tokens, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Text(
        context.l10n.trustTreeScreenMoreCount(count),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: 0.3,
          color: tokens.textDim,
        ),
      ),
    );
  }

  /// The display-name label under a node avatar — shared by column items, the
  /// center node, and the flying overlay so the name is continuous (never pops)
  /// as an avatar travels in/out of the center. [fontSize] lerps with the
  /// avatar size during the fly.
  Widget _nodeName(GlassTokens tokens, String name, {double fontSize = 10}) {
    return SizedBox(
      width: _columnWidth - 4,
      child: Text(
        name,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: tokens.starkWhite,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCenterAvatar(GlassTokens tokens) {
    const radius = _centerAvatarSize * (14 / 44);
    // Drop shadow only — no outer ring. GlassContactIcon already draws its own
    // shape and border (squircle for individuals, sharper for orgs); wrapping it
    // in a framed, clipped Container stamped a second, squarer ring that read as
    // a stray circle around the avatar.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: tokens.glassShadow,
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: _profileContact != null || _currentAddress != null
          ? GlassContactIcon(
              contact: _profileContact,
              address: _currentAddress?.eip55With0x,
              size: _centerAvatarSize,
            )
          : Container(
              width: _centerAvatarSize,
              height: _centerAvatarSize,
              decoration: BoxDecoration(
                color: tokens.surfaceElevated,
                borderRadius: BorderRadius.circular(radius),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.person_rounded,
                color: tokens.starkWhite,
                size: 30,
              ),
            ),
    );
  }

  Widget _buildTransitionOverlay(GlassTokens tokens) {
    final data = _transition!;
    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(
          _transitionController.value,
        );

        return Stack(
          children: [
            // Incoming — tapped item growing into the center.
            // Its drop shadow fades IN as it arrives so it settles into the
            // center avatar's lifted look.
            _flyingAvatar(
              tokens,
              fromX: data.inFromX,
              fromY: data.inFromY,
              toX: data.inToX,
              toY: data.inToY,
              fromSize: _avatarSize,
              toSize: _centerAvatarSize,
              contact: data.inContact,
              address: data.inAddress,
              t: t,
              haloAlphaAtStart: 0.0,
              haloAlphaAtEnd: 1.0,
            ),
            // Outgoing — old center shrinking to the opposite column.
            // Its drop shadow fades OUT so it settles into a flat column item.
            if (data.outAddress != null)
              _flyingAvatar(
                tokens,
                fromX: data.outFromX,
                fromY: data.outFromY,
                toX: data.outToX,
                toY: data.outToY,
                fromSize: _centerAvatarSize,
                toSize: _avatarSize,
                contact: data.outContact,
                address: data.outAddress!,
                t: t,
                haloAlphaAtStart: 1.0,
                haloAlphaAtEnd: 0.0,
              ),
            // If the animation has landed but the fetch hasn't resolved,
            // park a small spinner under the incoming overlay so the user
            // knows we're still loading.
            // if (_transitionController.isCompleted && _pendingData == null)
            //   Positioned(
            //     left: data.inToX - 10,
            //     top: data.inToY + _centerAvatarSize / 2 + 36,
            //     child: SizedBox(
            //       width: 20,
            //       height: 20,
            //       child: CircularProgressIndicator(
            //         strokeWidth: 1.5,
            //         color: tokens.starkWhite,
            //       ),
            //     ),
            //   ),
          ],
        );
      },
    );
  }

  Widget _flyingAvatar(
    GlassTokens tokens, {
    required double fromX,
    required double fromY,
    required double toX,
    required double toY,
    required double fromSize,
    required double toSize,
    required Contact? contact,
    required EthereumAddress address,
    required double t,
    required double haloAlphaAtStart,
    required double haloAlphaAtEnd,
  }) {
    final x = lerpDouble(fromX, toX, t)!;
    final y = lerpDouble(fromY, toY, t)!;
    final size = lerpDouble(fromSize, toSize, t)!;
    final radius = size * (14 / 44);
    final haloAlpha = lerpDouble(haloAlphaAtStart, haloAlphaAtEnd, t)!;
    // Name size tracks the avatar size (10 at a column row → 12 at center) so it
    // matches both endpoints and never pops on handoff.
    final nameSize = 10 +
        ((size - _avatarSize) / (_centerAvatarSize - _avatarSize) * 2)
            .clamp(0.0, 2.0);

    // Centre the avatar+name in a column-width slot so the avatar's centre stays
    // on (x, y) regardless of the (wider) name beneath it.
    return Positioned(
      left: x - _columnWidth / 2,
      top: y - size / 2,
      width: _columnWidth,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color:
                        tokens.glassShadow.withValues(alpha: 0.5 * haloAlpha),
                    offset: const Offset(0, 4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: GlassContactIcon(
                contact: contact,
                address: address.eip55With0x,
                size: size,
                // Decode once at the destination size, not the per-frame
                // animated size — otherwise ZeroCachedImage re-resolves every
                // frame and strobes back to the initials placeholder. Pinning to
                // the landing size also warms the cache so the handoff to the
                // real node is a mem-cache hit (no flash).
                decodeSize: toSize,
              ),
            ),
            const SizedBox(height: 4),
            _nodeName(
              tokens,
              _displayName(contact, address),
              fontSize: nameSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(GlassTokens tokens) {
    final showHomeButton = !_isViewingSelf;
    if (!showHomeButton && !_canVouch) return const SizedBox.shrink();

    return Row(
      children: [
        if (showHomeButton) ...[
          _greyPillButton(
            tokens: tokens,
            icon: Icons.home_rounded,
            label: context.l10n.trustTreeScreenMyTree,
            enabled: true,
            onTap: () {
              final myAddr = AppStateNotifier.currentMyContact?.publicosAddress;
              if (myAddr != null) _loadProfile(myAddr);
            },
          ),
          const SizedBox(width: 8),
        ],
        if (_canVouch)
          Expanded(
            child: _greyPillButton(
              tokens: tokens,
              icon: _isVouching ? null : Icons.verified_rounded,
              label: _isVouching
                  ? context.l10n.trustTreeScreenVouching
                  : context.l10n.trustTreeScreenVouchFor(
                      _displayName(_profileContact, _currentAddress)
                          .toUpperCase()),
              enabled: !_isVouching,
              onTap: _vouch,
              loading: _isVouching,
            ),
          ),
      ],
    );
  }

  Widget _greyPillButton({
    required GlassTokens tokens,
    required IconData? icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return Material(
      color: enabled ? tokens.surfaceElevated : tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: enabled ? tokens.borderMedium : tokens.borderSubtle,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: tokens.textDim,
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 14, color: tokens.starkWhite),
              if (loading || icon != null) const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: enabled ? tokens.starkWhite : tokens.textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustLinePainter extends CustomPainter {
  final Offset center;
  final List<Offset> leftPositions;
  final List<Offset> rightPositions;
  final Color color;

  /// Global multiplier (0..1) used to fade all lines in over the tail of the
  /// column unfold. 1 in steady state.
  final double reveal;

  /// Peak stroke opacity, reached once a node has scrolled into the middle band.
  static const double _peakAlpha = 0.24;

  /// Fraction of the height over which a line fades in/out as its node nears an
  /// edge. The fade completes (full opacity) by this fraction from the top —
  /// well before the vertical middle — and mirrors at the bottom.
  static const double _rampFraction = 0.35;

  _TrustLinePainter({
    required this.center,
    required this.leftPositions,
    required this.rightPositions,
    required this.color,
    this.reveal = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final pos in leftPositions) {
      _drawBezier(canvas, center, pos, size.height);
    }
    for (final pos in rightPositions) {
      _drawBezier(canvas, center, pos, size.height);
    }
  }

  /// Per-line opacity tied to its *node* endpoint's vertical position, so the
  /// whole line fades in as its contact scrolls down into the column and fades
  /// back out as the contact approaches the opposite edge. It reaches 0 at the
  /// top/bottom of the area — before the node is culled (cull margin is one
  /// half-avatar beyond the edge) — so a line never pops in or out: it's already
  /// invisible by the time it stops being drawn. Ease-out ramp (steep at the
  /// edge, easing into the plateau), full by [_rampFraction] of the height,
  /// solid through the middle band, mirrored at the bottom.
  double _nodeFade(double y, double height) {
    if (height <= 0) return 0;
    final ramp = height * _rampFraction;
    double x;
    if (y <= ramp) {
      x = y / ramp; // entering from the top
    } else if (y >= height - ramp) {
      x = (height - y) / ramp; // approaching the bottom
    } else {
      x = 1.0; // middle band — fully opaque
    }
    x = x.clamp(0.0, 1.0);
    return 1 - (1 - x) * (1 - x);
  }

  void _drawBezier(Canvas canvas, Offset from, Offset to, double height) {
    final a = _nodeFade(to.dy, height) * _peakAlpha * reveal;
    if (a <= 0.004) return;

    final paint = Paint()
      ..color = color.withValues(alpha: a)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(from.dx, from.dy);
    final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len > 0) {
      final perpX = -dy / len * 12;
      final perpY = dx / len * 12;
      path.quadraticBezierTo(mid.dx + perpX, mid.dy + perpY, to.dx, to.dy);
    } else {
      path.lineTo(to.dx, to.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrustLinePainter old) =>
      old.center != center ||
      old.leftPositions != leftPositions ||
      old.rightPositions != rightPositions ||
      old.color != color ||
      old.reveal != reveal;
}

/// Snapshot captured at tap time — both the incoming (tapped) avatar and
/// the outgoing (previous center) avatar fly on the same controller. The
/// tree underneath holds its old data for the full animation; the swap to
/// the new profile happens atomically when _applyProfileData fires.
class _TransitionData {
  // Incoming: tapped column item → center.
  final EthereumAddress inAddress;
  final Contact? inContact;
  final double inFromX, inFromY;
  final double inToX, inToY;

  // Outgoing: previous center → opposite column.
  final EthereumAddress? outAddress;
  final Contact? outContact;
  final double outFromX, outFromY;
  final double outToX, outToY;

  // true = tap came from the left (vouchers) column.
  final bool fromLeft;

  const _TransitionData({
    required this.inAddress,
    required this.inContact,
    required this.inFromX,
    required this.inFromY,
    required this.inToX,
    required this.inToY,
    required this.outAddress,
    required this.outContact,
    required this.outFromX,
    required this.outFromY,
    required this.outToX,
    required this.outToY,
    required this.fromLeft,
  });
}

/// Fetched profile data held off-screen until the transition controller
/// finishes. Applying it calls one setState that flips the whole tree to
/// the new focus and removes the overlays in the same frame — no flicker.
class _PendingProfileData {
  final EthereumAddress currentAddress;
  final Contact? profileContact;
  final bool isCitizen;
  final BigInt vouchCount;
  final BigInt vouchThreshold;
  final List<EthereumAddress> vouchers;
  final List<EthereumAddress> vouchees;
  final bool isGroup;
  final EthereumAddress? groupCreator;
  final bool hasAlreadyVouched;

  const _PendingProfileData({
    required this.currentAddress,
    required this.profileContact,
    required this.isCitizen,
    required this.vouchCount,
    required this.vouchThreshold,
    required this.vouchers,
    required this.vouchees,
    required this.isGroup,
    required this.groupCreator,
    required this.hasAlreadyVouched,
  });
}

class _OverflowCounts {
  final int above;
  final int below;
  const _OverflowCounts(this.above, this.below);
}
