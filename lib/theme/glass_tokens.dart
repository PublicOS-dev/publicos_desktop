import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Desktop glass-dark design tokens.
///
/// Authored fresh for publicos_desktop — same aesthetic family as the mobile
/// client's glass system (so the ecosystem reads as one product) but tuned for
/// desktop: denser surfaces, explicit hover/border states for a mouse, larger
/// canvases. NOT imported from publicos_client — this is a deliberately
/// separate app with its own organization.
///
/// Read via `GlassTokens.of(context)` inside a `build`.
class GlassTokens extends ThemeExtension<GlassTokens> {
  final Color background;
  final Color surfaceDeep;
  final Color surfaceElevated;
  final Color starkWhite;
  final Color textDim;
  final Color borderSubtle;
  final Color borderMedium;
  final Color glassFill;
  final Color glassFillHover;
  final Color glassShadow;

  /// "Connected / verified" accent (teal). Maps onto the keychain
  /// connected-vs-not semantics the desktop already uses.
  final Color connectedAccent;

  /// "Pending / fallback" accent (amber). Pending keys, warnings.
  final Color fallbackAccent;

  /// Soft "remove / destructive" red — chip X badges, remove affordances.
  /// Deliberately muted (never the theme errorColor) so it reads as a quiet
  /// control, not an alarm.
  final Color softDanger;

  const GlassTokens({
    required this.background,
    required this.surfaceDeep,
    required this.surfaceElevated,
    required this.starkWhite,
    required this.textDim,
    required this.borderSubtle,
    required this.borderMedium,
    required this.glassFill,
    required this.glassFillHover,
    required this.glassShadow,
    required this.connectedAccent,
    required this.fallbackAccent,
    required this.softDanger,
  });

  static const GlassTokens dark = GlassTokens(
    background: Color(0xFF030303),
    surfaceDeep: Color(0xFF0A0A0A),
    surfaceElevated: Color(0xFF141414),
    starkWhite: Color(0xFFFFFFFF),
    textDim: Color(0x99FFFFFF),
    borderSubtle: Color(0x1AFFFFFF),
    borderMedium: Color(0x33FFFFFF),
    glassFill: Color(0x0AFFFFFF),
    glassFillHover: Color(0x14FFFFFF),
    glassShadow: Color(0x80000000),
    connectedAccent: Color(0xFF64FFDA),
    fallbackAccent: Color(0xFFFFAB40),
    softDanger: Color(0xFFD25C5C),
  );

  /// Near-white mirror — same structural tokens so widgets never branch on
  /// brightness. Kept so the existing light/dark toggle keeps working.
  static const GlassTokens light = GlassTokens(
    background: Color(0xFFF5F6F8),
    surfaceDeep: Color(0xFFEEEFF2),
    surfaceElevated: Color(0xFFFFFFFF),
    starkWhite: Color(0xFF0A0A0A),
    textDim: Color(0x99000000),
    borderSubtle: Color(0x14000000),
    borderMedium: Color(0x29000000),
    glassFill: Color(0x0A000000),
    glassFillHover: Color(0x14000000),
    glassShadow: Color(0x1A000000),
    connectedAccent: Color(0xFF0D9488),
    fallbackAccent: Color(0xFFD97706),
    softDanger: Color(0xFFB54747),
  );

  static GlassTokens of(BuildContext context) =>
      Theme.of(context).extension<GlassTokens>() ?? dark;

  @override
  GlassTokens copyWith({
    Color? background,
    Color? surfaceDeep,
    Color? surfaceElevated,
    Color? starkWhite,
    Color? textDim,
    Color? borderSubtle,
    Color? borderMedium,
    Color? glassFill,
    Color? glassFillHover,
    Color? glassShadow,
    Color? connectedAccent,
    Color? fallbackAccent,
    Color? softDanger,
  }) {
    return GlassTokens(
      background: background ?? this.background,
      surfaceDeep: surfaceDeep ?? this.surfaceDeep,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      starkWhite: starkWhite ?? this.starkWhite,
      textDim: textDim ?? this.textDim,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderMedium: borderMedium ?? this.borderMedium,
      glassFill: glassFill ?? this.glassFill,
      glassFillHover: glassFillHover ?? this.glassFillHover,
      glassShadow: glassShadow ?? this.glassShadow,
      connectedAccent: connectedAccent ?? this.connectedAccent,
      fallbackAccent: fallbackAccent ?? this.fallbackAccent,
      softDanger: softDanger ?? this.softDanger,
    );
  }

