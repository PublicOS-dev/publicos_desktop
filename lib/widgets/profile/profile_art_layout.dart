import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

/// Banner + page background as ONE picture, the same rule on every host
/// (twins: publicos_client `components/profile/profile_art_layout.dart`, the
/// website's `artFit` in `lobby.js`).
///
/// The background is the canvas and the banner is its full-width top strip.
/// Both are drawn at one shared scale, both centred horizontally:
/// - the banner's bottom sits on the header box's bottom, so any overflow is
///   cut from the TOP;
/// - the background's top sits at the banner's top (above the view when the
///   banner is cut), so at the seam the background picks up exactly where the
///   banner ends.
///
/// The scale fills the width and grows only as far as needed for the
/// banner to cover its box and the background to reach the bottom of the
/// view. With no background the
/// banner is cover-fit, bottom-anchored; with no (plain) banner the
/// background is cover-fit, top-anchored.
class ProfileArtLayout {
  /// Drawn width of the art (≥ the view width).
  final double width;

  /// Top of the background (= the banner strip's top) relative to the header
  /// box's top. ≤ 0 when the banner overflows its box.
  final double top;

  /// Banner aspect (w / h), or null when there is no plain banner.
  final double? bannerAspect;

  /// Drawn background height, or null when there is no background.
  final double? backgroundHeight;

  const ProfileArtLayout._(
      this.width, this.top, this.bannerAspect, this.backgroundHeight);

  /// Left edge of the art inside a view [viewWidth] wide (centred).
  double leftIn(double viewWidth) => (viewWidth - width) / 2;

  /// Drawn banner height: its bottom goes on the box's bottom.
  double get bannerHeight => width / bannerAspect!;

  static ProfileArtLayout? compute({
    required Size? background,
    required Size? banner,
    required double viewWidth,
    required double viewHeight,
    required double boxHeight,
  }) {
    if (viewWidth <= 0) return null;
    final a = banner == null || banner.height <= 0
        ? null
        : banner.width / banner.height;
    final bg = background;
    if (bg != null && bg.width > 0 && bg.height > 0) {
      if (a != null) {
        final strip = bg.width / a; // banner height in background pixels
        var s = viewWidth / bg.width;
        // The banner must cover its box (a tall status bar makes the box
        // taller than a wide banner)...
        if (boxHeight / strip > s) s = boxHeight / strip;
        // ...and the background must reach the bottom of the view.
        if (bg.height > strip) {
          final fill = (viewHeight - boxHeight) / (bg.height - strip);
          if (fill > s) s = fill;
        }
        return ProfileArtLayout._(
            bg.width * s, boxHeight - strip * s, a, bg.height * s);
      }
      final sx = viewWidth / bg.width, sy = viewHeight / bg.height;
      final s = sx > sy ? sx : sy;
      return ProfileArtLayout._(bg.width * s, 0, null, bg.height * s);
    }
    if (a != null) {
      final w = viewWidth > boxHeight * a ? viewWidth : boxHeight * a;
      return ProfileArtLayout._(w, boxHeight - w / a, a, null);
    }
    return null;
  }

  static final Map<String, Size> _sizes = {};
  static final Map<String, List<VoidCallback>> _waiting = {};

  /// The natural size of the image at [url], or null while unknown. On a
  /// miss the image is resolved once (through the same disk cache the
  /// painters use) and every [onReady] asked meanwhile runs when it lands.
  static Size? sizeOf(String? url, VoidCallback onReady) {
    if (url == null || url.isEmpty) return null;
    final known = _sizes[url];
    if (known != null) return known;
    final waiting = _waiting[url];
    if (waiting != null) {
      if (!waiting.contains(onReady)) waiting.add(onReady);
      return null;
    }
    _waiting[url] = [onReady];
    // Never resolve inside build: a cached image answers synchronously, and
    // the callers' setState (plus the shared stream's other listeners) would
    // then fire mid-build. A microtask runs once the current frame is done.
    scheduleMicrotask(() {
      final stream =
          ZeroCachedImageProvider(url).resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener((info, _) {
        _sizes[url] = Size(
            info.image.width.toDouble(), info.image.height.toDouble());
        // Detach after this notification, not inside it.
        scheduleMicrotask(() => stream.removeListener(listener));
        for (final cb in _waiting.remove(url) ?? const <VoidCallback>[]) {
          cb();
        }
      }, onError: (_, __) {
        _waiting.remove(url);
        scheduleMicrotask(() => stream.removeListener(listener));
      });
      stream.addListener(listener);
    });
    return null;
  }
}
