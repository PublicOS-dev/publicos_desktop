import 'dart:math';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:publicos_desktop/widgets/key_lifetime_line.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/utils/favicon_utils.dart';

import '../theme/glass_tokens.dart';
import 'feeds/emoji_picker_dialog.dart';
import 'glass_contact_icon.dart';
import 'inbox_tab_dialog.dart';
import 'import_key_dialog.dart';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:web3dart/web3dart.dart' show EthPrivateKey;

import '../l10n/l10n_ext.dart';
import 'error/error_l10n.dart';
import 'pixel_rain_loading_widget.dart';

/// What a freshly created key carries: the label the user typed and the emoji
/// it will wear in the list.
class _NewKey {
  final String label;
  final String emoji;
  const _NewKey({required this.label, required this.emoji});
}

/// Avatars offered at key creation. The default is picked at RANDOM so keys a
/// user never bothers to personalise still tend to differ at a glance -
/// nothing keys off the emoji, so repeats are harmless.
const kKeyEmojiPool = <String>[
  '\u{1F511}', '\u{1F5DD}\u{FE0F}', '\u{1F98A}', '\u{1F419}', '\u{1F989}',
  '\u{1F41D}', '\u{1F988}', '\u{1F422}', '\u{1F981}', '\u{1F43C}',
  '\u{1F340}', '\u{1F335}', '\u{1F30A}', '\u{1F525}', '\u{26A1}',
  '\u{1F308}', '\u{1F319}', '\u{2B50}', '\u{1F355}', '\u{1F344}',
  '\u{1F3B2}', '\u{1F3B8}', '\u{1F3BA}', '\u{1F9ED}', '\u{1F6F8}',
  '\u{1F680}', '\u{26F5}', '\u{1F3D4}\u{FE0F}', '\u{1F9CA}', '\u{1FA90}',
];

String randomKeyEmoji() =>
    kKeyEmojiPool[Random.secure().nextInt(kKeyEmojiPool.length)];



/// Keychain management surface — publicos_client's `keychain_sheet.dart`
/// (`KeychainSheet`) re-shelled as a big desktop dialog (the BSP/SSP dialog
/// pattern), reached from the sidebar's connection footer.
///
/// Desktop deltas vs the client sheet:
///   - bottom sheet → glass dialog shell + bottom-right rain loader.
///   - `AppStateNotifier.currentMyContact` (client-only) → `PublicOS`
///     (`myPublicosAddress` for the user key, `sessionBlockchainAddress` for the
///     session key) + the self [Contact] passed in by the shell.
///   - personal keychain only — the group-keychain context lives behind a
///     group-settings entry point (not on desktop yet).
///   - `showSecretRevealDialog` → an inline glass reveal. Import reuses the
///     desktop `showImportKeyDialog`. The emoji picker is the real ported
///     picker, same as the client.
///   - the quick row action selects the XMTP key (sim-card); the web-key pointer
///     is a toggle inside each key's expanded drawer (the client's `xmtp` type).
///
/// [onboardingMode] / [tourGenerateKey] / [tourSimKey]: the onboarding tour's
/// coach sequence (port of the client's `KeychainSheet` `tour` mode).
/// Desktop has only the `tour` mode in use; the client's `create`
/// and `activate` modes are not ported.
Future<void> showKeychainDialog(
  BuildContext context, {
  Contact? myContact,
  VoidCallback? onKeysChanged,
  KeychainOnboardingMode onboardingMode = KeychainOnboardingMode.off,
  GlobalKey? tourGenerateKey,
  GlobalKey? tourSimKey,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _KeychainDialog(
      myContact: myContact,
      onKeysChanged: onKeysChanged,
      onboardingMode: onboardingMode,
      tourGenerateKey: tourGenerateKey,
      tourSimKey: tourSimKey,
    ),
  );
}

/// Client parity (`keychain_sheet.dart`). `tour`: the doing-tour's coach
/// sequence. Generate visible, Import hidden, generate does NOT auto-load, the
/// SIM stays live, and the publish-inbox offer is a tour step rather than an
/// offer (no "don't ask again", the standing opt-out is not consulted).
enum KeychainOnboardingMode { off, tour }

class _KeychainDialog extends StatefulWidget {
  final Contact? myContact;
  final VoidCallback? onKeysChanged;
  final KeychainOnboardingMode onboardingMode;

  /// Coach anchors: the tour spotlights GENERATE and the first key's SIM.
  /// Null for every other caller, so nothing changes.
  final GlobalKey? tourGenerateKey;
  final GlobalKey? tourSimKey;

  const _KeychainDialog({
    this.myContact,
    this.onKeysChanged,
    this.onboardingMode = KeychainOnboardingMode.off,
    this.tourGenerateKey,
    this.tourSimKey,
  });

  bool get inTour => onboardingMode == KeychainOnboardingMode.tour;

  @override
  State<_KeychainDialog> createState() => _KeychainDialogState();
}

