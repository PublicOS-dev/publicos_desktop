import 'package:flutter/material.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/favicon_utils.dart';
import 'package:publicos_desktop/utils/feed_metadata_utils.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

/// Resolves and renders a feed's icon with the standard fallback chain:
/// feed metadata `imageUrl` (channel logo, RSS `<image>`, Atom `<logo>`)
/// → website favicon → generic RSS icon. Reads [FeedMetadataUtils]'s icon
/// registry first (memory, then disk), so a feed any load has read paints
/// with no network; an unknown feed costs one fetch shared by every caller.
///
/// Designed for use anywhere a single feed needs to be visually identified
/// (drawer + inline header for single-flagged lists, add-to-lists sheet's
/// single-follow row, manage-lists sheet's single-flagged rows).
class FeedFavicon extends StatefulWidget {
  final String feedUrl;
  final double size;
  /// Corner radius of the rendered icon. Defaults to size / 5.5 for a
  /// soft-square look that matches the drawer + sheet rows.
  final double? cornerRadius;

  /// Tint of the RSS fallback glyph. Defaults to `starkWhite`, which is right
  /// on every dark app surface — but the browser's tab deck paints itself in
  /// the contact's own swatch, where a fixed white glyph can vanish. Callers
  /// on a non-token surface pass the colour their surface derived.
  final Color? fallbackColor;

  /// Site favicon FIRST, then the feed's own image, then the RSS glyph (the
  /// post-card avatar of a classic RSS post). No metadata
  /// fetch unless the favicon fails to load. Off by default: on single-list
  /// surfaces the feed image is a PublicOS channel's own logo, and every
  /// channel on one SSP would share that host's favicon.
  final bool faviconFirst;

  /// Shown while the icon URL resolves and while the image loads, in place
  /// of the RSS glyph (a shimmer, say). The glyph stays the fallback for an
  /// icon that cannot be had. Null keeps the glyph throughout.
  final Widget? placeholder;

  const FeedFavicon({
    super.key,
    required this.feedUrl,
    this.size = 22,
    this.cornerRadius,
    this.fallbackColor,
    this.faviconFirst = false,
    this.placeholder,
  });

  @override
  State<FeedFavicon> createState() => _FeedFaviconState();
}

class _FeedFaviconState extends State<FeedFavicon> {
  String? _imageUrl;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(FeedFavicon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedUrl != widget.feedUrl) {
      setState(() {
        _imageUrl = null;
        _resolved = false;
      });
      _resolve();
    }
  }

  Future<void> _resolve() async {
    String? url;
    if (widget.faviconFirst) {
      // Built locally — no network until the image loads.
      try {
        final uri = Uri.parse(widget.feedUrl);
        if (uri.host.isNotEmpty) {
          url = FaviconUtils.getFaviconUrl('${uri.scheme}://${uri.host}');
        }
      } catch (_) {}
      // Synchronous — runs inside initState / didUpdateWidget, which a build
      // always follows, so no setState.
      _imageUrl = url;
      _resolved = true;
      return;
    }
    // The icon registry first: a feed any load has read paints now, with no
    // network. Synchronous, so no setState (see above).
    final known = FeedMetadataUtils.displayIconNow(widget.feedUrl);
    if (known != null) {
      _imageUrl = known.url;
      _resolved = true;
      return;
    }
    url = await FeedMetadataUtils.resolveDisplayIcon(widget.feedUrl);
    if (!mounted) return;
    setState(() {
      _imageUrl = (url != null && url.isNotEmpty) ? url : null;
      _resolved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // RSS glyph at the full footprint — shown while the icon URL resolves,
    // while the network image loads (as ZeroCachedImage's placeholder), and
    // on error. Keeping it the exact `size` means the resolved favicon just
    // fades over it instead of reflowing the row.
    final fallback = Icon(
      Icons.rss_feed_rounded,
      size: widget.size,
      color: widget.fallbackColor ?? tokens.starkWhite,
    );
    // Favicon-first: when the favicon fails, the feed's own image is the next
    // rung — the default chain (image → favicon → glyph) in the same slot.
    final Widget onError = widget.faviconFirst
        ? FeedFavicon(
            feedUrl: widget.feedUrl,
            size: widget.size,
            cornerRadius: widget.cornerRadius,
            fallbackColor: widget.fallbackColor,
          )
        : fallback;
    final waiting = widget.placeholder ?? fallback;
    // Re-read the registry on every build: when a refresh brings a new icon,
    // the post loader rebuilds its surface and the tile follows.
    final live = widget.faviconFirst
        ? null
        : FeedMetadataUtils.displayIconNow(widget.feedUrl);
    final imageUrl = live != null ? live.url : _imageUrl;
    final resolved = live != null || _resolved;
    final Widget child;
    if (!resolved) {
      child = waiting;
    } else if (imageUrl == null) {
      child = widget.faviconFirst ? onError : fallback;
    } else {
      child = ClipRRect(
        borderRadius:
            BorderRadius.circular(widget.cornerRadius ?? widget.size / 5.5),
        child: ZeroCachedImage(
          imageUrl: imageUrl,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (_, __) => waiting,
          errorWidget: (_, __, ___) => onError,
        ),
      );
    }
    // Outer fixed box guarantees the slot never changes size across the
    // resolving / loading / loaded / error states.
    return SizedBox(width: widget.size, height: widget.size, child: child);
  }
}
