import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/doc_types.dart';
import 'package:url_launcher/url_launcher.dart';

/// A non-media attachment in the post carousel (a PDF or another kind of
/// file). The family glyph and tint come from `doc_types.dart`, chosen by
/// the attachment's MIME first (the server stores 23 of its 32 allowed
/// types as `.bin`, so the extension cannot be trusted; the MIME can), then
/// by the filename. A tap opens the URL outside the app.
///
/// Two shapes: the carousel's fixed footprint ([width] × [height], a column)
/// and the single-attachment row ([compact], the width the caller gives).
class PostFileTile extends StatelessWidget {
  final PostMediaItem item;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool compact;

  const PostFileTile({
    super.key,
    required this.item,
    this.width,
    this.height,
    this.borderRadius,
    this.compact = false,
  });

  String get _name {
    final t = item.title?.trim();
    if (t != null && t.isNotEmpty) return t;
    try {
      final segs = Uri.parse(item.url).pathSegments;
      if (segs.isNotEmpty && segs.last.isNotEmpty) return segs.last;
    } catch (_) {}
    return item.url;
  }

  String get _meta {
    final parts = <String>[];
    final ext = docExtension(_name);
    final label = ext.isNotEmpty
        ? ext.toUpperCase()
        : item.mimeType.split('/').last.toUpperCase();
    if (label.isNotEmpty) parts.add(label);
    final size = item.sizeInBytes;
    if (size != null && size > 0) parts.add(formatFileSize(size));
    return parts.join(' · ');
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(item.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final type = docTypeForMime(item.mimeType, _name);
    final radius = borderRadius ?? BorderRadius.circular(14);
    final glyph = Container(
      width: compact ? 40 : 48,
      height: compact ? 40 : 48,
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
      ),
      child: Icon(type.icon, color: type.color, size: compact ? 22 : 26),
    );
    final name = Text(
      _name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: compact ? TextAlign.start : TextAlign.center,
      style: TextStyle(
        color: tokens.starkWhite,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
    );
    final meta = Text(
      _meta,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: tokens.textDim, fontSize: 11),
    );
    final body = compact
        ? Row(
            children: [
              glyph,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [name, const SizedBox(height: 3), meta],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, size: 16, color: tokens.textDim),
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              glyph,
              const SizedBox(height: 12),
              name,
              const SizedBox(height: 4),
              meta,
            ],
          );
    return Semantics(
      button: true,
      label: _name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _open,
          borderRadius: radius,
          child: Container(
            width: width,
            height: height,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: radius,
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: body,
          ),
        ),
      ),
    );
  }
}
