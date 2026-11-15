import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart'
    show PointerScrollEvent, PointerSignalEvent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show HardwareKeyboard, LogicalKeyboardKey;

import '../theme/glass_tokens.dart';

/// Pill-shaped filter/action chip — publicos_client's `components/explorer/
/// chip_bar.dart` ported verbatim (only the theme import changed). Used for the
/// desktop contacts filters (Personal / Orgs / sort).
///
/// - Inactive: faint `glassFill`, dim text, **no hairline**.
/// - Active: elevated-surface fill, stark-white bolder text, **no hairline**.
/// - [accentColor] overrides the foreground with a tinted variant.
/// - [count] renders a small badge after the label — **the one hairline left**,
///   see [borderless].
/// - [trailing] is appended at the end of the row.
///
/// **Borderless is the default**, so the shell's chip bars (contacts,
/// messages, apps, wallets) match. Pass `borderless: false` to put a hairline
/// back on one bar.
class ExplorerChip extends StatelessWidget {
  final String label;

  /// The glyph before the label. Optional: a chip whose
  /// mark is a WIDGET rather than an [IconData] — a chain's brand SVG, say
  /// — passes [leading] instead, and passing both is a no-op for this one.
  final IconData? icon;

  /// Rendered in place of [icon] when given. Mirrors [trailing].
  final Widget? leading;
  final bool active;
  final int? count;
  final Color? accentColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Fill-only chip, no hairline — the default (the shell's borderless
  /// direction).
  ///
  /// ⚠ The [count] badge keeps its own hairline either way, and that is not an
  /// oversight: on an inactive borderless chip the badge's `glassFill` sits on
  /// the chip's `glassFill`, so the ring is the only thing that makes the count
  /// visible at all. Removing it would delete the badge, not its border.
  final bool borderless;

  const ExplorerChip({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    required this.active,
    this.count,
    this.accentColor,
    this.trailing,
    this.onTap,
    this.borderless = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final fg = accentColor ?? (active ? tokens.starkWhite : tokens.textDim);
    final borderColor =
        accentColor?.withValues(alpha: 0.5) ??
        (active ? tokens.borderMedium : tokens.borderSubtle);
    // Fill-only by default: an inactive chip gets a faint glass fill so it
    // still reads as a chip once the hairline is gone. Tone steps carry the
    // edge, which is the whole borderless argument.
    final fill = active
        ? tokens.surfaceElevated
        : (borderless ? tokens.glassFill : Colors.transparent);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: fill,
          border: borderless ? null : Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: fg,
                fontSize: 12,
                height: 1.3,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: tokens.glassFill,
                  border: Border.all(color: tokens.borderSubtle, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: fg,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: 6), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Horizontal scroller with leading/trailing fade gradients hinting at
/// off-screen chips. Ported verbatim from the client.
class ExplorerChipBar extends StatefulWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  final double height;
  final double fadeWidth;
  final Color? fadeColor;

  const ExplorerChipBar({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.height = 48,
    this.fadeWidth = 28,
    this.fadeColor,
  });

  @override
  State<ExplorerChipBar> createState() => _ExplorerChipBarState();
}

class _ExplorerChipBarState extends State<ExplorerChipBar> {
  final ScrollController _ctrl = ScrollController();
  bool _showStart = false;
  bool _showEnd = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_recompute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recompute());
  }

  @override
  void dispose() {
    _ctrl.removeListener(_recompute);
    _ctrl.dispose();
    super.dispose();
  }

  void _recompute() {
    if (!_ctrl.hasClients) return;
    final p = _ctrl.position;
    final showStart = p.pixels > 0.5;
    final showEnd = p.pixels < p.maxScrollExtent - 0.5;
    if (showStart != _showStart || showEnd != _showEnd) {
      setState(() {
        _showStart = showStart;
        _showEnd = showEnd;
      });
    }
  }

  /// **Vertical wheel over the bar scrolls the chips horizontally.** Wheel
  /// down → the bar moves toward its right end; up → back.
  ///
  /// ── WHY THIS IS NEEDED AT ALL ────────────────────────────────────────────
  /// `Scrollable` maps wheel input onto its own axis and reads **only that
  /// axis's delta** (`_pointerSignalEventDelta`: `Axis.horizontal` →
  /// `scrollDelta.dx`). A physical mouse wheel emits **`dy` only**, so a
  /// horizontal `ListView` is *not* wheel-scrollable in Flutter — verified in
  /// 3.32.4's `scrollable.dart`. Without this, chips past the pane edge are
  /// reachable only by dragging them or by holding Shift (which flips the
  /// axis via `ScrollBehavior.pointerAxisModifiers`, default the two Shifts).
  ///
  /// ── THE THREE GUARDS, each preventing a double-scroll or a stolen event ──
  /// A raw [Listener] does **not** consume a pointer signal, and `Scrollable`
  /// registers for the same event through the resolver — so anything the
  /// `ListView` can already handle itself must be left alone:
  ///
  /// 1. **`dx != 0` → return.** A trackpad delivers both axes; the ListView
  ///    consumes the `dx`. Translating `dy` on top would move the bar twice.
  /// 2. **Shift held → return.** `Scrollable` has already flipped its axis and
  ///    is reading this very `dy`. Same double-scroll, different cause.
  /// 3. **Nothing to scroll → return.** A bar whose chips fit leaves the event
  ///    untouched, so an ancestor scrollable still gets the wheel rather than
  ///    having it silently swallowed by a bar that could not use it.
  ///
  /// Movement goes through [ScrollPosition.pointerScroll] — the same method
  /// `Scrollable` itself calls for wheel input — so clamping, scroll direction,
  /// notifications and the ballistic settle are Flutter's, not ours. That is
  /// also what keeps the fade gradients honest: it notifies, so [_recompute]
  /// runs off the existing controller listener.
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_ctrl.hasClients) return;

    final double dy = event.scrollDelta.dy;
    if (dy == 0 || event.scrollDelta.dx != 0) return; // guard 1

    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    if (pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight)) {
      return; // guard 2
    }

    if (_ctrl.position.maxScrollExtent <= 0) return; // guard 3

    _ctrl.position.pointerScroll(dy);
  }

  @override
  Widget build(BuildContext context) {
    final fadeColor = widget.fadeColor ?? GlassTokens.of(context).surfaceDeep;
    final transparent = fadeColor.withValues(alpha: 0);
    return SizedBox(
      height: widget.height,
      // The wheel handler wraps the WHOLE bar, fades included, so the chips
      // respond anywhere over the strip rather than only over a chip.
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _recompute());
            return false;
          },
          child: Stack(
            children: [
              // DELTA(desktop): Flutter's default ScrollBehavior only lets
              // touch/stylus DRAG a scrollable — with a mouse, chips past the
              // pane edge would be unreachable. Allow mouse/trackpad drag on
              // this bar.
              //
              // ⚠ The wheel does NOT scroll this bar through the normal
              // pointer-scroll path; see [_onPointerSignal] for why and for
              // the handler that makes it work.
              ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: ListView(
                  controller: _ctrl,
                  scrollDirection: Axis.horizontal,
                  padding: widget.padding,
                  children: widget.children,
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _showStart ? 1 : 0,
                    child: Container(
                      width: widget.fadeWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [fadeColor, transparent],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _showEnd ? 1 : 0,
                    child: Container(
                      width: widget.fadeWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [fadeColor, transparent],
                        ),
                      ),
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
}
