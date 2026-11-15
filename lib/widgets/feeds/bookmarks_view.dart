// Bookmarks surface.
//
// A THIN wrapper: it owns one [BookmarkPostSource] (the DB
// read, the freshness sweep, the per-post refresh, the gone badge) and shows
// it through [PostSurface] → [PostListView], the same surface and renderer
// every feed list uses. That is how bookmarks get snapping, one-video-at-a-
// time playback and every future renderer behaviour for free instead of
// carrying their own ListView.

import 'package:flutter/material.dart';
import 'package:publicos_desktop/widgets/feeds/bookmark_post_source.dart';
import 'package:publicos_desktop/widgets/feeds/post_card.dart'
    show PostLayoutMode;
import 'package:publicos_desktop/widgets/feeds/post_surface.dart';

class BookmarksView extends StatefulWidget {
  final Color? color;

  /// Settings overrides — same contract as PostsList: when null the surface
  /// reads `PublicOSSettings` itself on init.
  final double? titleTextSize;
  final double? descriptionTextSize;
  final int? bodyMaxChars;
  final PostLayoutMode? layoutMode;

  final ScrollController? scrollController;

  /// Same unified-spinner contract as PostsList — feeds_view sets
  /// [showFullScreenLoader] false and drives one shared spinner from
  /// [onLoadingChanged].
  final bool showFullScreenLoader;
  final ValueChanged<bool>? onLoadingChanged;

  const BookmarksView({
    super.key,
    this.color,
    this.titleTextSize,
    this.descriptionTextSize,
    this.bodyMaxChars,
    this.layoutMode,
    this.scrollController,
    this.showFullScreenLoader = true,
    this.onLoadingChanged,
  });

  @override
  State<BookmarksView> createState() => _BookmarksViewState();
}

class _BookmarksViewState extends State<BookmarksView> {
  final BookmarkPostSource _source = BookmarkPostSource();

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
    );
  }
}
