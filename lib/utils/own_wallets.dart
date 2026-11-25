import 'package:flutter/foundation.dart' show debugPrint;
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/wallet/wallet_avatar.dart';

/// One of the signed-in user's OX-receiving wallets — their personal main Safe,
/// an org they belong to (main Safe), or a keychain (linked) wallet. Used to
/// pick where a payment REQUEST should be paid. No balance: a request doesn't
/// spend, so we skip the per-wallet balance reads the Send sheet does.
class OwnWallet {
  /// Display name — "main" for the personal Safe, the org's name, or the
  /// keychain wallet's label.
  final String name;

  /// The Safe / wallet address (hex, 0x-prefixed).
  final String address;

  /// The owning account (personal or org). Null for keychain wallets.
  final EthereumAddress? accountAddress;

  final bool isGroup;

  /// The org's contact (for its avatar). Null for personal / keychain wallets.
  final Contact? contact;

  /// The wallet's emoji mark — the user's local `wallet_icon_<addr>` override,
  /// else a keychain key's own emoji. Null → 🪙. Unused for group wallets
  /// (they render the org's avatar instead). Matches the Wallet tab exactly.
  final String? emoji;

  /// A keychain key's own colour (`key['color']`). Null → the connected accent.
  final int? colorValue;

  const OwnWallet({
    required this.name,
    required this.address,
    this.accountAddress,
    this.isGroup = false,
    this.contact,
    this.emoji,
    this.colorValue,
  });
}

/// Load [account]'s receiving wallets: personal main Safe + each org's main Safe
/// + keychain (linked) wallets — the same sources as the Send sheet's origin
/// list, minus balances. Best-effort per block: a failing/slow block simply
/// contributes nothing. Deduped by address, personal-first ordering.
/// The watched set, plus whether every source actually answered.
///
/// [complete] is false when any of the three lookups failed. That distinction
/// is load-bearing for the activity sweep and nothing else: a caller that is
/// only drawing a list (the payment sheet, the wallet tab) is happy with a
/// partial answer, but a caller that will ADVANCE A CURSOR past a block range
/// must not treat "I could not tell you what to watch" as "there was nothing
/// to see".
typedef OwnWalletScan = ({List<OwnWallet> wallets, bool complete});

/// Enumerate the wallets that can receive on the user's behalf, reporting
/// whether the enumeration is trustworthy.
///
/// **Why this exists.** If the sources swallow their own failures and return
/// an empty list, a transient RPC failure on the main-Safe lookup produces a
/// silently short watched set. The activity sweep then scans a block range
/// for the wrong wallets, finds nothing, and advances its cursor — making
/// that range permanently invisible.
Future<OwnWalletScan> scanOwnReceivingWallets(EthereumAddress account) async {
  final blocks = await Future.wait([
    _personal(account),
    _orgs(account),
    _keychain(account),
  ]);
  final out = <OwnWallet>[];
  final seen = <String>{};
  var complete = true;
  for (final block in blocks) {
    if (!block.ok) complete = false;
    for (final w in block.wallets) {
      if (seen.add(w.address.toLowerCase())) out.add(w);
    }
  }
  // Only a complete answer is remembered: a short set must not stand in for
  // the real one on the next screen that opens.
  if (complete) _lastScan[account.eip55With0x.toLowerCase()] = out;
  return (wallets: out, complete: complete);
}

/// The last COMPLETE set worked out for an account this run (the app's wallet
/// sweep fills it at start), so a screen can name the user's wallets at once
/// and refresh behind. null = none yet.
List<OwnWallet>? lastOwnReceivingWallets(EthereumAddress account) =>
    _lastScan[account.eip55With0x.toLowerCase()];

final Map<String, List<OwnWallet>> _lastScan = {};

/// The list alone, for callers that only render it.
Future<List<OwnWallet>> loadOwnReceivingWallets(EthereumAddress account) async =>
    (await scanOwnReceivingWallets(account)).wallets;

/// One source's answer: what it found, and whether it managed to look.
typedef _SourceResult = ({List<OwnWallet> wallets, bool ok});

const _SourceResult _sourceFailed = (wallets: <OwnWallet>[], ok: false);

Future<_SourceResult> _personal(EthereumAddress me) async {
  try {
    // Stored on the contact once known (a MainSafe never changes), so this is
    // a local read after the first time. Every account has one: null means
    // the lookup could not answer, which is a failure to retry, not "none".
    final safe = await PublicOSContacts.mainSafeOf(me);
    if (safe == null) return _sourceFailed;
    return (
      wallets: [
        OwnWallet(
          name: 'main',
          address: safe,
          accountAddress: me,
          emoji: await loadWalletIcon(safe),
        ),
      ],
      ok: true,
    );
  } catch (e) {
    debugPrint('[own_wallets] main Safe lookup failed: $e');
    return _sourceFailed;
  }
}

Future<_SourceResult> _orgs(EthereumAddress me) async {
  try {
    final orgs = await PublicOSGovernance.getOrgsForAccount(me);
    if (orgs.isEmpty) return (wallets: <OwnWallet>[], ok: true);
    final per = await Future.wait(orgs.map(_oneOrg));
    // A single org that failed to resolve still makes the SET incomplete —
    // that org's Safe is one we should have been watching.
    final ok = per.every((r) => r.ok);
    return (
      wallets: per.expand((r) => r.wallets).toList(),
      ok: ok,
    );
  } catch (e) {
    debugPrint('[own_wallets] org enumeration failed: $e');
    return _sourceFailed;
  }
}

Future<_SourceResult> _oneOrg(EthereumAddress org) async {
  try {
    // Local first: an org we already hold is not re-read from the
    // chain here, and its Safe is permanent. Only an org we do not know costs
    // a profile fetch, and that copy is kept.
    var contact = await PublicOSContacts.getContact(org);
    if (contact == null) {
      try {
        contact = await PublicOSContacts.fetchContact(org, requireRecords: true);
        await PublicOSContacts.saveContact(contact);
      } catch (e) {
        debugPrint('[own_wallets] org profile fetch failed for $org: $e');
      }
    }
    final safe = contact?.mainSafe ?? await PublicOSContacts.mainSafeOf(org);
    if (safe == null) return _sourceFailed;
    return (
      wallets: [
        OwnWallet(
          name: contact?.displayName ?? 'Org',
          address: safe,
          accountAddress: org,
          isGroup: true,
          contact: contact,
        ),
      ],
      ok: true,
    );
  } catch (e) {
    debugPrint('[own_wallets] org Safe lookup failed for $org: $e');
    return _sourceFailed;
  }
}

Future<_SourceResult> _keychain(EthereumAddress me) async {
  try {
    final keys =
        await PublicOSKeychain.getKeysWithWalletEnabled(me.eip55With0x);
    final wallets = await Future.wait(keys.map((k) async {
      final label = (k['label'] as String?) ?? '';
      final address = k['address'] as String;
      // Same precedence as the Wallet tab: the local icon override wins over
      // the key's own emoji, which wins over the 🪙 default.
      final custom = await loadWalletIcon(address);
      return OwnWallet(
        name: label.isNotEmpty ? label : 'Wallet',
        address: address,
        emoji: custom ?? (k['emoji'] as String?),
        colorValue: k['color'] as int?,
      );
    }));
    return (wallets: wallets, ok: true);
  } catch (e) {
    debugPrint('[own_wallets] keychain enumeration failed: $e');
    return _sourceFailed;
  }
}
