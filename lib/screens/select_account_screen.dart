import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import '../boot_phase.dart';
import '../data/demo_contacts.dart';
import '../router.dart';
import '../theme/glass_tokens.dart';
import '../theme/shell_tones.dart';
import '../widgets/app_version_label.dart';
import '../widgets/constellation_background.dart';
import '../widgets/glass_contact_icon.dart';
import '../widgets/import_key_dialog.dart';
import '../widgets/key_lifetime_line.dart';
import '../widgets/link_device_dialog.dart';
import '../widgets/new_account_ask_dialog.dart';
import '../widgets/new_key_flow_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/contact_banner.dart';
import '../widgets/phigital_loading_widget.dart';
import '../widgets/pixel_rain_loading_widget.dart';
import '../widgets/wave_text.dart';
import 'profile_qr_page.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// Account selection — the desktop "ID badge" gallery over a floating
/// network-of-nodes background. Adapted from publicos_client's
/// SelectAccountScreen (the card design) but laid out desktop-esque: a wide
/// centered canvas, cards in a responsive multi-column wrap, the constellation
/// drifting behind. The Core-call recipe (load / restore / new keys /
/// activate) is desktop's own.
class SelectAccountScreen extends StatefulWidget {
  /// Fired once a session is restored and post-login boot has run. The app
  /// gate swaps to the explorer in response.
  final VoidCallback onLoggedIn;

  const SelectAccountScreen({super.key, required this.onLoggedIn});

  @override
  State<SelectAccountScreen> createState() => _SelectAccountScreenState();
}

class _SelectAccountScreenState extends State<SelectAccountScreen> {
  static const double _cardWidth = 480;
  // publicos_client ID-card proportions: at the client's 440 max-width minus
  // 28px side padding the card is 384 wide × ~137 tall (88px banner + the
  // action bar) — keep that flatter ratio rather than 16:9.
  static const double _cardHeight = _cardWidth * 137 / 384;

  Map<String, EthereumAddress> _accounts = {};
  final Map<String, Contact> _accountContacts = {};
  bool _isLoadingData = true;
  bool _isProcessingAction = false;

  /// Current [BootPhase] `.name`, or `''` when no login is in flight.
  ///
  /// Deliberately NOT `_isProcessingAction`: that flag is shared by every
  /// action on this screen (delete, reset, activate, create), and the boot
  /// overlay must appear for login only. `_bootStatus.isNotEmpty` is the
  /// single source of truth for "a login is running".
  String _bootStatus = '';

  String? _lastUsedAccountAddress;

