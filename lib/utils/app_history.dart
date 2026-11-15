import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData, Icons;
import 'package:publicos_core/publicos_core.dart';

/// A shell pane offered as an APP:
/// a tile in the Apps dialog, off the rail, recorded in the rail history like
/// any registry app, but opening its full pane instead of an owner's profile.
@immutable
class SystemApp {
  /// The id `apps_view.dart`'s `_openSystemApp` hands out ('treasury', …).
  final String id;

  /// The `kShellDestinations` index of the pane it opens.
  final int destination;

  /// Same glyph as the Apps dialog tile, so the rail row and the tile match.
  final IconData icon;

  const SystemApp(this.id, this.destination, this.icon);

  /// The key it is stored under in Core's app history. The colon can never
  /// appear in an on-chain slug (`AppRegistryMemory._isValidSlug`:
  /// `[a-z0-9_-]`, 3–32), so a system entry never collides with a registry app.
  String get historyKey => '$kSystemAppKeyPrefix$id';
}

const String kSystemAppKeyPrefix = 'system:';

/// Tile order in the Apps dialog; the first-run seed puts the first on top.
const List<SystemApp> kSystemApps = [
  SystemApp('treasury', 5, Icons.account_balance_rounded),
  SystemApp('social_graph', 11, Icons.account_tree_rounded),
  SystemApp('nodes', 8, Icons.hub_rounded),
];

SystemApp? systemAppById(String id) {
  for (final s in kSystemApps) {
    if (s.id == id) return s;
  }
  return null;
}

SystemApp? systemAppForDestination(int destination) {
  for (final s in kSystemApps) {
    if (s.destination == destination) return s;
  }
  return null;
}

/// The system app a history entry stands for, or null for a registry app.
SystemApp? systemAppOf(AppBookmark app) {
  if (!app.appName.startsWith(kSystemAppKeyPrefix)) return null;
  return systemAppById(app.appName.substring(kSystemAppKeyPrefix.length));
}

/// **Desktop-only — "last visited apps" for the rail.**
///
/// The history itself lives in Core (`PublicOSAppRegistry.recordAppOpen` /
/// `getRecentApps` / `removeFromRecentApps`, settings-backed, per session).
/// This notifier is the desktop seam between the two places
/// that touch it: the Browser records an open when an app tab is selected,
/// and the shell's rail paints the list. It is a domain event ("the history
/// changed, here it is"), not a "please reload" ping — listeners receive the
/// list, they never re-query.
///
/// Singleton because the rail and the browser are far apart in the tree and
/// neither owns the other; same shape as `ChatAppearance`.
class RecentApps extends ChangeNotifier {
  RecentApps._();
  static final RecentApps instance = RecentApps._();

  List<AppBookmark> _apps = const [];

  /// Most recent first. Empty until [load] has run.
  List<AppBookmark> get apps => _apps;

  /// Read the history from Core. Called by the shell at mount (and again
  /// whenever the signed-in session changes, since the store is per session).
  Future<void> load() async {
    try {
      _apps = await PublicOSAppRegistry.getRecentApps();
    } catch (_) {
      _apps = const [];
    }
    notifyListeners();
  }

  /// Record an open (the Browser's app-tab selection) and re-read, so the
  /// rail moves the app to the top. Never throws — history must not block a
  /// tab switch.
  Future<void> recordOpen(AppBookmark app) async {
    try {
      await PublicOSAppRegistry.recordAppOpen(app);
    } catch (_) {}
    await load();
  }

  /// The rail's right-click "Remove from history".
  Future<void> remove(AppBookmark app) async {
    try {
      await PublicOSAppRegistry.removeFromRecentApps(app.appName);
    } catch (_) {}
    await load();
  }

  /// A shell pane became current. If it is a system app, record the open —
  /// the shell calls this for EVERY pane switch, so every door counts (Apps
  /// tile, history row, the BSP dialog's Treasury hand-off, the SSP gate's
  /// `AppNav.toTreasury`). Any other destination is a no-op.
  Future<void> recordDestinationOpen(int destination) async {
    final sys = systemAppForDestination(destination);
    if (sys == null) return;
    await recordOpen(_bookmarkOf(sys));
  }

  /// Settings flag for [seedSystemAppsOnce]. Same scope as the history itself
  /// (per session key), so a new device or account gets the seed once.
  static const String _seededKey = 'desktop_system_apps_history_seeded';

  /// First run only: put the system apps into history (the first of
  /// [kSystemApps] on top) so users see they exist, then set the flag. They
  /// fall back as other apps are opened and are never re-added — not even if
  /// the user removes them; the Apps dialog tiles stay. The flag is written
  /// only after the history writes, so a failed run retries next launch.
  Future<void> seedSystemAppsOnce() async {
    try {
      if (await PublicOSSettings.getSetting(_seededKey) != null) return;
      for (final sys in kSystemApps.reversed) {
        await PublicOSAppRegistry.recordAppOpen(_bookmarkOf(sys));
      }
      await PublicOSSettings.setSetting(
        _seededKey,
        Record.asSettings(
          key: _seededKey,
          value: 'true',
          isSystem: true,
          expiration: DateTime.now().add(const Duration(days: 3650)),
          isExpired: false,
        ),
      );
    } catch (_) {
      return;
    }
    await load();
  }

  /// A system app as a history entry: the reserved key, no owner, no
  /// pointers. The rail paints it from [SystemApp], never from these fields.
  static AppBookmark _bookmarkOf(SystemApp sys) => AppBookmark(
        appName: sys.historyKey,
        displayName: sys.id,
        ownerAccountAddress:
            EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'),
      );
}
