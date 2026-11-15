// The desktop half of the four seams that connect `publicos_web3_bridge` to an
// app. The client has its own copy of this file and nothing else.
//
// Three of the four are near-identical to the client's, because they wrap the
// same Core APIs. The engine host is the one that genuinely differs and it
// lives in `web3_host.dart`.

import 'dart:io' show Directory, Platform;

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_web3_bridge/publicos_web3_bridge.dart';
import 'package:web3dart/web3dart.dart';
import 'package:zero_webview_windows/zero_webview_windows.dart';

import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/widgets/browser/connect_request_sheet.dart';
import 'package:publicos_desktop/widgets/browser/signature_request_sheet.dart';

/// [Web3Consent] over the ported sheets.
///
/// **Defaults to refusal in every direction** -- an unmounted context, a
/// dismissed sheet and a thrown route all mean no. Silence is never consent,
/// and on a surface that signs transactions that rule is the whole point.
///
/// Note the asymmetry the set model forces: a connect refusal is `null`, not an
/// empty set -- the empty set is a real user decision (disconnect every key)
/// and `ConnectGate` applies it as one.
class SheetWeb3Consent implements Web3Consent {
  /// Read fresh on every ask rather than captured: a sheet can be raised long
  /// after construction, by which time the element may be gone.
  final BuildContext? Function() contextOf;
  final String Function() chainIdOf;

  const SheetWeb3Consent({required this.contextOf, required this.chainIdOf});

  @override
  Future<ConnectDecision?> requestConnect(ConnectRequest request) async {
    final context = contextOf();
    if (context == null || !context.mounted) return null;
    try {
      return await ConnectRequestSheet.show(
        context: context,
        // The ORIGIN, not the page URL. `request.origin` is the live document
        // URL, so `.toString()` carries the path and query -- a four-line
        // `https://app.zerion.io/send?inputFungibleId=0x...` in a header built
        // for one. It would also be a quiet lie: the grant is recorded against
        // `originKey`, so the string the user is asked to approve must be the
        // string that gets stored.
        origin: ConnectGate.originKey(request.origin),
        keys: request.keys,
        alreadyGranted: request.alreadyGranted,
        preferred: request.preferred,
        requested: request.requested,
        activeKey: request.activeKey,
        sessionKeyName: sessionKeyName(context),
        currentChainId: chainIdOf(),
      );
    } catch (_) {
      return null;
    }
  }

  /// The session key's display name -- the account's own, since "Session Key" is
  /// what the key IS, not what the user calls themselves. Resolved here rather
  /// than in the picker so the sheet stays a dumb renderer of what it is given.
  static String sessionKeyName(BuildContext context) =>
      AppStateNotifier.currentMyContact?.displayName ??
      context.l10n.connectRequestSheetSessionKey;

  /// Move the global preferred-key pointer, by LABEL -- the spelling Core's
  /// pointer uses. The picker hands back a [WalletKey] because it reasons in
  /// addresses; the translation belongs here, at the Core seam.
  ///

  @override
  Future<bool> requestSignature(SignatureRequest request) async {
    final context = contextOf();
    if (context == null || !context.mounted) return false;
    try {
      return await SignatureRequestSheet.show(
        context: context,
        requestType: _sheetType(request.kind),
        message: request.kind == SignatureKind.message ||
                request.kind == SignatureKind.legacyEthSign
            ? request.display
            : null,
        transactionData: request.kind == SignatureKind.transaction ||
                request.kind == SignatureKind.sendTransaction
            ? request.payload as Map<String, dynamic>?
            : null,
        typedData:
            request.kind == SignatureKind.typedData ? request.payload : null,
        // Same rule as the connect sheet: show the origin the permission is
        // scoped to, not the page's full URL.
        requestingOrigin: ConnectGate.originKey(request.origin),
        currentChainId: chainIdOf(),
        // The address the dApp named and the gate approved. The sheet shows
        // exactly this and offers no switcher -- what is displayed is what
        // signs.
        signingAddress: request.address,
      );
    } catch (_) {
      return false;
    }
  }

  /// 1:1, and it must stay that way. `eth_sign` has its own case because the
  /// sheet warns harder about blind signing than it does about
  /// `personal_sign`; collapsing the two would drop that warning silently.
  static SignatureRequestType _sheetType(SignatureKind kind) => switch (kind) {
        SignatureKind.message => SignatureRequestType.personalSign,
        SignatureKind.legacyEthSign => SignatureRequestType.ethSign,
        SignatureKind.typedData => SignatureRequestType.signTypedData,
        SignatureKind.transaction => SignatureRequestType.signTransaction,
        SignatureKind.sendTransaction => SignatureRequestType.sendTransaction,
      };
}

