import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The PublicOS "send" mark — two coins with a forward arrow. Material's icon
/// pack has no exact match, so it's an inline Material-Symbols-geometry SVG
/// (`0 -960 960 960` viewBox) rendered via `SvgPicture.string` — the same
/// zero-asset pattern `chain_icon.dart` / `crypto_icon.dart` use. Tinted to
/// [color] via a `srcIn` filter so one glyph serves every size/color.
///
/// Shared across the app: the wallet card's Send action + the chat input's
/// "Send" attach option, so "send money" reads identically everywhere.
class SendCoinsIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SendCoinsIcon({super.key, this.size = 24, required this.color});

  static const String _svg =
      '<svg xmlns="http://www.w3.org/2000/svg" height="24" '
      'viewBox="0 -960 960 960" width="24">'
      '<path d="M240-170Q136-197 68-282T0-480q0-113 68-198t172-112v84q-71 24-115.5 '
      '86T80-480q0 78 44.5 140T240-254v84Zm320 10q-133 0-226.5-93.5T240-480q0-133 '
      '93.5-226.5T560-800q66 0 124 25t102 69l-56 56q-33-33-76.5-51.5T560-720q-100 '
      '0-170 70t-70 170q0 100 70 170t170 70q50 0 93.5-18.5T730-310l56 56q-44 44-102 '
      '69t-124 25Zm240-160-56-56 64-64H520v-80h288l-64-64 56-56 160 160-160 160Z"/>'
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
