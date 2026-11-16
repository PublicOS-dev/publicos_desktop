// LatestPostSource — Explore's Latest posts.
//
// The network's newest public posts, from the user's own SSP: every 10
// minutes each SSP merges every SSP's list, keeps each person's first 3 per
// rolling 24 h, orders them by 10-minute slot (newest first, the order inside
// a slot drawn from that round's beacon block) and copies the top 100 from
// their servers (the feed server's `GET /api/stats/latest/feed`, Core
// `PublicOSChannels.getLatestPosts`). No time windows: the list is what it
// is. Reading it records nothing; a tap goes to the post's own server.

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/feeds/explore_post_source.dart' show exploreCacheFor;
import 'package:publicos_desktop/widgets/feeds/post_source.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/media_aspect_cache.dart';

class LatestPostSource extends PostSource {
  /// The last list fetched, for the app session: a view opening empty reuses
  /// it for `exploreCacheFor` (5 min); a pull always fetches.
  static ({LatestList? list, DateTime at})? _cache;

  LatestList? _list;
  bool _isLoading = true;
  bool _refreshing = false;
  int _loadGeneration = 0;

  @override
  PostSourceState get state => _isLoading
      ? const PostsLoading()
      : PostsReady(
          posts: [for (final l in _list?.items ?? const <LatestPost>[]) l.post],
          refreshing: _refreshing,
        );

  /// The first load shows the loader; a pull with a list on screen reloads
  /// quietly behind it (no cache to paint, so blanking would flash).
  @override
  Future<void> load() async {
    if (isDisposed) return;
    final gen = ++_loadGeneration;
    final hit = _cache;
    if (_list == null &&
        hit != null &&
        DateTime.now().difference(hit.at) < exploreCacheFor) {
      _show(hit.list);
      return;
    }
    if (_list != null) {
      _refreshing = true;
    } else {
      _isLoading = true;
    }
    changed();
    final list = await PublicOSChannels.getLatestPosts();
    if (isDisposed || gen != _loadGeneration) return;
    _cache = (list: list, at: DateTime.now());
    _show(list);
  }

  void _show(LatestList? list) {
    _list = list;
    _isLoading = false;
    _refreshing = false;
    changed();
    final posts = [for (final l in list?.items ?? const <LatestPost>[]) l.post];
    MediaAspectCache.prefetchAll(MediaAspectCache.singleMediaUrls(posts));
    resolveContacts(posts);
  }

  @override
  Future<void> refreshShowingNewest() async {
    await load();
    host?.scrollToTop();
  }

  @override
  Widget emptySlot(BuildContext context) => PostListEmptyContent(
        icon: Icons.schedule_rounded,
        headline: context.l10n.exploreLatestEmptyTitle,
        subline: context.l10n.exploreLatestEmptySubtitle,
      );
}
