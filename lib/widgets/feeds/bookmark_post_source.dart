// BookmarkPostSource — posts from the local bookmark store.
//
// A bookmark is a post stored AS AN OBJECT — the full copy of something
// someone said, kept so it renders exactly as it was seen, independent of any
// feed. Not a FeedSource, not a fetch: this source reads blobs and converges
// them on current reality; the renderer it feeds is the same one every feed
// surface uses, so bookmarks scroll, snap and play like any other post list.
//
// Read-back: blobs are decoded with the lossless `Post.fromJson` — the exact
// inverse of the `Post.toJson` the bookmark write stores. NEVER
// `fromJsonFeedItem` here: that factory takes feed enrichment (feedUrl,
// channelSlug, commentsUrl/reactionsUrl, …) as constructor args a stored blob
// has no caller to supply, so it silently drops the fields that make
// comments, reactions, and the bookmark identity key work.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/feeds/post_source.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/media_aspect_cache.dart';

class BookmarkPostSource extends PostSource {
  /// Refresh cadence — hardcoded on purpose so the
  /// numbers are easy to find and change. A healthy bookmark re-syncs after
  /// [_staleAfter]; one the server said is GONE retries only every
  /// [_unavailableRetryAfter] (it probably stays gone — don't hammer).
  static const Duration _staleAfter = Duration(hours: 48);
  static const Duration _unavailableRetryAfter = Duration(days: 7);

  /// The sweep touches at most this many rows per load (newest first).
  static const int _refreshSweepCap = 50;

  List<Post> _posts = [];
  bool _isLoading = true;

  /// The drift rows behind [_posts], keyed by [postIdentityKey] — the sweep
  /// and the per-post refresh need the row (updatedAt/unavailable/etag), not
  /// just the decoded post.
  Map<String, BookmarkedPost> _rowsByKey = {};

  /// Guards against overlapping sweeps when a pull-to-refresh reloads the
  /// list mid-sweep.
  int _sweepGeneration = 0;

  @override
  PostSourceState get state =>
      _isLoading ? const PostsLoading() : PostsReady(posts: _posts);

  /// Pull-to-refresh = re-read the rows and re-run the sweep.
  @override
  Future<void> load() async {
    if (isDisposed) return;
    _isLoading = true;
    changed();
    // Scope = the SESSION address (the signing key), per the uniform per-user
    // table convention — NEVER the account address.
    final sessionAddr = PublicOS.sessionBlockchainAddress;
    if (sessionAddr == null) {
      _posts = [];
      _isLoading = false;
      changed();
      return;
    }
    final bookmarks = await PublicOS.database.getBookmarkedPosts(sessionAddr);
    if (isDisposed) return;
    final posts = <Post>[];
    final rowsByKey = <String, BookmarkedPost>{};
    for (final b in bookmarks) {
      try {
        final json = jsonDecode(b.postJson) as Map<String, dynamic>;
        final post = Post.fromJson(json);
        posts.add(post);
        rowsByKey[_rowKey(b)] = b;
      } catch (_) {}
    }
    _posts = posts;
    _rowsByKey = rowsByKey;
    _isLoading = false;
    changed();
    MediaAspectCache.prefetchAll(MediaAspectCache.singleMediaUrls(posts));
    resolveContacts(posts);
    _sweepStaleBookmarks();
  }

  /// Nothing to compose into a bookmark list; a refresh is a plain reload.
  @override
  Future<void> refreshShowingNewest() async {
    await load();
    host?.scrollToTop();
  }

  String _rowKey(BookmarkedPost b) {
    if (b.postUid.isNotEmpty) return '${b.postUid}|${b.feedUrl ?? ''}';
    return '${b.title}|${b.feedUrl ?? ''}';
  }

