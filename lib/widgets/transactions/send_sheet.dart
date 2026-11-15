import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart' show Web3Client;
import 'package:publicos_desktop/widgets/chain_icon.dart';
import 'package:publicos_desktop/widgets/crypto_icon.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/grid_settings_sheet.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/data/chain_registry.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:wallet/wallet.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/widgets/transactions/wallet_sources.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';

enum SendStep { selectActor, search, amount }

/// How step 1 resolves the recipient.
///  - [fixed]: one known recipient (the lone candidate) → skip straight to amount.
///  - [pickFrom]: choose among [SendSheetConfig.candidates]; a single distinct
///    candidate skips. Used by tipping (post actors) and group chat sends.
///  - [searchAny]: search any contact / raw address. Used by the wallet.
enum SendTargetMode { fixed, pickFrom, searchAny }

/// The role a candidate plays — tipping labels these ("Author" / "Found via" /
/// "Channel owner"); chat and wallet leave it null.
enum SendRole { author, foundVia, channelOwner }

/// One candidate recipient. The same address can arrive under several [role]s
/// (tipping) — the sheet dedups by address and merges roles. [contact] is the
/// pre-resolved profile when known; null falls back to an address identicon.
class SendCandidate {
  final SendRole? role;
  final EthereumAddress address;
  final Contact? contact;
  const SendCandidate({this.role, required this.address, this.contact});
}

/// A deduped actor — one distinct address, the roles it plays, its contact.
class _SendActor {
  final EthereumAddress address;
  Contact? contact;
  final List<SendRole> roles;
  _SendActor({required this.address, this.contact, required this.roles});
}

/// Handed to [SendSheetConfig.onSent] after a real, immediate transfer
/// (keychain or personal-Safe — NOT an org governance vote). Carries the chain
/// + token so the chat receipt is correct for any token, not just OX.
class SentTxInfo {
  final String txHash;
  final String fromAddress;
  final String toAddress;
  final String amount; // human-entered string
  final int chainId;
  final String tokenSymbol;
  final int decimals;
  const SentTxInfo({
    required this.txHash,
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required this.chainId,
    required this.tokenSymbol,
    required this.decimals,
  });
}

typedef OxSentCallback = Future<void> Function(SentTxInfo info);

/// Drives the one send sheet for all three callers (wallet · post tip · chat).
/// Each passes exactly what it has; unused fields default away.
class SendSheetConfig {
  final SendTargetMode targetMode;
  final List<SendCandidate> candidates; // fixed / pickFrom
  /// Header title override (null → "Send OX").
  final String? title;
  /// Confirm-button label override (null → "Send <symbol>").
  final String? confirmLabel;
  /// Confirm-button icon override (tipping passes the 🙏 icon).
  final IconData? confirmIcon;
  /// Post-send hook (chat receipt). Null for tipping / wallet.
  final OxSentCallback? onSent;
  /// Chat reply-to-request: the requested raw amount → restaurant-style tip
  /// chips. Empty [tipChips] = no chips.
  final BigInt? requestedAmount;
  final List<double> tipChips;
  /// Pre-selected chain + token (request-pay, feed tip preference). Null → OX.
  /// [defaultToken] may be a token NOT in [defaultChain]'s list (a custom token
  /// resolved on-chain for a request).
  final ChainDef? defaultChain;
  final TokenDef? defaultToken;
  /// Pay this EXACT recipient wallet (request-pay) — skip target re-resolution;
  /// the [candidates] entry then provides display identity only.
  final String? exactTargetAddress;
  /// Hide the chain/token picker (read-only) — request-pay locks to the
  /// request's chain + token.
  final bool lockChainToken;
  /// searchAny origin seed (wallet).
  final EthereumAddress? feedFoundAtAccountAddress;
  final String? originatingWalletAddress;

  const SendSheetConfig({
    this.targetMode = SendTargetMode.searchAny,
    this.candidates = const [],
    this.title,
    this.confirmLabel,
    this.confirmIcon,
    this.onSent,
    this.requestedAmount,
    this.tipChips = const [],
    this.defaultChain,
    this.defaultToken,
    this.exactTargetAddress,
    this.lockChainToken = false,
    this.feedFoundAtAccountAddress,
    this.originatingWalletAddress,
  });
}

/// Shows the send sheet with the glass chrome (transparent backdrop +
/// `tokens.surfaceDeep` shell).
///
/// DELTA (desktop): the client presents this as a full-height bottom sheet;
/// desktop shows the SAME [SendSheet] in a centered glass dialog (the
/// sheets → dialogs rule). Same signature, so every caller — `post_card`'s
/// tip button included — stays verbatim.
Future<void> showSendSheet({
  required BuildContext context,
  required SendSheetConfig config,
}) {
  return showGlassSheetDialog<void>(
    context: context,
    width: DialogWidth.m,
    builder: (_) => SendSheet(config: config),
  );
}

class SendSheet extends StatefulWidget {
  final SendSheetConfig config;
  const SendSheet({super.key, required this.config});

  @override
  State<SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<SendSheet> with TickerProviderStateMixin {
  late SendStep _currentStep;
  Contact? _selectedContact;

  // Deduped candidate actors (pickFrom / fixed). The chosen one is resolved to
  // `_selectedContact` (the shared downstream representation).
  List<_SendActor> _actors = [];
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  Contact? _searchResult;
  /// True when `_searchResult` is a NON-persisted stub built from a typed
  /// address that matched no known contact — selecting it sends to that exact
  /// address with no Safe resolution. See `_buildRawAddressStub`.
  bool _searchResultIsRawAddress = false;
  bool _isSearching = false;
  String _query = '';
  int _resolveGeneration = 0;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isLoadingContacts = true;
  bool _isSending = false;
  String? _errorText;
  int _gridSize = kDefaultGridSize;
  TextSizeOption _textSize = kDefaultTextSize;

  // Multi-chain: selected chain + token. Defaults to OX/4489 everywhere. The
  // picker is shown only for keychain (EOA) origin wallets — a Safe can't
  // transact off-chain, so Safe/group origins pin to OX (see _setSelectedWallet
  // and the wallet-select onTap). For non-OX tokens, the SENDING FROM balance,
  // the cap check, and presets use _tokenBalance (a balanceOf read on the
  // selected token); OX keeps the existing PublicOS-balance path.
  ChainDef _selectedChain = kOxChain;
  TokenDef _selectedToken = kOxChain.defaultToken;
  double? _tokenBalance; // selected non-OX token balance for the origin wallet
  bool _isLoadingTokenBalance = false;
  int _tokenBalanceGen = 0; // race guard for async balanceOf reads

  /// Selected tip chip (request-pay): null = none / user typed a custom amount.
  int? _selectedChipIndex;

  // Originating wallet selection
  String? _selectedWalletName;
  String? _selectedWalletAddress;
  List<Map<String, dynamic>> _allWallets = [];
  bool _isLoadingWallets = true;
  bool _isWalletSelectorExpanded = false;

  // Target wallet selection
  /// When true, the chosen target is a raw typed address (a `_searchResult`
  /// stub) — `_loadTargetWallets` short-circuits to that exact address instead
  /// of resolving the contact's main Safe.
  bool _targetIsRawAddress = false;
  String? _selectedTargetWalletName;
  String? _selectedTargetWalletAddress;

  // Exact-target callers (request-pay, tip cards): who owns the wallet being
  // paid, looked up MainSafe first, then linked wallets (never session
  // keys). `_exactOwnerChecked` stays false while the lookup runs and after
  // it failed; off 4489 Send waits for it.
  bool _exactOwnerChecked = false;
  bool _exactTargetIsMainSafe = false;
  String? _exactOwnerName; // null = the address belongs to no account
  EthereumAddress? _exactOwnerAccount;
  String? _exactWalletLabel; // the directory label, for a linked wallet
  List<Map<String, dynamic>> _allTargetWallets = [];
  bool _isLoadingTargetWallets = false;
  bool _isTargetWalletSelectorExpanded = false;

  // Animation
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Pre-selected chain/token from the caller (request-pay / feed tip pref);
    // both default to OX. A request can pass a token NOT in the chain's list.
    if (widget.config.defaultChain != null) {
      _selectedChain = widget.config.defaultChain!;
    }
    if (widget.config.defaultToken != null) {
      _selectedToken = widget.config.defaultToken!;
    }

    // Resolve step 1 from the target mode.
    _actors = _dedupCandidates(widget.config.candidates);
    final mode = widget.config.targetMode;
    if (mode == SendTargetMode.fixed ||
        (mode == SendTargetMode.pickFrom && _actors.length == 1)) {
      // A single known recipient → skip selection, open on the amount step.
      if (_actors.isNotEmpty) _selectActorInternal(_actors.first);
      _currentStep = SendStep.amount;
      _animationController.value = 1.0;
    } else if (mode == SendTargetMode.pickFrom) {
      _currentStep = SendStep.selectActor;
    } else {
      _currentStep = SendStep.search;
    }

    // Chat reply-to-request: prefill the requested amount (the "Requested" chip).
    final req = widget.config.requestedAmount;
    if (req != null) {
      _amountController.text =
          PublicOSWallets.formatTokenAmount(req, _selectedToken.decimals);
      if (widget.config.tipChips.isNotEmpty) _selectedChipIndex = 0;
    }

    _seedPlaceholderFromPointer();
    _loadWallets();
    if (mode == SendTargetMode.searchAny) _loadContacts();
    _loadSettings();
    if (widget.config.exactTargetAddress != null) {
      // Request-pay: pay the EXACT recipient wallet — no re-resolution. The
      // candidate supplies only the SENDING TO display identity.
      _selectedTargetWalletAddress = widget.config.exactTargetAddress;
      _selectedTargetWalletName = null;
      _allTargetWallets = [];
      _isLoadingTargetWallets = false;
      _resolveExactTargetOwner();
    } else if (_selectedContact != null) {
      _loadTargetWallets();
    }
    _searchController.addListener(_onSearchChanged);
  }

