import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local shell layout preferences.
///
/// SharedPreferences, not Core's `PublicOSSettings`: like `theme_mode`, these
/// are per-device window-chrome concerns that must be readable before login
/// and shouldn't travel with the account.
class ShellPrefs {
  ShellPrefs._();

  static const String _kStatusBarTop = 'status_bar_top';
  static const String _kAutoplayCards = 'autoplay_app_cards';

  /// Status bar docked at the top edge instead of the bottom. The default is
  /// TOP for a new install; someone who already
  /// picked a side keeps it.
  /// The shell root is `Column[Row[rail, panes], StatusBar]`, so this only
  /// reorders the Column's children — by design.
  static final ValueNotifier<bool> statusBarTop = ValueNotifier<bool>(true);

  /// Run every interactive app card as soon as a profile opens, instead of
  /// waiting for a tap.
  ///
  /// Desktop only, and OFF by default. The restriction it lifts exists because
  /// of a memory ceiling that has never actually been measured — so this is
  /// offered where there is headroom to absorb being wrong, and withheld on
  /// mobile where there is not. See `LivePolicy` in publicos_core.
  static final ValueNotifier<bool> autoplayCards = ValueNotifier<bool>(false);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    statusBarTop.value = prefs.getBool(_kStatusBarTop) ?? true;
    autoplayCards.value = prefs.getBool(_kAutoplayCards) ?? false;
  }

  static Future<void> setAutoplayCards(bool value) async {
    autoplayCards.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoplayCards, value);
  }

  static Future<void> setStatusBarTop(bool value) async {
    statusBarTop.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kStatusBarTop, value);
  }
}
