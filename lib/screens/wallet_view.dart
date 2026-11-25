import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zero_cached_image/zero_cached_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/widgets/explorer_chip.dart';
import 'package:publicos_desktop/widgets/chain_icon.dart';
import 'package:publicos_desktop/data/chain_registry.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/dashed_add_button.dart';
import 'package:publicos_desktop/widgets/feeds/emoji_picker_dialog.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/transactions/send_sheet.dart';
import 'package:publicos_desktop/widgets/send_icon.dart';
import 'package:publicos_desktop/widgets/threshold_components.dart';
// DELTA: wallet_manager_sheet (the MANAGE dApp browser) is NOT ported — it
// wraps PublicOSWebView (webview_flutter), which has no Windows
// implementation. See _showWalletManagerSheet below.
import 'package:publicos_desktop/widgets/wallet/transaction_history_sheet.dart';
import 'package:publicos_desktop/widgets/wallet/wallet_avatar.dart';
import 'package:publicos_desktop/widgets/keychain_dialog.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart' show EthPrivateKey;
import 'package:publicos_desktop/router.dart';
import 'package:publicos_web3_bridge/publicos_web3_bridge.dart'
    show WebScope, WebStorageProfileId;
import 'package:publicos_desktop/widgets/browser/publicos_webview.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';

/// DELTA (desktop): the client launches the wallet's secondary surfaces as
/// bottom sheets (`showModalBottomSheet`). Desktop shows the SAME builder
/// content in a centered glass dialog via `showGlassSheetDialog`
/// (`utils/glass_sheet_dialog.dart`, the shared shell). The only body edits
/// at each
/// surface are dropping the drag handle and squaring the top-only sheet radius
/// to all corners.
class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => WalletViewState();
}

class WalletViewState extends State<WalletView> {
  // One flag per loader so that the build can keep showing the loading
  // indicator until *all* sources have settled — instead of the first one
  // to finish flipping a shared flag and exposing a premature empty state.
  bool _isLoading = true;
  bool _groupsLoading = true;
  bool _keychainLoading = true;
  bool _linkedLoading = true;
  List<Map<String, dynamic>> _wallets = [];
  List<Map<String, dynamic>> _groupWallets = [];
  List<Map<String, dynamic>> _keychainWallets = [];
  List<Map<String, dynamic>> _linkedWallets = [];
  bool _showPersonal = true;
  bool _showGroup = false;
  bool _showKeychain = true;
  bool _showLinked = true;
  bool _groupsLoaded = false;

  // Recent OX transfers per wallet address (lowercased key), for the in-card
  // activity preview + the full-history sheet. Loaded async so the card never
  // blocks on a log scan; empty list = loaded-but-quiet, absent = not loaded.
  final Map<String, List<TokenTransfer>> _txByAddress = {};
  final Set<String> _txLoading = {};

  /// Wallets whose history was never stored on this device and is being read
  /// from the chain for the first time. Only these reserve the activity
  /// block's height while they load; every other landing already has its
  /// lines from the device (see [_primeTransfers]).
  final Set<String> _txFirstFill = {};

  /// Rows per page: the card's read and each further page of the sheet.
  static const int _txPage = 25;

  /// Counterparty **wallet** address (lowercase) -> their [Contact], for the
  /// history sheet's rows. Two hops, mirroring the notification rows:
  ///   1. wallet -> account, on chain, via `PublicOSWalletActivity.ownerAccountOf`
  ///      (a main Safe is never a contact address, so a direct contacts lookup
  ///      always misses). One `eth_call` per DISTINCT NEW counterparty.
  ///   2. account -> Contact, from the LOCAL store — free, no chain.
  /// [_cpOwnerCache] is shared across every wallet and negative-caches, so a
  /// stranger seen in two wallets is queried once and never re-queried.
  final Map<String, Contact> _cpByWallet = {};
  final Map<String, String?> _cpOwnerCache = {};

  // Local per-wallet icon override (emoji), stored LOCAL only (a
  // `PublicOSSettings` Drift row, free + device-scoped), keyed per wallet
  // address. Applies to every wallet the user owns — Safe, keychain keys, and
  // linked wallets; groups keep their on-chain avatar. Missing → a sensible
  // default at render (the key's own emoji, else a coin). UI-owned key — the
  // SDK stays generic per the "no typed wrappers for UI-only settings" rule.
  static const _kWalletIconKeyPrefix = 'wallet_icon_';
  static const _kDefaultWalletIcon = '🪙';
  String _walletIconKey(String address) =>
      '$_kWalletIconKeyPrefix${address.toLowerCase()}';

  /// Read a wallet's local icon override (null if unset). Free Drift read.
  Future<String?> _loadWalletIcon(String address) async {
    try {
      final rec = await PublicOSSettings.getSetting(_walletIconKey(address));
      return rec?.value;
    } catch (_) {
      return null;
    }
  }

  bool get _anyLoading =>
      _isLoading || _groupsLoading || _keychainLoading || _linkedLoading;

  // Wallet manager app
  AppBookmark? _selectedWalletManagerApp;
  Contact? _walletManagerOwnerContact;

  @override
  void initState() {
    super.initState();
    _loadWallets();
    _loadKeychainWallets();
    _loadGroupWallets(showLoading: false);
    _loadLinkedWallets(showLoading: false);
    _loadWalletManagerSetting();
  }

