import 'dart:math' show max;

import 'package:publicos_core/publicos_core.dart';
import 'package:zero_cached_image/zero_cached_image.dart';
import 'package:publicos_desktop/widgets/feeds/mention_text.dart';
import 'package:flutter/material.dart';
import 'package:publicos_desktop/utils/favicon_utils.dart';
import '../browser/publicos_webview.dart';
import '../nft_info_dialog.dart';
import '../image_overlay.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/theme_provider.dart';
import '../nft_verified_art.dart';
import '../shimmer_box.dart';
import 'content_card.dart';
import 'profile_post_card.dart';
import '../transactions/send_sheet.dart';
import '../../data/chain_registry.dart';
import '../glass_context_menu.dart';
import '../dashed_add_button.dart';
import '../../theme/glass_tokens.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// Display names for known social platform record keys.
/// Display names = Core's fixed social list ([SocialLinks]): the
/// picker, the strip and these labels read one table.
final socialDisplayNames = SocialLinks.names;

/// Returns a friendly display name for known social keys, or the key itself.
String socialDisplayName(String key) => socialDisplayNames[key] ?? key;

/// Branded icons for known social platform record keys.
/// Returns a CustomPaint widget with the platform's logo, or null if unknown.
Widget? socialIconForKey(
  String key, {
  double size = 20,
  Color color = Colors.white,
}) {
  // Email and Website have no brand mark: a mail glyph and the web globe
  // (a Website record swaps the globe for the site's own icon, see
  // [socialGlyphForRecord]).
  final k = key.toLowerCase();
  if (k == 'email') {
    return Icon(Icons.mail_outline_rounded, size: size, color: color);
  }
  if (k == 'url') {
    return Icon(Icons.language_rounded, size: size, color: color);
  }
  final path = _socialSvgPaths[key];
  if (path == null) return null;
  return CustomPaint(
    size: Size.square(size),
    painter: _SvgPathPainter(
      path: path,
      color: color,
      viewBoxSize: _socialViewBox[key] ?? 24,
    ),
  );
}

/// The glyph for a social RECORD: [socialIconForKey], except that a Website
/// shows the site's own icon (the favicon of the URL the user set), falling
/// back to the web globe while it loads or when there is none.
Widget? socialGlyphForRecord(Record record,
    {double size = 20, Color color = Colors.white}) {
  final fallback = socialIconForKey(record.key, size: size, color: color);
  if (record.key.toLowerCase() != 'url') return fallback;
  final site = SocialLinks.of('url')?.buildLink(record.value);
  final host = site == null ? null : Uri.tryParse(site)?.host;
  if (host == null || host.isEmpty) return fallback;
  return ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.2),
    child: ZeroCachedImage(
      imageUrl: FaviconUtils.getFaviconUrl('https://$host'),
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholder: (_, __) => fallback ?? const SizedBox.shrink(),
      errorWidget: (_, __, ___) => fallback ?? const SizedBox.shrink(),
    ),
  );
}

