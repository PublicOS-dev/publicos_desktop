import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/feeds/emoji_picker_dialog.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/hover_grow.dart';

/// Reader setting: the emoji a double tap on a post adds.
/// Default ❤️. The card reads it synchronously ([doubleTapEmojiSync]) from a
/// static cache that [warm] fills on its first build; the settings sheet
/// writes through [setDoubleTapEmoji]. The `TranslationPrefs` shape.
class ReactionPrefs {
  ReactionPrefs._();

  static const String heart = '❤️';
  static const String kDoubleTapKey = 'reaction_double_tap_emoji';

  static String? _cache;

  /// The cached value, or ❤️ before the first read lands.
  static String get doubleTapEmojiSync => _cache ?? heart;

  static Future<String> doubleTapEmoji() async {
    if (_cache != null) return _cache!;
    try {
      final r = await PublicOSSettings.getSetting(kDoubleTapKey);
      final v = r?.value;
      _cache = (v == null || v.isEmpty) ? heart : v;
    } catch (_) {
      _cache = heart;
    }
    return _cache!;
  }

  /// Fill the cache; cheap after the first call.
  static Future<void> warm() => doubleTapEmoji();

  static Future<void> setDoubleTapEmoji(String emoji) async {
    _cache = emoji;
    try {
      await PublicOSSettings.setSetting(
        kDoubleTapKey,
        Record.asSettings(
          key: kDoubleTapKey,
          value: emoji,
          isSystem: true,
          expiration: DateTime.now().add(const Duration(days: 365)),
        ),
      );
    } catch (_) {}
  }
}

/// A non-emoji button at the end of the pill, after a hairline (desktop's
/// right-click adds share and bookmark). Runs after the pill has closed,
/// like a pick.
class QuickBarAction {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const QuickBarAction({required this.icon, required this.onTap, this.color});
}

/// The reaction quick bar: an intermediate step, so a reaction does not load
/// the full emoji picker. Tapping a react heart grows a glass pill out
/// of it, to the right, holding the reader's four most-used emojis and a `+`:
/// an emoji adds that reaction, `+` opens the full picker, any pointer down
/// outside collapses the pill back into the heart. Add-only by design;
/// removal stays in the who-reacted sheet.
///
/// The four: `emoji_picker_history` top entries first, then
/// [defaultQuickEmojis] fills the gaps until the habit forms. A pill tap
/// counts as a use, so the pill tunes itself.
///
/// Same shell as [GlassContextMenu]: a [PopupRoute] on the root navigator
/// (system back closes the pill first), surfaceDeep @0.92 over a blur,
/// borderSubtle, glassShadow, `Material(transparency)` so the glyphs render.
/// Anchored to the heart's own global rect, never to screen edges; it grows
/// leftward instead when the right edge would cross the screen inset.
class ReactionQuickBar {
  /// Fill for an empty history, in order; the heart takes the first four,
  /// the hold all five.
  static const defaultQuickEmojis = ['❤️', '😂', '👍', '🔥', '🙏'];

  /// Slots out of the heart; the card's hold asks for [holdSlots].
  static const heartSlots = 4;
  static const holdSlots = 5;

  static _QuickBarRoute? _route;

  /// The emojis to show: history first, defaults fill. A local read.
  static Future<List<String>> emojis(int slots) async {
    final out = await mostUsedEmojis(limit: slots);
    for (final d in defaultQuickEmojis) {
      if (out.length >= slots) break;
      if (!out.contains(d)) out.add(d);
    }
    return out;
  }

  /// [anchor] is the heart's own BuildContext (wrap the button in a
  /// `Builder`). [onPick] gets the tapped emoji after the pill has closed;
  /// [onMore] runs for `+`, after the close.
  static Future<void> show(
    BuildContext anchor, {
    required ValueChanged<String> onPick,
    required VoidCallback onMore,
    int slots = heartSlots,
  }) {
    final box = anchor.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return Future.value();
    return _open(
      anchor,
      box.localToGlobal(Offset.zero) & box.size,
      slots: slots,
      onPick: onPick,
      onMore: onMore,
    );
  }

