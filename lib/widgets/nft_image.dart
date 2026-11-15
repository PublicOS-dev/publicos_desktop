import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

/// One image widget that renders whatever an NFT's `image` field throws at it,
/// picking the renderer by media type:
///
///   - **SVG** (`data:image/svg+xml…` or a `.svg` URL) → `flutter_svg`. On-chain
///     SVG is sanitized first — flutter_svg's parser rejects the CSS
///     `transform: rotate(.0turn)` that on-chain generators emit, so the
///     `transform:` declaration is stripped (cosmetic / a no-op). An on-chain
///     SVG that is a frame flipbook plays as one ([SvgFlipbook]).
///   - **raster `data:` URI** (`data:image/png|jpeg|gif|webp…`) → `Image.memory`.
///   - **everything else** (http/https/ipfs-resolved URLs) → `ZeroCachedImage`,
///     so normal NFT + avatar images keep their disk cache.
class NftImage extends StatefulWidget {
  final String url;
  final BoxFit fit;

  /// Shown when there is **no image to show**: a bad `data:` URI, an SVG that
  /// won't parse, a decode error, a network failure.
  final Widget? fallback;

  /// Shown while a network image is **still resolving**. Deliberately separate
  /// from [fallback]: "the artwork is on its way" and "there is no artwork" are
  /// different states, and painting the fallback during the wait makes
  /// every avatar flash its initials tile before the picture arrives. Falls
  /// back to [fallback] when null, for callers that don't distinguish the
  /// two.
  final Widget? placeholder;

  /// Logical edge (in dp) of the box this image renders into. When set, raster
  /// paths decode down to ~this size (× device pixel ratio) instead of the
  /// NFT's native resolution — a high-def image in a small avatar stays crisp
  /// (decoder downscale + mipmapped sampling) and costs far less memory. Null
  /// decodes at native resolution. Vector (SVG) ignores it.
  final double? renderSize;

  const NftImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallback,
    this.placeholder,
    this.renderSize,
  });

  @override
  State<NftImage> createState() => _NftImageState();

  static bool _isSvgUrl(String url) =>
      url.startsWith('data:image/svg') ||
      ((url.startsWith('http://') || url.startsWith('https://')) &&
          url.toLowerCase().split('?').first.endsWith('.svg'));

  /// Bytes from a `data:[<mime>][;base64],<payload>` URI.
  static Uint8List? _dataUriBytes(String uri) {
    final comma = uri.indexOf(',');
    if (comma < 0) return null;
    final meta = uri.substring(5, comma);
    final payload = uri.substring(comma + 1);
    try {
      if (meta.contains('base64')) return base64.decode(payload);
      return Uint8List.fromList(utf8.encode(Uri.decodeComponent(payload)));
    } catch (_) {
      return null;
    }
  }

  /// flutter_svg's transform parser can't handle CSS angle units (turn/deg/rad)
  /// that fully-on-chain art puts in `style="…transform: rotate(.0turn)"`. Strip
  /// CSS `transform:` declarations from inline styles (cosmetic / usually a
  /// no-op); the SVG `transform=""` presentation attribute is left untouched.
  static String _sanitizeSvg(String svg) =>
      svg.replaceAll(RegExp(r'transform\s*:\s*[^;"]*;?', caseSensitive: false), '');
}

class _NftImageState extends State<NftImage> {
  /// Sanitized + validated SVG source for an on-chain `data:` SVG, or null.
  String? _svg;
  bool _svgFailed = false;

  /// The same SVG as frames, when its art is a flipbook; null plays nothing.
  SvgFlipbook? _book;

  @override
  void initState() {
    super.initState();
    _resolveSvg();
  }

  @override
  void didUpdateWidget(covariant NftImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _resolveSvg();
  }