const _socialSvgPaths = <String, String>{
  'com.twitter':
      'M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z',
  'com.instagram':
      'M7.8 2h8.4C19.4 2 22 4.6 22 7.8v8.4c0 3.2-2.6 5.8-5.8 5.8H7.8C4.6 22 2 19.4 2 16.2V7.8C2 4.6 4.6 2 7.8 2zm-.2 2C5.61 4 4 5.61 4 7.6v8.8C4 18.39 5.61 20 7.6 20h8.8c1.99 0 3.6-1.61 3.6-3.6V7.6C20 5.61 18.39 4 16.4 4H7.6zM12 7.5c2.49 0 4.5 2.01 4.5 4.5s-2.01 4.5-4.5 4.5S7.5 14.49 7.5 12 9.51 7.5 12 7.5zm0 2c-1.38 0-2.5 1.12-2.5 2.5s1.12 2.5 2.5 2.5 2.5-1.12 2.5-2.5-1.12-2.5-2.5-2.5zm4.75-2.75c.55 0 1 .45 1 1s-.45 1-1 1-1-.45-1-1 .45-1 1-1z',
  'com.github':
      'M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12',
  'app.bsky':
      'M12 10.8c-1.087-2.114-4.046-6.053-6.798-7.995C2.566.944 1.561 1.266.902 1.565.139 1.908 0 3.08 0 3.768c0 .69.378 5.65.624 6.479.785 2.627 3.601 3.476 6.96 3.066-4.08.558-7.048 1.96-3.6 6.687 3.671 4.323 6.152-.397 7.016-2.660.864 2.263 1.87 6.836 6.816 2.66 2.592-3.14 1.225-5.44-2.856-6.687 3.36.41 6.176-.44 6.96-3.066.246-.828.624-5.79.624-6.479 0-.688-.139-1.86-.902-2.203-.659-.3-1.664-.62-4.3 1.24C14.046 4.747 11.087 8.686 12 10.8z',
  'com.linkedin':
      'M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 01-2.063-2.065 2.064 2.064 0 112.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z',
  'com.discord':
      'M20.317 4.3698a19.7913 19.7913 0 00-4.8851-1.5152.0741.0741 0 00-.0785.0371c-.211.3753-.4447.8648-.6083 1.2495-1.8447-.2762-3.68-.2762-5.4868 0-.1636-.3933-.4058-.8742-.6177-1.2495a.077.077 0 00-.0785-.037 19.7363 19.7363 0 00-4.8852 1.515.0699.0699 0 00-.0321.0277C.5334 9.0458-.319 13.5799.0992 18.0578a.0824.0824 0 00.0312.0561c2.0528 1.5076 4.0413 2.4228 5.9929 3.0294a.0777.0777 0 00.0842-.0276c.4616-.6304.8731-1.2952 1.226-1.9942a.076.076 0 00-.0416-.1057c-.6528-.2476-1.2743-.5495-1.8722-.8923a.077.077 0 01-.0076-.1277c.1258-.0943.2517-.1923.3718-.2914a.0743.0743 0 01.0776-.0105c3.9278 1.7933 8.18 1.7933 12.0614 0a.0739.0739 0 01.0785.0095c.1202.099.246.1981.3728.2924a.077.077 0 01-.0066.1276 12.2986 12.2986 0 01-1.873.8914.0766.0766 0 00-.0407.1067c.3604.698.7719 1.3628 1.225 1.9932a.076.076 0 00.0842.0286c1.961-.6067 3.9495-1.5219 6.0023-3.0294a.077.077 0 00.0313-.0552c.5004-5.177-.8382-9.6739-3.5485-13.6604a.061.061 0 00-.0312-.0286zM8.02 15.3312c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9555-2.4189 2.157-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.9555 2.4189-2.1569 2.4189zm7.9748 0c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9554-2.4189 2.1569-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.946 2.4189-2.1568 2.4189z',
  'org.telegram':
      'M11.944 0A12 12 0 000 12a12 12 0 0012 12 12 12 0 0012-12A12 12 0 0012.056 0h-.112zM17.89 8.02l-1.98 9.32c-.15.67-.54.83-1.1.52l-3.02-2.23-1.46 1.4c-.16.16-.3.3-.61.3l.22-3.06 5.56-5.02c.24-.22-.05-.33-.37-.13L8.55 13.7l-2.95-.92c-.64-.2-.65-.64.13-.95l11.52-4.44c.53-.2 1 .13.82.95l-.17-.32z',
  'com.reddit':
      'M12 0A12 12 0 000 12a12 12 0 0012 12 12 12 0 0012-12A12 12 0 0012 0zm5.01 4.744c.688 0 1.25.561 1.25 1.249a1.25 1.25 0 01-2.498.056l-2.597-.547-.8 3.747c1.824.07 3.48.632 4.674 1.488.308-.309.73-.491 1.207-.491.968 0 1.754.786 1.754 1.754 0 .716-.435 1.333-1.01 1.614a3.111 3.111 0 01.042.52c0 2.694-3.13 4.87-7.004 4.87-3.874 0-7.004-2.176-7.004-4.87 0-.183.015-.366.043-.534A1.748 1.748 0 014.028 12c0-.968.786-1.754 1.754-1.754.463 0 .898.196 1.207.49 1.207-.883 2.878-1.43 4.744-1.487l.885-4.182a.342.342 0 01.14-.197.35.35 0 01.238-.042l2.906.617a1.214 1.214 0 011.108-.7zM9.25 12C8.561 12 8 12.56 8 13.25c0 .687.561 1.248 1.25 1.248.687 0 1.248-.561 1.248-1.249 0-.688-.561-1.249-1.249-1.249zm5.5 0c-.687 0-1.248.561-1.248 1.25 0 .687.561 1.248 1.249 1.248.688 0 1.249-.561 1.249-1.249 0-.687-.562-1.249-1.25-1.249zm-5.466 3.99a.327.327 0 00-.231.094.33.33 0 000 .463c.842.842 2.484.913 2.961.913.477 0 2.105-.056 2.961-.913a.361.361 0 000-.462.34.34 0 00-.462 0c-.545.533-1.684.73-2.512.73-.828 0-1.953-.21-2.498-.73a.326.326 0 00-.22-.095z',
  'com.youtube':
      'M23.498 6.186a3.016 3.016 0 00-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 00.502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 002.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 002.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z',
  'xyz.farcaster':
      'M18.24.24H5.76C2.5789.24 0 2.8188 0 6v12c0 3.1811 2.5789 5.76 5.76 5.76h12.48c3.1812 0 5.76-2.5789 5.76-5.76V6C24 2.8188 21.4212.24 18.24.24m.8155 17.1662v.504c.2868-.0256.5458.1905.5439.479v.5688h-5.1437v-.5688c-.0019-.2885.2576-.5047.5443-.479v-.504c0-.22.1525-.402.358-.458l-.0095-4.3645c-.1589-1.7366-1.6402-3.0979-3.4435-3.0979-1.8038 0-3.2846 1.3613-3.4435 3.0979l-.0096 4.3578c.2276.0424.5318.2083.5395.4648v.504c.2863-.0256.5457.1905.5438.479v.5688H4.3915v-.5688c-.0019-.2885.2575-.5047.5438-.479v-.504c0-.2529.2011-.4548.4536-.4724v-7.895h-.4905L4.2898 7.008l2.6405-.0005V5.0419h9.9495v1.9656h2.8219l-.6091 2.0314h-.4901v7.8949c.2519.0177.453.2195.453.4724',
};

const _socialViewBox = <String, double>{
  'xyz.farcaster': 24,
  'com.twitter': 24,
  'com.instagram': 24,
  'com.github': 24,
  'app.bsky': 24,
  'com.linkedin': 24,
  'com.discord': 24,
  'org.telegram': 24,
  'com.reddit': 24,
  'com.youtube': 24,
};

class _SvgPathPainter extends CustomPainter {
  final String path;
  final Color color;
  final double viewBoxSize;

