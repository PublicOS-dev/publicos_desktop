import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Material Symbols `sticker` and `sticker_add`.
///
/// Neither ships in Flutter's bundled Material Icons font, so they follow the
/// same zero-asset pattern as `send_icon.dart` / `chain_icon.dart` /
/// `crypto_icon.dart`: the glyph's inline SVG geometry (`0 -960 960 960`
/// viewBox, the Material Symbols canvas) rendered via `SvgPicture.string` and
/// tinted through a `srcIn` filter, so one path serves every size and color.
///
/// Paths are verbatim from `google/material-design-icons`
/// (`symbols/web/<name>/materialsymbolsoutlined/<name>_24px.svg`), Outlined
/// FILL@0 wght@400 GRAD@0 opsz@24 — do not hand-edit them.

/// The peeling-corner sticker mark. Opens the composer's sticker panel.
class StickerIcon extends StatelessWidget {
  final double size;
  final Color color;

  const StickerIcon({super.key, this.size = 24, required this.color});

  static const String _svg =
      '<svg xmlns="http://www.w3.org/2000/svg" height="24" '
      'viewBox="0 -960 960 960" width="24">'
      '<path d="M460-360q69 0 120-45t60-113l-320 90q26 32 62 50t78 18ZM294-510l106-30q4-28-14-49t-46-21q-25 '
      '0-42.5 17.5T280-550q0 11 4 21t10 19Zm240-70 106-30q5-28-13.5-49T580-680q-25 0-42.5 17.5T520-620q0 '
      '11 4 21t10 19Zm106 460H200q-33 0-56.5-23.5T120-200v-560q0-33 23.5-56.5T200-840h560q33 0 56.5 '
      '23.5T840-760v440L640-120Zm-40-80v-80q0-33 23.5-56.5T680-360h80v-400H200v560h400Zm0 0Zm-400 '
      '0v-560 560Z"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// The sticker mark with a plus. "Save this sticker to my library" — used in
/// the message long-press action bar, left of Reply.
class StickerAddIcon extends StatelessWidget {
  final double size;
  final Color color;

  const StickerAddIcon({super.key, this.size = 24, required this.color});

  static const String _svg =
      '<svg xmlns="http://www.w3.org/2000/svg" height="24" '
      'viewBox="0 -960 960 960" width="24">'
      '<path d="M460-360q69 0 120-45t60-113l-320 90q26 32 62 50t78 18ZM294-510l106-30q4-28-14-49t-46-21q-25 '
      '0-42.5 17.5T280-550q0 11 4 21t10 19Zm240-70 106-30q5-28-13.5-49T580-680q-25 0-42.5 17.5T520-620q0 '
      '11 4 21t10 19Zm-54 100ZM200-120q-33 0-56.5-23.5T120-200v-560q0-33 23.5-56.5T200-840h400v80H200v560h400v-80q0-33 '
      '23.5-56.5T680-360h80v-240h80v280L640-120H200Zm400-80Zm160-480v-80h-80v-80h80v-80h80v80h80v80h-80v80h-80Z"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