class _KeychainDialogState extends State<_KeychainDialog>
    with TickerProviderStateMixin {
  String? _userAddress;
  List<Map<String, dynamic>> _keys = [];

  /// Each key's published inbox as `name/label`, keyed by key label, for the
  /// tile subtitle: picking a messaging key
  /// says which inbox people will reach. Absent = unknown (no XMTP client
  /// loaded to ask, or the key never made an inbox); '' = the key has an
  /// inbox that no directory lists.
  Map<String, String> _inboxAddressByKey = {};
  static final _kHex64 = RegExp(r'^[0-9a-f]{64}$');

  /// Each key's inbox (from its metadata stamp, else one XMTP lookup), then
  /// one directory read per owner: mine, plus the
  /// org of every org key, whose inbox lives in the ORG's directory and is
  /// named after the org (`publicos/admin`).
  Future<void> _loadInboxAddresses(
      String me, List<Map<String, dynamic>> keys) async {
    final inboxByKey = <String, String>{};
    final owners = <String>{me};
    for (final k in keys) {
      final label = k['label'] as String?;
      final address = k['address'] as String?;
      if (label == null || address == null) continue;
      // Stamped into key metadata at first activation, so no network and no
      // loaded client needed. Placeholders (`pending_initialization`,
      // `Error`) fail the hex check and fall back to asking XMTP, which does
      // need a loaded client.
      final stamped = (k['inboxId'] as String?)?.toLowerCase();
      final inboxId = (stamped != null && _kHex64.hasMatch(stamped))
          ? stamped
          : Contact.normalizeInboxId(
              await PublicOSConversations.inboxIdFromAddress(address));
      if (inboxId == null) continue;
      inboxByKey[label] = inboxId;
      final org = k['isGroupKey'] == true ? k['orgAddress'] as String? : null;
      if (org != null) owners.add(org);
    }
    if (inboxByKey.isEmpty) return;

    final named = <String, String>{};
    for (final owner in owners) {
      try {
        final ownerAddress = EthereumAddress.fromHex(owner);
        final dir = await PublicOSXmtp.getAllAccountInboxIds(ownerAddress);
        if (dir == null || dir.inboxIds.isEmpty) continue;
        final name = await PublicOSContacts
            .getPublicosDisplayNameByAccountAddress(ownerAddress);
        for (var i = 0; i < dir.inboxIds.length; i++) {
          final label = i < dir.labels.length ? dir.labels[i] : '';
          if (label.isEmpty) continue;
          named[bytes32ToString(dir.inboxIds[i])] =
              (name == null || name.isEmpty) ? label : '$name/$label';
        }
      } catch (_) {
        // RPC down: those keys stay "unregistered" until the next open.
      }
    }
    if (!mounted) return;
    setState(() => _inboxAddressByKey = {
          for (final e in inboxByKey.entries) e.key: named[e.value] ?? '',
        });
  }
  bool _loading = true;
  String? _error;
  String? _currentSelectedKey; // XMTP-selected key
  String? _webSelectedKey; // web/signing-selected key

  /// Connect grants held by this session — the rows behind
  /// `ConnectGate.hasGrant`, read through Core's `listGrants` / `revokeSite`.
  /// Has a key fetch actually SUCCEEDED yet?
  ///
  /// The prune deletes grant rows permanently, and it decides what to delete by
  /// asking which keys exist -- so running it before the keychain has loaded
  /// means running it against an empty key set, which deletes every grant that
  /// was not made with the session key. That is not hypothetical: `initState`
  /// fires `_fetchKeys()` and the web-key load in PARALLEL and unawaited, the
  /// web-key path is a single read while the fetch is N secure-storage reads
  /// plus key parsing, so the fast path wins essentially every time and would
  /// quietly wipe exactly the EOA-key grants.
  ///
  /// So this is an explicit "the inputs are known" flag, NOT `_keys.isNotEmpty`
  /// -- a user who has deleted all their EOA keys has an empty list AND real
  /// orphans to clean, and would never get pruned.
  bool _keysLoaded = false;

  List<ConnectedSite> _grants = const [];

  // NOTE: each grant is filed under the key that owns it, and the "Preferred
  // key" toggle sits in the same panel. That says structurally that a grant
  // made with a different key exists but does not apply, so a flat list
  // with an "OTHER KEY" badge is not needed.

  // Accordion — one row expanded at a time. Controllers are lazily created per
  // key label so only interacted rows animate.
  String? _expandedLabel;
  final Map<String, AnimationController> _animControllers = {};
  final Map<String, Animation<double>> _expandAnims = {};

  @override
  void initState() {
    super.initState();
    _userAddress = PublicOS.myPublicosAddress;
    // First load reads context.l10n, which is not allowed inside initState.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchKeys());
    _loadCurrentSelectedKey();
    _loadWebSelectedKey();
    // Re-entering the tour with a key ALREADY loaded: the offer fires on a SIM
    // tap, and the active key's SIM has no handler, so a user who declined the
    // register dialog once would have no control left that offers again. The
    // offer gates itself on an unpublished inbox, so this is a no-op otherwise.
    // Tour only (client parity).
    if (widget.inTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeOfferInboxRegistration(context, _snack, inTour: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _animControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _fetchKeys() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final addr = _userAddress;
    if (addr == null) {
      _setError(context.l10n.bspScreenNoActiveAccount);
      return;
    }
    try {
      final fetched = await PublicOSKeychain.fetchKeys(addr);
      if (!mounted) return;
      setState(() {
        _keys = fetched;
        _keysLoaded = true;
        _loading = false;
        _error = null;
      });
      // ONLY here. The prune deletes rows and there is no undo, so it must run
      // downstream of the fetch that tells it which keys exist -- see
      // [_keysLoaded].
      await _loadAndPruneGrants();
      unawaited(_loadInboxAddresses(addr, fetched));
    } catch (e) {
      _setError(localizedError(context.l10n, e));
    }
  }

  void _setError(String error) {
    if (!mounted) return;
    setState(() {
      _error = error;
      _loading = false;
    });
  }

  Future<void> _loadCurrentSelectedKey() async {
    final addr = _userAddress;
    if (addr == null) return;
    try {
      final selected = await PublicOSKeychain.getXmtpSelectedKey(addr);
      if (mounted) setState(() => _currentSelectedKey = selected);
    } catch (_) {}
  }

  Future<void> _loadWebSelectedKey() async {
    final addr = _userAddress;
    if (addr == null) return;
    try {
      final web = await PublicOSKeychain.getWebSelectedKey(addr);
      if (mounted) setState(() => _webSelectedKey = web);
    } catch (_) {}
  }

  // ── Accordion ───────────────────────────────────────────────────────────────

  AnimationController _getOrCreateController(String label) {
    if (!_animControllers.containsKey(label)) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      _animControllers[label] = controller;
      _expandAnims[label] = CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      );
    }
    return _animControllers[label]!;
  }

  Future<void> _toggleExpanded(String label) async {
    final controller = _getOrCreateController(label);
    if (_expandedLabel == label) {
      await controller.reverse();
      if (mounted) setState(() => _expandedLabel = null);
      return;
    }
    if (_expandedLabel != null) {
      await _animControllers[_expandedLabel]?.reverse();
    }
    if (!mounted) return;
    setState(() => _expandedLabel = label);
    unawaited(controller.forward());
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _generateNewKey() async {
    final created = await _askNewKey();
    if (created == null) return;
    final label = created.label;
    final addr = _userAddress;
    if (addr == null) {
      _setError(context.l10n.bspScreenNoActiveAccount);
      return;
    }
    try {
      setState(() => _loading = true);
      final keyData = await PublicOSKeychain.generateNewKey(addr, label,
          emoji: created.emoji);
      // Generation (the slow part) is done — stop the loader before showing the
      // recovery phrase, so it isn't left spinning behind the copy-words dialog.
      if (mounted) setState(() => _loading = false);
      await _showSecretReveal(
        title: context.l10n.keychainRecoveryTitle,
        subtitle: label,
        warning:
            context.l10n.keychainRecoveryWarning,
        secret: keyData['mnemonic'] as String,
      );
      // Generating a key NEVER switches messaging on (client parity).
      // The key is stored and listed; the user points XMTP at it
      // with the SIM, which is also where the publish-inbox offer fires.
      if (mounted) _snack(context.l10n.keychainKeyCreated);
      await _fetchKeys();
      widget.onKeysChanged?.call();
    } catch (e) {
      _setError(localizedError(context.l10n, e));
    }
  }

  Future<void> _deleteKey(String label) async {
    // Client parity (keychain_sheet._deleteKey): the key messaging
    // runs on gets two warnings, then is unloaded before it is deleted.
    final bool loaded = PublicOS.currentXmtpKeyLabel == label;
    if (loaded) {
      final first = await _confirm(
        title: context.l10n.keychainDeleteLoadedTitle,
        body: context.l10n.keychainDeleteLoadedBody(label),
        cta: context.l10n.keychainDeleteContinue,
      );
      if (first != true || !mounted) return;
      final second = await _confirm(
        title: context.l10n.keychainDeleteLoadedPhraseTitle,
        body: context.l10n.keychainDeleteLoadedPhraseBody,
        cta: context.l10n.keychainDelete,
        destructive: true,
      );
      if (second != true) return;
    } else {
      final confirmed = await _confirm(
        title: context.l10n.keychainActionDelete,
        body: context.l10n.keychainDeleteConfirm(label),
        cta: context.l10n.keychainDelete,
        destructive: true,
      );
      if (confirmed != true) return;
    }
    final addr = _userAddress;
    if (addr == null) {
      _setError(context.l10n.bspScreenNoActiveAccount);
      return;
    }
    try {
      setState(() => _loading = true);
      // Unload first, then delete — never the other way round.
      if (loaded) await _unloadXmtp();
      await PublicOSKeychain.deleteKey(addr, label);
      if (_currentSelectedKey == label) _currentSelectedKey = null;
      if (!mounted) return;
      _snack(loaded
          ? context.l10n.keychainKeyDeletedUnloaded
          : context.l10n.keychainKeyDeleted);
      await _fetchKeys();
      widget.onKeysChanged?.call();
    } catch (e) {
      _setError(localizedError(context.l10n, e));
    }
  }

  /// Unload the XMTP client WITHOUT loading another key (first unload, then
  /// delete). Core's deleteKey only clears the loaded-key
  /// fields, and only when the key is also the saved selection; it never stops
  /// the stream, closes the native client or flips the connected flag, so the
  /// UI would keep reporting a client for a key that is gone. Same calls
  /// Core uses before a re-init: stream off, native client closed, status
  /// false, loaded-key fields cleared. Messaging stays off until a key is picked.
  static Future<void> _unloadXmtp() async {
    try {
      await PublicOSConversations.disposeMessages();
    } catch (_) {}
    try {
      await PublicOS.xmtpClient?.closeClient();
    } catch (_) {}
    PublicOS.setXmtpConnected(false);
    PublicOS.currentXMTPPrivateKey = null;
    PublicOS.clientXmtpAddress = null;
    PublicOS.clientXmtpInboxId = null;
    PublicOS.currentXmtpDbKey = null;
    PublicOS.currentXmtpKeyLabel = null;
  }

  Future<void> _selectKey(String label) async {
    final addr = _userAddress;
    if (addr == null) {
      _snack(context.l10n.bspScreenNoActiveAccount);
      return;
    }
    try {
      setState(() => _loading = true);
      // Client parity (keychain_sheet._selectKey): activation funnels through
      // the orchestrator — loads silently when the key is set up on this
      // device, otherwise asks create-fresh vs restore-backup. Bare
      // `selectKey` throws XmtpNotSetUpException on a never-activated key.
      final loaded = await _activateKeyForXmtp(context, addr, label);
      if (!loaded) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (mounted) {
        setState(() {
          _currentSelectedKey = label;
          _loading = false;
        });
      }
      _snack(context.l10n.keychainClientReloaded(label));
      // The offer runs BEFORE the pop: once this dialog closes there is no
      // context left to show it in (client parity, keychain_sheet._selectKey).
      if (mounted) {
        await _maybeOfferInboxRegistration(context, _snack,
            inTour: widget.inTour);
      }
      widget.onKeysChanged?.call();
      // Picking a key is the errand - close the keychain once it is loaded,
      // as mobile does. The snack rides the app-level
      // ScaffoldMessenger, so it survives the pop.
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack(localizedError(context.l10n, e));
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Load this session's grants and **drop the orphans** — rows whose granted
  /// key is no longer on the device.
  ///
  /// A grant is scoped to the session address (one account can hold several
  /// sessions on one device, and an account-scoped grant could not tell them
  /// apart), so every row here was necessarily created with a key that lived on
  /// THIS device. If its EOA is not in the keychain any more, the key was
  /// deleted and the row can never match again: `hasGrant` compares against the
  /// key about to be handed over, and that key no longer exists. It is dead
  /// state that can only mislead.
  ///
  /// ⚠️ **The guard is the important part.** Grants never expire and there is
  /// no undo, so pruning against an EMPTY or FAILED key fetch would silently
  /// wipe every connection the user has. This runs only when the fetch actually
  /// produced the device's keys — `_keys` populated and no error — and it
  /// always counts the session key, which is not in `_keys` and is the one key
  /// that cannot be deleted.
  Future<void> _loadAndPruneGrants() async {
    final session = PublicOS.sessionBlockchainAddress?.toLowerCase();
    if (session == null) return;
    try {
      var rows = await PublicOS.database.listGrants(session);

      if (_keysLoaded) {
        final live = <String>{session};
        for (final k in _keys) {
          final a = (k['address'] as String?)?.toLowerCase();
          if (a != null && a.isNotEmpty && a != 'unknown') live.add(a);
        }
        final orphans =
            rows.where((r) => !live.contains(r.grantedEoa.toLowerCase()));
        for (final o in orphans) {
          debugPrint('[keychain] pruning orphan grant ${o.origin} '
              '(key ${o.grantedEoa} is no longer on this device)');
          await PublicOS.database.revokeSite(
            origin: o.origin,
            session: o.sessionAddress,
            eoa: o.grantedEoa,
          );
        }
        if (orphans.isNotEmpty) {
          rows = await PublicOS.database.listGrants(session);
        }
      }

      if (mounted) setState(() => _grants = rows);
    } catch (e) {
      // Non-fatal: the keychain's own job does not depend on this list.
      debugPrint('[keychain] could not load grants: $e');
    }
  }

  /// The grants belonging to one key, by its address. `null`/'session' asks for
  /// the session key's.
  List<ConnectedSite> _grantsForKey(String? address) {
    final a = (address ?? PublicOS.sessionBlockchainAddress ?? '').toLowerCase();
    if (a.isEmpty) return const [];
    return _grants.where((g) => g.grantedEoa.toLowerCase() == a).toList();
  }

  /// Drop one grant row. Exactly (origin, session, eoa) — a site connected
  /// under two different keys keeps its other grant, which is the whole point
  /// of the per-key model.
  Future<void> _revokeGrant(ConnectedSite g) async {
    try {
      await PublicOS.database.revokeSite(
        origin: g.origin,
        session: g.sessionAddress,
        eoa: g.grantedEoa,
      );
      _snack(context.l10n.desktopGrantRevoked(g.origin));
      await _loadAndPruneGrants();
      widget.onKeysChanged?.call();
    } catch (e) {
      _snack(localizedError(context.l10n, e));
    }
  }

  Future<void> _selectWebKey(String label) async {
    final addr = _userAddress;
    if (addr == null) {
      _snack(context.l10n.bspScreenNoActiveAccount);
      return;
    }
    try {
      await PublicOSKeychain.setWebSelectedKey(addr, label);
      if (mounted) setState(() => _webSelectedKey = label);
      _snack(context.l10n.keychainWebKeySet(
          label == 'session' ? context.l10n.keychainSessionKey : label));
      widget.onKeysChanged?.call();
    } catch (e) {
      _snack(localizedError(context.l10n, e));
    }
  }

  Future<void> _toggleWallet(String label, bool currentState) async {
    final addr = _userAddress;
    if (addr == null) {
      _snack(context.l10n.bspScreenNoActiveAccount);
      return;
    }
    try {
      setState(() => _loading = true);
      await PublicOSKeychain.setWalletEnabled(addr, label, !currentState);
      _snack(!currentState
          ? context.l10n.keychainWalletEnabled(label)
          : context.l10n.keychainWalletDisabled(label));
      await _fetchKeys();
      widget.onKeysChanged?.call();
    } catch (e) {
      _snack(localizedError(context.l10n, e));
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editKeyLabel(String currentLabel) async {
    final newLabel = await _askLabel(
      title: context.l10n.keychainActionRename,
      cta: context.l10n.keychainSave,
      initial: currentLabel,
    );
    if (newLabel == null || newLabel.isEmpty || newLabel == currentLabel) return;
    final addr = _userAddress;
    if (addr == null) {
      _setError(context.l10n.bspScreenNoActiveAccount);
      return;
    }
    try {
      setState(() => _loading = true);
      await PublicOSKeychain.updateKeyLabel(addr, currentLabel, newLabel);
      if (_currentSelectedKey == currentLabel) _currentSelectedKey = newLabel;
      if (_webSelectedKey == currentLabel) _webSelectedKey = newLabel;
      _snack(context.l10n.inboxIdsLabelUpdated);
      await _fetchKeys();
      widget.onKeysChanged?.call();
    } catch (e) {
      _setError(localizedError(context.l10n, e));
    }
  }

  /// Tap the avatar → the real picker, no intermediate dialog.
  ///
  /// Not a `TextField(maxLength: 2)`: that is not an emoji input, it is a
  /// two-character text box: it accepts `ab`, accepts two unrelated emoji,
  /// and splits any emoji built from a ZWJ sequence or a skin-tone modifier
  /// straight down the middle. The categorized picker
  /// (`widgets/feeds/emoji_picker_dialog.dart`) is the one every emoji surface
  /// in the app uses.
  Future<void> _changeEmoji(String label, String currentEmoji) async {
    final emoji = await showEmojiPickerDialog(
      context,
      currentEmoji: currentEmoji,
    );
    if (emoji == null || emoji.isEmpty || emoji == currentEmoji) return;
    final addr = _userAddress;
    if (addr == null) {
      _snack(context.l10n.bspScreenNoActiveAccount);
      return;
    }
    try {
      setState(() => _loading = true);
      await PublicOSKeychain.setKeyEmoji(addr, label, emoji);
      _snack(context.l10n.keychainEmojiUpdated(label));
      await _fetchKeys();
      widget.onKeysChanged?.call();
    } catch (e) {
      _snack(localizedError(context.l10n, e));
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportKey(String label) async {
    final addr = _userAddress;
    if (addr == null) {
      _snack(context.l10n.bspScreenNoActiveAccount);
      return;
    }
    try {
      final hex = await PublicOSKeychain.exportPrivateKey(addr, label);
      if (hex == null) {
        _snack(context.l10n.keychainPrivKeyNotFound);
        return;
      }
      await _showSecretReveal(
        title: context.l10n.importModePrivateKey,
        subtitle: label,
        warning: context.l10n.secretDialogsExportWarning,
        secret: hex,
      );
    } catch (e) {
      _snack(localizedError(context.l10n, e));
    }
  }

  void _exportSessionKey() {
    final pk = PublicOS.currentBlockchainPrivateKey;
    if (pk == null) {
      _snack(context.l10n.keychainSessionKeyUnavail);
      return;
    }
    final hex =
        '0x${pk.privateKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
    _showSecretReveal(
      title: context.l10n.keychainSessionKey.toUpperCase(),
      subtitle: context.l10n.desktopSessionKeySubtitle,
      warning: context.l10n.desktopSessionKeyWarning,
      secret: hex,
    );
  }

  Future<void> _showImportDialog() async {
    await showImportKeyDialog(
      context,
      title: context.l10n.inboxIdsMethodImportKeyTitle,
      subtitle: context.l10n.keychainImportSubtitle,
      onImportMnemonic: (mnemonic) async {
        final addr = _userAddress;
        if (addr == null) return false;
        // Label AND icon, the generate prompt reused (client parity).
        final named = await _askNewKey(forImport: true);
        if (named == null) return false;
        final label = named.label;
        try {
          await PublicOSKeychain.importFromMnemonic(addr, mnemonic, label,
              emoji: named.emoji);
        } on XmtpDbKeyMismatchException catch (e) {
          if (!mounted) return false;
          final wipe = await _confirmDbWipe(e.walletAddress);
          if (wipe != true) return false;
          await PublicOSKeychain.retryImportAfterDbWipe(
            addr,
            e.walletAddress,
            '',
            label,
            mnemonic: mnemonic,
            emoji: named.emoji,
          );
        }
        return true;
      },
      onImportPrivateKey: (privateKey) async {
        final addr = _userAddress;
        if (addr == null) return false;
        final named = await _askNewKey(forImport: true);
        if (named == null) return false;
        final label = named.label;
        try {
          await PublicOSKeychain.importFromPrivateKey(addr, privateKey, label,
              emoji: named.emoji);
        } on XmtpDbKeyMismatchException catch (e) {
          if (!mounted) return false;
          final wipe = await _confirmDbWipe(e.walletAddress);
          if (wipe != true) return false;
          await PublicOSKeychain.retryImportAfterDbWipe(
            addr,
            e.walletAddress,
            privateKey,
            label,
            emoji: named.emoji,
          );
        }
        return true;
      },
    );
    await _fetchKeys();
    widget.onKeysChanged?.call();
  }

  // ── Small prompt dialogs ────────────────────────────────────────────────────

  /// Create-a-key dialog - the client's twin (`keychain_sheet._askNewKey`):
  /// avatar (random to start, tap to pick), label, and one line saying what
  /// generating does NOT do. Null on cancel.
  /// [forImport]: the same prompt for an IMPORTED key (name and icon are
  /// picked when importing too) — import title + hint, IMPORT as
  /// the action, and no "generating does not…" line.
  Future<_NewKey?> _askNewKey({bool forImport = false}) {
    final controller = TextEditingController();
    var emoji = randomKeyEmoji();

    return showDialog<_NewKey>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final tokens = GlassTokens.of(ctx);
          void submit() {
            final label = controller.text.trim();
            if (label.isNotEmpty) {
              Navigator.pop(ctx, _NewKey(label: label, emoji: emoji));
            }
          }

          return AlertDialog(
            constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
            title: Row(
              children: [
                Icon(Icons.key_rounded, size: 20, color: tokens.starkWhite),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(forImport
                        ? ctx.l10n.keychainEnterLabelTitle
                        : ctx.l10n.keychainGenTitle)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // The avatar the key will wear in the list; the same
                    // picker the tile's emoji opens later.
                    Tooltip(
                      message: ctx.l10n.keychainGenEmojiHint,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final picked = await showEmojiPickerDialog(ctx,
                              currentEmoji: emoji);
                          if (picked != null && picked.isNotEmpty) {
                            setLocal(() => emoji = picked);
                          }
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: tokens.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 26)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        maxLength: 50,
                        decoration: InputDecoration(
                          labelText: ctx.l10n.keychainKeyLabel,
                          hintText: forImport
                              ? ctx.l10n.keychainImportLabelHint
                              : ctx.l10n.keychainKeyLabelHint,
                        ),
                        onSubmitted: (_) => submit(),
                      ),
                    ),
                  ],
                ),
                if (!forImport) ...[
                const SizedBox(height: 4),
                Text(
                  ctx.l10n.keychainGenExplain,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: tokens.textDim,
                  ),
                ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(ctx.l10n.dlgCancel),
              ),
              TextButton(
                onPressed: submit,
                child: Text(forImport
                    ? ctx.l10n.keychainImport
                    : ctx.l10n.keychainGenerate),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _askLabel({
    required String title,
    required String cta,
    String? initial,
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: InputDecoration(
            labelText: context.l10n.keychainKeyLabel,
            hintText: context.l10n.keychainKeyLabelHint,
          ),
          onSubmitted: (v) {
            final t = v.trim();
            if (t.isNotEmpty) Navigator.pop(ctx, t);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.dlgCancel),
          ),
          TextButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isNotEmpty) Navigator.pop(ctx, t);
            },
            child: Text(cta),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String cta,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tokens = GlassTokens.of(ctx);
        // Severity rule: destructive = red icon + red uppercase title, body
        // in textDim.
        final accent = destructive
            ? Theme.of(ctx).colorScheme.error
            : tokens.starkWhite;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: DialogWidth.s),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: GlassTheme.glassBox(ctx).copyWith(
                color: tokens.surfaceDeep,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        destructive
                            ? Icons.warning_amber_rounded
                            : Icons.help_outline_rounded,
                        size: 20,
                        color: accent,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          title.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            color: accent,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(
                            ctx.l10n.dlgCancel,
                            style: const TextStyle(
                              fontFamily: 'SpaceGrotesk',
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
                            backgroundColor: accent,
                            foregroundColor: tokens.background,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            cta,
                            style: const TextStyle(
                              fontFamily: 'SpaceGrotesk',
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
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDbWipe(String walletAddress) {
    return _confirm(
      title: context.l10n.keychainDbMismatchTitle,
      body: context.l10n.keychainDbMismatchBody(
          shortenString(walletAddress, isAddress: true)),
      cta: context.l10n.keychainEraseContinue,
      destructive: true,
    );
  }

  Future<void> _showSecretReveal({
    required String title,
    String? subtitle,
    required String warning,
    required String secret,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        final tokens = GlassTokens.of(ctx);
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                width: DialogWidth.m,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                decoration: GlassTheme.glassBox(ctx).copyWith(
                  color: tokens.surfaceDeep.withValues(alpha: 0.92),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: tokens.fallbackAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: tokens.fallbackAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.starkWhite,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      warning,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: tokens.textDim,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tokens.glassFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        secret,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.5,
                          color: tokens.starkWhite,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: secret));
                              _snack(context.l10n.signatureRequestSheetCopiedToClipboard);
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: Text(context.l10n.groupVotingViewCopy),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: tokens.starkWhite,
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tokens.starkWhite,
                              foregroundColor: tokens.background,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              context.l10n.onbDone,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _copyToClipboard(String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    _snack(context.l10n.acctSettingsCopiedToClipboard(what));
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final maxH = MediaQuery.of(context).size.height * 0.82;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            width: DialogWidth.l,
            constraints: BoxConstraints(maxHeight: maxH),
            decoration: GlassTheme.glassBox(
              context,
            ).copyWith(color: tokens.surfaceDeep.withValues(alpha: 0.92)),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogHeader(tokens),
                    Flexible(child: _buildContent(tokens)),
                    _footerBar(tokens),
                  ],
                ),
                if (_loading)
                  const Positioned(
                    right: 16,
                    bottom: 16,
                    child: PixelRainLoadingWidget(size: 28, showShadows: false),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogHeader(GlassTokens tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 12, 8),
      child: Row(
        children: [
          // White, not teal: the client's keychain header draws its key glyph in
          // the plain foreground, and teal is reserved for ACTIVE/connected state
          // — the header is not a state.
          Icon(Icons.vpn_key_rounded, color: tokens.starkWhite, size: 20),
          const SizedBox(width: 10),
          Text(
            context.l10n.keychainTitle.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: tokens.starkWhite,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: context.l10n.createRecordPageClose,
            icon: Icon(Icons.close_rounded, size: 19, color: tokens.textDim),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(GlassTokens tokens) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: tokens.fallbackAccent),
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: tokens.textDim),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _fetchKeys,
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.starkWhite,
                  side: BorderSide.none,
                ),
                child: Text(context.l10n.actionRetry),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      children: [
        _buildSessionKeyTile(tokens),
        const SizedBox(height: 14),
        if (_keys.isEmpty && !_loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.key_off, size: 40, color: tokens.textDim),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.keychainNoKeys,
                    style: TextStyle(fontSize: 13, color: tokens.textDim),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(_keys.length, (index) {
            final key = _keys[index];
            final isActive = key['label'] == _currentSelectedKey;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _keys.length - 1 ? 12 : 0,
              ),
              // The tour spotlights the SIM on the FIRST row; during the
              // coach sequence there is exactly one, the key just generated.
              child: _buildKeyTile(tokens, key,
                  isCurrentKey: isActive, isSimTarget: index == 0),
            );
          }),
      ],
    );
  }

  /// **Connected apps, for ONE key** — the sites this key has been granted to.
  ///
  /// Per-key and not global, because that is what a grant actually is: the row
  /// is keyed by `(origin, session, EOA)` and `ConnectGate.hasGrant` asks about
  /// "the exact key about to be handed over". A flat list forced the reader to
  /// hold that mapping in their head; under the key it owns, the model is the
  /// layout.
  ///
  /// ⚠️ **A grant never expires.** `hasGrant` is `row != null`; `lastUsedAt` is
  /// a sort key, not a TTL, and nothing in the gate or the schema ages one out.
  /// The trash button here is the ONLY way a grant ever ends — this is the
  /// app's sole revocation surface, not a read-only log.
  Widget _buildKeyGrants(GlassTokens tokens, String? address) {
    final grants = _grantsForKey(address);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.apps_rounded, size: 13, color: tokens.textDim),
            const SizedBox(width: 8),
            Text(
              'CONNECTED APPS',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
                color: tokens.textDim,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${grants.length}',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: tokens.textDim.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (grants.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 21, bottom: 4),
            child: Text(
              'No apps connected with this key.',
              style: TextStyle(
                fontSize: 10.5,
                color: tokens.textDim.withValues(alpha: 0.7),
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(left: 21, bottom: 8),
            child: Text(
              'Allowed to see this key\'s address. Access lasts until removed.',
              style: TextStyle(
                fontSize: 10.5,
                height: 1.3,
                color: tokens.textDim.withValues(alpha: 0.7),
              ),
            ),
          ),
          for (final g in grants) _buildGrantRow(tokens, g),
        ],
      ],
    );
  }

  /// Icon · title over url · trash.
  ///
  /// The title is DERIVED, because nothing stores one: a grant row carries only
  /// (origin, session, eoa, keyLabel, timestamps). [_siteTitle] guesses from the
  /// host, which is why the full origin sits directly underneath — a wrong
  /// guess is then harmless, since the authoritative string is on screen.
  Widget _buildGrantRow(GlassTokens tokens, ConnectedSite g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _SiteFavicon(origin: g.origin, tokens: tokens),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _siteTitle(g.origin),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.starkWhite,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  g.origin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: tokens.textDim.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove access',
            icon: Icon(Icons.delete_outline_rounded,
                size: 16, color: tokens.textDim),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
            onPressed: () => _revokeGrant(g),
          ),
        ],
      ),
    );
  }

  /// A readable name for an origin, guessed from the host: drop a leading
  /// `www.` / `app.` / `m.` (they name a deployment, not a site) and title-case
  /// the first remaining label -- `https://app.zerion.io` -> `Zerion`.
  /// Falls back to the raw origin
  /// for anything unparseable.
  String _siteTitle(String origin) {
    final host = Uri.tryParse(origin)?.host;
    if (host == null || host.isEmpty) return origin;
    var h = host;
    for (final prefix in const ['www.', 'app.', 'm.']) {
      if (h.startsWith(prefix)) {
        h = h.substring(prefix.length);
        break;
      }
    }
    final first = h.split('.').first;
    if (first.isEmpty) return host;
    return first[0].toUpperCase() + first.substring(1);
  }

  Widget _footerBar(GlassTokens tokens) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      // No rule above the buttons (borderless).
      decoration: const BoxDecoration(),
      child: Row(
        children: [
          // Import is hidden in the tour: a brand-new user generates.
          if (!widget.inTour) ...[
            Expanded(
              child: _footerButton(
                tokens,
                icon: Icons.download_rounded,
                label: context.l10n.keychainImport.toUpperCase(),
                onTap: _showImportDialog,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: _footerButton(
              tokens,
              key: widget.tourGenerateKey,
              icon: Icons.add_circle_outline,
              label: context.l10n.keychainGenerate.toUpperCase(),
              onTap: _generateNewKey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerButton(
    GlassTokens tokens, {
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      key: key,
      style: ElevatedButton.styleFrom(
        backgroundColor: tokens.glassFill,
        foregroundColor: tokens.starkWhite,
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide.none,
        ),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          fontSize: 12,
        ),
      ),
    );
  }

  // ── Session key tile ─────────────────────────────────────────────────────────

  Widget _buildSessionKeyTile(GlassTokens tokens) {
    final contact = widget.myContact;
    final address = PublicOS.sessionBlockchainAddress ?? '0x0000...0000';
    final isWebSelected = _webSelectedKey == null || _webSelectedKey == 'session';
    final name =
        contact?.publicosDisplayName ?? contact?.displayName ?? context.l10n.keychainMyAccount;

    // The session key is a key like any other and behaves like one: a
    // chevron, and its settings in the panel underneath, so its only per-key
    // action (Export) is not a bare glyph on the row and the row reads like
    // every other key's.
    // `'session'` is the accordion id, the same sentinel the rest of the
    // codebase already uses for this key (`_selectWebKey('session')`, a grant's
    // `keyLabel`).
    final isExpanded = _expandedLabel == 'session';
    final controller = _getOrCreateController('session');
    final expandAnim = _expandAnims['session'];

    return Column(
      children: [
        Container(
      decoration: BoxDecoration(
        // The FILL carries the expansion, not a thicker ring.
        color: isExpanded ? tokens.surfaceElevated : tokens.glassFill,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleExpanded('session'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                if (contact != null)
                  GlassContactIcon(contact: contact, size: 44)
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tokens.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_circle_rounded,
                      color: tokens.textDim,
                      size: 28,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: tokens.starkWhite,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.keychainSessionBadge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: tokens.textDim,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            shortenString(address, isAddress: true),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: tokens.textDim,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _copyToClipboard(address, context.l10n.appSettingsPageAddressLabel),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 12,
                              color: tokens.textDim,
                            ),
                          ),
                        ],
                      ),
                      // This key's lifetime.
                      KeyLifetimeLine(
                        sessionAddress: address,
                        showPermanent: true,
                        shadow: false,
                        color: tokens.textDim,
                      ),
                    ],
                  ),
                ),
                _RowIconButton(
                  icon: isWebSelected ? Icons.public_rounded : Icons.public_outlined,
                  primary: isWebSelected,
                  onTap: () => _selectWebKey('session'),
                  tokens: tokens,
                ),
                const SizedBox(width: 4),
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => Transform.rotate(
                    angle: controller.value * 1.5708,
                    child: _RowIconButton(
                      icon: Icons.expand_more_rounded,
                      onTap: () => _toggleExpanded('session'),
                      tokens: tokens,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
        ),
        if (expandAnim != null)
          SizeTransition(
            sizeFactor: expandAnim,
            alignment: Alignment.topCenter,
            child: _buildSessionKeyExpandedSection(tokens),
          ),
      ],
    );
  }

  /// The session key's panel. Deliberately short: this key cannot be renamed,
  /// re-emoji'd or deleted, and its XMTP/web pointers are quick actions on the
  /// row — so what is left is Export and the apps it is connected to.
  Widget _buildSessionKeyExpandedSection(GlassTokens tokens) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceDeep.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKeyGrants(tokens, null),
          const SizedBox(height: 6),
          const SizedBox(height: 2),
          const SizedBox(height: 6),
          _KeychainActionRow(
            icon: Icons.upload_rounded,
            label: context.l10n.keychainActionExport,
            subtitle:
                context.l10n.keychainActionExportSub,
            onTap: _exportSessionKey,
            tokens: tokens,
          ),
        ],
      ),
    );
  }

  // ── Key tile (accordion) ─────────────────────────────────────────────────────

  Widget _buildKeyTile(
    GlassTokens tokens,
    Map<String, dynamic> key, {
    bool isCurrentKey = false,
    bool isSimTarget = false,
  }) {
    final label = (key['label'] ?? context.l10n.keychainUnnamedKey) as String;
    final address = (key['address'] ?? context.l10n.keychainUnknownAddr) as String;
    final emoji = (key['emoji'] ?? '🔑') as String;
    final isExpanded = _expandedLabel == label;
    final controller = _getOrCreateController(label);
    final expandAnim = _expandAnims[label];

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            // The FILL carries the expansion, not a thicker ring.
            color: isExpanded ? tokens.surfaceElevated : tokens.glassFill,
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleExpanded(label),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _changeEmoji(label, emoji),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: tokens.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tokens.starkWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_inboxAddressByKey[label] != null) ...[
                                Flexible(
                                  child: Text(
                                    _inboxAddressByKey[label]!.isEmpty
                                        ? context.l10n.statusBarInboxUnregistered
                                        : _inboxAddressByKey[label]!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      color: tokens.textDim,
                                    ),
                                  ),
                                ),
                                Text('  ·  ',
                                    style: TextStyle(fontSize: 10, color: tokens.textDim)),
                              ],
                              Text(
                                shortenString(address, isAddress: true),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: tokens.textDim,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _copyToClipboard(address, context.l10n.appSettingsPageAddressLabel),
                                child: Icon(
                                  Icons.copy_rounded,
                                  size: 12,
                                  color: tokens.textDim,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _RowIconButton(
                          key: isSimTarget ? widget.tourSimKey : null,
                          icon: isCurrentKey
                              ? Icons.sim_card_rounded
                              : Icons.sim_card_outlined,
                          primary: isCurrentKey,
                          onTap: isCurrentKey ? null : () => _selectKey(label),
                          tokens: tokens,
                        ),
                        const SizedBox(width: 4),
                        AnimatedBuilder(
                          animation: controller,
                          builder: (context, _) => Transform.rotate(
                            angle: controller.value * 1.5708,
                            child: _RowIconButton(
                              icon: Icons.expand_more_rounded,
                              onTap: () => _toggleExpanded(label),
                              tokens: tokens,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (expandAnim != null)
          SizeTransition(
            sizeFactor: expandAnim,
            alignment: Alignment.topCenter,
            child: _buildKeyExpandedSection(tokens, key),
          ),
      ],
    );
  }

  Widget _buildKeyExpandedSection(GlassTokens tokens, Map<String, dynamic> key) {
    final label = (key['label'] ?? context.l10n.keychainUnnamedKey) as String;
    final emoji = (key['emoji'] ?? '🔑') as String;
    final isWebSelected = _webSelectedKey == label;
    final walletEnabled = key['walletEnabled'] == true;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceDeep.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KeychainToggleRow(
            icon: Icons.public_outlined,
            label: context.l10n.keychainToggleWebKey,
            subtitle:
                context.l10n.keychainToggleWebSub,
            value: isWebSelected,
            onChanged: isWebSelected ? null : (_) => _selectWebKey(label),
            tokens: tokens,
          ),
          _KeychainToggleRow(
            icon: Icons.account_balance_wallet_outlined,
            label: context.l10n.keychainToggleWallet,
            subtitle:
                context.l10n.keychainToggleWalletSub,
            value: walletEnabled,
            onChanged: (_) => _toggleWallet(label, walletEnabled),
            tokens: tokens,
          ),
          const SizedBox(height: 6),
          _buildKeyGrants(tokens, key['address'] as String?),
          const SizedBox(height: 6),
          const SizedBox(height: 2),
          const SizedBox(height: 6),
          _KeychainActionRow(
            icon: Icons.emoji_emotions_outlined,
            label: context.l10n.keychainActionEmoji,
            subtitle: context.l10n.keychainActionEmojiSub,
            onTap: () => _changeEmoji(label, emoji),
            tokens: tokens,
          ),
          _KeychainActionRow(
            icon: Icons.edit_outlined,
            label: context.l10n.keychainActionRename,
            subtitle:
                context.l10n.keychainActionRenameSub,
            onTap: () => _editKeyLabel(label),
            tokens: tokens,
          ),
          _KeychainActionRow(
            icon: Icons.upload_rounded,
            label: context.l10n.keychainActionExport,
            subtitle:
                context.l10n.keychainActionExportSub,
            onTap: () => _exportKey(label),
            tokens: tokens,
          ),
          _KeychainActionRow(
            icon: Icons.delete_outline_rounded,
            label: context.l10n.keychainActionDelete,
            subtitle:
                context.l10n.keychainActionDeleteSub,
            destructive: true,
            onTap: () => _deleteKey(label),
            tokens: tokens,
          ),
        ],
      ),
    );
  }
}