  /// For on-chain (`data:`) SVG only: decode → sanitize once. Network SVGs and
  /// non-SVGs are handled directly in [build].
  void _resolveSvg() {
    _svg = null;
    _svgFailed = false;
    _book = null;
    final url = widget.url;
    if (!NftImage._isSvgUrl(url) || !url.startsWith('data:')) return;
    final bytes = NftImage._dataUriBytes(url);
    if (bytes == null) {
      _svgFailed = true;
      return;
    }
    _svg = NftImage._sanitizeSvg(utf8.decode(bytes, allowMalformed: true));
    _book = SvgFlipbook.parse(_svg!);
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    // `fb` is the no-image state, `ph` the still-loading one. Every error slot
    // below takes `fb`; every loading slot takes `ph`.
    final fb = widget.fallback ?? const SizedBox.shrink();
    final ph = widget.placeholder ?? fb;

    // Decode target in physical pixels: a high-def NFT downsampled once by the
    // decoder is sharper than the GPU minifying a full-res texture every frame.
    final int? decodePx = widget.renderSize == null
        ? null
        : (widget.renderSize! * MediaQuery.devicePixelRatioOf(context)).ceil();

    // On-chain SVG (validated above).
    if (url.startsWith('data:') && NftImage._isSvgUrl(url)) {
      if (_svgFailed || _svg == null) return fb;
      if (_book != null) {
        return _SvgFlipbookView(book: _book!, fit: widget.fit, placeholder: ph);
      }
      return SvgPicture.string(_svg!, fit: widget.fit,
          placeholderBuilder: (_) => ph);
    }

    // Network SVG — best effort (can't pre-validate synchronously).
    if (NftImage._isSvgUrl(url)) {
      return SvgPicture.network(url, fit: widget.fit,
          placeholderBuilder: (_) => ph);
    }

    // Raster data: URI — decode inline.
    if (url.startsWith('data:')) {
      final bytes = NftImage._dataUriBytes(url);
      if (bytes == null) return fb;
      return Image.memory(bytes,
          fit: widget.fit,
          gaplessPlayback: true,
          // Single-axis decode: pinning BOTH cacheWidth+cacheHeight to the same
          // scalar forces an exact square decode that squishes non-square sources
          // (e.g. Farcaster pfps) before BoxFit.cover ever runs. One axis preserves
          // the source aspect ratio; cover then crops it into the square box.
          cacheWidth: decodePx,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => fb);
    }

    // Network / ipfs-resolved URL — keep ZeroCachedImage's disk cache.
    return ZeroCachedImage(
      imageUrl: url,
      fit: widget.fit,
      // Single axis only (see note in the data-URI branch above): both axes would
      // force a square decode and distort non-square avatars; this keeps aspect.
      memCacheWidth: decodePx,
      filterQuality: FilterQuality.medium,
      placeholder: (_, __) => ph,
      errorWidget: (_, __, ___) => fb,
    );
  }
}

/// An on-chain SVG whose animation is a frame flipbook, split into one still
/// SVG per frame.
///
/// flutter_svg draws no SVG animation, so art that a browser shows moving
/// painted as its first frame only. The usual on-chain pixel-art animation is
/// the one this reads: elements that take turns being shown, each carrying as
/// its first child
///
///     <animate attributeName="visibility" calcMode="discrete"
///              values="visible;hidden;hidden;visible"
///              keyTimes="0;0.333;0.667;1" dur="390ms" repeatCount="indefinite"/>
///
/// (`display` works the same way). Everything else an SVG can animate (motion,
/// colour, transforms, CSS keyframes) is left as it was: not played.
/// [parse] returns null for anything it does not fully understand, and the
/// caller then paints the SVG as before.
class SvgFlipbook {
  /// One complete SVG per frame, the `<animate>` elements removed.
  final List<String> frames;

  /// When each frame starts inside the loop, in microseconds. Starts at 0.
  final List<int> starts;

  /// Length of the loop in microseconds.
  final int loopMicros;

  const SvgFlipbook._(this.frames, this.starts, this.loopMicros);

  static const int _maxFrames = 32;

  /// Nothing switches faster than this; a quicker flipbook is not played.
  static const int _minFrameMicros = 40000;

  /// The frame showing at [micros] on any clock.
  int frameAt(int micros) {
    final t = micros % loopMicros;
    var i = frames.length - 1;
    while (i > 0 && starts[i] > t) {
      i--;
    }
    return i;
  }

