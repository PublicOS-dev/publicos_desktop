import 'package:flutter/material.dart';

import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Glass-styled Sticker / GIF segmented toggle. Same design as [QualityToggle].
/// Shown on the compose preview when a keyboard inserts an animated GIF, so the
/// user picks how it sends:
/// - STICKER -> isSticker=true (small, capped, bubble-less, stacks)
/// - GIF     -> isSticker=false (a normal attachment, natural up to 300px)
class StickerGifToggle extends StatelessWidget {
  final bool sendAsSticker;
  final ValueChanged<bool> onChanged;

  const StickerGifToggle({
    super.key,
    required this.sendAsSticker,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSubtle),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option(
            tokens: tokens,
            label: context.l10n.stickerGifToggleSticker,
            active: sendAsSticker,
            onTap: () => onChanged(true),
          ),
          _option(
            tokens: tokens,
            label: 'GIF',
            active: !sendAsSticker,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }

  Widget _option({
    required GlassTokens tokens,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final accent = tokens.connectedAccent;
    final color = active ? accent : tokens.textDim;
    final fill = active ? accent.withValues(alpha: 0.18) : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: color,
          ),
        ),
      ),
    );
  }
}
