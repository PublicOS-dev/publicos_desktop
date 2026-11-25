import 'dart:async';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import '../data/shell_prefs.dart';
import '../theme/glass_tokens.dart';
import '../theme/shell_tones.dart';
import '../utils/notification_sound.dart';
import '../utils/social_notifs.dart';
import '../widgets/bsp_dialog.dart';
import '../widgets/chat_appearance.dart';
import '../widgets/constellation_background.dart';
import '../widgets/keychain_dialog.dart';
import '../widgets/chat_no_key_state.dart' show xmtpKeyEpoch;
import '../widgets/wallet_dialog.dart';
import '../widgets/shell_morph.dart';
import '../widgets/shell_split.dart';
import '../widgets/sidebar.dart';
import '../widgets/ssp_dialog.dart';
import '../widgets/status_bar.dart';
import '../router_helpers.dart';
import 'package:publicos_desktop/widgets/onboarding/onboarding_flow.dart';
import 'package:publicos_desktop/utils/notification_kinds.dart';
import 'package:publicos_desktop/utils/own_wallets.dart';
import 'package:publicos_desktop/widgets/notifications_dialog.dart';
import 'contacts_pane.dart';
import 'account_center_page.dart';
import 'node_page.dart';
import 'treasury_page.dart';
import 'graph_pane.dart';
import 'messages_pane.dart';
import 'feature_placeholder.dart';
import 'feeds_pane.dart';
import '../widgets/feeds/feed_source.dart';
import 'settings_pane.dart';
import '../utils/app_history.dart';
import '../utils/app_update.dart';
import '../widgets/apps_dialog.dart';
import '../utils/deep_links.dart';

/// The desktop home — the multi-pane shell that is reached after login. A glass
/// sidebar (brand + self user-card + nav + live connection footer) drives a
/// single content pane via an index switch (desktop-idiomatic; no router).
///
/// The frame is real and live; a feature destination with no pane of its own
/// renders a [FeaturePlaceholder]. The Core calls behind the chrome:
///   - the self contact: `PublicOSContacts.getContact(...)` seeded from
///     `PublicOS.myPublicosAddress`, then kept fresh via the
///     `PublicOS.selfContactUpdates` domain-event stream.
///   - the block number: `PublicOSBsp.getBlockNumber()`.
class AppShell extends StatefulWidget {
  /// Returns to account selection.
  final VoidCallback onLogout;

  const AppShell({super.key, required this.onLogout});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // BSP / SSP open as big dialogs, not panes —
  // their nav rows intercept in onSelect instead of switching the pane.
  static const int _bspIndex = 6;
  static const int _sspIndex = 7;
  static const int _treasuryIndex = 5;
  static const int _walletsIndex = 4;

  /// Nodes (index 8) — the client's `node_page.dart` mounted directly as a
  /// pane.
  static const int _nodesIndex = 8;

  /// Account (appended index 12) — the client's `account_center_page.dart`.
  /// Its own rail row rather than the user chip: the chip keeps opening
  /// Contacts-focused-on-self.
  static const int _accountIndex = 12;

  /// **My Account** (the sidebar's self user-card) is not a pane of its own — it
  /// routes to Contacts with the user's own profile focused. Your account isn't
  /// one of your contacts (the list filters self out), so the row highlights
  /// Contacts and the detail pane shows you.
  static const int _myAccountIndex = 0;
  static const int _contactsIndex = 1;
  static const int _messagesIndex = 2;
  static const int _feedsIndex = 3;

  // Index 10 is unused: orgs live in Contacts behind the Personal/Orgs chips.
  // The slot stays defined in kShellDestinations (positional) but is off the
  // rail and routes nowhere.

  /// Social Graph (appended index 11; an APP — Apps dialog tile + rail
  /// history, no rail row, see `kSystemApps`) — the trust-tree canvas,
  /// hosted by GraphPane.
  static const int _graphIndex = 11;

  /// Land on Contacts-focused-on-self (My Account).
  int _selectedIndex = _contactsIndex;

  /// One GlobalKey per destination so [ShellMorph] can move a pane between
  /// Stack slots (over / under the other one) during a transition without
  /// remounting it — the outgoing pane keeps rendering its real content
  /// while it slides, the incoming keeps what it loaded.
  final Map<int, GlobalKey> _paneKeys = {};

  /// ONE focus intent for the Contacts pane: [_focusContact] null = focus SELF
  /// (My Account), non-null = focus that contact (`AppNav.toContact` /
  /// `toProfile`). [_focusToken] bumps on every request so the pane re-focuses
  /// even when already mounted showing someone else. Starts at 1 with a null
  /// contact so first paint lands on the user's own profile.
  ///
  /// Deliberately a single (contact, token) pair, NOT two parallel tokens: a
  /// self token starting at 1 plus a separate contact token would let a fresh
  /// ContactsPane mount see BOTH as pending — its async self-focus would
  /// resolve after the synchronous contact-focus and stomp it, so a mention/
  /// author tap from Feeds would always land on the user's own profile. One
  /// pair = only the LATEST intent exists to apply.
  Contact? _focusContact;
  int _focusToken = 1;

  /// Rides [_focusContact] for an Apps landing (`AppNav.toApp`): the app tab
  /// the Browser lands on. Cleared by every other focus path so a later
  /// contact/self focus never replays a stale app landing.
  AppBookmark? _focusApp;

