import 'package:flutter/material.dart';

import '../theme/shell_tones.dart';

/// One floating shell surface — a rounded
/// card on the shell canvas. Every panel in the shell frame is one of these;
/// pass the [ShellTones] step this surface sits on.
class ShellPanel extends StatelessWidget {
  final Color tone;
  final Widget child;

  const ShellPanel({super.key, required this.tone, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tone,
        // Borderless: the tonal ladder alone
        // separates surfaces — no hairline on any shell panel.
        borderRadius: BorderRadius.circular(ShellMetrics.radius),
      ),
      child: child,
    );
  }
}

/// The standard split pane: a fixed-width list panel and an expanding content
/// panel, two separate floating cards with a canvas gap between them (two
/// panels, not one — keeps the list independently collapsible later). Used
/// by Contacts / Messages / Feeds; the pane's Row itself sits transparent on
/// the canvas.
class ShellSplit extends StatelessWidget {
  final double listWidth;
  final Widget list;
  final Widget content;

  const ShellSplit({
    super.key,
    required this.listWidth,
    required this.list,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final tones = ShellTones.of(context);
    return Row(
      children: [
        SizedBox(
          width: listWidth,
          child: ShellPanel(tone: tones.list, child: list),
        ),
        const SizedBox(width: ShellMetrics.gap),
        Expanded(
          child: ShellPanel(tone: tones.content, child: content),
        ),
      ],
    );
  }
}
