import 'dart:async';
import 'dart:convert';

import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/utils/favicon_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedMetadata {
  final String title;
  final String? imageUrl;
  final String? description;

  FeedMetadata({
    required this.title,
    this.imageUrl,
    this.description,
  });
}

class FeedMetadataUtils {
  static final Map<String, FeedMetadata> _cache = {};
  static const Duration _cacheExpiry = Duration(hours: 1);
  static final Map<String, DateTime> _cacheTimestamps = {};

  /// One fetch per url at a time: every caller asking while it runs shares
  /// it. Without this, a list header's pre-fetch and its icon tile would
  /// each download the same whole channel document.
  static final Map<String, Future<FeedMetadata?>> _inFlight = {};

  /// Get RSS feed metadata (title, image, description) with caching
  static Future<FeedMetadata?> getFeedMetadata(String rssUrl) {
    final cachedTime = _cacheTimestamps[rssUrl];
    if (_cache.containsKey(rssUrl) &&
        cachedTime != null &&
        DateTime.now().difference(cachedTime) < _cacheExpiry) {
      return Future.value(_cache[rssUrl]);
    }
    return _inFlight[rssUrl] ??=
        _fetchMetadata(rssUrl).whenComplete(() => _inFlight.remove(rssUrl));
  }

  static Future<FeedMetadata?> _fetchMetadata(String rssUrl) async {
    try {
      // Fetch fresh data — `userAddress` parameter retired with
      // unified_interaction_rules / Core 0.4.0; signed reads now derive
      // identity from the envelope, anonymous reads get no enrichment.
      final feed = await RssParser.fetchFeed(rssUrl);

      final metadata = FeedMetadata(
        title: feed.title,
        imageUrl: feed.imageUrl,
        description: feed.description,
      );

      // Cache the result
      _cache[rssUrl] = metadata;
      _cacheTimestamps[rssUrl] = DateTime.now();
      if (!feed.isParseError) {
        rememberIcons({rssUrl: feed.imageUrl?.trim() ?? ''});
      }

      return metadata;
    } catch (e) {
      // If fetch fails but we have cached data, return it even if expired
      if (_cache.containsKey(rssUrl)) {
        return _cache[rssUrl];
      }

      // Return null if no data available
      return null;
    }
  }

  /// Clear the cache
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Clear expired entries from cache
  static void cleanupCache() {
    final now = DateTime.now();
    final expiredKeys = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value) >= _cacheExpiry)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  // ── The icon registry ──────────────────────────────────────────────────
  //
  // Feed url → the feed's own image (a channel's icon or its owner's
  // avatar, RSS <image>, Atom <logo>, JSON Feed icon); '' = the feed has
  // none, so its site favicon stands in. Kept in memory and saved to disk,
  // so an icon paints at once, cold start included, with no network.
  //
  // It is written by the loads that already read the feed: the post
  // loader's cached paint and its refresh hand over Core's `feedIcons`.
  // The refresh writes first and the loader rebuilds, so the icon updates
  // before the posts do. A feed that no load has read yet costs one shared
  // fetch through [getFeedMetadata], which writes here too.

  static const _iconsKey = 'feed_icon_registry';
  static final Map<String, String> _icons = {};
  static Future<void>? _iconsLoad;

  /// Read the saved registry once. Idempotent; cheap after the first call.
  static Future<void> loadIcons() => _iconsLoad ??= _readIcons();

  static Future<void> _readIcons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_iconsKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      decoded.forEach((k, v) {
        // A value set this session is newer than the saved one.
        if (k is String && v is String) _icons.putIfAbsent(k, () => v);
      });
    } catch (_) {}
  }

  /// Store icons a load just read. True when any of them changed, so the
  /// caller knows a rebuild is worth it.
  static bool rememberIcons(Map<String, String> icons) {
    var changed = false;
    icons.forEach((url, icon) {
      if (_icons[url] != icon) {
        _icons[url] = icon;
        changed = true;
      }
    });
    if (changed) unawaited(_saveIcons());
    return changed;
  }

  static Future<void> _saveIcons() async {
    // Never write over the saved copy before it was read in.
    await loadIcons();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_iconsKey, jsonEncode(_icons));
    } catch (_) {}
  }

  /// What to paint for [feedUrl] right now, from memory: its own image,
  /// else its site favicon. Null means the registry does not know the feed
  /// yet; `(url: null)` means it is known and has nothing (the RSS glyph).
  static ({String? url})? displayIconNow(String feedUrl) {
    final image = _icons[feedUrl];
    if (image == null) return null;
    if (image.isNotEmpty) return (url: image);
    return (url: _favicon(feedUrl));
  }

  /// [displayIconNow], falling back to the saved registry and then to one
  /// shared fetch. Never throws.
  static Future<String?> resolveDisplayIcon(String feedUrl) async {
    final now = displayIconNow(feedUrl);
    if (now != null) return now.url;
    await loadIcons();
    final loaded = displayIconNow(feedUrl);
    if (loaded != null) return loaded.url;
    final m = await getFeedMetadata(feedUrl);
    final image = m?.imageUrl?.trim();
    if (image != null && image.isNotEmpty) return image;
    return _favicon(feedUrl);
  }

  static String? _favicon(String feedUrl) {
    try {
      final uri = Uri.parse(feedUrl);
      if (uri.host.isEmpty) return null;
      return FaviconUtils.getFaviconUrl('${uri.scheme}://${uri.host}');
    } catch (_) {
      return null;
    }
  }
}
