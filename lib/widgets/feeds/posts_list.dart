// PostsList — a feed-backed post list (feeds_view body, browser channel tab,
// the feed reader page).
//
// This is a THIN wrapper: it owns one [FeedPostSource] (the fetch engine —
// roster, cache, pages, gates, header data, verbs) and shows it through
// [PostSurface], which switches between the whole-view screens and the
// renderer, [PostListView]. The roster arrives as a new `feeds` value on any
// mutation and `refreshTick` re-fetches after the host's own compose.
//
// Bookmarks are not a feed — see BookmarksView, which shows a
// BookmarkPostSource through the same surface and renderer.

import 'package:flutter/material.dart';
import 'package:publicos_desktop/widgets/feeds/feed_post_source.dart';
import 'package:publicos_desktop/widgets/feeds/feed_source.dart';
import 'package:publicos_desktop/widgets/feeds/post_card.dart'
    show PostLayoutMode;
import 'package:publicos_desktop/widgets/feeds/post_surface.dart';

export 'package:publicos_desktop/widgets/feeds/feed_post_source.dart'
    show kGateRefusalCodes;

class PostsList extends StatefulWidget {
  /// The roster — derived by the HOST, never in here. One [FeedSource] per
  /// feed; each post renders with its own feed's context.
  final List<FeedSource> feeds;

  /// Set when this surface renders a list: enables the per-card verbs
  /// (mute / remove), the locked-feeds banner, and the "feed · via" context
  /// line. The mute write needs the id itself.
  final int? listId;

  /// Surface title — the compose target name when the url alone can't say.
  final String? displayName;

  /// Allow the compose FAB. The FAB itself lights only when the surface is a
  /// single feed whose response says `posting_policy == open` (that means
  /// it lights from the browser door too).
  final bool showNewPostButton;

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

  /// When false the list renders nothing (a `SizedBox`) while its posts are
  /// loading, instead of a spinner. `feeds_view` sets this so it can show a
  /// single unified spinner across its own metadata load AND this post load.
  /// Default true keeps the standalone behavior for other hosts (browser tab).
  final bool showFullScreenLoader;

  /// Fired (post-frame) whenever the post-load state flips. Lets the host
  /// drive a single shared spinner from the combined loading state.
  final ValueChanged<bool>? onLoadingChanged;

  /// Fired while phase 2 (the network revalidation) is in flight, *after* the
  /// cached posts are already on screen.
  final ValueChanged<bool>? onRefreshingChanged;

  /// The "N new" chip handed to a header (see [PostListView.onHeldDocked]).
  final ValueChanged<Widget?>? onHeldDocked;

  /// The "Unfollow" button on the Channel-not-found screen. Null → the
  /// screen shows no button (a
  /// standalone channel pick or browser tab has nothing to unfollow here).
  final VoidCallback? onUnfollowGone;

  /// Extra top inset applied INSIDE the scroll view (and to the non-scroll
  /// states). The browser's channel tab passes its expanded address-bar
  /// overhang — the same contract as `ProfilePage.topInset`. Column-layout
  /// hosts leave it 0.
  final double topInset;

  /// Bumped by the host after ITS OWN compose flow saves a post (feeds_view's
  /// channel-picker compose lives outside this widget). A change triggers a
  /// reload that applies the refresh DIRECTLY — no "New posts" chip — and
  /// scrolls to top, so the author sees their post land. The chip exists to
  /// protect a reading position; right after composing there is none. The
  /// internal FAB compose does the same via the source.
  final int refreshTick;

  /// A list's header: who the list follows, opening "Manage
  /// [list]". Built by the host, it takes the channel description's slot, so
  /// a list never shows one feed's description. DESKTOP DELTA: no inset
  /// argument (the desktop channel header uses its fixed 16).
  final Widget Function()? listHeader;

  const PostsList({
    super.key,
    required this.feeds,
    this.listId,
    this.displayName,
    this.showNewPostButton = true,
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
    this.onUnfollowGone,
    this.topInset = 0,
    this.refreshTick = 0,
    this.listHeader,
  });

  @override
  State<PostsList> createState() => _PostsListState();
}

class _PostsListState extends State<PostsList> {
  late final FeedPostSource _source = FeedPostSource(
    feeds: widget.feeds,
    listId: widget.listId,
    displayName: widget.displayName,
    showNewPostButton: widget.showNewPostButton,
    listHeader: widget.listHeader,
    onUnfollowGone: widget.onUnfollowGone,
  );

  @override
  void didUpdateWidget(PostsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _source
      ..displayName = widget.displayName
      ..showNewPostButton = widget.showNewPostButton
      ..listHeader = widget.listHeader
      ..onUnfollowGone = widget.onUnfollowGone;
    // A changed roster patches the deck or reloads; an unchanged one is a
    // no-op inside setRoster.
    _source.setRoster(widget.feeds, listId: widget.listId);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _source.refreshShowingNewest();
    }
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PostSurface(
      source: _source,
      color: widget.color,
      titleTextSize: widget.titleTextSize,
      descriptionTextSize: widget.descriptionTextSize,
      bodyMaxChars: widget.bodyMaxChars,
      layoutMode: widget.layoutMode,
      scrollController: widget.scrollController,
      showFullScreenLoader: widget.showFullScreenLoader,
      onLoadingChanged: widget.onLoadingChanged,
      onRefreshingChanged: widget.onRefreshingChanged,
      onHeldDocked: widget.onHeldDocked,
      topInset: widget.topInset,
    );
  }
}
