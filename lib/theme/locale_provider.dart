import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-shell language preference.
///
/// Mirrors [ThemeProvider]: a device-global, boot-time, pre-auth preference
/// stored in [SharedPreferences] — deliberately NOT `PublicOSSettings`, which
/// is account-scoped + drift-DB-backed (keyed by sessionAddr) and therefore
/// unavailable at first frame and on the account-selection screen, where the
/// chrome must already be localized.
///
/// Resolution (see the `MaterialApp.router` wiring in main.dart):
///   * [locale] == null  -> follow the device language; Flutter falls back to
///     `AppLocalizations.supportedLocales.first` (== `en`) when the device
///     language isn't one we ship. This is "System default".
///   * [locale] != null  -> the user's explicit Settings override; wins over
///     the device language.
class LocaleProvider with ChangeNotifier {
  /// Live instance, set in main.dart so screens (e.g. the Settings language
  /// picker) can reach it — same singleton pattern as `AppStateNotifier.instance`.
  static LocaleProvider? instance;

  static const String _localeKey = 'app_locale';

  /// Language codes the app ships. Keep in lockstep with
  /// `AppLocalizations.supportedLocales` and `lib/l10n/app_*.arb`.
  static const List<String> supportedLanguageCodes = <String>['en', 'es'];

  Locale? _locale; // null => follow device (System default)

  LocaleProvider() {
    _load();
  }

  /// Feed into `MaterialApp.locale`. `null` => device resolution / EN fallback.
  Locale? get locale => _locale;

  /// True when no explicit override is set (following the device language).
  bool get isSystemDefault => _locale == null;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null && supportedLanguageCodes.contains(code)) {
      _locale = Locale(code);
    }
    notifyListeners();
  }

  /// Set an explicit language, or pass `null` for "System default" (clears the
  /// override and follows the device again). Unsupported codes are ignored.
  Future<void> setLocale(Locale? locale) async {
    final code = locale?.languageCode;
    if (code != null && !supportedLanguageCodes.contains(code)) return;
    _locale = code == null ? null : Locale(code);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, code);
    }
  }
}