  @override
  GlassTokens lerp(ThemeExtension<GlassTokens>? other, double t) {
    if (other is! GlassTokens) return this;
    return GlassTokens(
      background: Color.lerp(background, other.background, t)!,
      surfaceDeep: Color.lerp(surfaceDeep, other.surfaceDeep, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      starkWhite: Color.lerp(starkWhite, other.starkWhite, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderMedium: Color.lerp(borderMedium, other.borderMedium, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassFillHover: Color.lerp(glassFillHover, other.glassFillHover, t)!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
      connectedAccent: Color.lerp(connectedAccent, other.connectedAccent, t)!,
      fallbackAccent: Color.lerp(fallbackAccent, other.fallbackAccent, t)!,
      softDanger: Color.lerp(softDanger, other.softDanger, t)!,
    );
  }
}

/// Glass surface helpers. `GlassTheme.glassBox(context)` is the canonical
/// elevated-panel decoration (fill + subtle border + soft shadow).
class GlassTheme {
  static BoxDecoration glassBox(
    BuildContext context, {
    double radius = 16,
    bool hover = false,
  }) {
    final t = GlassTokens.of(context);
    return BoxDecoration(
      color: hover ? t.glassFillHover : t.glassFill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: t.borderSubtle),
      boxShadow: [
        BoxShadow(
          color: t.glassShadow,
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}

// ── Theme assembly ──────────────────────────────────────────────────────────

/// Global theme notifier — no Provider needed.
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

Future<void> loadThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('theme_mode') ?? true;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
}

Future<void> toggleTheme() async {
  final isDark = themeNotifier.value == ThemeMode.dark;
  themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('theme_mode', !isDark);
}

ThemeData _buildTheme(GlassTokens t, Brightness brightness) {
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    // Brand font everywhere. Per-widget monospace (addresses,
    // hashes) still overrides via fontFamily: 'monospace'.
    fontFamily: 'SpaceGrotesk',
  );
  return base.copyWith(
    scaffoldBackgroundColor: t.background,
    canvasColor: t.background,
    colorScheme: base.colorScheme.copyWith(
      primary: t.connectedAccent,
      secondary: t.fallbackAccent,
      surface: t.surfaceElevated,
    ),
    extensions: [t],
    // A bare AlertDialog (no backgroundColor of its own, e.g. record_button's
    // delete confirm) renders the way it does on mobile. The
    // client gets this from its ColorScheme (surface = surfaceDeep, which M3
    // dialogs read as surfaceContainerHigh, and onSurfaceVariant = onSurface);
    // here the scheme keeps the M3 defaults, so the dialog is themed directly.
    dialogTheme: DialogThemeData(
      backgroundColor: t.surfaceDeep,
      surfaceTintColor: Colors.transparent,
      titleTextStyle:
          base.textTheme.headlineSmall?.copyWith(color: t.starkWhite),
      contentTextStyle:
          base.textTheme.bodyMedium?.copyWith(color: t.starkWhite),
    ),
    // Ported from the client's glass_theme: without it a SnackBar that sets a
    // dark backgroundColor keeps M3's default dark content colour and is
    // unreadable. Same block as mobile.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: t.surfaceElevated,
      contentTextStyle: TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: t.starkWhite,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
      actionTextColor: t.starkWhite,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: t.borderSubtle, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 48,
        vertical: 24,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: t.connectedAccent,
      selectionColor: t.connectedAccent.withValues(alpha: 0.3),
    ),
  );
}

ThemeData buildDarkTheme() => _buildTheme(GlassTokens.dark, Brightness.dark);
ThemeData buildLightTheme() => _buildTheme(GlassTokens.light, Brightness.light);

/// Dialog widths. Every one is a MAX
/// width; narrow windows shrink it. S confirm · M form / picker / reveal ·
/// L settings / readers · XL editors / managers · W a window inside the window.
class DialogWidth {
  static const double s = 400;
  static const double m = 480;
  static const double l = 560;
  static const double xl = 720;
  static const double w = 900;

  /// Flutter's own floor for a dialog (`BoxConstraints(minWidth: 280)`).
  /// Setting `constraints:` on an AlertDialog replaces that default, so the
  /// AlertDialog sites pass it back alongside their max.
  static const double min = 280;
}
