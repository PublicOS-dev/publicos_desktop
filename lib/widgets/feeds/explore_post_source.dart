// ExplorePostSource — the network's most-read posts.
//
// What the whole network is reading, from the user's own SSP: every 10
// minutes the registered SSPs agree on the most read posts and channels over
// four windows, and the user's SSP copies the top ones from the servers that
// host them (the server's `GET /api/stats/trending/feed`, Core
// `PublicOSChannels.getTrendingPosts` / `getTrendingChannels`).
//
// Both lists load together on one cut, so the Explore view's two tabs switch
// instantly: this source yields the POSTS to the shared renderer and keeps
// the CHANNELS for the view's own feeds tab. Reading this list records
// nothing; a tap goes to the item's own server, where the read counts.

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
  /// Per window (`''` = the server's suggested one), for the app session.
  static final Map<String,
          ({
            TrendingList<TrendingPost>? posts,
            TrendingList<TrendingChannel>? channels,
            DateTime at,
          })> _cache = {};

  /// null until the first answer: the server picks its suggested window, and
  /// the chips then show what it picked.
  String? _cut;
  String? get cut => _cut;

  TrendingList<TrendingPost>? _posts;
  TrendingList<TrendingChannel>? _channels;
  bool _isLoading = true;
  bool _refreshing = false;
  int _loadGeneration = 0;

  /// The feeds tab's list — the view renders it itself (channel rows are not
  /// posts).
  TrendingList<TrendingChannel>? get channels => _channels;

  /// Rank by identity, for the line above each card.
  final Map<String, ({int rank, int readers})> _rankByKey = {};

  @override
  PostSourceState get state => _isLoading
      ? const PostsLoading()
      : PostsReady(
          posts: [for (final t in _posts?.items ?? const <TrendingPost>[]) t.post],
          refreshing: _refreshing,
        );

  /// First load and a cut change show the loader; a pull-to-refresh with
  /// lists already on screen reloads QUIETLY behind them (there is no cache
  /// to paint, so blanking the list would be the whole screen flashing).
  /// A view opening empty reuses a list fetched less than [exploreCacheFor]
  /// ago; a pull (lists on screen) always fetches.
  @override
  Future<void> load() {
    final onScreen = _posts != null || _channels != null;
    return _load(quiet: onScreen, allowCache: !onScreen);
  }

  /// A window change: both lists reload together, loud.
  void selectCut(String cut) {
    if (cut == _cut) return;
    _cut = cut;
    _load(quiet: false, allowCache: true);
  }

  Future<void> _load({required bool quiet, bool allowCache = false}) async {
    if (isDisposed) return;
    final gen = ++_loadGeneration;
    final asked = _cut ?? '';
    final hit = _cache[asked];
    if (allowCache &&
        hit != null &&
        DateTime.now().difference(hit.at) < exploreCacheFor) {
      _apply(hit.posts, hit.channels);
      return;
    }
    if (quiet) {
      _refreshing = true;
    } else {
      _isLoading = true;
    }
    changed();
    final results = await Future.wait([
      PublicOSChannels.getTrendingPosts(cut: _cut),
      PublicOSChannels.getTrendingChannels(cut: _cut),
    ]);
    if (isDisposed || gen != _loadGeneration) return;
    final posts = results[0] as TrendingList<TrendingPost>?;
    final channels = results[1] as TrendingList<TrendingChannel>?;
    final entry = (posts: posts, channels: channels, at: DateTime.now());
    _cache[asked] = entry;
    final cut = posts?.cut ?? channels?.cut;
    if (cut != null) _cache[cut] = entry;
    _apply(posts, channels);
  }

  void _apply(TrendingList<TrendingPost>? posts,
      TrendingList<TrendingChannel>? channels) {
    _posts = posts;
    _channels = channels;
    _cut ??= posts?.cut ?? channels?.cut;
    _rankByKey.clear();
    var i = 0;
    for (final t in posts?.items ?? const <TrendingPost>[]) {
      i++;
      _rankByKey[postIdentityKey(t.post)] = (rank: i, readers: t.value);
    }
    _isLoading = false;
    _refreshing = false;
    changed();
    final list = [for (final t in posts?.items ?? const <TrendingPost>[]) t.post];
    MediaAspectCache.prefetchAll(MediaAspectCache.singleMediaUrls(list));
    resolveContacts(list);
  }

  @override
  Future<void> refreshShowingNewest() async {
    await _load(quiet: false);
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
