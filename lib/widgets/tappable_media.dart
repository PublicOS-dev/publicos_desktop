import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:publicos_desktop/widgets/post_playback_scope.dart';
import 'package:publicos_desktop/router.dart' show appRouteObserver;
import 'package:publicos_desktop/utils/media_mime.dart';
import 'package:publicos_desktop/widgets/media_overlay.dart';
import 'package:publicos_desktop/widgets/publicos_bytes_video.dart';
import 'package:publicos_desktop/widgets/publicos_video.dart';
import 'package:publicos_desktop/widgets/tappable_image.dart';
import 'package:publicos_desktop/widgets/video_controls_pill.dart';
import 'package:publicos_desktop/widgets/video_url_thumbnail.dart';
import 'package:video_player/video_player.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

/// Unified tap target for posts, chat attachments, etc. Dispatches on
/// extension/MIME — image URLs render `ZeroCachedImage`, video URLs render
/// an inline `PublicOSVideo` (autoplay, muted; one at a time under a
/// `PostPlaybackScope`), both push `MediaOverlay` on tap / expand.
///
/// For image-only call sites that don't need video support, [TappableImage]
/// remains the lighter option.
class TappableMedia extends StatelessWidget {
  /// Either image OR video URL. Dispatch is by extension via [isVideoUrl].
  /// For binary image data (already-loaded XMTP attachments), pass [imageData].
  /// For binary video data (decrypted XMTP RemoteAttachment, or pending
  /// chat-send preview), pass [videoBytes].
  final String? mediaUrl;
  final Uint8List? imageData;
  final Uint8List? videoBytes;

  /// Filename hint for the bytes-video path — used by `PublicOSBytesVideo`
  /// to key the temp file.
  final String? filename;

  /// Force a specific media kind. Useful when the URL has no extension or
  /// when the source provides MIME info upstream.
  final MediaKind? kindOverride;

  /// Optional poster URL for the video case (rendered by PublicOSVideo
  /// in feed / inline contexts).
  final String? posterUrl;

  final String heroTag;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Show the top-right expand-to-fullscreen button on video tiles. Defaults
  /// to true. Set false where fullscreen makes no sense (e.g. send-pending
  /// previews — the user is staging, not consuming).
  final bool showExpandButton;

  /// Video tiles: a handle the host fills with this tile's expand action, so
  /// a corner control the host draws (the post card's pill) opens the
  /// focused viewer the right way: inline decoder released first, position
  /// handed over. With a handle the tile draws no expand disc of its own.
  final ExpandHandle? expandHandle;

  /// Where this clip starts, muted and looping as the surface the user came
  /// from had it (the focused post, opened from a list card with the clip
  /// playing). Null = from the top, the player's defaults.
  final VideoHandoff? videoHandoff;

  /// When true, a video URL renders as a static poster tile with a large
  /// centered play affordance instead of an inline autoplaying player; the
  /// whole tile taps through to [MediaOverlay] (the focused video screen).
  ///
  /// Used by the post carousel, and by the hero pager for every page but the
  /// one on screen: a video tile then fills the same footprint as its sibling
  /// image tiles, and N video tiles in one post don't each mount a
  /// `VideoPlayerController` (the feed-scroll controller-fleet pressure).
  /// URL-only — has no effect on the bytes path. Default
  /// false preserves inline autoplay for existing call sites.
  final bool videoTapToFullscreen;

  /// The post's whole media list and this tile's index in it (the carousel
  /// and the hero pager pass both): the overlay pages through all of them
  /// from this one, whether it opens from a tap on a tile or from the inline
  /// player's expand button.
  final List<MediaGalleryItem>? gallery;
  final int galleryIndex;

  /// The post's header for the overlay's fixed top row ([MediaOverlay.header]);
  /// rides every way into the overlay from this tile (a tap, the expand).
  final Widget? overlayHeader;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const TappableMedia({
    super.key,
    this.mediaUrl,
    this.imageData,
    this.videoBytes,
    this.filename,
    this.kindOverride,
    this.posterUrl,
    required this.heroTag,
    this.borderRadius,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.showExpandButton = true,
    this.expandHandle,
    this.videoHandoff,
    this.videoTapToFullscreen = false,
    this.gallery,
    this.galleryIndex = 0,
    this.overlayHeader,
    this.loadingBuilder,
    this.errorBuilder,
  }) : assert(
         mediaUrl != null || imageData != null || videoBytes != null,
         'Provide one of mediaUrl, imageData, or videoBytes.',
       );

