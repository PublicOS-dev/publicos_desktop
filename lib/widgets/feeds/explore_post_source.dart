// ExplorePostSource — the network's most-read posts.
//
// What the whole network is reading, from the user's own SSP: every 10
// minutes the registered SSPs agree on the most read posts and channels over
// four windows, and the user's SSP copies the top ones from the servers that
// host them (the server's `GET /api/stats/trending/feed`, Core
// `PublicOSChannels.getTrendingPosts` / `getTrendingChannels`).
//
// One source shows one list: the POSTS go to the shared renderer, the
// CHANNELS (`feeds: true`) are rendered by the view itself. Reading either
// records nothing; a tap goes to the item's own server, where the read counts.
//
// Loads like a feed: the list kept on
// the device paints first, the network answers behind it with the header's
// hint up until the list itself has answered (one call), and the counts then
// change on screen as they arrive. No "N new" chip: this is a ranking, not a
// timeline.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/feeds/post_source.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/media_aspect_cache.dart';

/// How long a fetched Explore list is reused by a fresh view, so coming back
/// from a post's feed does not reload the list. A pull still fetches.
const exploreCacheFor = Duration(minutes: 5);

class ExplorePostSource extends PostSource {
  /// true = Hot feeds (the channels list), false = Hot posts. Each fetches
  /// only its own list: the posts cost one counts call per post, which the
  /// feeds row has no use for.
  final bool feeds;
  ExplorePostSource({this.feeds = false});

  /// Per window (`''` = the server's suggested one), for the app session: a
  /// view opening on a list fetched less than [exploreCacheFor] ago shows it
  /// with no fetch at all.
  static final Map<String, ({TrendingList<TrendingPost> list, DateTime at})>
      _postsCache = {};
  static final Map<String, ({TrendingList<TrendingChannel> list, DateTime at})>
      _channelsCache = {};

  /// null until the first answer: the server picks its suggested window, and
  /// the chips then show what it picked.
  String? _cut;
  String? get cut => _cut;

  TrendingList<TrendingPost>? _posts;
  TrendingList<TrendingChannel>? _channels;
  bool _isLoading = true;
  bool _refreshing = false;
  int _loadGeneration = 0;

  /// The feeds row's list: the view renders it itself (channel rows are not
  /// posts).
  TrendingList<TrendingChannel>? get channels => _channels;

  /// Rank by identity, for the line above each card.
  final Map<String, ({int rank, int readers})> _rankByKey = {};

  bool get _onScreen => _posts != null || _channels != null;

  @override
  PostSourceState get state => _isLoading
      ? const PostsLoading()
      : PostsReady(
          posts: [for (final t in _posts?.items ?? const <TrendingPost>[]) t.post],
          refreshing: _refreshing,
        );

  /// First load: the session's list if it is fresh, else the device's copy
  /// with the network behind it. With a list on screen it is a pull: fetch
  /// behind it, hint up.
  @override
  Future<void> load() {
    final pull = _onScreen;
    return _untilListed((listed) => _load(pull: pull, listed: listed));
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

  /// A window change: that window's kept list if there is one, the loader if
  /// not, the network behind either.
  void selectCut(String cut) {
    if (cut == _cut) return;
    _cut = cut;
    _load(pull: false);
  }

  Future<void> _load({required bool pull, void Function()? listed}) async {
    if (isDisposed) return;
    final gen = ++_loadGeneration;
    final asked = _cut;
    final sessionKey = asked ?? '';
    bool stale() => isDisposed || gen != _loadGeneration;

    if (pull) {
      _refreshing = true;
      changed();
    } else {
      final at =
          feeds ? _channelsCache[sessionKey]?.at : _postsCache[sessionKey]?.at;
      if (at != null && DateTime.now().difference(at) < exploreCacheFor) {
        _show(
          posts: _postsCache[sessionKey]?.list,
          channels: _channelsCache[sessionKey]?.list,
        );
        return;
      }
      if (!_onScreen) {
        _isLoading = true;
        changed();
      }
      final keptPosts = feeds
          ? null
          : await PublicOSChannels.getCachedTrendingPosts(cut: asked);
      final keptChannels = feeds
          ? await PublicOSChannels.getCachedTrendingChannels(cut: asked)
          : null;
      if (stale()) return;
      if (keptPosts != null || keptChannels != null) {
        _show(posts: keptPosts, channels: keptChannels, refreshing: true);
      } else {
        // Nothing kept for this window: the loader, over nothing (the list
        // of another window must not sit under this window's chip).
        _posts = null;
        _channels = null;
        _rankByKey.clear();
        _isLoading = true;
        _refreshing = false;
        changed();
      }
    }

    TrendingList<TrendingPost>? posts;
    TrendingList<TrendingChannel>? channels;
    if (feeds) {
      channels = await PublicOSChannels.getTrendingChannels(cut: asked);
    } else {
      posts = await PublicOSChannels.getTrendingPosts(
        cut: asked,
        // The list itself is the one quick call: it lands with the last
        // visit's counts and takes the loader down (the ranking reorders
        // here, once). The counts then change on screen as each batch
        // answers, with no loader.
        onDocument: (doc) {
          if (!stale()) _show(posts: doc);
          listed?.call();
        },
        onCounts: (list) {
          if (!stale()) _show(posts: list);
        },
      );
    }
    if (stale()) return;
    if (posts == null && channels == null) {
      // No answer: what is on screen stays (stale beats empty).
      _isLoading = false;
      _refreshing = false;
      changed();
      return;
    }
    final now = DateTime.now();
    final picked = posts?.cut ?? channels?.cut ?? '';
    for (final k in {sessionKey, picked}) {
      if (posts != null) _postsCache[k] = (list: posts, at: now);
      if (channels != null) _channelsCache[k] = (list: channels, at: now);
    }
    _show(posts: posts, channels: channels);
  }

  void _show({
    TrendingList<TrendingPost>? posts,
    TrendingList<TrendingChannel>? channels,
    bool refreshing = false,
  }) {
    _posts = feeds ? null : posts;
    _channels = feeds ? channels : null;
    final picked = posts?.cut ?? channels?.cut;
    if (_cut == null && picked != null && picked.isNotEmpty) _cut = picked;
    _rankByKey.clear();
    var i = 0;
    for (final t in _posts?.items ?? const <TrendingPost>[]) {
      i++;
      _rankByKey[postIdentityKey(t.post)] = (rank: i, readers: t.value);
    }
    _isLoading = false;
    _refreshing = refreshing;
    changed();
    final list = [for (final t in _posts?.items ?? const <TrendingPost>[]) t.post];
    MediaAspectCache.prefetchAll(MediaAspectCache.singleMediaUrls(list));
    resolveContacts(list);
  }

  @override
  Future<void> refreshShowingNewest() async {
    final pull = _onScreen;
    await _untilListed((listed) => _load(pull: pull, listed: listed));
    host?.scrollToTop();
  }

  @override
  PostHooks hooksFor(BuildContext context, Post post) {
    final r = _rankByKey[postIdentityKey(post)];
    final tokens = GlassTokens.of(context);
    return PostHooks(
      above: r == null
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(
                '#${r.rank} · ${context.l10n.exploreReaders(r.readers)}',
                style: TextStyle(
                  color: tokens.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
    );
  }

  @override
  Widget emptySlot(BuildContext context) => PostListEmptyContent(
        icon: Icons.explore_outlined,
        headline: context.l10n.exploreEmptyTitle,
        subline: context.l10n.exploreEmptySubtitle,
      );
}
