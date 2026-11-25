/// Coach marks — a spotlight over one live control, with everything else
/// scrimmed and untappable.
///
/// ## Why this lives in the root Overlay
///
/// The doing-tour's inbox step walks four beats, and **two of them are inside a
/// modal bottom sheet** (Generate, then the SIM icon on the key that appears).
/// A coach painted as a sibling widget on the page underneath would be *below*
/// that sheet's route and could not reach them. So the coach is an
/// [OverlayEntry] inserted into the **root** overlay, which paints above modal
/// routes — and the sheet stays an ordinary modal route, keeping its own
/// `Navigator.pop` working, which is the thing that breaks if you try to host
/// the sheet inside the page's own `Stack` instead.
///
/// ## Why the scrim is painted once but absorbed in four pieces
///
/// The dim is a single [CustomPaint] with a hole cut by `Path.combine`, because
/// that gives one smooth surface with no seams. But **hit-testing cannot use
/// that path** — so the absorbing layer is four plain boxes around the hole,
/// leaving the target's own rect covered by nothing at all. A tap there is not
/// intercepted and forwarded; it simply falls through to the real control
/// underneath, which is why the real button's real `onPressed` runs and the
/// coach never has to know what any beat actually does.
///
/// ## Measuring
///
/// Targets are found by [GlobalKey] and measured **late** — after the frame
/// that built them. A sheet animating up, an icon font reflowing a row, a list
/// settling: all of them move a rect after the widget exists. [CoachOverlay]
/// re-measures on every frame while it is showing, which is cheap (one
/// `localToGlobal` per frame) and immune to all of it.
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Where the speech bubble sits relative to the spotlight.
enum CoachSide {
  /// Bubble below the target, tail pointing up at it.
  below,

  /// Bubble above the target, tail pointing down at it.
  above,
}

/// One beat of a coach sequence: what to spotlight, and what to say about it.
class CoachMark {
  /// The control to cut out of the scrim. Attach the same key to the widget.
  final GlobalKey targetKey;

  /// The line in the bubble. Supports `**bold**`, like the tour's pages.
  final String text;

  /// Which side of the target the bubble sits on.
  final CoachSide side;

  /// Extra breathing room around the target's rect, in logical pixels.
  final double padding;

  /// A second control to put in the same hole: the spotlight is the union of
  /// both rects. For a beat that talks about two neighbours at once (the
  /// keychain's title and its session key). Ignored while it is not laid out.
  final GlobalKey? alsoKey;

  /// Set on a beat that only EXPLAINS. Nothing is tappable then, the hole
  /// included, and a tap anywhere calls this. Null on a doing beat, which
  /// advances when the real control's real action lands.
  final VoidCallback? onContinue;

  /// The small "tap to continue" line under [text] on an explaining beat.
  final String? continueLabel;

  const CoachMark({
    required this.targetKey,
    required this.text,
    this.side = CoachSide.below,
    this.padding = 6,
    this.alsoKey,
    this.onContinue,
    this.continueLabel,
  });
}

/// Drives a coach sequence and owns its [OverlayEntry].
///
/// The controller is deliberately dumb about *what* each beat does: it shows a
/// mark, and the caller advances it when the real world says the beat happened
/// (a sheet returned, a key appeared, a registration landed). Advancing on the
/// tap itself would be a lie — the same "a step completes on the RETURN, not on
/// the tap" rule the tour's own gates follow.
class CoachController extends ChangeNotifier {
  CoachMark? _current;
  OverlayEntry? _entry;
  OverlayState? _overlay;

  CoachMark? get current => _current;
  bool get isShowing => _current != null;

  /// Show [mark], inserting the overlay entry on first use.
  ///
  /// [context] only has to be under a [Navigator]; the entry goes into the root
  /// overlay regardless, so it outranks any modal route opened afterwards.
  void show(BuildContext context, CoachMark mark) {
    _current = mark;
    if (_entry == null) {
      _overlay = Overlay.of(context, rootOverlay: true);
      _entry = OverlayEntry(
        builder: (_) => CoachOverlay(controller: this),
      );
      _overlay!.insert(_entry!);
    }
    notifyListeners();
  }

  /// Take the spotlight down without tearing the entry out — the sequence may
  /// have another beat coming once the current one resolves.
  void hide() {
    _current = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    _overlay = null;
    super.dispose();
  }
}

/// The scrim, the spotlight and the bubble. Rebuilt every frame while a mark is
/// showing so the hole tracks a target that is still moving.
class CoachOverlay extends StatefulWidget {
  final CoachController controller;

  const CoachOverlay({super.key, required this.controller});

