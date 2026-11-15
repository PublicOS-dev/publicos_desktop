import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

/// The user's spendable wallets, as the send sheet models them.
///
/// **One list, two sheets.** The send sheet and the subscribe sheet show the
/// same PAYING FROM list, so the loaders live here. The row shape is
/// untyped maps on purpose — the send sheet reads these maps by key in
/// dozens of places:
///
/// | key              | personal Safe | group Safe | keychain key |
/// |------------------|:---:|:---:|:---:|
/// | `name`           | `'main'` | `'main'` | key label |
/// | `address`        | Safe | Safe | EOA |
/// | `balance`        | OX, human | OX, human | OX, human |
/// | `accountAddress` | me | org | — |
/// | `isGroup`        | false | **true** | — |
/// | `groupContact`   | — | `Contact` | — |
/// | `isKeychain`     | — | — | **true** |
/// | `privateKey`     | — | — | hex |
/// | `emoji`          | — | — | key emoji |
/// | `color`          | derived | derived | key colour |
///
/// Three blocks fan out in parallel and each returns `[]` on failure, so a
/// slow or dead block never gates the others. Results merge keyed by
/// lowercased address.
///
/// ⚠ **Same edit twice** — twin of
/// `publicos_client/lib/components/transactions/wallet_sources.dart`.
Future<List<Map<String, dynamic>>> loadWalletRows(
  EthereumAddress currentUserAddress,
) async {
  final localContactsByAddress = <String, Contact>{};
  try {
    final stored = await PublicOSContacts.getStoredContacts();
    for (final c in stored) {
      final addr = c.publicosAddress?.eip55With0x.toLowerCase();
      if (addr != null) localContactsByAddress[addr] = c;
    }
  } catch (_) {
    // Contact names are cosmetic here; a failed read must not block wallets.
  }

  final results = await Future.wait([
    loadPersonalWallet(currentUserAddress),
    loadGroupWallets(currentUserAddress, localContactsByAddress),
    loadKeychainWallets(currentUserAddress),
  ]);

  final merged = <Map<String, dynamic>>[];
  final seen = <String>{};
  for (final w in [...results[0], ...results[1], ...results[2]]) {
    final addr = (w['address'] as String).toLowerCase();
    if (seen.add(addr)) merged.add(w);
  }
  return merged;
}

Future<List<Map<String, dynamic>>> loadPersonalWallet(
  EthereumAddress currentUserAddress,
) async {
  try {
    final mainSafeAddress =
        await PublicOSSafe.getMainSafeAddress(currentUserAddress);
    if (mainSafeAddress == null) return const [];
    final balanceWei = await PublicOSTreasury.getTokenBalance(
      EthereumAddress.fromHex(mainSafeAddress),
    );
    return [
      {
        'name': 'main',
        'address': mainSafeAddress,
        'balance': balanceWei.toDouble() / 1e18,
        'accountAddress': currentUserAddress,
        'isGroup': false,
        'color': walletColorFor('main'),
      },
    ];
  } catch (_) {
    return const [];
  }
}

Future<List<Map<String, dynamic>>> loadGroupWallets(
  EthereumAddress currentUserAddress,
  Map<String, Contact> localContactsByAddress,
) async {
  try {
    final groupAddresses =
        await PublicOSGovernance.getOrgsForAccount(currentUserAddress);
    if (groupAddresses.isEmpty) return const [];

    final perOrg = await Future.wait(
      groupAddresses.map(
        (orgAddr) => _loadOneGroupWallet(orgAddr, localContactsByAddress),
      ),
    );
    return perOrg.whereType<Map<String, dynamic>>().toList();
  } catch (_) {
    return const [];
  }
}

/// Local-first contact lookup, then in parallel with the wallet address
/// + balance reads. Single-org failure returns null and gets filtered out.
Future<Map<String, dynamic>?> _loadOneGroupWallet(
  EthereumAddress orgAddress,
  Map<String, Contact> localContactsByAddress,
) async {
  try {
    final addrKey = orgAddress.eip55With0x.toLowerCase();
    final cached = localContactsByAddress[addrKey];

    // Run the contact resolution and safe-address lookup concurrently.
    // Cached contact → synchronous Future.value, no chain hit.
    final contactFuture = cached != null
        ? Future<Contact?>.value(cached)
        : PublicOSContacts.fetchContact(orgAddress);
    final safeAddressFuture = PublicOSSafe.getMainSafeAddress(orgAddress);

    final results = await Future.wait([contactFuture, safeAddressFuture]);
    final groupContact = results[0] as Contact?;
    final mainWalletAddress = results[1] as String?;

    if (groupContact == null || mainWalletAddress == null) return null;

    final balanceWei = await PublicOSTreasury.getTokenBalance(
      EthereumAddress.fromHex(mainWalletAddress),
    );

    return {
      'name': 'main',
      'address': mainWalletAddress,
      'balance': balanceWei.toDouble() / 1e18,
      'accountAddress': orgAddress,
      'isGroup': true,
      'groupContact': groupContact,
      'color': walletColorFor(groupContact.displayName),
    };
  } catch (_) {
    return null;
  }
}

Future<List<Map<String, dynamic>>> loadKeychainWallets(
  EthereumAddress currentUserAddress,
) async {
  try {
    final keychainKeys = await PublicOSKeychain.getKeysWithWalletEnabled(
      currentUserAddress.eip55With0x,
    );
    if (keychainKeys.isEmpty) return const [];

    final perKey = await Future.wait(
      keychainKeys.map((key) => _loadOneKeychainWallet(key)),
    );
    return perKey.whereType<Map<String, dynamic>>().toList();
  } catch (_) {
    return const [];
  }
}

Future<Map<String, dynamic>?> _loadOneKeychainWallet(
  Map<String, dynamic> key,
) async {
  try {
    final balanceWei = await PublicOSTreasury.getTokenBalance(
      EthereumAddress.fromHex(key['address']),
    );
    return {
      'name': key['label'],
      'address': key['address'],
      'balance': balanceWei.toDouble() / 1e18,
      'isKeychain': true,
      'privateKey': key['privateKey'],
      'emoji': key['emoji'] ?? '🔑',
      'color': Color(key['color'] ?? Colors.green.value),
    };
  } catch (_) {
    return null;
  }
}

/// Stable per-name colour for Safe rows (keychain rows carry their own).
Color walletColorFor(String name) {
  final colors = [
    Colors.green.shade700,
    Colors.blue.shade700,
    Colors.purple.shade700,
    Colors.orange.shade700,
    Colors.red.shade700,
    Colors.teal.shade700,
  ];
  final index = name.hashCode.abs() % colors.length;
  return colors[index];
}
