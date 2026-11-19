import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:zero_cached_image/zero_cached_image.dart';
import '../../utils/favicon_utils.dart';
import 'package:publicos_desktop/widgets/feeds/feed_favicon.dart';
import 'package:publicos_desktop/widgets/shimmer_box.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

class TabIconWidget extends StatefulWidget {
  final Record record;
  final double size;
  
  const TabIconWidget({
    super.key,
    required this.record,
    this.size = 32.0,
  });

  @override
  State<TabIconWidget> createState() => _TabIconWidgetState();
}

class _TabIconWidgetState extends State<TabIconWidget>
    with SingleTickerProviderStateMixin {
  // Drives the shimmer while a channel's icon comes, matching the list
  // header's tiles.
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GlassTokens.of(context);
    final isRssTab = widget.record.routerSubtype == RouterSubtype.channel;
    final fallback = _buildFallbackIcon(theme, isRssTab);

    // A channel tab reads the icon registry through FeedFavicon:
    // a channel any load has read paints at once, an unknown one costs one
    // shared fetch. Before, this widget downloaded the whole channel itself
    // and ignored the registry, so the tabs sheet spun long after the
    // profile had the icon.
    final Widget child = isRssTab
        ? FeedFavicon(
            feedUrl: widget.record.value,
            size: widget.size,
            cornerRadius: 5,
            fallback: fallback,
            placeholder: ShimmerBox(
              progress: _shimmer,
              width: widget.size,
              height: widget.size,
              radius: 5,
              base: tokens.surfaceElevated,
              highlight: Color.alphaBlend(
                tokens.starkWhite.withValues(alpha: 0.10),
                tokens.surfaceElevated,
              ),
            ),
          )
        : _buildWebIcon(fallback);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: child,
      ),
    );
  }

  /// A web tab: the site's favicon, built locally (no fetch).
  Widget _buildWebIcon(Widget fallback) {
    final url = FaviconUtils.getFaviconUrl(widget.record.value);
    return ZeroCachedImage(
      imageUrl: url,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) => fallback,
      errorWidget: (context, url, error) => fallback,
    );
  }

  Widget _buildFallbackIcon(ThemeData theme, bool isRssTab) {
    return Container(
      width: widget.size,
      height: widget.size,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Icon(
        isRssTab ? Icons.rss_feed : Icons.language,
        size: widget.size * 0.6,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }
}

/// Tab-type mini badge — the monochrome glass notch shared across the browser
/// header avatar (`browser.dart::_buildMiniTabIcon`), the tab-switcher sheet,
/// and the Manage tabs sheet: solid `surfaceDeep` rounded-square so it cuts out
/// of the artwork underneath, `starkWhite` glyph, no border (a hairline
/// reads as a frame around the glyph). Type
/// is carried by the glyph, never by color (the grey-palette rule).
/// Notch it into a leading icon's bottom-right corner via a `Stack` +
/// `Positioned(right: -2, bottom: -2)`.
class TabTypeBadge extends StatelessWidget {
  final IconData icon;
  static const double size = 16;

  const TabTypeBadge({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tokens.surfaceDeep,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Center(
        child: Icon(icon, size: size * 0.62, color: tokens.starkWhite),
      ),
    );
  }
}