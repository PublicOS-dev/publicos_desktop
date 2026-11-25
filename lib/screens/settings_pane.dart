import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, Uint8List;
import 'package:publicos_core/publicos_core.dart';

import '../data/demo_contacts.dart';
import '../data/demo_feeds_data.dart';
import '../data/nft_avatar_prefs.dart';
import '../data/shell_prefs.dart';
import '../l10n/l10n_ext.dart';
import '../theme/glass_tokens.dart';
import '../theme/locale_provider.dart';
import '../widgets/app_version_label.dart';
import '../widgets/error/error_l10n.dart';
import '../widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/onboarding/onboarding_flow.dart';
import 'package:publicos_desktop/router_helpers.dart';
import '../widgets/keychain_dialog.dart';
import '../widgets/phigital_loading_widget.dart';
import '../widgets/system_app_scaffold.dart';

/// The Settings feature pane (shell index 9). publicos_client's
/// `app_settings_page.dart` ported into the desktop shell — notifications,
/// session, blockchain polling, video, NFT-avatar prefs, XMTP info (with the
/// 10-tap developer gate), the demo-data helpers, and the Developer card
/// (sync log / test sync / redeploy / register DAO / destructive ops). All of
/// it talks to the live, shared Core (`PublicOSSettings` / `PublicOS*`).
///
/// Desktop deltas vs the client page:
///   - `SystemAppScaffold` + pinned header → centered desktop pane
///     (max-width column, bottom-right loader).
///   - `SystemAppActionButton` → the local [_actionButton].
///   - dropped the mobile-only bits: "Watch onboarding" (needs the mobile
///     onboarding screen), the `package_info`-backed version label, and the FCM
///     bootstrap on the push toggle (desktop has no push delivery — the push
///     setting still persists to Core, which mobile honors; disable still
///     unregisters via `PublicOSPush`).
///   - Log out added at the bottom.
class SettingsPane extends StatefulWidget {
  final VoidCallback onLogout;

  const SettingsPane({super.key, required this.onLogout});

  @override
  State<SettingsPane> createState() => _SettingsPaneState();
}

class _SettingsPaneState extends State<SettingsPane> {
  /// Mirrors `kInboxPromptOffKey` in `widgets/keychain_dialog.dart`, inverted
  /// for display: the stored setting means "never ask", the toggle reads "do
  /// offer". Same key as the checkbox inside the publish-inbox dialog, so
  /// either surface moves the other.
  bool _offerInboxPrompt = true;

  // 10-tap gate on the XMTP card title
  int _xmtpTapCount = 0;
  bool _showDeveloperOptions = false;

  /// Which settings group is open — one at a time, like channel settings'
  /// drawers; null = all closed. Session-only on purpose.
  String? _openGroup = 'appearance';

  // Loading flags
  bool _isLoadingData = true;
  bool _isReseedingDemo = false;
  bool _isResetting = false;
  bool _isRedeployingProfile = false;
  bool _isCreatingNewsList = false;
  bool _isCreatingBlueskyList = false;
  bool _isBookmarkingApps = false;
  bool _isRegisteringDAO = false;
  bool _isDeletingContacts = false;
  bool _isDeletingApps = false;
  bool _isDeletingMessages = false;
  bool _isClearingNotifs = false;

  // Settings state
  bool _liveNotifications = true;
  bool _pushNotifications = true;
  bool _autoLogin = false;
  int _pollingMinutes = 60;
  bool _nftSparkles = true;
  bool _nftShimmer = true;

  // keccak256("PUBLICOS_ROOT_ORG")
  static final _rootOrgTypeHash = Uint8List.fromList([
    0x05, 0x81, 0x0c, 0xe1, 0xac, 0xed, 0xa5, 0x00, //
    0x58, 0x59, 0x7c, 0x4c, 0x4d, 0x41, 0x89, 0x4b, //
    0x55, 0x4d, 0x4a, 0xec, 0xd8, 0x82, 0x30, 0x8d, //
    0xe6, 0xf5, 0xe6, 0x45, 0x4f, 0x3a, 0x32, 0xd8, //
  ]);

  // Dev address gate for "redeploy profile" / "register DAO". Set this to
  // your own session address to unlock the developer options in your build.
  static const String _devAddress =
      '0x0000000000000000000000000000000000000000';

  @override
  void initState() {
    super.initState();
    _loadInboxPromptSetting();
    _loadAllData();
  }

  // ── Load ─────────────────────────────────────────────────────────────────

  Future<void> _loadAllData({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingData = true);
    try {
      await _loadNotificationSettings();
      await _loadSessionSettings();
      await _loadPollingSettings();
      await _loadAvatarSettings();
    } catch (_) {}
    if (mounted) setState(() => _isLoadingData = false);
  }

