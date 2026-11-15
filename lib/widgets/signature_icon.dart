import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The signature mark — a hand-drawn flourish over a ruled line.
///
/// Flutter's bundled `Icons` font has **no signature glyph**: the one everybody
/// means lives in Material *Symbols*, which is a different, newer font than the
/// Material *Icons* Flutter ships. So this is an inline Material-Symbols-geometry
/// SVG (`0 -960 960 960` viewBox) rendered via `SvgPicture.string` — exactly the
/// zero-asset pattern `send_icon.dart` / `chain_icon.dart` / `crypto_icon.dart`
/// already use. Tinted to [color] with a `srcIn` filter, so one glyph serves
/// every size and colour.
///
/// Used by the signature-request sheet for the "sign this data" requests
/// (`personalSign` / `ethSign` / `signTypedData`), rather than
/// `Icons.edit_document` — a page-with-a-pencil that reads as "edit a file",
/// not "put your name to this".
class SignatureIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SignatureIcon({super.key, this.size = 24, required this.color});

  static const String _svg =
      '<svg xmlns="http://www.w3.org/2000/svg" height="24" '
      'viewBox="0 -960 960 960" width="24">'
      '<path d="'
      'M563-491q73-54 114-118.5T718-738q0-32-10.5-47T679-800'
      'q-47 0-83 79.5T560-541q0 14 .5 26.5T563-491Z'
      'M120-120v-80h80v80h-80Z'
      'm160 0v-80h80v80h-80Z'
      'm160 0v-80h80v80h-80Z'
      'm160 0v-80h80v80h-80Z'
      'm160 0v-80h80v80h-80Z'
      'M136-280l-56-56 64-64-64-64 56-56 64 64 64-64 56 56-64 64 64 6'
      '4-56 56-64-64-64 64Z'
      'm482-40q-30 0-55-11.5T520-369q-25 14-51.5 25T414-322l-28-75'
      'q28-10 53.5-21.5T489-443q-5-22-7.5-48t-2.5-56'
      'q0-144 57-238.5T679-880q52 0 85 38.5T797-734'
      'q0 86-54.5 170T591-413q7 7 14.5 10.5T621-399'
      'q26 0 60.5-33t62.5-87l73 34q-7 17-11 41t1 42'
      'q10-5 23.5-17t27.5-30l63 49q-26 36-60 58t-63 22'
      'q-21 0-37.5-12.5T733-371q-28 25-57 38t-58 13Z'
      '"/>'
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