// ── Row-local helpers (copied from the client keychain sheet) ─────────────────

/// A connected app's favicon, with a fixed 28px footprint across loading and
/// error so a row never reflows while the network answers.
///
/// The URL is Google's favicon service (`FaviconUtils`), the same rung the
/// browser's web tabs use -- so opening the keychain sends one request per
/// connected app to Google, naming hosts the user has connected to. Same
/// trade-off as for web tabs; worth knowing it applies here too.
class _SiteFavicon extends StatelessWidget {
  final String origin;
  final GlassTokens tokens;

  const _SiteFavicon({required this.origin, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(Icons.public_rounded, size: 15, color: tokens.textDim);
    return SizedBox(
      width: 28,
      height: 28,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: ZeroCachedImage(
          imageUrl: FaviconUtils.getFaviconUrl(origin),
          fit: BoxFit.cover,
          placeholder: (_, __) => Center(child: fallback),
          errorWidget: (_, __, ___) => Center(child: fallback),
        ),
      ),
    );
  }
}

class _RowIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;
  final GlassTokens tokens;

  const _RowIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tokens,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    const size = 34.0;
    const iconSize = 16.0;
    final bg = primary
        ? tokens.connectedAccent.withValues(alpha: 0.2)
        : tokens.glassFill;
    final fg = primary
        ? tokens.connectedAccent
        : (onTap == null
            ? tokens.starkWhite.withValues(alpha: 0.35)
            : tokens.starkWhite);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: size,
          height: size,
          // `bg` and `fg` already say primary / destructive / neutral.
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: iconSize, color: fg),
        ),
      ),
    );
  }
}