  /// Microseconds from [micros] until the next frame starts.
  int untilNext(int micros) {
    final t = micros % loopMicros;
    final i = frameAt(micros);
    final next = i + 1 < starts.length ? starts[i + 1] : loopMicros;
    return next - t;
  }

  static String? _attr(String tag, String name) {
    final m = RegExp('(?:^|\\s)$name\\s*=\\s*(["\'])(.*?)\\1', dotAll: true)
        .firstMatch(tag);
    return m?.group(2);
  }

  /// `390ms`, `1.5s` or a bare number of seconds. Null for anything else.
  static int? _durMicros(String? dur) {
    if (dur == null) return null;
    final m = RegExp(r'^\s*([0-9]*\.?[0-9]+)\s*(ms|s)?\s*$').firstMatch(dur);
    if (m == null) return null;
    final n = double.tryParse(m.group(1)!);
    if (n == null || n <= 0) return null;
    return (n * (m.group(2) == 'ms' ? 1000 : 1000000)).round();
  }

  static SvgFlipbook? parse(String svg) {
    if (!svg.contains('<animate')) return null;

    final tracks = <_FlipTrack>[];
    int? loop;
    final animates = RegExp(r'<animate\b([^>]*?)(?:/>|>\s*</animate\s*>)',
        dotAll: true);
    for (final m in animates.allMatches(svg)) {
      final attrs = m.group(1)!;
      final name = _attr(attrs, 'attributeName');
      if (name != 'visibility' && name != 'display') continue;
      if (_attr(attrs, 'calcMode') != 'discrete') continue;
      // A begin offset or a finite repeat is a different animation; leave it.
      final begin = _attr(attrs, 'begin');
      if (begin != null && begin.trim() != '0' && begin.trim() != '0s') {
        return null;
      }
      if (_attr(attrs, 'repeatCount') != 'indefinite') return null;

      final dur = _durMicros(_attr(attrs, 'dur'));
      if (dur == null) return null;
      if (loop != null && loop != dur) return null; // one clock only
      loop = dur;

      final values = [
        for (final v in (_attr(attrs, 'values') ?? '').split(';'))
          if (v.trim().isNotEmpty) v.trim()
      ];
      if (values.length < 2) return null;
      final List<double> times;
      final keyTimes = _attr(attrs, 'keyTimes');
      if (keyTimes == null) {
        times = [for (var i = 0; i < values.length; i++) i / values.length];
      } else {
        final parsed = [
          for (final k in keyTimes.split(';'))
            if (k.trim().isNotEmpty) double.tryParse(k.trim())
        ];
        if (parsed.length != values.length || parsed.contains(null)) {
          return null;
        }
        times = parsed.cast<double>();
        if (times.first != 0) return null;
        for (var i = 1; i < times.length; i++) {
          if (times[i] < times[i - 1] || times[i] > 1) return null;
        }
      }

      // The element it animates is its parent. Only the plain shape is read:
      // the animate is the first thing inside that element's opening tag.
      final before = svg.substring(0, m.start).trimRight();
      if (!before.endsWith('>') || before.endsWith('/>')) return null;
      final tagStart = before.lastIndexOf('<');
      if (tagStart < 0) return null;
      final tag = before.substring(tagStart);
      if (tag.startsWith('</') || tag.startsWith('<!') || tag.startsWith('<?')) {
        return null;
      }
      if (tracks.any((t) => t.tagStart == tagStart)) return null;

      tracks.add(_FlipTrack(
        tagStart: tagStart,
        tagEnd: before.length,
        animStart: m.start,
        animEnd: m.end,
        times: times,
        hidden: [
          for (final v in values)
            v == 'hidden' || v == 'collapse' || v == 'none'
        ],
      ));
    }
    if (tracks.isEmpty || loop == null) return null;

    // Every moment something changes, across all tracks.
    final cuts = <int>{0};
    for (final t in tracks) {
      for (final k in t.times) {
        final at = (k * loop).round();
        if (at < loop) cuts.add(at);
      }
    }
    final order = cuts.toList()..sort();

    final frames = <String>[];
    final starts = <int>[];
    String? lastState;
    for (final at in order) {
      final hidden = [for (final t in tracks) t.hiddenAt(at / loop)];
      final state = hidden.join(',');
      if (state == lastState) continue; // nothing changed at this cut
      lastState = state;
      frames.add(_still(svg, tracks, hidden));
      starts.add(at);
    }
    if (frames.length < 2 || frames.length > _maxFrames) return null;
    for (var i = 0; i < starts.length; i++) {
      final end = i + 1 < starts.length ? starts[i + 1] : loop;
      if (end - starts[i] < _minFrameMicros) return null;
    }
    return SvgFlipbook._(frames, starts, loop);
  }