  /// Rides [_focusContact] for a `/publicosAddress/:a/tab/:key` deep link: the
  /// router record key the Browser should land on. Cleared by every other
  /// focus path, exactly like [_focusApp], so a later focus never replays a
  /// stale tab landing.
  String? _focusTabKey;

  /// A feed to open on its own in the Feeds pane (`AppNav.onOpenFeedUrl`, a
  /// post's "Go to feed"). Its own token: FeedsPane remounts on every visit,
  /// so it applies a token once and ignores it after.
  FeedSource? _focusFeed;
  int _feedFocusToken = 0;

  /// The rail's "last visited apps" (Core history via [RecentApps]).
  List<AppBookmark> _recentApps = const [];

  Contact? _myContact;
  String? _myAddress;

  // ── XMTP chip state (status bar) ──────────────────────────────────────────
  /// Keychain emoji of the active messaging key (`currentXmtpKeyLabel`).
  String? _xmtpKeyEmoji;
  /// Label the active inbox is bound to in the account's on-chain inbox
  /// directory; null = not registered (or nothing loaded).
  String? _inboxRegisteredLabel;
  /// Display name of the org whose directory holds the active inbox, when
  /// the active key is an org key; null = the inbox is mine.
  String? _inboxOrgName;

  /// Bumped when the ACTIVE messaging key changes from here (the status bar's
  /// keychain). Conversations, their topics and their unread state all belong
  /// to the loaded inbox, so the Messages pane must start over rather than
  /// keep showing the previous key's list. Opening the
  /// keychain from inside Messages is already handled there.
  int _messagesEpoch = 0;
  bool _inboxLookupDone = false;

  // ── Provider indicator state (client explorer pattern) ────────────────────
  /// null = checking, true = up, false = down.
  bool? _chainReachable;
  String _rpcSource = 'public';
  String? _chainName;
  String? _chainHost;

  bool? _sspReachable;
  String _sspSource = 'default';
  String? _sspName;
  String? _sspHost;

  Timer? _networkTimer;
  StreamSubscription<Contact>? _selfSub;

  // ── On-chain notifications (ported from publicos_client) ──────────────────
  //
  // The bell badge is fed by TWO sweeps on deliberately separate timers, the
  // same as the client's explorer (`pages/explorer.dart`):
  //
  //   * contract events (vouch / citizenship / domain / profile) — slow. A
  //     profile edit is not time-critical.
  //   * wallet transfers (own Safes + walletEnabled keychain EOAs) — fast.
  //     "You got paid" should feel closer to a message than to a profile edit.
  //
  // COST NOTE, because it is the dial that matters: a wallet sweep
  // is exactly TWO getLogs calls no matter how many wallets are watched, so 30s
  // costs ~4 calls/min per user. Affordable per client, NOT necessarily for the
  // node as users grow — the multiplier is per-user and the node is a
  // read-dominant social DB. Raising _walletSweepInterval is a one-literal fix.
  static const Duration _walletSweepInterval = Duration(seconds: 30);
  static const Duration _activitySweepInterval = Duration(minutes: 10);

  int _unreadCount = 0;
  Timer? _activityTimer;
  Timer? _walletTimer;
  // A sweep can still be in flight when the next tick fires (a cold-start
  // backfill walks many windows). Without this, ticks stack and each re-scans
  // the same range.
  bool _walletSweepInFlight = false;

  // Message chime: suppress during the initial sync burst, then ring on
  // incoming content messages (see _maybePlayChime).
  StreamSubscription<Message>? _chimeSub;
  bool _chimeReady = false;

  /// Messages rail badge: incoming messages that arrived while the Messages
  /// pane was NOT showing. In-memory only — starts at 0 every launch (no seed
  /// from `getUnreadCounts()`: that counts per-conversation unread, a
  /// different question, and would resurrect every launch). Cleared on any
  /// entry into Messages, whether or not the unread chats get opened.
  int _messagesBadge = 0;

  /// First-run gate (client parity with `explorer.dart`):
  /// null = not read yet, true = render [OnboardingFlow] instead of the shell.
  bool? _needsOnboarding;

