// FeedPostSource — posts from a roster of feeds.
//
// Everything about FETCHING lives here. The source takes a roster of
// [FeedSource]s and FETCHES — it knows nothing about lists, follows, or
// resolution (the HOST derives the roster and hands a new one on any roster
// mutation). Every url is fetched through the one Core path, cache-first;
// single-feed affordances (header, sort chips, private gate,
// pagination, compose) fire on `feeds.length == 1` and are driven by the
// RESPONSE (description / stats / postingPolicy / hasMore), never by who
// constructed the source. List verbs (mute / remove / locked banner /
// per-card "feed · via") fire on `listId != null`. Bookmarks are not a feed —
// see BookmarkPostSource.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/feeds/channel_header_card.dart';
import 'package:publicos_desktop/widgets/feeds/channel_signin_dialogs.dart';
import 'package:publicos_desktop/widgets/feeds/feed_source.dart';
import 'package:publicos_desktop/widgets/feeds/forum_sort_bar.dart';
import 'package:publicos_desktop/widgets/feeds/paywall_locked_widget.dart';
import 'package:publicos_desktop/widgets/feeds/post_source.dart';
import 'package:publicos_desktop/widgets/feeds/private_feed_locked_widget.dart';
import 'package:publicos_desktop/widgets/feeds/signin_locked_widget.dart';
import 'package:publicos_desktop/widgets/feeds/tier_locked_widget.dart';
import 'package:publicos_desktop/widgets/flag_sheet.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/screens/compose_post_page.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/widgets/media_aspect_cache.dart';
import 'package:publicos_desktop/utils/feed_metadata_utils.dart';

/// Every refusal the read ladder can answer a feed fetch with.
///
/// These are GATES, not failures: each one means "you cannot see this", and the
/// UI owes the reader the locked-channel state rather than an error screen.
///
/// It has to be an explicit list because `RssParser` substitutes the response
/// body's `error.code` for the HTTP status, so a 403 refusal never presents as
/// HTTP_403 — matching on status alone silently misses every one of them, and
/// VERIFIED_ONLY or PAYWALL_DENIED would render as raw errors.
///
/// The server's list: `internal/handlers/authorize.go`. Add a rung there, add
/// its code here.
const List<String> kGateRefusalCodes = <String>[
  'PRIVATE_FEED',              // banned, or not on an enabled list (masked)
  'PRIVATE_FEED_NOT_APPROVED', // not on an enabled list
  'VERIFIED_ONLY',             // citizens only
  'ACCOUNT_ONLY',              // PublicOS accounts only
  'STANDING_REQUIRED',         // citizen, or a paid-up domain
  'PAYWALL_DENIED',            // subscription required
  'SIGNIN_REQUIRED',           // the 401 challenge with a key loaded (Core
                               // FeedSigninRequired) — ask or lock, never an error
];

class FeedPostSource extends PostSource {
  /// The roster — derived by the HOST, never in here. One [FeedSource] per
  /// feed; each post renders with its own feed's context.
  List<FeedSource> feeds;

  /// Set when this surface renders a list: enables the per-card verbs
  /// (mute / remove), the locked-feeds banner, and the "feed · via" context
  /// line. The mute write needs the id itself.
  int? listId;

  /// Surface title — the compose target name when the url alone can't say.
  String? displayName;

  /// Allow the compose FAB. The FAB itself lights only when the surface is a
  /// single feed whose response says `posting_policy == open` (so it lights
  /// from the browser door too).
  bool showNewPostButton;

  /// A list's header: who the list follows, opening "Manage
  /// [list]". Built by the host, it takes the channel description's slot, so
  /// a list never shows one feed's description. DESKTOP DELTA: no inset
  /// argument (the desktop channel header uses its fixed 16).
  Widget Function()? listHeader;

  /// The "Unfollow" button on the Channel-not-found screen.
  /// Null → the screen shows no button (a
  /// standalone channel pick or browser tab has nothing to unfollow here).
  VoidCallback? onUnfollowGone;

  FeedPostSource({
    required this.feeds,
    this.listId,
    this.displayName,
    this.showNewPostButton = true,
    this.listHeader,
    this.onUnfollowGone,
  });

  List<Post> _posts = [];
  bool _isLoading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;
  bool _isPrivateFeed = false;

  /// The single feed no longer exists — its owner deleted it (the source
  /// says so) or the server answered 404. Renders "Channel not found", never
  /// a stale cached copy.
  bool _gone = false;

  /// Which gate refused (one of [kGateRefusalCodes]), so the locked body can
  /// be the RIGHT one: pay, request, or "you need X". `_isPrivateFeed` stays
  /// the host-facing bool; this is what picks the screen.
  String? _gateCode;

  /// The typed paywall refusal, kept intact — entries + lapsed_at are the
  /// pay sheet's whole input. Stringifying it would throw them away.
  PaywallException? _paywall;

  /// The channel object the server attached to a refusal (`error.channel`,
  /// Core `FeedGateException.channel`) or embedded on a served single feed
  /// (`ParsedFeed.channel`). Null = UNKNOWN (older server, a cached body) —
  /// the locks then resolve on their own.
  Channel? _gateChannel;

  /// The sign-in row for the single feed, re-read after every load — what
  /// the ask and the SIGNIN_REQUIRED body branch on.
  ChannelSigninPref? _signinPref;

  /// Channels asked during THIS source's life. A dismissed dialog leaves
  /// `decision` null and is asked again on the next open, not on the next
  /// refresh.
  final Set<String> _askedThisMount = {};

  Set<String> _lockedFeedUrls = {};

  /// Phase 2 in flight (cached posts already showing).
  bool _isRefreshing = false;

  /// Posts fetched by phase 2 that are NOT yet on screen, because applying them
  /// would move the page under a reader who is already reading. Surfaced as the
  /// "New posts" chip; applied only when the user asks for them.
  RefreshedFeedList? _pending;

