// PostSurface — the common ancestor of a post source and the renderer.
//
// It owns the SWITCH: listening to one [PostSource], it shows the loader, the
// source's locked screen, "Channel not found", the error screen, or the
// renderer ([PostListView]) with the posts and chrome the source produced.
// The whole-view screens are horizontal to the renderer, never inside it, so
// the renderer only ever receives posts and scrolls.
//
// It also owns what is about THIS SURFACE rather than the posts or their
// origin: the reading settings (text sizes, layout), the scroll controller it
// hands the renderer (and scrolls to top on a source's request), the bookmark
// keys + toggle (a generic card verb on every surface), and the host-facing
// load / refresh reports.

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/feeds/feeds_settings_sheet.dart'
    show parsePostLayoutMode;
import 'package:publicos_desktop/widgets/feeds/post_card.dart';
import 'package:publicos_desktop/widgets/feeds/post_list_view.dart';
import 'package:publicos_desktop/widgets/feeds/post_source.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_label.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

class PostSurface extends StatefulWidget {
  /// Created and disposed by whoever shows this surface (PostsList,
  /// BookmarksView). The surface attaches to it on mount.
  final PostSource source;

  final Color? color;

  /// Settings overrides — when null the surface reads `PublicOSSettings`
  /// itself on init. `feeds_view` passes its live values so the settings
  /// sheet can edit them; browser leaves them null.
  final double? titleTextSize;
  final double? descriptionTextSize;
  final int? bodyMaxChars;
  final PostLayoutMode? layoutMode;

  /// Optional external scroll controller. `feeds_view` shares its existing
  /// controller so the header compress-animation listener keeps firing on
  /// the same scroll position the post list scrolls.
  final ScrollController? scrollController;

  /// When false the surface renders nothing (a `SizedBox`) while its posts are
  /// loading, instead of a spinner. `feeds_view` sets this so it can show a
  /// single unified spinner across its own metadata load AND this post load —
  /// a second spinner here is what produced the doubled animation. Default
  /// true keeps the standalone behavior for other hosts (browser tab).
  final bool showFullScreenLoader;

  /// Fired (post-frame) whenever the load state flips. Lets the host drive a
  /// single shared spinner from the combined loading state.
  final ValueChanged<bool>? onLoadingChanged;

  /// Fired while a revalidation is in flight *after* posts are already on
  /// screen. Distinct from [onLoadingChanged]: "loading" means "you have
  /// nothing to look at yet" and warrants a blocking spinner; "refreshing"
  /// means "there may be more soon" and warrants a peripheral hint.
  final ValueChanged<bool>? onRefreshingChanged;

  /// The "N new" chip handed to a header (see [PostListView.onHeldDocked]).
  final ValueChanged<Widget?>? onHeldDocked;

  /// Extra top inset applied INSIDE the scroll view (and to the non-scroll
  /// states: loader / locked / error). The browser's channel tab passes its
  /// expanded address-bar overhang so the list starts below the expanded
  /// header and its scroll drives the header collapse 1:1 — the same
  /// contract as `ProfilePage.topInset`. Column-layout hosts leave it 0.
  final double topInset;

  const PostSurface({
    super.key,
    required this.source,
    this.color,
    this.titleTextSize,
    this.descriptionTextSize,
    this.bodyMaxChars,
    this.layoutMode,
    this.scrollController,
    this.showFullScreenLoader = true,
    this.onLoadingChanged,
    this.onRefreshingChanged,
    this.onHeldDocked,
    this.topInset = 0,
  });

  @override
  State<PostSurface> createState() => _PostSurfaceState();
}

class _PostSurfaceState extends State<PostSurface> implements PostListHost {
  double _titleTextSize = 16.0;
  double _descriptionTextSize = 14.0;
  int? _trimChars;
  PostLayoutMode _layoutMode = PostLayoutMode.compact;

  ScrollController? _ownedScrollController;
  ScrollController get _scrollController =>
      widget.scrollController ?? _ownedScrollController!;

