import 'dart:async';

import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:publicos_desktop/widgets/feeds/header_slot.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/feeds/bookmarks_view.dart';
import 'package:publicos_desktop/widgets/feeds/explore_view.dart';
import 'package:publicos_desktop/widgets/feeds/feed_favicon.dart';
import 'package:publicos_desktop/widgets/feeds/feed_source.dart';
import 'package:publicos_desktop/widgets/feeds/feed_reader_header.dart';
import 'package:publicos_desktop/widgets/feeds/add_to_lists_sheet.dart';
import 'package:publicos_desktop/widgets/feeds/channel_signin_dialogs.dart';
import 'package:publicos_desktop/widgets/feeds/feeds_settings_sheet.dart';
import 'package:publicos_desktop/widgets/feeds/post_card.dart' show PostLayoutMode;
import 'package:publicos_desktop/widgets/inline_flow_host.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_widget.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/screens/compose_post_page.dart';
import 'package:publicos_desktop/screens/channel_settings_page.dart';
import 'package:publicos_desktop/screens/create_channel_page.dart';
import 'package:publicos_desktop/screens/manage_server_page.dart';
import 'package:publicos_desktop/widgets/feeds/discover_browser.dart';
import 'package:publicos_desktop/widgets/feeds/edit_list_sheet.dart';
import 'package:publicos_desktop/widgets/feeds/feeds_navigation_drawer.dart';
import 'package:publicos_desktop/widgets/feeds/manage_lists_sheet.dart';
import 'package:publicos_desktop/widgets/feeds/list_header_card.dart';
import 'package:publicos_desktop/widgets/content_metrics_listener.dart';
import 'package:publicos_desktop/widgets/feeds/posts_list.dart';
import 'package:publicos_desktop/theme/theme_provider.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/favicon_utils.dart';
import 'package:publicos_desktop/widgets/shell_split.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_label.dart';
import 'package:zero_cached_image/zero_cached_image.dart';
import 'package:flutter/cupertino.dart';
/// **Feeds — nav index 3.** publicos_client's `RssFeedsView`, re-shelled as the
/// desktop dual-pane (the template Contacts established).
///
/// **The one structural delta:** on mobile the feeds navigation is an OVERLAY
/// DRAWER — a hamburger in an inline header slides `FeedsNavigationDrawer` in
/// over the content. A desktop window has room to just *show* it, so the drawer
/// widget is **unchanged** and simply always-mounted as the 300px left pane;
/// all of the client's drawer machinery (AnimationController, OverlayEntry,
/// open/close/toggle, the slide transform, the scrim) is deleted rather than
/// ported. Everything else -- state, loaders, selection, the unified spinner --
/// is the client's, verbatim.
///
/// Reading, interacting, curating (lists), writing (compose / create / manage
/// channel) and server admin all live here. The flow pages render **inside
/// the reading column** via [InlineFlowHost] (nested navigator, so the client
/// pages' own pop/push work verbatim).
class FeedsPane extends StatefulWidget {
  /// The list card's width — public so the shell can morph into it.
  static const double listWidth = 300;


  final Color color;
  final String searchQuery;

  /// A feed to open on its own (`AppNav.onOpenFeedUrl`, a post's "Go to
  /// feed"), applied once per [focusToken].
  final FeedSource? focusFeed;
  final int focusToken;

  const FeedsPane({
    super.key,
    this.color = const Color(0xFF14b8a6),
    this.searchQuery = '',
    this.focusFeed,
    this.focusToken = 0,
  });

  @override
  State<FeedsPane> createState() => FeedsPaneState();
}

class FeedsPaneState extends State<FeedsPane> {
  /// Max width of the reading column — **now a user setting, not a constant**
  /// (desktop-only; see `kReadingWidthPresets`). A 520px column reads like a
  /// timeline and a 900px one like a magazine, and that is a taste, so it belongs
  /// to the user. Persisted through PublicOSSettings like the other four reading
  /// settings; `double.infinity` = no cap, fill the pane.
  ///
  /// Header and content both route through [_readingColumn], so they stay locked
  /// to the same edge whatever the user picks.

  List<Channel> _channels = [];
  List<FeedList> _lists = [];

  /// True once the (local, fast) lists half of `_loadData` has resolved.
  /// The late channels arrival consults it so its last-resort cold-start
  /// fallback (select the first channel) can never fire before the lists
  /// read has had its chance to select the first list.
  bool _listsLoaded = false;

  // The feeds selection — the single source of truth for "what am I looking
  // at". Holds one of: a [FeedList], a [Channel], a [FeedsView] enum value
  // (discover / bookmarks), a [FeedSource] (one feed by URL, outside any list:
  // a post's "Go to feed", DESKTOP DELTA for the client's FeedReaderPage), or
  // null during the cold-start window before `_loadData` bootstraps a default. The four modes can't desync because
  // there is only one field; the getters below are the content-checks every
  // read site shares, and `_select` is the only writer outside `_loadData`.
  Object? _selected;

  FeedList? get _selectedList {
    final s = _selected;
    return s is FeedList ? s : null;
  }

  Channel? get _selectedChannel {
    final s = _selected;
    return s is Channel ? s : null;
  }

  FeedSource? get _selectedFeed {
    final s = _selected;
    return s is FeedSource ? s : null;
  }

  /// The focus token last applied. Static because the pane remounts on every
  /// visit with the shell's latest token; only a newer one is a new request.
  static int _appliedFocusToken = 0;

  /// Whether [_selectedFeed] is in any of the user's lists (the follow glyph).
  bool _selectedFeedFollowed = false;

  /// What "Go to feed" replaced, and where it was scrolled — the ← in the
  /// title bar returns to it (desktop has no system back button). Null when
  /// there's nothing to return to; any other selection forgets it.
  Object? _returnSelection;
  double? _returnOffset;

  /// Scroll offset to re-apply once the restored selection's posts land.
  double? _pendingRestoreOffset;

  bool get _isViewingBookmarks => _selected == FeedsView.bookmarks;
  bool get _isViewingDiscover => _selected == FeedsView.discover;
  bool get _isViewingExplore => exploreViews.contains(_selected);

  /// The Explore row on screen (three rows, one view).
  ExploreMode get _exploreMode => switch (_selected) {
        FeedsView.hotFeeds => ExploreMode.hotFeeds,
        FeedsView.latest => ExploreMode.latest,
        _ => ExploreMode.hotPosts,
      };

  /// The body is a PostsList (a channel, a single or a list), the surface
  /// the header's refresh button reloads.
  bool get _showsPostsList =>
      !_isLoading &&
      _openPost == null &&
      _openPostSource == null &&
      !_isViewingDiscover &&
      !_isViewingExplore &&
      !_isViewingBookmarks &&
      _selected != null &&
      _roster != null;

  bool _isLoading = true;

  // Posts-layer loading, reported up from the active PostsList via
  // `onLoadingChanged`. Combined with `_isLoading` (the lists/channels
  // metadata load) into the single spinner overlay in `build`, so a cold start
  // or a selection change shows ONE continuous animation instead of the shell
  // spinner handing off to a freshly-mounted PostsList spinner (which reset the
  // orbit to its start position). Set eagerly wherever we already know a
  // PostsList is about to (re)mount and load, so the overlay never blinks off
  // in the one-frame gap before PostsList reports its own loading.
  bool _postsLoading = false;

  /// Phase 2 of the two-phase feed load is in flight — the cached posts are
  /// ALREADY on screen and the network is revalidating behind them.
  ///
  /// Deliberately NOT folded into `_postsLoading`: that one drives a blocking
  /// overlay ("you have nothing to look at yet"), and once the cache paints
  /// instantly that is exactly the wrong message. Refreshing gets a peripheral
  /// hint instead — the pixel-rain loader at the far right of the title bar.
  bool _postsRefreshing = false;

  /// The "N new" chip once the list has docked it here.
  Widget? _dockedNewChip;

  /// Bumped when this pane's own compose flow saves a post — PostsList sees
  /// the change in didUpdateWidget and re-fetches, applying directly (no
  /// "New posts" chip) so the author sees their post immediately.
  int _postsRefreshTick = 0;

  /// Re-keys the list header so it recounts after a list change.
  /// Who the selected list follows, for the scroll-away card and the inline
  /// header's mini stack. Loaded with the roster and again after the list
  /// was managed; null while loading or when the selection is not a list.
  ListFollowSummary? _listSummary;
  int _listSummaryGen = 0;

  /// The list card is an item of the scroll view (a `SliverToBoxAdapter`
  /// before the posts), so it leaves with the content. True once it has
  /// fully left the top: the inline header then shows the mini stack beside
  /// Manage, and takes it back when the card returns. Position only, never
  /// scroll activity, like `_scrolledUnder`.
  final ValueNotifier<bool> _listCardGone = ValueNotifier<bool>(false);
  final GlobalKey _listCardKey = GlobalKey();

  Future<void> _loadListSummary() async {
    final gen = ++_listSummaryGen;
    final sel = _selected;
    if (sel is! FeedList || sel.isSingle) {
      if (_listSummary != null) setState(() => _listSummary = null);
      return;
    }
    // The roster ranks the tiles: latest posters first.
    final summary = await ListFollowSummary.load(sel.id, roster: _roster);
    if (!mounted || gen != _listSummaryGen) return;
    setState(() => _listSummary = summary);
  }