  Future<void> _loadAvatarSettings() async {
    try {
      await NftAvatarPrefs.ensureLoaded();
      if (mounted) {
        setState(() {
          _nftSparkles = NftAvatarPrefs.sparkles;
          _nftShimmer = NftAvatarPrefs.shimmer;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final live = await PublicOSSettings.getLiveNotifications();
      final push = await PublicOSSettings.getPushNotifications();
      if (mounted) {
        setState(() {
          _liveNotifications = live;
          _pushNotifications = push;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liveNotifications = true;
          _pushNotifications = true;
        });
      }
    }
  }

  Future<void> _loadSessionSettings() async {
    try {
      final val =
          await PublicOS.secureStorage.read(key: 'auto_login') ?? 'false';
      if (mounted) setState(() => _autoLogin = val == 'true');
    } catch (_) {}
  }

  Future<void> _loadPollingSettings() async {
    try {
      final minutes = await PublicOSSettings.getModulePollingMinutes();
      if (mounted) setState(() => _pollingMinutes = minutes);
    } catch (_) {}
  }

  // ── Setting mutations ──────────────────────────────────────────────────────

  Future<void> _updateLiveNotifications(bool enabled) async {
    try {
      final success = await PublicOSSettings.setLiveNotifications(enabled);
      if (success && mounted) {
        setState(() => _liveNotifications = enabled);
      } else if (mounted) {
        _snack(context.l10n.appSettingsPageFailedUpdateLive);
      }
    } catch (e) {
      if (mounted) _snack(localizedError(context.l10n, e));
    }
  }

  Future<void> _updatePushNotifications(bool enabled) async {
    try {
      final success = await PublicOSSettings.setPushNotifications(enabled);
      if (!success) {
        if (mounted) _snack(context.l10n.appSettingsPageFailedUpdatePush);
        return;
      }
      if (mounted) setState(() => _pushNotifications = enabled);
      // Desktop has no FCM delivery — persist the (shared, per-account) Core
      // setting only; on disable still unregister any token Core holds.
      if (!enabled) {
        try {
          await PublicOSPush.unregister();
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) _snack(localizedError(context.l10n, e));
    }
  }

  Future<void> _updateAutoLogin(bool enabled) async {
    try {
      await PublicOS.secureStorage.write(
        key: 'auto_login',
        value: enabled ? 'true' : 'false',
      );
      if (mounted) setState(() => _autoLogin = enabled);
    } catch (e) {
      if (mounted) _snack(localizedError(context.l10n, e));
    }
  }

  Future<void> _updatePollingMinutes(int minutes) async {
    try {
      final success = await PublicOSSettings.setModulePollingMinutes(minutes);
      if (success && mounted) setState(() => _pollingMinutes = minutes);
    } catch (e) {
      if (mounted) _snack(localizedError(context.l10n, e));
    }
  }

  Future<void> _updateNftSparkles(bool enabled) async {
    await NftAvatarPrefs.setSparkles(enabled);
    if (mounted) setState(() => _nftSparkles = enabled);
  }

  Future<void> _updateNftShimmer(bool enabled) async {
    await NftAvatarPrefs.setShimmer(enabled);
    if (mounted) setState(() => _nftShimmer = enabled);
  }

  Future<void> _reconnectRpc() async {
    try {
      await PublicOSBsp.connectToAvailableRPC();
      if (mounted) _snack(context.l10n.appSettingsPageReconnectedRpc);
    } catch (e) {
      if (mounted) _snack(localizedError(context.l10n, e));
    }
  }

  // ── Dev gate + helpers ─────────────────────────────────────────────────────

  void _onXmtpTitleTap() {
    setState(() {
      _xmtpTapCount++;
      if (_xmtpTapCount >= 10 && !_showDeveloperOptions) {
        _showDeveloperOptions = true;
        _openGroup = 'developer';
      }
    });
  }

  bool get _isDeveloperAddress {
    final currentAddress =
        PublicOS.currentBlockchainPrivateKey?.address.eip55With0x;
    return currentAddress?.toLowerCase() == _devAddress.toLowerCase();
  }

  String _formatAddress(String? address) {
    if (address == null || address.isEmpty || address.length < 10) {
      return context.l10n.appSettingsPageInvalidAddress;
    }
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _snack(context.l10n.acctSettingsCopiedToClipboard(label));
  }

  // ── Demo helpers ───────────────────────────────────────────────────────────

  Future<void> _reseedDemoContacts() async {
    setState(() => _isReseedingDemo = true);
    try {
      await seedDemoContactsIfNeeded(force: true);
      if (!mounted) return;
      _snack(context.l10n.appSettingsPageDemoContactsReseeded);
    } finally {
      if (mounted) setState(() => _isReseedingDemo = false);
    }
  }

  Future<FeedList?> _recreateList(String name, String icon) async {
    final existing = await PublicOSFeedLists.getUserLists();
    for (final list in existing.where((l) => l.name == name)) {
      await PublicOSFeedLists.deleteList(list.id);
    }
    return PublicOSFeedLists.createList(name, icon: icon);
  }

  Future<void> _createDemoChannelList() async {
    if (_isCreatingNewsList) return;
    setState(() => _isCreatingNewsList = true);
    try {
      // Feeds are a baked, live-validated set (see demo_feeds_data.dart), no
      // longer scraped from contact channel records — the demo accounts that
      // carried those are gone. Direct external RSS URLs; RssParser reads them
      // straight (no PublicOS feed server), so they carry no source-account
      // provenance.
      final newsList = await _recreateList('News', '📰');
      if (newsList == null) {
        if (mounted) _snack(context.l10n.appSettingsPageFailedCreateNewsList);
        return;
      }
      int ok = 0;
      int fail = 0;
      for (final feed in kDemoNewsFeeds) {
        try {
          final success = await PublicOSFeedLists.addFeedToList(
            newsList.id,
            feed.url,
            feed.title,
            null,
          );
          success ? ok++ : fail++;
        } catch (_) {
          fail++;
        }
      }
      if (mounted) {
        _snack(context.l10n.appSettingsPageCreatedNewsList(ok) +
            (fail > 0 ? context.l10n.appSettingsPageFailedSuffix(fail) : ''));
      }
    } catch (e) {
      if (mounted) _snack(localizedError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _isCreatingNewsList = false);
    }
  }

  Future<void> _createBlueskyListFromContacts() async {
    if (_isCreatingBlueskyList) return;
    setState(() => _isCreatingBlueskyList = true);
    try {
      final contacts = await PublicOSContacts.getStoredContacts();
      final feeds = <Map<String, dynamic>>[];
      for (final contact in contacts) {
        final rss = contact.records
            .where((r) => r.routerSubtype == RouterSubtype.channel)
            .toList();
        final canonical = rss.where((r) => r.key == 'bluesky').firstOrNull;
        final legacy = canonical == null
            ? rss.where((r) {
                final name = r.metadata.keys.contains('name')
                    ? (r.metadata['name'] as String).toLowerCase()
                    : r.key.toLowerCase();
                return name.contains('bluesky');
              }).firstOrNull
            : null;
        final record = canonical ?? legacy;
        if (record != null) {
          feeds.add({
            'url': record.value,
            'title': record.metadata.keys.contains('name')
                ? record.metadata['name'] as String
                : record.key,
            'feedFoundAtAccountAddress': contact.publicosAddress?.eip55With0x,
          });
        }
      }
      if (feeds.isEmpty) {
        if (mounted) _snack(context.l10n.appSettingsPageNoBlueskyFeeds);
        return;
      }
      final list = await _recreateList('bluesky', '🧿');
      if (list == null) {
        if (mounted) _snack(context.l10n.appSettingsPageFailedCreateBlueskyList);
        return;
      }
      int ok = 0;
      int fail = 0;
      for (final feed in feeds) {
        try {
          final success = await PublicOSFeedLists.addFeedToList(
            list.id,
            feed['url'] as String,
            feed['title'] as String?,
            null,
            feedFoundAtAccountAddress:
                feed['feedFoundAtAccountAddress'] as String?,
          );
          success ? ok++ : fail++;
        } catch (_) {
          fail++;
        }
      }
      if (mounted) {
        _snack(context.l10n.appSettingsPageCreatedBlueskyList(ok) +
            (fail > 0 ? context.l10n.appSettingsPageFailedSuffix(fail) : ''));
      }
    } catch (e) {
      if (mounted) _snack(localizedError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _isCreatingBlueskyList = false);
    }
  }

  Future<void> _bookmarkAllContactApps() async {
    if (_isBookmarkingApps) return;
    setState(() => _isBookmarkingApps = true);
    try {
      final contacts = await PublicOSContacts.getStoredContacts();
      int ok = 0;
      int fail = 0;
      int skipped = 0;
      for (final contact in contacts) {
        if (contact.publicosAddress == null) continue;
        try {
          final apps = await PublicOSAppRegistry.getAllAccountApps(
            contact.publicosAddress!,
          );
          if (apps == null || apps.isEmpty) continue;
          for (final app in apps) {
            try {
              final already = await PublicOSAppRegistry.isAppBookmarked(
                app.appName,
                contact.publicosAddress!,
              );
              if (already) {
                skipped++;
                continue;
              }
              final success = await PublicOSAppRegistry.bookmarkApp(app);
              success ? ok++ : fail++;
            } catch (_) {
              fail++;
            }
          }
        } catch (_) {}
      }
      if (mounted) {
        var msg = context.l10n.appSettingsPageBookmarkedApps(ok);
        if (skipped > 0) {
          msg += context.l10n.appSettingsPageAlreadyBookmarkedSuffix(skipped);
        }
        if (fail > 0) msg += context.l10n.appSettingsPageFailedSuffix(fail);
        _snack(msg);
      }
    } catch (e) {
      if (mounted) _snack(localizedError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _isBookmarkingApps = false);
    }
  }

  // ── Profile redeploy + DAO register (dev address only) ─────────────────────

  Future<void> _redeployJmslProfile() async {
    if (_isRedeployingProfile) return;
    setState(() => _isRedeployingProfile = true);
    try {
      final records = ProfileTemplates.getProfileRecords('jmsl');
      final privateKey = PublicOS.currentBlockchainPrivateKey;
      if (privateKey == null) throw Exception('No private key available');

      int ok = 0;
      int fail = 0;
      for (final record in records) {
        try {
          await Future.any([
            PublicOSBsp.recordManagerContract.setRecord(
              (
                target: EthereumAddress.fromHex(PublicOS.myPublicosAddress!),
                key: record.key,
                value: jsonEncode(record.toJson()),
                expiration:
                    record.chainExpiration,
                recordType: BigInt.from(record.type.index),
                customType: record.subtype ?? '',
              ),
              credentials: privateKey,
            ),
            Future.delayed(const Duration(seconds: 15))
                .then((_) => throw Exception('Timeout')),
          ]);
          ok++;
        } catch (_) {
          fail++;
        }
      }
      if (mounted) {
        _snack(context.l10n.appSettingsPageRedeployedRecords(ok) +
            (fail > 0 ? context.l10n.appSettingsPageFailedSuffix(fail) : ''));
      }
    } catch (e) {
      if (mounted) {
        _snack(localizedError(context.l10n, e,
            fallback: context.l10n.appSettingsPageRedeployFailed));
      }
    } finally {
      if (mounted) setState(() => _isRedeployingProfile = false);
    }
  }

  Future<void> _registerPublicOSDAO() async {
    if (_isRegisteringDAO) return;
    setState(() => _isRegisteringDAO = true);
    try {
      final registry = ModuleRegistry(
        address: PublicOSBsp.moduleRegistryAddress,
        client: PublicOS.web3Client,
        chainId: PublicOS.CHAIN_ID,
      );

      final existing = await Future.any([
        registry.getModuleAddress((moduleType: _rootOrgTypeHash)),
        Future.delayed(const Duration(seconds: 10))
            .then((_) => throw Exception('Timeout')),
      ]);

      final isRegistered = existing.eip55Without0x !=
          '0000000000000000000000000000000000000000';

      Contact? daoContact;
      if (isRegistered) {
        try {
          daoContact = await PublicOSContacts.fetchContact(existing);
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() => _isRegisteringDAO = false);

      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => _RegisterDAODialog(
          existingAddress: isRegistered ? existing : null,
          existingContact: daoContact,
        ),
      );

      if (result == null || result.isEmpty) return;
      setState(() => _isRegisteringDAO = true);

      final privateKey = PublicOS.currentBlockchainPrivateKey;
      if (privateKey == null) throw Exception('No private key available');

      await Future.any([
        registry.registerOrUpdateModule(
          (
            moduleType: _rootOrgTypeHash,
            moduleAddress: EthereumAddress.fromHex(result),
          ),
          credentials: privateKey,
        ),
        Future.delayed(const Duration(seconds: 30))
            .then((_) => throw Exception('Timeout')),
      ]);

      if (mounted) {
        _snack(context.l10n
            .appSettingsPageDaoRegistered('${result.substring(0, 10)}...'));
      }
    } catch (e) {
      if (mounted) _snack(localizedError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _isRegisteringDAO = false);
    }
  }

  // ── Background sync / destructive ops ──────────────────────────────────────

  Future<void> _testBackgroundSyncNow() async {
    _snack(context.l10n.appSettingsPageRunningSync);
    try {
      final result = await PublicOS.executeBackgroundSync();
      if (mounted) {
        _snack(result ? context.l10n.appSettingsPageSyncCompleted : context.l10n.appSettingsPageSyncFailed);
      }
    } catch (e) {
      if (mounted) _snack(localizedError(context.l10n, e));
    }
  }

  Future<void> _showBackgroundSyncLog() async {
    final log = await PublicOS.getBackgroundSyncLog();
    if (!mounted) return;
    final tokens = GlassTokens.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.l),
        title: Text(
          context.l10n.appSettingsPageSyncLogTitle,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: SingleChildScrollView(
          child: (log == null || log.isEmpty)
              ? Text(
                  context.l10n.appSettingsPageSyncLogEmpty,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 13,
                    height: 1.4,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.glassFill,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.borderSubtle),
                  ),
                  child: SelectableText(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: tokens.starkWhite,
                      fontSize: 11,
                    ),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.createRecordPageClose,
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk', color: tokens.starkWhite)),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDestructive(String title, String body) async {
    final tokens = GlassTokens.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.fallbackAccent.withValues(alpha: 0.4)),
        ),
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.fallbackAccent,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          body,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.dlgCancel,
                style:
                    TextStyle(fontFamily: 'SpaceGrotesk', color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.appSettingsPageDeleteAll,
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.fallbackAccent,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _confirmCompleteReset() async {
    final ok = await _confirmDestructive(
      context.l10n.appSettingsPageCompleteResetTitle,
      context.l10n.appSettingsPageCompleteResetBody,
    );
    if (ok && mounted) _performCompleteReset();
  }

  Future<void> _performCompleteReset() async {
    if (_isResetting) return;
    setState(() => _isResetting = true);
    try {
      await PublicOS.clearAllDatabaseAndSecretsData();
      if (mounted) _snack(context.l10n.appSettingsPageAllDataDeleted);
    } catch (e) {
      if (mounted) {
        _snack(localizedError(context.l10n, e,
            fallback: context.l10n.appSettingsPageResetFailed));
      }
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  Future<void> _deleteAllContacts() async {
    final ok = await _confirmDestructive(
      context.l10n.appSettingsPageDeleteContactsTitle,
      context.l10n.appSettingsPageDeleteContactsBody,
    );
    if (!ok || _isDeletingContacts) return;
    setState(() => _isDeletingContacts = true);
    try {
      final contacts = await PublicOSContacts.getStoredContacts();
      int count = 0;
      for (final contact in contacts) {
        try {
          await PublicOSContacts.removeContact(contact);
          count++;
        } catch (_) {}
      }
      if (mounted) _snack(context.l10n.appSettingsPageDeletedContacts(count));
    } catch (e) {
      if (mounted) _snack(localizedError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _isDeletingContacts = false);
    }
  }

  Future<void> _deleteAllMessagesAndConversations() async {
    final ok = await _confirmDestructive(
      context.l10n.appSettingsPageDeleteMessagesTitle,
      context.l10n.appSettingsPageDeleteMessagesBody,
    );
    if (!ok || _isDeletingMessages) return;
    setState(() => _isDeletingMessages = true);
    try {
      await PublicOS.clearAllMessagesAndConversations();
      if (mounted) _snack(context.l10n.appSettingsPageDeletedMessages);
    } catch (e) {
      if (mounted) _snack(localizedError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _isDeletingMessages = false);
    }
  }

  Future<void> _deleteAllApps() async {
    final ok = await _confirmDestructive(
      context.l10n.appSettingsPageDeleteAppsTitle,
      context.l10n.appSettingsPageDeleteAppsBody,
    );
    if (!ok || _isDeletingApps) return;
    setState(() => _isDeletingApps = true);
    try {
      final apps = await PublicOSAppRegistry.getBookmarkedApps();
      int count = 0;
      for (final app in apps) {
        try {
          await PublicOSAppRegistry.removeBookmark(
            app.appName,
            app.ownerAccountAddress,
          );
          count++;
        } catch (_) {}
      }
      if (mounted) _snack(context.l10n.appSettingsPageDeletedApps(count));
    } catch (e) {
      if (mounted) _snack(localizedError(context.l10n, e));
    } finally {
      if (mounted) setState(() => _isDeletingApps = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Built on the same `SystemAppScaffold` pane mode the
    // Account / Treasury / Nodes panes use (the client's system-app anatomy:
    // toolbar spacer first, every section in `Padding(20, 0, 20, 36)`), so all
    // four panes share ONE header implementation.
    return SystemAppScaffold(
      maxContentWidth: 720,
      title: context.l10n.appSettingsPageSettingsTitle,
      icon: Icons.settings_rounded,
      asset: 'assets/system_apps/settings.png',
      pinHeader: true,
      // NO refresh action here, deliberately.
      // Account / Treasury / Nodes keep theirs because they show live chain
      // state; Settings shows this device's own preferences, which nothing else
      // can change while the pane is open — a button would only invite the
      // question of what it is for. `_loadAllData` still runs on open.
      // Don't "restore parity" with account_center here.
      builder: (context, scrollController, tokens) {
        Widget section(Widget child) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: child,
            );
        return Stack(
          children: [
            ListView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: kToolbarHeight + 60),
                section(_buildAppearanceSection(tokens)),
                section(_buildLanguageSection(tokens)),
                section(_buildNotificationsSection(tokens)),
                section(_buildSessionSection(tokens)),
                section(_buildBlockchainSection(tokens)),
                section(_buildAvatarSection(tokens)),
                section(_group(
                  tokens,
                  id: 'mature',
                  icon: Icons.visibility_outlined,
                  title: context.l10n.settingsMatureProfilesTitle,
                  children: const [_MatureProfilesList()],
                )),
                section(_buildXmtpSection(tokens)),
                section(_buildHelpSection(tokens)),
                if (_showDeveloperOptions)
                  section(_buildDeveloperSection(tokens)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
                  child: _actionButton(
                    tokens,
                    icon: Icons.logout_rounded,
                    label: context.l10n.desktopLogOut,
                    onTap: widget.onLogout,
                  ),
                ),
              ],
            ),
            if (_isLoadingData)
              const Positioned(
                right: 16,
                bottom: 16,
                child: PhigitalLoadingWidget(size: 28, showShadows: false),
              ),
          ],
        );
      },
    );
  }

  // ── Sections ────────────────────────────────────────────────────────────────

  Widget _buildAppearanceSection(GlassTokens tokens) {
    return _group(
      tokens,
      id: 'appearance',
      icon: Icons.palette_outlined,
      title: context.l10n.desktopSettingsAppearanceTitle,
      children: [
        // Device-local (ShellPrefs / SharedPreferences, like theme_mode) —
        // window-chrome layout, not an account setting.
        ValueListenableBuilder<bool>(
          valueListenable: ShellPrefs.statusBarTop,
          builder: (context, top, _) => _toggleRow(
            tokens,
            title: context.l10n.desktopStatusBarTopTitle,
            subtitle: context.l10n.desktopStatusBarTopSubtitle,
            value: top,
            onChanged: (v) => ShellPrefs.setStatusBarTop(v),
          ),
        ),
        const SizedBox(height: 6),
        // Wording chosen over "Load all live cards at profile load": that named
        // the implementation, not the effect, and leaned on three words the
        // user does not have. "Autoplay" is borrowed from video, where every
        // user already owns it. The subtitle carries the memory cost, which is
        // the only honest way to offer a setting whose downside is invisible
        // until the app is already slow.
        ValueListenableBuilder<bool>(
          valueListenable: ShellPrefs.autoplayCards,
          builder: (context, on, _) => _toggleRow(
            tokens,
            title: context.l10n.desktopAutoplayCardsTitle,
            subtitle:
                context.l10n.desktopAutoplayCardsSubtitle,
            value: on,
            onChanged: (v) => ShellPrefs.setAutoplayCards(v),
          ),
        ),
      ],
    );
  }

  /// Language picker — client-verbatim
  /// (`app_settings_page._buildLanguageSection`). The choices feed
  /// [LocaleProvider] (SharedPreferences
  /// `app_locale`): "System default" clears the override (follow device →
  /// English fallback), English / Español set an explicit override. Endonyms
  /// ("English"/"Español") stay literal — language names are shown in their
  /// own language by convention.
  Widget _buildLanguageSection(GlassTokens tokens) {
    final l10n = context.l10n;
    final currentCode = LocaleProvider.instance?.locale?.languageCode; // null => system
    return _group(
      tokens,
      id: 'language',
      icon: Icons.language_rounded,
      title: l10n.settingsLanguageTitle,
      children: [
        Text(
          l10n.settingsLanguageSubtitle,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 11,
            fontWeight: FontWeight.w400,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _choiceChip(
              tokens,
              l10n.settingsLanguageSystemDefault,
              currentCode == null,
              () => _setLocale(null),
            ),
            _choiceChip(
              tokens,
              'English',
              currentCode == 'en',
              () => _setLocale('en'),
            ),
            _choiceChip(
              tokens,
              'Español',
              currentCode == 'es',
              () => _setLocale('es'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _setLocale(String? code) async {
    final lp = LocaleProvider.instance;
    if (lp == null) return;
    await lp.setLocale(code == null ? null : Locale(code));
    if (mounted) setState(() {});
  }

  Widget _buildNotificationsSection(GlassTokens tokens) {
    return _group(
      tokens,
      id: 'notifications',
      icon: Icons.notifications_outlined,
      title: context.l10n.appSettingsPageNotificationsTitle,
      children: [
        _toggleRow(
          tokens,
          title: context.l10n.appSettingsPageLiveNotificationsTitle,
          subtitle: context.l10n.appSettingsPageLiveNotificationsSubtitle,
          value: _liveNotifications,
          onChanged: _updateLiveNotifications,
        ),
        const SizedBox(height: 6),
        _toggleRow(
          tokens,
          title: context.l10n.appSettingsPagePushNotificationsTitle,
          subtitle: context.l10n.desktopPushSubtitle,
          value: _pushNotifications,
          onChanged: _updatePushNotifications,
        ),
      ],
    );
  }

  Widget _buildSessionSection(GlassTokens tokens) {
    return _group(
      tokens,
      id: 'session',
      icon: Icons.login_rounded,
      title: context.l10n.appSettingsPageSessionTitle,
      children: [
        _toggleRow(
          tokens,
          title: context.l10n.appSettingsPageAutoLoginTitle,
          subtitle: context.l10n.appSettingsPageAutoLoginSubtitle,
          value: _autoLogin,
          onChanged: _updateAutoLogin,
        ),
      ],
    );
  }

  Widget _buildBlockchainSection(GlassTokens tokens) {
    return _group(
      tokens,
      id: 'blockchain',
      icon: Icons.link_rounded,
      title: context.l10n.appSettingsPageBlockchainTitle,
      children: [
        _tile(
          tokens,
          child: Column(
            children: [
              _kvRow(tokens, context.l10n.appSettingsPageChainIdLabel, '${PublicOS.CHAIN_ID}'),
              const SizedBox(height: 8),
              _kvRow(tokens, context.l10n.appSettingsPageRpcLabel, _truncateUrl(PublicOS.activeRpcUrl)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _miniLabel(tokens, context.l10n.appSettingsPagePollingRateLabel),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: const [15, 30, 60, 120, 360, 1440]
              .map((m) =>
                  _pollingChip(tokens, m, m == _pollingMinutes, _updatePollingMinutes))
              .toList(),
        ),
        const SizedBox(height: 14),
        _actionButton(
          tokens,
          icon: Icons.refresh_rounded,
          label: context.l10n.appSettingsPageReconnectButton,
          onTap: _reconnectRpc,
        ),
      ],
    );
  }

  Widget _buildAvatarSection(GlassTokens tokens) {
    return _group(
      tokens,
      id: 'avatars',
      icon: Icons.auto_awesome,
      title: context.l10n.appSettingsPageAvatarTitle,
      children: [
        Text(
          context.l10n.appSettingsPageAvatarDesc,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 11,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        _toggleRow(
          tokens,
          title: context.l10n.appSettingsPageSparklesTitle,
          subtitle: context.l10n.appSettingsPageSparklesSubtitle,
          value: _nftSparkles,
          onChanged: _updateNftSparkles,
        ),
        const SizedBox(height: 6),
        _toggleRow(
          tokens,
          title: context.l10n.appSettingsPageShimmerTitle,
          subtitle: context.l10n.appSettingsPageShimmerSubtitle,
          value: _nftShimmer,
          onChanged: _updateNftShimmer,
        ),
      ],
    );
  }

  /// Replay the onboarding flow (client `_watchOnboarding`). DESKTOP DELTA: a
  /// dialog holding the phone-shaped flow, not a full-screen route.
  void _watchOnboarding() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 900),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: OnboardingFlow(
              previewMode: true,
              onComplete: () => Navigator.of(ctx).pop(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection(GlassTokens tokens) {
    return _group(
      tokens,
      id: 'help',
      icon: Icons.help_outline,
      title: context.l10n.appSettingsPageHelpTitle,
      children: [
        // Onboarding replay (client parity): preview mode never
        // touches `onboarding_completed` and ends on DONE -> pops back here.
        Text(
          context.l10n.appSettingsPageHelpOnboardingDesc,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 11,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        _actionButton(
          tokens,
          icon: Icons.play_circle_outline,
          label: context.l10n.appSettingsPageWatchOnboardingButton,
          onTap: _watchOnboarding,
        ),
        const SizedBox(height: 14),
        // Visible demo tool: build a "News" list from a baked set of live RSS
        // feeds (demo_feeds_data.dart). Kept out of the developer-options gate
        // below so it's always available as reading material.
        Text(
          context.l10n.appSettingsPageDemoNewsDesc,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 11,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        _actionButton(
          tokens,
          icon: Icons.rss_feed_rounded,
          label: _isCreatingNewsList ? context.l10n.appSettingsPageCreatingButton : context.l10n.appSettingsPageCreateDemoChannelButton,
          onTap: _isCreatingNewsList ? null : _createDemoChannelList,
        ),
        // Remaining demo/dev seeding tools are gated behind the
        // developer-options unlock (tap the XMTP area 10x), matching the
        // client.
        if (_showDeveloperOptions) ...[
          const SizedBox(height: 14),
          Text(
            context.l10n.appSettingsPageReseedDemoDesc,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          _actionButton(
            tokens,
            icon: Icons.refresh,
            label: _isReseedingDemo ? context.l10n.appSettingsPageReseedingButton : context.l10n.appSettingsPageReseedDemoButton,
            onTap: _isReseedingDemo ? null : _reseedDemoContacts,
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.appSettingsPageDemoFeedsDesc,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          _actionButton(
            tokens,
            icon: Icons.cloud_outlined,
            label:
                _isCreatingBlueskyList ? context.l10n.appSettingsPageCreatingButton : context.l10n.appSettingsPageCreateDemoBlueskyButton,
            onTap: _isCreatingBlueskyList ? null : _createBlueskyListFromContacts,
          ),
          const SizedBox(height: 10),
          _actionButton(
            tokens,
            icon: Icons.apps_rounded,
            label:
                _isBookmarkingApps ? context.l10n.appSettingsPageBookmarkingButton : context.l10n.appSettingsPageCreateDemoBookmarksButton,
            onTap: _isBookmarkingApps ? null : _bookmarkAllContactApps,
          ),
        ],
        const SizedBox(height: 16),
        const Align(
          alignment: Alignment.centerRight,
          child: AppVersionLabel(),
        ),
      ],
    );
  }

  Widget _buildXmtpSection(GlassTokens tokens) {
    final xmtpAddress = PublicOS.clientXmtpAddress;
    final inboxId = PublicOS.clientXmtpInboxId;
    final keyLabel = PublicOS.currentXmtpKeyLabel;
    final connected = xmtpAddress != null;

    return _group(
      tokens,
      id: 'xmtp',
      icon: Icons.forum_outlined,
      title: context.l10n.onbXmtpTitle,
      trailing: connected
          ? _pillBadge(tokens, context.l10n.appSettingsPageConnectedBadge, tokens.connectedAccent)
          : null,
      // The hidden 10-tap developer unlock rides the header tap.
      onHeaderTap: _onXmtpTitleTap,
      children: [
        _tile(
          tokens,
          child: Column(
            children: [
              _kvRow(
                tokens,
                context.l10n.appSettingsPageAddressLabel,
                connected ? _formatAddress(xmtpAddress) : context.l10n.appSettingsPageNotInitialized,
                copyable: connected ? xmtpAddress : null,
                onCopy: (v) => _copyToClipboard(v, context.l10n.appSettingsPageCopyLabelXmtpAddress),
              ),
              const SizedBox(height: 8),
              _kvRow(
                tokens,
                context.l10n.appSettingsPageInboxIdLabel,
                inboxId != null ? _formatAddress(inboxId) : context.l10n.appSettingsPageNotInitialized,
                copyable: inboxId,
                onCopy: (v) => _copyToClipboard(v, context.l10n.appSettingsPageInboxIdLabel),
              ),
              const SizedBox(height: 8),
              _kvRow(tokens, context.l10n.appSettingsPageActiveKeyLabel, keyLabel ?? context.l10n.accountCenterNone),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _toggleRow(
          tokens,
          title: context.l10n.appSettingsPageInboxPromptTitle,
          subtitle:
              context.l10n.appSettingsPageInboxPromptSubtitle,
          value: _offerInboxPrompt,
          onChanged: _updateInboxPrompt,
        ),
      ],
    );
  }

  Future<void> _loadInboxPromptSetting() async {
    try {
      final rec = await PublicOSSettings.getSetting(kInboxPromptOffKey);
      if (!mounted) return;
      setState(() => _offerInboxPrompt = rec?.value != 'true');
    } catch (_) {
      // Unreadable — keep the default (offer on), matching the keychain.
    }
  }

  Future<void> _updateInboxPrompt(bool offer) async {
    setState(() => _offerInboxPrompt = offer);
    try {
      await PublicOSSettings.setSetting(
        kInboxPromptOffKey,
        Record.asSettings(
          key: kInboxPromptOffKey,
          // Stored inverted: the key means "never ask".
          value: (!offer).toString(),
          isSystem: true,
          isExpired: false,
        ),
      );
    } catch (_) {}
  }

  Widget _buildDeveloperSection(GlassTokens tokens) {
    return _group(
      tokens,
      id: 'developer',
      icon: Icons.bug_report_outlined,
      title: context.l10n.appSettingsPageDeveloperTitle,
      trailing: _pillBadge(tokens, context.l10n.appSettingsPageUnlockedBadge, tokens.fallbackAccent),
      children: [
        _miniLabel(tokens, context.l10n.appSettingsPageUtilitiesLabel),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _devChip(tokens, Icons.bug_report_outlined, 'Sync Log',
                loading: false, onTap: _showBackgroundSyncLog),
            _devChip(tokens, Icons.play_arrow_rounded, 'Test Sync',
                loading: false, onTap: _testBackgroundSyncNow),
            if (_isDeveloperAddress) ...[
              _devChip(tokens, Icons.refresh_rounded, 'Redeploy',
                  loading: _isRedeployingProfile,
                  onTap: _isRedeployingProfile ? null : _redeployJmslProfile),
              _devChip(tokens, Icons.account_balance_rounded, 'Register DAO',
                  loading: _isRegisteringDAO,
                  onTap: _isRegisteringDAO ? null : _registerPublicOSDAO),
            ],
          ],
        ),
        const SizedBox(height: 20),
        _miniLabel(tokens, context.l10n.appSettingsPageDestructiveLabel, color: tokens.fallbackAccent),
        const SizedBox(height: 8),
        _destructiveButton(
          tokens,
          icon: Icons.people_outline_rounded,
          label: _isDeletingContacts ? context.l10n.appSettingsPageDeletingButton : context.l10n.appSettingsPageDeleteAllContactsButton,
          onTap: _isDeletingContacts ? null : _deleteAllContacts,
        ),
        const SizedBox(height: 8),
        _destructiveButton(
          tokens,
          icon: Icons.forum_outlined,
          label: _isDeletingMessages ? context.l10n.appSettingsPageDeletingButton : context.l10n.appSettingsPageDeleteAllMessagesButton,
          onTap:
              _isDeletingMessages ? null : _deleteAllMessagesAndConversations,
        ),
        const SizedBox(height: 8),
        _destructiveButton(
          tokens,
          icon: Icons.apps_rounded,
          label: _isDeletingApps ? context.l10n.appSettingsPageDeletingButton : context.l10n.appSettingsPageDeleteAllAppsButton,
          onTap: _isDeletingApps ? null : _deleteAllApps,
        ),
        const SizedBox(height: 8),
        // Client-verbatim (`app_settings_page` developer block): wipes the
        // cached chain-activity rows AND resets the sweep cursor to block 0.
        _destructiveButton(
          tokens,
          icon: Icons.notifications_off_rounded,
          label: _isClearingNotifs
              ? context.l10n.appSettingsPageClearingButton
              : context.l10n.appSettingsPageClearChainNotificationsButton,
          onTap: _isClearingNotifs ? null : _clearChainNotifications,
        ),
        const SizedBox(height: 8),
        _destructiveButton(
          tokens,
          icon: Icons.delete_forever_rounded,
          label: _isResetting ? context.l10n.appSettingsPageResettingButton : context.l10n.appSettingsPageResetAllDataButton,
          onTap: _isResetting ? null : _confirmCompleteReset,
        ),
      ],
    );
  }

  /// Client-verbatim (`app_settings_page._clearChainNotifications`).
  /// `PublicOSActivity.clearStored` deletes every activity row for this
  /// client and rewinds the sweep cursor to block 0, so the next background
  /// sweep re-scans the current chain from the start instead of resuming
  /// from a stale block height.
  Future<void> _clearChainNotifications() async {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        title: Text(
          l10n.appSettingsPageClearChainTitle,
          style: TextStyle(
              fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          l10n.appSettingsPageClearChainBody,
          style: TextStyle(
              fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.dlgCancel,
              style: TextStyle(
              fontFamily: 'SpaceGrotesk',color: tokens.textDim),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.appSettingsPageClear,
              style: TextStyle(
              fontFamily: 'SpaceGrotesk',color: tokens.fallbackAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || _isClearingNotifs) return;
    setState(() => _isClearingNotifs = true);
    try {
      final deleted = await PublicOSActivity.clearStored();
      if (mounted) _snack(l10n.appSettingsPageClearedNotifs(deleted));
    } catch (e) {
      if (mounted) _snack(localizedError(l10n, e));
    } finally {
      if (mounted) setState(() => _isClearingNotifs = false);
    }
  }

  // ── Leaf helpers ─────────────────────────────────────────────────────────────

  Widget _miniLabel(GlassTokens tokens, String text, {Color? color}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: color ?? tokens.textDim,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  /// Collapsible settings group.
  /// Borrows `channel_settings_page`'s accordion drawers: one group open at a
  /// time, the whole header row toggles, the chevron turns 90°, the first group
  /// starts open. Shell deltas: no divider line (borderless), and the header's
  /// glyphs brighten on hover or while open, the way a rail row does.
  Widget _group(
    GlassTokens tokens, {
    required String id,
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onHeaderTap,
    required List<Widget> children,
  }) {
    final open = _openGroup == id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GroupHeader(
          icon: icon,
          title: title,
          trailing: trailing,
          open: open,
          onTap: () {
            setState(() => _openGroup = open ? null : id);
            onHeaderTap?.call();
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: open
              ? Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Borderless settings tile — the desktop shell's surface grammar: a
  /// `glassFill` tone step carries the edge, no hairline, radius 12 like the
  /// rail's icon box. **Tiles hold ROWS** (toggles, key/value groups). Chips
  /// and buttons sit on the stage beside them, never inside one: a filled
  /// control in a filled tile is a box-in-a-box. A tile with
  /// [onTap] brightens on hover.
  Widget _tile(GlassTokens tokens, {required Widget child, VoidCallback? onTap}) {
    return Material(
      color: tokens.glassFill,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: tokens.glassFill,
        highlightColor: tokens.glassFill,
        splashColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: child,
        ),
      ),
    );
  }

  /// A toggle row: the whole tile flips the switch. No leading icon — the
  /// section header already names the group.
  Widget _toggleRow(
    GlassTokens tokens, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _tile(
      tokens,
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Teal only while ON (it is the state); off is grey on grey with
          // no outline ring, which M3 draws by default.
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeThumbColor: tokens.connectedAccent,
            activeTrackColor: tokens.connectedAccent.withValues(alpha: 0.25),
            inactiveThumbColor: tokens.textDim,
            inactiveTrackColor: tokens.surfaceElevated,
            trackOutlineColor:
                const WidgetStatePropertyAll(Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _pillBadge(GlassTokens tokens, String label, Color color) {
    // No ring: the tint already says it (the shell's borderless rule).
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
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

  Widget _kvRow(
    GlassTokens tokens,
    String label,
    String value, {
    String? copyable,
    void Function(String)? onCopy,
  }) {
    // Field label speaks the caps eyebrow voice of [_miniLabel], so every
    // in-page field label (POLLING RATE, CHAIN ID, …) reads the same.
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: _miniLabel(tokens, label.toUpperCase()),
        ),
        Expanded(
          child: copyable != null
              ? GestureDetector(
                  onTap: () => onCopy?.call(copyable),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: tokens.starkWhite,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.copy_rounded, size: 11, color: tokens.textDim),
                    ],
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tokens.starkWhite,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ],
    );
  }

  Widget _devChip(
    GlassTokens tokens,
    IconData icon,
    String label, {
    required bool loading,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: tokens.glassFill,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: tokens.glassFill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const PhigitalLoadingWidget(size: 14, showShadows: false)
              else
                Icon(icon,
                    size: 14,
                    color: onTap == null ? tokens.textDim : tokens.starkWhite),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: onTap == null ? tokens.textDim : tokens.starkWhite,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _destructiveButton(
    GlassTokens tokens, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    // Borderless: the orange tint carries "destructive" by itself.
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: tokens.fallbackAccent.withValues(alpha: 0.10),
          foregroundColor: tokens.fallbackAccent,
          disabledBackgroundColor: tokens.glassFill,
          disabledForegroundColor: tokens.textDim,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    GlassTokens tokens, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.surfaceElevated,
          foregroundColor: tokens.starkWhite,
          disabledBackgroundColor: tokens.glassFill,
          disabledForegroundColor: tokens.textDim,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          // No ring: the elevated fill already makes it the primary.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _truncateUrl(String url) {
    if (url.length <= 40) return url;
    return '${url.substring(0, 20)}...${url.substring(url.length - 16)}';
  }
}

// ── Group header ──────────────────────────────────────────────────────────────

/// The tappable header of a [_SettingsPaneState._group]. Grey glyphs that turn
/// white on hover or while open (the rail's selected/hovered grammar); the
/// title stays white. Teal is never used here: open is a place, not a state.
class _GroupHeader extends StatefulWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool open;
  final VoidCallback onTap;

  const _GroupHeader({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.open,
    required this.onTap,
  });

  @override
  State<_GroupHeader> createState() => _GroupHeaderState();
}

class _GroupHeaderState extends State<_GroupHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final fg = (_hovered || widget.open) ? tokens.starkWhite : tokens.textDim;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        // Open = a really light `glassFill` wash, so it stands out;
        // a hovered closed header gets half of that, so hover
        // never reads as open. The 14 px inset matches the tiles below, so the
        // wash's edge lines up with theirs and the glyph lines up with their
        // text.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.open
                ? tokens.glassFill
                : _hovered
                    ? tokens.glassFill.withValues(alpha: tokens.glassFill.a / 2)
                    : tokens.glassFill.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: fg, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (widget.trailing != null) ...[
                widget.trailing!,
                const SizedBox(width: 10),
              ],
              AnimatedRotation(
                turns: widget.open ? 0.25 : 0,
                duration: const Duration(milliseconds: 180),
                child: Icon(Icons.chevron_right_rounded, size: 18, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Polling chip ──────────────────────────────────────────────────────────────

Widget _pollingChip(
  GlassTokens tokens,
  int minutes,
  bool active,
  ValueChanged<int> onChanged,
) {
  String label;
  if (minutes < 60) {
    label = '${minutes}m';
  } else if (minutes < 1440) {
    label = '${minutes ~/ 60}h';
  } else {
    label = '${minutes ~/ 1440}d';
  }
  return _choiceChip(tokens, label, active, () => onChanged(minutes));
}

/// Pick-one chip for the settings pickers (language, polling rate). Borderless
/// with the shell chip's exact values (`ExplorerChip`: glassFill inactive,
/// surfaceElevated active, radius 18, 12/8 padding, w500/w700), so the pickers
/// match the Contacts / Messages chip bars.
Widget _choiceChip(
  GlassTokens tokens,
  String label,
  bool active,
  VoidCallback onTap,
) {
  return Material(
    color: active ? tokens.surfaceElevated : tokens.glassFill,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      hoverColor: tokens.glassFill,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            height: 1.3,
            letterSpacing: 0.3,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? tokens.starkWhite : tokens.textDim,
          ),
        ),
      ),
    ),
  );
}

// ── Register DAO dialog (ported from the client) ──────────────────────────────

class _RegisterDAODialog extends StatefulWidget {
  final EthereumAddress? existingAddress;
  final Contact? existingContact;

  const _RegisterDAODialog({this.existingAddress, this.existingContact});

  @override
  State<_RegisterDAODialog> createState() => _RegisterDAODialogState();
}

class _RegisterDAODialogState extends State<_RegisterDAODialog> {
  final _addressCtrl = TextEditingController();
  bool _showInput = false;

  @override
  void initState() {
    super.initState();
    _showInput = widget.existingAddress == null;
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return AlertDialog(
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
      backgroundColor: tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.borderSubtle),
      ),
      title: Text(
        context.l10n.appSettingsPageRegisterDaoTitle,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.starkWhite,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.existingAddress != null && !_showInput) ...[
              Text(
                context.l10n.appSettingsPageDaoAlreadyRegistered,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.glassFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Row(
                  children: [
                    if (widget.existingContact != null)
                      GlassContactIcon(
                        contact: widget.existingContact!,
                        size: 36,
                      )
                    else
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: tokens.glassFill,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tokens.borderSubtle),
                        ),
                        child: Icon(Icons.account_balance_rounded,
                            color: tokens.connectedAccent, size: 18),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.existingContact != null)
                            Text(
                              widget.existingContact!.displayName,
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                color: tokens.starkWhite,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            widget.existingAddress!.eip55With0x,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: tokens.textDim,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: () => setState(() => _showInput = true),
                icon: Icon(Icons.edit_outlined,
                    color: tokens.connectedAccent, size: 16),
                label: Text(
                  context.l10n.appSettingsPageUpdateDaoAddress,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.connectedAccent,
                    fontSize: 13,
                  ),
                ),
              ),
            ] else ...[
              Text(
                context.l10n.appSettingsPageEnterDaoAddress,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              _GlassField(
                tokens: tokens,
                controller: _addressCtrl,
                label: context.l10n.appSettingsPageDaoAddressLabel,
                hint: '0x...',
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.dlgCancel,
              style: TextStyle(fontFamily: 'SpaceGrotesk', color: tokens.textDim)),
        ),
        if (_showInput)
          TextButton(
            onPressed: () {
              final address = _addressCtrl.text.trim();
              if (address.isEmpty ||
                  !address.startsWith('0x') ||
                  address.length != 42) {
                return;
              }
              Navigator.pop(context, address);
            },
            child: Text(
              context.l10n.keychainRegister,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.connectedAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Glass text field ──────────────────────────────────────────────────────────

class _GlassField extends StatelessWidget {
  final GlassTokens tokens;
  final TextEditingController controller;
  final String label;
  final String? hint;

  const _GlassField({
    required this.tokens,
    required this.controller,
    required this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: tokens.starkWhite,
        fontSize: 14,
      ),
      cursorColor: tokens.starkWhite,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.textDim,
          fontSize: 13,
        ),
        hintStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.textDim.withValues(alpha: 0.6),
          fontSize: 13,
        ),
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
          borderSide: BorderSide(color: tokens.connectedAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.fallbackAccent),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

/// Profiles the viewer said "I'm 18+" to (Core settings `mature_ok.<address>`,
/// written by the browser's mature gate; client twin). Desktop's
/// AppNav.toProfile focuses the Contacts pane on the profile. Icon + name on the left,
/// a tap opens the profile, the red bin deletes the setting so the profile asks
/// again next time.
class _MatureProfilesList extends StatefulWidget {
  const _MatureProfilesList();

  @override
  State<_MatureProfilesList> createState() => _MatureProfilesListState();
}

class _MatureProfilesListState extends State<_MatureProfilesList> {
  static const _prefix = 'mature_ok.';
  List<({String key, String address, Contact? contact})>? _rows;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = <({String key, String address, Contact? contact})>[];
    try {
      final all = await PublicOSSettings.getAllSettings();
      for (final e in all.entries) {
        if (!e.key.startsWith(_prefix) || e.value.value != 'true') continue;
        final address = e.key.substring(_prefix.length);
        Contact? contact;
        try {
          contact = await PublicOSContacts.getContact(EthereumAddress.fromHex(address));
        } catch (_) {}
        rows.add((key: e.key, address: address, contact: contact));
      }
    } catch (_) {} // signed out: nothing kept
    if (mounted) setState(() => _rows = rows);
  }

  Future<void> _remove(String key) async {
    try {
      await PublicOSSettings.deleteSetting(key);
    } catch (_) {}
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final rows = _rows;
    if (rows == null) return const SizedBox(height: 48);
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          l10n.settingsMatureProfilesEmpty,
          style: TextStyle(
              fontFamily: 'SpaceGrotesk', color: tokens.textDim, fontSize: 12, height: 1.4),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final r in rows) ...[
          Material(
            color: tokens.glassFill,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => AppNav.toProfile(context, r.address),
              hoverColor: tokens.glassFill,
              highlightColor: tokens.glassFill,
              splashColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                child: Row(
                  children: [
                    GlassContactIcon(contact: r.contact, address: r.address, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        r.contact?.publicosDisplayName ??
                            r.contact?.displayName ??
                            '${r.address.substring(0, 6)}…${r.address.substring(r.address.length - 4)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          color: tokens.starkWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.settingsMatureProfilesRemove,
                      icon: Icon(Icons.delete_outline_rounded,
                          size: 20, color: tokens.softDanger),
                      onPressed: () => _remove(r.key),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