  MediaKind get _kind {
    if (kindOverride != null) return kindOverride!;
    if (videoBytes != null) return MediaKind.video;
    if (imageData != null) return MediaKind.image;
    return isVideoUrl(mediaUrl!) ? MediaKind.video : MediaKind.image;
  }

  @override
  Widget build(BuildContext context) {
    // Bytes-video has its own dispatch — bytes route is exclusive of URL.
    if (videoBytes != null) {
      return _BytesVideoTappable(
        videoBytes: videoBytes!,
        filename: filename,
        heroTag: heroTag,
        borderRadius: borderRadius,
        width: width,
        height: height,
        fit: fit,
        showExpandButton: showExpandButton,
      );
    }
    if (_kind == MediaKind.image) {
      return TappableImage(
        imageUrl: mediaUrl,
        imageData: imageData,
        heroTag: heroTag,
        gallery: gallery,
        galleryIndex: galleryIndex,
        overlayHeader: overlayHeader,
        borderRadius: borderRadius,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
      );
    }
    if (videoTapToFullscreen) {
      return _VideoPosterTappable(
        videoUrl: mediaUrl!,
        posterUrl: posterUrl,
        heroTag: heroTag,
        gallery: gallery,
        galleryIndex: galleryIndex,
        overlayHeader: overlayHeader,
        borderRadius: borderRadius,
        width: width,
        height: height,
        fit: fit,
      );
    }
    return _VideoTappable(
      videoUrl: mediaUrl!,
      posterUrl: posterUrl,
      heroTag: heroTag,
      gallery: gallery,
      galleryIndex: galleryIndex,
      overlayHeader: overlayHeader,
      borderRadius: borderRadius,
      width: width,
      height: height,
      fit: fit,
      showExpandButton: showExpandButton,
      expandHandle: expandHandle,
      videoHandoff: videoHandoff,
    );
  }
}

/// The host's way to trigger a video tile's expand from outside the tile.
/// The tile that owns the handle sets [open] while mounted and clears it on
/// the way out; a host calls [call]. Nothing happens with no owner.
/// One clip, one timeline, across surfaces: videos pass the playback time
/// along and back, so it feels continuous. An inline tile that goes away
/// with a live player leaves its
/// state here under the clip's URL; a tile showing the same clip takes it
/// when it mounts or when the route above it pops. This is what carries the
/// focused post's position back to the list (mobile: the list tile's
/// `didPopNext`; desktop: the Feeds pane rebuilt the list, so a fresh mount)
/// and the list's into desktop's focused post. Small and bounded: the
/// oldest entries fall off.
class VideoResumeMemo {
  VideoResumeMemo._();
  static const int _cap = 64;
  static final Map<String, VideoHandoff> _byUrl = <String, VideoHandoff>{};

  static void put(String url, VideoHandoff h) {
    _byUrl.remove(url);
    _byUrl[url] = h;
    while (_byUrl.length > _cap) {
      _byUrl.remove(_byUrl.keys.first);
    }
  }

  static VideoHandoff? take(String url) => _byUrl.remove(url);

  static void drop(String url) => _byUrl.remove(url);
}

class ExpandHandle {
  VoidCallback? open;
  Object? owner;

  /// The tile's live video state, for a host handing the clip to another
  /// surface (the post card, opening the focused post). Null with no player.
  VideoHandoff? Function()? snapshot;

  void call() => open?.call();
}

/// Static video tile for carousels. Fills the same footprint as a sibling
/// image tile: an optional poster (or a neutral black fill) behind a dim
/// scrim, a large centered play affordance, and a tap that pushes
/// [MediaOverlay] (the focused video screen). No `VideoPlayerController` is
/// mounted — playback happens only in the overlay, so a post with several
/// video tiles costs nothing until one is opened.
class _VideoPosterTappable extends StatelessWidget {
  final String videoUrl;
  final String? posterUrl;
  final String heroTag;
  final List<MediaGalleryItem>? gallery;
  final int galleryIndex;
  final Widget? overlayHeader;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final BoxFit fit;

