// LatestPostSource — Explore's Latest posts.
//
// The network's newest public posts, from the user's own SSP: every 10
// minutes each SSP merges every SSP's list, keeps each person's first 3 per
// rolling 24 h, orders them by 10-minute slot (newest first, the order inside
// a slot drawn from that round's beacon block) and copies the top 100 from
// their servers (the feed server's `GET /api/stats/latest/feed`, Core
// `PublicOSChannels.getLatestPosts`). No time windows: the list is what it
// is. Reading it records nothing; a tap goes to the post's own server.
//
// Loads like a feed: the list kept on the device paints first, the network answers
// behind it with the header's hint up until the list itself has answered
// (one call), the counts then change on screen as they arrive, and posts that
// were not there wait behind the "N new" chip. Before, nothing painted until
// up to 100 count calls had answered.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/feeds/explore_post_source.dart' show exploreCacheFor;
import 'package:publicos_desktop/widgets/feeds/post_source.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/media_aspect_cache.dart';

class LatestPostSource extends PostSource {
  /// The last list fetched, for the app session: a view opening empty reuses
  /// it for `exploreCacheFor` (5 min) with no fetch at all; a pull always
  /// fetches.
  static ({LatestList list, DateTime at})? _cache;

  /// What is on screen. null = nothing painted yet.
  List<Post>? _posts;

  /// A fresher list held behind the reader: the "N new" chip.
  List<Post>? _held;
  int _heldCount = 0;

  bool _isLoading = true;
  bool _refreshing = false;
  int _loadGeneration = 0;

  @override
  PostSourceState get state {
    if (_isLoading) return const PostsLoading();
    final held = _held;
    return PostsReady(
      posts: _posts ?? const [],
      refreshing: _refreshing,
      held: held == null ? null : HeldPosts(count: _heldCount, posts: held),
    );
  }

  static List<Post> _postsOf(LatestList? list) =>
      [for (final l in list?.items ?? const <LatestPost>[]) l.post];

  /// First load: the session's list if it is fresh, else the device's copy
  /// with the network behind it. A pull (posts already on screen) fetches and
  /// applies the answer directly: the reader asked for it.
  @override
  Future<void> load() {
    final direct = _posts != null;
    return _untilListed((listed) => _load(direct: direct, listed: listed));
  }

  /// Runs a load and completes when the LIST has answered (or the load ended
  /// without one), not when the counts have: the pull-to-refresh spinner and
  /// the scroll-to-top wait on this, and the counts keep arriving after it.
  Future<void> _untilListed(Future<void> Function(void Function() listed) run) {
    final first = Completer<void>();
    void listed() {
      if (!first.isCompleted) first.complete();
    }

    run(listed).catchError((_) {}).whenComplete(listed);
    return first.future;
  }

  Future<void> _load({required bool direct, void Function()? listed}) async {
    if (isDisposed) return;
    final gen = ++_loadGeneration;
    if (_posts == null) {
      final hit = _cache;
      if (hit != null && DateTime.now().difference(hit.at) < exploreCacheFor) {
        _paint(_postsOf(hit.list));
        return;
      }
      _isLoading = true;
      changed();
      final kept = await PublicOSChannels.getCachedLatestPosts();
      if (isDisposed || gen != _loadGeneration) return;
      if (kept != null && kept.items.isNotEmpty) {
        _paint(_postsOf(kept), refreshing: true);
      }
    } else {
      _refreshing = true;
      changed();
    }

    // The document lands first (posts, last visit's counts) and takes the
    // header's hint down: that is the one quick call. The counts then arrive
    // batch by batch (one call per post, signed where the reader signs) and
    // change on screen as they come, with no loader. All
    // of them go through the same landing.
    void land(LatestList list) {
      if (isDisposed || gen != _loadGeneration) return;
      _land(_postsOf(list), direct: direct);
    }

    final list = await PublicOSChannels.getLatestPosts(
        onDocument: (doc) {
          land(doc);
          listed?.call();
        },
        onCounts: land);
    if (isDisposed || gen != _loadGeneration) return;
    if (list == null) {
      // No answer: what is on screen stays (stale beats empty).
      _isLoading = false;
      _refreshing = false;
      changed();
      return;
    }
    _cache = (list: list, at: DateTime.now());
    land(list);
  }

  /// A network answer. Nothing on screen, a pull, or nothing new: it becomes
  /// the list. Otherwise the posts on screen take their fresh twins in place
  /// (same rows, same order, so the page does not move) and the answer waits
  /// behind the chip.
  void _land(List<Post> fresh, {required bool direct}) {
    final shown = _posts;
    final shownKeys = {for (final p in shown ?? const <Post>[]) postIdentityKey(p)};
    final newCount =
        fresh.where((p) => !shownKeys.contains(postIdentityKey(p))).length;
    if (shown == null || shown.isEmpty || direct || newCount == 0) {
      _held = null;
      _heldCount = 0;
      _paint(fresh);
      return;
    }
    final byKey = {for (final p in fresh) postIdentityKey(p): p};
    _posts = [for (final p in shown) byKey[postIdentityKey(p)] ?? p];
    _held = fresh;
    _heldCount = newCount;
    _isLoading = false;
    _refreshing = false;
    changed();
    // Held posts too: the chip shows their authors' faces.
    resolveContacts([..._posts!, ...fresh]);
  }

  void _paint(List<Post> posts, {bool refreshing = false}) {
    _posts = posts;
    _isLoading = false;
    _refreshing = refreshing;
    changed();
    MediaAspectCache.prefetchAll(MediaAspectCache.singleMediaUrls(posts));
    resolveContacts(posts);
  }

  @override
  void applyHeld() {
    final held = _held;
    if (held == null) return;
    _held = null;
    _heldCount = 0;
    _paint(held, refreshing: _refreshing);
    host?.scrollToTop();
  }

  @override
  Future<void> refreshShowingNewest() async {
    await _untilListed((listed) => _load(direct: true, listed: listed));
    host?.scrollToTop();
  }

  @override
  Widget emptySlot(BuildContext context) => PostListEmptyContent(
        icon: Icons.schedule_rounded,
        headline: context.l10n.exploreLatestEmptyTitle,
        subline: context.l10n.exploreLatestEmptySubtitle,
      );
}