  /// Background freshness sweep — runs after every list load, newest rows
  /// first, at most [_refreshSweepCap] rows. Healthy rows older than
  /// [_staleAfter] and gone-flagged rows older than [_unavailableRetryAfter]
  /// re-sync via `PublicOSFeedLists.refreshBookmarkedPost` (ETag-conditional,
  /// so the steady state is a 304 per post). Each fresh result lands on the
  /// card as it arrives; verdict changes (a post going/coming back) land in
  /// the final quiet reload.
  Future<void> _sweepStaleBookmarks() async {
    final gen = ++_sweepGeneration;
    final now = DateTime.now().millisecondsSinceEpoch;
    final stale = _rowsByKey.values.where((b) {
      final age = now - b.updatedAt;
      return b.unavailable
          ? age > _unavailableRetryAfter.inMilliseconds
          : age > _staleAfter.inMilliseconds;
    }).take(_refreshSweepCap).toList();
    Log.i('BookmarkPostSource',
        'sweep: ${_rowsByKey.length} rows, ${stale.length} stale');
    if (stale.isEmpty) return;

    var verdictChanged = false;
    for (final row in stale) {
      final merged = await PublicOSFeedLists.refreshBookmarkedPost(row);
      if (isDisposed || gen != _sweepGeneration) return;
      if (merged != null) {
        _patchPost(_rowKey(row), merged);
        if (row.unavailable) verdictChanged = true; // came back
      } else {
        verdictChanged = true; // gone, or transport noise — reload will tell
      }
    }
    if (verdictChanged) await _reloadRowsQuiet(gen);
  }

  /// Replace one post in place, keyed like the rows.
  void _patchPost(String key, Post fresh) {
    _posts = [
      for (final p in _posts) postIdentityKey(p) == key ? fresh : p,
    ];
    changed();
  }

  /// Re-read rows + blobs without touching the loading state — used after
  /// refresh verdicts so the unavailable badges match the DB. Skipped if a
  /// newer load/sweep superseded this one.
  Future<void> _reloadRowsQuiet(int gen) async {
    final sessionAddr = PublicOS.sessionBlockchainAddress;
    if (sessionAddr == null) return;
    final bookmarks = await PublicOS.database.getBookmarkedPosts(sessionAddr);
    if (isDisposed || gen != _sweepGeneration) return;
    final posts = <Post>[];
    final rowsByKey = <String, BookmarkedPost>{};
    for (final b in bookmarks) {
      try {
        posts.add(Post.fromJson(jsonDecode(b.postJson) as Map<String, dynamic>));
        rowsByKey[_rowKey(b)] = b;
      } catch (_) {}
    }
    _posts = posts;
    _rowsByKey = rowsByKey;
    changed();
  }

  /// One-post refresh — the tap/focus hook and the menu's Refresh item.
  Future<void> _refreshOne(Post post, {bool showSnack = false}) async {
    final key = postIdentityKey(post);
    final row = _rowsByKey[key];
    if (row == null) {
      Log.w('BookmarkPostSource', 'refreshOne: no row for key "$key"');
      return;
    }
    final gen = _sweepGeneration;
    final merged = await PublicOSFeedLists.refreshBookmarkedPost(row);
    if (isDisposed || gen != _sweepGeneration) return;
    if (merged != null) {
      _patchPost(key, merged);
      if (row.unavailable) await _reloadRowsQuiet(gen); // badge clears
      if (showSnack) _snack((ctx) => ctx.l10n.postsListPostRefreshed);
    } else {
      await _reloadRowsQuiet(gen);
      if (showSnack) _snack((ctx) => ctx.l10n.postsListPostRefreshFailed);
    }
  }

  void _snack(String Function(BuildContext ctx) text) {
    final ctx = host?.context;
    if (ctx == null || !ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(text(ctx))));
  }

  /// The surface deleted the row and told the user; drop the post from the
  /// deck (optimistic — carried over from the old BookmarksSource branch of
  /// PostsList's toggle).
  @override
  void didUnbookmark(Post post) {
    final key = postIdentityKey(post);
    _posts = _posts.where((p) => postIdentityKey(p) != key).toList();
    _rowsByKey.remove(key);
    changed();
  }

  @override
  PostHooks hooksFor(BuildContext context, Post post) {
    final key = postIdentityKey(post);
    return PostHooks(
      isUnavailable: _rowsByKey[key]?.unavailable ?? false,
      onRefreshRequested: () => _refreshOne(post, showSnack: true),
      // Focus = live data: write back a fresh snapshot while the user reads
      // the detail page, so the card is current when they return.
      onDetailOpened: () => _refreshOne(post),
      onPostUpdated: load,
      onPostDeleted: load,
    );
  }

  @override
  Widget emptySlot(BuildContext context) => PostListEmptyContent(
        icon: Icons.bookmark_outline_rounded,
        headline: context.l10n.postsListEmptyBookmarksHeadline,
        subline: context.l10n.postsListEmptyBookmarksSubline,
      );
}