  @override
  void initState() {
    super.initState();
    _myAddress = PublicOS.myPublicosAddress;
    _checkOnboarding();
    _ensurePublicosOnboarded();
    _loadMyContact();
    _loadXmtpIdentity();
    _startActivitySweeps();
    // Self-update check: off in debug builds (no build id), never blocks boot.
    AppUpdate.start();

    // Desktop's stand-in for the client's router. Ported widgets call
    // `AppNav.toContact(...)` (tap a post's author avatar) and `AppNav.toTreasury(...)`
    // (an SSP gate refused a write); the client pushes routes, the shell swaps
    // panes. Registering here keeps those widgets byte-identical to the client.
    AppNav.onOpenContact = (contact) {
      if (!mounted) return;
      setState(() {
        // Orgs and individuals share the Contacts pane.
        _selectedIndex = _contactsIndex;
        _focusContact = contact;
        _focusApp = null;
        _focusTabKey = null;
        _focusToken++;
      });
    };
    // Apps landing: same focus, plus the app tab to land on —
    // the client's "open an app = the owner's profile at the app tab".
    AppNav.onOpenApp = (owner, app) {
      if (!mounted) return;
      setState(() {
        _selectedIndex = _contactsIndex;
        _focusContact = owner;
        _focusApp = app;
        _focusTabKey = null;
        _focusToken++;
      });
    };
    // Custom-tab landing (`AppNav.toTab`): same focus shape as the
    // apps landing, carrying the router record key instead of a bookmark.
    AppNav.onOpenTab = (owner, tabKey) {
      if (!mounted) return;
      setState(() {
        _selectedIndex = _contactsIndex;
        _focusContact = owner;
        _focusApp = null;
        _focusTabKey = tabKey;
        _focusToken++;
      });
    };
    // Go to feed with no tab to land on: the
    // Feeds pane, reading that one feed.
    AppNav.onOpenFeedUrl = (url, title, foundAt, recordKey) {
      if (!mounted) return;
      setState(() {
        _selectedIndex = _feedsIndex;
        _focusFeed = FeedSource(
          url: url,
          title: title,
          foundAtAccountAddress: foundAt,
          recordKey: recordKey,
        );
        _feedFocusToken++;
      });
    };
    // A deep link can arrive before this shell exists -- Windows activates the
    // app with a URL long before Flutter mounts, and while the account picker
    // is up nobody is signed in. `DeepLinks` holds those, and this is the first
    // instant a dispatch has somewhere to land: the AppNav callbacks above are
    // registered, so the no-op branch cannot swallow the URL.
    // Post-frame so the navigator exists too (AppNav.toApp pops dialogs).
    WidgetsBinding.instance
        .addPostFrameCallback((_) => DeepLinks.flushPending());
    RecentApps.instance.addListener(_onRecentApps);
    // Load, then (first run only) seed Treasury · Social Graph · Nodes into
    // the history so users find them.
    RecentApps.instance
        .load()
        .then((_) => RecentApps.instance.seedSystemAppsOnce());
    AppNav.onOpenDestination = (index) {
      if (!mounted) return;
      _showDestination(index);
    };
    AppNav.onShowFeeds = () {
      if (!mounted) return;
      _showDestination(_feedsIndex);
    };

    // Self-profile changes (avatar / name / records) repaint the user card.
    // This is a domain-event stream carrying the Contact, not a "please reload"
    // ping — consumed directly, the blessed pattern (see Core selfContactUpdates).
    _selfSub = PublicOS.selfContactUpdates.listen((contact) {
      if (!mounted) return;
      setState(() {
        _myContact = contact;
        _myAddress = contact.publicosAddress?.eip55With0x ?? _myAddress;
      });
    });

    _pollChainStatus();
    _networkTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _pollChainStatus(),
    );
    _loadProviderStatus();

    // Chat appearance overrides — loaded once so message bubbles read them
    // synchronously from the first build (widgets/chat_appearance.dart).
    ChatAppearance.instance.load();

