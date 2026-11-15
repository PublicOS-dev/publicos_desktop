import 'package:flutter/material.dart';

import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Divider marking the boundary between read and unread messages. Shows
/// the "Unread" label on first build, then returns [SizedBox.shrink] on
/// subsequent rebuilds so the band doesn't flash back in when the list
/// reshapes (e.g. on scroll back or after a resort).
class UnreadDivider extends StatefulWidget {
  const UnreadDivider({super.key});

  @override
  State<UnreadDivider> createState() => _UnreadDividerState();
}

class _UnreadDividerState extends State<UnreadDivider> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    if (_shown) return const SizedBox.shrink();
    _shown = true;

    final tokens = GlassTokens.of(context);
    final lineColor = tokens.connectedAccent.withValues(alpha: 0.4);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: lineColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Unread',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.connectedAccent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: lineColor)),
        ],
      ),
    );
  }
}