  Future<void> _loadWallets({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
    try {
      // Ensure currentMyContact is not null before proceeding
      if (AppStateNotifier.currentMyContact == null || AppStateNotifier.currentMyContact!.publicosAddress == null) {
        print('WalletView: currentMyContact or its address is null. Cannot load wallets.');
        if (mounted) {
          setState(() {
            _wallets = [];
            if (showLoading) _isLoading = false;
          });
        }
        return;
      }

      final accountAddress = AppStateNotifier.currentMyContact!.publicosAddress!;
      // The "Personal" section is the account's main Safe, always first.
      // WalletDirectory v2's getWallets() does not prepend the Safe, so we
      // resolve it independently — this guarantees the Safe card is always
      // present regardless of what the directory returns. Linked/additional
      // wallets are loaded separately in _loadLinkedWallets().
      final safeAddress = await PublicOSSafe.getMainSafeAddress(accountAddress);
      final List<Map<String, dynamic>> walletsWithDetails = [];

      if (safeAddress != null) {
        double balance = 0;
        try {
          final balanceWei = await PublicOSTreasury.getTokenBalance(
              EthereumAddress.fromHex(safeAddress));
          balance = balanceWei.toDouble() / 1e18;
        } catch (_) {}

        // Local icon override (emoji) if the user set one; else the card falls
        // back to a coin at render.
        final customIcon = await _loadWalletIcon(safeAddress);

        walletsWithDetails.add({
          'name': 'main',
          'address': safeAddress,
          'balance': balance,
          'details': null,
          'color': _getWalletColor('main'),
          'accountAddress': accountAddress,
          'protocol': PublicOSWallets.protoEvm,
          'chainId': null,
          'walletType': null,
          'walletKey': null,
          'isMainSafe': true,
          'label': '',
          'showBalance': true,
          'customIcon': customIcon,
        });
      }

      // What the device already holds of the Safe's history, read before the
      // card is shown so it lands with its activity lines.
      if (safeAddress != null) await _primeTransfers(safeAddress);

      if (mounted) {
        setState(() {
          _wallets = walletsWithDetails;
          if (showLoading) _isLoading = false;
        });
      }

      // Then bring it up to the chain's head in the background.
      if (safeAddress != null) {
        _loadTransfers(safeAddress);
      }
    } catch (e) {
      print('Error loading wallets: $e');
      if (mounted) {
        setState(() {
          _wallets = [];
          if (showLoading) _isLoading = false;
        });
      }
    }
  }

  /// The device's copy of a wallet's history, read with no chain request
  /// Called before the card is shown, so the card lands with its
  /// activity lines and its final height. Sets no state: the caller's own
  /// `setState` shows it. A wallet never stored here is marked as a first
  /// fill instead, the one case that reserves the height while it loads.
  Future<void> _primeTransfers(String walletAddress) async {
    final key = walletAddress.toLowerCase();
    if (_txByAddress.containsKey(key)) return;
    try {
      final addr = EthereumAddress.fromHex(walletAddress);
      if (await PublicOSWallets.hasTransferHistory(addr,
          chainId: PublicOS.CHAIN_ID)) {
        _txByAddress[key] = await PublicOSWallets.getTransferHistory(addr,
            chainId: PublicOS.CHAIN_ID, limit: _txPage);
      } else {
        _txFirstFill.add(key);
      }
    } catch (e) {
      print('Error reading stored transfers: $e');
    }
  }

  /// Bring a PublicOS wallet's stored history (Safe, group Safe, keychain key)
  /// up to the chain's head, then re-read the first page if anything arrived.
  /// The first time on a device this reads the whole chain; after that only
  /// the blocks since the last visit (`PublicOSWallets.syncTransferHistory`).
  /// Async + best-effort: a failure leaves what was showing. Deduped so
  /// overlapping section reloads don't sync the same address twice.
  /// PublicOS network only for now.
  Future<void> _loadTransfers(String walletAddress) async {
    final key = walletAddress.toLowerCase();
    if (_txLoading.contains(key)) return;
    if (mounted) setState(() => _txLoading.add(key));
    final addr = EthereumAddress.fromHex(walletAddress);
    try {
      final had = _txByAddress[key];
      // Names for the lines already showing; not awaited, the sync is next.
      if (had != null) _resolveCounterparties(addr, had);
      final found = await PublicOSWallets.syncTransferHistory(addr,
          chainId: PublicOS.CHAIN_ID);
      if (found || had == null) {
        final txs = await PublicOSWallets.getTransferHistory(addr,
            chainId: PublicOS.CHAIN_ID, limit: _txPage);
        if (mounted) setState(() => _txByAddress[key] = txs);
        await _resolveCounterparties(addr, txs);
      }
    } catch (e) {
      print('Error loading transfers: $e');
    } finally {
      if (mounted) {
        setState(() {
          _txLoading.remove(key);
          _txFirstFill.remove(key);
        });
      }
    }
  }

  /// Name + avatar for the OTHER end of each transfer, so the history sheet can
  /// read "Received from · [icon] Juan" instead of a bare hex string.
  ///
  /// Best-effort and cosmetic: a failed lookup just leaves the row showing the
  /// address, exactly as it does today. Deliberately does NOT `fetchContact`
  /// (4-7 chain calls) — the account -> Contact hop reads the local store only,
  /// so an unknown-but-real account simply renders unnamed until it's a contact.
  Future<void> _resolveCounterparties(
    EthereumAddress me,
    List<TokenTransfer> txs,
  ) async {
    final others = <String, EthereumAddress>{};
    for (final t in txs) {
      final other = t.isOutgoing(me) ? t.to : t.from;
      final k = other.eip55With0x.toLowerCase();
      if (!_cpByWallet.containsKey(k)) others[k] = other;
    }
    if (others.isEmpty) return;

    // account (lowercase) -> Contact, read once from the local store.
    final stored = <String, Contact>{};
    for (final c in await PublicOSContacts.getStoredContacts()) {
      final a = c.publicosAddress?.eip55With0x.toLowerCase();
      if (a != null) stored[a] = c;
    }

    final resolved = <String, Contact>{};
    for (final entry in others.entries) {
      final account = await PublicOSWalletActivity.ownerAccountOf(
        entry.value,
        _cpOwnerCache,
      );
      if (account == null) continue; // no account => no icon, by design
      final c = stored[account.toLowerCase()];
      if (c != null) resolved[entry.key] = c;
    }
    if (resolved.isNotEmpty && mounted) {
      setState(() => _cpByWallet.addAll(resolved));
    }
  }

  /// Load the account's linked wallets from the WalletDirectory's stored set
  /// (no main-Safe prepend). These render as standalone "linked" cards with a
  /// dashed border, carrying edit-label + unlink actions (the user owns the
  /// *link* even when they don't hold the key, e.g. a Solana wallet).
  ///
  /// Two things are deliberately NOT shown here:
  ///   - the main Safe (it owns the Personal slot), and
  ///   - any EVM address that is also a keychain key marked "show in wallet" —
  ///     those surface as keychain cards with a LINKED badge instead (see
  ///     [_loadKeychainWallets]), so we don't render the same address twice.
  /// Non-EVM links (Solana etc.) always show here.
  Future<void> _loadLinkedWallets({bool showLoading = true}) async {
    if (mounted) {
      setState(() => _linkedLoading = true);
    }
    try {
      final account = AppStateNotifier.currentMyContact?.publicosAddress;
      if (account == null) {
        if (mounted) {
          setState(() {
            _linkedWallets = [];
            _linkedLoading = false;
          });
        }
        return;
      }

      final stored = await PublicOSWallets.getStoredWallets(account);
      final safeAddress =
          (await PublicOSSafe.getMainSafeAddress(account))?.toLowerCase();
      // EVM addresses also surfaced as keychain "show in wallet" cards are
      // deduped out here — they get a LINKED badge on their keychain card.
      Set<String> keychainAddrs = {};
      try {
        final keys = await PublicOSKeychain.getKeysWithWalletEnabled(
            account.eip55With0x);
        keychainAddrs =
            keys.map((k) => (k['address'] as String).toLowerCase()).toSet();
      } catch (_) {}

      final List<Map<String, dynamic>> linked = [];
      for (final w in stored) {
        final isEvm = w.protocol == PublicOSWallets.protoEvm;
        final addrLower = isEvm ? w.addressHex.toLowerCase() : null;

        if (isEvm && addrLower != null) {
          // Never surface the main Safe — it owns the Personal slot.
          if (safeAddress != null && addrLower == safeAddress) continue;
          // Deduped against keychain show-in-wallet cards.
          if (keychainAddrs.contains(addrLower)) continue;
        }

        // EVM displays as 0x…; non-EVM (Solana etc.) displays its human address
        // (base58/bech32), carried as UTF-8 in addressData.
        final displayAddress =
            isEvm ? w.addressHex : utf8.decode(w.addressData);

        // Only EVM linked wallets carry a OX balance on this chain.
        double balance = 0;
        if (isEvm) {
          try {
            final balanceWei = await PublicOSTreasury.getTokenBalance(
                EthereumAddress.fromHex(w.addressHex));
            balance = balanceWei.toDouble() / 1e18;
          } catch (_) {}
        }

        final displayName = w.label.isNotEmpty ? w.label : 'Linked wallet';
        linked.add({
          'name': displayName,
          'address': displayAddress,
          'balance': balance,
          'color': _getWalletColor(displayName),
          'accountAddress': account,
          'protocol': w.protocol,
          'chainId': w.chainId,
          'walletKey': w.walletKey,
          'label': w.label,
          'showBalance': isEvm,
          'isLinked': true,
          'customIcon': await _loadWalletIcon(displayAddress),
        });
      }

      if (mounted) {
        setState(() {
          _linkedWallets = linked;
          _linkedLoading = false;
        });
      }
    } catch (e) {
      print('Error loading linked wallets: $e');
      if (mounted) {
        setState(() {
          _linkedWallets = [];
          _linkedLoading = false;
        });
      }
    }
  }

  Future<void> _loadGroupWallets({bool showLoading = true}) async {
    if (mounted) {
      setState(() => _groupsLoading = true);
    }
    try {
      // Ensure currentMyContact is not null before proceeding
      if (AppStateNotifier.currentMyContact == null || AppStateNotifier.currentMyContact!.publicosAddress == null) {
        print('WalletView: currentMyContact or its address is null. Cannot load group wallets.');
        if (mounted) {
          setState(() {
            _groupWallets = [];
            _groupsLoading = false;
            _groupsLoaded = true;
          });
        }
        return;
      }

      // Clear existing group wallets for fresh load
      if (mounted) {
        setState(() => _groupWallets = []);
      }

      // Get groups that current user is a member of
      final currentUserAddress = AppStateNotifier.currentMyContact!.publicosAddress!;
      final groupAddresses = await PublicOSGovernance.getOrgsForAccount(currentUserAddress);

      // Load each group wallet progressively (display as each loads)
      for (final groupAddress in groupAddresses) {
        try {
          // Local-only contact lookup — the wallet row only needs displayName,
          // and orgs the user is a member of are almost always already cached.
          // Fall back to a short-address stub so a cold cache still renders the
          // row instead of blocking on ~7 RPCs per group via fetchContact.
          Contact groupContact = await PublicOSContacts.getContact(groupAddress) ??
              Contact(
                displayName: _formatAddress(groupAddress.eip55With0x),
                publicosAddress: groupAddress,
                isOrgAccount: true,
              );

          final mainWalletAddress = await PublicOSSafe.getMainSafeAddress(groupAddress);
          if (mainWalletAddress != null) {
            final balanceWei = await PublicOSTreasury.getTokenBalance(EthereumAddress.fromHex(mainWalletAddress));
            final balance = balanceWei.toDouble() / 1e18;

            final walletData = {
              'name': 'main',
              'address': mainWalletAddress,
              'balance': balance,
              'groupContact': groupContact,
              'color': _getWalletColor(groupContact.displayName),
              'isGroup': true,
              'accountAddress': groupAddress,
            };

            // Group Safes are PublicOS addresses too — load their activity.
            await _primeTransfers(mainWalletAddress);
            _loadTransfers(mainWalletAddress);

            if (mounted) {
              setState(() {
                _groupWallets.add(walletData);
                _sortGroupWallets();
              });
            }
          }
        } catch (e) {
          print('Error loading group wallet details for ${groupAddress.eip55With0x}: $e');
        }
      }
      if (mounted) {
        setState(() {
          _groupsLoading = false;
          _groupsLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading group wallets: $e');
      if (mounted) {
        setState(() {
          _groupWallets = [];
          _groupsLoading = false;
          _groupsLoaded = true;
        });
      }
    }
  }

  /// Sort group wallets with PublicOS always first
  void _sortGroupWallets() {
    _groupWallets.sort((a, b) {
      final aContact = a['groupContact'] as Contact?;
      final bContact = b['groupContact'] as Contact?;
      final aName = aContact?.displayName.toLowerCase() ?? '';
      final bName = bContact?.displayName.toLowerCase() ?? '';

      // PublicOS always comes first
      if (aName == 'publicos') return -1;
      if (bName == 'publicos') return 1;

      // Otherwise alphabetical
      return aName.compareTo(bName);
    });
  }

  Future<void> _loadKeychainWallets({bool showLoading = true}) async {
    if (mounted) {
      setState(() => _keychainLoading = true);
    }
    try {
      final currentUserAddress = AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;
      if (currentUserAddress == null) {
        print('WalletView: currentMyContact or its address is null. Cannot load keychain wallets.');
        if (mounted) {
          setState(() {
            _keychainWallets = [];
            _keychainLoading = false;
          });
        }
        return;
      }

      // Get all keys with wallet enabled
      final walletEnabledKeys = await PublicOSKeychain.getKeysWithWalletEnabled(currentUserAddress);

      // Which of these keychain keys are also linked in the WalletDirectory?
      // Keep the full directory entry per address so the card's tab button can
      // unlink it (needs walletKey + chainId). Also deduped out of the Linked
      // section so the same EVM address never appears twice.
      Map<String, Wallet> linkedByAddr = {};
      try {
        final acct = AppStateNotifier.currentMyContact?.publicosAddress;
        if (acct != null) {
          final stored = await PublicOSWallets.getStoredWallets(acct);
          for (final w in stored) {
            if (w.protocol == PublicOSWallets.protoEvm) {
              linkedByAddr[w.addressHex.toLowerCase()] = w;
            }
          }
        }
      } catch (_) {}

      // Get balance for each key
      final List<Map<String, dynamic>> keychainWalletsWithBalances = [];
      for (final key in walletEnabledKeys) {
        try {
          final address = key['address'] as String;
          final label = key['label'] as String;
          final emoji = key['emoji'] as String? ?? '🔑';

          // Get token balance
          final ethAddress = EthereumAddress.fromHex(address);
          final balanceWei = await PublicOSTreasury.getTokenBalance(ethAddress);
          final balanceEth = balanceWei.toDouble() / 1e18;

          // Keychain keys are PublicOS addresses — load their activity too.
          await _primeTransfers(address);
          _loadTransfers(address);

          keychainWalletsWithBalances.add({
            'name': label,
            'address': address,
            'balance': balanceEth,
            'emoji': emoji,
            'color': Color(key['color'] ?? Colors.blue.value),
            'isKeychain': true,
            'isAlsoLinked': linkedByAddr.containsKey(address.toLowerCase()),
            'walletKey': linkedByAddr[address.toLowerCase()]?.walletKey,
            'chainId': linkedByAddr[address.toLowerCase()]?.chainId,
            'customIcon': await _loadWalletIcon(address),
          });
        } catch (e) {
          print('Error loading balance for keychain wallet ${key['label']}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _keychainWallets = keychainWalletsWithBalances;
          _keychainLoading = false;
        });
      }
    } catch (e) {
      print('Error loading keychain wallets: $e');
      if (mounted) {
        setState(() {
          _keychainWallets = [];
          _keychainLoading = false;
        });
      }
    }
  }

  /// Load the configured wallet manager app from settings
  Future<void> _loadWalletManagerSetting() async {
    try {
      // Get stored app name from settings
      final settingRecord = await PublicOSSettings.getSetting('wallet_manager_app');
      final storedAppName = settingRecord?.value;

      // Get all bookmarked apps
      final bookmarkedApps = await PublicOSAppRegistry.getBookmarkedApps();

      // Filter to wallet_manager category apps
      final walletManagerApps = bookmarkedApps.where(
        (app) => app.getPointer('category_one')?.value == 'wallet_manager',
      ).toList();

      if (walletManagerApps.isEmpty) {
        if (mounted) {
          setState(() {
            _selectedWalletManagerApp = null;
            _walletManagerOwnerContact = null;
          });
        }
        return;
      }

      // Find the stored app by name, or fall back to first wallet_manager app
      AppBookmark? selectedApp;
      if (storedAppName != null && storedAppName.isNotEmpty) {
        selectedApp = walletManagerApps.where(
          (app) => app.appName == storedAppName,
        ).firstOrNull;
      }
      selectedApp ??= walletManagerApps.first;

      // Resolve owner contact
      Contact? ownerContact;
      try {
        ownerContact = await PublicOSContacts.fetchContact(
          selectedApp.ownerAccountAddress,
        );
      } catch (e) {
        print('WalletView: Error resolving wallet manager owner: $e');
      }

      if (mounted) {
        setState(() {
          _selectedWalletManagerApp = selectedApp;
          _walletManagerOwnerContact = ownerContact;
        });
      }
    } catch (e) {
      print('WalletView: Error loading wallet manager setting: $e');
    }
  }

  // Simplified color generation for consistency, without relying on external 'details'
  Color _getWalletColor(String name) {
    final colors = [
      _glassConnectedAccent(context),
      _glassConnectedAccent(context),
      const Color(0xFF7c3aed), // purple
      _glassFallbackAccent(context),
      _glassFallbackAccent(context),
      _glassConnectedAccent(context),
    ];
    // Hash the name to get a consistent index
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }

  void _launchProfile(Contact contact) {
    AppNav.toContact(context, contact);
  }

  List<Map<String, dynamic>> get _filteredWallets {
    List<Map<String, dynamic>> combinedWallets = [];

    // Order: Personal (Safe) → Keychain (show-in-wallet keys) → Linked (other
    // linked wallets) → Groups (with PublicOS first).
    if (_showPersonal) {
      combinedWallets.addAll(_wallets);
    }

    if (_showKeychain) {
      combinedWallets.addAll(_keychainWallets);
    }

    if (_showLinked) {
      combinedWallets.addAll(_linkedWallets);
    }

    if (_showGroup) {
      // Groups are already sorted with PublicOS first via _sortGroupWallets
      combinedWallets.addAll(_groupWallets);
    }

    return combinedWallets;
  }

  void _copyToClipboard(String text) {
    final l10n = context.l10n;
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.walletAddressCopied)),
      );
    });
  }

  String _formatAddress(String address) {
    if (address.length < 10) return address;
    return "${address.substring(0, 6)}...${address.substring(address.length - 4)}";
  }

  void _showUnifiedSendSheet({EthereumAddress? accountAddress, String? walletAddress}) {
    print('DEBUG: Opening UnifiedSendSheet with:');
    print('DEBUG: accountAddress: ${accountAddress?.eip55With0x}');
    print('DEBUG: walletAddress: $walletAddress');

    showSendSheet(
      context: context,
      config: SendSheetConfig(
        targetMode: SendTargetMode.searchAny,
        feedFoundAtAccountAddress: accountAddress,
        originatingWalletAddress: walletAddress,
      ),
    ).then((_) {
      // Refresh wallet balances when the send sheet is closed
      print('DEBUG: Send sheet closed, refreshing wallet balances');
      _refreshWalletBalances();
    });
  }

  /// Refresh wallet balances without showing loading indicators
  Future<void> _refreshWalletBalances() async {
    try {
      await _loadWallets(showLoading: false);
      await _loadGroupWallets(showLoading: false);
      await _loadKeychainWallets(showLoading: false);
      await _loadLinkedWallets(showLoading: false);
      print('DEBUG: Wallet balances refreshed successfully');
    } catch (e) {
      print('DEBUG: Error refreshing wallet balances: $e');
    }
  }

  // Wallet settings sheet with wallet manager selector
  void showSettingsSheet() {
    showGlassSheetDialog(
      context: context,
      builder: (sheetContext) {
        final tokens = GlassTokens.of(context);

        return Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                  child: Row(
                    children: [
                      Text(
                        context.l10n.walletSettingsTitle,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          color: tokens.starkWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: tokens.starkWhite),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                  child: Divider(color: tokens.borderSubtle, height: 1),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.walletManagerLabel,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: tokens.textDim,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _WalletManagerSelector(
                        selectedApp: _selectedWalletManagerApp,
                        ownerContact: _walletManagerOwnerContact,
                        cardBg: tokens.glassFill,
                        cardBorder: tokens.borderMedium,
                        onSelect: () async {
                          Navigator.pop(sheetContext);
                          await _showWalletManagerPicker();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show a picker sheet to select a wallet manager app
  Future<void> _showWalletManagerPicker() async {
    // Load available wallet manager apps
    List<AppBookmark> walletManagerApps = [];
    try {
      final bookmarkedApps = await PublicOSAppRegistry.getBookmarkedApps();
      walletManagerApps = bookmarkedApps
          .where(
              (app) => app.getPointer('category_one')?.value == 'wallet_manager')
          .toList();
    } catch (e) {
      print('WalletView: Error loading wallet manager apps: $e');
    }

    if (!mounted) return;

    showGlassSheetDialog(
      context: context,
      builder: (sheetContext) {
        final tokens = GlassTokens.of(context);

        return Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                  child: Row(
                    children: [
                      Text(
                        context.l10n.walletSelectManagerTitle,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          color: tokens.starkWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: tokens.starkWhite),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                  child: Divider(color: tokens.borderSubtle, height: 1),
                ),
                if (walletManagerApps.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.l10n.walletNoManagerApps,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 13,
                        height: 1.4,
                        color: tokens.textDim,
                      ),
                    ),
                  )
                else
                  ...walletManagerApps.map((app) => _WalletManagerAppRow(
                        app: app,
                        isSelected: _selectedWalletManagerApp?.appName ==
                            app.appName,
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          try {
                            await PublicOSSettings.setSetting(
                              'wallet_manager_app',
                              Record.asSettings(
                                key: 'wallet_manager_app',
                                value: app.appName,
                                isSystem: true,
                              ),
                            );
                          } catch (e) {
                            print(
                                'WalletView: Error saving wallet manager setting: $e');
                          }
                          await _loadWalletManagerSetting();
                        },
                      )),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleGroupChipTap() {
    setState(() => _showGroup = !_showGroup);
  }

  void _showManageKeysSheet() {
    // DELTA: the client mounts KeychainSheet(type: KeychainType.web) as a
    // bottom sheet; desktop already re-shelled that whole sheet as
    // showKeychainDialog — reuse it. myContact must be passed or
    // the session-key tile renders the avatar-less fallback and the dialog
    // reads as a different (duplicate) keychain vs the sidebar entry.
    showKeychainDialog(
      context,
      myContact: AppStateNotifier.currentMyContact,
      onKeysChanged: () {
        // Reload keychain wallets when keys are modified
        _loadKeychainWallets();
      },
    );
  }

  /// Open the add-wallet sheet. EVM (v1): pick a keychain key, sign the
  /// LinkWallet proof locally, and submit a verified `addWallet`. Non-EVM
  /// (Solana etc.) is shown as coming-soon. Reloads every wallet section on
  /// success — a newly linked wallet surfaces via [_loadLinkedWallets] (or
  /// [_loadKeychainWallets] when the EVM link is also a keychain key), never
  /// via [_loadWallets] (which only owns the main Safe), so a full refresh is
  /// required for the new card to appear without a manual pull-to-refresh.
  Future<void> _showAddWalletSheet() async {
    if (AppStateNotifier.currentMyContact?.publicosAddress == null) return;
    final result = await showGlassSheetDialog<bool>(
      context: context,
      builder: (_) => const _AddWalletSheet(),
    );
    if (result == true) {
      await _refreshWalletBalances();
    }
  }

  /// A tinted square emoji tile — the keychain-key look, reused for a Safe's
  /// user-picked icon. Sized to [size] with an accent-tinted background.
  ///
  /// The body now lives in `components/wallet/wallet_avatar.dart` so the wallet
  /// **notification rows render the identical mark** — one implementation, not
  /// a copy that can drift.
  Widget _emojiTile(String emoji, double size, double cornerRadius,
          Color accent, bool isDark) =>
      walletEmojiTile(emoji, size, cornerRadius, accent, isDark);

  /// Tapping a wallet's icon opens the emoji picker and persists the choice
  /// LOCALLY (a `PublicOSSettings` row keyed by the wallet address — free,
  /// device-scoped), then reloads so every section repaints with the new icon.
  /// Used by the Safe, keychain keys, and linked wallets (not groups).
  Future<void> _showEditWalletIcon(
      String address, String? currentIcon) async {
    final emoji = await showEmojiPickerDialog(
      context,
      currentEmoji: (currentIcon != null && currentIcon.isNotEmpty)
          ? currentIcon
          : _kDefaultWalletIcon,
    );
    if (emoji == null) return;
    final key = _walletIconKey(address);
    await PublicOSSettings.setSetting(
      key,
      Record.asSettings(
        key: key,
        value: emoji,
        isSystem: true,
      ),
    );
    await _refreshWalletBalances();
  }

  /// Link a keychain key to the account's WalletDirectory from its card tab
  /// button: ask for a (required) label, sign the LinkWallet proof locally with
  /// the held key, submit `addWallet`. Mirrors the in-app EVM path in
  /// `_AddWalletSheet`. [keyLabel] is the keychain key's label (used to export
  /// its private key); the user-typed label names the directory entry.
  Future<void> _linkKeychainWallet(String address, String keyLabel) async {
    final account = AppStateNotifier.currentMyContact?.publicosAddress;
    if (account == null) return;

    final controller = TextEditingController(text: keyLabel);
    final walletLabel = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
        title: Text(context.l10n.walletLinkWalletTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: context.l10n.walletLabelHint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.dlgCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(context.l10n.walletLinkWalletAction),
          ),
        ],
      ),
    );
    // Label is required.
    if (walletLabel == null || walletLabel.isEmpty || !mounted) return;

    try {
      final pkHex = await PublicOSKeychain.exportPrivateKey(
          account.eip55With0x, keyLabel);
      if (pkHex == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errAddWalletFailed)),
          );
        }
        return;
      }
      final eoaKey = EthPrivateKey.fromHex(
          pkHex.startsWith('0x') ? pkHex.substring(2) : pkHex);
      final walletAddress = EthereumAddress.fromHex(address);
      final deadline =
          BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600);
      final signature = PublicOSWallets.signLinkWalletEoa(
        account: account,
        walletAddress: walletAddress.value,
        deadline: deadline,
        eoaKey: eoaKey,
      );
      final wallet = Wallet(
        protocol: PublicOSWallets.protoEvm,
        addressData: walletAddress.value,
        chainId: 0, // EOA → chain-agnostic
        label: walletLabel,
        walletType: WalletType.eoa,
        proof: signature,
        verification: Verification.onchainVerified,
      );
      final txHash =
          await PublicOSWallets.addWallet(wallet, deadline: deadline);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(txHash == null
              ? context.l10n.errAddWalletFailed
              : context.l10n.walletLinked),
        ),
      );
      if (txHash != null) await _refreshWalletBalances();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errAddWalletFailed)),
      );
    }
  }

  /// Top-right link/unlink tab button — the inbox-id "add/remove tab" glyph.
  /// [linked] true → red `tab_unselected` (unlink); false → accent
  /// `tab_rounded` (link). Pinned to the top of the [iconSize]-tall row.
  Widget _walletTab(bool linked, double iconSize, VoidCallback onTap) {
    final color =
        linked ? const Color(0xFFf87171) : _glassConnectedAccent(context);
    return SizedBox(
      height: iconSize,
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(left: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(linked ? Icons.tab_unselected : Icons.tab_rounded,
                size: 18, color: color),
          ),
        ),
      ),
    );
  }

  /// Per-row overflow menu for additional directory wallets.
  Future<void> _showWalletRowMenu({
    required Uint8List? walletKey,
    required int chainId,
    required String currentLabel,
  }) async {
    if (walletKey == null) return;
    final tokens = GlassTokens.of(context);
    final choice = await showGlassSheetDialog<String>(
      context: context,
      width: DialogWidth.m,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.edit_outlined, color: tokens.starkWhite),
                title: Text(context.l10n.walletEditLabel),
                onTap: () => Navigator.pop(sheetContext, 'edit'),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: tokens.starkWhite),
                title: Text(context.l10n.walletRemoveWallet),
                onTap: () => Navigator.pop(sheetContext, 'remove'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (choice == 'edit') {
      await _showEditLabelSheet(
        walletKey: walletKey,
        chainId: chainId,
        currentLabel: currentLabel,
      );
    } else if (choice == 'remove') {
      await _showRemoveWalletConfirm(
        walletKey: walletKey,
        chainId: chainId,
        currentLabel: currentLabel,
      );
    }
  }

  Future<void> _showEditLabelSheet({
    required Uint8List walletKey,
    required int chainId,
    required String currentLabel,
  }) async {
    final controller = TextEditingController(text: currentLabel);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
        title: Text(context.l10n.walletEditLabel),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: context.l10n.walletLabelHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.dlgCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(context.l10n.walletSave),
          ),
        ],
      ),
    );
    if (newLabel == null || newLabel == currentLabel) return;
    final txHash = await PublicOSWallets.updateWalletLabel(
      walletKey: walletKey,
      chainId: chainId,
      newLabel: newLabel,
    );
    if (!mounted) return;
    if (txHash == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.walletLabelUpdateFailed)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.walletLabelUpdateSubmitted)),
    );
    await Future.wait([
      _loadLinkedWallets(showLoading: false),
      _loadKeychainWallets(showLoading: false),
    ]);
  }

  Future<void> _showRemoveWalletConfirm({
    required Uint8List walletKey,
    required int chainId,
    required String currentLabel,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        title: Text(context.l10n.walletRemoveWalletConfirmTitle),
        content: Text(
          currentLabel.isEmpty
              ? context.l10n.walletRemoveWalletBodyNoLabel
              : context.l10n.walletRemoveWalletBody(currentLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.dlgCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.walletRemove),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final txHash = await PublicOSWallets.removeWallet(
      walletKey: walletKey,
      chainId: chainId,
    );
    if (!mounted) return;
    if (txHash == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.walletRemoveFailed)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.walletRemoved)),
    );
    await Future.wait([
      _loadLinkedWallets(showLoading: false),
      _loadKeychainWallets(showLoading: false),
    ]);
  }

  Widget _buildChips(ThemeData theme) {
    final tokens = GlassTokens.of(context);
    final groupShowsCount = _groupsLoaded || _groupWallets.isNotEmpty;
    return ExplorerChipBar(
      children: [
        // ExplorerChip(
        //   label: 'Personal',
        //   icon: Icons.person_outline_rounded,
        //   active: _showPersonal,
        //   onTap: () => setState(() => _showPersonal = !_showPersonal),
        // ),
        // const SizedBox(width: 8),
        // ExplorerChip(
        //   label: 'Keychain',
        //   icon: Icons.vpn_key_rounded,
        //   active: _showKeychain,l
        //   onTap: () => setState(() => _showKeychain = !_showKeychain),
        // ),
        // const SizedBox(width: 8),
        ExplorerChip(
          label: context.l10n.walletChipLinked,
          icon: Icons.link_rounded,
          active: _showLinked,
          count: _linkedWallets.isNotEmpty ? _linkedWallets.length : null,
          trailing: _linkedLoading
              ? SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.2,
                    color: tokens.textDim,
                  ),
                )
              : null,
          onTap: () => setState(() => _showLinked = !_showLinked),
        ),
        const SizedBox(width: 8),
        ExplorerChip(
          label: context.l10n.walletChipGroup,
          icon: Icons.group_rounded,
          active: _showGroup,
          count: groupShowsCount ? _groupWallets.length : null,
          trailing: _groupsLoading
              ? SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.2,
                    color: tokens.textDim,
                  ),
                )
              : null,
          onTap: _handleGroupChipTap,
        ),
        const SizedBox(width: 16),
        ExplorerChip(
          label: context.l10n.walletChipManageKeys,
          icon: Icons.key_rounded,
          active: false,
          onTap: _showManageKeysSheet,
        ),
        const SizedBox(width: 8),
        ExplorerChip(
          label: context.l10n.walletChipSettings,
          icon: Icons.tune_rounded,
          active: false,
          onTap: showSettingsSheet,
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final loading = _anyLoading;
    final hasWallets = _filteredWallets.isNotEmpty;

    // While anything is still loading and we don't have a wallet to show
    // yet, don't fall through to "No Wallets Found" — keep the chips visible
    // and show a small bottom-right loader (same pattern as the BSP page),
    // so the empty state only ever appears after every loader has settled.
    final Widget body = hasWallets
        ? _buildWalletsList()
        : (loading ? _buildLoadingShell() : _buildEmptyState(context));

    return Stack(
      children: [
        body,
        if (loading)
          const Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: PhigitalLoadingWidget(size: 28, showShadows: false),
            ),
          ),
      ],
    );
  }

  /// Chips header + an empty scroll area while we wait for the first wallet.
  /// Keeps the layout stable so the bottom-right loader doesn't sit on a
  /// blank background and the header doesn't pop in once data arrives.
  Widget _buildLoadingShell() {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildChips(theme),
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }

  Future<void> _refreshWallets() async {
    await Future.wait([
      _loadWallets(),
      _loadGroupWallets(),
      _loadKeychainWallets(),
      _loadLinkedWallets(),
    ]);
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Chips at the top (fixed)
        _buildChips(theme),
        // Empty state (scrollable)
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshWallets,
            color: _glassConnectedAccent(context),
            child: ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: ThresholdEmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: context.l10n.walletEmptyTitle,
                    subtitle: context.l10n.walletEmptySubtitle,
                    iconColor: _glassConnectedAccent(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletsList() {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Chips at the top (fixed)
        _buildChips(theme),
        // Wallets list (scrollable)
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshWallets,
            color: _glassConnectedAccent(context),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 0.0, bottom: 20),
              // +1 for the dashed "Link new wallet" footer affordance.
              itemCount: _filteredWallets.length + 1,
              itemBuilder: (context, index) {
                if (index == _filteredWallets.length) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: DashedAddButton(
                      label: context.l10n.walletLinkNewWallet,
                      icon: Icons.add_rounded,
                      onTap: _showAddWalletSheet,
                    ),
                  );
                }
                final wallet = _filteredWallets[index];
                return _buildWalletCard(
                  name: wallet['name'],
                  address: wallet['address'],
                  balance: wallet['balance'],
                  color: wallet['color'] ?? _glassConnectedAccent(context),
                  isGroup: wallet['isGroup'] ?? false,
                  groupContact: wallet['groupContact'],
                  accountAddress: wallet['accountAddress'] as EthereumAddress?,
                  isKeychain: wallet['isKeychain'] ?? false,
                  emoji: wallet['emoji'],
                  protocol: wallet['protocol'] as String?,
                  chainId: wallet['chainId'] as int?,
                  walletKey: wallet['walletKey'] as Uint8List?,
                  showBalance: wallet['showBalance'] as bool? ?? true,
                  isMainSafe: wallet['isMainSafe'] as bool? ?? false,
                  label: wallet['label'] as String? ?? '',
                  isLinked: wallet['isLinked'] as bool? ?? false,
                  isAlsoLinked: wallet['isAlsoLinked'] as bool? ?? false,
                  customIcon: wallet['customIcon'] as String?,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Format large balances with scientific notation for readability
  String _formatLargeBalance(double balance) {
    if (balance >= 1e12) {
      // Trillions: show as x.xx × 10^12
      return '${(balance / 1e12).toStringAsFixed(2)} × 10¹²';
    } else if (balance >= 1e9) {
      // Billions: show as x.xxB
      return '${(balance / 1e9).toStringAsFixed(2)}B';
    } else if (balance >= 1e6) {
      // Millions: show as x.xxM
      return '${(balance / 1e6).toStringAsFixed(2)}M';
    } else if (balance >= 1e4) {
      // Ten thousands: show as x.xxK
      return '${(balance / 1e3).toStringAsFixed(1)}K';
    } else if (balance >= 100) {
      return balance.toStringAsFixed(0);
    } else if (balance >= 1) {
      return balance.toStringAsFixed(2);
    } else {
      return balance.toStringAsFixed(4);
    }
  }

  Widget _buildWalletCard({
    required String name,
    required String address,
    required double balance,
    required Color color,
    bool isGroup = false,
    Contact? groupContact,
    EthereumAddress? accountAddress,
    bool isKeychain = false,
    String? emoji,
    String? protocol,
    int? chainId,
    Uint8List? walletKey,
    bool showBalance = true,
    bool isMainSafe = false,
    String label = '',
    bool isLinked = false,
    bool isAlsoLinked = false,
    String? customIcon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    // Responsive sizing
    final iconSize = isSmallScreen ? 44.0 : 50.0;
    final iconCornerRadius = isSmallScreen ? 10.0 : 12.0;
    final walletNameFontSize = isSmallScreen ? 17.0 : 20.0;
    final balanceFontSize = isSmallScreen ? 22.0 : 28.0;
    final addressFontSize = isSmallScreen ? 11.0 : 13.0;

    // Phigital card colors
    final cardBg = GlassTokens.of(context).surfaceElevated;
    final cardBorder = GlassTokens.of(context).borderMedium;

    // Determine accent color based on wallet type
    final accentColor = isGroup
        ? _glassFallbackAccent(context)
        : isKeychain
            ? color
            : _glassConnectedAccent(context);

    // The account-type glyph shown left of the name (replaces the PRIMARY/KEY/
    // GROUP badges + the old avatar corner badge). Safe accounts (personal Safe
    // and group Safes) → shield; keychain keys → key; linked wallets → link.
    final IconData? typeGlyph = (isMainSafe || isGroup)
        ? Icons.shield_rounded
        : isKeychain
            ? Icons.key_rounded
            : isLinked
                ? Icons.link_rounded
                : null;

    // Group Safes read as "<org>.<wallet>" (e.g. "PublicOS.main"); everything
    // else is just its own name.
    final String displayName = (isGroup && groupContact != null)
        ? '${groupContact.displayName}.$name'
        : name;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: CustomPaint(
        // Linked wallets are display-only — a dashed border signals that.
        foregroundPainter: isLinked
            ? _DashedBorderPainter(color: cardBorder, radius: 14)
            : null,
        child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          // All cards are borderless now — flat bank-card look, consistent
          // across every wallet type. Linked wallets keep their dashed frame
          // via the painter above (the display-only signal); nothing else
          // draws a border.
          border: null,
          boxShadow: const [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Column(
            children: [
              // Main content area
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Icon + Name/Address
                    Row(
                      children: [
                        // Identity icon: the Safe's user-picked emoji (default
                        // coin), a keychain key's emoji, or the contact avatar
                        // (groups / linked). The account TYPE is signalled by
                        // the glyph left of the name below, not on the avatar.
                        // The self path binds to AppStateNotifier so a self-edit
                        // repaints here live.
                        // Groups show the org's on-chain avatar (tap → profile,
                        // not editable). Every wallet the user owns (Safe /
                        // keychain / linked) shows a tappable local emoji icon —
                        // tap opens the picker; the value is a `wallet_icon_
                        // <addr>` override that falls back to the key's emoji or
                        // a coin.
                        if (isGroup && groupContact != null)
                          GlassContactIcon(
                            contact: groupContact,
                            size: iconSize,
                            onTap: () => _launchProfile(groupContact),
                          )
                        else
                          GestureDetector(
                            onTap: () =>
                                _showEditWalletIcon(address, customIcon),
                            child: _emojiTile(
                              customIcon ??
                                  (isKeychain && emoji != null
                                      ? emoji
                                      : _kDefaultWalletIcon),
                              iconSize,
                              iconCornerRadius,
                              accentColor,
                              isDark,
                            ),
                          ),
                        const SizedBox(width: 14),
                        // Name and address
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Wallet name row with badges
                              Row(
                                children: [
                                  if (typeGlyph != null) ...[
                                    Icon(
                                      typeGlyph,
                                      size: walletNameFontSize * 0.95,
                                      color: accentColor,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Text(
                                      displayName,
                                      style: TextStyle(
                                        fontSize: walletNameFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface,
                                        letterSpacing: -0.3,
                                        height: 1.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!isMainSafe && !isGroup && !isKeychain && !isLinked && protocol != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _protocolBadgeLabel(protocol, chainId),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                  // Non-EVM linked wallets (Solana etc.) show
                                  // their chain so they're distinguishable.
                                  if (isLinked &&
                                      protocol != null &&
                                      protocol != PublicOSWallets.protoEvm) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _protocolBadgeLabel(protocol, chainId),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                  // (LINKED badge dropped — the top-right tab
                                  // button now shows link/unlink state.)
                                ],
                              ),
                              const SizedBox(height: 4),
                              // (Group subtitle dropped — the name already reads
                              // "<org>.<wallet>".)
                              // Address
                              GestureDetector(
                                onTap: () => _copyToClipboard(address),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatAddress(address),
                                      style: TextStyle(
                                        fontSize: addressFontSize,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.onSurfaceVariant,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.copy_rounded,
                                      size: addressFontSize,
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tab button (link / unlink) top-right — replaces the
                        // three-dots + the LINKED badge. Safe / group: none.
                        if (isKeychain && !isAlsoLinked)
                          _walletTab(false, iconSize,
                              () => _linkKeychainWallet(address, name))
                        else if (isKeychain &&
                            isAlsoLinked &&
                            walletKey != null)
                          _walletTab(
                              true,
                              iconSize,
                              () => _showRemoveWalletConfirm(
                                    walletKey: walletKey,
                                    chainId: chainId ?? 0,
                                    currentLabel: name,
                                  ))
                        else if (isLinked && walletKey != null)
                          _walletTab(
                              true,
                              iconSize,
                              () => _showRemoveWalletConfirm(
                                    walletKey: walletKey,
                                    chainId: chainId ?? 0,
                                    currentLabel: label,
                                  )),
                      ],
                    ),
                    SizedBox(height: showBalance ? 14 : 8),
                    // Balance + activity stack on the left, actions pinned to
                    // the BOTTOM RIGHT of the whole block (buttons always
                    // bottom-right, with or without activity).
                    // `CrossAxisAlignment.end` is what does
                    // it: the actions bottom-align against whatever the left
                    // column turns out to be, so they sit level with the
                    // balance on a quiet wallet and drop to the last activity
                    // line on a busy one.
                    //
                    // Deliberately OUTSIDE `if (showBalance)`: a non-EVM linked
                    // wallet has no balance, and gating the whole block on it
                    // also hid that wallet's Edit action.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showBalance)
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _formatLargeBalance(balance),
                                        style: TextStyle(
                                          fontSize: balanceFontSize,
                                          fontWeight: FontWeight.w800,
                                          color: theme.colorScheme.onSurface,
                                          letterSpacing: -0.5,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'OX',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              // Activity under the balance. Draws NOTHING while
                              // loading and NOTHING when the wallet is quiet.
                              ..._activityBelowBalance(address),
                            ],
                          ),
                        ),
                        // There from the first frame: the
                        // buttons no longer wait for the history.
                          const SizedBox(width: 8),
                          _buildWalletActionRow(
                            name: name,
                            address: address,
                            balance: balance,
                            // The icon the card shows (the user's own pick
                            // first), so the manager's key chip matches it.
                            emoji: customIcon ?? emoji,
                            isSmallScreen: isSmallScreen,
                            isGroup: isGroup,
                            isKeychain: isKeychain,
                            isMainSafe: isMainSafe,
                            protocol: protocol,
                            chainId: chainId,
                            walletKey: walletKey,
                            label: label,
                            accountAddress: accountAddress,
                            isLinked: isLinked,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  /// Bottom action bar — varies depending on whether this is the main Safe,
  /// a group wallet, a keychain entry, or an additional directory wallet.
  Widget _buildWalletActionRow({
    required String name,
    required String address,
    required double balance,
    required String? emoji,
    required bool isSmallScreen,
    required bool isGroup,
    required bool isKeychain,
    required bool isMainSafe,
    required String? protocol,
    required int? chainId,
    required Uint8List? walletKey,
    required String label,
    required EthereumAddress? accountAddress,
    bool isLinked = false,
  }) {
    final isAdditional = !isMainSafe && !isGroup && !isKeychain;
    final isEvm = protocol == null || protocol == PublicOSWallets.protoEvm;

    if (isLinked) {
      // Not transactable from here (we may not even hold the key — e.g. a
      // Solana link). The user owns the *link*, so they can rename it; unlink
      // is on the top-right tab button. The address is copyable by tapping
      // it on the card.
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (walletKey != null)
            _WalletActionButton(
              icon: Icons.edit_outlined,
              label: context.l10n.walletEditLabel,
              onTap: () => _showEditLabelSheet(
                walletKey: walletKey,
                chainId: chainId ?? 0,
                currentLabel: label,
              ),
            ),
        ],
      );
    }

    if (isAdditional) {
      // Additional directory wallet — Send (EVM only) + overflow. Copy dropped
      // (the address row already copies on tap).
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEvm)
            _WalletActionButton(
              icon: Icons.arrow_upward_rounded,
              iconBuilder: (c) => SendCoinsIcon(size: 15, color: c),
              label: context.l10n.walletActionSend,
              onTap: () => _showUnifiedSendSheet(
                accountAddress: accountAddress,
                walletAddress: address,
              ),
            ),
          const SizedBox(width: 8),
          _WalletActionButton(
            icon: Icons.more_horiz_rounded,
            label: '',
            onTap: () => _showWalletRowMenu(
              walletKey: walletKey,
              chainId: chainId ?? 0,
              currentLabel: label,
            ),
          ),
        ],
      );
    }

    // Main Safe / group / keychain — Send (coins-arrow glyph) + Manage. Copy
    // was dropped: the address row already copies on tap.
    final sendButton = _WalletActionButton(
      icon: Icons.arrow_upward_rounded,
      iconBuilder: (c) => SendCoinsIcon(size: 15, color: c),
      label: '', // icon-only for every account
      onTap: () => _showUnifiedSendSheet(
        accountAddress: isKeychain ? null : accountAddress,
        walletAddress: address,
      ),
    );
    final manageButton = _buildManageButton(
      wallet: {
        'name': name,
        'address': address,
        'balance': balance,
        'emoji': emoji,
        // The sheet must know whether this device holds the wallet's key:
        // without it every wallet read as watched (and could be signed for
        // with the account's own key).
        'isKeychain': isKeychain,
      },
      isSmallScreen: isSmallScreen,
    );

    // Send + Manage only, shrink-wrapped so they sit at the RIGHT of the
    // balance row. The activity preview has its own line under the balance
    // (`_activityBelowBalance`) — inline, it would make this strip change
    // height as transfers resolve.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        sendButton,
        // No Manage on the account's own MainSafe: the
        // button opens the chosen wallet-manager app (Zerion by default), and
        // no manager website can manage this Safe. It comes back when we have
        // our own screen for it (modules and the rest). Keychain and linked
        // wallets keep theirs.
        if (!isGroup && !isMainSafe) ...[
          const SizedBox(width: 8),
          manageButton,
        ],
      ],
    );
  }

  /// Is this wallet's history being read for the FIRST time on this device,
  /// with nothing to show yet? The one state that reserves the activity
  /// block's height (see [_activityBelowBalance]).
  bool _txLoadingFor(String address) {
    final key = address.toLowerCase();
    return _txFirstFill.contains(key) && _txByAddress[key] == null;
  }

  /// Activity under the balance.
  ///
  /// Returns an EMPTY list — i.e. draws nothing at all — while the transfers
  /// load and when the wallet has never moved. Two deliberate consequences:
  ///
  ///  * no in-card spinner. There is already a loader outside the card and
  ///    spinners on the chips; a third one here would be noise, and because
  ///    it would differ in height from the two preview lines that replace it,
  ///    the card would visibly jump when it resolves;
  ///  * a quiet wallet shows nothing rather than an "Activity" affordance —
  ///    that button led to a history sheet with nothing in it.
  ///
  /// The lines come from the device, so a landing normally
  /// has them (or knows there are none) on its first frame. The exception is
  /// a wallet's first-ever read on this device: its height is RESERVED, two
  /// invisible lines, so the card does not grow when they arrive. A wallet that turns out quiet
  /// gives the space back, that one time.
  List<Widget> _activityBelowBalance(String address) {
    if (_txLoadingFor(address)) {
      final zero =
          EthereumAddress.fromHex('0x0000000000000000000000000000000000000000');
      final blank = TokenTransfer(
        from: zero,
        to: zero,
        rawAmount: BigInt.zero,
        blockNumber: 0,
        timestamp: DateTime.now(),
        txHash: '',
        logIndex: 0,
      );
      return [
        const SizedBox(height: 10),
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _txPreviewLine(blank, address),
              _txPreviewLine(blank, address),
            ],
          ),
        ),
      ];
    }
    final txs = _txByAddress[address.toLowerCase()];
    if (txs == null || txs.isEmpty) return const [];
    return [
      const SizedBox(height: 10),
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showTransactionHistorySheet(address),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final t in txs.take(2)) _txPreviewLine(t, address)],
        ),
      ),
    ];
  }

  /// One compact preview line — direction arrow + amount + relative time. In a
  /// right-aligned FittedBox so it scales down instead of overflowing on a
  /// narrow card.
  Widget _txPreviewLine(TokenTransfer t, String address) {
    final tokens = GlassTokens.of(context);
    final out = t.isOutgoing(EthereumAddress.fromHex(address));
    final accent = out ? const Color(0xFFf87171) : const Color(0xFF34d399);
    final amount = _formatLargeBalance(t.rawAmount.toDouble() / 1e18);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            out ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: accent,
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            txRelativeTime(t.timestamp),
            style: TextStyle(fontSize: 11, color: tokens.textDim),
          ),
        ],
      ),
    );
  }

  void _showTransactionHistorySheet(String address) {
    final key = address.toLowerCase();
    showGlassSheetDialog(
      context: context,
      width: DialogWidth.l,
      builder: (_) => TransactionHistorySheet(
        address: address,
        transfers: _txByAddress[key] ?? const [],
        loading: _txLoading.contains(key),
        counterparties: _cpByWallet,
        pageSize: _txPage,
        // Older pages come from the device, never the chain. The names for
        // the new rows are resolved before the page is handed back (the map
        // above is this view's own, so the sheet sees them).
        onLoadMore: (last) async {
          final addr = EthereumAddress.fromHex(address);
          final page = await PublicOSWallets.getTransferHistory(addr,
              chainId: PublicOS.CHAIN_ID, limit: _txPage, before: last);
          await _resolveCounterparties(addr, page);
          return page;
        },
      ),
    );
  }

  String _protocolBadgeLabel(String protocol, int? chainId) {
    final upper = protocol.toUpperCase();
    if (chainId == null || chainId == 0) return upper;
    return '$upper · $chainId';
  }

  /// Build the manage button for the wallet card action bar
  Widget _buildManageButton({
    required Map<String, dynamic> wallet,
    required bool isSmallScreen,
  }) {
    final app = _selectedWalletManagerApp;

    // Fallback: no wallet manager configured.
    if (app == null || app.url == null || app.url!.isEmpty) {
      return _WalletActionButton(
        icon: Icons.open_in_new_rounded,
        label: context.l10n.walletActionManage,
        onTap: () => showSettingsSheet(),
      );
    }

    // Just the squared app icon — the old banner + owner/app text are gone.
    final iconUrl = app.icon;
    const double size = 30;
    return GestureDetector(
      onTap: () => _showWalletManagerSheet(wallet),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: GlassTokens.of(context).borderSubtle),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: iconUrl != null && iconUrl.isNotEmpty
              ? ZeroCachedImage(
                  imageUrl: iconUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _manageIconFallback(size),
                  errorWidget: (_, __, ___) => _manageIconFallback(size),
                )
              : _manageIconFallback(size),
        ),
      ),
    );
  }

  static Widget _manageIconFallback(double size) => Container(
        width: size,
        height: size,
        color: Colors.white.withValues(alpha: 0.08),
        alignment: Alignment.center,
        child: const Icon(Icons.apps_rounded, size: 15, color: Colors.white70),
      );

  /// Show the wallet manager dApp, pinned to [wallet].
  ///
  /// The client renders the manager in a webview with the managed wallet's
  /// signing key injected, and launching it in the OS browser is not a lesser
  /// version of that — the OS browser has no `window.ethereum`, so the page
  /// could not manage anything at all.
  ///
  /// The webview is pinned by `overrideAccountAddress` + `overrideSigningKey`,
  /// so the dApp talks to THIS wallet rather than the globally web-selected
  /// key. Scope is locked to the app's own origin: a wallet manager has no
  /// business navigating elsewhere while holding a pinned key.
  Future<void> _showWalletManagerSheet(Map<String, dynamic> wallet) async {
    final app = _selectedWalletManagerApp;
    if (app == null || app.url == null || app.url!.isEmpty) return;

    final url = Uri.tryParse(app.url!);
    if (url == null) return;

    final signingKey = await _resolveManagedSigningKey(wallet);
    if (!mounted) return;

    // A keychain wallet is one whose key this device holds. Anything else
    // that reaches the manager (a linked address) is WATCHED: the page may be
    // shown it, nothing here signs for it.
    final watchOnly = wallet['isKeychain'] != true;
    // The dialog's own state: the key chip's tap, the page's chain for the
    // chip's corner mark, and the "can't sign" notice.
    var permissionsRevision = 0;
    String? chainHex;
    var noticeUp = false;
    Timer? noticeTimer;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogCtx) => StatefulBuilder(builder: (dialogCtx, setDialog) {
        final tokens = GlassTokens.of(dialogCtx);
        void setChain(String id) {
          // May arrive while the dialog is still building its child.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (dialogCtx.mounted && chainHex != id) {
              setDialog(() => chainHex = id);
            }
          });
        }

        void showCantSign() {
          if (!dialogCtx.mounted) return;
          noticeTimer?.cancel();
          setDialog(() => noticeUp = true);
          noticeTimer = Timer(const Duration(seconds: 4), () {
            if (dialogCtx.mounted) setDialog(() => noticeUp = false);
          });
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: DialogWidth.w, maxHeight: 760),
              child: Container(
                color: tokens.surfaceDeep,
                child: Column(
                  children: [
                    _walletManagerBar(
                      dialogCtx,
                      tokens,
                      app,
                      wallet,
                      watchOnly: watchOnly,
                      chainHex: chainHex,
                      onKeyTap: () => setDialog(() => permissionsRevision++),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                      child: PublicOSWebView(
                        initialUrl: app.url!,
                        // Its own jar: the wallet dApp never shares cookies
                        // with an app tab of this account. Twin of the client.
                        profileId: WebStorageProfileId.wallet(
                          PublicOS.sessionBlockchainAddress!,
                        ),
                        overrideAccountAddress: wallet['address'] as String?,
                        overrideSigningKey: signingKey,
                        overrideWatchOnly: watchOnly,
                        // The key chip in the bar opens this site's permission
                        // for the ONE pinned key, through the page's own gate
                        // No `grantsRevision`: nothing outside
                        // this dialog changes the pin's permission while it is
                        // open.
                        permissionsRevision: permissionsRevision,
                        onNoSigningKey: showCantSign,
                        onChainRegistryCreated: (r) =>
                            setChain(r.currentChainId),
                        onChainChanged: setChain,
                        // A manager stays on its own site. Origin-level, so its
                        // own internal navigation is unaffected.
                        scope: WebScope.of(url),
                      ),
                          ),
                          // "This wallet can't sign", over the page.
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: IgnorePointer(
                              child: AnimatedOpacity(
                                opacity: noticeUp ? 1 : 0,
                                duration: const Duration(milliseconds: 180),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Color.alphaBlend(
                                          tokens.glassFillHover,
                                          tokens.surfaceElevated),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.visibility_outlined,
                                            size: 16, color: tokens.textDim),
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: Text(
                                            dialogCtx
                                                .l10n.walletWatchOnlyCantSign,
                                            style: TextStyle(
                                              color: tokens.starkWhite,
                                              fontSize: 13,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
    noticeTimer?.cancel();
  }

  /// The header strip above the manager webview: whose wallet, which app, and
  /// a way out. Deliberately states the pinned address — the user is about to
  /// let a page sign with it.
  Widget _walletManagerBar(
    BuildContext ctx,
    GlassTokens tokens,
    dynamic app,
    Map<String, dynamic> wallet, {
    required bool watchOnly,
    required String? chainHex,
    required VoidCallback onKeyTap,
  }) {
    final address = wallet['address'] as String? ?? '';
    final emoji = wallet['emoji'] as String?;
    final chain = chainIdFromHex(chainHex);
    final short = address.length > 12
        ? '${address.substring(0, 6)}...${address.substring(address.length - 4)}'
        : address;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        border: Border(bottom: BorderSide(color: tokens.borderSubtle)),
      ),
      child: Row(
        children: [
          // The key chip: this wallet's emoji with the page's chain on its
          // corner, the mark the browser's own chip carries. A tap opens this
          // site's permission for THIS key and no other.
          InkResponse(
            radius: 22,
            onTap: onKeyTap,
            child: SizedBox(
              width: 30,
              height: 30,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Center(
                      child: watchOnly
                          ? Icon(Icons.visibility_outlined,
                              size: 17, color: tokens.starkWhite)
                          : emoji != null
                              ? Text(emoji,
                                  style:
                                      const TextStyle(fontSize: 17, height: 1))
                              : Icon(Icons.key_outlined,
                                  size: 17, color: tokens.starkWhite),
                    ),
                  ),
                  if (chain != null)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: tokens.surfaceElevated,
                          shape: BoxShape.circle,
                        ),
                        child: NftChainIcon(chain: chain, size: 13),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            app.displayName as String? ?? 'Wallet manager',
            style: TextStyle(
              color: tokens.starkWhite,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            short,
            style: TextStyle(
              color: tokens.textDim,
              fontSize: 11.5,
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: tokens.textDim),
            onPressed: () => Navigator.of(ctx).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  /// Which key signs for the managed wallet.
  ///
  /// A keychain wallet signs with its OWN key, and NOTHING else signs here.
  /// A wallet whose key we do not hold must not fall back to the account's
  /// own key: that produces signatures that do not recover to the address the
  /// page was shown. Null = a watched wallet. Twin of the client's
  /// `_resolveManagedSigningKey`.
  Future<EthPrivateKey?> _resolveManagedSigningKey(
      Map<String, dynamic> wallet) async {
    EthPrivateKey? key;
    try {
      final account =
          AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;
      final isKeychain = wallet['isKeychain'] == true;
      final label = wallet['name'] as String?;
      if (isKeychain && account != null && label != null) {
        final hex = await PublicOSKeychain.exportPrivateKey(account, label);
        if (hex != null) key = EthPrivateKey.fromHex(hex);
      }
    } catch (_) {
      // No key: the wallet is watched, and a signature request says so.
    }
    return key;
  }
}

/// Wallet action button (small, subtle) - phigital style
class _WalletActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Optional custom glyph (e.g. the inline-SVG send mark). Given the button's
  /// resolved foreground colour so it tints to match; overrides [icon].
  final Widget Function(Color color)? iconBuilder;

  const _WalletActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // Mirror the select-account screen's small action buttons: a dim-but-visible
    // foreground (textDim) on a faint glass fill with a subtle border. The old
    // version used colorScheme.onSurfaceVariant, which this theme leaves
    // undefined → it falls back to onSurface (= starkWhite, pure white in dark
    // mode), so the icon/label rendered white on a near-invisible fill with no
    // border: a "white button" with unreadable text.
    final fg = tokens.textDim;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconBuilder != null
                ? iconBuilder!(fg)
                : Icon(icon, size: 14, color: fg),
            if (label.isNotEmpty) const SizedBox(width: 5),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Strokes a dashed rounded-rectangle border. Used to mark display-only
/// "linked" wallet cards as non-interactive.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  static const double _strokeWidth = 1.2;
  static const double _dashLength = 5;
  static const double _gapLength = 4;

  const _DashedBorderPainter({
    required this.color,
    this.radius = 14,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    const inset = _strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - _strokeWidth,
        size.height - _strokeWidth,
      ),
      Radius.circular(radius),
    );

    final source = Path()..addRRect(rrect);
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + _dashLength).clamp(0.0, metric.length);
        dashed.addPath(metric.extractPath(distance, end), Offset.zero);
        distance += _dashLength + _gapLength;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Shows the currently selected wallet manager or a prompt to select one
class _WalletManagerSelector extends StatelessWidget {
  final AppBookmark? selectedApp;
  final Contact? ownerContact;
  final Color cardBg;
  final Color cardBorder;
  final VoidCallback onSelect;

  const _WalletManagerSelector({
    required this.selectedApp,
    required this.ownerContact,
    required this.cardBg,
    required this.cardBorder,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedApp == null) {
      return GestureDetector(
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.apps_rounded,
                  size: 24, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.walletNoManagerSelected,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                context.l10n.walletSelect,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _glassConnectedAccent(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final iconUrl = selectedApp!.icon;
    final ownerName = ownerContact?.displayName ?? context.l10n.walletOwnerUnknown;

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: iconUrl != null && iconUrl.isNotEmpty
                  ? ZeroCachedImage(
                      imageUrl: iconUrl,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 28,
                        height: 28,
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 28,
                        height: 28,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.apps_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : Container(
                      width: 28,
                      height: 28,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.apps_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedApp!.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    ownerName,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              context.l10n.walletChange,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _glassConnectedAccent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row in the wallet manager app picker
class _WalletManagerAppRow extends StatelessWidget {
  final AppBookmark app;
  final bool isSelected;
  final VoidCallback onTap;

  const _WalletManagerAppRow({
    required this.app,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconUrl = app.icon;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: iconUrl != null && iconUrl.isNotEmpty
                  ? ZeroCachedImage(
                      imageUrl: iconUrl,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 32,
                        height: 32,
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 32,
                        height: 32,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.apps_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.apps_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (app.url != null)
                    Text(
                      app.url!,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  size: 20, color: _glassConnectedAccent(context)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Glass token shortcuts — wallet view uses these at many call sites; keeping
// them as top-level helpers instead of threading a `tokens` local through
// every method keeps the port to a minimal-diff cosmetic pass.
// ---------------------------------------------------------------------------

Color _glassConnectedAccent(BuildContext context) =>
    GlassTokens.of(context).connectedAccent;

Color _glassFallbackAccent(BuildContext context) =>
    GlassTokens.of(context).fallbackAccent;

/// Add-wallet modal sheet — protocol picker, label, address, chainId.
/// Returns true via `Navigator.pop(true)` on successful submit.
class _AddWalletSheet extends StatefulWidget {
  const _AddWalletSheet();

  @override
  State<_AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends State<_AddWalletSheet>
    with WidgetsBindingObserver {
  final _labelController = TextEditingController();
  // One proof field — the connect flows fill it; the Link button routes by the
  // bundle's `protocol` (eip155 → ETH, solana → SOL).
  final _pasteController = TextEditingController();
  bool _submitting = false;
  String? _error;

  // Verbose tracing for the connect/link round-trip (launch -> sign -> resume
  // -> clipboard -> submit -> addWallet). Filter `flutter run` / logcat on
  // "mm-link".
  void _mmLog(String msg) => debugPrint('[mm-link] $msg');

  bool get _canSubmit =>
      !_submitting &&
      _labelController.text.trim().isNotEmpty &&
      _pasteController.text.trim().isNotEmpty;

  /// The chain implied by the current proof bundle (its `protocol` field), or
  /// null if the field is empty / unparseable. Drives the "detected" chip and
  /// the Link routing.
  String? _detectedChain() {
    final raw = _pasteController.text.trim();
    if (raw.isEmpty) return null;
    try {
      final obj = jsonDecode(raw);
      if (obj is Map) {
        final p = obj['protocol'];
        if (p == PublicOSWallets.protoSolana) return PublicOSWallets.protoSolana;
        if (p == PublicOSWallets.protoEvm) return PublicOSWallets.protoEvm;
      }
    } catch (_) {}
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// On return from a connect flow (MetaMask / Phantom / browser) the signing
  /// page has copied its proof bundle to the clipboard. Fill the (empty) proof
  /// field so linking "comes back filled in" — we never auto-submit, so the
  /// required label is always entered by hand before Link.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_pasteController.text.trim().isEmpty) {
      _tryAutofillProofFromClipboard();
    }
  }

  Future<void> _tryAutofillProofFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final txt = data?.text?.trim();
      if (txt == null || txt.isEmpty) return;
      final obj = jsonDecode(txt);
      // Accept either chain's bundle — the Link button routes by `protocol`.
      if (obj is Map &&
          (obj['protocol'] == PublicOSWallets.protoSolana ||
              obj['protocol'] == PublicOSWallets.protoEvm) &&
          obj['signature'] != null) {
        if (!mounted) return;
        setState(() => _pasteController.text = txt);
      }
    } catch (_) {
      // Clipboard held something that wasn't a proof bundle — ignore.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _labelController.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  /// Build + submit the verified EVM link. The signature is an INPUT here, so
  /// this same path serves both transports: the in-app keychain (signs locally,
  /// in [_submit]) and a future "paste a signature from an external wallet" flow
  /// — that flow would show `PublicOSWallets.linkWalletDigest(...)` for the user
  /// to sign elsewhere, then hand the resulting 65-byte sig straight to here.
  Future<String?> _linkEvm({
    required EthereumAddress walletAddress,
    required Uint8List signature,
    required BigInt deadline,
    required String label,
  }) {
    _mmLog('_linkEvm: addWallet protoEvm addr=${walletAddress.eip55With0x} '
        'chainId=0 type=eoa sigBytes=${signature.length} deadline=$deadline '
        'label="$label"');
    final wallet = Wallet(
      protocol: PublicOSWallets.protoEvm,
      addressData: walletAddress.value,
      chainId: 0, // EOA → chain-agnostic
      label: label,
      walletType: WalletType.eoa,
      proof: signature,
      verification: Verification.onchainVerified, // contract overrides; UI hint
    );
    return PublicOSWallets.addWallet(wallet, deadline: deadline);
  }

  /// Route by the proof bundle's `protocol`: `solana` → [_submitSolana],
  /// `eip155` → [_submitEvmExternal]. Both read the label from the required
  /// field (the Link button gates on label + proof being present).
  Future<void> _submit() async {
    final raw = _pasteController.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = context.l10n.walletPasteProofError);
      return;
    }
    Map bundle;
    try {
      bundle = jsonDecode(raw) as Map;
    } catch (_) {
      setState(() => _error = context.l10n.walletInvalidProofError);
      return;
    }
    final proto = (bundle['protocol'] as String?)?.trim();
    if (proto == PublicOSWallets.protoSolana) {
      await _submitSolana();
    } else if (proto == PublicOSWallets.protoEvm) {
      await _submitEvmExternal(bundle);
    } else {
      setState(() => _error = context.l10n.walletInvalidProofError);
    }
  }

  /// Solana add flow: parse the pasted "proof for PublicOS" bundle, verify the
  /// ed25519 link proof against THIS account (the client respects the binding
  /// even though the chain stores it CLAIMED unverified), then push to chain.
  Future<void> _submitSolana() async {
    final account = AppStateNotifier.currentMyContact?.publicosAddress;
    if (account == null) {
      setState(() => _error = context.l10n.walletNoActiveAccount);
      return;
    }
    final raw = _pasteController.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = context.l10n.walletPasteProofError);
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      Map<String, dynamic> bundle;
      try {
        bundle = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        setState(() {
          _error = context.l10n.walletInvalidProofError;
          _submitting = false;
        });
        return;
      }
      final pubkeyB58 = (bundle['pubkey'] as String?)?.trim() ?? '';
      final sigB58 = (bundle['signature'] as String?)?.trim() ?? '';
      final bundleAccount = (bundle['account'] as String?)?.trim() ?? '';
      if (pubkeyB58.isEmpty || sigB58.isEmpty) {
        setState(() {
          _error = context.l10n.walletProofMissingWalletSig;
          _submitting = false;
        });
        return;
      }
      // Friendly account-match guard (verifySolanaWalletLink is the real boundary).
      if (bundleAccount.isNotEmpty &&
          bundleAccount.toLowerCase() != account.eip55With0x.toLowerCase()) {
        setState(() {
          _error = context.l10n.walletProofWrongAccount;
          _submitting = false;
        });
        return;
      }
      Uint8List proof;
      try {
        proof = PublicOSWallets.base58Decode(sigB58);
      } catch (_) {
        setState(() {
          _error = context.l10n.walletProofBadBase58;
          _submitting = false;
        });
        return;
      }
      // Non-EVM convention: addressData = UTF-8 of the base58 display address.
      final wallet = Wallet(
        protocol: PublicOSWallets.protoSolana,
        addressData: Uint8List.fromList(utf8.encode(pubkeyB58)),
        chainId: 0,
        label: _labelController.text.trim(),
        walletType: WalletType.none,
        proof: proof,
        verification: Verification.claimed, // contract sets it; UI hint
      );
      // Verify before submit — reject a proof that doesn't bind this account.
      if (!PublicOSWallets.verifySolanaWalletLink(
          account: account, wallet: wallet)) {
        setState(() {
          _error = context.l10n.walletProofVerifyFailed;
          _submitting = false;
        });
        return;
      }
      final deadline = BigInt.from(
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600);
      final txHash = await PublicOSWallets.addWallet(wallet, deadline: deadline);
      if (!mounted) return;
      if (txHash == null) {
        final l10n = context.l10n;
        setState(() {
          _error = localizedError(l10n, PublicOS.lastError,
              fallback: l10n.errAddWalletFailed);
          _submitting = false;
        });
        return;
      }
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.walletSolanaLinked)),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      setState(() {
        _error = localizedError(l10n, e, fallback: l10n.errAddWalletFailed);
        _submitting = false;
      });
    }
  }

  /// Submit an external-wallet EVM proof bundle (from MetaMask / the signing
  /// page) straight through the verified [_linkEvm] seam. The signature is
  /// secp256k1, so the contract re-verifies it on-chain (ecrecover) and stores
  /// ONCHAIN_VERIFIED — no client-side proof check is needed (unlike Solana).
  Future<void> _submitEvmExternal(Map bundle) async {
    _mmLog('_submitEvmExternal: enter');
    final account = AppStateNotifier.currentMyContact?.publicosAddress;
    if (account == null) {
      _mmLog('_submitEvmExternal: ABORT no active account');
      return;
    }
    final addrStr = (bundle['walletAddress'] as String?)?.trim() ?? '';
    final sigStr = (bundle['signature'] as String?)?.trim() ?? '';
    final deadlineStr = (bundle['deadline'] as String?)?.trim() ?? '';
    _mmLog('_submitEvmExternal: walletAddress=$addrStr deadline=$deadlineStr '
        'sigStrLen=${sigStr.length}');
    if (addrStr.isEmpty || sigStr.isEmpty || deadlineStr.isEmpty) {
      _mmLog('_submitEvmExternal: ABORT missing field '
          '(addr=${addrStr.isNotEmpty} sig=${sigStr.isNotEmpty} '
          'deadline=${deadlineStr.isNotEmpty})');
      setState(() =>
          _error = context.l10n.walletProofMissingFields);
      return;
    }
    final EthereumAddress walletAddress;
    final BigInt deadline;
    final Uint8List signature;
    try {
      walletAddress = EthereumAddress.fromHex(addrStr);
      deadline = BigInt.parse(deadlineStr);
      signature = _hexToBytes(sigStr);
      _mmLog('_submitEvmExternal: parsed ok addr=${walletAddress.eip55With0x} '
          'sigBytes=${signature.length} deadline=$deadline');
    } catch (e) {
      _mmLog('_submitEvmExternal: ABORT parse failed: $e');
      setState(() => _error = context.l10n.walletProofMalformed);
      return;
    }
    if (signature.length != 65) {
      _mmLog('_submitEvmExternal: WARN signature is ${signature.length} bytes, '
          'expected 65 (r||s||v); on-chain ecrecover will likely revert');
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      _mmLog('_submitEvmExternal: calling _linkEvm -> addWallet (this is a tx)');
      final txHash = await _linkEvm(
        walletAddress: walletAddress,
        signature: signature,
        deadline: deadline,
        label: _labelController.text.trim(),
      );
      _mmLog('_submitEvmExternal: _linkEvm returned txHash=$txHash');
      if (!mounted) return;
      if (txHash == null) {
        _mmLog('_submitEvmExternal: FAILED, PublicOS.lastError='
            '${PublicOS.lastError}');
        final l10n = context.l10n;
        setState(() {
          _error = localizedError(l10n, PublicOS.lastError,
              fallback: l10n.errAddWalletFailed);
          _submitting = false;
        });
        return;
      }
      _mmLog('_submitEvmExternal: SUCCESS wallet linked tx=$txHash');
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.walletLinked)),
      );
    } catch (e, st) {
      _mmLog('_submitEvmExternal: EXCEPTION $e');
      _mmLog('_submitEvmExternal: $st');
      if (!mounted) return;
      final l10n = context.l10n;
      setState(() {
        _error = localizedError(l10n, e, fallback: l10n.errAddWalletFailed);
        _submitting = false;
      });
    }
  }

  /// 0x-hex (or bare hex) → bytes; decodes an EVM signature from the bundle.
  Uint8List _hexToBytes(String hex) {
    final clean = hex.startsWith('0x') ? hex.substring(2) : hex;
    final out = Uint8List(clean.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final account = AppStateNotifier.currentMyContact?.publicosAddress;
    final detected = _detectedChain();
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.walletLinkWalletTitle,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.walletLinkExplainer,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                // Connect — each button runs its flow and auto-fills the proof.
                Text(context.l10n.walletConnectHeader, style: _labelStyle(tokens)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _connectTile(
                        tokens,
                        glyph: const Text('🦊', style: TextStyle(fontSize: 16)),
                        glyphBg: const Color(0xFFF6851B),
                        name: 'MetaMask',
                        onTap:
                            account == null ? null : () => _openMetaMask(account),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _connectTile(
                        tokens,
                        glyph: SvgPicture.string(_phantomGhostSvg,
                            width: 16, height: 16),
                        glyphBg: const Color(0xFFAB9FF2),
                        name: 'Phantom',
                        onTap:
                            account == null ? null : () => _openPhantom(account),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _connectTile(
                        tokens,
                        glyph: ChainIcon(
                            protocol: PublicOSWallets.protoEvm, size: 16),
                        glyphBg: tokens.glassFill,
                        name: chainDisplayName(PublicOSWallets.protoEvm),
                        sub: context.l10n.walletSignOnBrowser,
                        onTap: account == null
                            ? null
                            : () => _openLinkingPage(account, evm: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _connectTile(
                        tokens,
                        glyph: ChainIcon(
                            protocol: PublicOSWallets.protoSolana, size: 16),
                        glyphBg: tokens.glassFill,
                        name: chainDisplayName(PublicOSWallets.protoSolana),
                        sub: context.l10n.walletSignOnBrowser,
                        onTap: account == null
                            ? null
                            : () => _openLinkingPage(account),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _orDivider(tokens),
                const SizedBox(height: 18),
                // Label — required (the Link button gates on it + the proof).
                Text(context.l10n.walletLabelRequired, style: _labelStyle(tokens)),
                const SizedBox(height: 6),
                TextField(
                  controller: _labelController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: context.l10n.walletLabelExampleHint,
                    hintStyle: TextStyle(color: tokens.textDim),
                  ),
                ),
                const SizedBox(height: 18),
                // Proof — one field; auto-detects ETH (0x-hex bundle) vs SOL.
                Row(
                  children: [
                    Text(context.l10n.walletPasteProofLabel,
                        style: _labelStyle(tokens)),
                    const Spacer(),
                    if (detected != null) _detectedChip(tokens, detected),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _pasteController,
                  minLines: 2,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: InputDecoration(
                    hintText: context.l10n.walletPasteProofBundleHint,
                    hintStyle: TextStyle(color: tokens.textDim),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),
                // Canonical action button (auto dashed-disabled until label +
                // proof are present; "LINKING…" mid-flight).
                SystemAppActionButton(
                  label: _submitting
                      ? context.l10n.walletLinkingAction
                      : context.l10n.walletLinkWalletAction,
                  icon: Icons.link_rounded,
                  onTap: _canSubmit ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle(GlassTokens tokens) => TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: tokens.starkWhite,
      );

  /// A compact "connect a wallet" tile (icon + name, optional sub) for the
  /// sheet's 2×2 grid. Tapping runs the connect flow, which auto-fills the proof
  /// field on return.
  Widget _connectTile(
    GlassTokens tokens, {
    required Widget glyph,
    required Color glyphBg,
    required String name,
    String? sub,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
          decoration: BoxDecoration(
            color: tokens.glassFill,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: glyphBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: glyph,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tokens.starkWhite,
                      ),
                    ),
                    if (sub != null)
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10.5, color: tokens.textDim),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The "<chain> detected" chip beside the proof field once a bundle is
  /// present. Green for Solana, connected-accent for Ethereum.
  Widget _detectedChip(GlassTokens tokens, String proto) {
    final isSol = proto == PublicOSWallets.protoSolana;
    final color = isSol ? const Color(0xFF34D399) : tokens.connectedAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChainIcon(protocol: proto, size: 13),
          const SizedBox(width: 6),
          Text(
            context.l10n.walletChainDetected(chainDisplayName(proto)),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _orDivider(GlassTokens tokens) {
    return Row(
      children: [
        Expanded(child: Divider(color: tokens.borderSubtle, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            context.l10n.walletOr,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 12,
              color: tokens.textDim,
            ),
          ),
        ),
        Expanded(child: Divider(color: tokens.borderSubtle, height: 1)),
      ],
    );
  }

  /// Primary mobile path: open the signing page inside Phantom's in-app browser
  /// (its provider is injected there) with the account pre-filled and a
  /// `return=app` flag. After the user signs, the page copies the proof and
  /// bounces `publicos://wallet-link-return` to foreground us;
  /// [_tryAutofillProofFromClipboard] then fills the paste field. No native
  /// wallet SDK or crypto handshake needed.
  Future<void> _openPhantom(EthereumAddress account) async {
    final page =
        'https://publicos.dev/Link_solana_wallet?account=${account.eip55With0x}&return=app';
    final phantom = Uri.parse(
        'https://phantom.app/ul/browse/${Uri.encodeComponent(page)}'
        '?ref=${Uri.encodeComponent('https://publicos.dev')}');
    if (await canLaunchUrl(phantom)) {
      await launchUrl(phantom, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.l10n.walletCouldNotOpenPhantom)),
      );
    }
  }

  /// Secondary path: open the signing page in the device browser. The Android
  /// App Link is path-scoped (see AndroidManifest) so `/Link_solana_wallet` is
  /// not captured by the app and lands in the browser; on iOS a same-app
  /// universal link opens in Safari anyway. `return=app` lets the proof come
  /// back via the clipboard the same way as the Phantom path.
  Future<void> _openLinkingPage(EthereumAddress account, {bool evm = false}) async {
    _mmLog('_openLinkingPage: enter evm=$evm account=${account.eip55With0x}');
    final Uri uri;
    if (evm) {
      final wdm = PublicOSBsp.walletDirectoryManagerAddress;
      if (wdm == null) {
        _mmLog('_openLinkingPage: ABORT walletDirectoryManagerAddress is null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.walletDirectoryNotReady)),
          );
        }
        return;
      }
      final deadline = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
      uri = Uri.parse(
          'https://publicos.dev/Link_ethereum_wallet?account=${account.eip55With0x}'
          '&wdm=${wdm.eip55With0x}&deadline=$deadline&return=app&debug=1');
      _mmLog('_openLinkingPage: EVM wdm=${wdm.eip55With0x} deadline=$deadline');
    } else {
      uri = Uri.parse(
          'https://publicos.dev/Link_solana_wallet?account=${account.eip55With0x}&return=app');
    }
    final can = await canLaunchUrl(uri);
    _mmLog('_openLinkingPage: uri=$uri canLaunchUrl=$can');
    if (can) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _mmLog('_openLinkingPage: launchUrl returned');
    } else if (mounted) {
      _mmLog('_openLinkingPage: launch FAILED');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.walletCouldNotOpenLinkingPage)),
      );
    }
  }

  /// Primary mobile path: open the signing page inside MetaMask's in-app browser
  /// (its window.ethereum provider is injected there) with the account, the live
  /// WalletDirectoryManager address, and a deadline pre-filled, plus return=app.
  /// After the user signs, the page copies the proof and bounces
  /// `publicos://wallet-link-return`; [_tryConsumeEvmReturn] then submits it. The
  /// dapp URL is passed SCHEME-STRIPPED, per MetaMask's deeplink convention.
  Future<void> _openMetaMask(EthereumAddress account) async {
    _mmLog('_openMetaMask: enter account=${account.eip55With0x}');
    final wdm = PublicOSBsp.walletDirectoryManagerAddress;
    if (wdm == null) {
      _mmLog('_openMetaMask: ABORT walletDirectoryManagerAddress is null '
          '(BSP resolver not ready)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.walletDirectoryNotReady)),
        );
      }
      return;
    }
    final deadline = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
    // No scheme on the dapp segment — MetaMask strips it (origin.slice(8)).
    // &debug=1 turns on the in-page debug log on the signing page (no devtools
    // in MetaMask's in-app browser); strip it before public launch.
    final path = 'publicos.dev/Link_ethereum_wallet'
        '?account=${account.eip55With0x}'
        '&wdm=${wdm.eip55With0x}'
        '&deadline=$deadline&return=app&debug=1';
    final mm = Uri.parse('https://link.metamask.io/dapp/$path');
    _mmLog('_openMetaMask: wdm=${wdm.eip55With0x} deadline=$deadline');
    _mmLog('_openMetaMask: deeplink=$mm');
    final can = await canLaunchUrl(mm);
    _mmLog('_openMetaMask: canLaunchUrl=$can');
    if (can) {
      await launchUrl(mm, mode: LaunchMode.externalApplication);
      _mmLog('_openMetaMask: launchUrl returned (MetaMask should be foreground)');
    } else if (mounted) {
      _mmLog('_openMetaMask: launch FAILED; MetaMask not installed?');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.walletCouldNotOpenMetaMask)),
      );
    }
  }

  // Phantom ghost mark (dark fill, for their light-purple button). If it looks
  // off, swap in the official Phantom asset.
  static const _phantomGhostSvg =
      '<svg viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">'
      '<path fill-rule="evenodd" clip-rule="evenodd" '
      'd="M110.584 64.9142H99.142C99.142 41.7651 80.173 23 56.7724 23C33.6612 23 14.8688 41.3057 14.4147 64.0583C13.9446 87.5807 36.0469 108 59.8225 108H62.8138C83.7355 108 111.797 91.7163 116.181 71.8331C116.99 68.1657 114.321 64.9142 110.584 64.9142ZM39.7505 65.9952C39.7505 69.0581 37.2349 71.5727 34.1709 71.5727C31.1069 71.5727 28.5913 69.0581 28.5913 65.9952V56.8541C28.5913 53.7911 31.1069 51.2765 34.1709 51.2765C37.2349 51.2765 39.7505 53.7911 39.7505 56.8541V65.9952ZM58.1255 65.9952C58.1255 69.0581 55.6099 71.5727 52.5459 71.5727C49.4819 71.5727 46.9663 69.0581 46.9663 65.9952V56.8541C46.9663 53.7911 49.4819 51.2765 52.5459 51.2765C55.6099 51.2765 58.1255 53.7911 58.1255 56.8541V65.9952Z" '
      'fill="#2A2440"/></svg>';

}
