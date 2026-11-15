import 'package:publicos_core/publicos_core.dart';

import 'demo_contacts_data.dart';

/// Per-client setting flag marking that the baked demo contacts have already
/// been seeded into this account's local store. Scoped to the session address
/// (PublicOSSettings is keyed by (key, sessionAddress)), so every new account
/// on the device gets its own one-time seed.
///
/// Ported verbatim from publicos_client (`data/demo_contacts.dart`); only the
/// data import is relative here. The baked snapshot lives in
/// [demo_contacts_data.dart] (copied alongside).
const String _seededFlagKey = 'demo_contacts_seeded';

/// One-time, per-account silent seed of the baked demo accounts into the local
/// contact store — plus their registered apps into the local app-bookmark
/// store — so a brand-new account's Contacts has people to explore from first
/// launch. Both stores self-heal: the Contacts screen refreshes each contact
/// from chain on view, and the app bookmarks are re-checked against the
/// AppRegistry, so any staleness in the baked snapshot corrects itself.
///
/// Idempotent (gated by a per-session setting flag) and best-effort — never
/// throws. Pass [force] to bypass the seeded-flag check (the Settings "Reseed
/// demo contacts" button).
Future<void> seedDemoContactsIfNeeded({bool force = false}) async {
  try {
    if (!PublicOS.isAuthenticated ||
        PublicOS.sessionBlockchainAddress == null) {
      return;
    }

    // Every boot, before the one-time gate: replace retired org apps.
    await _supersedeRetiredApps();
    // Same, for seeded accounts that moved to a new address.
    await _supersedeRetiredAccounts();

    if (!force) {
      final already = await PublicOSSettings.getSetting(_seededFlagKey);
      if (already?.value == 'true') return;
    }

    final myAddr = PublicOS.myPublicosAddress?.toLowerCase();
    for (final contact in buildDemoContacts()) {
      final addr = contact.publicosAddress?.eip55With0x.toLowerCase();
      if (addr == null) continue;
      if (myAddr != null && addr == myAddr) continue; // never seed self
      try {
        await PublicOSContacts.saveContact(contact);
      } catch (_) {
        // Non-fatal — keep seeding the rest.
      }
    }

    for (final app in buildDemoApps()) {
      final owner = app.ownerAccountAddress.eip55With0x.toLowerCase();
      if (myAddr != null && owner == myAddr) continue; // never seed self
      try {
        await PublicOSAppRegistry.bookmarkApp(app);
      } catch (_) {
        // Non-fatal — keep seeding the rest.
      }
    }

    await PublicOSSettings.setSetting(
      _seededFlagKey,
      Record.asSettings(
        key: _seededFlagKey,
        value: 'true',
        isSystem: true,
        expiration: DateTime.now().add(const Duration(days: 3650)),
        isExpired: false,
      ),
    );
  } catch (_) {
    // Seeding must never block boot.
  }
}


/// Org apps the publicos org retired, and the slug that replaced each. A
/// fixed list, oldest first: a device that bookmarked (or opened) the old slug
/// keeps a dead row, because the slug no longer exists on chain and the 24 h
/// bookmark refresh just skips it. [_supersedeRetiredApps] swaps it out.
const Map<String, String> _supersededApps = {
  'developers': 'library', // the Developers portal became the Library
};

/// Swap every retired org app on this device for its successor: the old
/// bookmark is removed and the successor bookmarked from the baked snapshot
/// (its 24 h refresh then pulls the live pointers); an old row in the open
/// history is dropped. Only rows owned by the successor's owner are touched,
/// so someone else re-registering the old slug is never affected. Runs every
/// boot (from [seedDemoContactsIfNeeded], before its one-time gate);
/// idempotent and best-effort, never throws.
Future<void> _supersedeRetiredApps() async {
  try {
    final baked = {for (final a in buildDemoApps()) a.appName: a};
    final bookmarks = await PublicOSAppRegistry.getBookmarkedApps();
    final recent = await PublicOSAppRegistry.getRecentApps();
    for (final swap in _supersededApps.entries) {
      final successor = baked[swap.value];
      if (successor == null) continue; // not in the snapshot: leave the old row
      final owner = successor.ownerAccountAddress.eip55With0x.toLowerCase();
      bool ownedByOrg(AppBookmark a) =>
          a.appName == swap.key &&
          a.ownerAccountAddress.eip55With0x.toLowerCase() == owner;
      final hasSuccessor = bookmarks.any((b) =>
          b.appName == swap.value &&
          b.ownerAccountAddress.eip55With0x.toLowerCase() == owner);
      for (final old in bookmarks.where(ownedByOrg)) {
        await PublicOSAppRegistry.removeBookmark(
            old.appName, old.ownerAccountAddress);
        if (!hasSuccessor) await PublicOSAppRegistry.bookmarkApp(successor);
      }
      if (recent.any(ownedByOrg)) {
        await PublicOSAppRegistry.removeFromRecentApps(swap.key);
      }
    }
  } catch (_) {
    // Never blocks boot.
  }
}