  /// The hold variant: no heart to grow out of, so a 40 px
  /// square at the finger stands in for it; five slots by default.
  static Future<void> showAt(
    BuildContext context,
    Offset at, {
    required ValueChanged<String> onPick,
    required VoidCallback onMore,
    int slots = holdSlots,
    List<QuickBarAction> actions = const [],
    bool reactions = true,
  }) =>
      _open(
        context,
        Rect.fromCenter(center: at, width: 40, height: 40),
        slots: slots,
        onPick: onPick,
        onMore: onMore,
        actions: actions,
        reactions: reactions,
      );

  static Future<void> _open(
    BuildContext anchor,
    Rect rect, {
    required int slots,
    required ValueChanged<String> onPick,
    required VoidCallback onMore,
    List<QuickBarAction> actions = const [],
    bool reactions = true,
  }) async {
    hide();
    if (!reactions && actions.isEmpty) return;
    final emojis =
        reactions ? await ReactionQuickBar.emojis(slots) : const <String>[];
    if (!anchor.mounted) return;
    HapticFeedback.selectionClick();
    final route = _QuickBarRoute(
      anchor: rect,
      emojis: emojis,
      onPick: (e) {
        recordEmojiUse(e);
        onPick(e);
      },
      onMore: onMore,
      actions: actions,
      reactions: reactions,
    );
    _route = route;
    Navigator.of(anchor, rootNavigator: true).push(route).whenComplete(() {
      if (identical(_route, route)) _route = null;
    });
  }

  /// Removes the pill at once (no close animation) if one is up.
  static void hide() {
    final route = _route;
    _route = null;
    if (route != null && route.isActive) route.navigator?.removeRoute(route);
  }
}

class _QuickBarRoute extends PopupRoute<void> {
  final Rect anchor;
  final List<String> emojis;
  final ValueChanged<String> onPick;
  final VoidCallback onMore;
  final List<QuickBarAction> actions;
  final bool reactions;

  _QuickBarRoute({
    required this.anchor,
    required this.emojis,
    required this.onPick,
    required this.onMore,
    this.actions = const [],
    this.reactions = true,
  });

  // The pill animates itself and owns its barrier.
  @override
  Color? get barrierColor => null;
  @override
  bool get barrierDismissible => false;
  @override
  String? get barrierLabel => null;
  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return _QuickBarOverlay(
      anchor: anchor,
      emojis: emojis,
      onPick: onPick,
      onMore: onMore,
      actions: actions,
      reactions: reactions,
      onClosed: () {
        if (isActive) navigator?.removeRoute(this);
      },
    );
  }
}

class _QuickBarOverlay extends StatefulWidget {
  final Rect anchor;
  final List<String> emojis;
  final ValueChanged<String> onPick;
  final VoidCallback onMore;
  final VoidCallback onClosed;
  final List<QuickBarAction> actions;
  final bool reactions;

  const _QuickBarOverlay({
    required this.anchor,
    required this.emojis,
    required this.onPick,
    required this.onMore,
    required this.onClosed,
    this.actions = const [],
    this.reactions = true,
  });

  @override
  State<_QuickBarOverlay> createState() => _QuickBarOverlayState();
}