    // Message chime: bell on every incoming content message, all
    // conversations. The 4s gate suppresses the initial sync burst — without
    // it history replay on boot rings the bell.
    NotificationSound.instance.init();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _chimeReady = true;
    });
    _chimeSub = PublicOS.messageStream.listen(_onIncomingMessage);
  }

  /// Old app_shell `_maybePlayChime`, verbatim rules: only incoming messages
  /// from others, only content types — never reactions, receipts, or system
  /// messages. (Rate limiting lives inside NotificationSound: 2s.) The same
  /// gate feeds the Messages rail badge, which counts every message — not
  /// every chime — and keeps counting with the chime muted.
  void _onIncomingMessage(Message message) {
    if (!_chimeReady) return;
    if (message.senderInboxId == PublicOS.clientXmtpInboxId) return;
    switch (message.content.type) {
      case MessageType.text:
      case MessageType.attachment:
      case MessageType.remoteAttachment:
      case MessageType.reply:
        NotificationSound.instance.play();
        if (mounted && _selectedIndex != _messagesIndex) {
          setState(() => _messagesBadge++);
        }
      default:
        break;
    }
  }

  @override
  void dispose() {
    RecentApps.instance.removeListener(_onRecentApps);
    _networkTimer?.cancel();
    _activityTimer?.cancel();
    _walletTimer?.cancel();
    _selfSub?.cancel();
    _chimeSub?.cancel();
    NotificationSound.instance.dispose();
    super.dispose();
  }

  // ── On-chain notifications ────────────────────────────────────────────────

  void _startActivitySweeps() {
    _sweepActivity();
    _sweepWallets();
    _activityTimer =
        Timer.periodic(_activitySweepInterval, (_) => _sweepActivity());
    _walletTimer =
        Timer.periodic(_walletSweepInterval, (_) => _sweepWallets());
  }

  /// Read the persisted activity into the bell badge (no network). Counts
  /// through the same filter + 24h throttle + per-type toggles the
  /// notifications list uses (`notification_kinds.dart`), so the badge never
  /// disagrees with the list.
  Future<void> _refreshUnreadCount() async {
    try {
      final raw = await PublicOSActivity.getStored(limit: 200);
      final enabled = await loadEnabledNotifKinds();
      final n = unreadNotifCount(buildNotifications(raw, enabled));
      // One-line health check for the whole pipeline: how many rows are
      // stored, how many kinds are enabled, what the badge will show. Reading
      // it answers "is the sweep finding nothing, or is the filter eating it".
      debugPrint(
          '[activity] stored=${raw.length} enabledKinds=${enabled.length} unread=$n');
      if (!mounted || n == _unreadCount) return;
      setState(() => _unreadCount = n);
    } catch (e) {
      debugPrint('[activity] badge read FAILED: $e');
    }
  }

  /// Poll P1 contract events into the activity cache, then refresh the badge.
  Future<void> _sweepActivity() async {
    try {
      await PublicOSActivity.sweep();
      await _pullSocialInbox();
      await _refreshUnreadCount();
    } catch (e, st) {
      // A silent catch on a background poll is how a feature dies quietly on
      // one platform while looking fine on the other: the bell shows nothing
      // and the reason is swallowed on every tick.
      debugPrint('[activity] contract sweep FAILED: $e');
      debugPrint('$st');
    }
  }

  /// The social inbox at the account's HOME SSP:
  /// replies, comments, mentions, reactions, follow requests from any
  /// registered server. DESKTOP DELTA: no push and no 15-min worker here, so
  /// this 10-min sweep is the only reader; the rows land in the same table
  /// the bell and the list read. Behind the Social notifications switch.
  Future<void> _pullSocialInbox() async {
    try {
      if (!await PublicOSSettings.getSocialNotifications()) return;
      final me = PublicOS.myPublicosAddress;
      final home = await PublicOSSsp.homeForIsolate();
      if (me == null || home == null) return;
      final fresh = await pullSocialInbox(account: me, home: home);
      if (fresh.isNotEmpty) debugPrint('[activity] social inbox: ${fresh.length} new');
    } catch (e) {
      debugPrint('[activity] social inbox pull FAILED: $e');
    }
  }

  /// Poll token transfers touching the user's OWN wallets (personal main Safe +
  /// every org main Safe + `walletEnabled` keychain EOAs) into the same cache.
  ///
  /// The watched set is enumerated CLIENT-side and handed to Core: "which
  /// wallets do I show" is a UI policy — `walletEnabled` is literally the
  /// Wallet-tab toggle — so Core takes the addresses as a parameter rather
  /// than deriving them.
  Future<void> _sweepWallets() async {
    if (_walletSweepInFlight) return; // a cold-start backfill can outrun a tick
    _walletSweepInFlight = true;
    try {
      final me = PublicOS.myPublicosAddress;
      if (me == null) return;
      final scan = await scanOwnReceivingWallets(EthereumAddress.fromHex(me));

      // **Do not sweep on a partial watched set.** Sweeping is what advances
      // the cursor, and the cursor is a promise that the range was handled. If
      // a source failed we do not know what to look for, so scanning would
      // step past those blocks having matched the wrong wallets — and Core is
      // right never to re-scan them.
      //
      // Cost of skipping: nothing. The next tick retries with the cursor
      // untouched. Cost of NOT skipping: a transfer to the main Safe is swept
      // past by a run whose Safe lookup failed, and becomes permanently
      // invisible.
      if (!scan.complete) {
        debugPrint('[activity] wallet scan incomplete — skipping sweep so the '
            'cursor does not advance past unwatched blocks');
        return;
      }
      final wallets = scan.wallets;
      if (wallets.isEmpty) return;
      await PublicOSWalletActivity.sweep(
        wallets: wallets
            .map((w) => EthereumAddress.fromHex(w.address))
            .toList(growable: false),
      );
      await _refreshUnreadCount();
    } catch (e, st) {
      // Best-effort, exactly like _sweepActivity: a failed pass leaves the
      // cursor untouched (Core guarantees that), so the next tick retries it.
      // Logged, not swallowed — see _sweepActivity.
      debugPrint('[activity] wallet sweep FAILED: $e');
      debugPrint('$st');
    } finally {
      _walletSweepInFlight = false;
    }
  }

  Future<void> _openNotifications() async {
    // The badge sits in the status bar behind the dialog: it follows as soon
    // as the list marks its rows read, not only when the dialog closes.
    await showNotificationsDialog(context,
        onMarkedRead: () => unawaited(_refreshUnreadCount()));
    if (!mounted) return;
    // The list marks everything read on open — re-read so the badge follows.
    await _refreshUnreadCount();
  }

  // ── Self contact ───────────────────────────────────────────────────────────

  Future<void> _loadMyContact() async {
    final hex = PublicOS.myPublicosAddress;
    if (hex == null) return;
    try {
      // Canonical read (Core docstring): the Contact is not cached in memory
      // after 1.0; consumers fetch it from the DB. restoreSession already saved
      // our own contact, so this resolves from the local DB.
      final contact = await PublicOSContacts.getContact(
        EthereumAddress.fromHex(hex),
      );
      if (!mounted) return;
      setState(() {
        _myContact = contact;
        _myAddress = hex;
      });
    } catch (_) {
      // Card falls back to the skeleton + address; not fatal.
    }
    _freshenMyContact();
  }

  /// The account this process has already re-read from chain, so a rebuilt
  /// shell does not refetch — but a switch to another account does.
  static String? _freshenedFor;

  /// Re-read the user's own contact from CHAIN once per boot, membership
  /// included (ported from the client explorer's twin).
  ///
  /// The local row is what everything paints, and its `isCitizen` is durable:
  /// `fetchContact` never re-reads it unless forced. Without this refresh a
  /// newly vouched account would keep the ghost avatar, its own included,
  /// until the local row was rebuilt. `fetchContact(self,
  /// forceMembership: true)` saves the row and emits on `selfContactUpdates`,
  /// which this shell already listens to. Background, best-effort: the cached
  /// contact is already on screen, and a failed read leaves it there.
  Future<void> _freshenMyContact() async {
    final hex = PublicOS.myPublicosAddress;
    if (hex == null || _freshenedFor == hex.toLowerCase()) return;
    _freshenedFor = hex.toLowerCase();
    try {
      await PublicOSContacts.fetchContact(
        EthereumAddress.fromHex(hex),
        forceMembership: true,
      );
    } catch (e) {
      _freshenedFor = null; // let the next landing try again
      Log.e('AppShell', 'Self contact refresh failed: $e');
    }
  }

  // ── Provider status (chain RPC + SSP) ──────────────────────────────────────
  //
  // The client explorer's _pollChainStatus / _loadProviderStatus recipe, plus
  // a name lookup so the sidebar can show the connected server as `name:host`
  // (the BSP/SSP dialogs' _loadSubscription / _fetchBsp recipe, title only).

  Future<void> _pollChainStatus() async {
    try {
      await PublicOSBsp.getBlockNumber();
      if (!mounted) return;
      final newSource = PublicOS.activeRpcSource;
      if (_chainReachable != true || _rpcSource != newSource) {
        setState(() {
          _chainReachable = true;
          _rpcSource = newSource;
        });
        await _loadChainName();
      }
    } catch (_) {
      if (!mounted) return;
      if (_chainReachable != false) setState(() => _chainReachable = false);
    }
  }

  Future<void> _loadProviderStatus() async {
    await _loadChainName();
    await _loadSspStatus();
  }

  Future<void> _loadChainName() async {
    final url = PublicOS.activeRpcUrl;
    final source = PublicOS.activeRpcSource;
    String? name;
    try {
      if (source == 'bsp') {
        final addrStr = PublicOS.myPublicosAddress;
        if (addrStr != null) {
          final slug = await PublicOSTreasury.assignedSlug(PublicOSTreasury.bspAxis, EthereumAddress.fromHex(addrStr));
          if (slug.isNotEmpty) {
            final data = await PublicOSBsp.bspRegistryMemoryContract
                .getBSPBySlug((slug: slug));
            if (data != null && data[0] as bool) {
              final title = data[2] as String;
              name = title.isNotEmpty ? title : slug;
            }
          }
        }
      } else if (source == 'custom') {
        final all = await PublicOSBsp.buildRpcEndpointList();
        for (final e in all) {
          if (e.url == url) {
            name = e.label;
            break;
          }
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _rpcSource = source;
      _chainName = name;
      _chainHost = _hostOf(url);
    });
  }

  Future<void> _loadSspStatus() async {
    final url = PublicOS.activeSspUrl;
    final source = PublicOS.activeSspSource;
    String? name;
    try {
      if (source == 'ssp') {
        final addrStr = PublicOS.myPublicosAddress;
        if (addrStr != null) {
          final slug = await PublicOSTreasury.assignedSlug(PublicOSTreasury.sspAxis, EthereumAddress.fromHex(addrStr));
          if (slug.isNotEmpty) {
            final data = await PublicOSBsp.socialServerRegistryMemoryContract
                .getSocialServerBySlug((slug: slug));
            if (data != null && data[0] as bool) {
              final title = data[2] as String;
              name = title.isNotEmpty ? title : slug;
            }
          }
        }
      } else if (source == 'custom') {
        final all = await PublicOSSsp.buildFeedServerList();
        for (final e in all) {
          if (e.url == url) {
            name = e.label;
            break;
          }
        }
      } else if (source == 'override') {
        name = 'Override';
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _sspReachable = PublicOS.sspConnected;
      _sspSource = source;
      _sspName = name;
      _sspHost = _hostOf(url);
    });
  }

  static String? _hostOf(String url) {
    if (url.isEmpty) return null;
    final host = Uri.tryParse(url)?.host;
    return (host == null || host.isEmpty) ? url : host;
  }

  // ── BSP / SSP dialogs ──────────────────────────────────────────────────────

  Future<void> _openBspDialog() async {
    await showBspDialog(
      context,
      onOpenTreasury: () {
        if (mounted) _showDestination(_treasuryIndex);
      },
    );
    // Client explorer's _refreshAfterBspPop: re-run the post-auth RPC
    // upgrade in case the user connected/added an endpoint, then re-poll.
    try {
      await PublicOS.upgradeRpcPostAuth();
    } catch (_) {}
    if (!mounted) return;
    await _pollChainStatus();
    await _loadChainName();
  }

  Future<void> _openSspDialog() async {
    await showSspDialog(context);
    // Client explorer's _refreshAfterSspPop: re-resolve the feed server.
    try {
      await PublicOS.initSSP();
    } catch (_) {}
    if (!mounted) return;
    await _loadSspStatus();
  }

  Future<void> _openKeychainDialog() async {
    // Keychain changes affect the XMTP/web signing keys, not the publicos
    // identity, so no shell refresh is needed on close — except the status
    // bar's XMTP chip, which reads the active key + its directory binding.
    // The self contact is passed in for the session-key tile's avatar.
    final keyBefore = PublicOS.currentXmtpKeyLabel;
    await showKeychainDialog(context, myContact: _myContact);
    if (mounted && PublicOS.currentXmtpKeyLabel != keyBefore) {
      setState(() {
        _messagesEpoch++;
        _messagesBadge = 0; // the count belonged to the previous inbox
      });
      // A chat tab open in another pane (Contacts) rebuilds on this.
      xmtpKeyEpoch.value++;
    }
    _loadXmtpIdentity();
  }

  /// Feeds the status bar's XMTP chip: the active key's keychain emoji, and
  /// whether its inbox is registered in the account's on-chain inbox
  /// directory (`XmtpManager.getAllAccountInboxIds`) — and under which label.
  /// One directory read per call; runs at mount and after the keychain dialog
  /// closes. The bar stays pure presentation.
  Future<void> _loadXmtpIdentity() async {
    final me = PublicOS.myPublicosAddress;
    final label = PublicOS.currentXmtpKeyLabel;
    final inboxId = PublicOS.clientXmtpInboxId;
    if (me == null || label == null || label.isEmpty) {
      if (!mounted) return;
      setState(() {
        _xmtpKeyEmoji = null;
        _inboxRegisteredLabel = null;
        _inboxOrgName = null;
        _inboxLookupDone = true;
      });
      return;
    }
    if (mounted) setState(() => _inboxLookupDone = false);

    String? emoji;
    String? orgAddress;
    try {
      final keys = await PublicOSKeychain.fetchKeys(me);
      for (final k in keys) {
        if (k['label'] == label) {
          emoji = k['emoji'] as String?;
          if (k['isGroupKey'] == true) orgAddress = k['orgAddress'] as String?;
          break;
        }
      }
    } catch (_) {}

    // An org key's inbox is registered in the ORG's directory (e.g. an admin
    // holding the org's Admin key), so read that one and name it after the
    // org. Reading only mine showed such a key as "unregistered".
    final owner = orgAddress ?? me;
    String? orgName;
    if (orgAddress != null) {
      orgName = await PublicOSContacts.getPublicosDisplayNameByAccountAddress(
          EthereumAddress.fromHex(orgAddress));
    }

    String? registered;
    try {
      final mine = Contact.normalizeInboxId(inboxId);
      final dir = await PublicOSXmtp.getAllAccountInboxIds(
        EthereumAddress.fromHex(owner),
      );
      if (dir != null && mine != null) {
        for (var i = 0; i < dir.inboxIds.length; i++) {
          if (bytes32ToString(dir.inboxIds[i] as Uint8List) == mine) {
            registered = i < dir.labels.length ? dir.labels[i] : '';
            break;
          }
        }
      }
    } catch (_) {
      // RPC down: chip shows "unregistered" once done; the BSP dot already
      // says why.
    }

    if (!mounted) return;
    setState(() {
      _xmtpKeyEmoji = emoji;
      _inboxRegisteredLabel = registered;
      _inboxOrgName = orgName;
      _inboxLookupDone = true;
    });
  }

  Future<void> _openWalletDialog() async {
    // Wallets is a big dialog (footer row under Keychain + nav intercept),
    // mirroring BSP/SSP. WalletView owns all its own loading/refresh.
    await showWalletDialog(context);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  // ── First run (client parity: publicos_client explorer.dart) ─────────────

  Future<void> _checkOnboarding() async {
    try {
      final record = await PublicOSSettings.getSetting('onboarding_completed');
      if (mounted) {
        setState(() => _needsOnboarding = record?.value != 'true');
      }
    } catch (_) {
      if (mounted) setState(() => _needsOnboarding = true);
    }
  }

  // Per-account flag marking that the one-time PublicOS onboarding (upsert the
  // org contact + follow its account in the default list) has run. Same key as
  // the client, scoped by PublicOSSettings' (key, sessionAddress) keying.
  static const String _publicosOnboardedFlag = 'publicos_onboarded';

  // Resolved by display NAME, never a hardcoded address (survives redeploys).
  static const String _publicosOrgName = 'PublicOS';

  /// One-time, name-resolved onboarding of the canonical PublicOS org: upsert
  /// the "PublicOS" contact and follow its ACCOUNT in the "Following" list, so
  /// a brand-new user lands already following everything PublicOS publishes.
  /// The flag is set only after a successful resolve, so a boot with no chain
  /// connectivity retries next launch. Best-effort, never blocks the shell.
  Future<void> _ensurePublicosOnboarded() async {
    for (final (name, flag, muted) in _defaultFollows) {
      await _ensureDefaultFollow(name, flag, muted);
    }
  }

  /// The accounts every new account follows into the default list, each with
  /// its OWN one-time flag. Twin of the client's `explorer.dart` list; same flag keys.
  /// The third field lists channels (the owner's `record.key`) that start
  /// muted in that follow, shown as turned off: Backstage is TheOrg's private
  /// channel, and a default follow of it gave newcomers the "private feed"
  /// warning.
  static const List<(String, String, List<String>)> _defaultFollows = [
    (_publicosOrgName, _publicosOnboardedFlag, []),
    ('jmsl', 'jmsl_default_follow', []),
    // TheOrg lists the channels its members run (Diez Palomas, Backstage).
    ('TheOrg', 'theorg_default_follow', ['channel.backstage']),
  ];

  Future<void> _ensureDefaultFollow(
      String name, String flag, List<String> muted) async {
    try {
      final already = await PublicOSSettings.getSetting(flag);
      if (already?.value == 'true') return;

      final org = await PublicOSContacts.resolveByIdentifier(name);
      if (org == null || org.publicosAddress == null) return;

      await PublicOSContacts.saveContact(org);
      // A default follow is a starred contact.
      await PublicOSContacts.setStarred(org, true);

      final following = await _ensureDefaultList();
      final session = PublicOS.sessionBlockchainAddress;
      if (following == null || session == null) return;

      await PublicOS.database.followAccount(
        session: session,
        account: org.publicosAddress!.eip55With0x,
        listId: following.id,
      );
      for (final key in muted) {
        await PublicOS.database.muteChannel(
          session: session,
          account: org.publicosAddress!.eip55With0x,
          listId: following.id,
          recordKey: key,
        );
      }

      await PublicOSSettings.setSetting(
        flag,
        Record.asSettings(
          key: flag,
          value: 'true',
          isSystem: true,
          isExpired: false,
        ),
      );
    } catch (_) {
      // Best-effort — never block the shell.
    }
  }

  /// Get-or-create the default list. Name/icon mirror the client's
  /// `_ensureDefaultList` (canonical owner: feeds_view's `_defaultListName`).
  static Future<FeedList?> _ensureDefaultList() async {
    const followingName = 'Following';
    const followingIcon = '👾';
    final lists = await PublicOSFeedLists.getUserLists();
    for (final l in lists) {
      if (l.name == followingName) return l;
    }
    return PublicOSFeedLists.createList(followingName, icon: followingIcon);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final tones = ShellTones.of(context);

    // First run: the onboarding tour replaces the shell until its outro writes
    // `onboarding_completed` (client parity). DESKTOP DELTA: the phone-shaped
    // flow sits in a centred column instead of stretching across the window.
    if (_needsOnboarding == true) {
      // The constellation fills the WINDOW, behind the column; the flow skips
      // its own (`drawBackground: false`), which would only cover the column.
      return ColoredBox(
        color: tokens.background,
        child: Stack(
          children: [
            const Positioned.fill(child: ConstellationBackground()),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                // DESKTOP DELTA 2: the flow sizes its grids from
                // `MediaQuery.sizeOf(context).width` (the phone's screen IS its
                // column). Here the window is wider than the column, so a preview
                // would reserve the height of a window-wide grid and draw a
                // 520 px one in it, leaving a screen of empty space under the
                // cards. Tell the flow its screen is the column.
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final mq = MediaQuery.of(context);
                    return MediaQuery(
                      data: mq.copyWith(
                        size: Size(constraints.maxWidth, mq.size.height),
                      ),
                      child: OnboardingFlow(
                        drawBackground: false,
                        onComplete: () {
                          if (mounted) setState(() => _needsOnboarding = false);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Shell skeleton:
    // Column[ Row[rail, pane], StatusBar ] — the status bar is a SIBLING of
    // the pane row, never nested in a panel, so docking it top vs bottom is
    // exactly a reorder of the Column's children (ShellPrefs.statusBarTop).
    // The rail overlays on hover: the Row only reserves its collapsed width;
    // the real rail sits in a Stack above the pane and grows over it.
    final statusBar = StatusBar(
      // The bar's identity chip is "what am I signing with": the SESSION key.
      // The account address lives on the rail's user chip.
      myAddress: PublicOS.sessionBlockchainAddress,
      xmtpKeyLabel: PublicOS.currentXmtpKeyLabel,
      xmtpKeyEmoji: _xmtpKeyEmoji,
      xmtpInboxId: PublicOS.clientXmtpInboxId,
      inboxRegisteredLabel: _inboxRegisteredLabel,
      inboxLookupDone: _inboxLookupDone,
      displayName: _inboxOrgName ??
          _myContact?.publicosDisplayName ??
          _myContact?.displayName,
      unreadCount: _unreadCount,
      onOpenNotifications: _openNotifications,
      chain: ProviderStatus(
        reachable: _chainReachable,
        source: _rpcSource,
        name: _chainName,
        endpoint: _chainHost,
      ),
      ssp: ProviderStatus(
        reachable: _sspReachable,
        source: _sspSource,
        name: _sspName,
        endpoint: _sspHost,
      ),
      onOpenKeychain: _openKeychainDialog,
      onOpenChain: _openBspDialog,
      onOpenSsp: _openSspDialog,
    );

    final mainRow = Expanded(
      child: Stack(
        children: [
          Row(
            children: [
              const SizedBox(width: ShellMetrics.railWidth + ShellMetrics.gap),
              Expanded(child: _paneArea(tokens, tones)),
            ],
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Sidebar(
              selectedIndex: _selectedIndex,
              onSelect: (i) {
                // BSP / SSP are big dialogs, not panes — intercept their nav
                // rows instead of switching the content pane.
                if (i == _bspIndex) {
                  _openBspDialog();
                  return;
                }
                if (i == _sspIndex) {
                  _openSspDialog();
                  return;
                }
                // Wallets is a big dialog too — same
                // interception as BSP/SSP.
                if (i == _walletsIndex) {
                  _openWalletDialog();
                  return;
                }
                // My Account isn't a pane — open Contacts on the user's own
                // profile. The token bump re-focuses self even if Contacts is
                // already up showing another contact.
                if (i == _myAccountIndex) {
                  setState(() {
                    _selectedIndex = _contactsIndex;
                    _focusContact = null; // null = self
                    _focusApp = null;
                    _focusTabKey = null;
                    _focusToken++;
                  });
                  return;
                }
                _showDestination(i);
              },
              myContact: _myContact,
              myAddress: _myAddress,
              badges: {_messagesIndex: _messagesBadge},
              // Apps: the last-visited history + the pinned
              // Apps button. Opening from the rail is the same path as the
              // Apps dialog's tiles — `AppNav.toApp` → the owner's profile.
              recentApps: _recentApps,
              // A system-app entry (Treasury · Social Graph · Nodes) opens its
              // pane instead — it has no owner to land on.
              onOpenApp: (app) {
                final sys = systemAppOf(app);
                if (sys != null) {
                  _showDestination(sys.destination);
                  return;
                }
                AppNav.toApp(
                  context,
                  app.ownerAccountAddress.eip55With0x,
                  appName: app.appName,
                  app: app,
                );
              },
              onRemoveRecentApp: (app) => RecentApps.instance.remove(app),
              onOpenApps: () => showAppsDialog(context),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: tones.canvas,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          ShellMetrics.gap,
          6,
          ShellMetrics.gap,
          ShellMetrics.gap,
        ),
        child: ValueListenableBuilder<bool>(
          valueListenable: ShellPrefs.statusBarTop,
          builder: (context, barTop, _) => Column(
            children: barTop
                ? [
                    statusBar,
                    const SizedBox(height: ShellMetrics.gap),
                    mainRow,
                  ]
                : [
                    mainRow,
                    const SizedBox(height: ShellMetrics.gap),
                    statusBar,
                  ],
          ),
        ),
      ),
    );
  }

  /// Split panes (Contacts / Messages / Feeds) draw their own two floating
  /// panels via [ShellSplit]; everything else gets the single content card.
  Widget _paneArea(GlassTokens tokens, ShellTones tones) {
    final shape = _shapeOf(_selectedIndex);
    final pane = _pane(tokens);
    // Split panes draw their own two cards; single panes get the content
    // card here. ShellMorph then animates single ↔ split on every switch
    // (the old panel becomes the content card and shrinks right while the
    // list card opens left → right; reversed on the way back).
    final rest = shape.isSplit ? pane : ShellPanel(tone: tones.content, child: pane);
    return ShellMorph(
      shape: shape,
      child: KeyedSubtree(
        key: _paneKeys.putIfAbsent(_selectedIndex, GlobalKey.new),
        child: rest,
      ),
    );
  }

  /// The rest shape of each destination — the split panes' own list widths,
  /// read from the panes so the morph lands exactly where they draw.
  static ShellPaneShape _shapeOf(int index) {
    if (index == _contactsIndex) {
      return const ShellPaneShape.split(ContactsPane.listWidth);
    }
    if (index == _messagesIndex) {
      return const ShellPaneShape.split(MessagesPane.listWidth);
    }
    if (index == _feedsIndex) {
      return const ShellPaneShape.split(FeedsPane.listWidth);
    }
    return const ShellPaneShape.single();
  }

  /// Switch the content pane. Every pane switch that is not a Contacts focus
  /// goes through here, so a system-app pane (Treasury · Social Graph · Nodes)
  /// is recorded in the rail history by whichever door opened it.
  void _showDestination(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == _messagesIndex) _messagesBadge = 0;
    });
    RecentApps.instance.recordDestinationOpen(index);
  }

  /// [RecentApps] changed (an app tab was selected somewhere, or a history
  /// row was removed) — repaint the rail with the new list.
  void _onRecentApps() {
    if (!mounted) return;
    setState(() => _recentApps = RecentApps.instance.apps);
  }

  Widget _pane(GlassTokens tokens) {
    final d = kShellDestinations[_selectedIndex];
    // Feature panes intercept here; everything else is a placeholder.
    if (d.index == _contactsIndex) {
      // Same instance across My Account / Contacts clicks (stable key) — the
      // token, not a remount, drives the self-focus.
      return ContactsPane(
        key: const ValueKey('contacts'),
        focusContact: _focusContact,
        focusToken: _focusToken,
        focusApp: _focusApp,
        focusTabKey: _focusTabKey,
      );
    }
    if (d.index == _graphIndex) {
      return const GraphPane(key: ValueKey('graph'));
    }
    if (d.index == _messagesIndex) {
      return MessagesPane(key: ValueKey('messages:$_messagesEpoch'));
    }
    if (d.index == _feedsIndex) {
      return FeedsPane(
        key: const ValueKey('feeds'),
        focusFeed: _focusFeed,
        focusToken: _feedFocusToken,
      );
    }
    if (d.index == _accountIndex) {
      // Ported verbatim from publicos_client. `browser.dart` hides the
      // Settings tab when you browse YOURSELF because self-settings live in
      // this app: it is the only door to devices / recovery contacts / accent
      // colour.
      return const AccountCenterPage(key: ValueKey('account'));
    }
    if (d.index == _treasuryIndex) {
      // Ported verbatim from publicos_client. The BSP dialog's
      // `onOpenTreasury` hook lands here.
      return const TreasuryPage(key: ValueKey('treasury'));
    }
    if (d.index == _nodesIndex) {
      // Ported from publicos_client verbatim — it brings its own
      // SystemAppScaffold chrome, which suppresses its back button when
      // there is nothing to pop (see SystemAppScaffold.showBack).
      return const NodePage(key: ValueKey('nodes'));
    }
    if (d.index == 9) {
      return SettingsPane(key: const ValueKey('settings'), onLogout: widget.onLogout);
    }
    return FeaturePlaceholder(
      key: ValueKey(d.index),
      icon: d.selectedIcon,
      title: d.label(context),
      blurb: d.blurb(context),
    );
  }

}
