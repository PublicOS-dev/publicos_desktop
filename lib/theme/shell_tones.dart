import 'package:flutter/material.dart';

/// Desktop shell tonal ladder.
///
/// The shell paints one canvas that owns the whole window (title bar included,
/// via the DWM caption tint in `utils/window_chrome.dart`) and floats the rail,
/// panels and status bar on it as rounded guests. Surfaces step tone-by-tone
/// toward the content panel — darkening inward in dark mode, brightening
/// inward in light mode — so the content panel is always the stage.
///
/// This is a desktop-shell-specific mapping layered OVER [GlassTokens]; it is
/// deliberately NOT part of the token set. Widgets inside the panels keep
/// reading their token roles (which assume canvas-darkest, like the client);
/// only the shell frame reads these.
class ShellTones {
  /// Window canvas + native title bar (DWM caption color).
  final Color canvas;

  /// Rail + status bar — the quiet chrome, one step in from the canvas.
  final Color chrome;

  /// List panel fill.
  final Color list;

  /// Content panel — the stage. Matches GlassTokens.background so ported
  /// widgets that paint `tokens.background` inside the panel stay seamless.
  final Color content;

  const ShellTones({
    required this.canvas,
    required this.chrome,
    required this.list,
    required this.content,
  });

  static const ShellTones dark = ShellTones(
    canvas: Color(0xFF141414),
    chrome: Color(0xFF0F0F0F),
    list: Color(0xFF0A0A0A),
    content: Color(0xFF030303),
  );

  /// Mirrored ladder: brightens inward so the content panel is the lightest
  /// surface (a dark stage on a light canvas would invert the hierarchy).
  static const ShellTones light = ShellTones(
    canvas: Color(0xFFE4E6EA),
    chrome: Color(0xFFEBEDF0),
    list: Color(0xFFF2F3F5),
    content: Color(0xFFFAFBFC),
  );

  static ShellTones of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? light : dark;
}

/// Shell frame metrics, single source so rail/panels/status bar agree.
abstract final class ShellMetrics {
  /// Gap between floating surfaces and against the window edges.
  static const double gap = 10.0;

  /// Corner radius of every floating surface.
  static const double radius = 16.0;

  /// Rail collapsed width (icons only) — reserved in the shell Row; the rail
  /// overlays PAST this width when hover-expanded, never pushing layout.
  static const double railWidth = 52.0;

  /// Rail hover-expanded width.
  static const double railWidthOpen = 220.0;

  /// Status bar height.
  static const double statusBarHeight = 30.0;
}
