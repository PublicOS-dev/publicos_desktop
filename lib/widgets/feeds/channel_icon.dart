import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_cached_image/zero_cached_image.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Rounded-square channel avatar used across the feeds tab.
///
/// Fills with the channel's own icon when available, otherwise cascades
/// through a favicon pulled from the channel's server host, and finally
/// falls back to a glyph matching the channel type (forum / rss).
class ChannelIcon extends StatelessWidget {
  final Channel channel;
  final double size;
  final bool selected;

  const ChannelIcon({
    super.key,
    required this.channel,
    this.size = 36,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final radius = size * 0.28;
    final glyphColor =
        selected ? tokens.connectedAccent : tokens.starkWhite;
    // Forum glyph when the owner chose the forum layout (it used to follow
    // "anyone can post"). Who may post no longer decides the look.
    final glyphIcon =
        channel.isForumLayout ? Icons.forum_outlined : Icons.rss_feed_rounded;
    final faviconUrl = _faviconUrlFor(channel.serverAddress);
    final iconUrl = channel.iconUrl;
    final hasIcon = iconUrl != null && iconUrl.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: tokens.borderSubtle, width: 1),
        borderRadius: BorderRadius.circular(radius),
        color: tokens.glassFill,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glyph fallback (always rendered under image layers)
            Icon(glyphIcon, size: size * 0.5, color: glyphColor),
            if (faviconUrl != null)
              Positioned.fill(
                child: ZeroCachedImage(
                  imageUrl: faviconUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            if (hasIcon)
              Positioned.fill(
                child: ZeroCachedImage(
                  imageUrl: iconUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String? _faviconUrlFor(String? serverAddress) {
  if (serverAddress == null || serverAddress.isEmpty) return null;
  final uri = Uri.tryParse(serverAddress);
  if (uri == null || uri.host.isEmpty) return null;
  return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=128';
}