  void _onContentMetrics(ScrollMetrics m) {
    // The card's own height decides when it is gone; once scrolled out of the
    // viewport it may be unmounted, and then it is gone by definition. Coming
    // back is slower than going, so the user pulls a little more before the
    // animation down starts: the stack leaves the
    // header only once half the card is showing again, so a small drag near
    // the edge does not flip it.
    final card = _listCardKey.currentContext?.size?.height;
    final before = m.extentBefore;
    if (before <= 0) {
      _listCardGone.value = false;
    } else if (card == null || before >= card) {
      _listCardGone.value = true;
    } else if (before < card / 2) {
      _listCardGone.value = false;
    }
  }

  /// Bumped by the header's Reload on Explore (desktop delta: a mouse can't
  /// pull to refresh).
  int _exploreRefreshTick = 0;

  final ScrollController _scrollController = ScrollController();

  // Text size settings — read once here so the settings view can edit them live;
  // passed down to PostsList as overrides.
  //
  // ⚠ Initialised from feeds_settings_sheet's EXPORTED defaults, not from
  // hard-coded numbers. publicos_client hard-codes them here (16.0 / **14.0**)
  // while the settings sheet's own default is **15** — so on a fresh account the
  // client renders body text at 14 while its slider reads 15, and the first drag
  // silently jumps the text. Desktop keeps ONE source of truth so the two cannot
  // drift.
  double _titleTextSize = kTitleDefault;
  double _descriptionTextSize = kBodyDefault;
  // Trim-long-posts setting. null = show full; positive int = char budget
  // applied across summary + body in PostCard.
  int? _trimChars;
  // Reading layout — compact (default microblog) or wide (flat-padded body).
  // Lives next to font sizes so the settings sheet edits a single bag.
  PostLayoutMode _layoutMode = kLayoutDefault;
  double _readingMaxWidth = kReadingWidthDefault;

  // Header/drawer-only contact resolution map. Populated by
  // `_loadSingleListMetadata` for the single-flagged via-line. The body
  // (PostsList) keeps its own separate map for post bodies — by design,
  // no coupling.
  Map<String, Contact> _resolvedContacts = {};

  // URLs of channels the user has pinned as router tabs. Mirrors the
  // logic on `ManageServerPage`: each entry is the JSON-feed URL for an
  // owned channel that has a matching `RouterSubtype.channel` record on the
  // user's contact. Used to render the Add-as-Tab toggle in the drawer.
  Set<String> _tabUrls = const <String>{};

  // First feed of each is_single list, keyed by list id. Drives single-row
  // rendering in the drawer + inline header. Populated by _loadData.
  Map<int, ListFeed> _singleFeedByListId = {};

  /// Singles whose channel the owner deleted (their row is in
  /// [_singleFeedByListId] AS STORED, so the header keeps its name + via).
  /// The roster marks the feed gone → "Channel not found".
  Set<int> _goneSingleListIds = {};

  // DESKTOP DELTA: no drawer state. The client's AnimationController +
  // OverlayEntry exist only to slide the drawer over the content; here it is
  // always on screen as the left pane.

  // ── Detail stack ──────────────────────────────────────────────────────────
  //
  // The client PUSHES PostDetailPage / PostSourceDetailsPage as routes. Desktop
  // shows them IN PLACE in the reading column, master-detail style: the post
  // list is swapped out, Back brings it home.
  //
  // Two fields rather than one enum because they genuinely stack: from a post's
  // detail you can open its SOURCE details, and Back should return you to the
  // post — not all the way out to the list. Source is therefore checked FIRST in
  // _buildContent, and its Back clears only itself.
  //
  // We hold the BUILDER the caller handed us, not a Post. `post_card` is the only
  // widget that holds the right arguments for these pages — chiefly PostsList's
  // post-AUTHOR contact map. This pane's own `_resolvedContacts` is the
  // drawer/header map and does NOT contain post authors (the client: *"the body
  // keeps its own separate map ... by design, no coupling"*); re-assembling the
  // args here from it would leave the author unresolved on the detail page.
  // So the caller builds the page, we only supply `onBack`.
  Widget Function(VoidCallback onBack)? _openPost;
  Widget Function(VoidCallback onBack)? _openPostSource;

  /// Reading settings, opened from the drawer footer. Sits on the SAME stack as
  /// the post detail rather than replacing the content: whatever you were
  /// reading (a post, or the list) is still underneath, and Back returns you to
  /// exactly that. Checked FIRST in _buildContent, so it wins over both.
  bool _openSettings = false;

  /// A hosted flow page (compose / create channel / manage channel /
  /// manage server) rendering **inside the reading column** via
  /// [InlineFlowHost]. Deepest of all — checked before
  /// settings/detail in _buildContent. Null when no flow is open.
  Widget? _openFlow;

  /// Open [page] in the reading column and complete with its pop result — the
  /// desktop stand-in for the client's `Navigator.push(...)` on these pages.
  /// Also registered as `AppNav.onOpenFlow` so verbatim child widgets
  /// (post_card's edit-post, posts_list's channel FAB) land here.
  Future<Object?> _openFlowPage(Widget page) {
    final completer = Completer<Object?>();
    setState(() {
      _openFlow = InlineFlowHost(
        page: page,
        onClose: (result) {
          if (mounted) setState(() => _openFlow = null);
          if (!completer.isCompleted) completer.complete(result);
        },
      );
    });
    return completer.future;
  }


  String get _selectedItemName {
    switch (_selected) {
      case FeedsView.discover:
        return context.l10n.feedsViewDiscover;
      case FeedsView.bookmarks:
        return context.l10n.feedsViewBookmarks;
      case FeedsView.hotPosts:
        return context.l10n.exploreHotPosts;
      case FeedsView.hotFeeds:
        return context.l10n.exploreHotFeeds;
      case FeedsView.latest:
        return context.l10n.exploreLatestPosts;
      case Channel ch:
        return ch.name;
      case FeedList list:
        return list.name;
      case FeedSource feed:
        return feed.title ?? context.l10n.feedReaderPageFallbackTitle;
      default:
        // Empty — only ever hit in the brief cold-start window before
        // `_loadData` bootstraps a selection. Was 'Channels', which read as
        // a (wrong) concrete selection and visibly flashed before
        // 'Following'; an empty title resolves straight into the real one.
        return '';
    }
  }

  // ── The roster (the HOST derives) ────────────────────────────────────────
  //
  // `_roster` is the resolved List<FeedSource> for the current selection —
  // null while deriving (the unified spinner covers the gap; `_select` clears
  // it synchronously so a stale roster never renders under a new selection).
  // Any mutation that changes what a list contains re-derives by going
  // through `_loadData`, which ends in `_deriveRoster()`.
  List<FeedSource>? _roster;
  int? _rosterListId;
  int _rosterGeneration = 0;

  /// The current SSP server base URL — fallback for channels whose `Channel`
  /// carries no serverAddress. Resolved once per `_loadData` (local DB read).
  String? _defaultServerUrl;

  /// Sign-in preference for the current single-feed surface.
  /// Null on multi-feed surfaces AND for feeds whose
  /// server never advertised envelope support — either way, no toggle in the
  /// header. Refreshed after every roster change and load/refresh completion,
  /// because the row is DISCOVERED during a fetch: the first load of a
  /// supporting feed is exactly when it appears.
  ChannelSigninPref? _signinPref;

  /// The RULE's answer for the current single feed — what the key glyph
  /// shows (never the raw column).
  bool _signinEffective = false;

  /// The one feed URL of a single-feed surface (a channel pick or a
  /// single-flagged list), null on multi-feed rosters. The sign-in toggle
  /// only exists where identity attaches to exactly one endpoint.
  String? get _singleRosterUrl {
    final roster = _roster;
    return (roster != null && roster.length == 1) ? roster.first.url : null;
  }

  /// Re-query the sign-in pref for the current surface. Cheap (one PK read),
  /// so it runs after every roster change and load completion; the
  /// stale-guard re-checks the URL after the await so a mid-flight selection
  /// change can't paint another feed's pref.
  Future<void> _refreshSigninPref() async {
    final url = _singleRosterUrl;
    if (url == null) {
      if (_signinPref != null && mounted) {
        setState(() {
          _signinPref = null;
          _signinEffective = false;
        });
      }
      return;
    }
    final pref = await PublicOSChannelSignin.getPref(url);
    final effective =
        pref == null ? false : await PublicOSChannelSignin.shouldSign(url);
    if (!mounted || _singleRosterUrl != url) return;
    setState(() {
      _signinPref = pref;
      _signinEffective = effective;
    });
  }

  /// Derive the roster from the current selection.
  ///
  /// Channel pick → a roster of one (the channel IS its `/json` url — the
  /// Channel object is not needed to load). Single-flagged list → its one
  /// wrapped feed, presented as the feed itself (no listId). Regular list →
  /// `resolveListItems` (stored rows ∪ followed accounts' channels − mutes),
  /// mapped 1:1 into FeedSources, passed with the listId for the verbs.
  Future<void> _deriveRoster() async {
    await _deriveRosterSelection();
    await _refreshSigninPref();
    await _loadListSummary();
  }