  bool _hasTemporaryKeys = false;
  String? _temporaryKeysAddress;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoadingData = true);
    try {
      final accounts = await PublicOSAccounts.getStoredAccountNames();
      final hasTemp = await PublicOSAccounts.doesTemporarySessionExist();
      String? tempAddress;
      if (hasTemp) {
        tempAddress = await PublicOS.secureStorage.read(
          key: 'temporaryAccountSessionAddress',
        );
      }
      final lastUsedAddress = await PublicOS.secureStorage.read(
        key: 'selected_contactos_AccountAddress',
      );

      _accountContacts.clear();
      for (final entry in accounts.entries) {
        final displayName = entry.key;
        final address = entry.value;
        Contact? contact;
        try {
          // Pre-login there is no active session, so the normal getContact
          // (active-session scoped) returns null. Instead read this account's
          // OWN cached self-contact, scoped to its OWN session address (saved
          // enriched at its last login) — real avatar/banner with no network
          // and no active session. getContactForAccountPicker is picker-only
          // by design; everywhere else uses getContact. (Recipe from
          // publicos_client's select_account_screen.)
          final sessionHex = await PublicOS.secureStorage.read(
            key: 'account_${address.eip55With0x}_sessionAddress',
          );
          contact = sessionHex != null
              ? await PublicOSContacts.getContactForAccountPicker(
                  address,
                  EthereumAddress.fromHex(sessionHex),
                )
              : null;
        } catch (_) {}
        _accountContacts[displayName] =
            contact ??
            Contact(
              displayName: displayName,
              publicosDisplayName: displayName,
              publicosAddress: address,
            );
      }

      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _hasTemporaryKeys = hasTemp;
        _temporaryKeysAddress = tempAddress;
        _lastUsedAccountAddress = lastUsedAddress;
        _isLoadingData = false;
      });

      if (hasTemp) {
        _startPolling();
      } else {
        _pollTimer?.cancel();
      }
    } catch (e) {
      debugPrint('[SelectAccount] load error: $e');
      if (!mounted) return;
      setState(() => _isLoadingData = false);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<void> _selectAccount(
    String displayName,
    EthereumAddress address,
  ) async {
    if (!mounted || _isProcessingAction) return;
    setState(() {
      _isProcessingAction = true;
      _bootStatus = BootPhase.restoringSession.name;
    });
    try {
      final ok = await PublicOSAccounts.restoreSession(address);
      if (!ok) {
        _snack(context.l10n.selectAccountScreenRestoreSessionFailed);
        setState(() {
          _isProcessingAction = false;
          _bootStatus = '';
        });
        return;
      }
      // Client runBoot stage 2 (app_initializer.dart): BSP init — module
      // resolution, post-auth RPC upgrade (public fallback → subscribed
      // BSP/custom endpoint), polling. Must run right after restoreSession so
      // myPublicosAddress is set. Aborts the boot on failure, like the client.
      _setBootPhase(BootPhase.connectingChain);
      final bspOk = await PublicOS.initBSP();
      if (!bspOk) {
        _snack(context.l10n.desktopBootChainFailed);
        setState(() {
          _isProcessingAction = false;
          _bootStatus = '';
        });
        return;
      }

      // Desktop post-restore boot.
      _setBootPhase(BootPhase.loadingKeys);
      await PublicOS.loadLastUsedXmtpKey();
      await PublicOSKeychain.loadWebSelectedKey(address.eip55With0x);

      // Client runBoot stage 3: feed-server resolution (sets activeSspUrl /
      // activeSspSource / sspConnected — the sidebar SSP indicator reads them).
      _setBootPhase(BootPhase.connectingFeed);
      await PublicOS.initSSP();

      // Emitted unconditionally, as the client does — the inbox-id guard is a
      // desktop-only skip, not a different stage.
      _setBootPhase(BootPhase.loadingMessages);
      if (PublicOS.clientXmtpInboxId != null) {
        await PublicOSConversations.initializeMessages();
      }

      _setBootPhase(BootPhase.settingUpNotifs);
      final backgroundEnabled =
          await PublicOSSettings.getBackgroundNotifications();
      if (backgroundEnabled) {
        await PublicOS.registerBackgroundSync();
      }
      _pollTimer?.cancel();

      // Client runBoot, last stage before `opening` (app_initializer.dart:300):
      // one-time per-account seed of the baked demo contacts + app bookmarks so
      // Contacts has people to explore on first launch. Idempotent, best-effort,
      // never throws. The only other path is the Settings reseed button, which
      // sits behind the 10-tap developer gate (client parity), so without
      // this a fresh account would see nothing.
      await seedDemoContactsIfNeeded();

      // Cache the signed-in user's Contact. Client parity: runBoot does this at
      // app_initializer.dart:270. Ported feed widgets read it via
      // `AppStateNotifier.currentMyContact` to answer "is this post/reaction
      // mine?" — without it every post in the feed looks like someone else's.
      await AppStateNotifier.loadMyContact();

      // Non-blocking conversation sync.
      if (PublicOS.clientXmtpInboxId != null) {
        PublicOSConversations.syncAll(
          consentStates: ['allowed', 'unknown'],
        ).catchError((e) {
          debugPrint('[SelectAccount] background sync failed: $e');
          return <String, int>{};
        });
      }

      if (!mounted) return;
      _setBootPhase(BootPhase.opening);
      widget.onLoggedIn();
    } catch (e) {
      if (!mounted) return;
      _snack(localizedError(context.l10n, e));
      setState(() {
        _isProcessingAction = false;
        _bootStatus = '';
      });
    }
  }

  /// Login-only progress sink — the desktop analogue of the client's
  /// `runBoot(onStatus:)` callback. Mounted-guarded, like `_setBootStatus` in
  /// publicos_client's select_account_screen.
  void _setBootPhase(BootPhase phase) {
    if (!mounted) return;
    setState(() => _bootStatus = phase.name);
  }

  // ── New / pending keys ──────────────────────────────────────────────────────

  /// Intent → inputs → recovery words → signed claim, then the QR at once.
  /// Port of publicos_client's `_startNewKeyFlow`. The activation check is
  /// the existing [_startPolling] that
  /// `_loadData` arms whenever a pending key exists.
  Future<void> _startNewKeyFlow(NewKeyIntent intent) async {
    final address = await showNewKeyFlowDialog(context, intent: intent);
    if (!mounted) return;
    await _loadData();
    if (address == null || !mounted) return;
    // A new account needs a citizen to create it. Ask before the QR: a friend
    // scans it, or the claim page creates the account (publicos_client's
    // `_startNewKeyFlow`). Closing the question leaves the pending
    // card, whose QR button is still there.
    if (intent == NewKeyIntent.newAccount) {
      final help = await showNewAccountAskDialog(context);
      if (!mounted || help == null) return;
      if (help) {
        await _openClaimPage();
        return;
      }
    }
    _showTempKeyQR(address);
  }

  /// The public beta's claim door. A test build can point at
  /// a door on the LAN: `--dart-define=CLAIM_PAGE_URL=http://<pc>:8092/`.
  static const String _claimPageUrl = String.fromEnvironment(
    'CLAIM_PAGE_URL',
    defaultValue: 'https://claim.publicos.dev/',
  );

  /// "I don't have a friend on PublicOS": open the claim page with this
  /// device's signed claim after `#c=` (browsers never send that part to a
  /// server). Signed again for three hours, because the page checks an email
  /// and may keep the request in line; [_startPolling] signs in once the
  /// account exists. Twin of publicos_client's `_openClaimPage`.
  Future<void> _openClaimPage() async {
    try {
      final saved = await PublicOSAccounts.loadTemporaryLinkClaim();
      if (saved == null || saved.kind != ConsentKind.newAccount) return;
      final claim = await PublicOSAccounts.signTemporaryLinkClaim(
        kind: ConsentKind.newAccount,
        displayName: saved.input,
        validFor: const Duration(hours: 3),
      );
      final ok = await launchUrl(
        Uri.parse('$_claimPageUrl#c=${claim.consentUri}'),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) _snack(context.l10n.newAccountAskOpenFailed);
    } catch (e) {
      debugPrint('Error opening the claim page: $e');
      if (mounted) _snack(context.l10n.newAccountAskOpenFailed);
    }
  }

  // ── Import key ──────────────────────────────────────────────────────────────

  /// publicos_client's ImportKeySheet flow, re-shelled as a desktop dialog
  /// (showImportKeyDialog). The import handlers below are the client's recipe
  /// over Core's PublicOSKeychain importers — no new logic.
  Future<void> _showImportDialog() async {
    await showImportKeyDialog(
      context,
      title: context.l10n.keychainImportTitle,
      subtitle: context.l10n.keychainImportSubtitle,
      onImportMnemonic: (mnemonic) async {
        await _importFromMnemonic(mnemonic);
        return true;
      },
      onImportPrivateKey: (privateKey) async {
        await _importFromPrivateKey(privateKey);
        return true;
      },
    );
  }

  Future<void> _importFromMnemonic(String mnemonicText) async {
    if (mnemonicText.isEmpty) {
      _snack(context.l10n.importEnterMnemonic);
      return;
    }
    if (!mounted) return;
    setState(() => _isProcessingAction = true);
    try {
      final keyData =
          await PublicOSKeychain.importTemporaryBlockchainKeyFromMnemonic(
            mnemonicText,
          );
      final address = keyData['address'] as String;
      await PublicOSKeychain.loadTemporaryBlockchainKey();
      if (!mounted) return;
      setState(() {
        _hasTemporaryKeys = true;
        _temporaryKeysAddress = address;
      });
      await _loadData();
      _snack(context.l10n.selectAccountScreenKeyImported);
    } catch (e) {
      if (!mounted) return;
      _snack(localizedError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _importFromPrivateKey(String privateKeyHexText) async {
    if (privateKeyHexText.isEmpty) {
      _snack(context.l10n.importEnterPrivateKey);
      return;
    }
    if (!mounted) return;
    setState(() => _isProcessingAction = true);
    try {
      final keyData =
          await PublicOSKeychain.importTemporaryBlockchainKeyFromPrivateKey(
            privateKeyHexText,
          );
      final address = keyData['address'] as String;
      await PublicOSKeychain.loadTemporaryBlockchainKey();
      if (!mounted) return;
      setState(() {
        _hasTemporaryKeys = true;
        _temporaryKeysAddress = address;
      });
      await _loadData();
      _snack(context.l10n.selectAccountScreenKeyImported);
    } catch (e) {
      if (!mounted) return;
      _snack(localizedError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_isProcessingAction || !mounted) return;
      try {
        final hex =
            await PublicOSAccounts.checkAndActivatePendingTemporarySession();
        if (hex != null && mounted) {
          _pollTimer?.cancel();
          _snack(context.l10n.selectAccountScreenKeysActivated);
          await _loadData();
        }
      } catch (_) {}
    });
  }

  Future<void> _checkAndActivate() async {
    if (!mounted || _isProcessingAction) return;
    setState(() => _isProcessingAction = true);
    try {
      final hex =
          await PublicOSAccounts.checkAndActivatePendingTemporarySession();
      if (hex != null) {
        _pollTimer?.cancel();
        _snack(context.l10n.selectAccountScreenKeysActivated);
        await _loadData();
      } else {
        _snack(context.l10n.selectAccountScreenKeysNotLinked);
      }
    } catch (e) {
      _snack(localizedError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  /// Delete a real account from THIS DEVICE — keys, messages, contacts,
  /// settings. The on-chain account is untouched and can be re-imported with
  /// its recovery phrase / private key. Local-only wipe via
  /// [PublicOSAccounts.deleteStoredAccounts] plus the on-disk libxmtp MLS
  /// database (keyed by the account's session signing address, resolved here
  /// before deleteStoredAccounts wipes the secret that holds it). Picker-screen
  /// only — Core blocks deleting the active account, which never applies here
  /// (nothing is logged in on this screen). Mirrors publicos_client.
  Future<void> _deleteAccount(
    String displayName,
    EthereumAddress address,
  ) async {
    final confirmed = await _confirmDialog(
      title: context.l10n.selectAccountScreenDeleteAccountTitle,
      body: context.l10n.enhancedVoteCardWeekdayAt(context.l10n.selectAccountScreenDeleteAccountBody(displayName), context.l10n.selectAccountScreenDeleteAccountNote),
      confirmLabel: context.l10n.keychainDelete,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isProcessingAction = true);
    try {
      // Resolve the session (signing) address BEFORE the wipe — it keys the
      // on-disk libxmtp MLS database, and deleteStoredAccounts removes the
      // secret that holds it. Best-effort: an orphan .db3 is harmless once its
      // DB key is gone, so a failure here never blocks the delete.
      final sessionHex = await PublicOS.secureStorage.read(
        key: 'account_${address.eip55With0x}_sessionAddress',
      );
      if (sessionHex != null && sessionHex.isNotEmpty) {
        await PublicOSKeychain.deleteLocalXmtpDatabase(sessionHex);
      }

      final ok = await PublicOSAccounts.deleteStoredAccounts(address);
      if (!mounted) return;
      if (ok) {
        _snack(context.l10n.inboxIdsAccountRemoved);
        await _loadData();
      } else {
        _snack(context.l10n.selectAccountScreenDeleteAccountFailed);
      }
    } catch (e) {
      debugPrint('[SelectAccount] delete error: $e');
      if (!mounted) return;
      _snack(localizedError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _deleteTemporaryKeys() async {
    final confirmed = await _confirmDialog(
      title: context.l10n.selectAccountScreenDeleteKeyPairTitle,
      body: context.l10n.selectAccountScreenDeleteKeyPairBody,
      confirmLabel: context.l10n.keychainDelete,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    _pollTimer?.cancel();
    // Canonical Core wipe — clears the temp private/encryption/mnemonic keys,
    // the session address, AND the bound signed link-device claim. Do not
    // hand-delete instead: Core's key names are `account_temporaryAccount_*`,
    // and a claim left behind means a stale signature survives a delete +
    // re-add. Mirrors publicos_client.
    await PublicOSKeychain.deleteTemporaryBlockchainKey();
    setState(() {
      _hasTemporaryKeys = false;
      _temporaryKeysAddress = null;
    });
    await _loadData();
  }

  // ── Reset app ───────────────────────────────────────────────────────────────

  Future<void> _resetApp() async {
    final confirmed = await _showResetDialog();
    if (confirmed != true || !mounted) return;

    setState(() => _isProcessingAction = true);
    try {
      // Snapshot wallet addresses BEFORE the wipe — the account list is gone
      // after deleteAll(). Includes any pending temp key.
      final walletAddresses = <String>{
        for (final addr in _accounts.values) addr.eip55With0x,
        if (_temporaryKeysAddress != null) _temporaryKeysAddress!,
      };

      // Full nuke: every Drift table (recipe from publicos_client's reset —
      // compiles against the same current Core). The conversations table caches
      // inbox-id -> topic; leaving it is what lets a stale MLS topic survive.
      await PublicOS.database.transaction(() async {
        await PublicOS.database.delete(PublicOS.database.messages).go();
        await PublicOS.database.delete(PublicOS.database.contacts).go();
        await PublicOS.database.delete(PublicOS.database.conversations).go();
        await PublicOS.database.delete(PublicOS.database.settings).go();
        await PublicOS.database.delete(PublicOS.database.feedServers).go();
        await PublicOS.database.delete(PublicOS.database.rpcServers).go();
        await PublicOS.database.delete(PublicOS.database.feedLists).go();
        await PublicOS.database.delete(PublicOS.database.listFeeds).go();
        await PublicOS.database.delete(PublicOS.database.attachmentCache).go();
        await PublicOS.database.delete(PublicOS.database.bookmarkedApps).go();
        await PublicOS.database.delete(PublicOS.database.bookmarkedPosts).go();
      });

      // On-disk libxmtp MLS databases so stale group state can't return.
      for (final address in walletAddresses) {
        await PublicOSKeychain.deleteLocalXmtpDatabase(address);
      }

      await PublicOS.secureStorage.deleteAll();

      if (!mounted) return;
      _pollTimer?.cancel();
      _snack(context.l10n.selectAccountScreenAppResetComplete);
      setState(() {
        _hasTemporaryKeys = false;
        _temporaryKeysAddress = null;
        _lastUsedAccountAddress = null;
      });
      await _loadData();
    } catch (e) {
      debugPrint('[SelectAccount] reset error: $e');
      if (!mounted) return;
      _snack(localizedError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<bool?> _showResetDialog() {
    final tokens = GlassTokens.of(context);
    final error = Theme.of(context).colorScheme.error;
    final items = [
      context.l10n.selectAccountScreenResetItemMessages,
      context.l10n.selectAccountScreenResetItemContacts,
      context.l10n.selectAccountScreenResetItemKeys,
      context.l10n.selectAccountScreenResetItemFeeds,
      context.l10n.selectAccountScreenResetItemDatabases,
    ];
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              width: DialogWidth.s,
              padding: const EdgeInsets.all(24),
              decoration: GlassTheme.glassBox(context).copyWith(
                color: tokens.surfaceDeep.withValues(alpha: 0.92),
                border: Border.all(color: error.withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: error,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.l10n.selectAccountScreenResetAppTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          // Destructive tier: icon + title both error.
                          color: error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.selectAccountScreenResetAppHeading,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.starkWhite,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(
                            Icons.remove_rounded,
                            size: 16,
                            color: error.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: tokens.textDim,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: error, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.selectAccountScreenCannotBeUndone,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            context.l10n.actionCancel,
                            style: TextStyle(color: tokens.textDim),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: error,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(context.l10n.selectAccountScreenReset),
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
    );
  }

  // ── Small actions ──────────────────────────────────────────────────────────

  void _copy(String address) {
    Clipboard.setData(ClipboardData(text: address));
    _snack(context.l10n.inboxIdsAddressCopied);
  }

  void _snack(String msg) {
    if (!mounted) return;
    final tokens = GlassTokens.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: tokens.starkWhite)),
        backgroundColor: tokens.surfaceElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // A login is in flight. The picker fades to the bare constellation and the
    // progress cluster takes over the bottom-right corner.
    final booting = _bootStatus.isNotEmpty;
    return Scaffold(
      // Shell canvas, not tokens.background: the title bar is DWM-tinted to
      // the canvas from startup (one-canvas rule, desktop_shell_redesign), so
      // every full-window screen must sit on the same tone or the bar seam
      // comes back exactly here.
      backgroundColor: ShellTones.of(context).canvas,
      body: Stack(
        children: [
          Positioned.fill(
            child: ConstellationBackground(
              color: tokens.starkWhite,
              secondaryColor: tokens.connectedAccent,
              planetCount: 42,
              maxConnectionDistance: 320,
            ),
          ),
          _fadeWhileBooting(
            booting: booting,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 40, right: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 36),
                    _header(tokens),
                    const SizedBox(height: 40),
                    Text(
                      context.l10n.selectAccountScreenIdentities,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 5,
                        color: tokens.starkWhite,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.selectAccountScreenSelectToAuthenticate,
                      style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Expanded(child: _content(tokens)),
                  ],
                ),
              ),
            ),
          ),
          // Account-creation actions, pinned bottom-right (desktop layout
          // delta; visual treatment ported from publicos_client's
          // select_account _buildActionButton — translucent starkWhite primary
          // + ghost secondary). Hidden while a
          // pending temp key still needs finishing.
          if (!_isLoadingData && !_hasTemporaryKeys)
            Positioned(
              right: 40,
              bottom: 0,
              // Fade INSIDE the Positioned — a Positioned must stay a direct
              // child of its Stack, so the wrapper cannot sit above it.
              child: _fadeWhileBooting(
                booting: booting,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    // IntrinsicWidth + stretch so both pills take the wider
                    // one's width (NEW ACCOUNT), instead of each sizing to its
                    // own label.
                    child: IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Intent first.
                          _CornerActionButton(
                            icon: Icons.devices_rounded,
                            label: context.l10n.newKeyFlowAddDevice,
                            onTap: _isProcessingAction
                                ? null
                                : () => _startNewKeyFlow(
                                    NewKeyIntent.addDevice),
                          ),
                          const SizedBox(height: 10),
                          _CornerActionButton(
                            icon: Icons.person_add_alt_1_rounded,
                            label: context.l10n.newKeyFlowNewAccount,
                            onTap: _isProcessingAction
                                ? null
                                : () => _startNewKeyFlow(
                                    NewKeyIntent.newAccount),
                          ),
                          const SizedBox(height: 10),
                          _CornerActionButton(
                            icon: Icons.key,
                            label: context.l10n.inboxIdsImportKeyTitle,
                            subtle: true,
                            onTap:
                                _isProcessingAction ? null : _showImportDialog,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Login progress — a desktop delta, not a port. publicos_client
          // covers the picker with an opaque, centered overlay
          // (select_account_screen.dart:1892); here the constellation stays lit
          // and the picker dissolves into it, with the pixel-rain + waving
          // caption pinned bottom-right — the same corner bsp_dialog/ssp_dialog
          // park their loader in. Mounted only while booting so the rain's ticker
          // isn't running invisibly on an idle picker.
          // Build version, bottom-right, small and quiet (client parity). It
          // gives the corner to the boot loader while a login runs.
          if (!booting)
            const Positioned(
              right: 20,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8, right: 4),
                  child: AppVersionLabel(),
                ),
              ),
            ),
          if (booting)
            Positioned(
              right: 40,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PixelRainLoadingWidget(
                        size: 28,
                        showShadows: false,
                      ),
                      const SizedBox(width: 14),
                      // Logo first, caption second — the loading row's canonical
                      // order desktop-wide (browser placeholder, pre-login
                      // gate). The caption waves so a long phase doesn't read
                      // as a frozen screen while the rain ticks alone.
                      WaveText(
                        text: bootPhaseLabel(context.l10n, _bootStatus) ??
                            _bootStatus,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w600,
                          color: tokens.textDim,
                          fontSize: 13,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Cross-fade a picker element out while a login runs, and stop it eating
  /// pointer events on the way. Callers that sit in the `Stack` behind a
  /// [Positioned] must wrap the Positioned's *child*, never the Positioned
  /// itself — parent-data widgets have to stay direct children of their Stack.
  Widget _fadeWhileBooting({required bool booting, required Widget child}) {
    return IgnorePointer(
      ignoring: booting,
      child: AnimatedOpacity(
        opacity: booting ? 0 : 1,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }

  Widget _header(GlassTokens tokens) {
    return Row(
      children: [
        const PhigitalLoadingWidget(size: 18, pulse: true, showShadows: false),
        const SizedBox(width: 4),
        // Wordmark: "PublicOS/client" — twin of publicos_client's login header.
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: tokens.starkWhite,
              letterSpacing: 1.2,
            ),
            children: [
              TextSpan(text: context.l10n.onbPublicosTitle),
              TextSpan(
                text: ' / ',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  color: tokens.starkWhite.withValues(alpha: 0.35),
                  letterSpacing: 0,
                ),
              ),
              const TextSpan(
                text: 'client',
                style: TextStyle(fontWeight: FontWeight.w300),
              ),
            ],
          ),
        ),
        const Spacer(),
        _HeaderIconButton(
          icon: Icons.restart_alt_rounded,
          tooltip: context.l10n.selectAccountScreenResetTooltip,
          danger: true,
          onTap: _isProcessingAction ? null : _resetApp,
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: Icons.refresh_rounded,
          tooltip: context.l10n.desktopReload,
          onTap: _isProcessingAction ? null : _loadData,
        ),
      ],
    );
  }

  Widget _content(GlassTokens tokens) {
    if (_isLoadingData) {
      return const PhigitalLoadingWidget(size: 36, showShadows: false);
    }

    final hasNothing = _accounts.isEmpty && !_hasTemporaryKeys;

    final sorted = _accounts.entries.toList()
      ..sort((a, b) {
        final al = a.value.eip55With0x == _lastUsedAccountAddress;
        final bl = b.value.eip55With0x == _lastUsedAccountAddress;
        if (al && !bl) return -1;
        if (!al && bl) return 1;
        return 0;
      });

    // Single column of cards, top-left under the IDENTITIES header. The
    // scrollable is height-capped to ~3 cards; further accounts scroll. A
    // freshly created pending key renders below the existing accounts.
    const cardGap = 18.0;
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: _cardHeight * 3 + cardGap * 2,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasNothing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    context.l10n.selectAccountScreenNoIdentitiesFound,
                    style: TextStyle(color: tokens.textDim, fontSize: 14),
                  ),
                ),
              for (final entry in sorted)
                Padding(
                  padding: const EdgeInsets.only(bottom: cardGap),
                  child: SizedBox(
                    width: _cardWidth,
                    height: _cardHeight,
                    child: _IdBadge(
                      displayName: entry.key,
                      address: entry.value.eip55With0x,
                      contact: _accountContacts[entry.key]!,
                      isLastUsed:
                          entry.value.eip55With0x == _lastUsedAccountAddress,
                      busy: _isProcessingAction,
                      onLogin: () => _selectAccount(entry.key, entry.value),
                      onCopy: () => _copy(entry.value.eip55With0x),
                      onQr: () => _openProfileQR(entry.key, entry.value),
                      onDelete: () => _deleteAccount(entry.key, entry.value),
                    ),
                  ),
                ),
              if (_hasTemporaryKeys && _temporaryKeysAddress != null)
                SizedBox(
                  width: _cardWidth,
                  height: _cardHeight,
                  child: _IdBadge(
                    displayName: context.l10n.selectAccountScreenNewKeysCardName,
                    address: _temporaryKeysAddress!,
                    contact: Contact(displayName: context.l10n.voteCardPending),
                    isPending: true,
                    busy: _isProcessingAction,
                    onCopy: () => _copy(_temporaryKeysAddress!),
                    onQr: () => _showTempKeyQR(_temporaryKeysAddress!),
                    onDelete: _deleteTemporaryKeys,
                    onActivate: _checkAndActivate,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  /// Full-screen profile-share QR for a real account — publicos_client's
  /// `ProfileQrPage` (`publicos://profile/<addr>`). Pure view; the contact is
  /// the picker's already-loaded self-contact.
  void _openProfileQR(String displayName, EthereumAddress address) {
    final contact =
        _accountContacts[displayName] ??
        Contact(
          displayName: displayName,
          publicosDisplayName: displayName,
          publicosAddress: address,
        );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileQrPage(
          address: address.eip55With0x,
          contact: contact,
          displayName: displayName,
        ),
      ),
    );
  }

  /// Link-device flow for the pending temp key — publicos_client's
  /// `showLinkDeviceDialog` (toggle New account / Add session → signs the
  /// EIP-712 consent claim via Core → QR + 1h countdown). Reload on close so a
  /// freshly-signed claim's countdown surfaces on the pending card.
  void _showTempKeyQR(String address) {
    showLinkDeviceDialog(context, tempAddress: address).then((_) {
      if (mounted) _loadData();
    });
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) {
    final tokens = GlassTokens.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        backgroundColor: tokens.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: TextStyle(color: tokens.starkWhite)),
        content: Text(body, style: TextStyle(color: tokens.textDim)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.dlgCancel, style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: destructive
                    ? Theme.of(context).colorScheme.error
                    : tokens.starkWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ID badge card
// ─────────────────────────────────────────────────────────────────────────────

class _IdBadge extends StatefulWidget {
  final String displayName;
  final String address;
  final Contact contact;
  final bool isLastUsed;
  final bool isPending;
  final bool busy;
  final VoidCallback? onLogin;
  final VoidCallback? onCopy;
  final VoidCallback? onQr;
  final VoidCallback? onDelete;
  final VoidCallback? onActivate;

  const _IdBadge({
    required this.displayName,
    required this.address,
    required this.contact,
    this.isLastUsed = false,
    this.isPending = false,
    this.busy = false,
    this.onLogin,
    this.onCopy,
    this.onQr,
    this.onDelete,
    this.onActivate,
  });

  @override
  State<_IdBadge> createState() => _IdBadgeState();
}

class _IdBadgeState extends State<_IdBadge> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final c = widget.contact;
    final short =
        '${widget.address.substring(0, 6)}...${widget.address.substring(widget.address.length - 4)}';
    final emphasis = widget.isLastUsed ? tokens.connectedAccent : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.isPending || widget.onLogin == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _hover && !widget.isPending ? 1.012 : 1,
        duration: const Duration(milliseconds: 120),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              clipBehavior: Clip.antiAlias,
              // Borderless card (mirrors publicos_client): only
              // the last-used card keeps its accent ring as a state signal.
              decoration: GlassTheme.glassBox(context, hover: _hover).copyWith(
                border: emphasis != null
                    ? Border.all(
                        color: emphasis.withValues(alpha: 0.5),
                        width: 1.5,
                      )
                    : const Border.fromBorderSide(BorderSide.none),
              ),
              child: Column(
                children: [
                  // Banner with avatar + name + address — flexes to fill the
                  // card height above the fixed action/activation rows (16:9).
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // NFT banner first ([ContactBanner]). Costs no round
                        // trip: this picker reads each account's cached
                        // self-contact, enriched at its last login, so the
                        // NFT verdict is already in the row.
                        ContactBanner(
                          contact: c,
                          fallback: _bannerFallback(tokens, c),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.15),
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 10,
                          child: Row(
                            children: [
                              GlassContactIcon(
                                contact: c,
                                address: widget.address,
                                size: 56,
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
                                            widget.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black54,
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (widget.isPending ||
                                            widget.isLastUsed) ...[
                                          const SizedBox(width: 8),
                                          _StatusBadge(
                                            label: widget.isPending
                                                ? context.l10n.manageListsSheetPendingBadge
                                                : context.l10n.selectAccountScreenBadgeRecent,
                                            color: widget.isPending
                                                ? tokens.fallbackAccent
                                                : tokens.connectedAccent,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      short,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black54,
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // An expiring key counts down here;
                                    // permanent: nothing.
                                    if (!widget.isPending)
                                      KeyLifetimeLine(accountAddress: widget.address),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Garbage button — delete this account locally from
                        // the device. Real accounts only (pending temp keys
                        // keep their own Remove in the action bar).
                        if (widget.onDelete != null && !widget.isPending)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Tooltip(
                              message: context.l10n.selectAccountScreenDeleteFromDevice,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: widget.busy ? null : widget.onDelete,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: tokens.starkWhite,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Action bar.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Row(
                      children: [
                        _SlimAction(
                          icon: Icons.qr_code_2_rounded,
                          tooltip: context.l10n.selectAccountScreenShowQr,
                          onTap: widget.busy ? null : widget.onQr,
                        ),
                        const SizedBox(width: 6),
                        _SlimAction(
                          icon: Icons.copy_rounded,
                          tooltip: context.l10n.selectAccountScreenCopyAddress,
                          onTap: widget.busy ? null : widget.onCopy,
                        ),
                        const Spacer(),
                        if (widget.isPending)
                          _SlimAction(
                            icon: Icons.delete_outline_rounded,
                            tooltip: context.l10n.walletRemove,
                            onTap: widget.busy ? null : widget.onDelete,
                          )
                        else
                          // No per-card spinner: the whole picker fades out on
                          // login and the bottom-right pixel-rain cluster owns
                          // the progress. LOGIN stays put, disabled via `busy`.
                          _PrimaryAction(
                            icon: Icons.login_rounded,
                            label: context.l10n.selectAccountScreenLogin,
                            onTap: widget.busy ? null : widget.onLogin,
                          ),
                      ],
                    ),
                  ),

                  if (widget.isPending)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: _PrimaryAction(
                          icon: Icons.check_circle_outline_rounded,
                          label: context.l10n.selectAccountScreenCheckActivation,
                          stretch: true,
                          onTap: widget.busy ? null : widget.onActivate,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bannerFallback(GlassTokens tokens, Contact contact) {
    final base = contact.iconColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base.withValues(alpha: 0.3), tokens.surfaceDeep],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: color,
        ),
      ),
    );
  }
}

class _SlimAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _SlimAction({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 18,
              color: onTap == null ? tokens.textDim : tokens.starkWhite,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool stretch;
  final VoidCallback? onTap;
  const _PrimaryAction({
    required this.icon,
    required this.label,
    this.stretch = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final enabled = onTap != null;
    // Grey primary. Teal is reserved for
    // meaning (recent/connected), never for CTAs.
    final fg = enabled ? tokens.starkWhite : tokens.textDim;
    return Material(
      color: enabled ? tokens.surfaceElevated : tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The bottom-right account-creation actions. Port of publicos_client's
/// select_account `_buildActionButton`: the primary (New account) carries a
/// translucent `starkWhite` fill; the subtle (Import key) is a `glassFill`
/// ghost. Borderless (both apps). Monochrome — teal/amber are reserved for
/// state, never CTAs. Sized `mainAxisSize.min` with
/// horizontal padding for the corner cluster (the client renders them
/// full-width inline; the corner placement is the desktop layout delta).
class _CornerActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool subtle;
  final VoidCallback? onTap;
  const _CornerActionButton({
    required this.icon,
    required this.label,
    this.subtle = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final enabled = onTap != null;
    final fg = enabled ? tokens.starkWhite : tokens.textDim;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: subtle
                ? tokens.glassFill
                : tokens.starkWhite.withValues(alpha: enabled ? 0.1 : 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool danger;
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final fg = onTap == null
        ? tokens.textDim
        : (danger ? errorColor : tokens.starkWhite);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: danger && onTap != null
            ? errorColor.withValues(alpha: 0.12)
            : tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, size: 18, color: fg),
          ),
        ),
      ),
    );
  }
}