  /// Feeds muted/removed THIS session, before the host re-derives the roster.
  /// The roster input is immutable; this overlay keeps refresh from re-adding
  /// a feed the user just dismissed.
  final Set<String> _removedUrls = {};

  // ── The uniform fetch-result state (one shape, every door) ──────────────
  String? _description;
  // The feed's declared website + language: the header card's details line.
  String? _siteUrl;
  String? _language;
  ChannelStats? _stats;
  String? _postingPolicy;
  // `_publicos.is_private` from the fetch result — the composer routes media
  // uploads by it (private channel ⇒ pedia door). Response-derived, never
  // from the URL shape.
  bool? _channelIsPrivate;

  ChannelSort _currentSort = ChannelSort.newest;
  int _loadGeneration = 0;

  static const Duration _loadingTimeout = Duration(seconds: 45);
  static const int _pageSize = 50;

  // ── Roster views ─────────────────────────────────────────────────────────

  /// Roster minus session-dismissed feeds, deduped by url. On a duplicate the
  /// followed-account FeedSource wins over the hand-added row (its via + Mute
  /// verb apply).
  List<FeedSource> get _effectiveFeeds {
    final out = <FeedSource>[];
    final index = <String, int>{};
    for (final f in feeds) {
      if (_removedUrls.contains(f.url)) continue;
      final at = index[f.url];
      if (at == null) {
        index[f.url] = out.length;
        out.add(f);
      } else if (out[at].origin is! AccountFeedOrigin &&
          f.origin is AccountFeedOrigin) {
        out[at] = f;
      }
    }
    return out;
  }

  Map<String, FeedSource> get _sourceByUrl =>
      {for (final f in _effectiveFeeds) f.url: f};

  FeedSource? get _singleFeed {
    final feeds = _effectiveFeeds;
    return feeds.length == 1 ? feeds.first : null;
  }

  bool get _isSingleSurface => _singleFeed != null;

  /// Forum-ness comes from the fetch result (`_publicos.posting_policy`),
  /// never from the URL shape or the first post.
  bool get _isForum => _postingPolicy == 'open';

  bool get _showSortBar => _isForum && _isSingleSurface;

  bool get _isListSurface => listId != null;

  bool get _isMultiFeed => _effectiveFeeds.length > 1;

  // ── State ────────────────────────────────────────────────────────────────

  @override
  PostSourceState get state {
    if (_isLoading) return const PostsLoading();
    if (_isPrivateFeed) return PostsGated(_gateScreenBuilder());
    if (_gone) return PostsGone(onUnfollow: onUnfollowGone);
    if (_error != null) return PostsFailed(_error!);
    final pending = _pending;
    return PostsReady(
      posts: _stampedPosts,
      refreshing: _isRefreshing,
      loadingMore: _loadingMore,
      held: pending == null
          ? null
          : HeldPosts(count: pending.newCount, posts: pending.posts),
    );
  }

  /// The tab the feed was found on rides each post, so "Go to feed" (and a
  /// bookmark or pin made from here) can land back on it.
  List<Post> get _stampedPosts {
    final byUrl = _sourceByUrl;
    return [
      for (final raw in _posts)
        if (byUrl[raw.feedUrl]?.recordKey != null && raw.feedRecordKey == null)
          raw.copyWith(feedRecordKey: byUrl[raw.feedUrl]!.recordKey)
        else
          raw,
    ];
  }

  // ── Roster changes — the host re-derived ─────────────────────────────────

  /// The host passes a new roster (and list) whenever it re-derives. A changed
  /// roster either PATCHES the deck or reloads it.
  ///
  /// The user edits the list they are reading (Manage [list]: unfollow, mute,
  /// remove a feed, add one) and comes back to it. The deck they were reading
  /// stays where it is: posts of feeds that left are taken out, the feeds that
  /// arrived are fetched on their own and their posts slotted in by date. No
  /// reload, no loader, no scroll reset: the deck is not rebuilt, the new
  /// items are inserted where they belong, so the screen does not flicker.
  ///
  /// Only a settled multi-feed list surface patches. A roster going to or from
  /// one feed changes SHAPE (the one-feed path paginates and carries the
  /// feed's header), and a surface still loading, erroring or gated has no
  /// deck to keep, so those take the full load.
  void setRoster(List<FeedSource> newFeeds, {required int? listId}) {
    final changed = this.listId != listId ||
        !listEquals(
          feeds.map((f) => f.url).toList(),
          newFeeds.map((f) => f.url).toList(),
        );
    if (!changed) return;
    final before = <String>{
      for (final f in feeds)
        if (!_removedUrls.contains(f.url)) f.url,
    };
    _removedUrls.clear();
    final sameList = this.listId == listId;
    feeds = newFeeds;
    this.listId = listId;
    final after = _sourceByUrl;
    final removed = before.difference(after.keys.toSet());
    final added = [
      for (final e in after.entries)
        if (!before.contains(e.key)) e.value,
    ];
    final canPatch = sameList &&
        listId != null &&
        before.length > 1 &&
        after.length > 1 &&
        !_isLoading &&
        _error == null &&
        !_isPrivateFeed &&
        !_gone;
    if (canPatch) {
      _patchRoster(added: added, removed: removed);
    } else {
      load();
    }
  }