class _KeychainToggleRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final GlassTokens tokens;

  const _KeychainToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.tokens,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 18, color: tokens.starkWhite),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: tokens.connectedAccent,
          ),
        ],
      ),
    );
  }
}

class _KeychainActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;
  final GlassTokens tokens;

  const _KeychainActionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.tokens,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = destructive ? tokens.fallbackAccent : tokens.starkWhite;
    final subFg = destructive
        ? tokens.fallbackAccent.withValues(alpha: 0.7)
        : tokens.textDim;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subFg,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: subFg, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── XMTP key activation (ported verbatim from keychain_sheet.dart) ──────────
//
// Key tiles never call bare `PublicOSKeychain.selectKey`:
// selection funnels through `activateKeyForXmtp`, the single gate every
// activation entry point uses (chip tap, onboarding, Messages view). If the
// key isn't set up for messaging on THIS device, Core throws
// XmtpNotSetUpException and the orchestrator asks the user — create a fresh
// installation or restore a database backup — activation never assumes.
// Calling selectKey directly would make picking such a key error instead of
// setting up XMTP.
// Bodies below are the client's, verbatim (statics on KeychainSheet there,
// file-level privates here).

// ══════════════════════════════════════════════════════════════════════════
//  Publish-this-inbox offer
//  Client parity: bodies mirror `keychain_sheet.dart` (statics on the state
//  there, file-level privates here — the same split the activation
//  orchestrator above already uses).
//
//  Fires ONCE the XMTP client is loaded with a key, never at create or import
//  time: activation is the first moment an inbox ID exists at all, so there is
//  no "does this key have an inbox?" question and no network lookup to invent.
//
//  Three gates, cheapest first: the local setting, then already-published,
//  then domain compliance — registering is an on-chain write and compliance is
//  the consensus gate, so offering it to a non-compliant account promises
//  something that would revert.
// ══════════════════════════════════════════════════════════════════════════

