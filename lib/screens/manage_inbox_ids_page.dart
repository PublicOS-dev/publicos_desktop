import 'dart:async';

import '../widgets/contact_banner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:web3dart/web3dart.dart' show EthPrivateKey;


import 'package:publicos_desktop/widgets/inbox_tab_dialog.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_label.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// Full-screen page for managing the current account's XMTP inbox IDs.
/// Pushed via `CupertinoPageRoute` from the messages-view chip and the
/// XMTP-contacts-view chip. Same `SystemAppScaffold(pinHeader: true)` shell
/// as Treasury / Account Center / BSP / SSP / Manage Server (the system-app
/// page anatomy).
///
/// Row backdrop: when the `messages_show_contact_banner` setting is ON
/// (default true — same toggle that drives the ConversationRow banner
/// layer in the messages view), each REGISTERED inbox row renders its
/// account-contact banner as a dim layer behind the row content. Local-
/// only rows (no on-chain registration) have no contact yet, so they
/// stay on the plain glass surface.
///
/// Features (three tiers):
///   - **Tier A**: list + expand + rename label + register + remove from registry
///   - **Tier B**: installations view + revoke single / all others + sync consent + send history
///   - **Tier C**: offline recovery + add account + remove account
///
/// Expanded panel: the loading check is `(isLoading || inboxState == null)
/// ? spinner : content` so the brief null state on the first frame after an
/// expand doesn't render a "Failed to load inbox state" flash.
///
/// Temporary key switching: tapping a row to expand it calls
/// `PublicOSKeychain.selectKey(...)` to switch the active XMTP client to a
/// key that owns that inbox (XMTP's `getInboxState` reads from the currently-
/// active client). `_originalKeyLabel` is saved in `initState` and restored in
/// `dispose`, so the messages tab's cached conversations remain valid by the
/// time the user navigates back.

// ============================================================================
// Private data models
// ============================================================================

class _KeyInfo {
  final String label;
  final String address;
  final String privateKeyHex;
  const _KeyInfo({
    required this.label,
    required this.address,
    required this.privateKeyHex,
  });
}

class _RegistrationInfo {
  final EthereumAddress accountAddress;
  final String label;
  final Uint8List inboxIdBytes;
  final Contact? accountContact;
  const _RegistrationInfo({
    required this.accountAddress,
    required this.label,
    required this.inboxIdBytes,
    this.accountContact,
  });
}

class _InboxEntry {
  final String inboxId;
  final List<_KeyInfo> localKeys;
  final _RegistrationInfo? registration;

  const _InboxEntry({
    required this.inboxId,
    required this.localKeys,
    this.registration,
  });

  bool get isManageable => localKeys.isNotEmpty;
  bool get isRegistered => registration != null;

  String get displayName {
    if (registration != null) {
      final contact = registration!.accountContact;
      final name = (contact != null && contact.displayName.isNotEmpty)
          ? contact.displayName
          : null;
      final label =
          registration!.label.isNotEmpty ? registration!.label : null;
      if (name != null && label != null) return '$name/$label';
      if (name != null) return name;
      if (label != null) return label;
    }
    if (localKeys.isNotEmpty) return localKeys.first.label;
    return 'Unknown';
  }

  Color get fallbackColor {
    return Color((inboxId.hashCode & 0x00FFFFFF) | 0xFF000000);
  }
}

class _InboxStateData {
  final String inboxId;
  final List<Map<String, dynamic>> identities;
  final List<Map<String, dynamic>> installations;
  final Map<String, dynamic>? recoveryIdentity;
  final bool hasRecoveryKeyLocally;

  const _InboxStateData({
    required this.inboxId,
    required this.identities,
    required this.installations,
    this.recoveryIdentity,
    this.hasRecoveryKeyLocally = false,
  });
}

// ============================================================================
// Page widget
// ============================================================================

class ManageInboxIdsPage extends StatefulWidget {
  const ManageInboxIdsPage({super.key});

  @override
  State<ManageInboxIdsPage> createState() => _ManageInboxIdsPageState();
}