  Future<void> _patchRoster({
    required List<FeedSource> added,
    required Set<String> removed,
  }) async {
    if (removed.isNotEmpty) {
      _posts = _posts.where((p) => !removed.contains(p.feedUrl)).toList();
      _lockedFeedUrls = _lockedFeedUrls.difference(removed);
      // Held posts were offered for the old roster; the next refresh offers
      // them again against the new one.
      _pending = null;
      changed();
    }
    if (added.isEmpty) return;

    // A full load started meanwhile owns the deck; this patch steps aside.
    final gen = _loadGeneration;
    final listFeeds = added.map(_toListFeed).toList();
    final urls = {for (final f in added) f.url};
    _setRefreshing(true);
    try {
      // The network starts with the disk read, not after it.
      final freshing = PublicOSFeedLists.refreshPostsForFeeds(listFeeds);
      final cached = await PublicOSFeedLists.getCachedPostsForFeeds(listFeeds);
      if (isDisposed || gen != _loadGeneration) return;
      FeedMetadataUtils.rememberIcons(cached.feedIcons);
      if (cached.posts.isNotEmpty) {
        _slotIn(cached.posts, urls: urls, locked: cached.lockedFeedUrls);
      }
      final fresh = await freshing;
      if (isDisposed || gen != _loadGeneration) return;
      final iconsChanged = FeedMetadataUtils.rememberIcons(fresh.feedIcons);
      if (fresh.posts.isNotEmpty || cached.posts.isEmpty) {
        _slotIn(fresh.posts, urls: urls, locked: fresh.lockedFeedUrls);
      } else if (iconsChanged) {
        changed();
      }
    } catch (_) {
      // The new feed contributes nothing this time, like a failed feed in a
      // roster load; the deck is untouched.
    } finally {
      if (!isDisposed && gen == _loadGeneration) _setRefreshing(false);
    }
  }

  /// Replace the deck's posts of [urls] with [incoming] and merge them in by
  /// date. Both sides are newest-first already (Core sorts what it returns),
  /// so this is one merge pass that never reorders what the reader has.
  void _slotIn(
    List<Post> incoming, {
    required Set<String> urls,
    required Set<String> locked,
  }) {
    final kept = _posts.where((p) => !urls.contains(p.feedUrl)).toList();
    final merged = <Post>[];
    var i = 0, j = 0;
    while (i < kept.length && j < incoming.length) {
      if (incoming[j].createdAt.isAfter(kept[i].createdAt)) {
        merged.add(incoming[j++]);
      } else {
        merged.add(kept[i++]);
      }
    }
    merged
      ..addAll(kept.skip(i))
      ..addAll(incoming.skip(j));
    _posts = merged;
    _lockedFeedUrls = {..._lockedFeedUrls.difference(urls), ...locked};
    changed();
    MediaAspectCache.prefetchAll(MediaAspectCache.singleMediaUrls(incoming));
    _resolve();
  }

  /// Held posts too: the "new" chip shows their authors' faces.
  void _resolve() => resolveContacts([..._posts, ...?_pending?.posts]);

  // -----------------------------------------------------------------------
  // LOADERS — one fetch path, branched by roster SIZE, never by source type
  // -----------------------------------------------------------------------

  /// Post-compose reload: re-fetch and apply the result DIRECTLY, bypassing
  /// the "New posts" chip, then take the author to the top to see their post.
  /// Used by the FAB compose and by the host's `refreshTick`.
  bool _applyNextRefresh = false;

  @override
  Future<void> refreshShowingNewest() async {
    _applyNextRefresh = true;
    try {
      await load();
    } finally {
      _applyNextRefresh = false;
    }
    if (!isDisposed) host?.scrollToTop();
  }

  /// Pull-to-refresh = re-fetch the held urls ONLY. Roster changes
  /// arrive through [setRoster], never from in here.
  @override
  Future<void> load() async {
    if (isDisposed) return;
    _loadGeneration++;
    final gen = _loadGeneration;
    _isLoading = true;
    _isPrivateFeed = false;
    _gateCode = null;
    _paywall = null;
    _gateChannel = null;
    _error = null;
    _gone = false;
    _hasMore = false;
    _pending = null;
    // Cleared on every fresh load; the fetch result repopulates them, so
    // the header is a property of the DATA, not of who asked.
    _description = null;
    _siteUrl = null;
    _language = null;
    _stats = null;
    _postingPolicy = null;
    _channelIsPrivate = null;
    changed();

    try {
      final feeds = _effectiveFeeds;
      if (feeds.isEmpty) {
        _posts = [];
        _isLoading = false;
        changed();
      } else if (feeds.length == 1 && feeds.first.gone) {
        // The owner deleted it — nothing to fetch.
        _gone = true;
        _posts = [];
        _isLoading = false;
        changed();
      } else if (feeds.length == 1) {
        await _loadSingle(feeds.first, gen);
      } else {
        await _loadMany(feeds, gen);
      }
    } catch (e) {
      if (isDisposed || gen != _loadGeneration) return;
      if (e is FeedGoneException) {
        // The server says the feed no longer exists (404).
        _gone = true;
        _posts = [];
        _isLoading = false;
        changed();
        return;
      }
      final s = e.toString();
      final isChannelUrl = _singleFeed != null &&
          channelStubFromFeedUrl(_singleFeed!.url) != null;
      // Keep the TYPED refusal when the fetch surfaced one; otherwise derive
      // the code from the message the same way the boolean below does.
      // PaywallException IS a FeedGateException; the 401-with-a-key is its
      // own type.
      final paywall = e is PaywallException ? e : null;
      final gate = e is FeedGateException ? e : null;
      final signin = e is FeedSigninRequired;
      final code = signin
          ? FeedSigninRequired.code
          : (gate?.code ?? kGateRefusalCodes.where(s.contains).firstOrNull);
      // ENVELOPE_MISSING on a channel URL = the server's privacy-neutral
      // challenge answered a plain fetch we couldn't sign (no key) — for a
      // channel feed that IS the locked gate, not a generic failure.
      //
      // The codes are matched EXPLICITLY rather than by HTTP status, because
      // RssParser substitutes the body's `error.code` for the HTTP code — so
      // a refusal never actually presents as HTTP_403 and any gate code this
      // list omits falls through to a raw error screen: a real gate rendering
      // as "something went wrong". So the set is named in one place
      // ([kGateRefusalCodes]) instead of guessed at.
      _isPrivateFeed = signin ||
          s.contains('PRIVATE_FEED') ||
          (isChannelUrl &&
              (kGateRefusalCodes.any(s.contains) ||
                  s.contains('HTTP_403') ||
                  s.contains('ENVELOPE_MISSING')));
      _gateCode = _isPrivateFeed ? code : null;
      _paywall = _isPrivateFeed ? paywall : null;
      _gateChannel = _isPrivateFeed ? gate?.channel : null;
      _error = _isPrivateFeed ? null : s;
      _isLoading = false;
      _posts = [];
      changed();
    } finally {
      // Guarded so a superseded pass (a newer load bumped the generation)
      // leaves the follow-up to the owner.
      if (!isDisposed && gen == _loadGeneration) {
        // The sign-in row is re-read after EVERY settled load — served or
        // refused — and the ask fires from here (the browser renders this
        // list with no feed header, so the one asker lives in the source, not
        // the header).
        unawaited(_refreshSigninAndMaybeAsk());
      }
    }
  }