class _QuickBarOverlayState extends State<_QuickBarOverlay>
    with SingleTickerProviderStateMixin {
  static const double _cell = 40;
  static const double _height = 44;
  static const double _hPad = 6;
  static const double _screenInset = 12;
  static const double _dividerW = 13;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    reverseDuration: const Duration(milliseconds: 140),
  );
  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);

  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _dismiss([VoidCallback? then]) {
    if (_closing) return;
    _closing = true;
    _anim.reverse().then((_) {
      widget.onClosed();
      then?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final screen = MediaQuery.sizeOf(context);
    // Padding, the cells, and the 1 px ring on each side: the ring lives
    // INSIDE a sized box, so without its 2 px the row overflows by exactly
    // that.
    // Cells: the emojis, the `+` (when reacting), the actions; plus the
    // hairline between the two groups when both are there.
    final cells = widget.emojis.length +
        (widget.reactions ? 1 : 0) +
        widget.actions.length;
    final divider =
        widget.reactions && widget.actions.isNotEmpty ? _dividerW : 0.0;
    final width = _hPad * 2 + _cell * cells + divider + 2;

    // Grow out of the heart to the right; mirror when that would cross the
    // screen inset. The first cell sits where the heart is either way.
    final a = widget.anchor;
    final growRight = a.left - 4 + width <= screen.width - _screenInset;
    final left = growRight
        ? (a.left - 4).clamp(_screenInset, screen.width - width - _screenInset)
        : (a.right + 4 - width)
            .clamp(_screenInset, screen.width - width - _screenInset);
    final top = (a.center.dy - _height / 2)
        .clamp(_screenInset, screen.height - _height - _screenInset);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _dismiss();
      },
      child: Stack(
        children: [
          // Any pointer down outside: collapse (a tap, or the start of a
          // scroll; the list underneath takes the next one).
          Positioned.fill(
            child: Listener(
              onPointerDown: (_) => _dismiss(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: width,
            height: _height,
            child: AnimatedBuilder(
              animation: _curve,
              builder: (_, child) => ClipRect(
                child: Align(
                  alignment:
                      growRight ? Alignment.centerLeft : Alignment.centerRight,
                  widthFactor: _curve.value.clamp(0.0, 1.0),
                  child: Opacity(
                    opacity: _curve.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: SizedBox(
                  width: width,
                  height: _height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_height / 2),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: tokens.surfaceDeep.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(_height / 2),
                          border: Border.all(color: tokens.borderSubtle),
                          boxShadow: [
                            BoxShadow(
                              color: tokens.glassShadow,
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: _hPad),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            for (final e in widget.emojis) _emojiCell(e),
                            if (widget.reactions) _moreCell(tokens),
                            if (divider > 0)
                              Container(
                                width: 1,
                                height: 20,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: (_dividerW - 1) / 2),
                                color: tokens.borderSubtle,
                              ),
                            for (final a in widget.actions)
                              _actionCell(tokens, a),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emojiCell(String emoji) {
    return InkResponse(
      onTap: () => _dismiss(() => widget.onPick(emoji)),
      radius: _cell / 2,
      child: SizedBox(
        width: _cell,
        height: _height,
        child: Center(
          // height 1.0: the line box is the glyph box, so Center puts the
          // emoji's own middle on the pill's middle, the heart's centre line.
          // DESKTOP DELTA: grows 4 px under the pointer.
          child: HoverGrow(
            size: 22,
            child: Text(
              emoji,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, height: 1.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionCell(GlassTokens tokens, QuickBarAction a) {
    return InkResponse(
      onTap: () => _dismiss(a.onTap),
      radius: _cell / 2,
      child: SizedBox(
        width: _cell,
        height: _height,
          child: HoverGrow(
            size: 20,
            child: Icon(a.icon, size: 20, color: a.color ?? tokens.textDim),
          ),
      ),
    );
  }

  Widget _moreCell(GlassTokens tokens) {
    return InkResponse(
      onTap: () => _dismiss(widget.onMore),
      radius: _cell / 2,
      child: SizedBox(
        width: _cell,
        height: _height,
        // A bare glyph, the emojis' size, with no disc around it.
        // DESKTOP DELTA: grows on hover like the emojis.
        child: HoverGrow(
          size: 22,
          child: Icon(Icons.add_rounded, size: 22, color: tokens.starkWhite),
        ),
      ),
    );
  }
}
