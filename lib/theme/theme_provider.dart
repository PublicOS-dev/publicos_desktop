import 'package:flutter/material.dart';

/// The publicos_client "Civic Modernism" palette constants, as consumed by the
/// ported profile tree (`record_button`, `profile_grid`, `social_strip`,
/// `nft_info_dialog`, …). Those files reference `ThemeProvider.tealPrimary` /
/// `ThemeProvider.tealLight` directly, so keeping the class name and the
/// constant names identical means they port with an import swap and no edits.
///
/// **Desktop delta:** the client's `ThemeProvider` is a `ChangeNotifier` that
/// also owns theme-mode persistence (shared_preferences) and builds `ThemeData`.
/// Desktop already owns its theming in [GlassTokens] / `glass_tokens.dart`, so
/// only the colour constants are mirrored here — no notifier, no persistence.
/// Colour values are copied verbatim from `publicos_client/lib/providers/
/// theme_provider.dart`; keep them in sync if the client's palette moves.
class ThemeProvider {
  ThemeProvider._();

  // Slate/Concrete range - maturity and structure
  static const Color slateDarkest = Color(0xFF1e2328);
  static const Color slateDark = Color(0xFF2d3339);
  static const Color slateMid = Color(0xFF4a5568);
  static const Color slateLight = Color(0xFF718096);
  static const Color slateLighter = Color(0xFFa0aec0);
  static const Color slateLightest = Color(0xFFf4f6f8);

  // International Teal - primary action, trustworthy
  static const Color tealPrimary = Color(0xFF0f766e);
  static const Color tealLight = Color(0xFF14b8a6);
  static const Color tealDark = Color(0xFF0d6b63);

  // Warm Amber - secondary accent, human connection
  static const Color amberAccent = Color(0xFFd97706);
  static const Color amberLight = Color(0xFFf59e0b);
  static const Color amberDark = Color(0xFFb45309);

  // Error. Mirrored verbatim from publicos_client's ThemeProvider (same hex,
  // same names) so ported widgets that reference it -- MediaOverlay's failed-
  // save / failed-load states -- compile untouched.
  static const Color errorLight = Color(0xFFdc2626);
  static const Color errorDark = Color(0xFFf87171);

  // Success. Same provenance and same rule as the error pair above: mirrored
  // verbatim from publicos_client so the ported widget referencing it -- the
  // profile grid's drag landing slot -- compiles untouched.
  static const Color successLight = Color(0xFF16a34a);
  static const Color successDark = Color(0xFF4ade80);

  // Alabaster/Paper - off-white backgrounds
  static const Color paperWhite = Color(0xFFfafbfc);
  static const Color paperLight = Color(0xFFf5f6f7);
  static const Color paperMid = Color(0xFFedf2f7);
}

/// Canonical radii + card surfaces, lifted verbatim from the client's
/// `theme_provider.dart` (same file, same class name) — the ported profile tree
/// reads `PhigitalStyle.radiusButton` / `radiusCard` directly.
class PhigitalStyle {
  PhigitalStyle._();

  // ── Canonical border radii ──
  static const double radiusSheet = 20.0;
  static const double radiusCard = 14.0;
  static const double radiusButton = 8.0;

  /// Icon/avatar radius as 18% of size
  static double radiusIcon(double size) => size * 0.18;

  // ── Surface colors ──
  static const Color cardBackgroundDark = Color(0xFF2a3038);
  static const Color cardBackgroundLight = Color(0xFFF8F9FB);
  static const Color cardBorderDark = Color(0xFF3d454f);
  static const Color cardBorderLight = Color(0xFFE8EAED);

  /// Deeper surface for heavy containers (e.g. select account screen)
  static const Color surfaceDeepDark = Color(0xFF15181c);

  /// Deep teal for teal-heavy containers
  static const Color tealDeep = Color(0xFF0a524c);

  static Color cardBackground(bool isDark) =>
      isDark ? cardBackgroundDark : cardBackgroundLight;

  static Color cardBorder(bool isDark) =>
      isDark ? cardBorderDark : cardBorderLight;

  // ── Shadows (verbatim from the client; wallet tree reads smallShadow,
  // inbox-id dropdown reads cardShadow) ──
  static List<BoxShadow> cardShadow(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.4)
              : const Color(0xFF1e2328).withValues(alpha: 0.06),
          offset: const Offset(0, 3),
          blurRadius: 0,
        ),
      ];

  static List<BoxShadow> smallShadow(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.8)
              : const Color(0xFF1e2328).withValues(alpha: 0.12),
          offset: const Offset(0, 2),
          blurRadius: 0,
        ),
      ];

  // ── User-selectable accent color presets (verbatim from the client; the
  // chat bubble paints these at FULL OPACITY — the swatch the user taps is
  // literally the bubble they get) ──
  static const List<Color> colorPresets = [
    // Hue sweep, snaked: families run red -> rose, and every other one is
    // listed light -> dark so the brightness carries across the boundary
    // instead of resetting, so the grid reads as a rainbow.
    // Red (dark -> light)
    Color(0xFF7f1d1d), Color(0xFFef4444), Color(0xFFfca5a5), Color(0xFFfee2e2),
    // Orange (light -> dark)
    Color(0xFFffedd5), Color(0xFFfdba74), Color(0xFFf97316), Color(0xFF7c2d12),
    // Amber (dark -> light)
    Color(0xFFf59e0b), Color(0xFFfcd34d),
    // Lime (light -> dark)
    Color(0xFFecfccb), Color(0xFFbef264), Color(0xFF84cc16), Color(0xFF365314),
    // Green (dark -> light)
    Color(0xFF14532d), Color(0xFF22c55e), Color(0xFF86efac), Color(0xFFdcfce7),
    // Teal (light -> dark)
    Color(0xFF5eead4), Color(0xFF14b8a6), Color(0xFF134e4a),
    // Cyan (dark -> light)
    Color(0xFF164e63), Color(0xFF06b6d4), Color(0xFF67e8f9), Color(0xFFcffafe),
    // Blue (light -> dark)
    Color(0xFFdbeafe), Color(0xFF93c5fd), Color(0xFF3b82f6), Color(0xFF1e3a8a),
    // Indigo (dark -> light)
    Color(0xFF6366f1), Color(0xFFa5b4fc),
    // Violet (light -> dark)
    Color(0xFF8b5cf6), Color(0xFF4c1d95),
    // Fuchsia (dark -> light)
    Color(0xFF701a75), Color(0xFFd946ef), Color(0xFFf0abfc), Color(0xFFfae8ff),
    // Pink (light -> dark)
    Color(0xFFf9a8d4), Color(0xFFec4899), Color(0xFF831843),
    // Rose (dark -> light)
    Color(0xFFf43f5e),
    // Neutrals, dim -> bright
    Color(0xFF1e293b), Color(0xFF475569), Color(0xFF64748b),
    Color(0xFF94a3b8), Color(0xFFf8fafc),
  ];

  // ── Subtle surface tints for nested elements ──
  static Color subtleTint(bool isDark) => isDark
      ? Colors.black.withValues(alpha: 0.15)
      : const Color(0xFF1e2328).withValues(alpha: 0.03);

  static Color subtleBorder(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : const Color(0xFF1e2328).withValues(alpha: 0.06);
}