/// [WalletBinding] over Core's keychain.
///
/// Answers three questions the bridge asks and NOTHING else: which keys exist,
/// which one is preferred, and what signs for a given address. A host-pinned
/// wallet (the "Manage" flow) short-circuits all three.
///
/// ── NO FALLBACK. ANYWHERE. ───────────────────────────────────────────────────
/// [signingKeyFor] is an EXACT match or null, and that is the point of the
/// class. It must never end `?? PublicOS.currentBlockchainPrivateKey`: a
/// lookup that missed would then sign as the session key instead -- producing
/// a signature that does not recover to the address the page was shown.
/// Core's own helpers carry no such substitution either; do not introduce it
/// at either layer.
class SessionWalletBinding implements WalletBinding {
  /// **Closures, not values, and that is load-bearing.** The wallet manager
  /// resolves the managed key asynchronously, so a widget can be built before
  /// the key exists. Holding the value would freeze that `null` for the life of
  /// the bridge and every signature would silently fall back to the globally
  /// web-selected key -- the page told one address, signing with another.
  ///
  /// Desktop awaits the key before opening the dialog, so it does not hit that
  /// race today; the closures are here anyway because the two apps must not
  /// disagree about this, and because a rebuild with a different pin has to be
  /// picked up either way.
  final String? Function() overrideAccountAddressOf;
  final EthPrivateKey? Function() overrideSigningKeyOf;

  final String? Function() userAddressOf;

  const SessionWalletBinding({
    required this.userAddressOf,
    required this.overrideAccountAddressOf,
    required this.overrideSigningKeyOf,
  });

  /// A pinned view offers exactly one key -- the wallet the user pressed
  /// "Manage" on. A manager for one wallet forces that wallet: there is nothing
  /// to pick, so the picker gets one row and [signingKeyFor] refuses every
  /// other address rather than reaching into a keychain this view is not
  /// speaking for.
  PinnedWalletBinding? get _pin {
    final address = overrideAccountAddressOf();
    if (address == null || address.isEmpty) return null;
    return PinnedWalletBinding(
      address: address,
      signingKey: overrideSigningKeyOf(),
    );
  }

  @override
  Future<List<WalletKey>> availableKeys() async {
    final pin = _pin;
    if (pin != null) return pin.availableKeys();

    // The session key is NOT in `fetchKeys` -- that walks the keychain index
    // only -- so it is prepended here. It is deliberately FIRST: it is the
    // account's own identity and the default `accounts[0]` when no preference
    // applies. `fetchKeys` sorts the rest alphabetically by label.
    final session = PublicOS.sessionBlockchainAddress;
    final user = userAddressOf();
    final keys = <WalletKey>[
      if (session != null && session.isNotEmpty)
        WalletKey(label: 'session', address: session),
    ];
    if (user == null) return keys;

    try {
      for (final k in await PublicOSKeychain.fetchKeys(user)) {
        final address = (k['address'] ?? '') as String;
        if (address.isEmpty || address == 'Unknown') continue;
        keys.add(WalletKey(
          label: k['label'] as String,
          address: address,
          emoji: k['emoji'] as String?,
        ));
      }
    } catch (e) {
      debugPrint('[web3] could not load keychain keys: $e');
    }
    return keys;
  }

  @override
  Future<String?> preferredAddress() async {
    final pin = _pin;
    if (pin != null) return pin.preferredAddress();

    final user = userAddressOf();
    if (user == null) return PublicOS.sessionBlockchainAddress?.toLowerCase();
    // Null when the pointer names a key that no longer exists. That is a
    // missing PREFERENCE, not a missing identity: ordering falls back to
    // keychain order, and nothing is granted or signed differently.
    final addr = await PublicOSKeychain.getWebSelectedAddress(user);
    return (addr == null || addr.isEmpty) ? null : addr.toLowerCase();
  }

