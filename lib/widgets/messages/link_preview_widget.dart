import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zero_cached_image/zero_cached_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:publicos_desktop/utils/favicon_utils.dart';

/// Metadata extracted from a URL's Open Graph tags
class LinkPreviewData {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;
  final String? favicon;

  const LinkPreviewData({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    this.favicon,
  });

  bool get hasContent => title != null || description != null || imageUrl != null;
}

/// Utility class for fetching and parsing Open Graph metadata
class LinkPreviewUtils {
  static final Map<String, LinkPreviewData> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(hours: 1);
  static const Duration _fetchTimeout = Duration(seconds: 10);

  /// URL regex pattern - matches http/https URLs
  static final RegExp urlRegex = RegExp(
    r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    caseSensitive: false,
  );

  /// Extract first URL from text
  static String? extractFirstUrl(String text) {
    final match = urlRegex.firstMatch(text);
    return match?.group(0);
  }

  /// Extract all URLs from text
  static List<String> extractAllUrls(String text) {
    return urlRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  /// Fetch Open Graph metadata for a URL
  static Future<LinkPreviewData> fetchPreview(String url) async {
    // Check cache first
    if (_cache.containsKey(url) && _cacheTimestamps.containsKey(url)) {
      final cachedTime = _cacheTimestamps[url]!;
      if (DateTime.now().difference(cachedTime) < _cacheExpiry) {
        return _cache[url]!;
      }
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; PublicOS/1.0; +https://publicos.app)',
          'Accept': 'text/html,application/xhtml+xml',
        },
      ).timeout(_fetchTimeout);

      if (response.statusCode != 200) {
        return LinkPreviewData(url: url);
      }

      final html = response.body;
      final preview = _parseHtml(html, url);

      // Cache the result
      _cache[url] = preview;
      _cacheTimestamps[url] = DateTime.now();

      return preview;
    } catch (e) {
      // Return basic data if fetch fails, check cache for stale data
      if (_cache.containsKey(url)) {
        return _cache[url]!;
      }
      return LinkPreviewData(url: url);
    }
  }

  /// Parse HTML and extract Open Graph metadata
  static LinkPreviewData _parseHtml(String html, String url) {
    // Extract OG tags first (preferred)
    String? ogTitle = _extractMetaContent(html, 'property=["\']og:title["\']');
    String? ogDescription = _extractMetaContent(html, 'property=["\']og:description["\']');
    String? ogImage = _extractMetaContent(html, 'property=["\']og:image["\']');
    String? ogSiteName = _extractMetaContent(html, 'property=["\']og:site_name["\']');

    // Fallback to Twitter Card tags
    ogTitle ??= _extractMetaContent(html, 'name=["\']twitter:title["\']');
    ogDescription ??= _extractMetaContent(html, 'name=["\']twitter:description["\']');
    ogImage ??= _extractMetaContent(html, 'name=["\']twitter:image["\']');

    // Fallback to standard meta tags
    ogDescription ??= _extractMetaContent(html, 'name=["\']description["\']');

    // Fallback to <title> tag
    ogTitle ??= _extractTitle(html);

    // Get favicon
    final favicon = FaviconUtils.getFaviconUrl(url);

    // Extract site name from URL if not provided
    ogSiteName ??= _extractDomain(url);

    // Make image URL absolute if relative
    if (ogImage != null && !ogImage.startsWith('http')) {
      final uri = Uri.parse(url);
      if (ogImage.startsWith('//')) {
        ogImage = '${uri.scheme}:$ogImage';
      } else if (ogImage.startsWith('/')) {
        ogImage = '${uri.scheme}://${uri.host}$ogImage';
      } else {
        ogImage = '${uri.scheme}://${uri.host}/$ogImage';
      }
    }

    return LinkPreviewData(
      url: url,
      title: _cleanText(ogTitle),
      description: _cleanText(ogDescription),
      imageUrl: ogImage,
      siteName: _cleanText(ogSiteName),
      favicon: favicon,
    );
  }

  /// Extract meta tag content using pattern for the attribute
  static String? _extractMetaContent(String html, String attributePattern) {
    // Try content after the property/name attribute
    final regex1 = RegExp(
      '<meta[^>]+$attributePattern[^>]+content=["\']([^"\']+)["\']',
      caseSensitive: false,
    );
    var match = regex1.firstMatch(html);
    if (match != null) return match.group(1);

    // Try content before the property/name attribute
    final regex2 = RegExp(
      '<meta[^>]+content=["\']([^"\']+)["\'][^>]+$attributePattern',
      caseSensitive: false,
    );
    match = regex2.firstMatch(html);
    if (match != null) return match.group(1);

    return null;
  }

  /// Extract <title> tag content
  static String? _extractTitle(String html) {
    final regex = RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false);
    final match = regex.firstMatch(html);
    return match?.group(1)?.trim();
  }

  /// Extract domain from URL
  static String? _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      var host = uri.host;
      // Remove www. prefix
      if (host.startsWith('www.')) {
        host = host.substring(4);
      }
      return host;
    } catch (e) {
      return null;
    }
  }

  /// Clean text - decode HTML entities and trim
  static String? _cleanText(String? text) {
    if (text == null || text.isEmpty) return null;

    // Decode common HTML entities
    text = text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&#34;', '"')
        .replaceAll('&#x22;', '"');

    // Handle numeric entities
    text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      try {
        return String.fromCharCode(int.parse(match.group(1)!));
      } catch (e) {
        return '';
      }
    });

    // Handle hex entities
    text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
      try {
        return String.fromCharCode(int.parse(match.group(1)!, radix: 16));
      } catch (e) {
        return '';
      }
    });

    return text.trim();
  }

  /// Clear cache
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}