  /// Re-read the sign-in row for the single feed; ask ONCE per source life
  /// when a key is loaded, the reader-wide default is OFF, the channel has
  /// signalled (row exists) and the user has not answered (`decision` null).
  /// Rosters never ask. Core never asks — it only hands the row.
  Future<void> _refreshSigninAndMaybeAsk() async {
    final feed = _singleFeed;
    if (feed == null) return;
    final pref = await PublicOSChannelSignin.getPref(feed.url);
    if (isDisposed) return;
    _signinPref = pref;
    changed();
    if (pref == null || pref.decision != null) return;
    if (!PublicOSChannelSignin.hasKey) return;
    if (await PublicOSSettings.getFeedsAutoSignin()) return;
    if (!_askedThisMount.add(feed.url)) return;
    final ctx = host?.context;
    if (isDisposed || ctx == null || !ctx.mounted) return;
    final decision = await showChannelSigninAskDialog(ctx, mode: pref.mode);
    if (decision == null || isDisposed) return;
    await PublicOSChannelSignin.setDecision(feed.url, decision);
    // Full reload under the new posture — never a partial.
    await load();
  }

  void _applyResultMetadata(RefreshedFeedList r) {
    _description = r.description;
    _siteUrl = r.siteUrl;
    _language = r.language;
    _stats = r.stats;
    _postingPolicy = r.postingPolicy;
    _channelIsPrivate = r.isPrivate;
    _hasMore = r.hasMore;
    _gateChannel = r.channel;
  }

  /// **Single feed — two-phase, cached** (everything caches; the bare
  /// first-page default-sort fetch rides the cache, a non-default sort goes
  /// straight to the server, uncached).
  Future<void> _loadSingle(FeedSource feed, int gen) async {
    final foundAtAddr = feed.effectiveFoundAtAddress;

    if (_currentSort != ChannelSort.newest) {
      // Sorted view: direct fetch, server order preserved. No chip logic —
      // there is no cached baseline to diff against.
      final fresh = await PublicOSFeedLists.fetchPostsForFeed(
        feed.url,
        sort: _currentSort.queryParam,
        limit: _pageSize,
        offset: 0,
        feedFoundAtAccountAddress: foundAtAddr,
        feedTitle: feed.title,
      ).timeout(_loadingTimeout);
      if (isDisposed || gen != _loadGeneration) return;
      _posts = fresh.posts;
      _applyResultMetadata(fresh);
      _isLoading = false;
      changed();
      MediaAspectCache.prefetchAll(
        MediaAspectCache.singleMediaUrls(fresh.posts),
      );
      _resolve();
      return;
    }

    // Phase 2 starts now, alongside the disk read, and is awaited below.
    // A newer load can return early and leave it unawaited, so
    // its failure is marked handled here; the await below still sees it.
    final freshing = PublicOSFeedLists.refreshPostsForFeed(
      feed.url,
      feedFoundAtAccountAddress: foundAtAddr,
      feedTitle: feed.title,
    ).timeout(_loadingTimeout);
    unawaited(freshing.then<void>((_) {}, onError: (Object _) {}));

    // ── Phase 1 — cache. Disk only; posts AND header metadata. ────────────
    final cached = await PublicOSFeedLists.getCachedFeed(
      feed.url,
      feedFoundAtAccountAddress: foundAtAddr,
      feedTitle: feed.title,
    );
    if (isDisposed || gen != _loadGeneration) return;
    final hadCache = cached != null && !cached.locked && cached.posts.isNotEmpty;
    // The icon first, then the posts: the rebuild below paints both.
    final cachedIcon = cached?.imageUrl;
    if (cachedIcon != null) {
      FeedMetadataUtils.rememberIcons({feed.url: cachedIcon});
    }
    if (hadCache) {
      _posts = cached.posts;
      _description = cached.description;
      _siteUrl = cached.siteUrl;
      _language = cached.language;
      _stats = cached.stats;
      _postingPolicy = cached.postingPolicy;
      _channelIsPrivate = cached.isPrivate;
      _hasMore = cached.hasMore;
      _isLoading = false; // the reader can start reading NOW
      changed();
      MediaAspectCache.prefetchAll(
        MediaAspectCache.singleMediaUrls(cached.posts),
      );
      _resolve();
    } else if (cached != null && cached.locked) {
      // A persisted locked verdict — show the gate immediately; the refresh
      // below still runs, so a landed approval unlocks without a cold start.
      _isPrivateFeed = true;
      _isLoading = false;
      _posts = [];
      changed();
    }

    // ── Phase 2 — network, behind the reader. ─────────────────────────────
    if (hadCache) _setRefreshing(true);
    final RefreshedFeedList fresh;
    try {
      fresh = await freshing;
    } catch (e) {
      if (isDisposed || gen != _loadGeneration) return;
      _setRefreshing(false);
      // Warm: keep the cached copy on screen — stale beats empty. Cold:
      // rethrow so `load` surfaces the private-feed gate / error.
      // EXCEPT a REFUSAL, warm or cold: the server just said "you may not
      // read this", and a stale (possibly signed) body would contradict it
      // (Deny on a paid channel would leave the feed visible).
      // And never on GONE: the feed no longer exists.
      if (hadCache &&
          !PublicOSFeedLists.isFeedRefusal(e) &&
          e is! FeedGoneException) {
        return;
      }
      rethrow;
    }
    if (isDisposed || gen != _loadGeneration) return;
    _setRefreshing(false);
    final iconsChanged = FeedMetadataUtils.rememberIcons(fresh.feedIcons);

    // Private/locked — this is a single-feed surface, so the whole view is
    // the gate (not a list's "some feeds are private" banner).
    if (fresh.lockedFeedUrls.contains(feed.url)) {
      _isPrivateFeed = true;
      _isLoading = false;
      _posts = [];
      changed();
      return;
    }

    // Nothing came back but we still hold a cached copy — keep showing it.
    // A changed icon still repaints.
    if (fresh.posts.isEmpty && hadCache) {
      if (iconsChanged) changed();
      return;
    }

    // Cold start, nothing changed, or a post-compose reload: apply straight
    // away — no reading position to protect, so a chip would just be an
    // extra tap (after your own post, an actively wrong one).
    if (!hadCache || fresh.newCount == 0 || _applyNextRefresh) {
      _posts = fresh.posts;
      _applyResultMetadata(fresh);
      _isPrivateFeed = false;
      _isLoading = false;
      changed();
      MediaAspectCache.prefetchAll(
        MediaAspectCache.singleMediaUrls(fresh.posts),
      );
      _resolve();
      return;
    }

    // New posts arrived while the user was reading — offer, don't inject.
    // The header metadata updates in place (it sits above the reading
    // position only at the very top, where the chip lands anyway), and so do
    // the posts already on screen: they take their refreshed
    // counts now, same rows, same height, so the reading position holds and
    // only the genuinely new rows wait behind the chip.
    _posts = _refreshShown(_posts, fresh.posts);
    _pending = fresh;
    _applyResultMetadata(fresh);
    changed();
    _resolve();
  }