  @override
  State<CoachOverlay> createState() => _CoachOverlayState();
}

/// **`TickerProviderStateMixin`, not the `Single` one.** This state drives TWO
/// tickers and they are deliberately separate concerns: `_pulse` animates the
/// ring, `_ticker` re-measures the target's rect. The single-ticker mixin
/// throws on the second one — *"multiple tickers were created"* — and it throws
/// at build time, so the whole stage comes up red rather than degrading.
class _CoachOverlayState extends State<CoachOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;

  /// Ticks once per frame while a mark is up, so the measured rect stays true
  /// through sheet animations and layout settling.
  late final Ticker _ticker;
  Rect? _rect;

  /// The route the current target lives in, captured once per mark.
  ///
  /// Looked up through `ModalRoute.of` — an inherited lookup — so it is done
  /// **once when the target first appears**, not every frame. Afterwards
  /// [ModalRoute.isCurrent] is a plain getter and costs nothing to poll.
  ModalRoute<dynamic>? _targetRoute;

  /// Whether something has been pushed on top of the target's route.
  ///
  /// **This is what lets a beat get out of the way.** The overlay sits in the
  /// ROOT overlay, inserted on top — which is the whole reason it can reach
  /// controls inside a modal sheet — but `Navigator.push` inserts a new route's
  /// entries *above the previous route's*, not above everything. So a dialog
  /// opened from the spotlighted button lands **underneath** this overlay, and
  /// the absorbers then swallow every tap meant for it: the coach goes on
  /// insisting its button is the only live thing on screen while the actual
  /// interaction has moved somewhere it is covering.
  ///
  /// Without this, the "name your key" dialog opened from Generate could not
  /// be typed in or confirmed. Standing down whenever the target's route is
  /// not on top covers every dialog in the sequence at once: the label prompt,
  /// the mnemonic reveal, and beat 4's register dialog.
  bool _covered = false;

  /// Drives the glide from one beat's target to the next.
  ///
  /// **Only a change of MARK animates.** The measured rect also moves for
  /// boring reasons — a list scrolls, a sheet settles — and easing those would
  /// make the spotlight lag behind a target the user can see. So a moving
  /// target is tracked live, frame by frame, and only a new beat travels.
  late final AnimationController _move;

  /// Where the glide starts: the rect we were actually PAINTING when the mark
  /// changed, not the raw measurement. Starting from the measurement would
  /// jump if a beat arrived while an earlier glide was still running.
  Rect? _fromRect;

  /// The side the bubble was on when the glide started.
  ///
  /// Beats do not all sit on the same side — beat 1 points down at a chip near
  /// the top, beats 2 and 3 point up at controls inside a sheet — and a bubble
  /// that adopts the new side on the first frame hops *backwards* over its own
  /// target before it starts travelling. Holding the old side until the move is
  /// half done turns that hop into the bubble swinging round the target as it
  /// goes.
  CoachSide? _fromSide;

  /// The last rect we drew. Kept so the overlay can fade out from where it was
  /// rather than blinking off the moment its target goes away.
  Rect? _painted;

  static final Animatable<double> _glide =
      CurveTween(curve: Curves.easeInOutCubic);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _move = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: 1,
    )..addListener(_onMove);
    _ticker = createTicker((_) => _measure());
    _ticker.start();
    widget.controller.addListener(_onController);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    _ticker.dispose();
    _move.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _onMove() {
    if (mounted) setState(() {});
  }

  void _onController() {
    // A new mark means a new target, which may live in a different route.
    _targetRoute = null;
    // Glide from wherever the spotlight is RIGHT NOW to wherever the new beat
    // puts it. With no previous position there is nothing to travel from, so
    // the first beat simply appears.
    final from = _painted;
    if (widget.controller.current != null && from != null) {
      _fromRect = from;
      _fromSide = _shownSide;
      _move.forward(from: 0);
    } else {
      _fromRect = null;
      _fromSide = null;
      _move.value = 1;
    }
    if (mounted) setState(() {});
  }

  /// The rect to paint this frame — the glide, resolved.
  ///
  /// The middle branch is the one that matters: when a beat changes, the new
  /// target usually is not laid out yet (it may be inside a sheet that is still
  /// opening), so the measurement is null for a frame or two. Holding the old
  /// position through that gap is what turns "flash out, flash in" into one
  /// continuous move.
  Rect? get _paintRect {
    final to = _rect;
    final from = _fromRect;
    if (to != null) {
      if (from == null || _move.value >= 1) return to;
      return Rect.lerp(from, to, _glide.transform(_move.value));
    }
    // No live target. Hold the previous position ONLY while the glide is
    // actually running — a bounded 380ms — so a beat whose target is still
    // being laid out travels instead of blinking.
    //
    // ⚠ **This must not be an unconditional `from ?? _painted`.**
    // `_measure` reports a target it cannot find as `rect = null, covered =
    // false` — and an unconditional fallback turns that "draw nothing" into
    // "draw at the last known place, visibly", so the spotlight and its bubble
    // sit on top of any dialog that unmounts the target. The overlay's whole
    // contract is that it stands down for anything pushed above it; an
    // unbounded memory of its last position quietly breaks that.
    if (from != null && _move.isAnimating) return from;
    return null;
  }

  /// Which side the bubble sits on this frame. The old side is held while the
  /// spotlight is parked at the previous target and through the first half of
  /// the travel; the new one takes over as it arrives.
  CoachSide _shownSide = CoachSide.below;

  CoachSide _sideFor(CoachMark? mark) {
    final old = _fromSide;
    if (old != null && (_rect == null || _move.value < 0.5)) return old;
    return mark?.side ?? old ?? CoachSide.below;
  }

  /// Read the target's rect in global coordinates. A target that is not on
  /// screen yet (or has just left) simply yields null and the overlay paints
  /// nothing — no flash of a full-screen scrim with no hole in it.
  void _measure() {
    final mark = widget.controller.current;
    if (mark == null) {
      _apply(null, false);
      return;
    }
    final ctx = mark.targetKey.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (ctx == null || box == null || !box.hasSize) {
      _apply(null, false);
      return;
    }

    _targetRoute ??= ModalRoute.of(ctx);
    final covered = !(_targetRoute?.isCurrent ?? true);

    final origin = box.localToGlobal(Offset.zero);
    var rect = origin & box.size;
    final alsoBox =
        mark.alsoKey?.currentContext?.findRenderObject() as RenderBox?;
    if (alsoBox != null && alsoBox.hasSize) {
      rect = rect.expandToInclude(
          alsoBox.localToGlobal(Offset.zero) & alsoBox.size);
    }
    _apply(rect.inflate(mark.padding), covered);
  }

  /// One setState for both facts, and only when one of them actually moved —
  /// this runs every frame.
  void _apply(Rect? rect, bool covered) {
    if (!mounted || (_rect == rect && _covered == covered)) return;
    setState(() {
      _rect = rect;
      _covered = covered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mark = widget.controller.current;
    final rect = _paintRect;

    // Nothing has ever been measured — there is no position to fade from, so
    // there is genuinely nothing to draw.
    if (rect == null) return const SizedBox.shrink();
    _painted = rect;

    // ── Covered, and hidden, FADE rather than cut ──
    //
    // The invariant is the whole reason this is opacity and not a
    // conditional: **a covered coach must not hit-test.** Returning
    // `SizedBox.shrink()` would satisfy that by not existing — at the cost of
    // a hard cut every time a dialog opened and closed, which makes the
    // sequence feel chopped. `IgnorePointer` satisfies it just as
    // completely: with `ignoring` true not one of the four absorbers can take a
    // tap meant for whatever was pushed on top. What we gain is 140ms of fade
    // instead of a blink.
    //
    // Out is quicker than in, deliberately: getting out of the user's way
    // should feel immediate, coming back should feel like it settled.
    final visible = mark != null && !_covered;

    final tokens = GlassTokens.of(context);
    final screen = MediaQuery.sizeOf(context);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: Duration(milliseconds: visible ? 220 : 140),
        curve: visible ? Curves.easeOut : Curves.easeIn,
        child: _paint(context, mark, rect, rrect, screen, tokens),
      ),
    );
  }

  /// The scrim, the absorbers, the ring and the bubble at [rect].
  ///
  /// [mark] may be null for the frames where a finished sequence is still
  /// fading out — the bubble is simply dropped, and the spotlight fades from
  /// where it last was.
  Widget _paint(
    BuildContext context,
    CoachMark? mark,
    Rect rect,
    RRect rrect,
    Size screen,
    GlassTokens tokens,
  ) {
    return Stack(
      children: [
        // The dim, painted as one surface with the hole cut out of it.
        IgnorePointer(
          child: CustomPaint(
            size: screen,
            painter: _ScrimPainter(hole: rrect),
          ),
        ),

        // The absorbing layer: four boxes around the hole. The hole itself is
        // covered by none of them, so the tap lands on the real control.
        ..._absorbers(screen, rect, mark?.onContinue),

        // The pulsing ring on the target.
        Positioned.fromRect(
          rect: rect,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = _pulse.value;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: tokens.fallbackAccent
                          .withValues(alpha: 0.55 + 0.45 * t),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.fallbackAccent
                            .withValues(alpha: 0.10 + 0.25 * t),
                        blurRadius: 8 + 14 * t,
                        spreadRadius: 1 + 2 * t,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        if (mark != null)
          _bubble(context, mark, _sideFor(mark), rect, screen, tokens),
      ],
    );
  }

  /// Four boxes around the hole. Written as explicit rects rather than a
  /// clever clip because hit-testing has to agree with them exactly.
  ///
  /// On an explaining beat ([onContinue] set) a fifth box covers the hole too,
  /// and every box calls [onContinue]: the beat has nothing to do, only to
  /// read, so a tap anywhere moves on.
  List<Widget> _absorbers(Size screen, Rect hole, VoidCallback? onContinue) {
    Widget box(double l, double t, double w, double h) => Positioned(
          left: l,
          top: t,
          width: w < 0 ? 0 : w,
          height: h < 0 ? 0 : h,
          // Swallows the tap and does nothing — the point is that nothing
          // outside the spotlight can be reached, not that taps are counted.
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onContinue ?? () {},
            child: const SizedBox.expand(),
          ),
        );
    return [
      box(0, 0, screen.width, hole.top),
      box(0, hole.bottom, screen.width, screen.height - hole.bottom),
      box(0, hole.top, hole.left, hole.height),
      box(hole.right, hole.top, screen.width - hole.right, hole.height),
      if (onContinue != null) box(hole.left, hole.top, hole.width, hole.height),
    ];
  }

  /// The speech bubble, clamped into the screen and tailed at the target.
  Widget _bubble(BuildContext context, CoachMark mark, CoachSide side,
      Rect hole, Size screen, GlassTokens tokens) {
    const margin = 16.0;
    const gap = 14.0;
    final below = side == CoachSide.below;
    // Remembered for the next glide's starting side. Assigned during build
    // rather than in a callback because it is a cache of what was drawn, not
    // state anything rebuilds on.
    _shownSide = side;

    return Positioned(
      left: margin,
      right: margin,
      top: below ? hole.bottom + gap : null,
      bottom: below ? null : screen.height - hole.top + gap,
      child: IgnorePointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: tokens.surfaceDeep,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: tokens.borderMedium),
                boxShadow: [
                  BoxShadow(
                    color: tokens.glassShadow,
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              // `Material`, purely so the text is not underlined in yellow.
              //
              // This overlay is an `OverlayEntry`, which sits OUTSIDE the app's
              // Material tree, so `Text` here inherits `DefaultTextStyle
              // .fallback()` — and that fallback is the debug style: a double
              // underline in `0xFFFFFF00`. An explicit `style:` does not save
              // you, because `TextStyle` MERGES with the inherited one and
              // decoration is not a field this style sets. Hence both the
              // wrapper and the explicit `TextDecoration.none` below.
              child: Material(
                type: MaterialType.transparency,
                // The bubble travels with the hole, so the only thing left to
                // snap was the sentence inside it. Cross-fading it keyed on the
                // text means a beat that reuses the same line — beat 2 skipped
                // because a key already exists, so 2 and 3 point at the same
                // control — does not blink for no reason.
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  // Sized by the incoming child rather than the outgoing one,
                  // so a longer line does not clip while it arrives.
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topLeft,
                    children: [...previous, if (current != null) current],
                  ),
                  child: Column(
                    key: ValueKey(mark.text),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(children: coachBoldSpans(mark.text, tokens)),
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 14,
                          height: 1.5,
                          color: tokens.starkWhite,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      if (mark.continueLabel != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          mark.continueLabel!,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 12,
                            color: tokens.textDim,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `**bold**` → a bold span, the same keyword the tour's page bodies use, so a
/// coach line and a page body are written the same way.
List<InlineSpan> coachBoldSpans(String source, GlassTokens tokens) {
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'\*\*(.+?)\*\*');
  var index = 0;
  for (final match in pattern.allMatches(source)) {
    if (match.start > index) {
      spans.add(TextSpan(text: source.substring(index, match.start)));
    }
    spans.add(TextSpan(
      text: match.group(1),
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: tokens.starkWhite,
      ),
    ));
    index = match.end;
  }
  if (index < source.length) {
    spans.add(TextSpan(text: source.substring(index)));
  }
  return spans;
}

class _ScrimPainter extends CustomPainter {
  final RRect hole;

  const _ScrimPainter({required this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final cut = Path()..addRRect(hole);
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, cut),
      Paint()..color = const Color(0xB30A0614),
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.hole != hole;
}