/// Widget that displays a link preview card
class LinkPreviewWidget extends StatefulWidget {
  final String url;
  final Color? accentColor;

  const LinkPreviewWidget({
    super.key,
    required this.url,
    this.accentColor,
  });

  @override
  State<LinkPreviewWidget> createState() => _LinkPreviewWidgetState();
}

class _LinkPreviewWidgetState extends State<LinkPreviewWidget> {
  Future<LinkPreviewData>? _previewFuture;

  @override
  void initState() {
    super.initState();
    _previewFuture = LinkPreviewUtils.fetchPreview(widget.url);
  }

  @override
  void didUpdateWidget(LinkPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _previewFuture = LinkPreviewUtils.fetchPreview(widget.url);
    }
  }

  Future<void> _openUrl() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LinkPreviewData>(
      future: _previewFuture,
      builder: (context, snapshot) {
        // Loading, error, or no content - show nothing (URL is already clickable in message)
        // Only expand when we have actual content to display
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.hasContent) {
          return const SizedBox.shrink();
        }

        final preview = snapshot.data!;
        return _buildPreviewCard(preview);
      },
    );
  }

  Widget _buildPreviewCard(LinkPreviewData preview) {
    return GestureDetector(
      onTap: _openUrl,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (if available)
            if (preview.imageUrl != null) _buildImage(preview.imageUrl!),

            // Content section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Site info row (favicon + site name)
                  if (preview.siteName != null || preview.favicon != null)
                    _buildSiteInfo(preview),

                  // Title
                  if (preview.title != null) ...[
                    if (preview.siteName != null) const SizedBox(height: 6),
                    Text(
                      preview.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Description
                  if (preview.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      preview.description!,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return _LinkPreviewImage(imageUrl: imageUrl);
  }

  Widget _buildSiteInfo(LinkPreviewData preview) {
    return Row(
      children: [
        // Favicon
        if (preview.favicon != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: ZeroCachedImage(
              imageUrl: preview.favicon!,
              width: 16,
              height: 16,
              fit: BoxFit.cover,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              errorWidget: (context, url, error) => Icon(
                Icons.language,
                size: 16,
                color: Colors.grey[500],
              ),
            ),
          ),
        if (preview.favicon != null && preview.siteName != null)
          const SizedBox(width: 6),
        // Site name
        if (preview.siteName != null)
          Expanded(
            child: Text(
              preview.siteName!,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  String _truncateUrl(String url) {
    // Remove protocol and www
    var display = url.replaceFirst(RegExp(r'^https?://'), '');
    display = display.replaceFirst(RegExp(r'^www\.'), '');
    if (display.length > 40) {
      display = '${display.substring(0, 40)}...';
    }
    return display;
  }
}

/// Stateful widget that handles image loading - only shows when loaded successfully
class _LinkPreviewImage extends StatefulWidget {
  final String imageUrl;

  const _LinkPreviewImage({required this.imageUrl});

  @override
  State<_LinkPreviewImage> createState() => _LinkPreviewImageState();
}

class _LinkPreviewImageState extends State<_LinkPreviewImage> {
  bool _imageLoaded = false;
  bool _hasError = false;
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final provider = ZeroCachedImageProvider(widget.imageUrl);
      // Pre-cache the image
      await precacheImage(provider, context, onError: (exception, stackTrace) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });

      if (mounted && !_hasError) {
        setState(() {
          _imageProvider = provider;
          _imageLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show nothing until image is loaded (or if error)
    if (!_imageLoaded || _hasError || _imageProvider == null) {
      return const SizedBox.shrink();
    }

    // Image loaded successfully - show it
    return Image(
      image: _imageProvider!,
      width: double.infinity,
      height: 160,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