  Future<void> _deriveRosterSelection() async {
    final gen = ++_rosterGeneration;
    final selected = _selected;

    if (selected is FeedSource) {
      setState(() {
        _roster = [selected];
        _rosterListId = null;
      });
      _checkSelectedFeedFollowed(selected.url);
      return;
    }

    if (selected is Channel) {
      final owner = selected.ownerAddress ??
          AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x ??
          '';
      final server = selected.serverAddress ?? _defaultServerUrl;
      if (owner.isEmpty || server == null || server.isEmpty) {
        setState(() {
          _roster = const [];
          _rosterListId = null;
        });
        return;
      }
      final base = server.endsWith('/')
          ? server.substring(0, server.length - 1)
          : server;
      final url = '$base/api/$owner/channels/${selected.slug}/json';
      // MY CHANNELS: when this channel is a tab
      // on the viewer's own profile, the posts carry that tab as where they
      // were found, so a pin's "Go to feed" lands on it. Same exact-URL match
      // as the drawer's tab indicator, so the two always agree.
      final me = PublicOS.myPublicosAddress;
      String? tabKey;
      if (me != null) {
        try {
          final records =
              await PublicOSContacts.getRecordsByType(RecordType.router);
          for (final r in records) {
            if (r.routerSubtype == RouterSubtype.channel &&
                feedUrlKey(r.value) == feedUrlKey(url)) {
              tabKey = r.key;
              break;
            }
          }
        } catch (_) {}
      }
      if (!mounted || gen != _rosterGeneration) return;
      setState(() {
        _roster = [
          FeedSource(
            url: url,
            title: selected.name,
            foundAtAccountAddress: tabKey != null ? me : null,
            recordKey: tabKey,
          ),
        ];
        _rosterListId = null;
      });
      return;
    }

    if (selected is FeedList) {
      // Single-flagged lists render as the wrapped feed itself — a roster of
      // one with its via, and NO listId (the surface is the feed's own page,
      // not a list).
      if (selected.isSingle) {
        final feed = _singleFeedByListId[selected.id];
        if (feed != null) {
          final foundAtAddr = feed.feedFoundAtAccountAddress;
          setState(() {
            _roster = [
              FeedSource(
                url: feed.feedUrl,
                title: feed.feedTitle,
                foundAtContact: (foundAtAddr != null && foundAtAddr.isNotEmpty)
                    ? _resolvedContacts[foundAtAddr]
                    : null,
                foundAtAccountAddress: foundAtAddr,
                recordKey: feed.feedRecordKey,
                gone: _goneSingleListIds.contains(selected.id),
              ),
            ];
            _rosterListId = null;
          });
          return;
        }
        // Metadata not loaded yet — the resolver below covers it (a single
        // list resolves to its one feed, which is the same roster).
      }
      List<FollowedFeed> followed;
      try {
        followed = await PublicOSFollows.resolveListItems(selected.id);
      } catch (_) {
        followed = const [];
      }
      if (!mounted || gen != _rosterGeneration) return;
      // The single metadata landed while we resolved — it is the authority
      // (it knows a gone channel; the resolver above silently drops it).
      if (selected.isSingle && _singleFeedByListId[selected.id] != null) {
        return _deriveRosterSelection();
      }
      setState(() {
        _roster = followed.map(FeedSource.fromFollowedFeed).toList();
        _rosterListId = selected.isSingle ? null : selected.id;
      });
      return;
    }

    // Bookmarks / Discover / no selection — no post roster.
    setState(() {
      _roster = null;
      _rosterListId = null;
    });
  }

  /// Stable identity for the current source — drives the `ValueKey` so a
  /// selection change rebuilds the PostsList with fresh state.
  String get _sourceKey {
    switch (_selected) {
      case FeedsView.bookmarks:
        return 'bookmarks';
      case FeedsView.hotPosts:
      case FeedsView.hotFeeds:
      case FeedsView.latest:
        return 'explore-${(_selected as FeedsView).name}';
      case Channel ch:
        return 'channel-${ch.id}';
      case FeedList list:
        if (list.isSingle && _singleFeedByListId[list.id] != null) {
          return 'single-${list.id}';
        }
        return 'list-${list.id}';
      case FeedSource feed:
        return 'feed-${feed.url}';
      default:
        return 'none';
    }
  }

  @override
  void initState() {
    super.initState();
    ExploreSectionPrefs.warm(); // the drawer's EXPLORE open/closed, read before it opens

    // A pending "Go to feed" lands before the cold-start bootstrap, which
    // only picks a default when nothing is selected.
    if (_takeFocusFeed() case final feed?) _selected = feed;
    _loadData();
    _loadSettings();

    // post_card is a verbatim port several widgets below us and cannot reach
    // this state directly; it calls AppNav.toPost / toPostSource, which land
    // here. Registered for as long as Feeds is mounted (cleared in dispose, so a
    // stale handler can't fire into a dead State).
    AppNav.onOpenPost = (builder) {
      if (!mounted) return;
      setState(() => _openPost = builder);
    };
    AppNav.onOpenPostSource = (builder) {
      if (!mounted) return;
      setState(() => _openPostSource = builder);
    };
    AppNav.onOpenFlow = (page) {
      if (!mounted) return Future<Object?>.value();
      return _openFlowPage(page);
    };
  }

  Future<void> _loadSettings() async {
    try {
      final titleSizeRecord =
          await PublicOSSettings.getSetting('rss_feeds_title_text_size');
      final descSizeRecord =
          await PublicOSSettings.getSetting('rss_feeds_description_text_size');
      final trimRecord =
          await PublicOSSettings.getSetting('rss_feeds_trim_chars');
      final layoutRecord =
          await PublicOSSettings.getSetting('rss_feeds_layout_mode');
      final widthRecord = await PublicOSSettings.getSetting(kReadingWidthKey);
      if (mounted) {
        setState(() {
          if (titleSizeRecord != null) {
            _titleTextSize = double.parse(titleSizeRecord.value);
          }
          if (descSizeRecord != null) {
            _descriptionTextSize = double.parse(descSizeRecord.value);
          }
          if (trimRecord != null) {
            final parsed = int.tryParse(trimRecord.value);
            _trimChars = (parsed != null && parsed > 0) ? parsed : null;
          }
          if (layoutRecord != null) {
            _layoutMode = parsePostLayoutMode(layoutRecord.value);
          }
          if (widthRecord != null) {
            _readingMaxWidth = parseReadingWidth(widthRecord.value);
          }
        });
      }
    } catch (e) {
      print('Error loading RSS feed settings: $e');
    }
  }

