import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart' show PublicOSSsp;
import 'package:publicos_desktop/utils/media_mime.dart';
import 'package:video_player/video_player.dart';
import 'package:zero_cached_image/zero_cached_image.dart';
import 'package:zero_cached_video/zero_cached_video.dart';

/// Process-wide aspect-ratio cache for media URLs. Probes images via
/// [ZeroCachedImageProvider] and videos via [VideoPlayerController.initialize],
/// dedupes inflight probes, and serves cached results synchronously to
/// callers (so feed widgets can render at the right shape on first paint
/// once a probe has run).
///
/// Forever-stored in memory for the process lifetime. Not persisted to disk;
/// first cold-start scroll will warm the cache. Server-side dimensions on
/// the JSON Feed will eventually obsolete this whole layer.
class MediaAspectCache {
  MediaAspectCache._();

  static final Map<String, double> _cache = {};
  static final Map<String, Future<double?>> _inflight = {};

  /// Synchronous lookup. Returns null if the URL has never been probed.
  static double? get(String url) => _cache[url];

  /// Probe one URL. Dedupes against in-flight probes for the same URL.
  /// On success, caches the ratio and returns it. On failure, returns null
  /// and does NOT cache (lets a later viewer retry).
  static Future<double?> probe(String url) {
    final cached = _cache[url];
    if (cached != null) return Future.value(cached);
    final inflight = _inflight[url];
    if (inflight != null) return inflight;

    final f = _doProbe(url);
    _inflight[url] = f;
    return f.whenComplete(() => _inflight.remove(url));
  }

  /// Fire-and-forget bulk prefetch. Bounded concurrency keeps a feed-load
  /// burst from swamping the network. Skips URLs that are already cached
  /// or in flight. Awaits internally; safe to call without `await`.
  static Future<void> prefetchAll(
    Iterable<String> urls, {
    int concurrency = 2,
  }) async {
    final queue = urls
        .where((u) => u.isNotEmpty && !_cache.containsKey(u) && !_inflight.containsKey(u))
        .toList();
    if (queue.isEmpty) return;

    var index = 0;
    Future<void> worker() async {
      while (true) {
        final i = index++;
        if (i >= queue.length) return;
        try {
          await probe(queue[i]);
        } catch (_) {
          // Swallow — failed probes don't block siblings.
        }
      }
    }

    final workers = List.generate(
      concurrency.clamp(1, queue.length),
      (_) => worker(),
    );
    await Future.wait(workers);
  }

  /// Pull single-media URLs out of a list of posts. Helper for callers in
  /// feed loaders — multi-media posts use the fixed-strip carousel path
  /// (200pt height) which doesn't need natural-ratio probing.
  static List<String> singleMediaUrls(Iterable<dynamic> posts) {
    final out = <String>[];
    for (final p in posts) {
      try {
        final List<String> media = (p.carouselImages as List<String>?) ?? const <String>[];
        if (media.length == 1) out.add(media.first);
      } catch (_) {
        // Skip anything that doesn't quack like a Post.
      }
    }
    return out;
  }

  static Future<double?> _doProbe(String url) async {
    if (isVideoUrl(url)) {
      return _probeVideo(url);
    }
    return _probeImage(url);
  }

  static Future<double?> _probeImage(String url) {
    final completer = Completer<double?>();
    final provider = ZeroCachedImageProvider(url);
    final stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        final w = info.image.width;
        final h = info.image.height;
        stream.removeListener(listener);
        if (w > 0 && h > 0) {
          final ratio = w / h;
          _cache[url] = ratio;
          if (!completer.isCompleted) completer.complete(ratio);
        } else {
          if (!completer.isCompleted) completer.complete(null);
        }
      },
      onError: (_, __) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  /// Private (envelope-gated) video can't be probed by a raw network player
  /// (401 → initialize throws → the tile would stay a skeleton forever).
  /// Order: the cached file if any
  /// earlier play or poster left one (exact, hook-safe) → the raw network
  /// probe (public URLs, as always) → for a URL that answers the 401
  /// challenge, 16:9 UNCACHED, so the tile mounts and the player (which
  /// downloads through the hooks) takes over; the next mount finds the
  /// cached file and gets the exact ratio. We never download for a ratio.
  static Future<double?> _probeVideo(String url) async {
    try {
      final cached = await ZeroVideoCacheManager.instance.getCachedFilePath(url);
      if (cached != null && await File(cached).exists()) {
        final r = await _ratioFrom(VideoPlayerController.file(File(cached)));
        if (r != null) return _cache[url] = r;
      }
    } catch (_) {}

    // A video's server poster IS the shape: a small JPEG of frame 0, already
    // display-oriented by the native extractor, and the same bytes the
    // poster tile is about to paint (shared image cache). No video opened.
    // Private ones too: the image provider runs the fetch hooks.
    if (url.contains('/media/') || url.contains('/pedia/')) {
      final pr = await _probeImage(PublicOSSsp.posterUrlFor(url));
      if (pr != null) return _cache[url] = pr;
    }

    final r = await _ratioFrom(VideoPlayerController.networkUrl(Uri.parse(url)));
    if (r != null) return _cache[url] = r;

    if (ZeroFetchHooks.requestAuth != null && await _isChallenged(url)) {
      return 16 / 9;
    }
    return null;
  }

  static Future<double?> _ratioFrom(VideoPlayerController c) async {
    try {
      await c.initialize();
      final size = c.value.size;
      if (size.width > 0 && size.height > 0) return size.width / size.height;
      return null;
    } catch (_) {
      return null;
    } finally {
      await c.dispose();
    }
  }

  /// One unauthenticated `GET Range: bytes=0-0`: true when the server answers
  /// `401` + `WWW-Authenticate` (RFC 7235), i.e. the URL is gated and only the
  /// hook-aware fetchers can open it. Costs the server nothing (no mint).
  static Future<bool> _isChallenged(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-0');
      final response = await request.close().timeout(const Duration(seconds: 8));
      await response.drain<void>();
      return response.statusCode == HttpStatus.unauthorized &&
          response.headers.value(HttpHeaders.wwwAuthenticateHeader) != null;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