  Set<String> _bookmarkedPostKeys = {};

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _ownedScrollController = ScrollController();
    }
    _loadSettings();
    _loadBookmarkedKeys();
    widget.source.addListener(_onSourceChanged);
    widget.source.attach(this);
    _report();
  }

  @override
  void didUpdateWidget(PostSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      oldWidget.source.removeListener(_onSourceChanged);
      oldWidget.source.detach();
      widget.source.addListener(_onSourceChanged);
      widget.source.attach(this);
      _report();
    }
  }

  @override
  void dispose() {
    widget.source.removeListener(_onSourceChanged);
    widget.source.detach();
    _ownedScrollController?.dispose();
    // Leaving mid-refresh: take the hint out of the host's header, as
    // PostListView does for its docked chip. Otherwise it spins forever:
    // `_report` drops its post-frame call once we are unmounted, and desktop
    // unmounts this list whenever a post opens in place. Refreshing only:
    // the blocking loader is raised eagerly by the hosts on a switch, so a
    // late `false` from here would race the new list's `true`. Post-frame,
    // because an ancestor's setState is not allowed while the tree is
    // finalized; the hosts check `mounted`.
    if (_lastReportedRefreshing) {
      final cb = widget.onRefreshingChanged;
      WidgetsBinding.instance.addPostFrameCallback((_) => cb?.call(false));
    }
    super.dispose();
  }

  void _onSourceChanged() {
    if (!mounted) return;
    setState(() {});
    _report();
  }

  // ── PostListHost ─────────────────────────────────────────────────────────

  @override
  void scrollToTop() {
    if (!mounted || !_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  double get leftInset => _effectiveLayout == PostLayoutMode.wide
      ? PostCard.wideContentInset
      : PostCard.compactContentInset;

  @override
  Color? get accent => widget.color;

  // ── Host reports — derived from the source's state transitions ──────────
  //
  // Deferred to a post-frame callback: the first flip can land during the
  // host's build (the source loads on attach, inside initState), where a
  // synchronous parent `setState` would throw. Deduped on the last reported
  // value so no redundant callback is scheduled. The "loading ended" report
  // on a cache paint is LOAD-BEARING: without it the host's blocking spinner
  // stays up over content the reader can already read, for the whole
  // network refresh.

  bool _lastReportedLoading = false;
  bool _lastReportedRefreshing = false;

  void _report() {
    final state = widget.source.state;
    final loading = state is PostsLoading;
    final refreshing = state is PostsReady && state.refreshing;
    if (loading != _lastReportedLoading && widget.onLoadingChanged != null) {
      _lastReportedLoading = loading;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onLoadingChanged!(loading);
      });
    }
    if (refreshing != _lastReportedRefreshing &&
        widget.onRefreshingChanged != null) {
      _lastReportedRefreshing = refreshing;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onRefreshingChanged!(refreshing);
      });
    }
  }

  // ── Reading settings ─────────────────────────────────────────────────────

  Future<void> _loadSettings() async {
    // Fast-path: when every setting is passed explicitly by the caller (the
    // feeds_view does this) the surface never needs to read storage itself.
    if (widget.titleTextSize != null &&
        widget.descriptionTextSize != null &&
        widget.layoutMode != null) {
      return;
    }
    try {
      final t = await PublicOSSettings.getSetting('rss_feeds_title_text_size');
      final d =
          await PublicOSSettings.getSetting('rss_feeds_description_text_size');
      final c = await PublicOSSettings.getSetting('rss_feeds_trim_chars');
      final l = await PublicOSSettings.getSetting('rss_feeds_layout_mode');
      if (!mounted) return;
      setState(() {
        if (t != null) {
          _titleTextSize = double.tryParse(t.value) ?? _titleTextSize;
        }
        if (d != null) {
          _descriptionTextSize =
              double.tryParse(d.value) ?? _descriptionTextSize;
        }
        if (c != null) {
          final parsed = int.tryParse(c.value);
          _trimChars = (parsed != null && parsed > 0) ? parsed : null;
        }
        if (l != null) {
          _layoutMode = parsePostLayoutMode(l.value);
        }
      });
    } catch (_) {}
  }

  double get _effectiveTitleSize => widget.titleTextSize ?? _titleTextSize;
  double get _effectiveDescSize =>
      widget.descriptionTextSize ?? _descriptionTextSize;
  int? get _effectiveTrim => widget.bodyMaxChars ?? _trimChars;
  PostLayoutMode get _effectiveLayout => widget.layoutMode ?? _layoutMode;

  // ── Bookmarks — a generic card verb on every surface ─────────────────────

  Future<void> _loadBookmarkedKeys() async {
    // Scope = the SESSION address (the signing key), per the uniform per-user
    // table convention — NEVER the account address.
    final sessionAddr = PublicOS.sessionBlockchainAddress;
    if (sessionAddr == null) return;
    try {
      final bookmarks = await PublicOS.database.getBookmarkedPosts(sessionAddr);
      if (!mounted) return;
      setState(() {
        _bookmarkedPostKeys = bookmarks.map((b) {
          if (b.postUid.isNotEmpty) return '${b.postUid}|${b.feedUrl ?? ''}';
          return '${b.title}|${b.feedUrl ?? ''}';
        }).toSet();
      });
    } catch (_) {}
  }

  bool _isBookmarked(Post post) =>
      _bookmarkedPostKeys.contains(postIdentityKey(post));

  Future<void> _toggleBookmark(Post post) async {
    final sessionAddr = PublicOS.sessionBlockchainAddress;
    if (sessionAddr == null) return;
    final key = postIdentityKey(post);
    final isCurrentlyBookmarked = _bookmarkedPostKeys.contains(key);

    HapticFeedback.mediumImpact();

    if (isCurrentlyBookmarked) {
      try {
        await PublicOS.database
            .deleteBookmarkedPost(post.uid, post.feedUrl, sessionAddr);
        if (!mounted) return;
        setState(() => _bookmarkedPostKeys.remove(key));
        widget.source.didUnbookmark(post);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.postsListBookmarkRemoved)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(context.l10n, e))),
        );
      }
    } else {
      try {
        // The blob is the record (read back via the lossless Post.fromJson);
        // the typed columns are only the identity key + sort + refresh state.
        final postJson = jsonEncode(post.toJson());
        final now = DateTime.now().millisecondsSinceEpoch;
        await PublicOS.database.upsertBookmarkedPost(
          BookmarkedPostsCompanion(
            postUid: Value(post.uid),
            title: Value(post.title),
            feedUrl: Value(post.feedUrl),
            postJson: Value(postJson),
            sessionAddress: Value(sessionAddr),
            bookmarkedAt: Value(now),
            // The post on screen came off a live fetch moments ago — it IS a
            // fresh sync, so the refresh sweep starts its clock here.
            updatedAt: Value(now),
          ),
        );
        if (!mounted) return;
        setState(() => _bookmarkedPostKeys.add(key));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.postsListPostBookmarked)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(context.l10n, e))),
        );
      }
    }
  }

  // -----------------------------------------------------------------------
  // BUILD — the switch
  // -----------------------------------------------------------------------

  /// Non-scroll states can't carry the inset inside a scroll view, so they
  /// take it as plain padding — keeps them clear of the browser's expanded
  /// address bar (which overlays the content in that layout).
  Widget _inset(Widget child) => widget.topInset > 0
      ? Padding(padding: EdgeInsets.only(top: widget.topInset), child: child)
      : child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GlassTokens.of(context);
    final source = widget.source;
    final state = source.state;

    switch (state) {
      case PostsLoading():
        // When the host owns the spinner (feeds_view's unified overlay) render
        // nothing here — a second spinner would double the animation.
        return widget.showFullScreenLoader
            ? const PixelRainLoadingCorner()
            : const SizedBox.shrink();
      case PostsGated(:final screen):
        if (screen != null) return _inset(screen(context));
        return _inset(_buildErrorState(theme,
            message: context.l10n.postsListFeedPrivate));
      case PostsGone(:final onUnfollow):
        return _inset(_buildGoneState(theme, tokens, onUnfollow));
      case PostsFailed(:final message):
        return _inset(_buildErrorState(theme, message: message));
      case PostsReady():
        final header = source.headerSlot(context);
        final banner = source.bannerSlot(context);
        return PostListView(
          posts: state.posts,
          contacts: source.contacts,
          awaitingContacts: source.awaitingContacts,
          leading: [
            if (banner != null) banner,
            if (header != null) header,
          ],
          pinned: source.pinnedSlot(context),
          floatingAction: source.floatingAction(context),
          held: state.held,
          onApplyHeld: source.applyHeld,
          onHeldDocked: widget.onHeldDocked,
          loadingMore: state.loadingMore,
          canLoadMore: source.canLoadMore,
          onLoadMore: source.loadMore,
          onRefresh: source.load,
          hooksFor: source.hooksFor,
          isBookmarked: _isBookmarked,
          onBookmarkToggled: _toggleBookmark,
          empty: source.emptySlot(context),
          titleTextSize: _effectiveTitleSize,
          descriptionTextSize: _effectiveDescSize,
          bodyMaxChars: _effectiveTrim,
          layoutMode: _effectiveLayout,
          scrollController: _scrollController,
          topInset: widget.topInset,
          color: widget.color,
        );
    }
  }

  Widget _buildErrorState(ThemeData theme, {required String message}) {
    return RefreshIndicator(
      onRefresh: widget.source.load,
      color: widget.color ?? theme.colorScheme.primary,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.postsListLoadFailedTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: widget.source.load,
                    child: Text(context.l10n.actionRetry),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Channel not found": same shape as the empty
  /// state, plus Unfollow when the host can remove the follow.
  Widget _buildGoneState(
      ThemeData theme, GlassTokens tokens, VoidCallback? onUnfollow) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link_off_rounded, size: 56, color: tokens.textDim),
                const SizedBox(height: 14),
                Text(
                  context.l10n.postsListChannelNotFoundHeadline,
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
                    context.l10n.postsListChannelNotFoundSubline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.textDim,
                      height: 1.4,
                    ),
                  ),
                ),
                if (onUnfollow != null) ...[
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: onUnfollow,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tokens.starkWhite,
                      side: BorderSide(color: tokens.borderSubtle),
                    ),
                    child: Text(context.l10n.postsListChannelNotFoundUnfollow),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
