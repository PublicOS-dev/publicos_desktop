import 'package:flutter/material.dart';

import '../theme/glass_tokens.dart';

/// The list-selection marker shared by every left-nav list (contacts,
/// messages, the feeds drawer): a 4 px white pill on the list's left edge,
/// 28 px tall on the selected row, a 10 px nub on hover, easing between the
/// two (Discord-style). Monochrome on purpose.
///
/// Wraps the row as-is: the pill paints over the row's left edge and never
/// takes the pointer, so the row keeps its own ink + tap handling. The row
/// still owns its selected fill (see each caller).
class SelectionPill extends StatefulWidget {
  final bool selected;
  final Widget child;

  const SelectionPill({super.key, required this.selected, required this.child});

  static const double width = 4;
  static const double selectedHeight = 28;
  static const double hoverHeight = 10;

  @override
  State<SelectionPill> createState() => _SelectionPillState();
}

class _SelectionPillState extends State<SelectionPill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final h = widget.selected
        ? SelectionPill.selectedHeight
        : (_hover ? SelectionPill.hoverHeight : 0.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Stack(
        children: [
          widget.child,
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: SelectionPill.width,
                  height: h,
                  decoration: BoxDecoration(
                    color: tokens.starkWhite,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
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
}