  /// The on-screen posts, each replaced by its fresh twin (same identity)
  /// when the refresh carried one; posts the refresh no longer lists stay as
  /// they are. Order and count unchanged, so nothing on screen moves.
  static List<Post> _refreshShown(List<Post> shown, List<Post> fresh) {
    final byKey = {for (final p in fresh) postIdentityKey(p): p};
    return [for (final p in shown) byKey[postIdentityKey(p)] ?? p];
  }

  /// **Merged roster — two-phase, cached.**
  ///
  /// Phase 1 paints whatever is on disk — instantly, no network. Phase 2
  /// revalidates every feed with an HTTP conditional GET behind the reader
  /// and, if anything new arrived, **offers** it via a chip rather than
  /// injecting it. No single-feed header, by design — a merged list has no
  /// single feed to describe.
  Future<void> _loadMany(List<FeedSource> feeds, int gen) async {
    final listFeeds = feeds.map(_toListFeed).toList();

    // Phase 2 starts now, alongside the disk read, and is awaited below.
    // It never throws.
    final freshing = PublicOSFeedLists.refreshPostsForFeeds(listFeeds);

    // ── Phase 1 — cache. Disk only; typically a few ms. ────────────────────
    final cached = await PublicOSFeedLists.getCachedPostsForFeeds(listFeeds);
    if (isDisposed || gen != _loadGeneration) return;
    // The icons first, then the posts: the rebuild below paints both.
    FeedMetadataUtils.rememberIcons(cached.feedIcons);

    final hadCache = cached.posts.isNotEmpty;
    if (hadCache) {
      _posts = cached.posts;
      _lockedFeedUrls = cached.lockedFeedUrls;
      _isLoading = false; // the reader can start reading NOW
      // The surface derives "loading ended" from this change: without it the
      // host's big blocking spinner would stay up over content the user can
      // already read, for the entire network refresh.
      changed();
      MediaAspectCache.prefetchAll(
        MediaAspectCache.singleMediaUrls(cached.posts),
      );
      _resolve();
    }

    // ── Phase 2 — network, behind the reader. ─────────────────────────────
    if (hadCache) _setRefreshing(true);
    final fresh = await freshing;
    if (isDisposed || gen != _loadGeneration) return;
    _setRefreshing(false);
    // The icons the refresh read, before its posts land.
    final iconsChanged = FeedMetadataUtils.rememberIcons(fresh.feedIcons);

    // Nothing came back at all (offline, every feed failed) — keep showing the
    // cached copy. Degrading to stale beats degrading to empty. A feed whose
    // fetch fails contributes nothing — its posts are simply absent.
    if (fresh.posts.isEmpty && hadCache) {
      if (iconsChanged) changed();
      return;
    }

    // Cold start, nothing actually changed, or a post-compose reload: apply
    // straight away. There is no reading position to protect, so a chip would
    // just be an extra tap (after your own post, an actively wrong one).
    if (!hadCache || fresh.newCount == 0 || _applyNextRefresh) {
      _posts = fresh.posts;
      _lockedFeedUrls = fresh.lockedFeedUrls;
      _isLoading = false;
      changed();
      MediaAspectCache.prefetchAll(
        MediaAspectCache.singleMediaUrls(fresh.posts),
      );
      _resolve();
      return;
    }

    // New posts arrived while the user was already reading. Date-sorted, they
    // belong ABOVE the current scroll position — applying them now would shove
    // the page down mid-sentence. Hold them and OFFER them instead. The posts
    // already on screen still take their refreshed counts.
    _posts = _refreshShown(_posts, fresh.posts);
    _pending = fresh;
    _lockedFeedUrls = fresh.lockedFeedUrls;
    changed();
    _resolve();
  }