/// Setting key for the offer. `'true'` = the user asked us to stop.
/// Shared with the Settings pane's XMTP section; must stay identical to
/// `KeychainSheet.kInboxPromptOffKey` in publicos_client.
const String kInboxPromptOffKey = 'xmtp_inbox_register_never_ask';

Future<void> _maybeOfferInboxRegistration(
    BuildContext context, void Function(String) snack,
    {bool inTour = false}) async {
  // During the tour this dialog is a step, the write the sequence exists to
  // reach: the standing "don't ask again" is not consulted and not offered.
  if (!inTour) {
    try {
      final off = await PublicOSSettings.getSetting(kInboxPromptOffKey);
      if (off?.value == 'true') return;
    } catch (_) {
      // Unreadable — fall through and ask.
    }
  }

  final inboxId = PublicOS.clientXmtpInboxId;
  if (inboxId == null || inboxId.isEmpty) return;

  try {
    if (await PublicOSXmtp.accountInboxIdExists(StringToBytes(inboxId))) return;
  } catch (_) {
    return; // Cannot tell — say nothing rather than offer a duplicate.
  }

  // Throws on a failed read (unlike the check above, which returns false), so
  // this catch is load-bearing: an unverifiable domain means we stay quiet.
  final myAddress = AppStateNotifier.currentMyContact?.publicosAddress;
  if (myAddress == null) return;
  try {
    if (!await PublicOSTreasury.isDomainCompliant(myAddress)) return;
  } catch (_) {
    return;
  }

  // Asked before the dialog is built so the field can open already filled.
  // One extra view call on a path that has just done three.
  final defaultLabel = await _defaultInboxLabel(myAddress);

  if (!context.mounted) return;
  // THE shared inbox-tab dialog (client twin) — same surface the
  // Inbox IDs page opens for register/rename. It owns the duplicate check, the
  // ownership pre-check and the write, and only returns `saved` once the chain
  // confirmed; a failure keeps the dialog open with the reason.
  final result = await showInboxTabDialog(
    context,
    account: myAddress,
    accountName: AppStateNotifier.currentMyContact?.publicosDisplayName,
    inboxIdBytes: StringToBytes(inboxId),
    mode: InboxTabMode.register,
    title: context.l10n.keychainOfferRegTitle,
    subtitle: context.l10n.keychainOfferRegBody(shortenString(inboxId)),
    cta: context.l10n.keychainOfferRegPublish,
    initialLabel: defaultLabel,
    offerDontAsk: !inTour,
  );
  if (result == null) return;

  if (result.dontAskAgain) {
    try {
      await PublicOSSettings.setSetting(
        kInboxPromptOffKey,
        Record.asSettings(
          key: kInboxPromptOffKey,
          value: 'true',
          isSystem: true,
          expiration: DateTime.now().add(const Duration(days: 3650)),
          isExpired: false,
        ),
      );
    } catch (_) {}
  }

  // Failures do not reach here: the dialog explains them in place.
  if (!result.saved) return;
  snack(context.l10n.keychainInboxRegOk);
}