  @override
  void dispose() {
    AppNav.onOpenPost = null;
    AppNav.onOpenPostSource = null;
    AppNav.onOpenFlow = null;
    _scrollController.dispose();
    _listCardGone.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FeedsPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_takeFocusFeed() case final feed?) _openFocusFeed(feed);
  }

  /// "Go to feed": remember what we were reading (the first one, if feeds
  /// chain) so ← can return to it, then show the feed.
  void _openFocusFeed(FeedSource feed) {
    final current = _selected;
    if (current is! FeedSource && current != null) {
      _returnSelection = current;
      _returnOffset =
          _scrollController.hasClients ? _scrollController.offset : null;
    }
    _select(feed);
  }

  Future<void> _copyFeedUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.feedReaderPageFeedUrlCopied),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// ← : back to what "Go to feed" replaced, at the same scroll position.
  void _goBackFromFeed() {
    final target = _returnSelection;
    if (target == null) return;
    _pendingRestoreOffset = _returnOffset;
    _returnSelection = null;
    _returnOffset = null;
    _select(target);
  }

  /// The shell's pending focus feed, once per token.
  FeedSource? _takeFocusFeed() {
    final feed = widget.focusFeed;
    if (feed == null || widget.focusToken <= _appliedFocusToken) return null;
    _appliedFocusToken = widget.focusToken;
    return feed;
  }

  /// Same membership scan as the Browser's channel follow: in ANY list.
  Future<void> _checkSelectedFeedFollowed(String url) async {
    var inAnyList = false;
    try {
      for (final list in await PublicOSFeedLists.getUserLists()) {
        final feeds = await PublicOSFeedLists.getFeedsInList(list.id);
        if (feeds.any((f) => feedUrlKey(f.feedUrl) == feedUrlKey(url))) {
          inAnyList = true;
          break;
        }
      }
    } catch (_) {}
    if (mounted && _selectedFeed?.url == url) {
      setState(() => _selectedFeedFollowed = inAnyList);
    }
  }

  /// The follow button on a feed opened by URL — the Browser channel tab's.
  Future<void> _followSelectedFeed() async {
    final feed = _selectedFeed;
    if (feed == null) return;
    final result = await showAddToListsSheet(
      context,
      feedUrl: feed.url,
      feedTitle: feed.title,
      feedDescription: null,
      feedFoundAtAccountAddress: feed.foundAtAccountAddress,
      feedRecordKey: feed.recordKey,
    );
    if (result == true) {
      _checkSelectedFeedFollowed(feed.url);
      _loadData(silent: true);
    }
  }

  /// DESKTOP DELTA: the client opens a bottom sheet here; desktop pushes the
  /// settings onto the reading column's detail stack.
  /// The live on-change callbacks are the client's, unchanged — edits still
  /// repaint the posts underneath in real time, which is the whole point of the
  /// live preview.
  void showSettingsSheet() {
    setState(() => _openSettings = true);
  }

  /// The client pushes `ManageServerPage` as a
  /// route; desktop hosts it in the reading column via the flow host. Body of
  /// the resolution logic is the client's, verbatim.
  Future<void> _navigateToServerManagement(String? serverAddress) async {
    // Use the same resolved URL that channels actually use (user selection -> SSP -> custom)
    String? resolvedAddress =
        serverAddress ?? await PublicOSSsp.getActiveFeedServerUrl();

    if (resolvedAddress == null || !mounted) return;

    final sspInfo = await PublicOSSsp.getSSPServerInfo();
    final isSSP = sspInfo != null && sspInfo.apiUrl == resolvedAddress;
    final label = isSSP
        ? (sspInfo!.title.isNotEmpty ? sspInfo.title : sspInfo.slug)
        : resolvedAddress;

    _openFlowPage(ManageServerPage(
      serverUrl: resolvedAddress,
      serverLabel: label,
      isSSP: isSSP,
      sspSlug: isSSP ? sspInfo!.slug : null,
    ));
  }

  /// Opens the glass ChannelSettingsPage for a channel the user owns.
  /// Separate from `_navigateToServerManagement` —
  /// that still handles the server-wide concerns (media quota, channel list,
  /// tab router records) via the drawer's "Manage server" row.
  ///
  /// Pops with `true` when the channel was deleted — we drop the selection
  /// and trigger a reload. For rename/edit it pops with `null` (the page
  /// handles its own in-page refresh), so we just re-pull the channel list
  /// to pick up the new slug/name.
  Future<void> _openManageChannelPage(Channel channel) async {
    final result = await _openFlowPage(ChannelSettingsPage(channel: channel));
    if (!mounted) return;
    if (result == true) {
      // Deleted — drop selection if it's still the one we opened.
      setState(() {
        if (_selectedChannel?.id == channel.id) {
          _selected = null;
        }
      });
    }
    // Refresh either way so renamed channels pick up the new slug/name.
    _loadData(silent: true);
  }

  /// JSON-feed URL for [channel], or null if we can't synthesize it (no
  /// server address on the channel, or the local account isn't loaded
  /// yet). The shape must match `ManageServerPage._channelJsonUrl` so
  /// records written by either path round-trip through the same equality
  /// check.
  String? _channelJsonUrl(Channel channel) {
    final addr = PublicOS.myPublicosAddress;
    final server = channel.serverAddress;
    if (addr == null || server == null) return null;
    return '$server/api/$addr/channels/${channel.slug}/json';
  }

  /// Reads every `RouterSubtype.channel` record on the local contact into
  /// `_tabUrls`. Called from `_loadData()` and after each tab mutation
  /// so the drawer rows can render their isInTabs state from membership
  /// on a synced Set.
  Future<void> _loadExistingTabUrls() async {
    try {
      final records =
          await PublicOSContacts.getRecordsByType(RecordType.router);
      final urls = records
          .where((r) => r.routerSubtype == RouterSubtype.channel)
          .map((r) => r.value)
          .toSet();
      if (mounted) setState(() => _tabUrls = urls);
    } catch (_) {}
  }

  /// Pin [channel] as a router tab by writing a `channel.<slug>` router
  /// record. Mirrors `ManageServerPage._addChannelAsTab`.
  Future<void> _addChannelAsTab(Channel channel) async {
    final url = _channelJsonUrl(channel);
    if (url == null) return;
    final record = Record.asRouter(
      key: Record.channelTabKey(channel.slug),
      routerSubtype: RouterSubtype.channel,
      value: url,
      name: channel.name,
    );
    final ok = await PublicOSContacts.setRecord(record);
    if (ok && mounted) await _onTabsChanged();
  }

  /// Remove the router tab pointing at [channel]'s JSON URL. Mirrors
  /// `ManageServerPage._removeChannelFromTabs`.
  Future<void> _removeChannelFromTab(Channel channel) async {
    final url = _channelJsonUrl(channel);
    if (url == null) return;
    try {
      final records =
          await PublicOSContacts.getRecordsByType(RecordType.router);
      final tab = records.firstWhere(
        (r) => r.routerSubtype == RouterSubtype.channel && r.value == url,
        orElse: () => throw StateError('Tab not found'),
      );
      final ok = await PublicOSContacts.deleteRecord(tab.key);
      if (ok && mounted) await _onTabsChanged();
    } catch (_) {
      // Record was already gone — refresh anyway to drop any stale state.
      if (mounted) await _onTabsChanged();
    }
  }

  /// A channel was added to or removed from the profile's tabs: refresh the
  /// drawer's indicators AND re-derive the roster, so an open MY CHANNELS
  /// pick picks up (or drops) its tab right away and a pin made now is right.
  Future<void> _onTabsChanged() async {
    await _loadExistingTabUrls();
    if (mounted && _selected is Channel) await _deriveRoster();
  }

  /// Hosted in the reading column.
  Future<void> _showCreateChannelPage() async {
    final created = await _openFlowPage(const CreateChannelPage());
    if (created != null && mounted) _loadData();
  }

  // The DEFAULT list \u2014 the one onboarding seeds and the empty state
  // bootstraps. It is NOT special: renameable, deletable, and behaves exactly
  // like every other list. This name is only a bootstrap default; once the
  // user renames it nothing here matches anymore, which is the point.
  static const String _defaultListName = 'Following';
  static const String _defaultListIcon = '\u{1F47E}';

  /// Bootstrap a starter list for a user who has NO lists at all, so the feeds
  /// pane is never a dead end.
  ///
  /// Gated on "zero lists", NOT on "no list named Following" \u2014 that difference
  /// is the whole point. Keying it on the name made the default list
  /// undeletable and unrenameable in practice: `_loadData` runs on init, on
  /// refresh, and right after any list mutation, so deleting it resurrected it
  /// on the very next load, and renaming it spawned a second empty one beside
  /// the renamed list. Deleting your LAST list still gets you a fresh one,
  /// which is the only case a bootstrap is actually for.
  Future<List<FeedList>> _ensureDefaultList(List<FeedList> fetched) async {
    if (fetched.isNotEmpty) return fetched;
    try {
      final created = await PublicOSFeedLists.createList(
        _defaultListName,
        icon: _defaultListIcon,
      );
      if (created == null) return fetched;
      return [...fetched, created];
    } catch (_) {
      return fetched;
    }
  }

  /// Presentational only \u2014 float the bootstrap-named list to the top when it is
  /// still called that. Carries no behavior; a renamed list simply sorts with
  /// the rest.
  List<FeedList> _sortDefaultFirst(List<FeedList> lists) {
    final first = lists.where((l) => l.name == _defaultListName);
    final rest = lists.where((l) => l.name != _defaultListName);
    return [...first, ...rest];
  }

  // There is deliberately no cold-start fallback for an empty Following: an
  // empty list is a fine place to land, and onboarding seeds the PublicOS
  // *account* follow, so the default list has content from first boot.

  /// Public refresh hook — re-pulls lists + channels.
  ///
  /// [silent] — when true, does NOT show the loading spinner. The previous
  /// content stays on screen while the fetch runs in the background and
  /// state swaps in once it completes. Used by the explorer shell when
  /// popping back from a pushed route (browser / post detail / etc.) so
  /// the feeds view doesn't flash a spinner on every pop.
  ///
  /// Default (loud) is used by the bottom-nav tap and by the initial mount.
  Future<void> refresh({bool silent = false}) => _loadData(silent: silent);

  Future<void> _loadData({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) setState(() => _isLoading = true);

    // DESKTOP DELTA: the client awaits lists AND channels
    // in one `Future.wait`, so the slow network read (getChannelsFromAllServers)
    // holds the whole drawer empty behind the unified spinner until it returns.
    // Split: lists are a LOCAL read — paint them and start the first list's
    // content immediately; the user's own channels land in their own setState
    // whenever the network answers, filling their drawer section late.
    PublicOSChannels.getChannelsFromAllServers().then((resp) {
      if (!mounted) return;
      final channels = resp.success && resp.data != null
          ? resp.data!.channels
          : <Channel>[];
      final bool takeFallback = _listsLoaded &&
          _selected == null &&
          _lists.isEmpty &&
          channels.isNotEmpty;
      setState(() {
        _channels = channels;
        // The old combined path's last-resort cold-start landing: no lists at
        // all (bootstrap failed) → fall back to the first channel. Gated on
        // `_listsLoaded` so a network read that somehow beats the local lists
        // read can't steal the initial selection from the first list.
        if (takeFallback) {
          _selected = channels.first;
          _postsLoading = true;
        }
      });
      if (takeFallback) _deriveRoster();
    }).catchError((_) {
      if (mounted) setState(() => _channels = []);
    });

    try {
      final fetchedLists = await PublicOSFeedLists.getUserLists();
      // The reader's own drawer order wins over default-first once they have
      // dragged a row (FeedsNavPrefs; a local settings read).
      final lists = FeedsNavPrefs.applyOrder(
        _sortDefaultFirst(await _ensureDefaultList(fetchedLists)),
        await FeedsNavPrefs.listOrder(),
      );
      // Only a true cold start reads where to land (Reading settings →
      // Landing).
      final landingRaw =
          _selected == null ? await FeedsNavPrefs.landing() : null;

      if (!mounted) return;

      // Bootstrap a default view only on a genuine cold start — when nothing
      // is selected at all. `_selected == null` is the *whole* check:
      // Discover and Bookmarks are values of the same field, so a re-entrant
      // load (silent route-pop refresh, `onFeedFollowed`) cannot be
      // mistaken for "no selection".
      //
      // Or when the selected list no longer exists (twin of the client).
      // `_selected` holds the FeedList itself, so a list deleted while it is
      // open (Manage Lists, another device, a sync) would otherwise stay
      // selected, its header over posts from a list that is gone. It lands
      // where a fresh open does.
      final sel = _selected;
      final selectedListGone =
          sel is FeedList && !lists.any((l) => l.id == sel.id);
      final needsInitialSelect = _selected == null || selectedListGone;

      // Cold-start landing: the first list. `_sortDefaultFirst` has already
      // floated the default list to the top, so that is what a fresh user
      // opens on.
      //
      // No emptiness test, deliberately. The old version counted
      // `getFeedsInList` rows and bounced to a hunted-down Newsletter single
      // whenever the default list had none — which, since onboarding started
      // seeding the ACCOUNT rather than channel snapshots, is the normal state
      // of a healthy Following list. An empty list is a fine place to land, so
      // there is nothing to detect and nowhere to bounce to.
      //
      // A cold start lands where the reader chose
      // (`resolveLanding`: never chosen = the first list, a chosen list that
      // is gone = Latest posts). A list deleted while open still lands on the
      // first list.
      final Object? initialSelection = !needsInitialSelect
          ? null
          : _selected == null
              ? FeedsNavPrefs.resolveLanding(landingRaw, lists)
              : (lists.isNotEmpty ? lists.first : null);

      // Fallback server base for channels that carry no serverAddress —
      // needed to build a channel pick's feed url. Local DB read.
      try {
        _defaultServerUrl =
            (await PublicOSSsp.getCurrentFeedServer())?.feedServerAddress;
      } catch (_) {}
      if (!mounted) return;

      setState(() {
        _lists = lists;
        _listsLoaded = true;
        if (needsInitialSelect) {
          // Prefer the first list; if the bootstrap somehow left zero lists,
          // fall back to whatever channels have already landed (the late
          // channel arrival covers the other ordering).
          _selected = initialSelection ??
              (_channels.isNotEmpty ? _channels.first : null);
        }
        if (!silent) {
          _isLoading = false;
          // A loud load drops the body to a SizedBox while `_isLoading`, so
          // clearing it remounts PostsList, which then loads its posts. Bridge
          // the unified spinner across that handoff (same overlay element, no
          // animation reset) until the remounted PostsList reports done.
          if (_selectionShowsPosts(_selected)) {
            _postsLoading = true;
          }
        }
      });

      // The host derives the roster — every path through _loadData
      // (cold start, silent refresh, list mutation callbacks) re-derives, so
      // roster changes always reach PostsList as a fresh `feeds` value.
      _deriveRoster();

      // Fire-and-forget — populate single-list metadata for the drawer +
      // inline header. Doesn't block initial render.
      _loadSingleListMetadata(lists);
      // Same shape — the drawer's Add-as-Tab toggle needs the current
      // set of pinned router URLs but the row state isn't blocking on it.
      _loadExistingTabUrls();
      // PostsList owns post loading and refreshes itself on source change /
      // pull-to-refresh — no explicit per-source load call here.
    } catch (e) {
      if (mounted) {
        setState(() {
          _lists = [];
          _listsLoaded = true; // lets the late-channels fallback act
          if (!silent) _isLoading = false;
        });
      }
    }
  }

  /// Per-`is_single`-list: pull the first feed and resolve its
  /// `feedFoundAtAccountAddress` contact. Drives drawer + inline-header
  /// single-row rendering. Updates `_singleFeedByListId` and merges any
  /// newly-resolved contacts into `_resolvedContacts` on completion.
  Future<void> _loadSingleListMetadata(List<FeedList> lists) async {
    final singles = lists.where((l) => l.isSingle).toList();
    if (singles.isEmpty) {
      if (mounted && _singleFeedByListId.isNotEmpty) {
        setState(() => _singleFeedByListId = {});
      }
      return;
    }
    // Collect every single's first feed FIRST, then re-resolve the whole set in
    // one pass. `resolveListFeeds` resolves each owner once per call, so
    // batching means N singles owned by the same account cost one profile read,
    // not N.
    final storedRows = <ListFeed>[];
    for (final list in singles) {
      try {
        final feeds = await PublicOSFeedLists.getFeedsInList(list.id);
        if (feeds.isNotEmpty) storedRows.add(feeds.first);
      } catch (_) {
        // Skip — list survives without single rendering, falls back to
        // multi-feed shape.
      }
    }

    // A single is a CHANNEL follow tracked by `record.key`, so its stored URL
    // is only ever a snapshot. Re-resolve against the owner's current records
    // before rendering: a re-pointed channel picks up its new URL, a raw URL
    // (no record key) passes through verbatim, and a channel the owner has
    // deleted comes back as GONE: the single keeps its stored row (name + via
    // for the header) and the roster renders "Channel not found" instead of
    // fetching.
    List<ListFeed> rows;
    List<ListFeed> goneRows = const [];
    try {
      final resolved = await PublicOSFollows.resolveListFeedsDetailed(storedRows);
      rows = resolved.live;
      goneRows = resolved.gone;
    } catch (_) {
      rows = storedRows; // resolution is best-effort; stale beats empty
    }

    final feedsByList = <int, ListFeed>{};
    final goneIds = {for (final r in goneRows) r.listId};
    final addressesToResolve = <String>{};
    for (final row in [...rows, ...goneRows]) {
      feedsByList[row.listId] = row;
      final addr = row.feedFoundAtAccountAddress;
      if (addr != null && addr.isNotEmpty) addressesToResolve.add(addr);
    }
    if (!mounted) return;
    final newContacts = Map<String, Contact>.from(_resolvedContacts);
    for (final address in addressesToResolve) {
      if (newContacts.containsKey(address)) continue;
      try {
        var contact = await PublicOSContacts.searchContacts(address);
        contact ??= await PublicOSContacts.resolveByIdentifier(address);
        if (contact != null) newContacts[address] = contact;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _singleFeedByListId = feedsByList;
      _goneSingleListIds = goneIds;
      _resolvedContacts = newContacts;
    });
    // The roster may have derived before this landed (cold open falls back to
    // `resolveListItems`, which drops a gone channel → an empty roster → "No
    // posts yet"). Re-derive only when the open single disagrees.
    final sel = _selected;
    if (sel is FeedList && sel.isSingle) {
      final r = _roster;
      final gone = goneIds.contains(sel.id);
      if (r != null && (r.length != 1 || r.first.gone != gone)) {
        _deriveRoster();
      }
    }
  }

  /// "Unfollow" on the Channel-not-found screen of a single: delete the
  /// single list (exactly what Manage Lists' trash does), then reload.
  Future<void> _unfollowSingle(FeedList list) async {
    final ok = await PublicOSFeedLists.deleteList(list.id);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.manageListsSheetFailedDeleteList)),
      );
      return;
    }
    await _loadData();
  }

  /// The single entry point for changing the feeds selection. `selection`
  /// is a [FeedList], a [Channel], or a [FeedsView] value — assigning it is
  /// the whole state change; there are no sibling flags to clear, so the
  /// modes cannot desync. No-ops when the selection is unchanged.
  ///
  /// PostsList re-loads via its `didUpdateWidget` + `ValueKey(_sourceKey)`
  /// rebuild on source change — no loader call needed here.
  void _select(Object? selection) {
    if (_sameSelection(_selected, selection)) return;
    setState(() {
      _selected = selection;
      _listCardGone.value = false;
      // Picking anything but a feed-by-URL ends the "Go to feed" detour.
      if (selection is! FeedSource) _returnSelection = null;
      // Leaving the detail stack: a new selection means a new post list, so an
      // open post from the PREVIOUS feed must not survive the switch. Settings
      // closes too -- the drawer stays visible while it is open, so clicking a
      // feed from in there must actually take you to that feed rather than
      // silently swapping the content hidden behind the settings page. Same
      // rule for a hosted flow page (compose / manage): the drawer click must
      // actually go somewhere visible.
      _openPost = null;
      _openPostSource = null;
      _openSettings = false;
      _openFlow = null;
      // A different selection remounts PostsList (its ValueKey changes) and it
      // will load — keep the unified spinner up from this frame so there's no
      // gap before PostsList reports its own loading.
      _postsLoading = _selectionShowsPosts(selection);
      // Cleared synchronously so a stale roster never renders under the new
      // selection; `_deriveRoster` repopulates it.
      _roster = null;
      _rosterListId = null;
    });
    _deriveRoster();
  }

  /// Whether [selection] renders a `PostsList` (vs Discover's own browser or
  /// the onboarding empty state). Drives the eager `_postsLoading` bridge.
  bool _selectionShowsPosts(Object? selection) =>
      selection != null && selection != FeedsView.discover;

  /// PostsList load-state reported up — the other half of the unified spinner.
  void _onPostsLoadingChanged(bool loading) {
    if (!mounted || _postsLoading == loading) return;
    setState(() => _postsLoading = loading);
    // A finished load is when a first-seen advertisement lands its pref row —
    // re-check so the sign-in toggle appears without a reopen.
    if (!loading) _refreshSigninPref();
    // Back from "Go to feed": land where the reader was.
    final restore = _pendingRestoreOffset;
    if (!loading && restore != null) {
      _pendingRestoreOffset = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final pos = _scrollController.position;
        _scrollController.jumpTo(restore.clamp(0.0, pos.maxScrollExtent));
      });
    }
  }

  /// Selection equality. Lists and channels are compared by id — `_loadData`
  /// rebuilds them as fresh instances on every refresh, so identity would
  /// miss — everything else (the [FeedsView] enum values, null) by `==`.
  static bool _sameSelection(Object? a, Object? b) {
    if (a is FeedList && b is FeedList) return a.id == b.id;
    if (a is Channel && b is Channel) return a.id == b.id;
    if (a is FeedSource && b is FeedSource) return a.url == b.url;
    return a == b;
  }

  /// The channel-selector composer, hosted as a full page inside the reading
  /// column. Argument list is the client's, verbatim.
  Future<void> _showNewPostBottomSheet() async {
    // Inside one of the user's own channels the post targets it; anywhere
    // else (a list, Bookmarks, Discover) the channel last posted to, then
    // the first in the list.
    final initial = _selectedChannel ??
        await ComposePostPage.lastPostedChannel(_channels);
    if (!mounted) return;
    _openFlowPage(ComposePostPage(
      channels: _channels,
      initialChannel: initial,
      // PostsList owns the post list; bump its refreshTick so it re-fetches
      // and applies directly (no "New posts" chip) — the author should see
      // their post land, not be offered it. (A bare setState here does
      // nothing: the ValueKey derives from the selection, which hasn't
      // changed, so the State survives and never reloads.)
      onPostSaved: () {
        if (mounted) setState(() => _postsRefreshTick++);
      },
    ));
  }

  /// Rename / re-icon a list. The client's `edit_list_sheet` and
  /// `manage_lists_sheet` are ported and re-shelled as dialogs.
  Future<void> _showEditListSheet(FeedList list) async {
    final updated = await showEditListSheet(context, existing: list);
    if (updated == null || !mounted) return;
    await _loadData(silent: true);
  }

  /// The full two-tier manage surface: followed ACCOUNTS (expand + per-channel
  /// mute) then individual feeds, for every list.
  ///
  /// Dismissing a manage dialog re-derives the roster from the database and
  /// hands it to PostsList, which patches its deck against what it was showing
  /// (posts of removed feeds out, added feeds fetched and slotted in by date)
  /// and does nothing when the roster came back the same. No dirty flag from
  /// the dialog (one cannot be trusted), no reload tick (reloading the whole
  /// deck every time makes it flicker). The list header re-reads its
  /// counts in place.
  Future<void> _showManageListsSheet() async {
    await showManageListsSheet(
      context,
      lists: _lists,
      onListsChanged: () {},
    );
    // Lists can be renamed or deleted here, so the metadata reloads too.
    if (!mounted) return;
    await _loadData(silent: true);
    await _rederiveAfterListChange();
  }

  Future<void> _showManageListSheet(FeedList list) async {
    await showManageListSheet(
      context,
      list: list,
      onChanged: () {},
    );
    await _rederiveAfterListChange();
  }

  Future<void> _rederiveAfterListChange() async {
    if (!mounted) return;
    await _deriveRoster();
  }

  /// The content beneath the unified spinner overlay. Always returns a real
  /// widget (never gated to a spinner here — the overlay owns that), so the
  /// Stack's content slot keeps a stable position across loads.
  Widget _buildContent(ThemeData theme) {
    // Detail stack first — deepest wins. Source details sit ON TOP of a post's
    // detail, so Back from source returns to the post, and Back from the post
    // returns to the list.
    // A hosted flow page (compose / create channel / manage channel / manage
    // server) beats everything: it is the page the user just asked for, and
    // whatever they were reading is restored the moment it pops.
    final flow = _openFlow;
    if (flow != null) {
      return KeyedSubtree(key: ObjectKey(flow), child: flow);
    }
    // Settings sits on top of the rest: Back drops you onto whatever you were
    // reading before (a post's detail, or the list) -- it does not clear it.
    if (_openSettings) {
      return FeedsSettingsView(
        titleSize: _titleTextSize,
        bodySize: _descriptionTextSize,
        trimChars: _trimChars,
        layoutMode: _layoutMode,
        lists: _lists,
        singleFeedByListId: _singleFeedByListId,
        onTitleChanged: (size) => setState(() => _titleTextSize = size),
        onBodyChanged: (size) => setState(() => _descriptionTextSize = size),
        onTrimChanged: (chars) => setState(() => _trimChars = chars),
        onLayoutChanged: (mode) => setState(() => _layoutMode = mode),
        // The very next fetch honours the new posture — the sheet's own rule.
        onAutoSigninChanged: (_) => setState(() => _postsRefreshTick++),
        readingWidth: _readingMaxWidth,
        onReadingWidthChanged: (w) => setState(() => _readingMaxWidth = w),
        onBack: () => setState(() => _openSettings = false),
      );
    }

    // The caller built these (see the field docs) -- we only hand back `onBack`.
    // KeyedSubtree + ObjectKey on the builder: a NEW builder closure means a new
    // post, so the page remounts rather than reusing the previous post's State.
    final openSource = _openPostSource;
    if (openSource != null) {
      return KeyedSubtree(
        key: ObjectKey(openSource),
        child: openSource(() => setState(() => _openPostSource = null)),
      );
    }
    final open = _openPost;
    if (open != null) {
      return KeyedSubtree(
        key: ObjectKey(open),
        child: open(() => setState(() => _openPost = null)),
      );
    }

    if (_isViewingDiscover) {
      return DiscoverBrowser(onFeedFollowed: _loadData);
    }
    // While the lists/channels metadata loads there's no selection yet — render
    // nothing under the overlay (the onboarding empty state would otherwise
    // flash behind the spinner).
    if (_isLoading) return const SizedBox.shrink();
    // Bookmarks leave the feed abstraction — their own surface.
    // Explore: what the network is reading, from the user's own SSP. Own
    // surface like Bookmarks — no roster.
    if (_isViewingExplore) {
      return ExploreView(
        // One view per row: without a key the State (and its source) is
        // reused across rows, so a row change loads nothing and the spinner
        // waits forever.
        key: ValueKey('explore-${_exploreMode.name}'),
        mode: _exploreMode,
        color: widget.color,
        titleTextSize: _titleTextSize,
        descriptionTextSize: _descriptionTextSize,
        bodyMaxChars: _trimChars,
        layoutMode: _layoutMode,
        scrollController: _scrollController,
        showFullScreenLoader: false,
        refreshTick: _exploreRefreshTick,
        onLoadingChanged: _onPostsLoadingChanged,
        // Explore loads like a feed: the hint and Latest's "N new" chip go
        // to the same header slots a list uses.
        onHeldDocked: (w) {
          if (!mounted) return;
          setState(() => _dockedNewChip = w);
        },
        onRefreshingChanged: (v) {
          if (!mounted || _postsRefreshing == v) return;
          setState(() => _postsRefreshing = v);
        },
      );
    }
    if (_isViewingBookmarks) {
      return BookmarksView(
        color: widget.color,
        titleTextSize: _titleTextSize,
        descriptionTextSize: _descriptionTextSize,
        bodyMaxChars: _trimChars,
        layoutMode: _layoutMode,
        scrollController: _scrollController,
        showFullScreenLoader: false,
        onLoadingChanged: _onPostsLoadingChanged,
      );
    }
    if (_selected == null) return _buildOnboardingState(theme);
    final roster = _roster;
    // Roster still deriving — the unified spinner (raised in `_select` /
    // `_loadData`) covers this gap; render nothing beneath it.
    if (roster == null) return const SizedBox.shrink();
    return PostsList(
      // Bumping the key on selection change forces a fresh State instance —
      // cleaner than relying on didUpdateWidget when bookmarks toggle vs.
      // list/channel switches.
      key: ValueKey(_sourceKey),
      // The list's own "+" posts INTO the feed on screen and lights only
      // where the server says this reader may post. On our own feed-style
      // channels the pane's post button is the one, so it stays off there
      // (same rule as the client's Feeds tab).
      showNewPostButton:
          _selectedChannel == null || _selectedChannel!.isOpen,
      feeds: roster,
      listId: _rosterListId,
      displayName: _selectedItemName,
      color: widget.color,
      titleTextSize: _titleTextSize,
      descriptionTextSize: _descriptionTextSize,
      bodyMaxChars: _trimChars,
      layoutMode: _layoutMode,
      scrollController: _scrollController,
      // Unified spinner: PostsList stays blank while loading and reports its
      // load state up; the overlay in `build` shows the single spinner.
      showFullScreenLoader: false,
      refreshTick: _postsRefreshTick,
      // A regular list (not a single) shows who it follows where a channel
      // shows its description.
      listHeader: switch (_selected) {
        FeedList l when _rosterListId == l.id => () => ListHeaderCard(
              key: _listCardKey,
              summary: _listSummary,
              onManage: () => _showManageListSheet(l),
            ),
        _ => null,
      },
      onLoadingChanged: _onPostsLoadingChanged,
      onUnfollowGone: switch (_selected) {
        FeedList l when l.isSingle => () => _unfollowSingle(l),
        _ => null,
      },
      onHeldDocked: (w) {
        if (!mounted) return;
        setState(() => _dockedNewChip = w);
      },
      onRefreshingChanged: (v) {
        if (!mounted || _postsRefreshing == v) return;
        setState(() => _postsRefreshing = v);
        if (!v) _refreshSigninPref();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GlassTokens.of(context);

    // FAB only for non-forum channels (ForumView has its own FAB). Verbatim.
    final showFab = _selectedChannel != null &&
        !_isViewingBookmarks &&
        !_selectedChannel!.isOpen;

    // THE DESKTOP DELTA. Mobile stacks [inline header -> content] and hides the
    // navigation behind a hamburger; desktop is wide, so the same
    // FeedsNavigationDrawer widget is simply always mounted on the left. Shape
    // is the Contacts template: ShellSplit's two floating panels.
    return ShellSplit(
      listWidth: FeedsPane.listWidth,
      list: FeedsNavigationDrawer(
            lists: _lists,
            channels: _channels,
            selected: _selected,
            singleFeedByListId: _singleFeedByListId,
            resolvedContacts: _resolvedContacts,
            onListSelected: _select,
            onChannelSelected: _select,
            onBookmarksSelected: () => _select(FeedsView.bookmarks),
            onDiscoverSelected: () => _select(FeedsView.discover),
            onExploreSelected: _select,
            onManageLists: _showManageListsSheet,
            onCreateChannel: _showCreateChannelPage,
            onSettings: showSettingsSheet,
            onManageServer: () => _navigateToServerManagement(null),
            onManageChannel: _openManageChannelPage,
            tabUrls: _tabUrls,
            onAddAsTab: _addChannelAsTab,
            onRemoveFromTab: _removeChannelFromTab,
            // No onClose: the pane is permanent, so the drawer shows no X
            // (the client passes _closeDrawer).
            onListsReordered: (lists) {
              setState(() => _lists = lists);
              FeedsNavPrefs.setListOrder(lists);
            },
            onEditList: (list) {
              // EVERY list is editable now. The old guard existed to protect a
              // permanent "Following" whose name carried behavior; nothing
              // keys off the name any more, so the default list renames and
              // deletes like any other.
              setState(() => _selected = list);
              _showEditListSheet(list);
            },
      ),
      content: Column(
            children: [
              _buildInlineHeader(theme),
              // "Go to feed": the feed's identity line (shared with the
              // client's FeedReaderPage) — favicon + name. Description and
              // details come from the posts list's header card below.
              if (_selectedFeed case final feed?)
                _readingColumn(FeedReaderHeader(
                  key: ValueKey(feed.url),
                  feedUrl: feed.url,
                  title: feed.title,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                )),
              Expanded(
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  // Content layer + the single unified spinner overlay. The
                  // overlay is the LAST child in every phase and carries a
                  // stable key, so Flutter reuses the same element (and its
                  // running orbit controller) across the metadata->posts
                  // handoff instead of disposing + recreating it. Verbatim.
                  body: Stack(
                    children: [
                      Positioned.fill(
                        child: ContentMetricsListener(
                          onMetrics: _onContentMetrics,
                          child: _readingColumn(_buildContent(theme)),
                        ),
                      ),
                      // The BIG, blocking loader — and it means exactly one
                      // thing: **there is nothing to look at yet** (a cold cache,
                      // or the shell's own metadata still loading).
                      //
                      // It deliberately does NOT show during phase 2 of the feed
                      // load. Once the cache has painted, the reader is already
                      // reading; covering their content with a spinner to say
                      // "there may be more soon" would be a lie about the state
                      // and would take the page away from them. That case is the
                      // pixel-rain hint at the far right of the title bar instead.
                      // (PostsList reports loading=false the moment the cache
                      // paints, so `_postsLoading` is already false here — this
                      // is the invariant that makes the split work.)
                      if (!_isViewingDiscover &&
                          !_openSettings &&
                          _openFlow == null &&
                          _openPost == null &&
                          _openPostSource == null &&
                          (_isLoading || _postsLoading))
                        const Positioned.fill(
                          key: ValueKey('feeds_unified_loader'),
                          child: PixelRainLoadingCorner(),
                        ),
                    ],
                  ),
                  floatingActionButton: showFab
                      ? FloatingActionButton(
                          heroTag: 'feeds_pane_fab',
                          onPressed: _showNewPostBottomSheet,
                          // The Contacts search box's colour, opaque so posts
                          // don't show through (the client's).
                          backgroundColor: Color.alphaBlend(
                            tokens.glassFill,
                            tokens.background,
                          ),
                          foregroundColor: tokens.starkWhite,
                          elevation: 0,
                          highlightElevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                                color: tokens.borderMedium, width: 1),
                          ),
                          child: const Icon(Icons.add_rounded, size: 22),
                        )
                      : null,
                ),
              ),
            ],
      ),
    );
  }

  /// Centre a reading-width column in the (much wider) desktop pane.
  ///
  /// **Desktop delta.** On a phone the post column IS the screen width, so the
  /// client never needed this. A maximised desktop window is ~2–3x that, and a
  /// post card stretched edge-to-edge reads badly — the eye loses the line start
  /// on the way back. [_readingMaxWidth] caps it; the pane's background, the
  /// header's divider and the scrollbar all stay full-bleed, so the pane still
  /// reads as a pane rather than a floating card.
  ///
  /// Applied to BOTH the header row and the content, so the title and the post
  /// cards share the same left edge. Wrap anything else that lands in this pane
  /// in the same helper, or it will silently fall out of alignment.
  Widget _readingColumn(Widget child) => Center(
        child: ConstrainedBox(
          // Not const: the width is a user setting now, so this rebuilds when
          // they pick a different preset. `double.infinity` = fill the pane.
          constraints: BoxConstraints(maxWidth: _readingMaxWidth),
          child: child,
        ),
      );

  Widget _buildInlineHeader(ThemeData theme) {
    final tokens = GlassTokens.of(context);
    // On forum channels the sort bar (just below us) provides its own
    // bottom underline — drop ours so we don't render two parallel lines.
    final isForumBody =
        _selectedChannel != null && _selectedChannel!.isOpen;

    // Single-flagged-list short-circuit — center body becomes
    // [favicon] feed_name · via [icon] displayName.
    final selList = _selectedList;
    final singleFeed = (selList != null && selList.isSingle)
        ? _singleFeedByListId[selList.id]
        : null;
    final isSingleSurface = selList != null &&
        selList.isSingle &&
        singleFeed != null &&
        !_isViewingBookmarks &&
        _selectedChannel == null;

    Widget centerBody;
    if (_selectedFeed != null) {
      // A feed opened by "Go to feed": its name + favicon live in the
      // FeedReaderHeader below (the client's FeedReaderPage);
      // the bar is ← (when there is somewhere to return) + the actions.
      centerBody = Align(
        alignment: Alignment.centerLeft,
        child: _returnSelection == null
            ? const SizedBox(height: 26)
            : InkResponse(
                onTap: _goBackFromFeed,
                radius: 18,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.arrow_back_rounded,
                      size: 18, color: tokens.starkWhite),
                ),
              ),
      );
    } else if (isSingleSurface) {
      centerBody = _buildSingleHeaderBody(
        feed: singleFeed,
        tokens: tokens,
      );
    } else {
      Widget leadingIcon;
      if (_isViewingExplore) {
        // The drawer row's own icon and tint.
        leadingIcon = Icon(exploreIcon(_selected as FeedsView),
            size: 20, color: tokens.connectedAccent);
      } else if (_isViewingBookmarks) {
        leadingIcon = Icon(Icons.bookmark_rounded,
            size: 20, color: tokens.fallbackAccent);
      } else if (_selectedChannel != null && _selectedChannel!.isOpen) {
        leadingIcon =
            Icon(Icons.forum_outlined, size: 20, color: tokens.starkWhite);
      } else if (_selectedChannel != null) {
        leadingIcon = _buildChannelHeaderIcon(_selectedChannel!);
      } else if (_selectedList != null &&
          _selectedList!.icon != null &&
          _selectedList!.icon!.isNotEmpty) {
        leadingIcon =
            Text(_selectedList!.icon!, style: const TextStyle(fontSize: 18));
      } else if (_selectedList != null) {
        leadingIcon =
            Icon(Icons.list_alt_rounded, size: 20, color: tokens.textDim);
      } else {
        leadingIcon =
            Icon(Icons.rss_feed_rounded, size: 20, color: tokens.textDim);
      }
      centerBody = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(child: SizedBox(width: 24, child: Center(child: leadingIcon))),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              _selectedItemName,
              style: TextStyle(
                color: tokens.starkWhite,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    // SSP management shortcut for owned channels — only thing that can
    // appear on the right side now that the chevron is gone.
    Widget? trailing;
    if (_selectedFeed case final feed?) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkResponse(
            onTap: _followSelectedFeed,
            radius: 18,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                _selectedFeedFollowed
                    ? Icons.bookmark_added_rounded
                    : Icons.bookmark_add_outlined,
                size: 18,
                color: tokens.starkWhite,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // ⋯ → Copy feed URL (the client FeedReaderPage's menu).
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded,
                size: 18, color: tokens.starkWhite),
            padding: EdgeInsets.zero,
            iconSize: 18,
            splashRadius: 18,
            tooltip: '',
            color: tokens.surfaceDeep,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: tokens.borderSubtle),
            ),
            onSelected: (v) {
              // Share copies what we hold (post_identity): the tab's
              // publicos.dev link when this feed is read through a profile's
              // tab, else the feed's own address.
              if (v == 'copy') {
                final at = feed.effectiveFoundAtAddress;
                final key = feed.recordKey;
                _copyFeedUrl(at != null &&
                        at.isNotEmpty &&
                        key != null &&
                        key.isNotEmpty
                    ? tabShareLink(foundAtAddress: at, tabKey: key)
                    : feed.url);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.content_copy_rounded,
                        size: 16, color: tokens.starkWhite),
                    const SizedBox(width: 10),
                    Text(
                      context.l10n.feedReaderPageCopyFeedUrl,
                      style: TextStyle(
                        color: tokens.starkWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
    if (_isViewingExplore) {
      trailing = Tooltip(
        message: context.l10n.desktopReload,
        child: InkResponse(
          onTap: () => setState(() => _exploreRefreshTick++),
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child:
                Icon(Icons.refresh_rounded, size: 18, color: tokens.starkWhite),
          ),
        ),
      );
    }
    if (_selectedChannel != null && !_isViewingBookmarks) {
      final isOwned = _channels.any((c) => c.id == _selectedChannel!.id);
      if (isOwned) {
        trailing = InkResponse(
          onTap: () => _openManageChannelPage(_selectedChannel!),
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.tune_rounded, size: 18, color: tokens.textDim),
          ),
        );
      }
    }

    // A regular list: once the scroll-away card has left the top, the list's
    // mini stack rides at the right edge, sliding up into place and back
    // down when the card returns. It is the one door to "Manage [list]" up
    // here; the card is the door at the top (there is no separate manage
    // button).
    Widget? listStack;
    if (selList != null &&
        !selList.isSingle &&
        !_isViewingBookmarks &&
        _selectedChannel == null) {
      final list = selList;
      final summary = _listSummary;
      if (summary != null && !summary.isEmpty) {
        listStack = ValueListenableBuilder<bool>(
          valueListenable: _listCardGone,
          // The icons fly in from the right one by one when the card
          // leaves, and out to the right when it returns (ported from the
          // client).
          builder: (_, gone, __) => ListMiniStackFlyIn(
            show: gone,
            summary: summary,
            tokens: tokens,
            onTap: () => _showManageListSheet(list),
            padding: const EdgeInsets.only(right: 4),
          ),
        );
      }
    }

    // DESKTOP DELTA. On mobile this whole header is a tap target that opens the
    // drawer, with a hamburger glyph as the cue. Here the drawer is the
    // permanent left pane, so BOTH are gone: no tap handler (there is nothing to
    // open) and no hamburger (nothing to hint at). What remains is the
    // header's other job -- naming the current selection -- so it is a plain
    // title bar, left-aligned rather than centre-aligned, since it has no
    // hamburger to balance against a trailing button.
    return Container(
      decoration: BoxDecoration(
        border: isForumBody
            ? null
            : Border(
                bottom: BorderSide(color: tokens.borderSubtle, width: 0.5),
              ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      // Same reading column as the content below, so the title lines up with the
      // post cards' left edge. The border above spans the full pane.
      child: _readingColumn(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
          child: Row(
            children: [
              Expanded(child: centerBody),
                // Right group, in order: [refresh hint] [refresh] [new posts] [sign-in
                // key] [list faces] [channel tune]. Each is a HeaderSlot:
                // it rises in from the header's bottom,
                // and when it leaves its width closes so the others slide
                // over. The title gives way (Expanded) instead of a fixed
                // right inset.
                HeaderSlot(
                  child: _postsRefreshing
                      ? const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: PixelRainLoadingWidget(size: 18),
                          ),
                        )
                      : null,
                ),
                // DESKTOP DELTA: a refresh button on the feed header. A
                // mouse cannot pull the RefreshIndicator,
                // so this is its door: the same reload, newest on top (the
                // refresh tick). It steps out while the refresh runs and the
                // loader beside it takes the place. Explore has its own.
                HeaderSlot(
                  child: !_showsPostsList || _postsRefreshing
                      ? null
                      : Tooltip(
                          message: context.l10n.desktopReload,
                          child: InkResponse(
                            onTap: () => setState(() => _postsRefreshTick++),
                            radius: 18,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: tokens.starkWhite,
                              ),
                            ),
                          ),
                        ),
                ),
                HeaderSlot(
                  child: _dockedNewChip == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _dockedNewChip,
                        ),
                ),
                HeaderSlot(
                  child: _signinPref == null
                      ? null
                      : InkResponse(
                    onTap: _showSigninMenu,
                    radius: 18,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _signinEffective
                            ? Icons.vpn_key_rounded
                            : Icons.vpn_key_off_rounded,
                        size: 18,
                        // starkWhite to match the menu glyph: signed-in is a
                        // state, not a call to action.
                        color: _signinEffective
                            ? tokens.starkWhite
                            : tokens.textDim,
                      ),
                    ),
                  ),
                ),
                if (listStack != null) listStack,
                HeaderSlot(child: trailing),
            ],
          ),
        ),
      ),
    );
  }

  /// The sign-in consent dialog. One surface for both
  /// advertised modes: `optional` explains the trade and offers the choice;
  /// `required` states that reading this feed identifies you anyway. The
  /// action flips the stored pref and bumps the refresh tick so the very next
  /// fetch honors it — turning it ON should land a verified read immediately,
  /// not on some later visit.
  /// The key menu: Allow · Deny ·
  /// Forget, current state on top. Writes the decision and refetches under
  /// the new posture right away.
  Future<void> _showSigninMenu() async {
    final pref = _signinPref;
    final url = _singleRosterUrl;
    if (pref == null || url == null) return;
    final choice = await showChannelSigninMenu(
      context,
      pref: pref,
      effective: _signinEffective,
    );
    if (choice == null || !mounted) return;
    await PublicOSChannelSignin.setDecision(url, choice.decision);
    await _refreshSigninPref();
    if (!mounted) return;
    // Refetch under the new identity posture right away.
    setState(() => _postsRefreshTick++);
  }

  /// Center body for a single-flagged list header: favicon + feed name +
  /// optional `via [icon] displayName`. The via segment is tappable
  /// independently of the parent so it opens the discovery contact's
  /// profile without bubbling up.
  Widget _buildSingleHeaderBody({
    required ListFeed feed,
    required GlassTokens tokens,
  }) {
    final feedName = (feed.feedTitle != null && feed.feedTitle!.isNotEmpty)
        ? feed.feedTitle!
        : (Uri.tryParse(feed.feedUrl)?.host ?? feed.feedUrl);
    final foundAtAddr = feed.feedFoundAtAccountAddress;
    final foundAt = (foundAtAddr != null && foundAtAddr.isNotEmpty)
        ? _resolvedContacts[foundAtAddr]
        : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FeedFavicon(feedUrl: feed.feedUrl, size: 20),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            feedName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tokens.starkWhite,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (foundAt != null) ...[
          const SizedBox(width: 8),
          Text('·',
              style: TextStyle(color: tokens.textDim, fontSize: 12)),
          const SizedBox(width: 8),
          Flexible(child: _buildHeaderViaLine(foundAt, tokens)),
        ],
      ],
    );
  }

  Widget _buildChannelHeaderIcon(Channel channel) {
    const double size = 20;
    const double radius = 4;
    final fallback = Icon(Icons.rss_feed_rounded, size: size, color: ThemeProvider.tealPrimary);

    final faviconUrl = channel.serverAddress != null
        ? FaviconUtils.getFaviconUrl(channel.serverAddress!)
        : null;

    Widget faviconOrFallback = faviconUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: ZeroCachedImage(
              imageUrl: faviconUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => fallback,
            ),
          )
        : fallback;

    if (channel.iconUrl != null && channel.iconUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ZeroCachedImage(
          imageUrl: channel.iconUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => faviconOrFallback,
        ),
      );
    }

    return faviconOrFallback;
  }

  /// `via [14px GlassContactIcon] displayName` for the inline header. Tappable
  /// only on the via segment — outer InkWell still toggles the drawer.
  Widget _buildHeaderViaLine(Contact contact, GlassTokens tokens) {
    final hasProfile = contact.publicosAddress != null &&
        contact.publicosAddress!.eip55With0x !=
            '0x0000000000000000000000000000000000000000';
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.feedsViewVia,
            style: TextStyle(color: tokens.textDim, fontSize: 12)),
        const SizedBox(width: 5),
        GlassContactIcon(contact: contact, size: 14),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            contact.displayName ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tokens.starkWhite.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
    if (!hasProfile) return row;
    return InkWell(
      onTap: () => AppNav.toContact(context, contact),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: row,
      ),
    );
  }

  /// Empty state shown when no channel, list, or bookmarks view is selected.
  /// Per-source empty states (bookmarks empty, list empty, channel empty,
  /// locked-feeds banner) all live inside PostsList now.
  Widget _buildOnboardingState(ThemeData theme) {
    final tokens = GlassTokens.of(context);
    return RefreshIndicator(
      key: const ValueKey('onboarding'),
      onRefresh: () => _loadData(),
      color: tokens.starkWhite,
      backgroundColor: tokens.surfaceElevated,
      child: ListView(
        controller: _scrollController,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rss_feed_rounded,
                    size: 56,
                    color: tokens.textDim,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.feedsViewOnboardingTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: tokens.starkWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      context.l10n.feedsViewOnboardingSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.textDim,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
