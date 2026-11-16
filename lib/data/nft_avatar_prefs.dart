import 'package:publicos_core/publicos_core.dart';

/// UI-only preferences for the NFT-avatar treatment (sparkles + shimmer).
/// Ported verbatim from publicos_client (`components/nft_avatar_prefs.dart`) —
/// Core-backed, no edits.
///
/// Per the SDK convention these are *UI concerns* (no SDK-internal side effects),
/// so they live as plain key constants + parse/serialize here and use Core's
/// generic `getSetting`/`setSetting`. Both default ON; cached in-memory.
///
/// The values are cached in-memory so `GlassContactIcon` can read them
/// synchronously during paint; [ensureLoaded] hydrates the cache once, and the
/// settings pane updates it on toggle.
class NftAvatarPrefs {
  NftAvatarPrefs._();

  static const String sparklesKey = 'nft_sparkles';
  static const String shimmerKey = 'nft_shimmer';

  static bool sparkles = true;
  static bool shimmer = true;

  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final s = await PublicOSSettings.getSetting(sparklesKey);
      final sh = await PublicOSSettings.getSetting(shimmerKey);
      if (s != null) sparkles = s.value == 'true';
      if (sh != null) shimmer = sh.value == 'true';
    } catch (_) {
      // Not authenticated yet / no DB — keep defaults.
    }
  }

  static Future<bool> setSparkles(bool value) async {
    sparkles = value;
    return _persist(sparklesKey, value);
  }

  static Future<bool> setShimmer(bool value) async {
    shimmer = value;
    return _persist(shimmerKey, value);
  }

  static Future<bool> _persist(String key, bool value) async {
    try {
      final record = Record.asSettings(
        key: key,
        value: value.toString(),
        isExpired: false,
        isSystem: true,
      );
      return await PublicOSSettings.setSetting(key, record);
    } catch (_) {
      return false;
    }
  }
}