/// The name a first inbox gets when nothing else claims it.
const String _kDefaultInboxLabel = 'personal';

/// The default tab name to offer, or `null` for an empty field.
///
/// `personal` is pre-filled when it is free and the field is left **empty with
/// its hint** when it is not: a second key on an account that already has
/// `personal` would otherwise arrive at a prefilled name guaranteed to revert
/// on `labelExists(account, label)`.
///
/// Read through `getAllAccountInboxIds`, which returns **null on failure** — so
/// an unreadable account is treated the same as a taken name and gets an empty
/// field. Guessing a default we cannot verify is the one outcome that spends
/// gas to find out.
Future<String?> _defaultInboxLabel(EthereumAddress account) async {
  try {
    final all = await PublicOSXmtp.getAllAccountInboxIds(account);
    if (all == null) return null;
    final taken = all.labels.map((l) => l.toLowerCase()).toSet();
    // Client twin: the KEY's own name first, sanitised to
    // the contract charset; `personal` only as the fallback.
    final keyLabel = _sanitiseInboxLabel(PublicOS.currentXmtpKeyLabel);
    if (keyLabel != null && !taken.contains(keyLabel)) return keyLabel;
    return taken.contains(_kDefaultInboxLabel) ? null : _kDefaultInboxLabel;
  } catch (_) {
    return null;
  }
}