/// Seeded accounts that moved to a new address, old -> new. A fixed list.
/// OpenSea and zerion became public orgs; the individual accounts that held
/// those names are now `opensea-old` and `zerion-old`. OpenSea, zerion,
/// assistant and the publicos org have each changed address since; every
/// older address of each points straight at the current one (the lookup does
/// not chain).
const Map<String, String> _supersededAccounts = {
  '0xbECcF5A0DEfcbB14F96bc039b253B1239A9E0600':
      '0xCC9eB2c9cB1bAB38a7cC6e756ECC5c6fe4baa70C', // OpenSea (individual)
  '0x3b1d310ab044584d67156A6dB4ea19415594f872':
      '0xCC9eB2c9cB1bAB38a7cC6e756ECC5c6fe4baa70C', // OpenSea (earlier org)
  '0xfBC0cd4E1263a68977C243B9B06f56B433c4fE55':
      '0x2f786A9a909d8EC5aC3a2FB36E94517b8B84c4f4', // zerion (individual)
  '0xf96B0438d1240f41d353AB01B36c6d1B6784B910':
      '0x2f786A9a909d8EC5aC3a2FB36E94517b8B84c4f4', // zerion (earlier org)
  '0xC33C42c83AD6AE468fb390604Ebd8a2150b255cD':
      '0x1D4Dd7b5b6bB4cD8A8B268d52142B6D757f34abA', // assistant
  '0x37eD87a6edD6fAB8F60ECFC41dc990a5a18440e7':
      '0x814f894Eb8F1B36b615baeCB7c4a35eBACa739bD', // publicos (root org)
};

/// Swap every moved seeded account on this device for its successor, and only
/// where the old one is there: an old contact is removed and the successor
/// saved from the baked snapshot (unless already a contact); an app bookmark
/// owned by the old address is removed and the successor's app of the same
/// slug bookmarked; an old row in the open history is dropped. A device that
/// never had the old contact or app gets nothing added. Runs every boot (from
/// [seedDemoContactsIfNeeded], before its one-time gate); idempotent and
/// best-effort, never throws.
Future<void> _supersedeRetiredAccounts() async {
  try {
    final bakedContacts = {
      for (final c in buildDemoContacts())
        if (c.publicosAddress != null)
          c.publicosAddress!.eip55With0x.toLowerCase(): c,
    };
    final bakedApps = buildDemoApps();
    final bookmarks = await PublicOSAppRegistry.getBookmarkedApps();
    final recent = await PublicOSAppRegistry.getRecentApps();
    for (final move in _supersededAccounts.entries) {
      final oldAddr = move.key.toLowerCase();
      final newAddr = move.value.toLowerCase();
      final successor = bakedContacts[newAddr];
      if (successor == null) continue; // not in the snapshot: leave the old rows

      final old = await PublicOSContacts.getContact(
          EthereumAddress.fromHex(move.key));
      if (old != null) {
        await PublicOSContacts.removeContact(old);
        final has = await PublicOSContacts.getContact(
            EthereumAddress.fromHex(move.value));
        if (has == null) await PublicOSContacts.saveContact(successor);
      }

      bool ownedByOld(AppBookmark a) =>
          a.ownerAccountAddress.eip55With0x.toLowerCase() == oldAddr;
      for (final b in bookmarks.where(ownedByOld)) {
        await PublicOSAppRegistry.removeBookmark(
            b.appName, b.ownerAccountAddress);
        final hasNew = bookmarks.any((x) =>
            x.appName == b.appName &&
            x.ownerAccountAddress.eip55With0x.toLowerCase() == newAddr);
        if (hasNew) continue;
        for (final a in bakedApps) {
          if (a.appName == b.appName &&
              a.ownerAccountAddress.eip55With0x.toLowerCase() == newAddr) {
            await PublicOSAppRegistry.bookmarkApp(a);
          }
        }
      }
      for (final r in recent.where(ownedByOld)) {
        await PublicOSAppRegistry.removeFromRecentApps(r.appName);
      }
    }
  } catch (_) {
    // Never blocks boot.
  }
}