  static final RegExp _shownAttrs = RegExp(
      '\\s(?:visibility|display)\\s*=\\s*(["\']).*?\\1',
      dotAll: true);

  /// [svg] with every track's animate removed and its element shown or hidden.
  static String _still(String svg, List<_FlipTrack> tracks, List<bool> hidden) {
    // Back to front, so earlier offsets stay valid.
    final idx = [for (var i = 0; i < tracks.length; i++) i]
      ..sort((a, b) => tracks[b].tagStart.compareTo(tracks[a].tagStart));
    var out = svg;
    for (final i in idx) {
      final t = tracks[i];
      out = out.replaceRange(t.animStart, t.animEnd, '');
      var tag = out.substring(t.tagStart, t.tagEnd).replaceAll(_shownAttrs, '');
      if (hidden[i]) {
        tag = '${tag.substring(0, tag.length - 1)}'
            ' visibility="hidden" display="none">';
      }
      out = out.replaceRange(t.tagStart, t.tagEnd, tag);
    }
    return out;
  }
}

class _FlipTrack {
  final int tagStart, tagEnd, animStart, animEnd;
  final List<double> times;
  final List<bool> hidden;

  const _FlipTrack({
    required this.tagStart,
    required this.tagEnd,
    required this.animStart,
    required this.animEnd,
    required this.times,
    required this.hidden,
  });

  /// Discrete: the value of the last key time at or before [t] (0..1).
  bool hiddenAt(double t) {
    var i = 0;
    while (i + 1 < times.length && times[i + 1] <= t + 1e-9) {
      i++;
    }
    return hidden[i];
  }
}

/// Plays an [SvgFlipbook]. Every frame is laid out at once and one is painted,
/// so a switch never waits on a parse. The frame comes from the wall clock, so
/// two copies of the same art (a card and an avatar) flip together. One timer
/// per frame change, no per-frame ticker. Holds on the first frame when the
/// system asks for reduced motion, and does not repaint while its route or tab
/// is not the one showing.
class _SvgFlipbookView extends StatefulWidget {
  final SvgFlipbook book;
  final BoxFit fit;
  final Widget placeholder;

  const _SvgFlipbookView({
    required this.book,
    required this.fit,
    required this.placeholder,
  });

  @override
  State<_SvgFlipbookView> createState() => _SvgFlipbookViewState();
}

class _SvgFlipbookViewState extends State<_SvgFlipbookView> {
  Timer? _timer;
  int _frame = 0;
  bool _still = false;
  bool _active = true;

  static int _now() => DateTime.now().microsecondsSinceEpoch;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    _active = TickerMode.valuesOf(context).enabled;
    _arm();
  }

  @override
  void didUpdateWidget(covariant _SvgFlipbookView old) {
    super.didUpdateWidget(old);
    if (!identical(old.book, widget.book)) _arm();
  }

  void _arm() {
    _timer?.cancel();
    _timer = null;
    if (_still) {
      _frame = 0;
      return;
    }
    final now = _now();
    _frame = widget.book.frameAt(now);
    final wait = widget.book.untilNext(now) + 1000;
    _timer = Timer(Duration(microseconds: wait < 16000 ? 16000 : wait), _tick);
  }

  void _tick() {
    if (!mounted) return;
    if (_active) {
      setState(_arm);
    } else {
      _arm();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frames = widget.book.frames;
    return IndexedStack(
      index: _frame < frames.length ? _frame : 0,
      sizing: StackFit.passthrough,
      children: [
        for (final f in frames)
          SvgPicture.string(f,
              fit: widget.fit, placeholderBuilder: (_) => widget.placeholder),
      ],
    );
  }
}