  /// Whose wallet is [SendSheetConfig.exactTargetAddress]? The same two lanes,
  /// in the same order, as the wallet-activity sweep's name lookup: someone's
  /// MainSafe (`getSafeOwnerAccount`), else a wallet in someone's directory
  /// (`getOwnerByAddress`). Both answer the zero address for "nobody" and
  /// null when the call failed.
  ///
  /// The MainSafe answer is also the lost-funds guard for this path: with an
  /// exact target `_allTargetWallets` is empty, so `_targetIsMainSafe` reads
  /// this instead.
  Future<void> _resolveExactTargetOwner() async {
    final target = EthereumAddress.fromHex(widget.config.exactTargetAddress!);
    bool isZero(EthereumAddress a) => a.value.every((b) => b == 0);
    try {
      final safeOwner = await PublicOSSafe.getSafeOwnerAccount(target);
      if (safeOwner == null) return; // failed: stays unchecked
      EthereumAddress? owner;
      var isSafe = false;
      if (!isZero(safeOwner)) {
        owner = safeOwner;
        isSafe = true;
      } else {
        final linked = await PublicOSWallets.getOwnerByAddress(
          protocol: PublicOSWallets.protoEvm,
          addressData: Uint8List.fromList(target.value),
        );
        if (linked == null) return;
        if (!isZero(linked)) owner = linked;
      }
      String? name;
      String? walletLabel;
      if (owner != null && !isSafe) {
        for (final w in await PublicOSWallets.getWallets(owner)) {
          if (listEquals(w.addressData, target.value) && w.label.isNotEmpty) {
            walletLabel = w.label;
          }
        }
      }
      if (owner != null) {
        final contact = await PublicOSContacts.fetchContact(owner);
        final shown = contact.displayName.trim();
        name = shown.isNotEmpty ? shown : _formatAddress(owner.eip55With0x);
      }
      if (!mounted) return;
      setState(() {
        _exactTargetIsMainSafe = isSafe;
        _exactOwnerName = name;
        _exactOwnerAccount = owner;
        _exactWalletLabel = walletLabel;
        _exactOwnerChecked = true;
      });
    } catch (_) {
      // Unchecked: the label stays off, and Send off 4489 stays disabled.
    }
  }

  /// The wallet label next to the address under SENDING TO, for an exact
  /// target. When the owner IS the recipient named above it, only the wallet
  /// is named ("main", or the linked wallet's own label), as SENDING FROM
  /// does; otherwise the owner is named too, since the name above is only
  /// who asked.
  String? _exactOwnerLabel(BuildContext context) {
    if (widget.config.exactTargetAddress == null || !_exactOwnerChecked) {
      return null;
    }
    final l10n = context.l10n;
    final name = _exactOwnerName;
    final owner = _exactOwnerAccount;
    if (name == null || owner == null) {
      return l10n.tipCardOwnerUnknown(_selectedContact?.displayName ?? '');
    }
    if (_selectedContact?.publicosAddress == owner) {
      return _exactTargetIsMainSafe
          ? 'main'
          : (_exactWalletLabel ?? l10n.tipCardOwnerWallet(name));
    }
    return _exactTargetIsMainSafe
        ? l10n.tipCardOwnerMainSafe(name)
        : l10n.tipCardOwnerWallet(name);
  }

  /// Set the chosen recipient from a candidate actor — resolves to a [Contact]
  /// (the actor's own, or a stub from its address) so the shared target/send
  /// path works unchanged.
  void _selectActorInternal(_SendActor actor) {
    _selectedContact = actor.contact ??
        Contact(
          displayName: _formatAddress(actor.address.eip55With0x),
          publicosAddress: actor.address,
        );
  }

  /// User tapped a candidate in the pickFrom list → go to the amount step.
  void _selectActor(_SendActor actor) {
    setState(() {
      _selectActorInternal(actor);
      _currentStep = SendStep.amount;
    });
    _animationController.forward();
    _loadTargetWallets();
  }

  /// Group candidates by lowercased address, merging roles and preferring the
  /// first non-null contact. Insertion order preserved. (Ported from tip_sheet.)
  List<_SendActor> _dedupCandidates(List<SendCandidate> candidates) {
    final byAddr = <String, _SendActor>{};
    final order = <String>[];
    for (final c in candidates) {
      final key = c.address.eip55With0x.toLowerCase();
      final existing = byAddr[key];
      if (existing == null) {
        byAddr[key] = _SendActor(
          address: c.address,
          contact: c.contact,
          roles: [if (c.role != null) c.role!],
        );
        order.add(key);
      } else {
        if (c.role != null && !existing.roles.contains(c.role)) {
          existing.roles.add(c.role!);
        }
        existing.contact ??= c.contact;
      }
    }
    return order.map((k) => byAddr[k]!).toList();
  }

  String _roleLabel(SendRole role) {
    switch (role) {
      case SendRole.author:
        return context.l10n.tipSheetActorAuthor;
      case SendRole.foundVia:
        return context.l10n.tipSheetActorFoundVia;
      case SendRole.channelOwner:
        return context.l10n.tipSheetActorChannelOwner;
    }
  }

  String _rolesLabel(List<SendRole> roles) => roles.map(_roleLabel).join(' · ');

  String _actorDisplayName(_SendActor actor) =>
      actor.contact?.displayName ?? _formatAddress(actor.address.eip55With0x);

  /// True when there's no step-1 to go back to (fixed, or a single pickFrom
  /// candidate) — the header back arrow is hidden in that case.
  bool get _skipsTargetSelection {
    final mode = widget.config.targetMode;
    return mode == SendTargetMode.fixed ||
        (mode == SendTargetMode.pickFrom && _actors.length == 1);
  }

  /// If the caller handed us an `originatingWalletAddress`, seed `_allWallets`
  /// synchronously so the SENDING FROM card renders on the very first frame.
  ///
  /// When the caller also told us the owning account
  /// (`feedFoundAtAccountAddress`) and it's the signed-in user, we resolve
  /// identity (avatar + name) up front instead of waiting on the directory
  /// sweep — only the balance shimmers. This is the "parse the safe first"
  /// path: the card never gets stuck on a bare `0x…` placeholder when the
  /// sweep is slow or its personal-wallet read times out (the personal block
  /// races N org + keychain reads behind a 5 s timeout). For an unknown owner
  /// (a keychain wallet, where the caller passes a null account) we fall back
  /// to the address-only placeholder and let the sweep fill identity in.
  void _seedPlaceholderFromPointer() {
    final pointer = widget.config.originatingWalletAddress;
    if (pointer == null || pointer.isEmpty) return;

    final account = widget.config.feedFoundAtAccountAddress;
    final myAddress = AppStateNotifier.currentMyContact?.publicosAddress;
    final isMine = account != null &&
        myAddress != null &&
        account.eip55With0x.toLowerCase() ==
            myAddress.eip55With0x.toLowerCase();

    if (isMine) {
      // Owner known and it's us → render our avatar + name immediately. Carries
      // `accountAddress` so the send path works even if the sweep never lands.
      _allWallets = [
        {
          'name': 'main',
          'address': pointer,
          'balance': null, // null → shimmer
          'accountAddress': account,
          'isGroup': false,
          'color': walletColorFor('main'),
        },
      ];
      _selectedWalletName = 'main';
    } else {
      _allWallets = [
        {
          'name': '',
          'address': pointer,
          'balance': null, // null → shimmer
          'isPlaceholder': true,
          'color': walletColorFor(pointer),
        },
      ];
      _selectedWalletName = '';
    }
    _selectedWalletAddress = pointer;
    _isLoadingWallets = false; // unblock the card immediately

    // Focused balance fetch — runs in parallel with the full sweep so the
    // shimmer resolves long before the directory does.
    _fetchPointerBalance(pointer);
  }