  /// Adapter into the Core loaders' shape. They never read `id`/`listId` —
  /// only `feedUrl` / `feedTitle` / `feedFoundAtAccountAddress`.
  ListFeed _toListFeed(FeedSource f) => ListFeed(
        id: switch (f.origin) {
          ListRowFeedOrigin(:final listFeedId) => listFeedId ?? -1,
          _ => -1,
        },
        listId: listId ?? -1,
        feedUrl: f.url,
        feedTitle: f.title,
        feedFoundAtAccountAddress: f.effectiveFoundAtAddress,
        feedRecordKey: f.recordKey,
        addedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  /// Apply the posts held behind the "New posts" chip, then take the reader to
  /// the top so they read *down* into what arrived.
  @override
  void applyHeld() {
    final pending = _pending;
    if (pending == null) return;
    _posts = pending.posts;
    _pending = null;
    changed();
    MediaAspectCache.prefetchAll(
      MediaAspectCache.singleMediaUrls(pending.posts),
    );
    _resolve();
    host?.scrollToTop();
  }

  void _setRefreshing(bool v) {
    if (_isRefreshing == v) return;
    _isRefreshing = v;
    changed();
  }

  /// Pagination — a single-feed capability, enabled by the response's
  /// `hasMore` (honored ONLY when the roster has exactly one entry).
  /// Pages go straight to the server, uncached.
  @override
  bool get canLoadMore =>
      _singleFeed != null && _hasMore && !_loadingMore && !_isLoading;

  @override
  Future<void> loadMore() async {
    final feed = _singleFeed;
    if (feed == null || _loadingMore || !_hasMore || _isLoading) return;
    _loadingMore = true;
    changed();
    final gen = _loadGeneration;
    try {
      final fresh = await PublicOSFeedLists.fetchPostsForFeed(
        feed.url,
        sort: _currentSort.queryParam,
        limit: _pageSize,
        offset: _posts.length,
        feedFoundAtAccountAddress: feed.effectiveFoundAtAddress,
        feedTitle: feed.title,
      ).timeout(_loadingTimeout);
      if (isDisposed || gen != _loadGeneration) return;
      _posts.addAll(fresh.posts);
      _hasMore = fresh.hasMore;
      _loadingMore = false;
      changed();
      MediaAspectCache.prefetchAll(
        MediaAspectCache.singleMediaUrls(fresh.posts),
      );
      _resolve();
    } catch (_) {
      if (isDisposed) return;
      _loadingMore = false;
      changed();
    }
  }

  // -----------------------------------------------------------------------
  // SORT — a single-feed capability, lit by the response's posting_policy
  // -----------------------------------------------------------------------

  void _onSortChanged(ChannelSort sort) {
    if (sort == _currentSort) return;
    _currentSort = sort;
    load();
  }

  // -----------------------------------------------------------------------
  // VOTE
  // -----------------------------------------------------------------------

  Future<void> _onVote(Post post, int value) async {
    final od = _voteOwnerSlug(post);
    if (od == null || post.uid.isEmpty) return;
    await PublicOSChannels.votePost(
      ownerAddress: od.owner,
      slug: od.slug,
      postUid: post.uid,
      value: value,
      serverAddress: od.server,
      // Required for target_hash — the server rejects signed votes on a
      // signed post that don't carry the content binding.
      post: post,
    );
  }

  /// Owner/slug/server for a vote — a non-fetch job, so the URL stub is fair
  /// game. Prefer the post's OWN feed url (correct per-feed server in a
  /// merged roster); fall back to the stamped post fields.
  ({String owner, String slug, String? server})? _voteOwnerSlug(Post post) {
    final feedUrl = post.feedUrl ?? _singleFeed?.url;
    if (feedUrl != null) {
      final stub = channelStubFromFeedUrl(feedUrl);
      if (stub != null && stub.ownerAddress != null) {
        return (
          owner: stub.ownerAddress!,
          slug: stub.slug,
          server: stub.serverAddress,
        );
      }
    }
    final o = post.channelOwnerAddress;
    final s = post.channelSlug;
    if (o != null && s != null) {
      return (owner: o, slug: s, server: null);
    }
    return null;
  }

  // -----------------------------------------------------------------------
  // COMPOSE — lit by the response (posting_policy == open), any door
  // -----------------------------------------------------------------------

  Channel? get _composeTarget {
    final feed = _singleFeed;
    if (feed == null) return null;
    return channelStubFromFeedUrl(feed.url);
  }

  void _showNewPostSheet(BuildContext context) {
    final feed = _singleFeed;
    final stub = _composeTarget;
    if (feed == null || stub == null || stub.ownerAddress == null) return;
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => ComposePostPage(
          forcedChannelSlug: stub.slug,
          forcedChannelOwner: stub.ownerAddress!,
          forcedChannelServer: stub.serverAddress,
          forcedChannelName: displayName ?? feed.title ?? stub.slug,
          // Response-derived privacy (never the stub's hardcoded flag) —
          // routes media uploads to the pedia door on private channels.
          forcedChannelIsPrivate: _channelIsPrivate ?? false,
          onPostSaved: refreshShowingNewest,
        ),
      ),
    );
  }

  @override
  Widget? floatingAction(BuildContext context) {
    // Compose lights when the DATA says the channel takes posts from anyone
    // (posting_policy == open) — which means it lights from the browser door
    // too. The host can suppress it via showNewPostButton.
    final canCompose =
        showNewPostButton && _isForum && _composeTarget?.ownerAddress != null;
    if (!canCompose) return null;
    final tokens = GlassTokens.of(context);
    return FloatingActionButton(
      heroTag: 'posts_list_fab',
      onPressed: () => _showNewPostSheet(context),
      // Same fill as the Feeds post button (the client's).
      backgroundColor: Color.alphaBlend(tokens.glassFill, tokens.background),
      foregroundColor: tokens.starkWhite,
      elevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.borderMedium, width: 1),
      ),
      child: const Icon(Icons.add_rounded, size: 22),
    );
  }

  // -----------------------------------------------------------------------
  // MUTE CHANNEL (account-origin feed in a list roster)
  // -----------------------------------------------------------------------

  void _snack(String text) {
    final ctx = host?.context;
    if (ctx == null || !ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Mute one account-origin channel: insert a `(accountAddress, recordKey)`
  /// row for this list and drop it from the current view. Reversible from the
  /// list manager. The identifiers come off the feed's own [FeedSource]
  /// origin — never the post's stamped `channelOwnerAddress`.
  Future<void> _muteChannel(BuildContext context, String feedUrl) async {
    final src = _sourceByUrl[feedUrl];
    final origin = src?.origin;
    final session = PublicOS.sessionBlockchainAddress;
    final listId = this.listId;
    if (origin is! AccountFeedOrigin || session == null || listId == null) {
      return;
    }
    final l10n = context.l10n;
    try {
      // Per-list, and anchored on the stable record.key rather than the URL —
      // the mute has to survive the author re-pointing the channel.
      await PublicOS.database.muteChannel(
        session: session,
        account: origin.accountAddress,
        listId: listId,
        recordKey: origin.recordKey,
      );
      if (isDisposed) return;
      _removedUrls.add(feedUrl);
      _posts = _posts.where((post) => post.feedUrl != feedUrl).toList();
      changed();
      _snack(l10n.postsListChannelMuted(src?.title ?? feedUrl));
    } catch (e) {
      if (isDisposed) return;
      _snack(localizedError(l10n, e));
    }
  }

  // -----------------------------------------------------------------------
  // REMOVE FEED FROM LIST (hand-added row in a list roster)
  // -----------------------------------------------------------------------

  Future<void> _removeFeedFromList(BuildContext context, String feedUrl) async {
    final src = _sourceByUrl[feedUrl];
    final origin = src?.origin;
    final listId = this.listId;
    if (origin is! ListRowFeedOrigin || listId == null) return;
    final l10n = context.l10n;
    final listFeedId = origin.listFeedId;
    if (listFeedId == null || listFeedId == -1) {
      _snack(l10n.postsListFeedNotFoundInList);
      return;
    }
    try {
      final success = await PublicOSFeedLists.removeFeedFromList(
        listId,
        listFeedId,
      );
      if (isDisposed) return;
      if (success) {
        _removedUrls.add(feedUrl);
        _posts = _posts.where((post) => post.feedUrl != feedUrl).toList();
        changed();
        _snack(l10n.postsListFeedRemovedFromList(src?.title ?? feedUrl));
      } else {
        _snack(l10n.postsListRemoveFeedFailed);
      }
    } catch (e) {
      if (isDisposed) return;
      _snack(localizedError(l10n, e));
    }
  }

  // -----------------------------------------------------------------------
  // PER-POST HOOKS
  // -----------------------------------------------------------------------

  @override
  PostHooks hooksFor(BuildContext context, Post post) {
    final source = _sourceByUrl[post.feedUrl];
    final isForumPost = post.isForumChannel == true;
    final canVote =
        isForumPost && post.uid.isNotEmpty && _voteOwnerSlug(post) != null;
    final origin = source?.origin;
    return PostHooks(
      showVoting: isForumPost,
      onVote: canVote ? (value) => _onVote(post, value) : null,
      showFeedContext: _isListSurface,
      onPostUpdated: load,
      onPostDeleted: load,
      // Already reading this one feed: "Go to feed" would land right here.
      showGoToFeed: !(_effectiveFeeds.length == 1 &&
          _effectiveFeeds.first.url == post.feedUrl),
      // Account-origin (a followed account's channel) → "Mute channel";
      // list-row origin → "Remove from list". Mutually exclusive, driven by
      // the post's OWN FeedSource origin; both need a list surface (a
      // one-feed list keeps its verbs alongside the feed's own header).
      onMuteChannel: _isListSurface && origin is AccountFeedOrigin
          ? (url) => _muteChannel(context, url)
          : null,
      onRemoveFeedFromList: _isListSurface && origin is ListRowFeedOrigin
          ? (url) => _removeFeedFromList(context, url)
          : null,
    );
  }

  // -----------------------------------------------------------------------
  // CHROME SLOTS
  // -----------------------------------------------------------------------

  @override
  Widget? bannerSlot(BuildContext context) {
    if (!(_isMultiFeed && _lockedFeedUrls.isNotEmpty)) return null;
    return _PrivateFeedsBanner(tokens: GlassTokens.of(context));
  }

  @override
  Widget? pinnedSlot(BuildContext context) {
    if (!_showSortBar) return null;
    return ChannelSortBar(
      current: _currentSort,
      onChanged: _onSortChanged,
    );
  }

  @override
  Widget emptySlot(BuildContext context) {
    final isList = _isListSurface || _isMultiFeed;
    return PostListEmptyContent(
      icon: Icons.article_outlined,
      headline: isList
          ? context.l10n.postsListEmptyListHeadline
          : context.l10n.postsListEmptyHeadline,
      subline: isList
          ? context.l10n.postsListEmptyListSubline
          : context.l10n.postsListEmptySubline,
    );
  }

  @override
  Widget? headerSlot(BuildContext context) {
    final listHeader = this.listHeader;
    if (listHeader != null) return listHeader();
    return _buildChannelHeader(context);
  }

  /// The scroll-away description + stats header for a single feed. Data-driven:
  /// shows whenever the roster is exactly one feed AND the fetch result carried
  /// a description or stats — same channel, same look, every door. Null when
  /// the feed has neither (plain external feed with no description, opted-out,
  /// or unread) — so it never occupies list space it hasn't earned.
  Widget? _buildChannelHeader(BuildContext context) {
    if (!_isSingleSurface) return null;
    final h = host;
    if (h == null) return null;
    final description = _description ?? '';
    final people = _channelPeople();
    // "updated" = the newest post's relative date (a feed's own date is not
    // parsed).
    Post? newest;
    for (final p in _posts) {
      if (newest == null || p.createdAt.isAfter(newest.createdAt)) newest = p;
    }
    final updatedAgo = newest?.formattedDate;
    final has = ChannelHeaderCard.hasContent(
      description: description,
      stats: _stats,
      owner: people?.owner,
      siteUrl: _siteUrl,
      updatedAgo: updatedAgo,
      language: _language,
    );
    if (!has) return null;
    return ChannelHeaderCard(
      description: description,
      stats: _stats,
      owner: people?.owner,
      siteUrl: _siteUrl,
      updatedAgo: updatedAgo,
      language: _language,
      writers: people?.writers ?? const [],
      ownerWrites: people?.ownerWrites ?? false,
      accent: h.accent,
      onFlag: _channelFlagAction(context),
    );
  }

  /// The channel's flag button: one PublicOS channel owned by someone else.
  VoidCallback? _channelFlagAction(BuildContext context) {
    final feeds = _effectiveFeeds;
    if (feeds.length != 1) return null;
    final owner = _ownerInUrl.firstMatch(feeds.first.url)?.group(1);
    final url = channelFlagUrl(feeds.first.url);
    final me = PublicOS.myPublicosAddress;
    if (owner == null ||
        url == null ||
        me == null ||
        owner.toLowerCase() == me.toLowerCase()) {
      return null;
    }
    return () => showFlagSheet(context,
        owner: EthereumAddress.fromHex(owner),
        kind: FlagTargetKind.feed,
        url: url);
  }

  static final RegExp _ownerInUrl =
      RegExp(r'/api/(0x[0-9a-fA-F]{40})/channels/');

  /// Who is behind this one feed: the channel
  /// owner, read from the feed URL, and the writers, the distinct authors of
  /// the received posts (an author-less post is the owner's). Null = no row:
  /// not a PublicOS channel, the owner not resolved yet, or nothing to add —
  /// the profile you're on IS the owner and nobody else writes here.
  /// Forums (open posting) show the owner only.
  ({Contact owner, List<Contact> writers, bool ownerWrites})? _channelPeople() {
    final feeds = _effectiveFeeds;
    if (feeds.length != 1) return null;
    final match = _ownerInUrl.firstMatch(feeds.first.url);
    if (match == null) return null;
    final ownerAddr = match.group(1)!.toLowerCase();
    final byAddr = {
      for (final e in contacts.entries) e.key.toLowerCase(): e.value,
    };
    final owner = byAddr[ownerAddr];
    if (owner == null) return null;

    final writerAddrs = <String>{
      for (final p in _posts)
        (p.postAuthorAddress?.toLowerCase() ?? ownerAddr),
    };
    final onlyOwner = writerAddrs.every((a) => a == ownerAddr);
    final profile = feeds.first.effectiveFoundAtAddress?.toLowerCase();
    if (onlyOwner && profile == ownerAddr) return null;

    final writers = _isForum || onlyOwner
        ? const <Contact>[]
        : [
            for (final a in writerAddrs)
              if (byAddr[a] != null) byAddr[a]!,
          ];
    return (owner: owner, writers: writers, ownerWrites: onlyOwner && !_isForum);
  }

  // -----------------------------------------------------------------------
  // THE GATE — the locked screen for the code the server answered with
  // -----------------------------------------------------------------------

  /// Null when the url carries no channel to unlock (the surface then shows
  /// its generic private error).
  Widget Function(BuildContext)? _gateScreenBuilder() {
    final feed = _singleFeed;
    final stub = feed == null ? null : channelStubFromFeedUrl(feed.url);
    if (stub == null) return null;
    return (context) {
      // One body per refusal code. The server sequences them (blacklist →
      // tier → lists → paywall), so a private paid channel arrives here as
      // PRIVATE_FEED_NOT_APPROVED first and PAYWALL_DENIED only once
      // approved — the client never has to model that order.
      final code = _gateCode;
      final accent = host?.accent;
      // The object the server attached to the refusal, when it did — the
      // locks then paint without a second call. Null on an older
      // server: each lock resolves itself.
      // The refusal's object carries no owner_address (models.Channel only
      // has account_id), so take owner and server from the URL. Without
      // them every lock action returns silently.
      final gate = _gateChannel;
      final live = gate?.copyWith(
        ownerAddress: gate.ownerAddress ?? stub.ownerAddress,
        serverAddress: gate.serverAddress ?? stub.serverAddress,
      );
      if (code == FeedSigninRequired.code) {
        return SigninLockedWidget(
          channel: live ?? stub,
          decision: _signinPref?.decision,
          accentColor: accent,
          onDecide: (d) async {
            await PublicOSChannelSignin.setDecision(feed!.url, d);
            await load();
          },
          onRefresh: load,
        );
      }
      if (code == 'PAYWALL_DENIED') {
        return PaywallLockedWidget(
          channel: stub,
          paywall: _paywall,
          live: live,
          accentColor: accent,
          onPaid: load,
        );
      }
      if (code != null && TierLockedWidget.codes.contains(code)) {
        return TierLockedWidget(
          code: code,
          channel: live ?? stub,
          accentColor: accent,
          onRetry: load,
        );
      }
      return PrivateFeedLockedWidget(
        channel: live ?? stub,
        initialStatus: live?.followStatus,
        accentColor: accent,
        onApproved: load,
      );
    };
  }
}

class _PrivateFeedsBanner extends StatelessWidget {
  final GlassTokens tokens;
  const _PrivateFeedsBanner({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.fallbackAccent.withValues(alpha: 0.10),
        border: Border.all(
          color: tokens.fallbackAccent.withValues(alpha: 0.4),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: tokens.fallbackAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.postsListPrivateFeedsBanner,
              style: TextStyle(
                color: tokens.starkWhite,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