  const _VideoPosterTappable({
    required this.videoUrl,
    this.posterUrl,
    required this.heroTag,
    this.gallery,
    this.galleryIndex = 0,
    this.overlayHeader,
    this.borderRadius,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openOverlay(context),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (posterUrl != null)
                  ZeroCachedImage(
                    imageUrl: posterUrl!,
                    width: width,
                    height: height,
                    fit: fit,
                  )
                else
                  // Real decoded frame (controller-free) instead of a black
                  // fill — feed video posters now show a thumbnail like chat.
                  VideoUrlThumbnail(videoUrl: videoUrl, fit: fit),
                // Dim scrim so the play glyph reads at any frame brightness.
                const ColoredBox(color: Colors.black26),
                const Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openOverlay(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => gallery != null
            ? MediaOverlay(
                header: overlayHeader,
                gallery: gallery,
                initialIndex: galleryIndex,
                heroTag: heroTag,
                onClose: () => Navigator.pop(context),
              )
            : MediaOverlay(
                header: overlayHeader,
                videoUrl: videoUrl,
                heroTag: heroTag,
                onClose: () => Navigator.pop(context),
              ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

class _VideoTappable extends StatefulWidget {
  final String videoUrl;
  final String? posterUrl;
  final String heroTag;
  final List<MediaGalleryItem>? gallery;
  final int galleryIndex;
  final Widget? overlayHeader;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool showExpandButton;
  final ExpandHandle? expandHandle;

  /// Where this clip starts, muted and looping as the surface the user came
  /// from had it (the focused post, opened from a list card with the clip
  /// playing). Null = from the top, the player's defaults.
  final VideoHandoff? videoHandoff;

  const _VideoTappable({
    required this.videoUrl,
    this.posterUrl,
    required this.heroTag,
    this.gallery,
    this.galleryIndex = 0,
    this.overlayHeader,
    this.borderRadius,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.showExpandButton = true,
    this.expandHandle,
    this.videoHandoff,
  });

  @override
  State<_VideoTappable> createState() => _VideoTappableState();
}

/// Manages the inline decoder against routes pushed on top.
///
/// ANY route pushed above this tile — a profile, the browser, or its own
/// fullscreen handoff (the expand button → `MediaOverlay`) — **unmounts**
/// the inline player (`_released`); the tile shows a thumbnail until the
/// route pops, then remounts a fresh controller. Merely pausing is not
/// enough: a paused ExoPlayer keeps its 64KiB-segment buffer pool on the
/// Java heap AND keeps loading toward its buffer target, so a feeds-view
/// player alive under a pushed browser rendering the same clip stacks two
/// full buffers and blows the 256MB heap limit (a device OOM).
/// Unmount trades instant-resume for the whole buffer back.
class _VideoTappableState extends State<_VideoTappable> with RouteAware {
  bool _released = false;

  // One-at-a-time playback on a feed (post_playback_scope.dart). Null when
  // no list placed a scope above us: then this tile is always active.
  PostPlaybackController? _playback;
  bool _wasActive = true;
  // TickerMode.valuesOf(context).enabled: false under a hidden shell tab (the explorer
  // wraps each IndexedStack child in TickerMode). Offstage = no player.
  bool _onstage = true;
  // The live inline controller, captured from the controls builder so the
  // position can be saved before the player unmounts.
  VideoPlayerController? _controller;
  // Where this clip was when its player last unmounted (lost the slot, a
  // route covered it, or it was expanded, in which case the overlay reports
  // back where the user left it). The list's scope keeps the same value for
  // tiles that come and go; this one lives with the tile.
  late Duration? _resumeAt = widget.videoHandoff?.position;
  // The mute / loop the last surface handed back (the focused media closing,
  // or the memo). Only read where no list scope keeps the mute (the focused
  // post), so the choice made in the expanded view survives the way back.
  bool? _mutedBack;
  bool? _loopBack;
  bool _tookMemo = false;

  String get _playbackId => widget.heroTag;

  bool get _isActive =>
      _onstage && (_playback == null || _playback!.activeId == _playbackId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
    // Leaving the tab: keep the position before the rebuild unmounts the
    // player (this runs before build, the controller is still alive).
    final onstage = TickerMode.valuesOf(context).enabled;
    if (_onstage && !onstage) _savePosition();
    _onstage = onstage;
    final playback = PostPlaybackScope.maybeOf(context);
    if (!identical(playback, _playback)) {
      _playback?.removeListener(_onPlaybackChanged);
      _playback?.scrollTick.removeListener(_measure);
      _playback = playback;
      _playback?.addListener(_onPlaybackChanged);
      _playback?.scrollTick.addListener(_measure);
      _wasActive = _isActive;
      _scheduleMeasure();
    }
    if (!_tookMemo) {
      _tookMemo = true;
      // An explicit handoff from the opener is the fresher word.
      if (widget.videoHandoff != null) {
        VideoResumeMemo.drop(widget.videoUrl);
      } else {
        _takeMemo();
      }
    }
  }

  /// Adopt what another surface left for this clip, if anything.
  void _takeMemo() {
    final h = VideoResumeMemo.take(widget.videoUrl);
    if (h == null) return;
    _resumeAt = h.position;
    _playback?.savePosition(_playbackId, h.position);
    _playback?.setMuted(h.muted);
    _mutedBack = h.muted;
    _loopBack = h.looping;
  }

  @override
  void didUpdateWidget(covariant _VideoTappable old) {
    super.didUpdateWidget(old);
    // NaturalRatioMedia resizes us once the ratio is known: measure again.
    if (old.width != widget.width || old.height != widget.height) {
      _scheduleMeasure();
    }
  }

  @override
  void dispose() {
    final handle = widget.expandHandle;
    if (handle != null && identical(handle.owner, this)) {
      handle.open = null;
      handle.owner = null;
      handle.snapshot = null;
    }
    // Leaving with a live player: the next surface showing this clip picks
    // it up from here (the focused post closing, a desktop list swapped out).
    final live = _handoff();
    if (live != null) VideoResumeMemo.put(widget.videoUrl, live);
    _savePosition();
    _playback?.removeListener(_onPlaybackChanged);
    _playback?.scrollTick.removeListener(_measure);
    _playback?.forget(_playbackId);
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  void _scheduleMeasure() {
    if (_playback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final playback = _playback;
    if (playback == null || !mounted) return;
    final seen = measureVisibility(context);
    if (seen == null) return;
    playback.report(_playbackId, fraction: seen.fraction, top: seen.top);
  }

  /// Runs before the rebuild that swaps the player for the poster: the
  /// controller is still alive here, so its position can be kept.
  void _onPlaybackChanged() {
    final active = _isActive;
    if (_wasActive && !active) _savePosition();
    _wasActive = active;
  }

  /// The live player's position, zero once it has run to the end, null when
  /// there is no initialized player to ask.
  Duration? _livePosition() {
    final c = _controller;
    if (c == null) return null;
    try {
      if (c.value.isCompleted) return Duration.zero;
      if (c.value.isInitialized) return c.value.position;
    } catch (_) {
      // A disposed controller throws on value: nothing to keep.
    }
    return null;
  }

  void _savePosition() {
    final at = _livePosition();
    if (at != null) {
      _resumeAt = at;
      _playback?.savePosition(_playbackId, at);
    }
    _controller = null;
  }

  /// The live player's state for the next surface; null with no player.
  VideoHandoff? _handoff() {
    final c = _controller;
    return c == null ? null : VideoHandoff.of(c);
  }

  /// The focused media screen closed: its state comes back. The position
  /// to this tile and the list's scope, the mute choice to the scope, so
  /// the remount (and the list's next winner) follow what the user set
  /// there. Loop needs no carrying: the pill persists it app-wide.
  void _resumeFrom(VideoHandoff h) {
    _resumeAt = h.position;
    _playback?.savePosition(_playbackId, h.position);
    _playback?.setMuted(h.muted);
    _mutedBack = h.muted;
    _loopBack = h.looping;
    // This is the freshest word; nothing older may override it on remount.
    VideoResumeMemo.drop(widget.videoUrl);
  }

  @override
  void didPushNext() {
    _savePosition();
    if (!_released) setState(() => _released = true);
  }

  @override
  void didPopNext() {
    // Route above dismissed → remount the inline player (a fresh controller,
    // re-gated by current size rules, resuming where it was if a scope kept
    // the position). A clip another surface played meanwhile (the focused
    // post) left its state in the memo: resume from that.
    _takeMemo();
    if (_released) setState(() => _released = false);
  }

  @override
  Widget build(BuildContext context) {
    // The host's corner control reaches this tile's expand through the
    // handle; the tile on screen owns it (a pager rebuilds the leaving page
    // after the arriving one, so ownership decides who may clear it).
    final handle = widget.expandHandle;
    if (handle != null) {
      handle.open = _openOverlay;
      handle.owner = this;
      handle.snapshot = _handoff;
    }
    final playback = PostPlaybackScope.maybeOf(context);
    final active =
        TickerMode.valuesOf(context).enabled &&
        (playback == null || playback.activeId == _playbackId);
    // Loading poster: the explicit posterUrl if one was given, otherwise a
    // decoded thumbnail frame of this video. ZeroCachedVideo paints the poster
    // during its probing/downloading phases, so the inline player shows the
    // real frame while it loads instead of a bare spinner → no spinner/black →
    // video flicker. The thumbnail reuses the player's cached file (no extra
    // download). Video-only — images never reach _VideoTappable.
    final Widget poster = widget.posterUrl != null
        ? ZeroCachedImage(
            imageUrl: widget.posterUrl!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          )
        : VideoUrlThumbnail(videoUrl: widget.videoUrl, fit: widget.fit);

    return Hero(
      tag: widget.heroTag,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_released || !active)
                // Either a route is on top (fullscreen overlay, profile,
                // browser…) or another tile holds this list's playback slot:
                // the inline player is unmounted (its controller disposed) so
                // its buffers are freed and only one decoder exists. Show a
                // thumbnail in its place (it shares the player's cached file,
                // no extra download). A tap on a waiting tile claims the slot.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: playback == null || _released || !_onstage
                      ? null
                      : () => playback.claim(_playbackId),
                  child: VideoUrlThumbnail(
                    videoUrl: widget.videoUrl,
                    fit: widget.fit,
                  ),
                )
              else
                // Full focused-screen video handling inline: the shared
                // VideoControlsPill brings play/pause + scrubber + position +
                // loop + mute AND the replay-on-completion the built-in play
                // button lacked. `compact: true` lays it out two-row and hugs
                // the bottom; no save button inline (omit onSave) — saving
                // lives in the full-screen overlay reached via the expand
                // button. Autoplays muted on a feed; the pill's volume button
                // unmutes. Loop follows the pill's persisted pref.
                PublicOSVideo(
                  videoUrl: widget.videoUrl,
                  width: widget.width,
                  height: widget.height,
                  fit: widget.fit,
                  poster: poster,
                  // No spinner over the poster: the poster IS the loading
                  // state.
                  placeholder: (_, __) => const SizedBox.shrink(),
                  showBuiltInPlayPause: true,
                  autoplay: true,
                  // Muted unless the user unmuted an earlier winner on this
                  // list; the choice travels with the slot.
                  startMuted: playback?.muted ??
                      _mutedBack ??
                      widget.videoHandoff?.muted ??
                      true,
                  loop: _loopBack ?? widget.videoHandoff?.looping ?? false,
                  // Resume where this clip was when it lost the slot, or
                  // where the user left it in the expanded view.
                  initialPosition:
                      playback?.positionFor(_playbackId) ?? _resumeAt,
                  // Takes no audio focus: every player that does makes Android
                  // send AUDIOFOCUS_LOSS to the previous holder, and media3
                  // pauses on that, so two mounted tiles freeze each other. The
                  // focused overlay keeps the default and still takes focus.
                  mixWithOthers: true,
                  controlsBuilder: (ctx, c) {
                    // Keep a handle on the live controller: the position is
                    // read from it right before the player unmounts.
                    _controller = c as VideoPlayerController;
                    return VideoControlsPill(
                      controller: c,
                      compact: true,
                      // Expand lives in the controls row, left of loop; there
                      // is no floating top-right button.
                      onExpand: widget.showExpandButton &&
                              widget.expandHandle == null
                          ? _openOverlay
                          : null,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openOverlay() {
    // Free the inline decoder BEFORE the overlay's spins up: render the
    // thumbnail this frame (which unmounts + disposes the inline controller),
    // then push the focused viewer on the next frame so the two never decode
    // the same clip simultaneously. didPushNext re-asserts the flag, no-op.
    //
    // The expanded player picks up at this frame's position and, on close,
    // hands back where the user left it; didPopNext then remounts the inline
    // player there. One clip, one timeline, two sizes.
    final handoff = _handoff();
    _savePosition();
    setState(() => _released = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // A page of a post's media list (the hero pager) opens the paging
      // lightbox at its own page; a lone video opens alone.
      final gallery = widget.gallery;
      Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => gallery != null
              ? MediaOverlay(
                  header: widget.overlayHeader,
                  gallery: gallery,
                  initialIndex: widget.galleryIndex,
                  heroTag: widget.heroTag,
                  handoff: handoff,
                  onVideoHandoff: _resumeFrom,
                  onClose: () => Navigator.pop(context),
                )
              : MediaOverlay(
                  header: widget.overlayHeader,
                  videoUrl: widget.videoUrl,
                  heroTag: widget.heroTag,
                  handoff: handoff,
                  onVideoHandoff: _resumeFrom,
                  onClose: () => Navigator.pop(context),
                ),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }
}

/// Bytes-driven sibling of [_VideoTappable]. Same UX shape (autoplay muted,
/// tap toggle, top-right expand to MediaOverlay, Hero handoff, pause when
/// an overlay is on top) — underlying player is `PublicOSBytesVideo`
/// (sha256 → temp file → file controller) instead of `PublicOSVideo` (URL).
class _BytesVideoTappable extends StatefulWidget {
  final Uint8List videoBytes;
  final String? filename;
  final String heroTag;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool showExpandButton;

  const _BytesVideoTappable({
    required this.videoBytes,
    this.filename,
    required this.heroTag,
    this.borderRadius,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.showExpandButton = true,
  });

  @override
  State<_BytesVideoTappable> createState() => _BytesVideoTappableState();
}

class _BytesVideoTappableState extends State<_BytesVideoTappable>
    with RouteAware {
  // Same unmount-on-route-push policy as _VideoTappableState (see its doc):
  // a paused player keeps + keeps filling its ExoPlayer buffer pool, so any
  // route on top frees the inline player and shows nothing-heavy instead.
  // Remounting from the bytes' temp file on pop is cheap (file persists).
  bool _released = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    if (!_released) setState(() => _released = true);
  }

  @override
  void didPopNext() {
    if (_released) setState(() => _released = false);
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.heroTag,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_released || !TickerMode.valuesOf(context).enabled)
                // Route on top, or a hidden shell tab — player unmounted.
                // Neutral black fill (no
                // URL to thumbnail from); the Hero/footprint stays stable.
                const ColoredBox(color: Colors.black)
              else
                PublicOSBytesVideo(
                  data: widget.videoBytes,
                  filename: widget.filename,
                  width: widget.width,
                  height: widget.height,
                  fit: widget.fit,
                  showBuiltInPlayPause: true,
                  autoplay: true,
                  // Loops: a bytes clip is a short local thing (a chat
                  // attachment, a draft in the composer) and keeps going.
                  loop: true,
                  startMuted: true,
                  // Same reason as the URL tile above: no audio focus.
                  mixWithOthers: true,
                ),
              if (widget.showExpandButton)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openOverlay,
                    child: const Padding(
                      // No disc: the glyph under a soft
                      // shade, like the row buttons on the post player.
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.open_in_full_rounded,
                        color: Colors.white,
                        size: 20,
                        shadows: [
                          Shadow(color: Color(0x80000000), blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openOverlay() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => MediaOverlay(
          videoBytes: widget.videoBytes,
          filename: widget.filename,
          heroTag: widget.heroTag,
          onClose: () => Navigator.pop(context),
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}