  _SvgPathPainter({
    required this.path,
    required this.color,
    required this.viewBoxSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final parsedPath = _parseSvgPath(path);
    final scale = size.width / viewBoxSize;
    final matrix = Matrix4.identity()..scale(scale, scale);
    final scaledPath = parsedPath.transform(matrix.storage);
    canvas.drawPath(scaledPath, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SvgPathPainter old) =>
      old.path != path || old.color != color;
}

/// Minimal SVG path parser — handles M, L, H, V, C, S, Q, T, A, Z (absolute & relative).
Path _parseSvgPath(String svg) {
  final path = Path();
  final re = RegExp(r'([MmLlHhVvCcSsQqTtAaZz])([^MmLlHhVvCcSsQqTtAaZz]*)');
  double cx = 0, cy = 0;
  double sx = 0, sy = 0; // subpath start
  double lastCx = 0, lastCy = 0; // last control point for S/T

  List<double> nums(String s) {
    return RegExp(
      r'-?[0-9]*\.?[0-9]+(?:e[+-]?[0-9]+)?',
    ).allMatches(s).map((m) => double.parse(m.group(0)!)).toList();
  }

  for (final match in re.allMatches(svg)) {
    final cmd = match.group(1)!;
    final args = nums(match.group(2)!);
    final bool rel = cmd.toLowerCase() == cmd;
    int i = 0;

    switch (cmd.toUpperCase()) {
      case 'M':
        while (i < args.length) {
          cx = rel ? cx + args[i] : args[i];
          cy = rel ? cy + args[i + 1] : args[i + 1];
          if (i == 0) {
            path.moveTo(cx, cy);
            sx = cx;
            sy = cy;
          } else {
            path.lineTo(cx, cy);
          }
          i += 2;
        }
      case 'L':
        while (i < args.length) {
          cx = rel ? cx + args[i] : args[i];
          cy = rel ? cy + args[i + 1] : args[i + 1];
          path.lineTo(cx, cy);
          i += 2;
        }
      case 'H':
        while (i < args.length) {
          cx = rel ? cx + args[i] : args[i];
          path.lineTo(cx, cy);
          i += 1;
        }
      case 'V':
        while (i < args.length) {
          cy = rel ? cy + args[i] : args[i];
          path.lineTo(cx, cy);
          i += 1;
        }
      case 'C':
        while (i + 5 < args.length) {
          final x1 = rel ? cx + args[i] : args[i];
          final y1 = rel ? cy + args[i + 1] : args[i + 1];
          final x2 = rel ? cx + args[i + 2] : args[i + 2];
          final y2 = rel ? cy + args[i + 3] : args[i + 3];
          final x = rel ? cx + args[i + 4] : args[i + 4];
          final y = rel ? cy + args[i + 5] : args[i + 5];
          path.cubicTo(x1, y1, x2, y2, x, y);
          lastCx = x2;
          lastCy = y2;
          cx = x;
          cy = y;
          i += 6;
        }
      case 'S':
        while (i + 3 < args.length) {
          final x1 = 2 * cx - lastCx;
          final y1 = 2 * cy - lastCy;
          final x2 = rel ? cx + args[i] : args[i];
          final y2 = rel ? cy + args[i + 1] : args[i + 1];
          final x = rel ? cx + args[i + 2] : args[i + 2];
          final y = rel ? cy + args[i + 3] : args[i + 3];
          path.cubicTo(x1, y1, x2, y2, x, y);
          lastCx = x2;
          lastCy = y2;
          cx = x;
          cy = y;
          i += 4;
        }
      case 'Q':
        while (i + 3 < args.length) {
          final x1 = rel ? cx + args[i] : args[i];
          final y1 = rel ? cy + args[i + 1] : args[i + 1];
          final x = rel ? cx + args[i + 2] : args[i + 2];
          final y = rel ? cy + args[i + 3] : args[i + 3];
          path.quadraticBezierTo(x1, y1, x, y);
          lastCx = x1;
          lastCy = y1;
          cx = x;
          cy = y;
          i += 4;
        }
      case 'T':
        while (i + 1 < args.length) {
          final x1 = 2 * cx - lastCx;
          final y1 = 2 * cy - lastCy;
          final x = rel ? cx + args[i] : args[i];
          final y = rel ? cy + args[i + 1] : args[i + 1];
          path.quadraticBezierTo(x1, y1, x, y);
          lastCx = x1;
          lastCy = y1;
          cx = x;
          cy = y;
          i += 2;
        }
      case 'A':
        // Arc flags are single digits (0/1) that can be concatenated — need special parsing
        final arcArgs = _parseArcArgs(match.group(2)!);
        int j = 0;
        while (j + 6 < arcArgs.length) {
          final rx = arcArgs[j];
          final ry = arcArgs[j + 1];
          final rotation = arcArgs[j + 2];
          final largeArc = arcArgs[j + 3] != 0;
          final sweep = arcArgs[j + 4] != 0;
          final x = rel ? cx + arcArgs[j + 5] : arcArgs[j + 5];
          final y = rel ? cy + arcArgs[j + 6] : arcArgs[j + 6];
          path.arcToPoint(
            Offset(x, y),
            radius: Radius.elliptical(rx, ry),
            rotation: rotation,
            largeArc: largeArc,
            clockwise: sweep,
          );
          cx = x;
          cy = y;
          j += 7;
        }
      case 'Z':
        path.close();
        cx = sx;
        cy = sy;
    }
  }
  return path;
}

/// Parse arc command arguments with proper flag handling.
/// SVG arc flags (large-arc, sweep) are single digits (0/1) that can be
/// concatenated with each other and adjacent numbers (e.g. "000" = flag 0, flag 0, coord 0).
List<double> _parseArcArgs(String s) {
  final result = <double>[];
  final numRe = RegExp(r'-?[0-9]*\.?[0-9]+(?:e[+-]?[0-9]+)?');
  int paramInSet = 0;
  int pos = 0;
  while (pos < s.length) {
    while (pos < s.length &&
        (s[pos] == ' ' || s[pos] == ',' || s[pos] == '\t' || s[pos] == '\n'))
      pos++;
    if (pos >= s.length) break;
    if ((paramInSet == 3 || paramInSet == 4) &&
        (s[pos] == '0' || s[pos] == '1')) {
      result.add(s[pos] == '1' ? 1.0 : 0.0);
      pos++;
    } else {
      final match = numRe.matchAsPrefix(s, pos);
      if (match == null) break;
      result.add(double.parse(match.group(0)!));
      pos = match.end;
    }
    paramInSet = (paramInSet + 1) % 7;
  }
  return result;
}

class RecordButton extends StatelessWidget {
  final Record record;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isEditable;
  final bool isEditMode;

  /// Set the viewer's avatar to this NFT card's pointer (the "use as avatar"
  /// action in the card's info dialog). Null hides the button — e.g. non-NFT
  /// cards, or surfaces with no self-write path.
  final Future<bool> Function(NftAvatarRef ref)? onUseNftAsAvatar;

  /// The profile this record belongs to — the NFT card's verified owner.
  /// Passed to the info dialog for the "owned by" mini avatar; null on previews.
  final Contact? nftOwner;

  /// Whether this app card is currently promoted to its live half. Owned by
  /// [ProfileGrid] — a card is TOLD, because "one live at a time" is a fact
  /// about the grid rather than about any card.
  final bool isLive;

  /// Toggles [isLive] in the grid.
  final VoidCallback? onToggleLive;

  /// This card was promoted and its live half failed to load.
  final bool liveFailed;

  /// Reports that failure up, so the grid demotes back to the image.
  final VoidCallback? onLiveFailed;

  /// The verified live URL, or null when this card cannot be promoted.
  /// Stamped by the resolver ONLY on an `ok` verdict, so its presence IS the
  /// promotability test — this widget cannot promote a card the trust walk
  /// refused, because it would have nothing to promote it to.
  String? get _liveUrl => record.metadata[AppCardMeta.live] as String?;

  const RecordButton({
    super.key,
    required this.record,
    required this.onTap,
    required this.onDelete,
    required this.isEditable,
    required this.isEditMode,
    this.onUseNftAsAvatar,
    this.nftOwner,
    this.isLive = false,
    this.onToggleLive,
    this.liveFailed = false,
    this.onLiveFailed,
  });

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
          title: Text(context.l10n.recordButtonDeleteTitle),
          content: Text(context.l10n.recordButtonDeleteConfirm(record.key)),
          actions: <Widget>[
            TextButton(
              child: Text(context.l10n.dlgCancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(context.l10n.recordButtonDelete),
              onPressed: () {
                Navigator.of(context).pop();
                onDelete();
              },
            ),
          ],
        );
      },
    );
  }

  /// Open a URL externally. Defaults to this record's own `link`; [url] is
  /// passed by an app card's live frame when it refuses an off-origin
  /// navigation, so the link still lands somewhere with real browser chrome
  /// rather than dying inside a tile that has no address bar.
  Future<void> _launchURL(BuildContext context, {String? url}) async {
    final target = url ?? record.link;
    if (target != null) {
      final Uri uri = Uri.parse(target);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.recordButtonCouldNotLaunch(target)),
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      }
    }
  }

  /// NFT card tap → the shared NFT info dialog (same one the avatar and banner
  /// use): art, ownership badge, chain/contract/token, traits, and explorer/
  /// marketplace links, all from the full verdict `fetchContact` cached on this
  /// record (`nftVerified`). Until that verdict lands (a freshly-added card on
  /// first view, or a card cached before `nftVerified` existed), fall back to
  /// the plain full-screen image. [onUseNftAsAvatar], when wired, surfaces the
  /// "use as avatar" button inside the dialog.
  void _showNftInfo(BuildContext context, String imageUrl) {
    final ref = NftAvatarRef.tryParse(record.value);
    if (ref == null) {
      // Not a parseable NFT pointer (legacy/corrupt card) — plain image.
      _showImageOverlay(context, imageUrl: imageUrl);
      return;
    }
    // Prefer the full verdict `fetchContact` cached on the record. If it hasn't
    // landed yet — a card cached before `nftVerified` existed, in the one-fetch
    // window before Core's backfill recompute — synthesize a lite verdict from
    // the pointer + cached image/ownership so the dialog still opens (art,
    // verified badge, chain/contract/token, links; name/traits fill in once the
    // rich verdict lands). No network on either path.
    final cache =
        VerifiedNftAvatar.tryParse(record.metadata['nftVerified'] as String?) ??
        VerifiedNftAvatar(
          pointer: ref,
          metadata: {'image': imageUrl},
          verifiedOwnership: record.metadata['nftOwned'] == true,
          checkedAt: DateTime.fromMillisecondsSinceEpoch(
            (record.metadata['nftCheckedAt'] as num?)?.toInt() ?? 0,
          ),
        );
    showNftInfoDialogFor(
      context,
      ref: ref,
      cache: cache,
      owner: nftOwner,
      onUseAsAvatar: onUseNftAsAvatar,
    );
  }

  /// A tip card's tap: the send sheet locked to exactly the
  /// card's wallet, chain and token, at amount 0 (no amount is ever suggested).
  /// The profile owner is the SENDING TO identity; the sheet itself names who
  /// owns the wallet. A card this build cannot pay (a chain the Send sheet
  /// does not offer, a token that does not resolve) says so instead.
  Future<void> _openTip(BuildContext context, CardTip tip) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    ChainDef? chain;
    for (final c in kSendChains) {
      if (c.chainId == tip.chainId) chain = c;
    }
    TokenDef? token;
    if (chain != null) {
      if (tip.isOx) {
        if (chain.isOx) token = chain.defaultToken;
      } else if (tip.isNative) {
        for (final t in chain.tokens) {
          if (t.isNative) token = t;
        }
      } else {
        token = tokenForAddress(chain.chainId, tip.token);
        if (token == null) {
          final meta = await PublicOSWallets.resolveTokenMeta(
            chain.chainId,
            tip.token,
          );
          if (meta != null) {
            token = TokenDef(
              symbol: meta.symbol,
              decimals: meta.decimals,
              address: tip.token,
            );
          }
        }
      }
    }
    if (chain == null || token == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.tipCardBroken)));
      return;
    }
    if (!context.mounted) return;
    final owner = nftOwner;
    await showSendSheet(
      context: context,
      config: SendSheetConfig(
        targetMode: SendTargetMode.fixed,
        candidates: [
          SendCandidate(
            address: owner?.publicosAddress ?? EthereumAddress.fromHex(tip.to),
            contact: owner,
          ),
        ],
        exactTargetAddress: tip.to,
        defaultChain: chain,
        defaultToken: token,
        lockChainToken: true,
        title: l10n.tipCardSheetTitle,
        confirmLabel: l10n.tipSheetSendTip,
        confirmIcon: Icons.volunteer_activism_rounded,
      ),
    );
  }

  /// DELTA (desktop): the right-click menu on a content card in view mode --
  /// the card's action and "See image", each only when it applies. With
  /// neither there is no menu (`GlassContextMenu.show` ignores an empty list).
  void _showContentMenu(
    BuildContext context,
    ContentCard card,
    Offset position,
  ) {
    final l10n = context.l10n;
    GlassContextMenu.show(
      context,
      position: position,
      items: [
        if (card.hasTip)
          GlassContextMenuItem(
            icon: Icons.volunteer_activism_rounded,
            label: l10n.recordButtonMenuTip,
            onTap: () => _openTip(context, card.tip!),
          )
        else if (card.hasLink)
          GlassContextMenuItem(
            icon: Icons.open_in_new_rounded,
            label: l10n.recordButtonMenuOpenLink,
            onTap: () => _launchURL(context, url: card.link),
          ),
        if (card.hasImage)
          GlassContextMenuItem(
            icon: Icons.image_outlined,
            label: l10n.recordButtonMenuSeeImage,
            onTap: () => _showImageOverlay(context, imageUrl: card.image),
          ),
      ],
    );
  }

  void _showImageOverlay(BuildContext context, {String? imageUrl}) {
    // Image cards pass nothing (URL is the record value); NFT cards pass the
    // resolved art URL (the record value is the NFT pointer, not an image).
    final url = imageUrl ?? record.value;
    if (url.isEmpty) return;

    final heroTag = "record_image_${record.key}_${url.hashCode}";
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => ImageOverlay(
          imageUrl: url,
          heroTag: heroTag,
          onClose: () => Navigator.pop(context),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  TextAlign _getTextAlign(String? alignment) {
    switch (alignment) {
      case 'left':
        return TextAlign.left;
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.start;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isImageRecord = record.metadata['isImageRecord'] == true;
    // cardKind is the differentiator (parallel to image-vs-text, which is itself
    // a metadata flag). Legacy rows with no cardKind fall back through isImageRecord.
    final String cardKind =
        (record.metadata['cardKind'] as String?) ??
        (isImageRecord ? 'image' : 'text');
    final bool isNft = cardKind == 'nft';
    // App card ("web_card") — a third-party app's card, resolved in Core.
    final bool isAppCard = cardKind == 'app';
    // Pinned post: `value` is the post URL.
    final bool isPostCard = cardKind == PostCardMeta.kind;
    final String? nftImage = record.metadata['nftImage'] as String?;
    final double recordOpacity =
        (record.metadata['opacity'] as num?)?.toDouble() ??
        1.0; // Get record's opacity from metadata
    // DELTA (desktop): the plate is suppressed for the kinds whose
    // own content fills the cell, and ONLY for those.
    //
    // Why those and not all of them: the plate is what a text card is READ
    // against. `_buildTextDisplay` paints its title and body in hardcoded
    // `Colors.white` / `white70` and draws no background of its own, so taking
    // the plate away leaves white text floating on the panel — the card stops
    // being a card. On an image / NFT / app card the opposite is true: the
    // content covers the cell edge to edge and the plate is never *seen*, it
    // only leaks at the corners.
    //
    // And it does leak, by construction rather than by accident: the titled
    // image branch clips its art at `innerBorderRadius` (`record.borderRadius
    // - 2`) while this container fills at the full `record.borderRadius`, so a
    // 2px ring of plate is exposed around every corner; the untitled branch
    // matches radii and still shows an antialiased fringe. Harmless in a colour
    // the owner chose — loud when the card has no colour and the fallback below
    // supplies one. On desktop that fallback is `colorScheme.primary` =
    // `connectedAccent` `#64FFDA`, which shows as a green fringe. The client
    // binds the same expression to
    // `neonAccent` (white in dark), so it has the identical leak in a colour
    // nobody notices.
    //
    // Kinds are matched by what RENDERS, so an unknown `cardKind` keeps its
    // plate — it falls through to `_buildTextDisplay` and needs one.
    // Content cards (the merged text + image card, content_card.dart) paint
    // their own background inside their clip, so the outer plate stays off for
    // them as well.
    final ContentCard? content = ContentCard.isContent(record)
        ? ContentCard.fromRecord(record)
        : null;
    final bool contentFillsCell =
        content != null || cardKind == 'nft' || cardKind == 'app' || isPostCard;

    // The second half of the rule: **no colour means no
    // plate.** A card the owner never coloured is not a card we should invent a
    // colour for — its text simply reads against the profile background, which
    // is a deliberate look rather than a missing one.
    //
    // So the client's `?? Theme.of(context).colorScheme.primary` fallback is
    // dropped here. It is not a *card* colour: it is whatever the app binds
    // to Material's `primary`, which the two twins bind differently
    // (`connectedAccent` `#64FFDA` here, `neonAccent` white in the client), so
    // it would paint a plate nobody chose in a colour nobody picked.
    final Color? baseColor = contentFillsCell ? null : record.color;
    // A transparent card (colour alpha 0) never paints a fill — NB: don't run it
    // through baseColor.withValues(alpha: recordOpacity), which would force the
    // alpha back up (transparent → solid black). A transparent card with no
    // title and no text is a "spacer": an invisible cell the user drops in to
    // organize the grid. It paints nothing in normal mode and shows a dashed
    // outline (grabbable / editable / deletable) only in edit mode.
    final bool isTransparent = (record.color?.a ?? 1) == 0;
    final bool isSpacer = content?.isSpacer ?? false;

    // General onTap for the InkWell. Priority order:
    // 1. If editable in edit mode -> editing
    // 2. NFT card -> the shared NFT info dialog (art/ownership/traits/links),
    //    falling back to the plain image overlay until the verdict is cached
    // 3. Content card, not in edit mode -> its action: the tip sheet, else
    //    the link
    // 4. Content card with an image and no action -> show image overlay
    // 5. Otherwise -> null
    // App cards: at rest, a tap promotes the live half; in EDIT mode, a tap
    // opens the sheet -- which routes `cardKind:'app'` to a
    // size-only editor (`_Flow.appCard`), so the owner can resize a card whose
    // content is not theirs. Size is placement, and placement is the owner's.
    // The sheet refuses any kind it does not recognise, so the data-loss
    // path (a text-card form rewriting the record) is closed at the sheet,
    // not by making the card inert. Twin of the client's rule.
    final VoidCallback? primaryOnTap = isPostCard
        // Edit mode: the size-only editor (`_Flow.postCard`). View mode: the
        // card opens the post itself, so nothing here competes for the tap.
        ? (isEditMode && isEditable ? onTap : null)
        : isAppCard
        // Promote on tap ONLY while at rest. Once live the whole card belongs
        // to the page: a handler here would compete for every click, and on
        // desktop (whose platform view does not swallow taps the way mobile's
        // does) it WINS -- which would turn every click on the page into a
        // live on/off toggle. The stop control below is the only way back out.
        ? (isEditMode
            ? (isEditable ? onTap : null)
            : ((!isLive && _liveUrl != null) ? onToggleLive : null))
        : (isEditable && isEditMode)
        ? onTap
        : isNft
        ? ((nftImage != null && nftImage.isNotEmpty)
              ? () => _showNftInfo(context, nftImage)
              : null)
        : content != null
        // Content card: the card's ACTION is its tap -- the tip sheet, else the
        // link -- and the image opens full size only when there is no action.
        // Same order as the client's; otherwise the image opens by
        // click-and-hold and from the right-click menu.
        ? (isEditMode
              ? null
              : content.hasTip
              ? () => _openTip(context, content.tip!)
              : content.hasLink
              ? () => _launchURL(context, url: content.link)
              : (content.hasImage
                    ? () => _showImageOverlay(context, imageUrl: content.image)
                    : null))
        : (record.link != null ? () => _launchURL(context) : null);

    // Desktop delta: GestureDetector
    // does NOT change the pointer, so on a mouse platform a tappable card is
    // indistinguishable from a dead one. Only claim the click cursor when there
    // really is a tap action.

    // Long-press (mobile) and click-and-hold (desktop) open a content card's
    // image, whatever its tap does. View mode only: in
    // edit mode a long-press (mobile) or a drag (desktop) moves the card.
    final VoidCallback? contentLongPress =
        content != null && !isEditMode && content.hasImage
        ? () => _showImageOverlay(context, imageUrl: content.image)
        : null;

    return MouseRegion(
      cursor: primaryOnTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: primaryOnTap, // Use the determined primary tap action
        onLongPress: contentLongPress,
        // DELTA (desktop): right-click, the desktop's long-press.
        onSecondaryTapDown: content != null && !isEditMode
            ? (d) => _showContentMenu(context, content, d.globalPosition)
            : null,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isTransparent || baseColor == null
                ? Colors.transparent
                : baseColor.withValues(
                    alpha: recordOpacity,
                  ), // Apply recordOpacity to the base color
            borderRadius: BorderRadius.circular(record.borderRadius),
          ),
          child: isSpacer
              ? _buildSpacerDisplay(context)
              : switch (cardKind) {
                  'nft' => _buildNftDisplay(context),
                  'app' => _buildAppCardDisplay(context),
                  PostCardMeta.kind => _buildPostCardDisplay(context),
                  _ =>
                    content != null
                        ? _buildContentCardDisplay(context, content)
                        : _buildTextDisplay(context),
                },
        ),
      ),
    );
  }

  /// Pinned post — the live post behind `record.value` (its permalink). The
  /// card owns its own tap (open the post); edit mode swaps that for the
  /// same pencil + trash overlay every other kind wears.
  Widget _buildPostCardDisplay(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ProfilePostCard.fromRecord(record, interactive: !isEditMode),
        if (isEditable && isEditMode)
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _overlayBtn(Icons.edit_rounded, onTap),
                const SizedBox(width: 6),
                _overlayBtn(
                  Icons.delete_rounded,
                  () => _showDeleteConfirmation(context),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// NFT card — verified art sized to the card width. Presentational: the
  /// resolved image + ownership verdict are computed in `fetchContact` (against
  /// the record owner) and stashed on `record.metadata` (`nftImage`/`nftOwned`);
  /// here we just paint. Shimmer + top-left sparkles when owned.
  Widget _buildNftDisplay(BuildContext context) {
    final String? image = record.metadata['nftImage'] as String?;
    final bool owned = record.metadata['nftOwned'] == true;
    final int w = record.width;
    final double fxSize = w >= 3 ? 50.0 : (w == 2 ? 38.0 : 28.0);
    final radius = BorderRadius.circular(record.borderRadius);
    final heroTag = "record_image_${record.key}_${image.hashCode}";
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none, // let the sparkles spill past the corner
      children: [
        Hero(
          tag: heroTag,
          child: NftVerifiedArt(
            image: image,
            verifiedOwner: owned,
            borderRadius: radius,
            fxSize: fxSize,
            focusedSparkles: w >= 3,
            // Loading skeleton: shown while the art resolves (image == null) and
            // while it loads, then replaced by the image. No white card flash.
            fallback: _CardShimmer(radius: record.borderRadius),
          ),
        ),
        if (isEditable && isEditMode)
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _overlayBtn(Icons.edit_rounded, onTap),
                const SizedBox(width: 6),
                _overlayBtn(
                  Icons.delete_rounded,
                  () => _showDeleteConfirmation(context),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _overlayBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(PhigitalStyle.radiusButton),
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    ),
  );

  /// Transparent "spacer" card — a title-less, text-less, transparent card the
  /// user drops in to organize the grid. Invisible in normal mode (it only
  /// occupies its cell); in edit mode it shows a dashed outline + a hint glyph
  /// so it can be seen, grabbed, moved, and removed.
  Widget _buildSpacerDisplay(BuildContext context) {
    if (!(isEditable && isEditMode)) return const SizedBox.expand();
    final tokens = GlassTokens.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: DashedRoundedRectPainter(
            color: tokens.borderMedium,
            strokeWidth: 1,
            radius: record.borderRadius,
            dashLength: 6,
            gapLength: 4,
          ),
          child: Center(
            child: Icon(Icons.space_bar, size: 18, color: tokens.textDim),
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _overlayBtn(Icons.edit_rounded, onTap),
              const SizedBox(width: 6),
              _overlayBtn(
                Icons.delete_rounded,
                () => _showDeleteConfirmation(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Resolve a human-readable title for any record.
  /// Card records store their title in metadata['name']; social records use the
  /// platform display-name map; everything else falls back to the raw key.
  String _displayTitle(Record r) {
    final metaName = r.metadata['name'] as String?;
    if (metaName != null && metaName.isNotEmpty) return metaName;
    return socialDisplayName(r.key);
  }

  Widget _buildTextDisplay(BuildContext context) {
    final fontFamily =
        record.profileSubtype == ProfileSubtype.card ||
            record.profileSubtype == ProfileSubtype.social
        ? record.textElementFontFamily
        : null;
    final fontSize =
        record.profileSubtype == ProfileSubtype.card ||
            record.profileSubtype == ProfileSubtype.social
        ? record.textElementFontSize
        : null;
    final textAlign =
        record.profileSubtype == ProfileSubtype.card ||
            record.profileSubtype == ProfileSubtype.social
        ? _getTextAlign(record.textElementAlignment)
        : TextAlign.start;
    final bool hasLink = record.link != null && record.link!.isNotEmpty;
    final bool isCard = record.profileSubtype == ProfileSubtype.card;
    final String title = _displayTitle(record);

    final titleSize =
        fontSize?.toDouble() ??
        (record.width == 1
            ? 12.0
            : record.width == 2
            ? 14.0
            : record.width == 3
            ? 16.0
            : 20.0);
    final valueSize = record.width == 1
        ? 8.0
        : record.width == 2
        ? 10.0
        : record.width == 3
        ? 12.0
        : 14.0;

    return Stack(
      children: [
        // Title top-left for card records
        if (isCard && !record.noTitle)
          Positioned(
            top: 8,
            left: 8,
            right: hasLink ? 30 : 8,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        // Value text centered for card records
        // Mentions: a text card's body renders `@[0xAddr]` tokens as tappable names.
        if (isCard)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: MentionText(
                record.value,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: valueSize,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        // Social / non-card records: original centered layout
        if (!isCard)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: textAlign == TextAlign.left
                    ? CrossAxisAlignment.start
                    : textAlign == TextAlign.center
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: textAlign,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (record.value.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.value,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: valueSize,
                        color: Colors.white70,
                      ),
                      textAlign: textAlign,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        // Icon overlay — branded social icon if available, else MaterialIcons fallback
        if (socialIconForKey(
                  record.key,
                  size: record.width == 1 ? 18.0 : 22.0,
                ) !=
                null ||
            record.icon != null)
          Positioned(
            top: 8,
            left: 8,
            child:
                socialIconForKey(
                  record.key,
                  size: record.width == 1 ? 18.0 : 22.0,
                ) ??
                Icon(
                  IconData(record.icon!, fontFamily: 'MaterialIcons'),
                  size: record.width == 1 ? 20 : 24,
                  color: Colors.white,
                ),
          ),
        // Open link indicator
        if (hasLink && !(isEditable && isEditMode))
          Positioned(
            top: 6,
            right: 6,
            child: Icon(
              Icons.open_in_new_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        // Edit/Delete buttons overlay - positioned at bottom right
        if (isEditable && isEditMode)
          Positioned(
            bottom: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(
                        PhigitalStyle.radiusButton,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _showDeleteConfirmation(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(
                        PhigitalStyle.radiusButton,
                      ),
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// App card ("web_card") — an image authored by a registered third-party app.
  ///
  /// Twin of `publicos_client`'s `_buildAppCardDisplay`; keep them in step.
  ///
  /// Purely presentational: `PublicOSContacts._resolveAndVerifyAppCards` already
  /// did the trust walk on this device (app registered → `card_origin` declared
  /// → both URLs under it) and stamped the verdict onto the record. Nothing here
  /// re-derives trust, and nothing here reads `record.value` — a `broken` card
  /// deliberately carries no image URL in its metadata, so there is nothing to
  /// paint even by accident.
  ///
  /// v0 renders the card AT REST only. `ok` and `imageOnly` look identical
  /// because nothing is promotable yet. The live half is no longer blocked --
  /// `PublicOSWebView.sandboxed` exists and app cards pass `true` -- it just is
  /// not built here yet.
  ///
  /// No ownership affordance, on purpose: the trust walk proves **authorship**,
  /// not possession. The app's name is the true and complete claim.
  Widget _buildAppCardDisplay(BuildContext context) {
    final String? image = record.metadata[AppCardMeta.image] as String?;
    final String slug = record.metadata[AppCardMeta.appSlug] as String? ?? '';
    final String? live = _liveUrl;
    final originRaw = record.metadata[AppCardMeta.origin] as String?;
    final Uri? originUri = originRaw == null ? null : Uri.tryParse(originRaw);
    final radius = BorderRadius.circular(record.borderRadius);

    // WHO GETS TOLD SOMETHING IS WRONG:
    //   unsolicited degradation is silent · degradation you asked for is
    //   reported · your own profile always tells you.
    // A visitor is not shown that some app revoked its origin — that is the
    // app's business and the owner's, and the silence is what makes revocation
    // graceful. But a tap is a question, and the owner can actually FIX a
    // broken card.
    final bool degraded = record.metadata[AppCardMeta.degraded] == true;
    final String? verdict = record.metadata[AppCardMeta.verdict] as String?;
    final bool showDegraded =
        ((degraded || verdict == 'broken') && isEditable) || liveFailed;

    // `broken` does NOT early-return: the placeholder is just a different base
    // layer, so the attribution bar still renders and names the app. A bare
    // broken-image glyph is indistinguishable from a failed download and tells
    // the owner nothing they can act on.
    final bool noContent = image == null || image.isEmpty;

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (noContent)
            _brokenImageWidget(context)
          else
            ZeroCachedImage(
              imageUrl: image,
              fit: BoxFit.cover,
              placeholder: (_, __) => _CardShimmer(radius: record.borderRadius),
              errorWidget: (context, error, stackTrace) =>
                  _brokenImageWidget(context),
            ),
          // The live half, composited OVER the image, which keeps painting
          // underneath: mounting shows the image, a failed load shows the
          // image, and demoting is removing this child.
          if (isLive && live != null)
            Positioned.fill(
              // Keyed, and not decoratively: this frame and the attribution bar
              // below are BOTH `Positioned`, so when the frame is removed on
              // demote, Flutter can match the bar against the frame's element
              // slot. A key pins each to its own element and makes the frame's
              // removal unambiguous -- which is what guarantees its `dispose`
              // (and the about:blank teardown inside it) actually runs.
              key: ValueKey('appcard-live-${record.key}'),
              child: PublicOSWebView(
                initialUrl: live,
                cardMode: true,
                sandboxed: true,
                allowedOrigin: originUri,
                onOffOriginNavigation: (url) => _launchURL(context, url: url),
                onError: (_) => onLiveFailed?.call(),
              ),
            ),
          if (slug.isNotEmpty && !(isEditable && isEditMode))
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 10, 4, 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: IgnorePointer(
                        child: Text(
                          slug,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 0.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // Informational only, so it must not take a pointer: while
                    // live, everything in this bar except the stop control has
                    // to fall through to the page underneath.
                    if (showDegraded)
                      const IgnorePointer(
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Icon(Icons.link_off_rounded,
                              size: 13, color: Colors.white54),
                        ),
                      ),
                    // Must be a real hit target when live: the frame above
                    // covers the whole card and a platform view consumes every
                    // pointer, so the card's own tap handler can never fire
                    // again. Without this, a promoted card has no way back.
                    if (live != null)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onToggleLive,
                        child: SizedBox(
                          // 44x44 while live: with the page swallowing every
                          // other tap this is the ONLY way back to the image,
                          // so it gets a real touch target rather than the
                          // glyph's own bounds. At rest the whole card is
                          // tappable, so it only needs to look right.
                          width: isLive ? 44 : 28,
                          height: isLive ? 44 : 28,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: isLive
                                  ? BoxDecoration(
                                      // The page underneath can be any colour;
                                      // a bare white glyph disappears on a light
                                      // one. The backing is what keeps the exit
                                      // findable.
                                      color: Colors.black.withValues(alpha: 0.55),
                                      shape: BoxShape.circle,
                                    )
                                  : null,
                              child: Icon(
                                isLive
                                    ? Icons.stop_rounded
                                    : Icons.play_circle_outline,
                                size: isLive ? 18 : 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          // Pencil + trash, the same pair every other kind wears. The pencil
          // is the visible route into the size-only editor (`_Flow.appCard`);
          // the whole-card tap also opens it, but a live frame swallows that
          // tap on mobile, so the button is the one route that always works.
          if (isEditable && isEditMode)
            Positioned(
              bottom: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _overlayBtn(Icons.edit_rounded, onTap),
                  const SizedBox(width: 6),
                  _overlayBtn(
                    Icons.delete_rounded,
                    () => _showDeleteConfirmation(context),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _brokenImageWidget(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white, size: 40),
      ),
    );
  }

  /// A content card's body in the box it was given: as many whole lines as fit
  /// at [size], then an ellipsis. Never fewer than one line.
  Widget _fittedBody(String text, double size, String? fontFamily,
      TextAlign align, Alignment alignment) {
    return LayoutBuilder(builder: (context, c) {
      final double lineH = size * 1.25;
      final int lines = c.maxHeight.isFinite
          ? max(1, (c.maxHeight / lineH).floor())
          : 3;
      return Align(
        alignment: alignment,
        child: Text(
          text,
          textAlign: align,
          maxLines: lines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: size,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    });
  }

  /// Content card (content_card.dart): the merged text + image card.
  ///
  /// Layers, back to front: the image, OR the gradient, OR the colour plate
  /// (never a plate under an image: two layers clipped at one radius leave a
  /// coloured fringe at the corners); a scrim only when text sits on an image;
  /// the body centred on the card whether or not there is a title; the title
  /// pinned top and centred; the link glyph in its own hit area. Tap rules
  /// live in `build`.
  Widget _buildContentCardDisplay(BuildContext context, ContentCard card) {
    final int w = record.width.clamp(1, 4);
    final fontFamily = record.textElementFontFamily;
    final bool showLink = card.hasLink && !(isEditable && isEditMode);
    final Color? color = card.color;
    return ClipRRect(
      borderRadius: BorderRadius.circular(record.borderRadius),
      child: LayoutBuilder(builder: (context, constraints) {
        // Type and marks scale with the CELL, not with the screen. The
        // per-width sizes below are the phone's, where one cell is ~88 px; a
        // 720 px desktop pane or the website gives a cell twice that, so
        // unscaled, the same 14 pt title would sit on a 180 px card and read
        // really small. Scale = cell / 88, floored at the phone sizes and
        // capped at 2×. The website applies the same rule (`--cs`), so a card
        // reads the same on every host.
        final double cell = constraints.maxWidth.isFinite
            ? (constraints.maxWidth - 4 * (w - 1)) / w
            : 88;
        final double s = (cell / 88).clamp(1.0, 2.0);
        // The tip mark grows at half the type's rate (at the full scale it
        // reads overdone on the desktop pane).
        final double ms = 1 + (s - 1) / 2;
        final double titleSize =
            (record.textElementFontSize ?? const [14.0, 17.0, 19.0, 23.0][w - 1]) * s;
        // The small bold label a title becomes when the card also has a body,
        // and the body's hero size. Both step with the card's width like titleSize.
        final double labelSize = const [10.0, 11.0, 12.0, 12.0][w - 1] * s;
        final double heroSize = const [12.0, 15.0, 17.0, 19.0][w - 1] * s;
        return Stack(
        fit: StackFit.expand,
        children: [
          if (card.hasImage)
            Hero(
              tag: "record_image_${record.key}_${card.image.hashCode}",
              child: Opacity(
                // The card's opacity fades its image too (Image is one of
                // the three background modes, and the slider applies).
                opacity: card.opacity.clamp(0.0, 1.0),
                child: ZeroCachedImage(
                  imageUrl: card.image!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      _CardShimmer(radius: record.borderRadius),
                  errorWidget: (context, _, __) => _brokenImageWidget(context),
                ),
              ),
            )
          else if (card.gradient != null)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient:
                    card.gradient!.toLinearGradient(opacity: card.opacity),
              ),
            )
          else if (color != null && color.a > 0)
            ColoredBox(color: color.withValues(alpha: card.opacity)),
          if (card.hasImage && (card.hasTitle || card.hasBody))
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x80000000),
                    Color(0x26000000),
                    Color(0x8C000000),
                  ],
                  stops: [0, 0.42, 1],
                ),
              ),
            ),
          // Text layout (twin of publicos_client):
          //  - title + body: the title is a small bold LABEL top-left, the body
          //    is the hero below it, as many lines as fit, then an ellipsis.
          //    The body has its own box, so it can never draw over the label.
          //  - title only: the title IS the content, big and centred.
          //  - body only: centred, at hero size.
          if (card.hasTitle && card.hasBody) ...[
            Positioned(
              top: 8,
              left: 10,
              right: showLink ? 30 : 10,
              child: Text(
                card.title.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: labelSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  color: Colors.white70,
                ),
              ),
            ),
            Positioned.fill(
              top: 8 + labelSize * 1.4 + 4,
              left: 10,
              right: 10,
              bottom: card.hasTip ? 34 * ms : 8,
              child: _fittedBody(card.body.trim(), heroSize, fontFamily,
                  TextAlign.left, Alignment.centerLeft),
            ),
          ] else if (card.hasTitle)
            Positioned.fill(
              left: showLink ? 30 : 10,
              right: showLink ? 30 : 10,
              top: 6,
              bottom: card.hasTip ? 34 * ms : 6,
              child: Center(
                child: Text(
                  card.title.trim(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else if (card.hasBody)
            Positioned.fill(
              left: 10,
              right: 10,
              top: 8,
              bottom: card.hasTip ? 34 * ms : 8,
              child: _fittedBody(card.body.trim(), heroSize, fontFamily,
                  TextAlign.center, Alignment.center),
            ),
          // The tip marker: the post tip button's glyph in a
          // borderless circle, bottom-left, clear of the edit buttons. Only a
          // marker: the whole card is the control.
          if (card.hasTip)
            Positioned(
              left: 6 * ms,
              bottom: 6 * ms,
              child: IgnorePointer(
                child: Container(
                  width: 24 * ms,
                  height: 24 * ms,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                  child: Icon(
                    Icons.volunteer_activism_rounded,
                    size: 13 * ms,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          if (showLink)
            Positioned(
              top: 0,
              right: 0,
              child: _LinkHitArea(
                onTap: () => _launchURL(context, url: card.link),
              ),
            ),
          if (isEditable && isEditMode)
            Positioned(
              bottom: 4,
              right: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _overlayBtn(Icons.edit_rounded, onTap),
                  const SizedBox(width: 6),
                  _overlayBtn(Icons.delete_rounded,
                      () => _showDeleteConfirmation(context)),
                ],
              ),
            ),
        ],
        );
      }),
    );
  }
}

/// A content card's link glyph as a control of its own: the same 14 px glyph,
/// drawn where it always sat (6 px in from the top-right corner), inside a
/// 40 px transparent target a finger can find. Opaque, so a tap here never
/// falls through to the card's own tap (the image overlay) underneath.
class _LinkHitArea extends StatelessWidget {
  final VoidCallback onTap;

  const _LinkHitArea({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 6, right: 6),
              child: Icon(
                Icons.open_in_new_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-bleed loading skeleton for a record card — the canonical [ShimmerBox]
/// sweep (same as the trust-tree / onboarding account-card skeleton) sized to
/// fill the card. Sits BEHIND the card content so it shows while an image / NFT
/// art resolves and is covered the moment the final image paints over it. Hosts
/// its own repeating controller (the card content is otherwise presentational).
class _CardShimmer extends StatefulWidget {
  final double radius;
  const _CardShimmer({required this.radius});

  @override
  State<_CardShimmer> createState() => _CardShimmerState();
}

class _CardShimmerState extends State<_CardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return ShimmerBox(
      progress: _c,
      width: double.infinity,
      height: double.infinity,
      radius: widget.radius,
      base: tokens.surfaceElevated,
      highlight: Color.alphaBlend(
        tokens.starkWhite.withValues(alpha: 0.10),
        tokens.surfaceElevated,
      ),
    );
  }
}