  Future<void> _fetchPointerBalance(String pointer) async {
    try {
      final balanceWei =
          await PublicOSTreasury.getTokenBalance(EthereumAddress.fromHex(pointer));
      if (!mounted) return;
      final balance = balanceWei.toDouble() / 1e18;
      setState(() {
        for (var i = 0; i < _allWallets.length; i++) {
          if (_allWallets[i]['address'] == pointer &&
              _allWallets[i]['balance'] == null) {
            _allWallets[i] = {..._allWallets[i], 'balance': balance};
          }
        }
      });
    } catch (_) {
      // Leave shimmer; the full sweep will fill it in or surface the error.
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    // NB: do NOT read `context.l10n` here — this method is kicked off from
    // initState(), so its synchronous prefix runs before initState completes,
    // and touching an inherited widget (Localizations) then throws. l10n is
    // read lazily at the one use site below (the catch, already mounted-guarded).
    // Don't toggle `_isLoadingWallets` if we already seeded a placeholder —
    // the card is already showing real content and flipping the flag back
    // on would re-trigger the AnimatedSwitcher into the spinner state.
    if (_allWallets.isEmpty) {
      setState(() => _isLoadingWallets = true);
    }

    try {
      final currentUserAddress =
          AppStateNotifier.currentMyContact!.publicosAddress!;

      // Hoist local contacts once and key them by lowercase eip55 address —
      // the org loop below uses this to skip the chain-fetch for any group
      // we've already seen. Same pattern as PublicOSContacts.resolveByIdentifier.
      // The three source loaders live in wallet_sources.dart (shared with
      // the subscribe sheet). Same rows, same keys.
      final swept = await loadWalletRows(currentUserAddress);

      final merged = <Map<String, dynamic>>[];
      final seen = <String>{};
      for (final w in swept) {
        final addr = (w['address'] as String).toLowerCase();
        if (seen.add(addr)) merged.add(w);
      }
      for (final existing in _allWallets) {
        final addr = (existing['address'] as String).toLowerCase();
        if (seen.add(addr)) merged.add(existing);
      }

      _setSelectedWallet(merged);

      if (mounted) {
        setState(() {
          _allWallets = merged;
          _isLoadingWallets = false;
        });
        // A non-OX default token (request-pay / feed pref) needs its balance read
        // now — the origin is only known after the sweep settles.
        if (!_isOxSelected) _fetchTokenBalance();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Only surface the error if we have nothing to show. If the
          // pointer placeholder is already on screen, swallow — the user
          // can still proceed with that wallet.
          if (_allWallets.isEmpty) {
            _errorText = context.l10n.unifiedSendSheetFailedToLoadWallets;
          }
          _isLoadingWallets = false;
        });
      }
    }
  }

  void _setSelectedWallet(List<Map<String, dynamic>> wallets) {
    if (wallets.isEmpty) return;

    // If we have originating wallet address, try to find it. Addresses are
    // case-insensitive (EIP-55 checksum vs all-lowercase are the same address),
    // so match on lowercase — a caller passing a non-checksummed address must
    // still land on its wallet, not fall through to the personal main Safe.
    if (widget.config.originatingWalletAddress != null) {
      final origin = widget.config.originatingWalletAddress!.toLowerCase();
      final matchingWallet = wallets.firstWhere(
        (wallet) => (wallet['address'] as String).toLowerCase() == origin,
        orElse: () => <String, dynamic>{},
      );

      if (matchingWallet.isNotEmpty) {
        _selectedWalletName = matchingWallet['name'];
        _selectedWalletAddress = matchingWallet['address'];
        return;
      }
    }

    // For a non-OX token the origin MUST be a keychain (EOA) — a Safe can't
    // transact off-PublicOS. Prefer a keychain wallet as the default; if there
    // is none, fall through to main and let the send block + warn.
    if (!_isOxSelected) {
      final keychain = wallets.firstWhere(
        (wallet) => wallet['isKeychain'] == true,
        orElse: () => <String, dynamic>{},
      );
      if (keychain.isNotEmpty) {
        _selectedWalletName = keychain['name'];
        _selectedWalletAddress = keychain['address'];
        return;
      }
    }

    // Default to main wallet or first wallet
    final mainWallet = wallets.firstWhere(
      (wallet) => wallet['name'].toLowerCase() == 'main',
      orElse: () => wallets.first,
    );

    _selectedWalletName = mainWallet['name'];
    _selectedWalletAddress = mainWallet['address'];
  }

  Future<void> _loadTargetWallets() async {
    if (_selectedContact?.publicosAddress == null) return;

    // Raw typed-address target: send to that EXACT address, no Safe lookup and
    // no wallet-name label (a null name hides the label slot — the target IS
    // the address).
    if (_targetIsRawAddress) {
      // Never a PublicOS account address: a typed account
      // address pays its main Safe instead; an unknown answer blocks Send.
      final safe = await _neverAnAccount(
          _selectedContact!.publicosAddress!.eip55With0x);
      if (!mounted) return;
      setState(() {
        _allTargetWallets = [];
        _isTargetWalletSelectorExpanded = false;
        _selectedTargetWalletName = null;
        _selectedTargetWalletAddress = safe;
        _isLoadingTargetWallets = false;
      });
      if (safe == null) _targetLookupFailed();
      return;
    }

    setState(() => _isLoadingTargetWallets = true);

    try {
      final account = _selectedContact!.publicosAddress!;
      // The recipient's full EVM wallet set: main Safe (index 0) + their linked
      // ETH wallets. OX is EVM-only, so non-EVM links are filtered out.
      final wallets = await PublicOSWallets.getWallets(account);
      const zero = '0x0000000000000000000000000000000000000000';
      final evm = wallets
          .where((w) =>
              w.protocol == PublicOSWallets.protoEvm &&
              w.addressHex.toLowerCase() != zero)
          .toList();

      final targetWallets =
          await Future.wait(evm.map((w) => _resolveTargetWallet(w, account)));

      // Default to the main Safe (where OX lives), else the first wallet, else
      // the account address directly when the directory comes back empty.
      if (targetWallets.isNotEmpty) {
        final def = targetWallets.firstWhere(
          (w) => w['isMainSafe'] == true,
          orElse: () => targetWallets.first,
        );
        _selectedTargetWalletName = def['name'];
        _selectedTargetWalletAddress = def['address'];
      } else {
        // Empty directory: the account's main Safe, never the account itself
        // (OX sent to an account address is stuck).
        _selectedTargetWalletName = null;
        _selectedTargetWalletAddress = await _neverAnAccount(account.eip55With0x);
        if (_selectedTargetWalletAddress == null) _targetLookupFailed();
      }

      if (mounted) {
        setState(() {
          _allTargetWallets = targetWallets;
          _isLoadingTargetWallets = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // No guess: falling back to the account address would get OX
          // stuck. Send stays disabled until a retry finds the wallet.
          _selectedTargetWalletName = null;
          _selectedTargetWalletAddress = null;
          _allTargetWallets = [];
          _isLoadingTargetWallets = false;
        });
        _targetLookupFailed();
      }
    }
  }

  /// On PublicOS (4489) an address that is a PublicOS ACCOUNT is replaced by
  /// that account's main Safe: an account contract can't move tokens, so OX
  /// sent to it is stuck (the app never relies on a contract-side sweep).
  /// Returns the address to pay, or null when the lookup failed (block Send).
  /// Off 4489 the address is used as given (accounts exist only on 4489).
  Future<String?> _neverAnAccount(String address) async {
    if (!_selectedChain.isOx) return address;
    try {
      final safe = await PublicOSBsp.safeManagerContract
          .getMainSafeAddress((accountAddress: EthereumAddress.fromHex(address)));
      final isAccount = safe.eip55With0x.toLowerCase() !=
          '0x0000000000000000000000000000000000000000';
      return isAccount ? safe.eip55With0x : address;
    } catch (e) {
      Log.w('SendSheet', 'recipient lookup failed: $e');
      return null;
    }
  }

  void _targetLookupFailed() {
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text(l10n.sendRecipientLookupFailed),
      action: SnackBarAction(label: l10n.sendRecipientRetry, onPressed: _loadTargetWallets),
    ));
  }

  /// Map a directory [Wallet] to the target-wallet row shape (name / address /
  /// balance / isMainSafe), fetching its OX balance. Shared by both the send
  /// and tip flows' recipient resolution.
  Future<Map<String, dynamic>> _resolveTargetWallet(
    Wallet w,
    EthereumAddress account,
  ) async {
    final addr = w.addressHex;
    double balance = 0;
    try {
      final balanceWei =
          await PublicOSTreasury.getTokenBalance(EthereumAddress.fromHex(addr));
      balance = balanceWei.toDouble() / 1e18;
    } catch (_) {}
    return {
      'name': w.isMainSafe
          ? 'main'
          : (w.label.isNotEmpty ? w.label : _formatAddress(addr)),
      'address': addr,
      'balance': balance,
      'isMainSafe': w.isMainSafe,
      'accountAddress': account,
      'color': walletColorFor(w.isMainSafe ? 'main' : addr),
    };
  }

  /// Load grid + text size from the shared explorer settings keys
  /// (`explorer_grid_size` / `explorer_text_size`) so the send-sheet grid
  /// stays in sync with the Apps + Contacts views in the explorer.
  Future<void> _loadSettings() async {
    final results = await Future.wait([
      loadStoredGridSize(),
      loadStoredTextSize(),
    ]);
    if (!mounted) return;
    setState(() {
      final grid = results[0] as int?;
      final text = results[1] as TextSizeOption?;
      if (grid != null) _gridSize = grid;
      if (text != null) _textSize = text;
    });
  }

  Future<void> _loadContacts() async {
    if (!mounted) return;
    setState(() => _isLoadingContacts = true);

    try {
      List<Contact> newContacts = [];
      Set<String> addedContactIds = {};

      // Fetch stored contacts - show one contact per contact, not per inbox ID
      final storedContacts = await PublicOSContacts.getStoredContacts();

      for (var contact in storedContacts) {
        if (contact.publicosAddress != null) {
          // Use a unique identifier for each contact
          final contactId = contact.publicosAddress?.eip55With0x ?? contact.displayName;
          if (!addedContactIds.contains(contactId)) {
            newContacts.add(contact);
            addedContactIds.add(contactId);
          }
        }
      }

      if (mounted) {
        setState(() {
          _allContacts = newContacts;
          _filteredContacts = newContacts;
          _isLoadingContacts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allContacts = [];
          _filteredContacts = [];
          _isLoadingContacts = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    final next = _searchController.text;
    if (next == _query) return;
    _query = next;
    _filterLocal();
    _resolveOnChain();
  }

  void _filterLocal() {
    final q = _query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        _filteredContacts = _allContacts.where((c) {
          final nameHit = c.displayName.toLowerCase().contains(q);
          final addrHit =
              c.publicosAddress?.eip55With0x.toLowerCase().contains(q) ?? false;
          return nameHit || addrHit;
        }).toList();
      }
    });
  }

  /// On-chain identifier resolution — same pattern as the explorer contacts
  /// view. Accepts addresses, inbox IDs, and on-chain usernames; the resolved
  /// hit is surfaced as a single tile prepended to the grid.
  Future<void> _resolveOnChain() async {
    final trimmed = _query.trim();
    final gen = ++_resolveGeneration;

    if (trimmed.isEmpty) {
      if (_searchResult != null || _isSearching) {
        setState(() {
          _searchResult = null;
          _searchResultIsRawAddress = false;
          _isSearching = false;
        });
      }
      return;
    }

    setState(() => _isSearching = true);
    try {
      final resolved = await PublicOSContacts.resolveByIdentifier(trimmed);
      if (!mounted || gen != _resolveGeneration) return;
      if (resolved == null) {
        // No known contact. If the query is a well-formed address, surface a
        // non-persisted stub so the user can send to that exact address.
        final stub = _buildRawAddressStub(trimmed);
        setState(() {
          _searchResult = stub;
          _searchResultIsRawAddress = stub != null;
          _isSearching = false;
        });
        return;
      }

      // Drop self and dupes already in the loaded list.
      final myAddress = AppStateNotifier.currentMyContact?.publicosAddress
          ?.eip55With0x
          .toLowerCase();
      final resolvedAddr =
          resolved.publicosAddress?.eip55With0x.toLowerCase();
      if (resolvedAddr == null || resolvedAddr == myAddress) {
        setState(() {
          _searchResult = null;
          _searchResultIsRawAddress = false;
          _isSearching = false;
        });
        return;
      }

      final alreadyLocal = _allContacts.any((c) =>
          c.publicosAddress?.eip55With0x.toLowerCase() == resolvedAddr);

      setState(() {
        _searchResult = alreadyLocal ? null : resolved;
        _searchResultIsRawAddress = false;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted || gen != _resolveGeneration) return;
      setState(() {
        _searchResult = null;
        _searchResultIsRawAddress = false;
        _isSearching = false;
      });
    }
  }

  /// Build a NON-persisted stub [Contact] for a typed address that resolved to
  /// no known contact, so the user can pick it and send to that EXACT address.
  /// Returns null when [input] isn't a well-formed EVM address, is our own
  /// account address, or already matches a loaded contact (those surface as
  /// the real contact via local filtering / on-chain resolution instead).
  Contact? _buildRawAddressStub(String input) {
    final trimmed = input.trim();
    if (!trimmed.startsWith('0x') || trimmed.length != 42) return null;

    final EthereumAddress addr;
    try {
      addr = EthereumAddress.fromHex(trimmed);
    } catch (_) {
      return null; // bad checksum / non-hex
    }

    final lower = addr.eip55With0x.toLowerCase();
    final myAddress = AppStateNotifier.currentMyContact?.publicosAddress
        ?.eip55With0x
        .toLowerCase();
    if (lower == myAddress) return null;
    if (_allContacts.any(
        (c) => c.publicosAddress?.eip55With0x.toLowerCase() == lower)) {
      return null;
    }

    return Contact(
      displayName: _formatAddress(addr.eip55With0x),
      publicosAddress: addr,
    );
  }

  List<Contact> get _displayContacts {
    final list = List<Contact>.from(_filteredContacts);
    if (_searchResult != null && _query.trim().isNotEmpty) {
      list.insert(0, _searchResult!);
    }
    return list;
  }

  String _formatAddress(String address) {
    if (address.length < 10) return address;
    return "${address.substring(0, 6)}...${address.substring(address.length - 4)}";
  }

  /// Compact balance formatting — mirrors `WalletView._formatLargeBalance` so
  /// the SENDING FROM card and the wallet pickers show the same "40.0B" form
  /// as the wallet cards instead of a 20-digit `toStringAsFixed(4)` wall of
  /// zeroes for large holdings.
  String _formatBalance(double balance) {
    if (balance >= 1e12) return '${(balance / 1e12).toStringAsFixed(2)} × 10¹²';
    if (balance >= 1e9) return '${(balance / 1e9).toStringAsFixed(2)}B';
    if (balance >= 1e6) return '${(balance / 1e6).toStringAsFixed(2)}M';
    if (balance >= 1e4) return '${(balance / 1e3).toStringAsFixed(1)}K';
    if (balance >= 100) return balance.toStringAsFixed(0);
    if (balance >= 1) return balance.toStringAsFixed(2);
    return balance.toStringAsFixed(4);
  }

  void _copyToClipboard(String text) {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.unifiedSendSheetAddressCopied)),
      );
    });
  }

  Map<String, dynamic>? get _selectedWalletData {
    return _allWallets.firstWhere(
      (wallet) => wallet['address'] == _selectedWalletAddress,
      orElse: () => <String, dynamic>{},
    );
  }

  /// Null while the selected wallet's balance is still in flight (pointer
  /// placeholder pre-balance-fetch). Callers that need a number for math
  /// should fall back to 0.0 explicitly.
  double? get _currentBalance {
    final walletData = _selectedWalletData;
    final raw = walletData?['balance'];
    return raw is double ? raw : null;
  }

  // ── Multi-chain (chain/token picker) ──────────────────────────────────────

  /// The selected origin wallet is a keychain (EOA) → multi-chain capable. Safe
  /// and group wallets pin to OX (a Safe can't transact on a chain where it
  /// isn't deployed), so the chain/token picker is shown only when this is true.
  bool get _originIsKeychain => _selectedWalletData?['isKeychain'] == true;

  bool get _isOxSelected => _selectedChain.isOx;

  /// The chosen TARGET is the recipient's main Safe — a Gnosis Safe deployed
  /// ONLY on PublicOS/4489. Its address on any other chain is empty, so sending
  /// a non-OX token there is unrecoverable.
  bool get _targetIsMainSafe {
    if (widget.config.exactTargetAddress != null) return _exactTargetIsMainSafe;
    for (final w in _allTargetWallets) {
      if (w['address'] == _selectedTargetWalletAddress) {
        return w['isMainSafe'] == true;
      }
    }
    return false;
  }

  /// Hard block: a main Safe target can't receive funds on a non-OX chain. The
  /// user picks a different token/chain (back to OX) or a linked-wallet target.
  bool get _blockedSafeTarget => !_isOxSelected && _targetIsMainSafe;

  /// Hard block: a non-OX token can only be SENT from a keychain (EOA) — a Safe
  /// can't transact off-PublicOS, and the Safe path is OX-pinned (it would send
  /// the wrong asset). Triggers when there's no keychain origin for a non-OX
  /// token (e.g. paying a non-OX request with no external wallet linked).
  bool get _blockedNonOxFromSafe {
    final w = _selectedWalletData;
    if (_isOxSelected || w == null || w.isEmpty) return false;
    return w['isKeychain'] != true;
  }

  /// Symbol of the token being sent (amount field + send button + balance).
  String get _tokenSymbol => _selectedToken.symbol;

  /// The balance to show/cap against: OX uses the PublicOS balance already on
  /// the wallet row; a non-OX token uses the on-chain `balanceOf` in
  /// [_tokenBalance]. Null while unknown (shimmer / failed read → cap is skipped
  /// and the tx fails honestly if underfunded, per the deferred-gas design).
  double? get _displayBalance => _isOxSelected ? _currentBalance : _tokenBalance;

  /// Origin balance slot for the SENDING FROM card. Shimmers only while the
  /// balance is genuinely loading; once settled, shows the value or "— SYMBOL"
  /// (a failed / timed-out non-OX read does not spin forever).
  Widget _buildOriginBalance(GlassTokens tokens) {
    final loading =
        _isOxSelected ? _currentBalance == null : _isLoadingTokenBalance;
    if (loading) {
      return _ShimmerRect(width: 72, height: 13, tokens: tokens);
    }
    final bal = _displayBalance;
    return Text(
      bal != null ? '${_formatBalance(bal)} $_tokenSymbol' : '— $_tokenSymbol',
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: tokens.starkWhite,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  /// Force OX/4489 — used when the origin wallet is (or becomes) a Safe/group.
  void _pinToOx() {
    _selectedChain = kOxChain;
    _selectedToken = kOxChain.defaultToken;
    _tokenBalance = null;
    _isLoadingTokenBalance = false;
  }

  void _onChainSelected(ChainDef chain) {
    setState(() {
      _selectedChain = chain;
      _selectedToken = chain.defaultToken;
    });
    _validateAmount(_amountController.text);
    _fetchTokenBalance();
  }

  void _onTokenSelected(TokenDef token) {
    setState(() => _selectedToken = token);
    _validateAmount(_amountController.text);
    _fetchTokenBalance();
  }

  /// Read the selected non-OX token's balance for the origin wallet via a
  /// transient client on the chain's RPC (the registry owns the RPC; Core just
  /// runs the standard ERC-20 `balanceOf`). OX clears it — OX uses the existing
  /// PublicOS-balance path.
  Future<void> _fetchTokenBalance() async {
    if (_isOxSelected) {
      if (mounted) {
        setState(() {
          _tokenBalance = null;
          _isLoadingTokenBalance = false;
        });
      }
      return;
    }
    final owner = _selectedWalletAddress;
    final tokenAddr = _selectedToken.address;
    if (owner == null) return;
    if (!_selectedToken.isNative && tokenAddr == null) return;

    final gen = ++_tokenBalanceGen;
    setState(() => _isLoadingTokenBalance = true);
    Web3Client? client;
    try {
      client = Web3Client(_selectedChain.rpcUrl, http.Client());
      final ownerAddr = EthereumAddress.fromHex(owner);
      // 10 s timeout so a slow/unreachable public RPC settles (→ "—") instead
      // of leaving the balance shimmer spinning forever.
      const timeout = Duration(seconds: 10);
      final BigInt raw;
      if (_selectedToken.isNative) {
        final wei = await client.getBalance(ownerAddr).timeout(timeout);
        raw = wei.getInWei;
      } else {
        final contract = PublicOSToken(
          address: EthereumAddress.fromHex(tokenAddr!),
          client: client,
          chainId: _selectedChain.chainId,
        );
        raw = await contract
            .balanceOf((account: ownerAddr))
            .timeout(timeout);
      }
      if (!mounted || gen != _tokenBalanceGen) return;
      final divisor = BigInt.from(10).pow(_selectedToken.decimals).toDouble();
      setState(() {
        _tokenBalance = raw.toDouble() / divisor;
        _isLoadingTokenBalance = false;
      });
    } catch (_) {
      if (!mounted || gen != _tokenBalanceGen) return;
      setState(() {
        _tokenBalance = null; // settled-unknown → "—" + cap skipped, tx fails honestly
        _isLoadingTokenBalance = false;
      });
    } finally {
      client?.dispose();
    }
  }

  /// BigInt-safe human→raw conversion: scales [text] by [decimals] with no float
  /// drift (the old `amount * 1e18` lost precision and assumed 18 decimals). The
  /// single source for decimals is the registry's [TokenDef.decimals].
  BigInt _parseAmountToRaw(String text, int decimals) {
    final parts = text.trim().split('.');
    final whole = parts[0].isEmpty ? '0' : parts[0];
    var frac = parts.length > 1 ? parts[1] : '';
    if (frac.length > decimals) frac = frac.substring(0, decimals);
    frac = frac.padRight(decimals, '0');
    return BigInt.parse('$whole$frac');
  }

  void _selectContact(Contact contact, {bool rawAddress = false}) {
    setState(() {
      _selectedContact = contact;
      _targetIsRawAddress = rawAddress;
      _currentStep = SendStep.amount;
    });
    _animationController.forward();
    _loadTargetWallets();
  }

  void _goBackToStep1() {
    setState(() {
      _currentStep = widget.config.targetMode == SendTargetMode.pickFrom
          ? SendStep.selectActor
          : SendStep.search;
    });
    _animationController.reverse();
  }

  void _validateAmount(String amount) {
    if (amount.isEmpty) {
      setState(() => _errorText = null);
      return;
    }

    try {
      final value = double.parse(amount);
      final bal = _displayBalance;

      if (value <= 0) {
        setState(() =>
            _errorText = context.l10n.unifiedSendSheetAmountGreaterThanZero);
      } else if (bal != null && value > bal) {
        setState(() =>
            _errorText = context.l10n.unifiedSendSheetAmountExceedsBalance);
      } else {
        // Balance not yet known → defer the cap check; the user can still
        // type, and validation runs again whenever the balance lands.
        setState(() => _errorText = null);
      }
    } catch (e) {
      setState(() => _errorText = context.l10n.unifiedSendSheetInvalidAmount);
    }
  }

  void _setPresetAmount(double ratio) {
    final bal = _displayBalance;
    if (bal == null) return; // shimmer still up — no number to anchor on
    // Clamp the displayed precision to the token's decimals (e.g. USDC = 6).
    final places = _selectedToken.decimals < 6 ? _selectedToken.decimals : 6;
    final amount = (bal * ratio).toStringAsFixed(places);
    _amountController.text = amount;
    _validateAmount(amount);
  }

  Future<void> _sendTransaction() async {
    if (_amountController.text.isEmpty || _errorText != null || _selectedWalletName == null || _selectedContact == null || _selectedWalletData == null || _selectedTargetWalletAddress == null) {
      return;
    }

    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isSending = true);

    try {
      final walletData = _selectedWalletData!;
      final isKeychain = walletData['isKeychain'] == true;
      final senderWalletAddress = walletData['address'] as String;

      // Check if trying to send to self (compare wallet addresses)
      if (senderWalletAddress.toLowerCase() == _selectedTargetWalletAddress!.toLowerCase()) {
        setState(() {
          _errorText = l10n.unifiedSendSheetCannotSendToSameWallet;
          _isSending = false;
        });
        return;
      }

      // Last check before the transaction: never a PublicOS account address.
      final safeTarget = await _neverAnAccount(_selectedTargetWalletAddress!);
      if (safeTarget == null) {
        setState(() => _isSending = false);
        _targetLookupFailed();
        return;
      }
      _selectedTargetWalletAddress = safeTarget;
      final recipientWalletAddress = EthereumAddress.fromHex(safeTarget);

      // Raw amount in the selected token's smallest units (OX = 18, USDC = 6,
      // WBTC = 8…). BigInt-safe — no float drift, no hardcoded 18.
      final amountRaw =
          _parseAmountToRaw(_amountController.text, _selectedToken.decimals);
      // Captured for the post-pop receipt (onSent runs after the sheet closes).
      final amountStr = _amountController.text;
      final targetAddr = _selectedTargetWalletAddress!;

      String? txHash;
      bool isGroupAccount = false;

      if (isKeychain) {
        // Keychain (EOA) — ERC-20 transfer. OX uses the global client; a non-OX
        // token uses a transient client on the selected chain's RPC + that
        // chain's token address. (Safe/group can't reach here — the picker is
        // keychain-only, so Safe sends stay OX/4489.)
        final privateKey = walletData['privateKey'] as String;
        if (_isOxSelected) {
          txHash = await PublicOSBsp.sendTokenFromKeychain(
            privateKeyHex: privateKey,
            to: recipientWalletAddress,
            amount: amountRaw,
          );
        } else {
          final client = Web3Client(_selectedChain.rpcUrl, http.Client());
          try {
            txHash = await PublicOSBsp.sendTokenFromKeychain(
              privateKeyHex: privateKey,
              to: recipientWalletAddress,
              amount: amountRaw,
              client: client,
              chainId: _selectedChain.chainId,
              native: _selectedToken.isNative,
              tokenAddress: _selectedToken.isNative
                  ? null
                  : EthereumAddress.fromHex(_selectedToken.address!),
            );
          } finally {
            client.dispose();
          }
        }

        if (mounted) {
          navigator.pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.unifiedSendSheetTransactionSent),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Safe wallet (personal or group)
        final senderAccountAddress = walletData['accountAddress'] as EthereumAddress;
        isGroupAccount = await PublicOSGovernance.isOrgAccount(senderAccountAddress);

        txHash = await PublicOSSafe.sendTokenFromSafe(
          accountAddress: senderAccountAddress,
          safeAddress: EthereumAddress.fromHex(senderWalletAddress),
          to: recipientWalletAddress,
          amount: amountRaw,
        );

        if (mounted) {
          navigator.pop();

          if (isGroupAccount) {
            // For group accounts, show that vote was started
            messenger.showSnackBar(
              SnackBar(
                content: Text(l10n.unifiedSendSheetVoteStarted),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 4),
              ),
            );
          } else {
            // For individual accounts, show transaction completed
            messenger.showSnackBar(
              SnackBar(
                content: Text(l10n.unifiedSendSheetTransactionSent),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }

      // Post-send hook (chat receipt). Only for a real, immediate transfer — an
      // org-account send starts a governance vote (funds move later), so there's
      // no tx to reference yet. Best-effort: the transfer already landed, so a
      // receipt failure must not surface as a send failure. Carries the chain +
      // token so the receipt is correct for any token, not just OX.
      if (widget.config.onSent != null &&
          !isGroupAccount &&
          txHash != null &&
          txHash.isNotEmpty) {
        try {
          await widget.config.onSent!(SentTxInfo(
            txHash: txHash,
            fromAddress: senderWalletAddress,
            toAddress: targetAddr,
            amount: amountStr,
            chainId: _selectedChain.chainId,
            tokenSymbol: _selectedToken.symbol,
            decimals: _selectedToken.decimals,
          ));
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = l10n.unifiedSendSheetTransactionFailed;
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceDeep,
        // DELTA (desktop): dialog presentation — all-corner radius, no handle.
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          // A cap, not a fixed height: the search/pick steps fill it (their
          // grids are Expanded), the amount step hugs its content.
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(tokens),
                        if (_currentStep == SendStep.search)
                          Expanded(child: _buildSearchStep(tokens))
                        else if (_currentStep == SendStep.selectActor)
                          Expanded(child: _buildSelectActorStep(tokens))
                        else
                          // Scrollable so the keyboard doesn't overflow the
                          // capped sheet (the yellow/black striped bar).
                          Flexible(
                            child: SingleChildScrollView(
                              child: _buildAmountStep(tokens),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(GlassTokens tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: _currentStep == SendStep.amount && !_skipsTargetSelection
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: tokens.starkWhite,
                      size: 18,
                    ),
                    onPressed: _goBackToStep1,
                  )
                : const SizedBox(),
          ),
          Expanded(
            child: Text(
              widget.config.title ?? context.l10n.unifiedSendSheetTitle,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close_rounded,
              color: tokens.starkWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchStep(GlassTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWalletCard(tokens, isOriginatingCard: true),
        _buildWalletSelectionList(tokens),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: tokens.glassFill,
              border: Border.all(color: tokens.borderSubtle, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 14,
              ),
              cursorColor: tokens.starkWhite,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: tokens.textDim,
                ),
                hintText: context.l10n.unifiedSendSheetSearchHint,
                hintStyle: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildContactsGrid(tokens)),
      ],
    );
  }

  /// Step 1 for pickFrom mode (tipping / group chat): the SENDING FROM card +
  /// the deduped candidate list. Ported from the old tip_sheet.
  Widget _buildSelectActorStep(GlassTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWalletCard(tokens, isOriginatingCard: true),
        _buildWalletSelectionList(tokens),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            context.l10n.tipSheetChooseRecipient,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _actors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _buildActorRow(tokens, _actors[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildActorRow(GlassTokens tokens, _SendActor actor) {
    final contact = actor.contact;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectActor(actor),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.glassFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: Row(
            children: [
              contact != null
                  ? GlassContactIcon(contact: contact, size: 40)
                  : GlassContactIcon(
                      address: actor.address.eip55With0x, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _actorDisplayName(actor),
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: tokens.starkWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (actor.roles.isNotEmpty) ...[
                          Text(
                            _rolesLabel(actor.roles),
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              color: tokens.starkWhite,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            _formatAddress(actor.address.eip55With0x),
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              color: tokens.textDim,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: tokens.textDim),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactsGrid(GlassTokens tokens) {
    if (_isLoadingContacts) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: tokens.textDim,
          ),
        ),
      );
    }

    final contacts = _displayContacts;
    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSearching) ...[
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: tokens.starkWhite,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.unifiedSendSheetSearchingOnChain,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 13,
                ),
              ),
            ] else ...[
              Icon(
                _searchController.text.isEmpty
                    ? Icons.account_balance_wallet_rounded
                    : Icons.search_off_rounded,
                size: 44,
                color: tokens.textDim,
              ),
              const SizedBox(height: 14),
              Text(
                _searchController.text.isEmpty
                    ? context.l10n.unifiedSendSheetSelectContact
                    : context.l10n.unifiedSendSheetNoContactsFound,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Same shape as the Apps and Contacts grids (childAspectRatio 0.65) so
    // the tile stays compact when columns shrink — a square ratio would
    // double the row height every time you halve the column count.
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridSize,
        childAspectRatio: 0.65,
        mainAxisSpacing: 0,
        crossAxisSpacing: 8,
      ),
      itemCount: contacts.length,
      itemBuilder: (context, index) =>
          _buildContactGridTile(tokens, contacts[index]),
    );
  }

  Widget _buildContactGridTile(GlassTokens tokens, Contact contact) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Icon scales with tile width but capped, mirroring the contacts view.
        final iconSize = (constraints.maxWidth * 0.62).clamp(40.0, 88.0);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _selectContact(
            contact,
            rawAddress:
                _searchResultIsRawAddress && identical(contact, _searchResult),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GlassContactIcon(
                  contact: contact,
                  size: iconSize,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    contact.displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.starkWhite,
                      fontSize: _textSize.fontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWalletCard(
    GlassTokens tokens, {
    required bool isOriginatingCard,
    bool showBalanceInfo = false,
  }) {
    const cardHeight = 104.0;

    final loaded = isOriginatingCard
        ? !(_isLoadingWallets || _selectedWalletData == null)
        : !(_isLoadingTargetWallets || _selectedContact == null);
    // Only offer "change" when there's actually another wallet to switch to.
    final canChange = loaded &&
        (isOriginatingCard
            ? _allWallets.length > 1
            : _allTargetWallets.length > 1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      height: cardHeight,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: !loaded
                ? _buildLoadingIndicator(tokens)
                : _buildWalletLoadedContent(
                    tokens,
                    isOriginatingCard: isOriginatingCard,
                    showBalanceInfo: showBalanceInfo,
                  ),
          ),
          // Subtle corner "change wallet" button (replaces the old text chip).
          if (canChange)
            Positioned(
              bottom: 0,
              right: 0,
              child: _buildChangeIconButton(tokens,
                  isOriginating: isOriginatingCard),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(GlassTokens tokens) {
    return Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: tokens.textDim,
        ),
      ),
    );
  }

  Widget _buildWalletLoadedContent(
    GlassTokens tokens, {
    required bool isOriginatingCard,
    bool showBalanceInfo = false,
  }) {
    final labelStyle = TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: tokens.textDim,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    );
    final titleStyle = TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: tokens.starkWhite,
      fontSize: 15,
      fontWeight: FontWeight.w700,
    );
    final smallStyle = TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: tokens.starkWhite,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
    final smallDimStyle = TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: tokens.textDim,
      fontSize: 12,
    );

    if (isOriginatingCard) {
      final walletData = _selectedWalletData!;
      final isGroup =
          walletData['isGroup'] == true && walletData['groupContact'] != null;
      final isKeychain = walletData['isKeychain'] == true;
      final isPlaceholder = walletData['isPlaceholder'] == true;
      final addr = walletData['address'] as String;

      // Title: short address while identity is unknown, real label once it
      // lands. AnimatedSwitcher swaps with a fade — ValueKey tracks the text
      // so identical labels don't re-animate on unrelated rebuilds.
      final titleText = isPlaceholder
          ? _formatAddress(addr)
          : isKeychain
              ? context.l10n.unifiedSendSheetKeychain
              : isGroup
                  ? walletData['groupContact']?.displayName ??
                      context.l10n.unifiedSendSheetGroupAccount
                  : AppStateNotifier.currentMyContact?.displayName ??
                      context.l10n.unifiedSendSheetMyAccount;

      return Row(
        key: const ValueKey('loaded'),
        children: [
          if (isPlaceholder)
            _PlaceholderAvatar(tokens: tokens)
          else if (isKeychain)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (walletData['color'] as Color?)?.withValues(alpha: 0.2) ??
                    Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  walletData['emoji'] ?? '🔑',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            )
          else if (isGroup)
            GlassContactIcon(
              contact: walletData['groupContact'],
              size: 40,
            )
          else
            GlassContactIcon(
              contact: AppStateNotifier.currentMyContact!,
              size: 40,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(context.l10n.unifiedSendSheetSendingFrom, style: labelStyle),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: child,
                        ),
                        child: Text(
                          titleText,
                          key: ValueKey(titleText),
                          style: titleStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (showBalanceInfo) _buildOriginBalance(tokens),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // Hide the "main" secondary label while we don't yet know
                    // the wallet's role (placeholder phase).
                    if (!isPlaceholder) ...[
                      Text(walletData['name'] ?? '', style: smallStyle),
                      const SizedBox(width: 8),
                    ],
                    GestureDetector(
                      onTap: () => _copyToClipboard(addr),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatAddress(addr),
                            style: smallDimStyle,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.copy_rounded,
                            size: 12,
                            color: tokens.textDim,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Row(
        key: const ValueKey('loaded'),
        children: [
          GlassContactIcon(
            contact: _selectedContact!,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(context.l10n.unifiedSendSheetSendingTo, style: labelStyle),
                const SizedBox(height: 4),
                Text(
                  _selectedContact!.displayName,
                  style: titleStyle,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // Only show a wallet-name label for a resolved Safe ("main").
                    // Direct-address targets leave it null → no label. Exact
                    // targets (request-pay, tip cards) name the wallet from
                    // the owner lookup. One row, so the card never grows.
                    if ((_exactOwnerLabel(context) ??
                            _selectedTargetWalletName)
                        case final walletLabel?) ...[
                      Flexible(
                        child: Text(
                          walletLabel,
                          style: smallStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_selectedTargetWalletAddress != null)
                      GestureDetector(
                        onTap: () => _copyToClipboard(_selectedTargetWalletAddress!),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatAddress(_selectedTargetWalletAddress!),
                              style: smallDimStyle,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.copy_rounded,
                              size: 12,
                              color: tokens.textDim,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  /// Subtle bottom-right "change wallet" icon button — replaces the old text
  /// chip. Toggles the origin / target wallet selection list; shows a close
  /// glyph while the list is open.
  Widget _buildChangeIconButton(
    GlassTokens tokens, {
    required bool isOriginating,
  }) {
    final expanded = isOriginating
        ? _isWalletSelectorExpanded
        : _isTargetWalletSelectorExpanded;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() {
          if (isOriginating) {
            _isWalletSelectorExpanded = !_isWalletSelectorExpanded;
          } else {
            _isTargetWalletSelectorExpanded = !_isTargetWalletSelectorExpanded;
          }
        }),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: tokens.glassFillHover,
            shape: BoxShape.circle,
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          alignment: Alignment.center,
          child: Icon(
            expanded ? Icons.close_rounded : Icons.swap_horiz_rounded,
            size: 15,
            color: tokens.textDim,
          ),
        ),
      ),
    );
  }

  Widget _buildWalletSelectionList(GlassTokens tokens) {
    if (!_isWalletSelectorExpanded) return const SizedBox.shrink();

    final availableWallets = _allWallets
        .where((wallet) => wallet['address'] != _selectedWalletAddress)
        .toList();

    return Column(
      children: availableWallets.map((wallet) {
        final isGroup = wallet['isGroup'] ?? false;
        final isKeychain = wallet['isKeychain'] ?? false;

        return Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _selectedWalletName = wallet['name'];
                  _selectedWalletAddress = wallet['address'];
                  _isWalletSelectorExpanded = false;
                  // A Safe/group origin can't go multi-chain → pin back to OX —
                  // UNLESS the chain/token is locked (request-pay), where the
                  // token must stay and a Safe origin is blocked + warned.
                  if (wallet['isKeychain'] != true &&
                      !widget.config.lockChainToken) {
                    _pinToOx();
                  }
                });
                // Non-OX token → re-read this origin's balance.
                if (!_isOxSelected) _fetchTokenBalance();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tokens.glassFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.borderSubtle, width: 1),
                ),
                child: Row(
                  children: [
                    if (isKeychain)
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (wallet['color'] as Color?)
                                  ?.withValues(alpha: 0.2) ??
                              Colors.green.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            wallet['emoji'] ?? '🔑',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      )
                    else if (isGroup && wallet['groupContact'] != null)
                      GlassContactIcon(contact: wallet['groupContact'], size: 36)
                    else
                      GlassContactIcon(
                        contact: AppStateNotifier.currentMyContact!,
                        size: 36,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isKeychain
                                ? context.l10n.unifiedSendSheetKeychain
                                : isGroup
                                    ? wallet['groupContact']?.displayName ??
                                        context.l10n.unifiedSendSheetGroupAccount
                                    : AppStateNotifier.currentMyContact?.displayName ??
                                        context.l10n.unifiedSendSheetMyAccount,
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              color: tokens.starkWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                wallet['name'],
                                style: TextStyle(
                                  fontFamily: 'SpaceGrotesk',
                                  color: tokens.starkWhite,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatAddress(wallet['address']),
                                style: TextStyle(
                                  fontFamily: 'SpaceGrotesk',
                                  color: tokens.textDim,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    wallet['balance'] is double
                        ? Text(
                            '${_formatBalance(wallet['balance'] as double)} OX',
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              color: tokens.starkWhite,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : _ShimmerRect(width: 64, height: 12, tokens: tokens),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTargetWalletSelectionList(GlassTokens tokens) {
    if (!_isTargetWalletSelectorExpanded || _allTargetWallets.isEmpty) {
      return const SizedBox.shrink();
    }

    final availableTargetWallets = _allTargetWallets
        .where((wallet) => wallet['address'] != _selectedTargetWalletAddress)
        .toList();

    return Column(
      children: availableTargetWallets.map((wallet) {
        return Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _selectedTargetWalletName = wallet['name'];
                  _selectedTargetWalletAddress = wallet['address'];
                  _isTargetWalletSelectorExpanded = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tokens.glassFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.borderSubtle, width: 1),
                ),
                child: Row(
                  children: [
                    GlassContactIcon(contact: _selectedContact!, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedContact!.displayName,
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              color: tokens.starkWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                wallet['name'],
                                style: TextStyle(
                                  fontFamily: 'SpaceGrotesk',
                                  color: tokens.starkWhite,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatAddress(wallet['address']),
                                style: TextStyle(
                                  fontFamily: 'SpaceGrotesk',
                                  color: tokens.textDim,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_formatBalance(wallet['balance'] as double)} OX',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: tokens.starkWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountStep(GlassTokens tokens) {
    final walletData = _selectedWalletData;
    final identityResolved = walletData?['isPlaceholder'] != true;
    // OX gates on the known PublicOS balance (existing UX). A non-OX token gates
    // only on the balanceOf read having settled — even a failed read lets the
    // send proceed and fail honestly (deferred-gas design).
    final balanceReady = _isOxSelected
        ? (walletData?['balance'] is double)
        : !_isLoadingTokenBalance;
    // Lost-funds / wrong-asset guards (see the getters): a main Safe target
    // can't receive off-OX, and a non-OX token can't be sent from a Safe.
    final blockMsg = _blockedSafeTarget
        ? context.l10n.unifiedSendSheetSafeOtherNetwork
        : (_blockedNonOxFromSafe
            ? context.l10n.unifiedSendSheetNeedKeychain
            : null);
    // Off 4489 an exact target must have been checked for being a MainSafe
    // before anything is sent.
    final exactTargetReady = widget.config.exactTargetAddress == null ||
        _isOxSelected ||
        _exactOwnerChecked;
    final canSend = !_isSending &&
        _errorText == null &&
        _amountController.text.isNotEmpty &&
        balanceReady &&
        identityResolved &&
        exactTargetReady &&
        blockMsg == null;

    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWalletCard(tokens, isOriginatingCard: true, showBalanceInfo: true),
          _buildWalletSelectionList(tokens),
          _buildWalletCard(tokens, isOriginatingCard: false),
          _buildTargetWalletSelectionList(tokens),

          // Chain + token: locked read-only for request-pay, else the picker
          // (keychain origins only; a Safe pins to OX).
          if (widget.config.lockChainToken)
            _buildLockedChainToken(tokens)
          else if (_originIsKeychain)
            _buildChainTokenPicker(tokens),

          // Amount input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: tokens.glassFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _errorText != null
                      ? const Color(0xFFFF453A).withValues(alpha: 0.7)
                      : tokens.borderSubtle,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.payments_rounded,
                    size: 18,
                    color: tokens.textDim,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: tokens.starkWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      cursorColor: tokens.starkWhite,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '0.0',
                        hintStyle: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          color: tokens.textDim,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      onChanged: (v) {
                        // Typing a custom amount clears the tip-chip selection.
                        if (_selectedChipIndex != null) {
                          setState(() => _selectedChipIndex = null);
                        }
                        _validateAmount(v);
                      },
                    ),
                  ),
                  Text(
                    _tokenSymbol,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.textDim,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Text(
                _errorText!,
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: Color(0xFFFF453A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Paying a request → restaurant-style tip chips (Requested / +10% …);
          // otherwise the balance-based quick-amount buttons.
          if (widget.config.requestedAmount != null &&
              widget.config.tipChips.isNotEmpty)
            _buildTipChips(tokens)
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAmountButton(tokens, '25%', 0.25),
                  _buildQuickAmountButton(tokens, '50%', 0.5),
                  _buildQuickAmountButton(tokens, '75%', 0.75),
                  _buildQuickAmountButton(
                      tokens, context.l10n.unifiedSendSheetMax, 1.0),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Lost-funds / wrong-asset guard banner (see blockMsg above).
          if (blockMsg != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: Color(0xFFFFAB40)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      blockMsg,
                      style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: Color(0xFFFFAB40),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Send button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SystemAppActionButton(
              label: _isSending
                  ? context.l10n.unifiedSendSheetSending
                  : (widget.config.confirmLabel ??
                      (_isOxSelected
                          ? context.l10n.unifiedSendSheetSendOx
                          : 'Send $_tokenSymbol')),
              icon: _isSending
                  ? Icons.hourglass_empty_rounded
                  : (widget.config.confirmIcon ?? Icons.arrow_upward_rounded),
              onTap: canSend ? _sendTransaction : null,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(
    GlassTokens tokens,
    String label,
    double ratio,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _setPresetAmount(ratio),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tokens.glassFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.borderSubtle, width: 1),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Read-only chain + token row for a locked request-pay (the request dictates
  /// the asset; the user pays from their wallet but can't change it here).
  Widget _buildLockedChainToken(GlassTokens tokens) {
    final style = TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: tokens.starkWhite,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        child: Row(
          children: [
            NftChainIcon(chain: _selectedChain.chainId, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(_selectedChain.name,
                  style: style, overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
            const SizedBox(width: 10),
            Text('·', style: TextStyle(color: tokens.textDim)),
            const SizedBox(width: 10),
            CoinIcon(symbol: _selectedToken.symbol, size: 24),
            const SizedBox(width: 8),
            Text(_selectedToken.symbol, style: style),
            const Spacer(),
            Icon(Icons.lock_outline_rounded, size: 14, color: tokens.textDim),
          ],
        ),
      ),
    );
  }

  /// Restaurant-style tip chips on the requested amount: Requested · +10% · …
  Widget _buildTipChips(GlassTokens tokens) {
    final req = widget.config.requestedAmount!;
    final chips = widget.config.tipChips;
    final base =
        req.toDouble() / BigInt.from(10).pow(_selectedToken.decimals).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _tipChip(tokens, i, base, chips[i])),
          ],
        ],
      ),
    );
  }

  Widget _tipChip(GlassTokens tokens, int index, double base, double mult) {
    final value = base * mult;
    final label = mult == 1.0
        ? context.l10n.unifiedSendSheetChipRequested
        : '+${((mult - 1) * 100).round()}%';
    final selected = _selectedChipIndex == index;
    final places = _selectedToken.decimals < 4 ? _selectedToken.decimals : 4;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () {
          final text = value.toStringAsFixed(places);
          _amountController.text = text;
          setState(() => _selectedChipIndex = index);
          _validateAmount(text);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? tokens.glassFillHover : tokens.glassFill,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected
                  ? tokens.starkWhite.withValues(alpha: 0.4)
                  : tokens.borderSubtle,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 2),
              Text(_formatBalance(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chain + token picker UI ───────────────────────────────────────────────

  /// Two glass pills (Chain · Token). Tapping opens a selection sheet. Choosing
  /// a chain resets to that chain's default token; choosing a token re-reads its
  /// balance. Shown only for keychain origins (Safe pins to OX).
  Widget _buildChainTokenPicker(GlassTokens tokens) {
    // IntrinsicHeight + stretch = both pills equal the taller one's content
    // height (no fixed height, so the 3-line content can never overflow).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _pickerPill(
                tokens,
                badge: NftChainIcon(chain: _selectedChain.chainId, size: 28),
                label: context.l10n.unifiedSendSheetChainLabel,
                value: _selectedChain.name,
                subtitle:
                    '${context.l10n.unifiedSendSheetGasLabel}: ${_selectedChain.nativeSymbol}',
                onTap: _showChainSheet,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _pickerPill(
                tokens,
                badge: CoinIcon(symbol: _selectedToken.symbol, size: 32),
                label: context.l10n.unifiedSendSheetTokenLabel,
                value: _selectedToken.symbol,
                subtitle: _selectedToken.isNative ? 'native' : 'ERC-20',
                valueSize: 18,
                onTap: _showTokenSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerPill(
    GlassTokens tokens, {
    required String label,
    required String value,
    String? subtitle,
    Widget? badge,
    double valueSize = 14,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          // No fixed height — IntrinsicHeight in the parent equalizes the two
          // pills; content-sized so the label/value/subtitle never overflow.
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: tokens.glassFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: Row(
            children: [
              if (badge != null) ...[badge, const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: tokens.textDim,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: tokens.starkWhite,
                        fontSize: valueSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          color: tokens.textDim,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.expand_more_rounded, size: 18, color: tokens.textDim),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChainSheet() async {
    final tokens = GlassTokens.of(context);
    final chosen = await showGlassSheetDialog<ChainDef>(
      context: context,
      width: DialogWidth.m,
      builder: (_) => _buildSelectionSheet<ChainDef>(
        tokens,
        title: context.l10n.unifiedSendSheetSelectChain,
        // kSendChains, not kChainRegistry: the registry is now the dApp
        // browser's chain list too, and a chain only reaches this money
        // surface once its tokens are explorer-verified (ChainDef.sendEnabled).
        items: kSendChains,
        isSelected: (c) => c.chainId == _selectedChain.chainId,
        labelOf: (c) => c.name,
        subtitleOf: (c) =>
            '${context.l10n.unifiedSendSheetGasLabel}: ${c.nativeSymbol}',
        badgeOf: (c) => NftChainIcon(chain: c.chainId, size: 34),
      ),
    );
    if (chosen != null && chosen.chainId != _selectedChain.chainId) {
      _onChainSelected(chosen);
    }
  }

  Future<void> _showTokenSheet() async {
    final tokens = GlassTokens.of(context);
    final chosen = await showGlassSheetDialog<TokenDef>(
      context: context,
      width: DialogWidth.m,
      builder: (_) => _buildSelectionSheet<TokenDef>(
        tokens,
        title: context.l10n.unifiedSendSheetSelectToken,
        items: _selectedChain.tokens,
        isSelected: (t) => t.symbol == _selectedToken.symbol,
        labelOf: (t) => t.symbol,
        subtitleOf: (t) => t.isNative ? 'native' : 'ERC-20',
        badgeOf: (t) => CoinIcon(symbol: t.symbol, size: 34),
      ),
    );
    if (chosen != null && chosen.symbol != _selectedToken.symbol) {
      _onTokenSelected(chosen);
    }
  }

  Widget _buildSelectionSheet<T>(
    GlassTokens tokens, {
    required String title,
    required List<T> items,
    required bool Function(T) isSelected,
    required String Function(T) labelOf,
    required String Function(T) subtitleOf,
    Widget Function(T)? badgeOf,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceDeep,
        // DELTA (desktop): dialog presentation — all-corner radius, no handle.
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  final isSel = isSelected(item);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.of(context).pop(item),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isSel ? tokens.glassFillHover : tokens.glassFill,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel
                                  ? tokens.starkWhite.withValues(alpha: 0.3)
                                  : tokens.borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (badgeOf != null) ...[
                                badgeOf(item),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      labelOf(item),
                                      style: TextStyle(
                                        fontFamily: 'SpaceGrotesk',
                                        color: tokens.starkWhite,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitleOf(item),
                                      style: TextStyle(
                                        fontFamily: 'SpaceGrotesk',
                                        color: tokens.textDim,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSel)
                                Icon(Icons.check_rounded,
                                    size: 18, color: tokens.starkWhite),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiny gradient-sweep shimmer for inline "balance loading" slots in the
/// SENDING FROM card and the wallet picker rows. Hand-rolled (no `shimmer`
/// package) — ~30 lines, animation isolated to this widget so it doesn't
/// trigger rebuilds on the rest of the sheet.
class _ShimmerRect extends StatefulWidget {
  final double width;
  final double height;
  final GlassTokens tokens;

  const _ShimmerRect({
    required this.width,
    required this.height,
    required this.tokens,
  });

  @override
  State<_ShimmerRect> createState() => _ShimmerRectState();
}

class _ShimmerRectState extends State<_ShimmerRect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.tokens.borderSubtle;
    final highlight = widget.tokens.glassFillHover;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.height / 2),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            // Sweep -1 → +2 so the gradient starts off-screen left and ends
            // off-screen right; the visible window catches one pass per cycle.
            final t = _ctrl.value * 3 - 1;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(t - 1, 0),
                  end: Alignment(t + 1, 0),
                  colors: [base, highlight, base],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Dim circular placeholder that fills the avatar slot in the SENDING FROM
/// card while the pointer wallet's identity (personal / group / keychain)
/// is still resolving. Sized to match `GlassContactIcon(size: 40)`.
class _PlaceholderAvatar extends StatelessWidget {
  final GlassTokens tokens;
  const _PlaceholderAvatar({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: tokens.glassFillHover,
        shape: BoxShape.circle,
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
    );
  }
}
