import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/glass_tokens.dart';

/// One row of a [GlassContextMenu]. [destructive] paints icon + label with
/// `colorScheme.error` (the dialog destructive tier); everything else renders
/// starkWhite label / textDim icon.
class GlassContextMenuItem {
  final IconData? icon;

  /// For a glyph that isn't an [IconData] (e.g. the SVG `SendCoinsIcon`):
  /// paints it at the row's icon size + color. Exactly one of [icon] /
  /// [iconBuilder].
  final Widget Function(double size, Color color)? iconBuilder;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const GlassContextMenuItem({
    this.icon,
    this.iconBuilder,
    required this.label,
    required this.onTap,
    this.destructive = false,
  }) : assert((icon == null) != (iconBuilder == null));
}

/// The canonical long-press quick-options menu — a small glass-dark floating
/// panel anchored at the press point. For 2–4 quick actions on a row/tile that
/// don't justify a bottom sheet (refresh, share, remove…).
///
/// Style: surfaceDeep @0.92 over a backdrop blur, r12, borderSubtle, 46px rows,
/// hairline dividers. Pops with a 160ms scale+fade anchored toward the press
/// point; backdrop tap, any item, or the system back dismisses. Haptic
/// (mediumImpact) fires here so call sites don't each roll their own.
///
/// It is a [PopupRoute] on the root navigator, not an
/// overlay entry: the system back closes the menu first, and only the next
/// back reaches the host route's own protocol (the browser's three tiers).
/// An overlay entry would outlive the route that opened it — back would pop
/// the Browser and leave the "…" menu floating over the Explorer. The app's
/// route observer is a `RouteObserver<PageRoute>`, so this route never counts
/// as "covering" for the inline video tiles.
class GlassContextMenu {
  static _GlassContextMenuRoute? _route;

  /// [frosted]: the browser action pills' chrome instead of the surfaceDeep
  /// panel: a 10-sigma blur over a 30% black wash, radius 8, white glyphs
  /// (the profile "…" menu: the same background as the icon buttons).
  static void show(
    BuildContext context, {
    required Offset position,
    required List<GlassContextMenuItem> items,
    bool frosted = false,
  }) {
    hide();
    if (items.isEmpty) return;
    HapticFeedback.mediumImpact();
    final route = _GlassContextMenuRoute(
      position: position,
      items: items,
      frosted: frosted,
    );
    _route = route;
    Navigator.of(context, rootNavigator: true).push(route).whenComplete(() {
      if (identical(_route, route)) _route = null;
    });
  }

  /// Removes the menu at once (no close animation) if one is up.
  static void hide() {
    final route = _route;
    _route = null;
    if (route != null && route.isActive) route.navigator?.removeRoute(route);
  }
}

class _GlassContextMenuRoute extends PopupRoute<void> {
  final Offset position;
  final List<GlassContextMenuItem> items;
  final bool frosted;

  _GlassContextMenuRoute({
    required this.position,
    required this.items,
    required this.frosted,
  });

  // The panel animates itself (scale + fade anchored at the press point) and
  // owns its backdrop tap, so the route adds no barrier and no transition.
  @override
  Color? get barrierColor => null;
  @override
  bool get barrierDismissible => false;
  @override
  String? get barrierLabel => null;
  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _GlassContextMenuOverlay(
      position: position,
      items: items,
      frosted: frosted,
      // After the close animation: drop the route without a second pop
      // animation or pop callbacks (a plain pop would re-enter the PopScope).
      onClosed: () {
        if (isActive) navigator?.removeRoute(this);
      },
    );
  }
}

class _GlassContextMenuOverlay extends StatefulWidget {
  final Offset position;
  final List<GlassContextMenuItem> items;
  final bool frosted;

  /// Removes the route — called after the close animation finishes.
  final VoidCallback onClosed;

  const _GlassContextMenuOverlay({
    required this.position,
    required this.items,
    required this.onClosed,
    this.frosted = false,
  });

  @override
  State<_GlassContextMenuOverlay> createState() =>
      _GlassContextMenuOverlayState();
}

class _GlassContextMenuOverlayState extends State<_GlassContextMenuOverlay>
    with SingleTickerProviderStateMixin {
  static const double _width = 210;
  static const double _rowHeight = 46;
  static const double _screenInset = 12;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    reverseDuration: const Duration(milliseconds: 120),
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _anim,
    curve: Curves.easeOutCubic,
  );

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
    final errorColor = Theme.of(context).colorScheme.error;
    final screen = MediaQuery.sizeOf(context);

    final menuHeight =
        widget.items.length * _rowHeight + (widget.items.length - 1);

    // Prefer just below the press point (so the finger isn't covering the
    // menu), centered on it horizontally; flip above when it would overflow
    // the bottom, and clamp to the screen either way.
    final left = (widget.position.dx - _width / 2).clamp(
      _screenInset,
      screen.width - _width - _screenInset,
    );
    final below = widget.position.dy + 12;
    final flip = below + menuHeight > screen.height - _screenInset;
    final top = (flip ? widget.position.dy - menuHeight - 12 : below).clamp(
      _screenInset,
      screen.height - menuHeight - _screenInset,
    );

    // Scale anchors toward the press point so the pop reads as growing out of
    // the touched tile, not out of the screen center.
    final anchor = Alignment(
      ((widget.position.dx - left) / _width * 2 - 1).clamp(-1.0, 1.0),
      flip ? 1 : -1,
    );

    // System back: close this menu (animated) and nothing else — the host
    // route's back protocol only runs on the NEXT back.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _dismiss();
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _dismiss,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: _width,
            child: AnimatedBuilder(
              animation: _curve,
              builder: (_, child) => Transform.scale(
                scale: 0.92 + 0.08 * _curve.value,
                alignment: anchor,
                child: Opacity(opacity: _curve.value, child: child),
              ),
              // A PopupRoute adds no Material of its own — without this, Text
              // falls back to the yellow double-underline style.
              child: Material(
                type: MaterialType.transparency,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.frosted ? 8 : 12),
                  child: BackdropFilter(
                    filter: widget.frosted
                        ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                        : ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: widget.frosted
                          ? BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.30),
                              borderRadius: BorderRadius.circular(8),
                            )
                          : BoxDecoration(
                              color: tokens.surfaceDeep.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: tokens.borderSubtle),
                              boxShadow: [
                                BoxShadow(
                                  color: tokens.glassShadow,
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < widget.items.length; i++) ...[
                            if (i > 0)
                              Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                color: widget.frosted
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : tokens.borderSubtle,
                              ),
                            _row(widget.items[i], tokens, errorColor),
                          ],
                        ],
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

  Widget _row(GlassContextMenuItem item, GlassTokens tokens, Color errorColor) {
    return GestureDetector(
      onTap: () => _dismiss(item.onTap),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: _rowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Builder(
                builder: (_) {
                  final double size = widget.frosted ? 16 : 18;
                  final Color color = item.destructive
                      ? errorColor
                      : widget.frosted
                      ? Colors.white.withValues(alpha: 0.92)
                      : tokens.textDim;
                  return item.iconBuilder?.call(size, color) ??
                      Icon(item.icon, size: size, color: color);
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: item.destructive ? errorColor : tokens.starkWhite,
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