  @override
  Future<EthPrivateKey?> signingKeyFor(String address) async {
    final pin = _pin;
    if (pin != null) return pin.signingKeyFor(address);

    final wanted = address.toLowerCase();

    // The session key is not in the keychain, so it is matched first, and by
    // ADDRESS -- never by the label a grant happens to carry, which is
    // display-only and survives a rename.
    final sessionKey = PublicOS.currentBlockchainPrivateKey;
    if (sessionKey != null &&
        sessionKey.address.eip55With0x.toLowerCase() == wanted) {
      return sessionKey;
    }

    final user = userAddressOf();
    if (user == null) return null;
    try {
      for (final k in await PublicOSKeychain.fetchKeys(user)) {
        if (((k['address'] ?? '') as String).toLowerCase() != wanted) continue;
        final hex = k['privateKey'] as String?;
        if (hex == null || hex.isEmpty || hex == 'Error loading key') return null;
        return EthPrivateKey.fromHex(hex);
      }
    } catch (e) {
      debugPrint('[web3] could not resolve signing key: $e');
    }
    return null;
  }
}

/// [GrantStore] over Core's database. Five calls, no logic.
class CoreGrantStore implements GrantStore {
  const CoreGrantStore();

  @override
  Future<bool> hasGrant({
    required String origin,
    required String session,
    required String eoa,
  }) =>
      PublicOS.database.hasGrant(origin: origin, session: session, eoa: eoa);

  @override
  Future<List<String>> listGrants({
    required String origin,
    required String session,
  }) =>
      PublicOS.database.listGrantsForOrigin(origin: origin, session: session);

  @override
  Future<void> grantSite({
    required String origin,
    required String session,
    required String eoa,
    String? keyLabel,
  }) =>
      PublicOS.database.grantSite(
        origin: origin,
        session: session,
        eoa: eoa,
        keyLabel: keyLabel,
      );

  @override
  Future<void> revokeSite({
    required String origin,
    required String session,
    required String eoa,
  }) =>
      PublicOS.database.revokeSite(origin: origin, session: session, eoa: eoa);

  @override
  Future<void> touchGrant({
    required String origin,
    required String session,
    required String eoa,
  }) =>
      PublicOS.database.touchGrant(origin: origin, session: session, eoa: eoa);

  @override
  Future<String?> activeKeyFor({
    required String origin,
    required String session,
  }) =>
      PublicOS.database.siteActiveKey(origin: origin, session: session);

  @override
  Future<void> setActiveKey({
    required String origin,
    required String session,
    required String eoa,
  }) =>
      PublicOS.database
          .setSiteActiveKey(origin: origin, session: session, eoa: eoa);

  @override
  Future<void> clearActiveKey({
    required String origin,
    required String session,
  }) =>
      PublicOS.database.clearSiteActiveKey(origin: origin, session: session);
}

/// The logged-in account, as both the binding and the grant scope need it.
String? currentUserAddress() =>
    AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;

/// The grant's scope key: the SESSION address, lowercased.
///
/// Session, not account -- a user can hold several sessions for one account on
/// one device, and an account-scoped grant cannot tell them apart.
String currentSessionAddress() =>
    (PublicOS.sessionBlockchainAddress ??
            '0x0000000000000000000000000000000000000000')
        .toLowerCase();

/// [WebStorageProfile] over WebView2 -- the fifth seam, desktop half.
///
/// A profile is a user-data folder; the fork gives each folder its own
/// environment (`initialize(userDataPath:)`, zero_webview_windows FORK.md
/// change 7). WebView2 always isolates, so `isolates` is a constant and
/// `wipeAll` refuses rather than pretending.
class DesktopWebStorage implements WebStorageProfile<WebviewController> {
  const DesktopWebStorage();

  @override
  Future<bool> get isolates async => true;

  @override
  Future<WebviewController> createController(String profileId) async {
    final controller = WebviewController();
    await controller.initialize(userDataPath: folderFor(profileId));
    return controller;
  }

  /// `%LOCALAPPDATA%\PublicOS\webview\<profileId>`. Local, not roaming: a
  /// WebView2 user-data folder is a browser profile, hundreds of MB of cache
  /// that must never sync. The plugin's own default
  /// (`%LOCALAPPDATA%\flutter_webview_windows\<exe>`) is not used and not
  /// migrated.
  static String folderFor(String profileId) {
    final base =
        Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path;
    return '$base\PublicOS\webview\$profileId';
  }

  @override
  Future<void> wipeAll() async {
    throw StateError(
      'WebView2 always isolates; wipeAll exists for engines that cannot.',
    );
  }
}