/// A keychain key label squeezed into `XmtpManager._validateLabel`'s charset:
/// lowercase, `[a-z0-9._-]`, 1..31 bytes, first char `[a-z0-9_]`. Null when
/// nothing usable survives.
String? _sanitiseInboxLabel(String? raw) {
  if (raw == null) return null;
  var out = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]'), '');
  out = out.replaceAll(RegExp(r'^[.-]+'), '');
  if (out.length > 31) out = out.substring(0, 31);
  return out.isEmpty ? null : out;
}

enum _XmtpSetupChoice { createFresh, restore }

/// Orchestrates loading a key into XMTP (the single gate every activation
/// entry point funnels through).
///
/// If the key is already set up on this device it loads silently. If not,
/// the gate first asks the NETWORK whether this key has an inbox at all
/// (`PublicOSKeychain.isKeyOnXmtpNetwork`, no client needed, nothing
/// registered):
///
///  * **no inbox** -> there is nothing to restore, so it sets up fresh
///    without asking. This is the just-generated key, and the question
///    ("create fresh or restore a backup?") is unanswerable for it.
///  * **has an inbox**, or the probe could not tell (offline / web) -> ask.
///    Never assume "no inbox" from a failed lookup: that
///    would spend an installation and strand the user's history.
///
/// [freshKey] still short-circuits straight to "create" for a caller that
/// already knows the key is brand new. Returns true when the client ends up
/// loaded.
Future<bool> _activateKeyForXmtp(
  BuildContext context,
  String userAddress,
  String label, {
  bool freshKey = false,
}) async {
  debugPrint('KeychainDialog: [ACTIVATE] label="$label" freshKey=$freshKey');
  try {
    await PublicOSKeychain.selectKey(userAddress, label);
    debugPrint(
        'KeychainDialog: [ACTIVATE] key was already set up — loaded directly');
    return true;
  } on XmtpNotSetUpException catch (e) {
    debugPrint(
        'KeychainDialog: [ACTIVATE] not set up here (status=${e.status.name}) — asking');
    if (freshKey) {
      return _setupFreshWithCapRecovery(context, userAddress, label);
    }
    // Client twin: only offer "restore a backup" when the key actually has an
    // inbox on the network.
    final onNetwork =
        await PublicOSKeychain.isKeyOnXmtpNetwork(userAddress, label);
    debugPrint(
        'KeychainDialog: [ACTIVATE] on network = ${onNetwork ?? "unknown"}');
    if (onNetwork == false) {
      if (!context.mounted) return false;
      return _setupFreshWithCapRecovery(context, userAddress, label);
    }
    if (!context.mounted) return false;
    final choice = await _showSetupChoiceDialog(context);
    debugPrint(
        'KeychainDialog: [ACTIVATE] user chose: ${choice?.name ?? "cancel"}');
    switch (choice) {
      case _XmtpSetupChoice.createFresh:
        return _setupFreshWithCapRecovery(context, userAddress, label);
      case _XmtpSetupChoice.restore:
        return _runRestoreBackup(context, userAddress, label);
      case null:
        return false;
    }
  }
}

