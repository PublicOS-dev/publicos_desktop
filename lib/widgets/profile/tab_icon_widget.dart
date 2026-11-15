import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:zero_cached_image/zero_cached_image.dart';
import '../../utils/favicon_utils.dart';
import '../../utils/feed_metadata_utils.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
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

class _TabIconWidgetState extends State<TabIconWidget> {
  String? _imageUrl;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadIcon();
  }
  
  @override
  void didUpdateWidget(TabIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.key != widget.record.key) {
      _loadIcon();
    }
  }
  
  Future<void> _loadIcon() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _imageUrl = null;
    });
    
    try {
      String? imageUrl;
      
      if (widget.record.routerSubtype == RouterSubtype.channel) {
        // For RSS tabs, get the feed image first
        final metadata = await FeedMetadataUtils.getFeedMetadata(widget.record.value);
        imageUrl = metadata?.imageUrl;
        
        // If RSS feed has no image, try to get favicon from the feed's website
        if (imageUrl == null || imageUrl.isEmpty) {
          try {
            final rssUri = Uri.parse(widget.record.value);
            final websiteUrl = '${rssUri.scheme}://${rssUri.host}';
            imageUrl = FaviconUtils.getFaviconUrl(websiteUrl);
          } catch (e) {
            // If URL parsing fails, imageUrl remains null
          }
        }
      } else {
        // For web tabs, get the favicon
        imageUrl = FaviconUtils.getFaviconUrl(widget.record.value);
      }
      
      if (mounted) {
        setState(() {
          _imageUrl = imageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _imageUrl = null;
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRssTab = widget.record.routerSubtype == RouterSubtype.channel;
    
    if (_isLoading) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(
          child: PhigitalLoadingWidget(size: 10, showShadows: false),
        ),
      );
    }
    
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: _imageUrl != null
            ? ZeroCachedImage(
                imageUrl: _imageUrl!,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (context, url) => _buildFallbackIcon(theme, isRssTab),
                errorWidget: (context, url, error) => _buildFallbackIcon(theme, isRssTab),
              )
            : _buildFallbackIcon(theme, isRssTab),
      ),
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