class _ManageInboxIdsPageState extends State<ManageInboxIdsPage>
    with TickerProviderStateMixin {
  // ---- state ----------------------------------------------------------------

  List<_InboxEntry> _entries = const [];
  bool _isLoading = true;

  /// A silent reload after a write is in flight: the list stays up and the
  /// corner loader shows, so a publish/unpublish is visibly being picked up.
  bool _refreshing = false;
  String? _error;

  String? _expandedInboxId;
  final Map<String, AnimationController> _animControllers = {};
  final Map<String, Animation<double>> _expandAnims = {};
  final Map<String, _InboxStateData?> _stateCache = {};
  final Map<String, bool> _loadingStates = {};
  String? _currentInstallationId;

  bool _isSyncingConsent = false;
  bool _isSyncingHistory = false;
  bool _isRevokingOffline = false;

  String? _originalKeyLabel;
  Contact? _myContact;

  // ---- lifecycle ------------------------------------------------------------

  /// Mirrors the messages view's banner toggle. When ON, the current
  /// user's contact banner renders as a dim full-bleed backdrop. Default
  /// true, same as ConversationRow.
  bool _showBanner = true;

  @override
  void initState() {
    super.initState();
    _originalKeyLabel = PublicOS.currentXmtpKeyLabel;
    _loadMyContact();
    _loadCurrentInstallationId();
    _loadBannerSetting();
    _loadData();
  }

  Future<void> _loadBannerSetting() async {
    try {
      final setting =
          await PublicOSSettings.getSetting('messages_show_contact_banner');
      if (!mounted) return;
      setState(() => _showBanner = setting?.value != 'false');
    } catch (_) {
      // leave default
    }
  }

  @override
  void dispose() {
    unawaited(_restoreOriginalKey());
    for (final c in _animControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMyContact() async {
    final addrHex = PublicOS.myPublicosAddress;
    if (addrHex == null) return;
    try {
      final contact = await PublicOSContacts.getContact(
        EthereumAddress.fromHex(addrHex),
      );
      if (mounted) setState(() => _myContact = contact);
    } catch (_) {}
  }

  Future<void> _loadCurrentInstallationId() async {
    final id = await PublicOSXmtp.getInstallationId();
    if (mounted) setState(() => _currentInstallationId = id);
  }

  Future<void> _restoreOriginalKey() async {
    final original = _originalKeyLabel;
    if (original == null) return;
    if (original == PublicOS.currentXmtpKeyLabel) return;
    final addrHex = PublicOS.myPublicosAddress;
    if (addrHex == null) return;
    try {
      await PublicOSKeychain.selectKey(addrHex, original);
    } catch (_) {}
  }

  // ---- data loading ---------------------------------------------------------

  /// Load + render. `silent: true` skips the `_isLoading` toggle so post-action
  /// reloads + pull-to-refresh don't kill the body. Initial mount uses the
  /// loud variant so the bottom-right `PixelRainLoadingCorner` shows during the
  /// 3s contract-settle delay on first open.
  ///
  /// `settle: false` skips the 3 s settle delay. Only for reloads after a
  /// write whose receipt is already confirmed (the delay is for a recent
  /// selectKey, not for a mined tx): with it, a publish takes ~4 s to show,
  /// silently, and reads as "the screen does not reload".
  Future<void> _loadData({bool silent = false, bool settle = true}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }

    try {
      final addrHex = PublicOS.myPublicosAddress;
      if (addrHex == null) {
        throw Exception('User address not available');
      }
      final userAddress = EthereumAddress.fromHex(addrHex);
      debugPrint(
          '[InboxMgr] === LOAD START === user=$addrHex, activeKey=${PublicOS.currentXmtpKeyLabel}');

      // Step 1: Keychain keys → inbox IDs
      final rawKeys = await PublicOSKeychain.fetchKeys(addrHex);
      debugPrint('[InboxMgr] Step 1: ${rawKeys.length} keys in keychain');
      final Map<String, List<_KeyInfo>> keysByInbox = {};
      final Set<String> orgAddresses = {};

      for (final key in rawKeys) {
        final address = key['address'] as String;
        final label = key['label'] as String;
        final privateKey = key['privateKey'] as String;
        final isGroupKey = key['isGroupKey'] == true;
        final orgAddress = key['orgAddress'] as String?;

        if (isGroupKey && orgAddress != null) {
          orgAddresses.add(orgAddress);
        }

        debugPrint(
            '[InboxMgr]   Key "$label" addr=${address.length >= 10 ? address.substring(0, 10) : address}... isGroup=$isGroupKey');

        try {
          final inboxId =
              await PublicOSConversations.inboxIdFromAddress(address);
          debugPrint('[InboxMgr]   -> inboxIdFromAddress = ${inboxId ?? "null"}');
          if (inboxId != null && inboxId.isNotEmpty) {
            keysByInbox.putIfAbsent(inboxId, () => []);
            keysByInbox[inboxId]!.add(_KeyInfo(
              label: label,
              address: address,
              privateKeyHex: privateKey,
            ));
          }
        } catch (e) {
          debugPrint('[InboxMgr]   -> ERROR resolving inbox ID: $e');
        }
      }

      debugPrint(
          '[InboxMgr] Step 1 result: ${keysByInbox.length} unique inbox IDs from keys');
      for (final entry in keysByInbox.entries) {
        debugPrint(
            '[InboxMgr]   inboxId=${entry.key} keys=[${entry.value.map((k) => k.label).join(", ")}]');
      }

      // Step 2: Contract query → registered inbox IDs.
      // The 3-second delay gives the XMTP manager contract + RPC state a
      // beat to settle after any recent selectKey / reinitialize flow.
      // Without it, keys that were "just loaded" silently drop out of
      // Step 2 on first open.
      final Map<String, _RegistrationInfo> registrations = {};

      if (settle) await Future.delayed(const Duration(seconds: 3));

      final userRegistered =
          await PublicOSXmtp.getAllAccountInboxIds(userAddress);
      debugPrint(
          '[InboxMgr] Step 2: contract returned ${userRegistered?.inboxIds.length ?? 0} registered inbox IDs');
      if (userRegistered != null) {
        for (int i = 0; i < userRegistered.inboxIds.length; i++) {
          final inboxIdBytes = userRegistered.inboxIds[i];
          final inboxIdString = bytes32ToString(inboxIdBytes);
          final label = i < userRegistered.labels.length
              ? userRegistered.labels[i]
              : '';
          registrations[inboxIdString] = _RegistrationInfo(
            accountAddress: userAddress,
            label: label,
            inboxIdBytes: inboxIdBytes,
          );
        }
      }

      for (final orgAddr in orgAddresses) {
        try {
          final orgAddress = EthereumAddress.fromHex(orgAddr);
          final groupRegistered =
              await PublicOSXmtp.getAllAccountInboxIds(orgAddress);
          if (groupRegistered != null) {
            for (int i = 0; i < groupRegistered.inboxIds.length; i++) {
              final inboxIdBytes = groupRegistered.inboxIds[i];
              final inboxIdString = bytes32ToString(inboxIdBytes);
              final label = i < groupRegistered.labels.length
                  ? groupRegistered.labels[i]
                  : '';
              registrations.putIfAbsent(
                inboxIdString,
                () => _RegistrationInfo(
                  accountAddress: orgAddress,
                  label: label,
                  inboxIdBytes: inboxIdBytes,
                ),
              );
            }
          }
        } catch (_) {
          // Org registration query failure is non-fatal.
        }
      }

      // Step 3: Cross-reference → unified list
      final allInboxIds = <String>{
        ...keysByInbox.keys,
        ...registrations.keys,
      };

      debugPrint(
          '[InboxMgr] Step 3: ${allInboxIds.length} unique inbox IDs total');
      final keysOnly = keysByInbox.keys
          .where((id) => !registrations.containsKey(id))
          .toList();
      final contractOnly = registrations.keys
          .where((id) => !keysByInbox.containsKey(id))
          .toList();
      final matched = keysByInbox.keys
          .where((id) => registrations.containsKey(id))
          .toList();
      debugPrint('[InboxMgr]   Matched (key+contract): $matched');
      debugPrint('[InboxMgr]   Key-only (no contract match): $keysOnly');
      debugPrint('[InboxMgr]   Contract-only (no key match): $contractOnly');

      final entries = <_InboxEntry>[];
      for (final inboxId in allInboxIds) {
        entries.add(_InboxEntry(
          inboxId: inboxId,
          localKeys: keysByInbox[inboxId] ?? const [],
          registration: registrations[inboxId],
        ));
      }

      entries.sort((a, b) {
        final aScore = (a.isManageable ? 2 : 0) + (a.isRegistered ? 1 : 0);
        final bScore = (b.isManageable ? 2 : 0) + (b.isRegistered ? 1 : 0);
        if (aScore != bScore) return bScore.compareTo(aScore);
        return a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase());
      });

      debugPrint('[InboxMgr] Final entries:');
      for (final e in entries) {
        debugPrint(
            '[InboxMgr]   "${e.displayName}" inbox=${e.inboxId} keys=${e.localKeys.length} registered=${e.isRegistered} manageable=${e.isManageable}');
      }

      // Step 4: Resolve account contacts
      await _resolveAccountContacts(entries, userAddress);

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      setState(() {
        _error = localizedError(l10n, e, fallback: l10n.errLoadContent);
        _isLoading = false;
      });
    }
  }

  /// Reload after a confirmed register / rename / remove: no settle delay,
  /// the list stays on screen, and the corner loader shows until it lands.
  Future<void> _reloadAfterWrite() async {
    if (!mounted) return;
    setState(() => _refreshing = true);
    await _loadData(silent: true, settle: false);
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _resolveAccountContacts(
    List<_InboxEntry> entries,
    EthereumAddress userAddress,
  ) async {
    for (int i = 0; i < entries.length; i++) {
      final reg = entries[i].registration;
      if (reg == null) continue;

      Contact? contact;
      if (reg.accountAddress == userAddress) {
        contact = _myContact;
      } else {
        try {
          contact = await PublicOSContacts.searchContacts(
            reg.accountAddress.eip55With0x,
          );
        } catch (_) {}
      }

      if (contact != null) {
        entries[i] = _InboxEntry(
          inboxId: entries[i].inboxId,
          localKeys: entries[i].localKeys,
          registration: _RegistrationInfo(
            accountAddress: reg.accountAddress,
            label: reg.label,
            inboxIdBytes: reg.inboxIdBytes,
            accountContact: contact,
          ),
        );
      }
    }
  }

  // ---- expansion ------------------------------------------------------------

  AnimationController _getOrCreateController(String inboxId) {
    if (!_animControllers.containsKey(inboxId)) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      _animControllers[inboxId] = controller;
      _expandAnims[inboxId] = CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      );
    }
    return _animControllers[inboxId]!;
  }

  Future<void> _toggleExpanded(String inboxId) async {
    final controller = _getOrCreateController(inboxId);

    if (_expandedInboxId == inboxId) {
      await controller.reverse();
      if (mounted) setState(() => _expandedInboxId = null);
      return;
    }

    if (_expandedInboxId != null) {
      await _animControllers[_expandedInboxId]?.reverse();
    }
    // Mark as "selected" (drives the chevron → spinner swap) and blow
    // away any stale per-inbox cache so the next render starts clean.
    // Deliberately NOT calling `controller.forward()` here — we defer the
    // expand animation until the fetch completes, so the user never sees
    // an empty drawer + in-content spinner. Instead the row's trailing
    // chevron shows a spinner inline while we work, then we open the
    // drawer with the data already present.
    setState(() {
      _expandedInboxId = inboxId;
      _stateCache.remove(inboxId);
    });

    // Look up the entry so we can decide whether we have a local key
    // that belongs to this inbox — if not, skip the key-scoped fetch
    // (it'd return state for whatever key is currently active on the
    // XMTP client, which is a DIFFERENT inbox, and would paint the
    // wrong identities/installations in our drawer).
    final entry = _entries.firstWhere(
      (e) => e.inboxId == inboxId,
      orElse: () => _InboxEntry(inboxId: inboxId, localKeys: const []),
    );

    if (entry.localKeys.isNotEmpty) {
      await _switchToKeyForInbox(inboxId);
      await _fetchInboxState(inboxId);
    }

    // User may have bailed / tapped a different row mid-fetch; don't
    // open the drawer for a stale selection.
    if (!mounted || _expandedInboxId != inboxId) return;
    unawaited(controller.forward());
  }

  Future<void> _switchToKeyForInbox(String inboxId) async {
    final entry = _entries.firstWhere(
      (e) => e.inboxId == inboxId,
      orElse: () => _entries.first,
    );
    if (entry.localKeys.isEmpty) return;

    final targetLabel = entry.localKeys.first.label;
    if (targetLabel == PublicOS.currentXmtpKeyLabel) return;

    final addrHex = PublicOS.myPublicosAddress;
    if (addrHex == null) return;

    try {
      await PublicOSKeychain.selectKey(addrHex, targetLabel);
      _stateCache.remove(inboxId);
    } catch (_) {}
  }

  Future<void> _fetchInboxState(String inboxId) async {
    if (_loadingStates[inboxId] == true) return;
    setState(() => _loadingStates[inboxId] = true);

    try {
      final state =
          await PublicOSXmtp.getInboxState(refreshFromNetwork: true);
      if (!mounted) return;
      if (state == null) {
        setState(() => _loadingStates[inboxId] = false);
        return;
      }

      final identitiesList = state['identities'] as List? ?? [];
      final installationsList = state['installations'] as List? ?? [];
      final recoveryMap = state['recoveryIdentity'];

      final recoveryIdentifier =
          recoveryMap is Map ? recoveryMap['identifier'] as String? : null;
      bool hasRecoveryKey = false;
      if (recoveryIdentifier != null) {
        final addrHex = PublicOS.myPublicosAddress;
        if (addrHex != null) {
          try {
            final allKeys = await PublicOSKeychain.fetchKeys(addrHex);
            hasRecoveryKey = allKeys.any((k) =>
                (k['address'] as String?)?.toLowerCase() ==
                recoveryIdentifier.toLowerCase());
          } catch (_) {}
        }
      }

      if (!mounted) return;
      setState(() {
        _stateCache[inboxId] = _InboxStateData(
          inboxId: state['inboxId'] as String? ?? inboxId,
          identities: identitiesList
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
          installations: installationsList
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
          recoveryIdentity:
              recoveryMap is Map ? Map<String, dynamic>.from(recoveryMap) : null,
          hasRecoveryKeyLocally: hasRecoveryKey,
        );
        _loadingStates[inboxId] = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingStates[inboxId] = false);
    }
  }

  // ---- key helpers ----------------------------------------------------------

  Future<List<_KeyInfo>> _findMatchingKeysForInbox(
      _InboxStateData inboxState) async {
    final addrHex = PublicOS.myPublicosAddress;
    if (addrHex == null) return const [];

    final allKeys = await PublicOSKeychain.fetchKeys(addrHex);
    final inboxAddresses = inboxState.identities
        .map((i) => (i['identifier'] as String?)?.toLowerCase())
        .whereType<String>()
        .toSet();

    final matching = <_KeyInfo>[];
    for (final key in allKeys) {
      final addr = (key['address'] as String?)?.toLowerCase();
      if (addr != null && inboxAddresses.contains(addr)) {
        matching.add(_KeyInfo(
          label: key['label'] as String,
          address: key['address'] as String,
          privateKeyHex: key['privateKey'] as String,
        ));
      }
    }
    return matching;
  }

  Future<_KeyInfo?> _getRecoveryKey(_InboxStateData inboxState) async {
    final recoveryId =
        inboxState.recoveryIdentity?['identifier'] as String?;
    if (recoveryId == null) return null;

    final keys = await _findMatchingKeysForInbox(inboxState);
    try {
      return keys.firstWhere(
          (k) => k.address.toLowerCase() == recoveryId.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  Future<_KeyInfo?> _pickSigningKey(
      List<_KeyInfo> keys, String purpose) async {
    if (keys.isEmpty) {
      _showSnack(context.l10n.inboxIdsNoMatchingKeys);
      return null;
    }
    if (keys.length == 1) return keys.first;

    return showDialog<_KeyInfo>(
      context: context,
      builder: (ctx) => _KeyPickerDialog(keys: keys, purpose: purpose),
    );
  }

  // ---- simple actions -------------------------------------------------------

  void _copyInboxId(String inboxId) {
    Clipboard.setData(ClipboardData(text: inboxId));
    _showSnack(context.l10n.inboxIdsInboxIdCopied);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Localize a caught error and show it via [_showSnack]. Sync method, so
  /// async catch sites stay free of use_build_context_synchronously.
  void _snackError(Object e, {String Function(AppLocalizations)? fallback}) {
    if (!mounted) return;
    final l10n = context.l10n;
    _showSnack(localizedError(l10n, e, fallback: fallback?.call(l10n)));
  }

  // ---- Tier A: register / rename / remove -----------------------------------

  Future<void> _registerInboxId(_InboxEntry entry) async {
    final l10n = context.l10n;
    // Registering always writes to MY directory, so the prefix is my name.
    final meHex = PublicOS.myPublicosAddress;
    if (meHex == null) return;
    final me = EthereumAddress.fromHex(meHex);
    final myName = await PublicOSAccounts.myDisplayName();
    if (!mounted) return;
    // THE shared inbox-tab dialog (twin of the client's): duplicate check,
    // ownership pre-check and the write all live there, and it only returns
    // `saved` once the chain said yes, so a duplicate label never spends gas,
    // reverts, and dismisses in silence.
    final result = await showInboxTabDialog(
      context,
      account: me,
      accountName: myName,
      inboxIdBytes: StringToBytes(entry.inboxId),
      mode: InboxTabMode.register,
      title: l10n.inboxIdsRegisterTitle,
      subtitle: l10n.inboxIdsRegisterSubtitle,
      cta: l10n.inboxIdsSave,
      initialLabel: entry.displayName,
    );
    if (result == null || !result.saved || !mounted) return;
    _showSnack(l10n.inboxIdsRegistered);
    await _reloadAfterWrite();
  }

  Future<void> _editLabel(_InboxEntry entry) async {
    final reg = entry.registration;
    if (reg == null) return;

    final l10n = context.l10n;
    // Rename rides the same dialog: the tab being renamed is excluded from the
    // duplicate check and stands in as the ghost tab.
    final result = await showInboxTabDialog(
      context,
      account: reg.accountAddress,
      accountName: reg.accountContact?.displayName,
      inboxIdBytes: reg.inboxIdBytes,
      mode: InboxTabMode.rename,
      title: l10n.inboxIdsEditLabelTitle,
      subtitle: l10n.inboxIdsEditLabelSubtitle,
      cta: l10n.inboxIdsSave,
      currentLabel: reg.label,
      initialLabel: reg.label,
    );
    if (result == null || !result.saved || !mounted) return;
    _showSnack(l10n.inboxIdsLabelUpdated);
    await _reloadAfterWrite();
  }

  Future<void> _removeFromRegistry(_InboxEntry entry) async {
    final reg = entry.registration;
    if (reg == null) return;

    final l10n = context.l10n;
    // The same dialog as register/rename, mirrored: the tab being taken away
    // is struck through under the ones that stay. It owns
    // the write and waits for the chain, so a failure is explained in place
    // instead of dismissing with a snackbar the user may not connect to it.
    final result = await showInboxTabDialog(
      context,
      account: reg.accountAddress,
      accountName: reg.accountContact?.displayName,
      inboxIdBytes: reg.inboxIdBytes,
      mode: InboxTabMode.remove,
      title: l10n.inboxIdsRemoveTitle,
      subtitle: l10n.inboxIdsRemoveBody(entry.displayName),
      cta: l10n.inboxIdsRemoveAction,
      currentLabel: reg.label,
    );
    if (result == null || !result.saved || !mounted) return;
    _showSnack(l10n.inboxIdsRemoved);
    await _reloadAfterWrite();
  }

  // ---- Tier B: sync + revoke ------------------------------------------------

  Future<void> _syncConsentPreferences() async {
    if (_isSyncingConsent) return;
    final l10n = context.l10n;
    setState(() => _isSyncingConsent = true);
    try {
      final success = await PublicOSXmtp.syncConsentPreferences();
      _showSnack(success
          ? l10n.inboxIdsConsentSynced
          : l10n.inboxIdsConsentSyncFailed);
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _isSyncingConsent = false);
    }
  }

  Future<void> _sendSyncRequest() async {
    if (_isSyncingHistory) return;
    final l10n = context.l10n;
    setState(() => _isSyncingHistory = true);
    try {
      final success = await PublicOSXmtp.sendSyncRequest();
      _showSnack(success
          ? l10n.inboxIdsHistorySyncRequested
          : l10n.inboxIdsHistorySyncFailed);
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _isSyncingHistory = false);
    }
  }

  Future<void> _confirmRevokeInstallation(
    String installationId,
    _InboxStateData inboxState,
  ) async {
    final l10n = context.l10n;
    final confirmed = await _confirmDestructive(
      title: l10n.inboxIdsRevokeInstallationTitle,
      body: l10n.inboxIdsRevokeInstallationBody(shortenString(installationId)),
      destructiveLabel: l10n.inboxIdsRevokeAction,
    );
    if (confirmed != true || !mounted) return;

    final matchingKeys = await _findMatchingKeysForInbox(inboxState);
    if (matchingKeys.isEmpty) {
      _showSnack(l10n.inboxIdsNoSigningKey);
      return;
    }
    if (!mounted) return;

    final signingKey =
        await _pickSigningKey(matchingKeys, l10n.inboxIdsPurposeRevokeInstallation);
    if (signingKey == null || !mounted) return;

    try {
      setState(() => _isLoading = true);
      final privateKeyBytes =
          PublicOSKeychain.hexToBytes(signingKey.privateKeyHex);
      final success = await PublicOSXmtp.revokeInstallations(
        privateKeyBytes,
        [installationId],
      );
      if (success && mounted) {
        _showSnack(l10n.inboxIdsInstallationRevoked);
        if (_expandedInboxId != null) {
          _stateCache.remove(_expandedInboxId);
          await _fetchInboxState(_expandedInboxId!);
        }
      } else if (mounted) {
        _showSnack(l10n.inboxIdsInstallationRevokeFailed);
      }
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmRevokeAllOthers(
    _InboxEntry entry,
    _InboxStateData inboxState,
  ) async {
    final otherCount = inboxState.installations.length - 1;
    final l10n = context.l10n;

    final confirmed = await _confirmDestructive(
      title: l10n.inboxIdsRevokeAllTitle,
      body: l10n.inboxIdsRevokeAllBody(otherCount),
      destructiveLabel: l10n.inboxIdsRevokeAllAction,
    );
    if (confirmed != true || !mounted) return;

    final matchingKeys = await _findMatchingKeysForInbox(inboxState);
    if (matchingKeys.isEmpty) {
      _showSnack(l10n.inboxIdsNoSigningKey);
      return;
    }
    if (!mounted) return;

    final signingKey = await _pickSigningKey(
      matchingKeys,
      l10n.inboxIdsPurposeRevokeAllOthers,
    );
    if (signingKey == null || !mounted) return;

    try {
      setState(() => _isLoading = true);
      final privateKeyBytes =
          PublicOSKeychain.hexToBytes(signingKey.privateKeyHex);
      final success =
          await PublicOSXmtp.revokeAllOtherInstallations(privateKeyBytes);
      if (success && mounted) {
        _showSnack(l10n.inboxIdsAllOthersRevoked);
        _stateCache.remove(entry.inboxId);
        await _fetchInboxState(entry.inboxId);
      } else if (mounted) {
        _showSnack(l10n.inboxIdsRevokeInstallationsFailed);
      }
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---- Tier C: remove account / recovery / add account ---------------------

  Future<void> _confirmRemoveAccount(
    String identifier,
    _InboxStateData inboxState,
  ) async {
    final l10n = context.l10n;
    final confirmed = await _confirmDestructive(
      title: l10n.inboxIdsRemoveAccountTitle,
      body: l10n.inboxIdsRemoveAccountBody(shortenString(identifier)),
      destructiveLabel: l10n.inboxIdsRemoveAction,
    );
    if (confirmed != true || !mounted) return;

    final recoveryKey = await _getRecoveryKey(inboxState);
    if (recoveryKey == null) {
      _showSnack(l10n.inboxIdsRecoveryKeyNotFound);
      return;
    }

    try {
      setState(() => _isLoading = true);
      final privateKeyBytes =
          PublicOSKeychain.hexToBytes(recoveryKey.privateKeyHex);
      final success = await PublicOSXmtp.removeAccountFromInbox(
        privateKeyBytes,
        identifier,
      );
      if (success && mounted) {
        _showSnack(l10n.inboxIdsAccountRemoved);
        if (_expandedInboxId != null) {
          _stateCache.remove(_expandedInboxId);
          await _fetchInboxState(_expandedInboxId!);
        }
      } else if (mounted) {
        _showSnack(l10n.inboxIdsAccountRemoveFailed);
      }
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showOfflineRecoveryDialog(_InboxEntry entry) async {
    final l10n = context.l10n;
    final proceed = await _confirmDestructive(
      title: l10n.inboxIdsOfflineRecovery,
      body: l10n.inboxIdsOfflineRecoveryBody,
      destructiveLabel: l10n.inboxIdsContinue,
    );
    if (proceed != true || !mounted) return;

    final keyMethod = await showDialog<String>(
      context: context,
      builder: (_) => const _RecoveryKeyMethodDialog(),
    );
    if (keyMethod == null || !mounted) return;

    Uint8List? recoveryKeyBytes;

    if (keyMethod == 'keychain') {
      final addrHex = PublicOS.myPublicosAddress;
      if (addrHex == null) {
        _showSnack(l10n.inboxIdsUserAddressUnavailable);
        return;
      }
      final allKeys = await PublicOSKeychain.fetchKeys(addrHex);
      if (allKeys.isEmpty) {
        _showSnack(l10n.inboxIdsNoKeysInKeychain);
        return;
      }
      if (!mounted) return;
      final selectedKey = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => _KeychainPickerDialog(
          keys: allKeys,
          title: l10n.inboxIdsSelectRecoveryKey,
        ),
      );
      if (selectedKey == null || !mounted) return;
      recoveryKeyBytes =
          PublicOSKeychain.hexToBytes(selectedKey['privateKey'] as String);
    } else {
      final isHex = keyMethod == 'hex';
      final input = await _promptSecret(
        title: isHex ? l10n.inboxIdsEnterPrivateKey : l10n.inboxIdsEnterMnemonic,
        hint: isHex ? l10n.inboxIdsHintPrivateKey : l10n.inboxIdsHintMnemonic,
        maxLines: isHex ? 1 : 3,
      );
      if (input == null || input.isEmpty || !mounted) return;
      try {
        if (isHex) {
          recoveryKeyBytes = PublicOSKeychain.hexToBytes(input);
        } else {
          final mnemonicList =
              input.split(' ').where((s) => s.isNotEmpty).toList();
          final keyInfo = PublicOSKeychain.deriveKeyFromMnemonic(mnemonicList);
          recoveryKeyBytes =
              PublicOSKeychain.hexToBytes(keyInfo['privateKeyHex'] as String);
        }
      } catch (_) {
        _showSnack(l10n.inboxIdsInvalidKeyFormat);
        return;
      }
    }

    await _performOfflineRecovery(entry.inboxId, recoveryKeyBytes);
  }

  Future<void> _performOfflineRecovery(
    String inboxId,
    Uint8List recoveryKeyBytes,
  ) async {
    if (_isRevokingOffline) return;
    final l10n = context.l10n;
    setState(() => _isRevokingOffline = true);

    try {
      _showSnack(l10n.inboxIdsQueryingInboxState);
      final states = await PublicOSXmtp.getInboxStates(
        [inboxId],
        refreshFromNetwork: true,
      );
      if (states == null || states.isEmpty) {
        _showSnack(l10n.inboxIdsInboxNotFound);
        return;
      }

      final state = states.first;
      final installations = (state['installations'] as List?)
              ?.map((i) => Map<String, dynamic>.from(i as Map))
              .toList() ??
          [];
      if (installations.isEmpty) {
        _showSnack(l10n.inboxIdsNoInstallationsToRevoke);
        return;
      }

      if (!mounted) return;
      final confirmed = await _confirmDestructive(
        title: l10n.inboxIdsConfirmRecoveryTitle,
        body: l10n.inboxIdsConfirmRecoveryBody(installations.length),
        destructiveLabel: l10n.inboxIdsRevokeAllAction,
      );
      if (confirmed != true || !mounted) return;

      _showSnack(l10n.inboxIdsRevokingInstallations(installations.length));
      final installationIds =
          installations.map((i) => i['id'] as String).toList();

      await PublicOSXmtp.staticRevokeInstallations(
        signerPrivateKey: recoveryKeyBytes,
        inboxId: inboxId,
        installationIds: installationIds,
      );

      if (mounted) {
        _showSnack(l10n.inboxIdsRevokedInstallations(installations.length));
        _stateCache.remove(inboxId);
        if (_expandedInboxId == inboxId) {
          await _fetchInboxState(inboxId);
        }
      }
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _isRevokingOffline = false);
    }
  }

  Future<void> _showAddAccountDialog(
    _InboxEntry entry,
    _InboxStateData inboxState,
  ) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => const _AddAccountOptionsDialog(),
    );
    if (choice == null || !mounted) return;

    if (choice == 'keychain') {
      await _showKeychainPickerForAddAccount(entry, inboxState);
    } else if (choice == 'import') {
      await _showImportOptionsForAddAccount(entry);
    }
  }

  Future<void> _showKeychainPickerForAddAccount(
    _InboxEntry entry,
    _InboxStateData inboxState,
  ) async {
    final l10n = context.l10n;
    final addrHex = PublicOS.myPublicosAddress;
    if (addrHex == null) {
      _showSnack(l10n.inboxIdsUserAddressUnavailable);
      return;
    }

    final allKeys = await PublicOSKeychain.fetchKeys(addrHex);
    final existingAddresses = inboxState.identities
        .map((i) => (i['identifier'] as String?)?.toLowerCase())
        .whereType<String>()
        .toSet();

    final availableKeys = allKeys.where((k) {
      final addr = (k['address'] as String?)?.toLowerCase();
      return addr != null && !existingAddresses.contains(addr);
    }).toList();

    if (availableKeys.isEmpty) {
      _showSnack(l10n.inboxIdsNoAvailableKeys);
      return;
    }
    if (!mounted) return;

    final selectedKey = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _KeychainPickerDialog(
        keys: availableKeys,
        title: l10n.inboxIdsSelectKeyToLink,
      ),
    );
    if (selectedKey == null || !mounted) return;

    final keyAddress = selectedKey['address'] as String;
    final canMessage = await PublicOSConversations.canMessage(keyAddress);

    if (canMessage && mounted) {
      final proceed = await _confirmDestructive(
        title: l10n.inboxIdsKeyAlreadyLinkedTitle,
        body: l10n.inboxIdsKeyAlreadyLinkedBodyKeychain,
        destructiveLabel: l10n.inboxIdsProceedAnyway,
      );
      if (proceed != true) return;
    }

    await _performAddAccount(selectedKey, allowReassign: canMessage);
  }

  Future<void> _showImportOptionsForAddAccount(_InboxEntry entry) async {
    final l10n = context.l10n;
    final importType = await showDialog<String>(
      context: context,
      builder: (_) => const _ImportOptionsDialog(),
    );
    if (importType == null || !mounted) return;

    final input = await _promptSecret(
      title: importType == 'mnemonic'
          ? l10n.inboxIdsEnterMnemonic
          : l10n.inboxIdsEnterPrivateKey,
      hint: importType == 'mnemonic'
          ? l10n.inboxIdsHintMnemonic
          : l10n.inboxIdsHintPrivateKey,
      maxLines: importType == 'mnemonic' ? 3 : 1,
    );
    if (input == null || input.isEmpty || !mounted) return;

    Uint8List privateKeyBytes;
    String address;
    try {
      if (importType == 'mnemonic') {
        final mnemonicList =
            input.split(' ').where((s) => s.isNotEmpty).toList();
        final keyInfo = PublicOSKeychain.deriveKeyFromMnemonic(mnemonicList);
        address = keyInfo['address'] as String;
        privateKeyBytes =
            PublicOSKeychain.hexToBytes(keyInfo['privateKeyHex'] as String);
      } else {
        final hex = input.trim();
        privateKeyBytes = PublicOSKeychain.hexToBytes(hex);
        address = EthPrivateKey.fromHex(hex).address.eip55With0x;
      }
    } catch (_) {
      _showSnack(l10n.inboxIdsErrorInvalidKeyFormat);
      return;
    }

    try {
      final canMessage = await PublicOSConversations.canMessage(address);
      if (canMessage && mounted) {
        final proceed = await _confirmDestructive(
          title: l10n.inboxIdsKeyAlreadyLinkedTitle,
          body: l10n.inboxIdsKeyAlreadyLinkedBodyImport,
          destructiveLabel: l10n.inboxIdsProceed,
        );
        if (proceed != true) return;
      }

      setState(() => _isLoading = true);
      final success = await PublicOSXmtp.addAccountToInbox(
        privateKeyBytes,
        allowReassignInboxId: canMessage,
      );
      if (success && mounted) {
        _showSnack(l10n.inboxIdsAccountAdded);
        _stateCache.remove(entry.inboxId);
        await _fetchInboxState(entry.inboxId);
      } else if (mounted) {
        _showSnack(l10n.inboxIdsAccountAddFailed);
      }
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performAddAccount(
    Map<String, dynamic> keyData, {
    bool allowReassign = false,
  }) async {
    final l10n = context.l10n;
    try {
      setState(() => _isLoading = true);
      final privateKeyHex = keyData['privateKey'] as String;
      final privateKeyBytes = PublicOSKeychain.hexToBytes(privateKeyHex);

      final success = await PublicOSXmtp.addAccountToInbox(
        privateKeyBytes,
        allowReassignInboxId: allowReassign,
      );
      if (success && mounted) {
        _showSnack(l10n.inboxIdsAccountAdded);
        if (_expandedInboxId != null) {
          _stateCache.remove(_expandedInboxId);
          await _fetchInboxState(_expandedInboxId!);
        }
      } else if (mounted) {
        _showSnack(l10n.inboxIdsAccountAddFailed);
      }
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---- prompt / confirm dialog helpers -------------------------------------

  Future<String?> _promptSecret({
    required String title,
    required String hint,
    int maxLines = 1,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final tokens = GlassTokens.of(ctx);
        return Dialog(
          backgroundColor: Colors.transparent,
          constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: GlassTheme.glassBox(ctx).copyWith(
              color: tokens.surfaceDeep,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'SpaceGrotesk', 
                    color: tokens.starkWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: maxLines,
                  style: const TextStyle(fontFamily: 'monospace')
                      .copyWith(color: tokens.starkWhite),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(fontFamily: 'SpaceGrotesk', color: tokens.textDim),
                    filled: true,
                    fillColor: tokens.glassFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: tokens.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: tokens.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: tokens.borderMedium),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: tokens.starkWhite,
                          side: BorderSide(color: tokens.borderMedium),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          context.l10n.actionCancel,
                          style: TextStyle(fontFamily: 'SpaceGrotesk', 
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.starkWhite,
                          foregroundColor: tokens.background,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () =>
                            Navigator.pop(ctx, controller.text.trim()),
                        child: Text(
                          context.l10n.inboxIdsContinue,
                          style: TextStyle(fontFamily: 'SpaceGrotesk',
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDestructive({
    required String title,
    required String body,
    required String destructiveLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tokens = GlassTokens.of(ctx);
        return Dialog(
          backgroundColor: Colors.transparent,
          constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: GlassTheme.glassBox(ctx).copyWith(
              color: tokens.surfaceDeep,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: tokens.fallbackAccent,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'SpaceGrotesk', 
                    color: tokens.starkWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'SpaceGrotesk', 
                    color: tokens.textDim,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: tokens.starkWhite,
                          side: BorderSide(color: tokens.borderMedium),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          context.l10n.actionCancel,
                          style: TextStyle(fontFamily: 'SpaceGrotesk', 
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.fallbackAccent,
                          foregroundColor: tokens.background,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          destructiveLabel,
                          style: TextStyle(fontFamily: 'SpaceGrotesk', 
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SystemAppScaffold(
      title: context.l10n.inboxIdsTitle,
      icon: Icons.inbox_rounded,
      pinHeader: true,
      builder: (context, scrollController, tokens) {
        return Stack(
          children: [
            if (!_isLoading)
              RefreshIndicator(
                onRefresh: () => _loadData(silent: true),
                color: tokens.starkWhite,
                backgroundColor: tokens.surfaceElevated,
                edgeOffset:
                    MediaQuery.of(context).padding.top + kToolbarHeight,
                child: _buildBody(scrollController, tokens),
              ),
            // Rain + the animated "Loading…" caption, on first load and while
            // a publish / rename / remove is being picked up. It owns its
            // corner; the page runs to the bottom edge, hence safeBottom.
            if (_isLoading || _refreshing)
              const Positioned.fill(
                child: PixelRainLoadingCorner(safeBottom: true),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController, GlassTokens tokens) {
    if (_error != null && _entries.isEmpty) {
      // Wrap the error in a scroll body so RefreshIndicator can still pull.
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          SizedBox(height: kToolbarHeight + 60),
          _buildErrorState(tokens),
        ],
      );
    }

    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        SizedBox(height: kToolbarHeight + 60),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                tokens,
                Icons.inbox_rounded,
                context.l10n.inboxIdsInboxesHeader,
                trailing: _entries.isEmpty
                    ? null
                    : _pillBadge(
                        tokens,
                        '${_entries.length}',
                        tokens.connectedAccent,
                      ),
              ),
              const SizedBox(height: 14),
              if (_entries.isEmpty)
                _buildEmptyInboxState(tokens)
              else
                ..._entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildInboxRow(e, tokens),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shared-shape helpers (copied verbatim from treasury_page.dart's
  // _sectionHeader / _pillBadge, the system-app page anatomy). Local copies,
  // not shared, per the convention.

  Widget _sectionHeader(
    GlassTokens tokens,
    IconData icon,
    String title, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: tokens.connectedAccent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _pillBadge(GlassTokens tokens, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: color,
        ),
      ),
    );
  }

  Widget _buildErrorState(GlassTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: tokens.fallbackAccent),
            const SizedBox(height: 14),
            Text(
              context.l10n.inboxIdsLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'SpaceGrotesk', 
                color: tokens.starkWhite,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'SpaceGrotesk', 
                color: tokens.textDim,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.starkWhite,
                side: BorderSide(color: tokens.borderMedium),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: _loadData,
              child: Text(
                context.l10n.inboxIdsRetry,
                style: TextStyle(fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInboxState(GlassTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 44, color: tokens.textDim),
            const SizedBox(height: 12),
            Text(
              context.l10n.inboxIdsEmptyTitle,
              style: TextStyle(fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.inboxIdsEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'SpaceGrotesk', 
                color: tokens.textDim,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInboxRow(_InboxEntry entry, GlassTokens tokens) {
    final isExpanded = _expandedInboxId == entry.inboxId;
    final controller = _getOrCreateController(entry.inboxId);
    final expandAnim = _expandAnims[entry.inboxId];
    final contact = entry.registration?.accountContact;
    final truncatedId = entry.inboxId.length > 16
        ? '${entry.inboxId.substring(0, 8)}…${entry.inboxId.substring(entry.inboxId.length - 6)}'
        : entry.inboxId;
    // Registered title: short names join the inbox label with a slash
    // (e.g. "jmsl/personal", the browser's domain/tab shape); names over 8 chars
    // are clipped to 7 plus an ellipsis (e.g. "jonatha…/personal").
    final accountName = contact?.displayName ?? '';
    final inboxLabel = entry.registration?.label ?? '';
    final registeredTitle = inboxLabel.isNotEmpty
        ? (accountName.isEmpty
            ? inboxLabel
            : (accountName.length <= 8
                ? '$accountName/$inboxLabel'
                : '${accountName.substring(0, 7)}…/$inboxLabel'))
        : (accountName.isEmpty ? truncatedId : accountName);
    // Row-level banner backdrop — registered inboxes only. Local-only
    // keys have no on-chain contact yet, so `rowContact` is null
    // and they render on the plain glass surface.
    final rowContact = entry.registration?.accountContact;
    final showRowBanner = _showBanner && rowContact != null;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: tokens.glassFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isExpanded
                  ? tokens.borderMedium
                  : tokens.borderSubtle,
              width: isExpanded ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              if (showRowBanner)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.12,
                    child: ContactBanner(
                      contact: rowContact,
                      fallback: const SizedBox.shrink(),
                    ),
                  ),
                ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: entry.isManageable
                      ? () => _toggleExpanded(entry.inboxId)
                      : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    if (contact != null)
                      GlassContactIcon(contact: contact, size: 44)
                    else
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: entry.fallbackColor.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tokens.starkWhite.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.inbox_outlined,
                          size: 20,
                          color: tokens.starkWhite.withValues(alpha: 0.7),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: entry.isRegistered
                          // Published: "{name}.{label}" for short names, or
                          // "{name[0..7]}…{label}" when the name exceeds 8 chars.
                          ? Text(
                              registeredTitle,
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                color: tokens.starkWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          // Not published: no owner name/badge — just the raw
                          // inbox ID.
                          : Text(
                              truncatedId,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: tokens.starkWhite,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    _rowActions(entry, isExpanded, controller, tokens),
                  ],
                ),
              ),
            ),
          ),
            ],
          ),
        ),
        if (expandAnim != null)
          SizeTransition(
            sizeFactor: expandAnim,
            axisAlignment: -1,
            child: _buildExpandedSection(entry, tokens),
          ),
      ],
    );
  }

  Widget _rowActions(
    _InboxEntry entry,
    bool isExpanded,
    AnimationController controller,
    GlassTokens tokens,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RowIconButton(
          icon: Icons.copy_rounded,
          onTap: () => _copyInboxId(entry.inboxId),
          tokens: tokens,
        ),
        if (entry.isRegistered) ...[
          // "Rename label" lives inside the expanded drawer's Quick
          // actions so the row stays narrow enough to keep the trailing
          // chevron on-screen for registered inboxes.
          const SizedBox(width: 4),
          // "remove from tab" glyph (feeds nav) — un-publishing an inbox ID
          // from the profile is the same kind of action as dropping a feed tab.
          _RowIconButton(
            icon: Icons.tab_unselected,
            destructive: true,
            tooltip: context.l10n.inboxIdsRemoveTooltip,
            onTap: () => _removeFromRegistry(entry),
            tokens: tokens,
          ),
        ] else if (entry.isManageable) ...[
          const SizedBox(width: 4),
          // "add as tab" glyph (feeds nav) — publishing an inbox ID to the
          // profile is the same kind of action as pinning a feed tab.
          _RowIconButton(
            icon: Icons.tab_rounded,
            primary: true,
            tooltip: context.l10n.inboxIdsAddTooltip,
            onTap: () => _registerInboxId(entry),
            tokens: tokens,
          ),
        ],
        // Show the chevron for any row the user can drill into — local
        // keys (manageable) OR on-chain registrations with no local key
        // (we still surface the linked accounts + label + register info
        // inside, just skip the key-scoped fetch).
        if (entry.isManageable || entry.isRegistered) ...[
          const SizedBox(width: 4),
          // While the inbox state is being fetched, the chevron is
          // replaced in-place with a spinner so the row itself signals
          // "I'm working on it" — the drawer below stays closed until
          // the fetch completes (see `_toggleExpanded`), so the user
          // sees a single clean open animation instead of drawer →
          // in-drawer spinner → content.
          if (_loadingStates[entry.inboxId] == true)
            // Match `_RowIconButton`'s shape exactly (34×34, glassFill,
            // borderSubtle, rounded-8) so the swap reads as "same button,
            // doing work" instead of a spinner floating next to the other
            // action buttons.
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tokens.glassFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.borderSubtle),
              ),
              alignment: Alignment.center,
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: tokens.starkWhite,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return Transform.rotate(
                  angle: controller.value * 1.5708,
                  child: _RowIconButton(
                    icon: Icons.expand_more_rounded,
                    onTap: () => _toggleExpanded(entry.inboxId),
                    tokens: tokens,
                  ),
                );
              },
            ),
        ],
      ],
    );
  }

  Widget _buildExpandedSection(_InboxEntry entry, GlassTokens tokens) {
    final inboxState = _stateCache[entry.inboxId];
    final isLoading = _loadingStates[entry.inboxId] == true;

    // Tri-state render:
    //   - isLoading  → spinner (fetch in flight — though normally the
    //     drawer won't open until fetch completes thanks to _toggleExpanded,
    //     so this is defensive only)
    //   - inboxState == null && no local key → "no local key on this
    //     device" message (user can still see the label + register, but
    //     identities + installations require a key)
    //   - otherwise → full content
    //
    // Collapsing `inboxState == null → spinner` into the loading check
    // prevents a "Failed to load" flash on the first frame after expand.
    final noLocalKey = inboxState == null && !entry.isManageable;
    final showSpinner = isLoading || (inboxState == null && !noLocalKey);

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceDeep.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: showSpinner
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: tokens.starkWhite,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          : noLocalKey
              ? _buildNoLocalKeyState(entry, tokens)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Non-null here: the noLocalKey branch caught the
                    // registered-without-key case, and the spinner branch
                    // catches `inboxState == null` for loading rows.
                    _buildLinkedAccounts(inboxState!, tokens),
                    const SizedBox(height: 14),
                    _buildInstallations(inboxState, tokens),
                    const SizedBox(height: 14),
                    _buildQuickActions(entry, inboxState, tokens),
                  ],
                ),
    );
  }

  /// Shown when the user expands a registered inbox that has no local
  /// key on this device. We can't fetch identities/installations (those
  /// require the XMTP client to be on that key), so the drawer just
  /// surfaces an explainer + the existing copy/delete row actions stay
  /// available up above.
  Widget _buildNoLocalKeyState(_InboxEntry entry, GlassTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.no_encryption_gmailerrorred_rounded,
              size: 18,
              color: tokens.fallbackAccent,
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.inboxIdsNoLocalKeyTitle,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.inboxIdsNoLocalKeyBody,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionMiniHeader(
    String title,
    IconData icon,
    int count,
    GlassTokens tokens,
  ) {
    return Row(
      children: [
        Icon(icon, size: 14, color: tokens.connectedAccent),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(fontFamily: 'SpaceGrotesk', 
            color: tokens.starkWhite,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: tokens.connectedAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontFamily: 'SpaceGrotesk', 
              color: tokens.connectedAccent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedAccounts(
    _InboxStateData inboxState,
    GlassTokens tokens,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionMiniHeader(
          context.l10n.inboxIdsLinkedAccounts,
          Icons.account_balance_wallet_outlined,
          inboxState.identities.length,
          tokens,
        ),
        const SizedBox(height: 8),
        ...inboxState.identities
            .map((identity) => _buildIdentityRow(identity, inboxState, tokens)),
      ],
    );
  }

  Widget _buildIdentityRow(
    Map<String, dynamic> identity,
    _InboxStateData inboxState,
    GlassTokens tokens,
  ) {
    final identifier = identity['identifier'] as String? ?? '';
    final kind = identity['kind'] as String? ?? 'ethereum';
    final isRecovery =
        inboxState.recoveryIdentity?['identifier'] == identifier;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRecovery
              ? tokens.fallbackAccent.withValues(alpha: 0.6)
              : tokens.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: tokens.connectedAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              kind == 'ethereum'
                  ? Icons.account_balance_wallet_outlined
                  : Icons.fingerprint_rounded,
              size: 14,
              color: tokens.connectedAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        shortenString(identifier),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ).copyWith(color: tokens.starkWhite),
                      ),
                    ),
                    if (isRecovery) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: tokens.fallbackAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context.l10n.inboxIdsRecoveryBadge,
                          style: TextStyle(fontFamily: 'SpaceGrotesk',
                            fontSize: 9,
                            color: tokens.fallbackAccent,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  kind == 'ethereum'
                      ? context.l10n.inboxIdsEthereumWallet
                      : context.l10n.inboxIdsPasskey,
                  style: TextStyle(fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          _RowIconButton(
            icon: Icons.copy_rounded,
            small: true,
            onTap: () {
              Clipboard.setData(ClipboardData(text: identifier));
              _showSnack(context.l10n.inboxIdsAddressCopied);
            },
            tokens: tokens,
          ),
          if (!isRecovery &&
              inboxState.identities.length > 1 &&
              inboxState.hasRecoveryKeyLocally) ...[
            const SizedBox(width: 4),
            _RowIconButton(
              icon: Icons.remove_circle_outline_rounded,
              small: true,
              destructive: true,
              onTap: () => _confirmRemoveAccount(identifier, inboxState),
              tokens: tokens,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstallations(
    _InboxStateData inboxState,
    GlassTokens tokens,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionMiniHeader(
          context.l10n.inboxIdsInstallations,
          Icons.devices_outlined,
          inboxState.installations.length,
          tokens,
        ),
        const SizedBox(height: 8),
        ...inboxState.installations.map(
          (installation) =>
              _buildInstallationRow(installation, inboxState, tokens),
        ),
      ],
    );
  }

  Widget _buildInstallationRow(
    Map<String, dynamic> installation,
    _InboxStateData inboxState,
    GlassTokens tokens,
  ) {
    final installationId = installation['id'] as String? ?? '';
    final createdAt = installation['createdAt'] as int?;
    final isCurrentDevice = installationId == _currentInstallationId;
    final l10n = context.l10n;

    String timeAgo = l10n.inboxIdsUnknown;
    if (createdAt != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) {
        timeAgo = l10n.inboxIdsDaysAgo(diff.inDays);
      } else if (diff.inHours > 0) {
        timeAgo = l10n.inboxIdsHoursAgo(diff.inHours);
      } else {
        timeAgo = l10n.inboxIdsMinutesAgo(diff.inMinutes);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentDevice
            ? tokens.connectedAccent.withValues(alpha: 0.1)
            : tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentDevice
              ? tokens.connectedAccent.withValues(alpha: 0.5)
              : tokens.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isCurrentDevice
                  ? tokens.connectedAccent.withValues(alpha: 0.2)
                  : tokens.glassFill,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isCurrentDevice
                  ? Icons.computer_rounded
                  : Icons.devices_other_rounded,
              size: 14,
              color: isCurrentDevice
                  ? tokens.connectedAccent
                  : tokens.textDim,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        shortenString(installationId),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ).copyWith(color: tokens.starkWhite),
                      ),
                    ),
                    if (isCurrentDevice) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: tokens.connectedAccent
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.inboxIdsThisDeviceBadge,
                          style: TextStyle(fontFamily: 'SpaceGrotesk',
                            fontSize: 9,
                            color: tokens.connectedAccent,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  l10n.inboxIdsCreatedAgo(timeAgo),
                  style: TextStyle(fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          _RowIconButton(
            icon: Icons.copy_rounded,
            small: true,
            onTap: () {
              Clipboard.setData(ClipboardData(text: installationId));
              _showSnack(l10n.inboxIdsInstallationIdCopied);
            },
            tokens: tokens,
          ),
          if (!isCurrentDevice) ...[
            const SizedBox(width: 4),
            _RowIconButton(
              icon: Icons.logout_rounded,
              small: true,
              destructive: true,
              onTap: () =>
                  _confirmRevokeInstallation(installationId, inboxState),
              tokens: tokens,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    _InboxEntry entry,
    _InboxStateData inboxState,
    GlassTokens tokens,
  ) {
    final hasOtherInstallations = inboxState.installations.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.inboxIdsQuickActions,
          style: TextStyle(fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (!entry.isRegistered)
              _ActionChipButton(
                icon: Icons.tab_rounded,
                label: context.l10n.inboxIdsActionRegisterToProfile,
                onTap: () => _registerInboxId(entry),
                tokens: tokens,
              ),
            if (entry.isRegistered)
              _ActionChipButton(
                icon: Icons.edit_outlined,
                label: context.l10n.inboxIdsActionRenameLabel,
                onTap: () => _editLabel(entry),
                tokens: tokens,
              ),
            _ActionChipButton(
              icon: Icons.add_rounded,
              label: context.l10n.inboxIdsActionAddAccount,
              onTap: () => _showAddAccountDialog(entry, inboxState),
              tokens: tokens,
            ),
            _ActionChipButton(
              icon: _isSyncingConsent ? Icons.sync_rounded : Icons.sync_alt_rounded,
              label: _isSyncingConsent
                  ? context.l10n.inboxIdsActionSyncing
                  : context.l10n.inboxIdsActionSyncConsent,
              onTap: _isSyncingConsent ? null : _syncConsentPreferences,
              isLoading: _isSyncingConsent,
              tokens: tokens,
            ),
            _ActionChipButton(
              icon: _isSyncingHistory ? Icons.sync_rounded : Icons.history_rounded,
              label: _isSyncingHistory
                  ? context.l10n.inboxIdsActionRequesting
                  : context.l10n.inboxIdsActionRequestHistory,
              onTap: _isSyncingHistory ? null : _sendSyncRequest,
              isLoading: _isSyncingHistory,
              tokens: tokens,
            ),
            if (hasOtherInstallations)
              _ActionChipButton(
                icon: Icons.logout_rounded,
                label: context.l10n.inboxIdsActionRevokeAllOthers,
                destructive: true,
                onTap: () => _confirmRevokeAllOthers(entry, inboxState),
                tokens: tokens,
              ),
            _ActionChipButton(
              icon: _isRevokingOffline ? Icons.sync_rounded : Icons.wifi_off_rounded,
              label: _isRevokingOffline
                  ? context.l10n.inboxIdsActionRevoking
                  : context.l10n.inboxIdsOfflineRecovery,
              destructive: true,
              onTap: _isRevokingOffline
                  ? null
                  : () => _showOfflineRecoveryDialog(entry),
              isLoading: _isRevokingOffline,
              tokens: tokens,
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// Small reusable widgets
// ============================================================================

class _RowIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;
  final bool destructive;
  final bool small;
  final GlassTokens tokens;

  /// Hover/long-press hint. These glyphs carry no label, and "which one
  /// un-publishes my tab?" is exactly the question a bare icon cannot answer.
  /// Same affordance as the status bar's XMTP chip.
  final String? tooltip;
  const _RowIconButton({
    required this.icon,
    required this.onTap,
    required this.tokens,
    this.tooltip,
    this.primary = false,
    this.destructive = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 30.0 : 34.0;
    final iconSize = small ? 14.0 : 16.0;
    final bg = primary
        ? tokens.connectedAccent.withValues(alpha: 0.2)
        : destructive
            ? tokens.fallbackAccent.withValues(alpha: 0.12)
            : tokens.glassFill;
    final border = primary
        ? tokens.connectedAccent.withValues(alpha: 0.5)
        : destructive
            ? tokens.fallbackAccent.withValues(alpha: 0.4)
            : tokens.borderSubtle;
    final fg = primary
        ? tokens.connectedAccent
        : destructive
            ? tokens.fallbackAccent
            : tokens.starkWhite;

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: iconSize, color: fg),
        ),
      ),
    );
    final hint = tooltip;
    if (hint == null || hint.isEmpty) return button;
    return Tooltip(message: hint, child: button);
  }
}

class _ActionChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;
  final bool isLoading;
  final GlassTokens tokens;
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tokens,
    this.destructive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? tokens.fallbackAccent : tokens.connectedAccent;
    final enabled = onTap != null;
    final alpha = enabled ? 1.0 : 0.5;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isLoading ? 0.06 : 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(icon, size: 13, color: color.withValues(alpha: alpha)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontFamily: 'SpaceGrotesk', 
                color: color.withValues(alpha: alpha),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Helper dialogs — picker / method / add-account options
// ============================================================================

class _KeyPickerDialog extends StatelessWidget {
  final List<_KeyInfo> keys;
  final String purpose;
  const _KeyPickerDialog({required this.keys, required this.purpose});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: GlassTheme.glassBox(context).copyWith(
          color: tokens.surfaceDeep,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.inboxIdsSelectKey,
              style: TextStyle(fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.inboxIdsKeyPickerSubtitle(purpose),
              style: TextStyle(fontFamily: 'SpaceGrotesk', 
                color: tokens.textDim,
                fontSize: 12,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: keys.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final key = keys[i];
                  return InkWell(
                    onTap: () => Navigator.pop(context, key),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: tokens.glassFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: tokens.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tokens.connectedAccent
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.key_rounded,
                              color: tokens.connectedAccent,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  key.label,
                                  style: TextStyle(fontFamily: 'SpaceGrotesk', 
                                    color: tokens.starkWhite,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  shortenString(key.address),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ).copyWith(color: tokens.textDim),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.l10n.actionCancel,
                  style: TextStyle(fontFamily: 'SpaceGrotesk', 
                    color: tokens.textDim,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoveryKeyMethodDialog extends StatelessWidget {
  const _RecoveryKeyMethodDialog();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: GlassTheme.glassBox(context).copyWith(
          color: tokens.surfaceDeep,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.inboxIdsRecoveryKeyDialogTitle,
              style: TextStyle(fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.inboxIdsRecoveryKeyDialogSubtitle,
              style: TextStyle(fontFamily: 'SpaceGrotesk', 
                color: tokens.textDim,
                fontSize: 12,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            _MethodOption(
              tokens: tokens,
              icon: Icons.key_rounded,
              title: context.l10n.inboxIdsMethodPickKeychainTitle,
              subtitle: context.l10n.inboxIdsMethodPickKeychainSubtitleShort,
              onTap: () => Navigator.pop(context, 'keychain'),
            ),
            const SizedBox(height: 8),
            _MethodOption(
              tokens: tokens,
              icon: Icons.vpn_key_outlined,
              title: context.l10n.inboxIdsEnterPrivateKey,
              subtitle: context.l10n.inboxIdsMethodPrivateKeySubtitle,
              onTap: () => Navigator.pop(context, 'hex'),
            ),
            const SizedBox(height: 8),
            _MethodOption(
              tokens: tokens,
              icon: Icons.text_snippet_outlined,
              title: context.l10n.inboxIdsEnterMnemonic,
              subtitle: context.l10n.inboxIdsMethodMnemonicSubtitle,
              onTap: () => Navigator.pop(context, 'mnemonic'),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.l10n.actionCancel,
                  style: TextStyle(fontFamily: 'SpaceGrotesk', 
                    color: tokens.textDim,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAccountOptionsDialog extends StatelessWidget {
  const _AddAccountOptionsDialog();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: GlassTheme.glassBox(context).copyWith(
          color: tokens.surfaceDeep,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.inboxIdsAddAccountTitle,
              style: TextStyle(fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.inboxIdsAddAccountSubtitle,
              style: TextStyle(fontFamily: 'SpaceGrotesk', 
                color: tokens.textDim,
                fontSize: 12,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            _MethodOption(
              tokens: tokens,
              icon: Icons.key_rounded,
              title: context.l10n.inboxIdsMethodPickKeychainTitle,
              subtitle: context.l10n.inboxIdsMethodPickKeychainSubtitleLong,
              onTap: () => Navigator.pop(context, 'keychain'),
            ),
            const SizedBox(height: 8),
            _MethodOption(
              tokens: tokens,
              icon: Icons.file_download_outlined,
              title: context.l10n.inboxIdsMethodImportKeyTitle,
              subtitle: context.l10n.inboxIdsMethodImportKeySubtitle,
              onTap: () => Navigator.pop(context, 'import'),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.l10n.actionCancel,
                  style: TextStyle(fontFamily: 'SpaceGrotesk', 
                    color: tokens.textDim,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportOptionsDialog extends StatelessWidget {
  const _ImportOptionsDialog();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: GlassTheme.glassBox(context).copyWith(
          color: tokens.surfaceDeep,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.inboxIdsImportKeyTitle,
              style: TextStyle(fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            _MethodOption(
              tokens: tokens,
              icon: Icons.text_snippet_outlined,
              title: context.l10n.inboxIdsMethodMnemonicPhraseTitle,
              subtitle: context.l10n.inboxIdsMethodMnemonicSubtitle,
              onTap: () => Navigator.pop(context, 'mnemonic'),
            ),
            const SizedBox(height: 8),
            _MethodOption(
              tokens: tokens,
              icon: Icons.vpn_key_outlined,
              title: context.l10n.inboxIdsMethodPrivateKeyOptTitle,
              subtitle: context.l10n.inboxIdsMethodPrivateKeySubtitle,
              onTap: () => Navigator.pop(context, 'hex'),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.l10n.actionCancel,
                  style: TextStyle(fontFamily: 'SpaceGrotesk', 
                    color: tokens.textDim,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeychainPickerDialog extends StatelessWidget {
  final List<Map<String, dynamic>> keys;
  final String title;
  const _KeychainPickerDialog({required this.keys, required this.title});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: GlassTheme.glassBox(context).copyWith(
          color: tokens.surfaceDeep,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontFamily: 'SpaceGrotesk', 
                color: tokens.starkWhite,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: keys.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final key = keys[i];
                  final label = key['label'] as String? ?? context.l10n.inboxIdsUnknown;
                  final address = key['address'] as String? ?? '';
                  final emoji = key['emoji'] as String? ?? '';
                  return InkWell(
                    onTap: () => Navigator.pop(context, key),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: tokens.glassFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: tokens.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: tokens.connectedAccent
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: emoji.isNotEmpty
                                ? Text(emoji,
                                    style: const TextStyle(fontSize: 18))
                                : Icon(
                                    Icons.key_rounded,
                                    color: tokens.connectedAccent,
                                    size: 16,
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(fontFamily: 'SpaceGrotesk', 
                                    color: tokens.starkWhite,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  shortenString(address),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ).copyWith(color: tokens.textDim),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.l10n.actionCancel,
                  style: TextStyle(fontFamily: 'SpaceGrotesk', 
                    color: tokens.textDim,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  final GlassTokens tokens;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MethodOption({
    required this.tokens,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tokens.connectedAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: tokens.connectedAccent, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontFamily: 'SpaceGrotesk', 
                      color: tokens.starkWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontFamily: 'SpaceGrotesk', 
                      color: tokens.textDim,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: tokens.textDim),
          ],
        ),
      ),
    );
  }
}