/// Set up a fresh installation, recovering from the 10/10 cap if hit.
Future<bool> _setupFreshWithCapRecovery(
    BuildContext context, String userAddress, String label) async {
  try {
    debugPrint('KeychainDialog: [SETUP-FRESH] calling setupFreshXmtp…');
    await PublicOSKeychain.setupFreshXmtp(userAddress, label);
    debugPrint('KeychainDialog: [SETUP-FRESH] SUCCESS');
    return true;
  } on XmtpInstallationCapException catch (e) {
    debugPrint(
        'KeychainDialog: [SETUP-FRESH] installation cap hit for ${e.walletAddress}');
    if (!context.mounted) return false;
    final proceed =
        await _runInstallCapRecovery(context, e.walletAddress, () async {
      final hex = await PublicOSKeychain.exportPrivateKey(userAddress, label);
      if (hex == null) throw Exception(context.l10n.keychainPrivKeyNotFound);
      return EthPrivateKey.fromHex(hex).privateKey;
    });
    if (!proceed) return false;
    await PublicOSKeychain.setupFreshXmtp(userAddress, label);
    return true;
  } catch (e, st) {
    debugPrint('KeychainDialog: [SETUP-FRESH] FAILED: $e\n$st');
    if (context.mounted) {
      await _showSimpleDialog(
          context, context.l10n.keychainSetupTitle, e.toString());
    }
    return false;
  }
}

/// Installation-cap recovery: informed-choice dialog → two-step
/// confirm → revoke ALL of the key's installations signed by the imported
/// key itself. Returns true when the revoke succeeded and the import should
/// be retried; false on cancel or failure (failure is shown in a dialog —
/// never silently, and never the cache-wipe dialog).
Future<bool> _runInstallCapRecovery(
  BuildContext context,
  String walletAddress,
  Future<Uint8List> Function() getKeyBytes,
) async {
  final choseRevokeAll = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
      title: Text(ctx.l10n.keychainInstallCapTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ctx.l10n
                .keychainInstallCapBody(walletAddress.substring(0, 10))),
            const SizedBox(height: 16),
            Text(ctx.l10n.keychainInstallCapRevokeAll,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(ctx.l10n.keychainInstallCapRevokeAllDetail),
            const SizedBox(height: 12),
            Text(ctx.l10n.keychainInstallCapSelective,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(ctx.l10n.keychainInstallCapSelectiveDetail),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.dlgCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.l10n.keychainInstallCapRevokeAll),
        ),
      ],
    ),
  );
  if (choseRevokeAll != true || !context.mounted) return false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
      title: Text(ctx.l10n.keychainInstallCapConfirmTitle),
      content: Text(ctx.l10n.keychainInstallCapConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.dlgCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.l10n.keychainInstallCapRevokeAll),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  try {
    final keyBytes = await getKeyBytes();
    await PublicOSKeychain.revokeAllInstallationsForCap(
        keyBytes, walletAddress);
    return true;
  } catch (e) {
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
          title: Text(ctx.l10n.keychainInstallCapTitle),
          content: Text(ctx.l10n.keychainInstallCapRevokeFailed(e.toString())),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.l10n.dlgOk),
            ),
          ],
        ),
      );
    }
    return false;
  }
}

/// Restore a raw database backup (file + encryption key) for a key that is
/// not set up on this device — the SAME installation, no slot burned.
Future<bool> _runRestoreBackup(
    BuildContext context, String userAddress, String label) async {
  final l10n = context.l10n;
  // 1. Pick the backup file. NO extension filter — backups can be typed as
  // anything by the OS document provider, so we accept any file and validate
  // on open. Path-based (XFile.path) avoids the Windows file_picker
  // null-bytes gotcha.
  final XFile? picked;
  try {
    picked = await openFile();
  } catch (e, st) {
    debugPrint('KeychainDialog: [RESTORE] file pick failed: $e\n$st');
    if (context.mounted) {
      await _showSimpleDialog(context, l10n.keychainRestoreTitle, e.toString());
    }
    return false;
  }
  if (picked == null) {
    debugPrint('KeychainDialog: [RESTORE] no file picked (cancelled)');
    return false;
  }
  debugPrint(
      'KeychainDialog: [RESTORE] picked name=${picked.name} path=${picked.path}');
  if (!context.mounted) return false;

  // 2. Paste the database encryption key.
  final key = await _promptSecretText(
    context,
    title: l10n.keychainRestoreTitle,
    message: l10n.keychainRestoreKeyPrompt,
    hint: l10n.keychainRestoreKeyHint,
  );
  if (key == null || key.trim().isEmpty || !context.mounted) {
    debugPrint('KeychainDialog: [RESTORE] no encryption key entered');
    return false;
  }
  debugPrint(
      'KeychainDialog: [RESTORE] key entered (len=${key.trim().length}), calling restoreXmtpBackup…');

  // 3. Restore.
  try {
    await PublicOSKeychain.restoreXmtpBackup(
        userAddress, label, picked.path, key.trim());
    debugPrint('KeychainDialog: [RESTORE] SUCCESS');
    return true;
  } catch (e, st) {
    debugPrint('KeychainDialog: [RESTORE] FAILED: $e\n$st');
    if (context.mounted) {
      // Show the RAW error text while we're debugging this flow.
      await _showSimpleDialog(
          context, l10n.keychainRestoreFailedTitle, e.toString());
    }
    return false;
  }
}

/// The create-vs-restore choice shown when a key is not set up here.
Future<_XmtpSetupChoice?> _showSetupChoiceDialog(BuildContext context) {
  return showDialog<_XmtpSetupChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
      title: Text(ctx.l10n.keychainSetupTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ctx.l10n.keychainSetupBody),
            const SizedBox(height: 16),
            Text(ctx.l10n.keychainSetupCreateFresh,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(ctx.l10n.keychainSetupCreateFreshDetail),
            const SizedBox(height: 12),
            Text(ctx.l10n.keychainSetupRestore,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(ctx.l10n.keychainSetupRestoreDetail),
            const SizedBox(height: 16),
            // Guidance, not a third option. A key created moments ago still
            // lands here (create does not auto-activate in the onboarding
            // path), and the user is asked about a backup they cannot have.
            Text(
              ctx.l10n.keychainSetupHint,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontStyle: FontStyle.italic,
                color:
                    Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(ctx.l10n.dlgCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _XmtpSetupChoice.restore),
          child: Text(ctx.l10n.keychainSetupRestore),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _XmtpSetupChoice.createFresh),
          child: Text(ctx.l10n.keychainSetupCreateFresh),
        ),
      ],
    ),
  );
}

Future<String?> _promptSecretText(BuildContext context,
    {required String title, required String message, required String hint}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(ctx.l10n.dlgCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: Text(ctx.l10n.keychainImport),
        ),
      ],
    ),
  );
}

Future<void> _showSimpleDialog(
    BuildContext context, String title, String body) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(ctx.l10n.dlgOk),
        ),
      ],
    ),
  );
}
