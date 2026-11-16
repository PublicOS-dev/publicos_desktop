import 'dart:typed_data';
import 'package:publicos_core/publicos_core.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_label.dart';
import 'package:publicos_desktop/widgets/profile/record_button.dart';
import 'package:publicos_desktop/widgets/profile/profile_grid.dart';
import 'package:zero_cached_image/zero_cached_image.dart';
import 'package:web3dart/web3dart.dart'
    show TupleType, DynamicLengthArray, StringType, UintType;
import 'package:flutter/services.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/members_stack.dart';
import 'package:publicos_desktop/widgets/org_management/cancel_vote_sheet.dart';
import 'package:publicos_desktop/widgets/org_management/children_sheet.dart';
import 'package:publicos_desktop/widgets/org_management/delegate_vote_sheet.dart';
import 'package:publicos_desktop/widgets/org_management/history_sheet.dart';
import 'package:publicos_desktop/widgets/org_management/members_sheet.dart';
import 'package:publicos_desktop/widgets/org_management/start_new_vote_sheet.dart';
import 'package:publicos_desktop/widgets/org_management/voters_sheet.dart';
import 'package:publicos_desktop/widgets/orgs/manage_group_inbox_ids_sheet.dart';
import 'package:publicos_desktop/widgets/orgs/pick_org_members_sheet.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_widget.dart';
import 'package:publicos_desktop/widgets/send_icon.dart';
import 'package:publicos_desktop/widgets/transactions/send_sheet.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/widgets/error/revert_reason_l10n.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Org Management screen — settings-page idiom (bare section headers + light
/// glass rows; **no** bordered section cards; **no** floating action button).
///
/// Every proposal type has an inline home: ADD/REMOVE_MEMBER + SET_THRESHOLD
/// in Membership, REGISTER_WALLET / REMOVE_WALLET in Wallets, SET/DELETE_RECORD
/// in the Records tab (separate surface), REGISTER/REMOVE/UPDATE_INBOX_ID_LABEL
/// inside the Manage Inbox IDs sheet. Add/Remove Module proposals are kept in
/// `ManagementVoteAction` but no listing UI ships yet (needs a
/// `Safe.getModulesPaginated` Core binding).
class GroupVotingView extends StatefulWidget {
  final Contact? contact;
  final bool isOrgMember;

  /// Hard-reload the org contact from chain (browser's `_syncFromChain`).
  /// Called after any write that may change on-chain contact state.
  final Future<void> Function()? onContactRefresh;

  /// Top inset applied INSIDE the scroll view so content starts below the
  /// browser's expanded address bar and scrolls up under it (management shows
  /// the same expanded header as the profile). 0 when not hosted under it.
  final double topInset;

  const GroupVotingView({
    super.key,
    required this.contact,
    required this.isOrgMember,
    this.onContactRefresh,
    this.topInset = 0,
  });

  @override
  State<GroupVotingView> createState() => _GroupVotingViewState();
}

/// Load-failure kind. Stored instead of a localized string so the message is
/// resolved in `build` (where a BuildContext is valid) rather than during the
/// initState-triggered load, where `context.l10n` would be unsafe.
enum _OrgLoadError { invalidAddress, loadFailed }

class _GroupVotingViewState extends State<GroupVotingView> {
  List<VoteHistoryItem> _votes = const [];
  /// Start of the week of history read with [_votes] (the history sheet pages back from here).
  DateTime _historySince = DateTime.now().subtract(const Duration(days: 7));
  bool _isLoading = true;
  _OrgLoadError? _error;

  List<EthereumAddress> _memberAddresses = const [];
  List<Contact> _memberContacts = const [];

  // Voting-engine knobs (org-resolved: own override, else global default).
  int _quorumBps = 0;
  int _voteDurationSeconds = 0;
  // Parallel votes: the engine's view of each open proposal (passed /
  // executable) by id, and the org's three vote settings.
  Map<BigInt, ActiveVoteInfo> _openInfo = const {};
  /// Votes decided while this screen is open keep their place, shown in
  /// their finished state, until the next visit.
  final Set<String> _keptIds = {};
  /// Proposals with a ballot or a run in flight: no buttons, a loader.
  final Set<String> _busyIds = {};
  int _maxOpen = 2;
  bool _waitFull = false;
  bool _proposerCap = true;
  // Vote cancel: the org's vetoer (null = none), its withdraw
  // cooldown in seconds, and when this member may propose again after a withdraw.
  String? _vetoer;
  int _cancelCooldown = 0;
  DateTime? _myCooldownUntil;

  // The default-lane delegate this member currently carries their ballot to
  // (null / self = not delegated). Loaded only for org members.
  String? _myDelegatee;

  List<Map<String, String>> _registeredInboxIds = const [];
  List<Wallet> _wallets = const [];

  double? _safeBalance;

  /// GroupSplitter: has the org Safe approved the
  /// splitter for OX? null = not read yet / read failed → no button.
  bool? _splitterActive;

  /// The one open collapsible group ('votes' · 'wallets' · 'records' ·
  /// 'inboxes'); Votes starts open. Page state only.
  String? _openGroup = 'votes';
  void _toggleGroup(String id) =>
      setState(() => _openGroup = _openGroup == id ? null : id);

  // Hierarchy — read-only. Mutation surfaces are not built here.
  Contact? _parentContact;
  int _childCount = 0;
  List<Contact> _childContacts = const [];

  /// Drives the outer management list directly so the nested Records box can
  /// forward its overscroll here (scroll chaining: when the box hits an end —
  /// or its content fits and can't scroll at all — continued drag scrolls the
  /// page instead of dead-ending inside the box).
  final ScrollController _outerController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAllData(silent: false);
  }

  @override
  void dispose() {
    _outerController.dispose();
    super.dispose();
  }

  /// [silent] (the default) re-reads everything and repaints in
  /// place: no loading screen, scroll and cards kept. Only the first load
  /// and the error screen's retry show the loader.
  Future<void> _loadAllData({bool silent = true}) async {
    if (!mounted) return;
    if (!silent || _error != null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      if (widget.contact?.publicosAddress == null) {
        if (mounted) {
          setState(() {
            _error = _OrgLoadError.invalidAddress;
            _isLoading = false;
          });
        }
        return;
      }

      final orgAddress = widget.contact!.publicosAddress!;

      // Children carousel mirrors Members (max 10 visible + the `+N` chip), so
      // a single 11-wide page is enough to feed the dense tile. The Children
      // sheet does its own paginated re-fetch when opened.
      final historySince = DateTime.now().subtract(const Duration(days: 7));
      final results = await Future.wait([
        PublicOSGovernance.getVotingHistory(orgAddress.eip55With0x, since: historySince),
        PublicOSGovernance.getOrgMembers(orgAddress),
        _loadRegisteredInboxIds(),
        PublicOSWallets.getWallets(orgAddress),
        PublicOSGovernance.getParentOrg(orgAddress),
        PublicOSGovernance.getChildOrgCount(orgAddress),
        PublicOSGovernance.getChildOrgs(orgAddress, offset: 0, limit: 11),
        PublicOSGovernance.getOrgQuorumBps(orgAddress.eip55With0x),
        PublicOSGovernance.getOrgVoteDuration(orgAddress.eip55With0x),
        PublicOSGovernance.getOpenVotes(orgAddress.eip55With0x),
        PublicOSGovernance.getOrgMaxOpen(orgAddress.eip55With0x),
        PublicOSGovernance.getOrgWaitFullPeriod(orgAddress.eip55With0x),
        PublicOSGovernance.getOrgProposerCap(orgAddress.eip55With0x),
        PublicOSGovernance.getOrgVetoer(orgAddress.eip55With0x),
        PublicOSGovernance.getOrgCancelCooldown(orgAddress.eip55With0x),
      ]);

      final votes = results[0] as List<VoteHistoryItem>;
      _historySince = historySince;
      final members = results[1] as List<EthereumAddress>;
      final inboxIds = results[2] as List<Map<String, String>>;
      final wallets = results[3] as List<Wallet>;
      final parentAddress = results[4] as EthereumAddress?;
      final childCount = results[5] as int;
      final childAddresses = results[6] as List<EthereumAddress>;
      final quorumBps = results[7] as BigInt?;
      final voteDuration = results[8] as BigInt?;
      final openInfo = results[9] as List<ActiveVoteInfo>;
      final maxOpen = results[10] as int?;
      final waitFull = results[11] as bool?;
      final proposerCap = results[12] as bool?;
      final vetoer = results[13] as String?;
      final cancelCooldown = results[14] as int?;

      final memberContacts = <Contact>[];
      for (final addr in members) {
        try {
          final contact = await PublicOSContacts.searchContacts(addr.eip55With0x);
          memberContacts.add(contact ??
              Contact(
                publicosAddress: addr,
                displayName: _short(addr.eip55With0x),
              ));
        } catch (_) {
          memberContacts.add(Contact(
            publicosAddress: addr,
            displayName: _short(addr.eip55With0x),
          ));
        }
      }

      Contact? parentContact;
      if (parentAddress != null) {
        try {
          parentContact = await PublicOSContacts.searchContacts(parentAddress.eip55With0x);
        } catch (_) {}
        parentContact ??= Contact(
          publicosAddress: parentAddress,
          displayName: _short(parentAddress.eip55With0x),
        );
      }

      final childContacts = <Contact>[];
      for (final addr in childAddresses) {
        try {
          final contact = await PublicOSContacts.searchContacts(addr.eip55With0x);
          childContacts.add(contact ??
              Contact(
                publicosAddress: addr,
                displayName: _short(addr.eip55With0x),
              ));
        } catch (_) {
          childContacts.add(Contact(
            publicosAddress: addr,
            displayName: _short(addr.eip55With0x),
          ));
        }
      }

      if (mounted) {
        setState(() {
          _votes = votes;
          _quorumBps = quorumBps?.toInt() ?? 0;
          _voteDurationSeconds = voteDuration?.toInt() ?? 0;
          _openInfo = {for (final i in openInfo) i.proposalId: i};
          _maxOpen = maxOpen ?? 2;
          _waitFull = waitFull ?? false;
          _proposerCap = proposerCap ?? true;
          _vetoer = vetoer;
          _cancelCooldown = cancelCooldown ?? 0;
          _memberAddresses = members;
          _memberContacts = memberContacts;
          _registeredInboxIds = inboxIds;
          _wallets = wallets;
          _parentContact = parentContact;
          _childCount = childCount;
          _childContacts = childContacts;
          _isLoading = false;
        });
      }

      // Balance (OX token) is member-gated. Fire-and-forget tail-of-flow so
      // first paint doesn't wait on the extra balanceOf call.
      if (widget.isOrgMember) {
        _loadSafeBalance();
        _loadMyDelegate();
        _loadMyCooldown();
      }
    } catch (_) {
      if (!mounted) return;
      if (!_isLoading) {
        // A silent refresh failed: keep what is on screen.
        _showSnackBar(context.l10n.groupVotingViewLoadFailed, isError: true);
        return;
      }
      setState(() {
        _error = _OrgLoadError.loadFailed;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSafeBalance() async {
    // Main Safe is auto-prepended at index 0 of PublicOSWallets.getWallets,
    // so reuse the wallet list rather than round-tripping getMainSafeAddress.
    // Matches the wallets-view convention of reading OX via
    // PublicOSTreasury.getTokenBalance (native gas-token balance is a
    // different asset and not what the user means by "Safe balance").
    final mainSafe = _wallets.where((w) => w.isMainSafe).firstOrNull;
    if (mainSafe == null) return;
    try {
      final addr = EthereumAddress.fromHex(mainSafe.addressHex);
      final results = await Future.wait<Object?>([
        PublicOSTreasury.getTokenBalance(addr),
        PublicOSGovernance.isSplitterActivated(addr),
      ]);
      if (!mounted) return;
      setState(() {
        _safeBalance = (results[0] as BigInt).toDouble() / 1e18;
        _splitterActive = results[1] as bool?;
      });
    } catch (_) {
      // Silent — the row degrades to "…".
    }
  }

  /// The splitter kinds ('activate' / 'split') that already have an open vote.
  Set<String> get _openSplitterVotes => {
        for (final v in _votes)
          if (v.status == VoteStatus.active && v.actionType == VoteActionType.executeSafeTx)
            if (v.parameters['targetAddress'] case final EthereumAddress t)
              if (v.parameters['dataParam'] case final List<int> d)
                if (PublicOSGovernance.decodeSplitterCall(t.eip55With0x, d) case final c?) c.kind,
      };

  /// What the splitter slot beside Send shows: 'activate' until the org has
  /// approved the splitter, then 'split'; nothing while that kind of vote is
  /// already open (so nobody starts a second one).
  String? get _splitterSlot {
    final active = _splitterActive;
    if (active == null || !widget.isOrgMember) return null;
    final kind = active ? 'split' : 'activate';
    return _openSplitterVotes.contains(kind) ? null : kind;
  }

  Future<void> _activateSplitter() async {
    final org = widget.contact?.publicosAddress;
    if (org == null) return;
    final l10n = context.l10n;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => _glassDialog(
        ctx,
        title: l10n.groupVotingViewSplitterActivateTitle,
        content: _dialogBody(ctx, l10n.groupVotingViewSplitterActivateBody),
        actions: [
          _dialogCancel(ctx),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.groupVotingViewStartVote)),
        ],
      ),
    );
    if (go != true || !mounted) return;
    HapticFeedback.lightImpact();
    final tx = await PublicOSGovernance.startVoteActivateSplitter(org);
    if (!mounted) return;
    if (tx != null) {
      _showSnackBar(l10n.groupVotingViewSettingVoteStarted);
      await _loadAllData();
      _loadSafeBalance();
    } else {
      _showSnackBar(PublicOS.lastError ?? l10n.groupVotingViewUnableToCastVote, isError: true);
    }
  }

  Future<void> _startSplit() async {
    final org = widget.contact?.publicosAddress;
    if (org == null) return;
    final l10n = context.l10n;
    final members = _memberAddresses.length;
    final balance = _safeBalance ?? 0;
    final ctrl = TextEditingController();
    BigInt? toRaw(String text) {
      final s = text.trim().replaceAll(',', '.');
      if (!RegExp(r'^\d*\.?\d*$').hasMatch(s) || s.isEmpty || s == '.') return null;
      final parts = s.split('.');
      var frac = parts.length > 1 ? parts[1] : '';
      if (frac.length > 18) frac = frac.substring(0, 18);
      return BigInt.parse('${parts[0].isEmpty ? '0' : parts[0]}${frac.padRight(18, '0')}');
    }

    final amount = await showDialog<BigInt>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final raw = toRaw(ctrl.text);
          final value = raw == null ? 0.0 : raw.toDouble() / 1e18;
          final ok = raw != null && raw > BigInt.zero && value <= balance && members > 0;
          final share = members > 0 ? value / members : 0.0;
          final t = GlassTokens.of(ctx);
          return _glassDialog(
            ctx,
            maxWidth: DialogWidth.m,
            title: l10n.groupVotingViewSplitTitle,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogBody(ctx, l10n.groupVotingViewSplitBody(members, _formatBalance(balance))),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontFamily: 'SpaceGrotesk', color: t.starkWhite, fontSize: 15),
                  decoration: _dialogField(ctx, l10n.groupVotingViewSplitAmountHint).copyWith(suffixText: 'OX'),
                  onChanged: (_) => setLocal(() {}),
                ),
                const SizedBox(height: 8),
                Text(
                  raw != null && value > balance
                      ? l10n.groupVotingViewSplitTooMuch
                      : l10n.groupVotingViewSplitEach(_formatBalance(share)),
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 12,
                    color: raw != null && value > balance ? Theme.of(ctx).colorScheme.error : t.textDim,
                  ),
                ),
              ],
            ),
            actions: [
              _dialogCancel(ctx),
              TextButton(
                onPressed: ok ? () => Navigator.pop(ctx, raw) : null,
                child: Text(l10n.groupVotingViewStartVote),
              ),
            ],
          );
        },
      ),
    );
    ctrl.dispose();
    if (amount == null || !mounted) return;
    HapticFeedback.lightImpact();
    final tx = await PublicOSGovernance.startVoteSplit(org, amount);
    if (!mounted) return;
    if (tx != null) {
      _showSnackBar(l10n.groupVotingViewSettingVoteStarted);
      await _loadAllData();
    } else {
      _showSnackBar(PublicOS.lastError ?? l10n.groupVotingViewUnableToCastVote, isError: true);
    }
  }

  /// The default-lane delegate the current member carries their ballot to.
  /// Self (or an unresolved read) means "voting your own weight".
  Future<void> _loadMyDelegate() async {
    final org = widget.contact?.publicosAddress?.eip55With0x;
    final me = AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;
    if (org == null || me == null) return;
    try {
      final delegatee = await PublicOSGovernance.getTagDelegatee(org, me);
      if (!mounted) return;
      // The contract returns self when not delegated — normalize that to null.
      final isSelf = delegatee != null &&
          delegatee.toLowerCase() == me.toLowerCase();
      setState(() => _myDelegatee = isSelf ? null : delegatee);
    } catch (_) {
      // Silent — the delegation row degrades to "not delegated".
    }
  }

  /// Open the same send sheet the wallets view uses, pre-seeded with this org's
  /// account + main Safe. Because the sender is an org account, the send flow
  /// starts an EXECUTE_SAFE_TX spend vote (funds move once it passes) — so on
  /// close we reload to surface the new active vote + refreshed balance.
  Future<void> _openSendSheet() async {
    final account = widget.contact?.publicosAddress;
    final mainSafe = _wallets.where((w) => w.isMainSafe).firstOrNull;
    if (account == null || mainSafe == null) return;
    HapticFeedback.lightImpact();
    // Match the checksummed (EIP-55) form the send sheet stores for org safes
    // (it seeds them from `getMainSafeAddress(...).eip55With0x`). `Wallet
    // .addressHex` is all-lowercase, and the sheet's origin match is a
    // case-sensitive `==`, so a raw addressHex would miss and fall back to the
    // user's personal main Safe.
    final safeAddress =
        EthereumAddress.fromHex(mainSafe.addressHex).eip55With0x;
    await showSendSheet(
      context: context,
      config: SendSheetConfig(
        targetMode: SendTargetMode.searchAny,
        feedFoundAtAccountAddress: account,
        originatingWalletAddress: safeAddress,
      ),
    );
    if (mounted) await _loadAllData();
  }

  Future<List<Map<String, String>>> _loadRegisteredInboxIds() async {
    if (widget.contact?.publicosAddress == null) return const [];
    try {
      final result = await PublicOSXmtp.getAllAccountInboxIds(
        widget.contact!.publicosAddress!,
      );
      if (result == null || result.inboxIds.isEmpty) return const [];
      final out = <Map<String, String>>[];
      for (var i = 0; i < result.inboxIds.length; i++) {
        out.add({
          'id': bytes32ToString(result.inboxIds[i]),
          'label': i < result.labels.length ? result.labels[i] : 'Unlabeled',
        });
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  // ─── Vote actions ─────────────────────────────────────────────────────

  bool _canUserVote(VoteHistoryItem vote) {
    if (!widget.isOrgMember || !vote.isActive) return false;
    final me = AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;
    if (me == null) return false;
    return !vote.hasVoted(me);
  }

  Future<void> _castVote(VoteHistoryItem vote, VoteSupport support) async {
    if (widget.contact?.publicosAddress == null) return;
    final l10n = context.l10n;
    setState(() {
      _busyIds.add(vote.id);
      _keptIds.add(vote.id);
    });
    try {
      // By proposal id: with several votes open, the org-keyed form refuses.
      final success = await PublicOSGovernance.castVoteWithSupport(
        widget.contact!.publicosAddress!.eip55With0x,
        support,
        proposalId: vote.proposalId,
      );
      if (success && mounted) {
        HapticFeedback.mediumImpact();
        _showSnackBar(l10n.groupVotingViewVoteRecorded);
        await _loadAllData();
        await widget.onContactRefresh?.call();
      } else if (mounted) {
        _showSnackBar(l10n.groupVotingViewUnableToCastVote, isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar(localizedError(l10n, e), isError: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(vote.id));
    }
  }

  // ─── Membership actions ───────────────────────────────────────────────

  Future<void> _openMembersSheet() async {
    HapticFeedback.lightImpact();
    final result = await showMembersSheet(
      context,
      members: _memberContacts,
      canMutate: widget.isOrgMember,
    );
    if (result == null || !mounted) return;
    if (result.requestAdd) {
      await _addMember();
    } else if (result.addressesToRemove.isNotEmpty) {
      // The sheet pops as soon as the first remove is confirmed — process
      // one address now.
      final addr = result.addressesToRemove.first;
      final contact = _memberContacts.firstWhere(
        (c) => c.publicosAddress == addr,
        orElse: () => Contact(publicosAddress: addr, displayName: _short(addr.eip55With0x)),
      );
      await _startRemoveMemberVote(contact);
    }
  }

  Future<void> _addMember() async {
    final l10n = context.l10n;
    final selectedContacts = await showPickOrgMembersSheet(
      context,
      existingMemberAddresses: _memberAddresses,
    );
    if (selectedContacts == null || selectedContacts.isEmpty) return;

    final orgAddress = widget.contact!.publicosAddress!;

    var successCount = 0;
    var alreadyMemberCount = 0;
    final failures = <String>[]; // "displayName: reason"

    for (final selected in selectedContacts) {
      if (selected.publicosAddress == null) continue;
      try {
        final isAlready = await PublicOSGovernance.isOrgMember(
          orgAddress,
          selected.publicosAddress!,
        );
        if (isAlready) {
          alreadyMemberCount++;
          continue;
        }
        await PublicOSBsp.orgManagerContract.startVote(
          (
            orgAddress: orgAddress,
            tag: Uint8List(32), // no topic
            actionType: BigInt.from(2), // ADD_MEMBER
            params: [
              selected.publicosAddress!,
              BigInt.zero,
              '',
              '',
              BigInt.zero,
              '',
              Uint8List(0),
              BigInt.zero,
            ],
          ),
          credentials: PublicOS.currentBlockchainPrivateKey!,
        );
        successCount++;
      } catch (e) {
        final raw = TxUtils.decodeRevertReason(e) ?? e.toString();
        final reason = localizedRevertReason(l10n, raw);
        failures.add('${selected.displayName}: $reason');
        // Once a vote opens on this org every subsequent startVote in this
        // batch will revert with the same reason — surface it once, stop
        // iterating. Match the raw contract phrase, not localized display text.
        if (raw.contains('Vote already active for this org')) break;
      }
    }

    if (!mounted) return;
    if (failures.isNotEmpty) {
      _showSnackBar(
        failures.length == 1
            ? failures.first
            : l10n.groupVotingViewMembersFailed(failures.length, failures.first),
        isError: true,
      );
    }
    if (alreadyMemberCount > 0 && successCount == 0 && failures.isEmpty) {
      _showSnackBar(l10n.groupVotingViewAlreadyMembers(alreadyMemberCount));
    }
    if (successCount > 0) {
      _showSnackBar(l10n.groupVotingViewVotesToAddStarted(successCount));
      _loadAllData();
    }
  }

  Future<void> _startRemoveMemberVote(Contact contact) async {
    if (contact.publicosAddress == null || _memberAddresses.length <= 1) return;
    final l10n = context.l10n;
    try {
      await PublicOSBsp.orgManagerContract.startVote(
        (
          orgAddress: widget.contact!.publicosAddress!,
          tag: Uint8List(32), // no topic
          actionType: BigInt.from(3), // REMOVE_MEMBER
          params: [
            contact.publicosAddress!,
            BigInt.zero,
            '',
            '',
            BigInt.zero,
            '',
            Uint8List(0),
            BigInt.zero,
          ],
        ),
        credentials: PublicOS.currentBlockchainPrivateKey!,
      );
      if (!mounted) return;
      _showSnackBar(l10n.groupVotingViewVoteToRemoveStarted);
      _loadAllData();
    } catch (e) {
      if (!mounted) return;
      final reason = localizedRevertReason(
        l10n,
        TxUtils.decodeRevertReason(e) ?? e.toString(),
      );
      _showSnackBar(reason, isError: true);
    }
  }

  /// Confirm, then start a vote that changes one org setting (parallel votes).
  Future<void> _confirmSettingVote(String setting, String value,
      Future<bool> Function(String org) start) async {
    final org = widget.contact?.publicosAddress?.eip55With0x;
    if (org == null) return;
    final l10n = context.l10n;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => _glassDialog(
        ctx,
        title: l10n.groupVotingViewSettingVoteTitle,
        content: _dialogBody(ctx, l10n.groupVotingViewSettingVoteBody(setting, value)),
        actions: [
          _dialogCancel(ctx),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.groupVotingViewStartVote)),
        ],
      ),
    );
    if (go != true || !mounted) return;
    HapticFeedback.lightImpact();
    final ok = await start(org);
    if (!mounted) return;
    if (ok) {
      _showSnackBar(l10n.groupVotingViewSettingVoteStarted);
      await _loadAllData();
      await widget.onContactRefresh?.call();
    } else {
      _showSnackBar(PublicOS.lastError ?? l10n.groupVotingViewUnableToCastVote, isError: true);
    }
  }

  /// Pick how many proposals may be open at once (1..5), then start the vote.
  Future<void> _pickMaxOpen() async {
    final l10n = context.l10n;
    var n = _maxOpen.clamp(1, 5);
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => _glassDialog(
          ctx,
          maxWidth: DialogWidth.m,
          title: l10n.groupVotingViewMaxOpen,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogBody(ctx, l10n.groupVotingViewMaxOpenBody),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_rounded, color: GlassTokens.of(ctx).starkWhite),
                    onPressed: n > 1 ? () => setLocal(() => n--) : null,
                  ),
                  Text('$n',
                      style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: GlassTokens.of(ctx).starkWhite)),
                  IconButton(
                    icon: Icon(Icons.add_rounded, color: GlassTokens.of(ctx).starkWhite),
                    onPressed: n < 5 ? () => setLocal(() => n++) : null,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            _dialogCancel(ctx),
            TextButton(
              onPressed: n == _maxOpen ? null : () => Navigator.pop(ctx, n),
              child: Text(l10n.groupVotingViewStartVote),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await _confirmSettingVote(l10n.groupVotingViewMaxOpen, '$picked',
        (org) => PublicOSGovernance.startVoteSetMaxOpenVotes(org, picked));
  }

  // ─── Cancel · veto · withdraw ───────────────────────────────────────────

  Future<void> _loadMyCooldown() async {
    final org = widget.contact?.publicosAddress?.eip55With0x;
    final me = AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;
    if (org == null || me == null) return;
    final until = await PublicOSGovernance.getProposerCooldownUntil(org, me);
    if (mounted) setState(() => _myCooldownUntil = until);
  }

  String? get _me => AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x.toLowerCase();

  bool _cancellable(VoteHistoryItem vote) {
    if (!vote.isActive || vote.proposalId == null) return false;
    return !(_openInfo[vote.proposalId]?.closable ?? false);
  }

  bool _canWithdraw(VoteHistoryItem vote) =>
      _cancellable(vote) && _me != null && vote.initiator.toLowerCase() == _me;

  bool _canVeto(VoteHistoryItem vote) =>
      widget.isOrgMember &&
      _cancellable(vote) &&
      _vetoer != null &&
      _vetoer!.toLowerCase() == _me &&
      vote.actionType != VoteActionType.setVetoer;

  String _durLabel(int s) {
    if (s <= 0) return context.l10n.groupVotingViewCooldownNone;
    if (s % 86400 == 0) return '${s ~/ 86400}d';
    if (s % 3600 == 0) return '${s ~/ 3600}h';
    return '${s ~/ 60}m';
  }

  String _cancelledByText(VoteHistoryItem vote) {
    final l10n = context.l10n;
    final by = vote.cancelledBy ?? '';
    final org = widget.contact;
    final (String name, String kind) = switch (vote.cancelKind) {
      CancelKind.proposer => (_delegateeName(by), l10n.groupVotingViewCancelKindProposer),
      CancelKind.vetoer => (_delegateeName(by), l10n.groupVotingViewCancelKindVetoer),
      CancelKind.org => (org?.displayName ?? _short(by), l10n.groupVotingViewCancelKindOrg),
      _ => (
          _parentContact?.publicosAddress?.eip55With0x.toLowerCase() == by.toLowerCase()
              ? _parentContact!.displayName
              : _short(by),
          l10n.groupVotingViewCancelKindAncestor
        ),
    };
    return l10n.groupVotingViewCancelledBy('$name ($kind)', vote.cancelReason ?? '');
  }

  Future<void> _runCancel(VoteHistoryItem vote, Future<bool> Function() call, String done) async {
    setState(() {
      _busyIds.add(vote.id);
      _keptIds.add(vote.id);
    });
    HapticFeedback.mediumImpact();
    final ok = await call();
    if (!mounted) return;
    _showSnackBar(ok ? done : (PublicOS.lastError ?? context.l10n.groupVotingViewUnableToCastVote), isError: !ok);
    await _loadAllData();
    if (mounted) setState(() => _busyIds.remove(vote.id));
    await widget.onContactRefresh?.call();
  }

  Future<void> _withdraw(VoteHistoryItem vote) async {
    final id = vote.proposalId;
    if (id == null) return;
    final l10n = context.l10n;
    final body = _cancelCooldown > 0
        ? '${l10n.groupVotingViewWithdrawBody} ${l10n.groupVotingViewWithdrawCooldown(_durLabel(_cancelCooldown))}'
        : l10n.groupVotingViewWithdrawBody;
    final reason = await askCancelReason(context,
        title: l10n.groupVotingViewWithdrawTitle, body: body, confirm: l10n.groupVotingViewWithdraw, destructive: true);
    if (reason == null || !mounted) return;
    await _runCancel(vote, () => PublicOSGovernance.withdrawVote(id, reason), l10n.groupVotingViewWithdrawn);
    _loadMyCooldown();
  }

  Future<void> _veto(VoteHistoryItem vote) async {
    final id = vote.proposalId;
    if (id == null) return;
    final l10n = context.l10n;
    final reason = await askCancelReason(context,
        title: l10n.groupVotingViewVetoTitle, body: l10n.groupVotingViewVetoBody, confirm: l10n.groupVotingViewVeto, destructive: true);
    if (reason == null || !mounted) return;
    await _runCancel(vote, () => PublicOSGovernance.vetoVote(id, reason), l10n.groupVotingViewVetoed);
  }

  /// Vote 58: pick an open vote here or under this org, give a reason, start the vote.
  Future<void> _openCancelPicker() async {
    final org = widget.contact;
    if (org?.publicosAddress == null) return;
    HapticFeedback.lightImpact();
    final pick = await showCancelVotePickerSheet(context, org: org!);
    if (pick == null || !mounted) return;
    final l10n = context.l10n;
    final reason = await askCancelReason(context,
        title: l10n.groupVotingViewCancelVoteTitle,
        body: l10n.groupVotingViewCancelVoteBody(pick.owner.displayName, '${pick.vote.proposalId}'),
        confirm: l10n.groupVotingViewStartVote);
    if (reason == null || !mounted) return;
    final ok = await PublicOSGovernance.startVoteCancelVote(
        org.publicosAddress!.eip55With0x, pick.vote.proposalId, reason);
    if (!mounted) return;
    if (ok) {
      _showSnackBar(l10n.groupVotingViewSettingVoteStarted);
      await _loadAllData();
      await widget.onContactRefresh?.call();
    } else {
      _showSnackBar(PublicOS.lastError ?? l10n.groupVotingViewUnableToCastVote, isError: true);
    }
  }

  /// Vote 57: pick one member (or nobody) as the org's vetoer.
  Future<void> _pickVetoer() async {
    final l10n = context.l10n;
    const none = '';
    final current = _vetoer?.toLowerCase() ?? none;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => _glassDialog(
        ctx,
        maxWidth: DialogWidth.m,
        title: l10n.groupVotingViewVetoer,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogBody(ctx, l10n.groupVotingViewVetoerBody),
              if (!_waitFull)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l10n.groupVotingViewVetoerAutoRun,
                      style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 12,
                          height: 1.4,
                          color: GlassTokens.of(ctx).fallbackAccent)),
                ),
              const SizedBox(height: 12),
              _dialogOption(ctx, value: none, selected: current == none, label: l10n.groupVotingViewVetoerNone),
              for (final c in _memberContacts)
                if (c.publicosAddress != null)
                  _dialogOption(
                    ctx,
                    value: c.publicosAddress!.eip55With0x,
                    selected: c.publicosAddress!.eip55With0x.toLowerCase() == current,
                    label: c.displayName,
                    leading: GlassContactIcon(contact: c, size: 24),
                  ),
            ],
          ),
        ),
        actions: [_dialogCancel(ctx)],
      ),
    );
    if (picked == null || !mounted || picked.toLowerCase() == current) return;
    final name = picked == none ? l10n.groupVotingViewVetoerNone : _delegateeName(picked);
    await _confirmSettingVote(l10n.groupVotingViewVetoer, name,
        (org) => PublicOSGovernance.startVoteSetVetoer(org, picked == none ? null : EthereumAddress.fromHex(picked)));
  }

  /// Vote 59: how long a member waits to propose again after a withdraw.
  Future<void> _pickCooldown() async {
    final l10n = context.l10n;
    const options = [0, 3600, 86400, 172800, 604800, 2592000];
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => _glassDialog(
        ctx,
        maxWidth: DialogWidth.m,
        title: l10n.groupVotingViewCooldown,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogBody(ctx, l10n.groupVotingViewCooldownBody),
              const SizedBox(height: 12),
              for (final s in options)
                _dialogOption(ctx, value: s, selected: s == _cancelCooldown, label: _durLabel(s)),
            ],
          ),
        ),
        actions: [_dialogCancel(ctx)],
      ),
    );
    if (picked == null || !mounted || picked == _cancelCooldown) return;
    await _confirmSettingVote(l10n.groupVotingViewCooldown, _durLabel(picked),
        (org) => PublicOSGovernance.startVoteSetCancelCooldown(org, picked));
  }

  /// Run a passed proposal: a wait-mode vote after its period, or a retry of a
  /// passed vote whose last run failed. Any member may (`OrgManager.execute`).
  Future<void> _executeVote(VoteHistoryItem vote) async {
    final id = vote.proposalId;
    if (id == null) return;
    final l10n = context.l10n;
    HapticFeedback.mediumImpact();
    setState(() {
      _busyIds.add(vote.id);
      _keptIds.add(vote.id);
    });
    final ok = await PublicOSGovernance.executeVote(id);
    if (!mounted) return;
    _showSnackBar(ok ? l10n.groupVotingViewExecuted : l10n.groupVotingViewExecuteFailed, isError: !ok);
    await _loadAllData();
    if (mounted) setState(() => _busyIds.remove(vote.id));
    await widget.onContactRefresh?.call();
  }

  Future<void> _startProposal(ManagementVoteAction action) async {
    if (widget.contact == null) return;
    HapticFeedback.lightImpact();
    final ok = await showProposalFormSheet(
      context,
      group: widget.contact!,
      action: action,
    );
    if (ok == true) {
      await _loadAllData();
      await widget.onContactRefresh?.call();
    }
  }

  Future<void> _openChildrenSheet() async {
    if (widget.contact?.publicosAddress == null) return;
    HapticFeedback.lightImpact();
    await showChildrenSheet(
      context,
      parent: widget.contact!,
      initialChildren: _childContacts,
      totalChildCount: _childCount,
      canVote: widget.isOrgMember,
    );
    // A child-lock vote may have started from the sheet: repaint in place.
    if (mounted) _loadAllData();
  }

  void _showInboxIdsSheet() async {
    if (widget.contact?.publicosAddress == null) return;
    final changed = await showManageGroupInboxIdsSheet(
      context,
      orgAddress: widget.contact!.publicosAddress!,
      groupName: widget.contact!.displayName,
    );
    if (changed == true) _loadAllData();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final tokens = GlassTokens.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.fixed,
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : tokens.surfaceElevated,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.contact?.isOrgAccount != true) {
      return _NotGroupState();
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final tokens = GlassTokens.of(context);

    if (_isLoading) {
      return const Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: PixelRainLoadingWidget(size: 40),
        ),
      );
    }
    if (_error != null) {
      final l10n = context.l10n;
      final msg = _error == _OrgLoadError.invalidAddress
          ? l10n.groupVotingViewInvalidGroupAddress
          : l10n.groupVotingViewLoadFailed;
      return _ErrorState(error: msg, onRetry: () => _loadAllData(silent: false));
    }

    // Parallel votes: up to five open at once, newest first.
    final activeVotes = _votes.where((v) => v.isActive).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final pastVotes = _votes.where((v) => !v.isActive).toList();
    // Cards on screen: open votes + the ones decided during this visit, which
    // keep their place.
    final cardVotes = _votes
        .where((v) => v.isActive || _keptIds.contains(v.id))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    // Then, at the bottom, everything else that ended in the last 24 hours.
    DateTime endedAt(VoteHistoryItem v) => v.endTime ?? v.expirationTime ?? v.startTime;
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final recentVotes = _votes
        .where((v) =>
            !v.isActive && !_keptIds.contains(v.id) && endedAt(v).isAfter(cutoff))
        .toList()
      ..sort((a, b) => endedAt(b).compareTo(endedAt(a)));

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: tokens.starkWhite,
      backgroundColor: tokens.surfaceElevated,
      edgeOffset: widget.topInset,
      child: ListView(
        controller: _outerController,
        padding: EdgeInsets.only(top: 4 + widget.topInset, bottom: 32),
        children: [
          // DESKTOP DELTA: the RefreshIndicator above is a PULL
          // gesture — a mouse cannot trigger it, so without this the view has
          // no way to reload after a vote is cast elsewhere. Right-aligned so
          // it reads as chrome, not as one of the hero tiles.
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 2),
              child: IconButton(
                tooltip: 'Refresh',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.refresh_rounded,
                    size: 18, color: tokens.textDim),
                onPressed: _loadAllData,
              ),
            ),
          ),
          // Hero row — three dense tiles, headline facts at first paint.
          // Members lives outside every section because membership is the
          // headline of the org; Parent + Children sit alongside as the
          // hierarchy snapshot. Each tile is read-display + tap-to-open-sheet.
          _HierarchyHeroRow(
            memberCount: _memberAddresses.length,
            memberContacts: _memberContacts,
            onMembersTap: _openMembersSheet,
            parentContact: _parentContact,
            // Tap on parent tile is a no-op while there's no mutation
            // surface yet (no Request / Cancel buttons in this pass).
            onParentTap: null,
            childCount: _childCount,
            childContacts: _childContacts,
            onChildrenTap: _childCount > 0 ? _openChildrenSheet : null,
          ),
          if (widget.isOrgMember) _mainSafeTile(tokens),
          if (_splitterSlot case final slot?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _SplitterButton(
                tokens: tokens,
                label: slot == 'split'
                    ? context.l10n.groupVotingViewSplit
                    : context.l10n.groupVotingViewSplitterActivate,
                onTap: slot == 'split' ? _startSplit : _activateSplitter,
              ),
            ),
          _votingSection(tokens, activeVotes, pastVotes, cardVotes, recentVotes),
          _walletsSection(tokens),
          _recordsSection(tokens),
          _inboxIdsSection(tokens),
        ],
      ),
    );
  }


  /// Slim main-Safe tile under the members hero. Same 1/3 left-column width;
  /// member-gated upstream. Left icon, "Main Safe" + truncated address,
  /// trailing OX balance.
  Widget _mainSafeTile(GlassTokens tokens) {
    final mainSafe = _wallets.where((w) => w.isMainSafe).firstOrNull;
    final addrShort = mainSafe == null ? '…' : _short(mainSafe.addressHex);
    final balance = _safeBalance;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tokens.glassFill,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.shield_outlined,
                color: tokens.connectedAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.groupVotingViewMainSafe,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.starkWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        addrShort,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: tokens.textDim,
                          fontSize: 11,
                          height: 1.1,
                        ),
                      ),
                      if (mainSafe != null) ...[
                        const SizedBox(width: 6),
                        InkResponse(
                          radius: 14,
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: mainSafe.addressHex),
                            );
                            HapticFeedback.selectionClick();
                            _showSnackBar(context.l10n.groupVotingViewAddressCopied);
                          },
                          child: Icon(
                            Icons.copy_rounded,
                            size: 12,
                            color: tokens.textDim,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (mainSafe != null) ...[
              const SizedBox(width: 8),
              _SendButton(tokens: tokens, onTap: _openSendSheet),
            ],
            const SizedBox(width: 10),
            _AnimatedBalance(
              value: balance,
              suffix: ' OX',
              format: _formatBalance,
              style: TextStyle(
                fontFamily: 'monospace',
                color: tokens.starkWhite,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trailingNumber(GlassTokens tokens, String value, [String sub = '']) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: tokens.starkWhite,
          ),
        ),
        if (sub.isNotEmpty)
          Text(
            sub,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: tokens.textDim,
            ),
          ),
      ],
    );
  }

  String _formatBalance(double v) {
    if (v == 0) return '0';
    if (v >= 1000) return v.toStringAsFixed(0);
    if (v >= 1) return v.toStringAsFixed(2);
    return v.toStringAsFixed(4);
  }

  // ─── Section: Voting ──────────────────────────────────────────────────

  Widget _votingSection(
    GlassTokens tokens,
    List<VoteHistoryItem> activeVotes,
    List<VoteHistoryItem> pastVotes,
    List<VoteHistoryItem> cardVotes,
    List<VoteHistoryItem> recentVotes,
  ) {
    Widget card(VoteHistoryItem vote) => _LiveVoteCard(
          key: ValueKey('vote-${vote.id}'),
          tokens: tokens,
          vote: vote,
          info: vote.proposalId == null ? null : _openInfo[vote.proposalId],
          members: _memberContacts,
          canVote: _canUserVote(vote),
          busy: _busyIds.contains(vote.id),
          onCastSupport: (support) => _castVote(vote, support),
          onExecute: widget.isOrgMember ? () => _executeVote(vote) : null,
          onWithdraw: _canWithdraw(vote) ? () => _withdraw(vote) : null,
          onVeto: _canVeto(vote) ? () => _veto(vote) : null,
          cancelledBy: vote.isCancelled ? _cancelledByText(vote) : null,
          safeBalance: _safeBalance,
          now: _OrgNow(
            quorumBps: _quorumBps,
            voteDurationSeconds: _voteDurationSeconds,
            maxOpen: _maxOpen,
            waitFull: _waitFull,
            proposerCap: _proposerCap,
            cancelCooldown: _cancelCooldown,
            records: widget.contact?.records ?? const [],
          ),
          onRosterTap: () => showVotersSheet(
            context,
            vote: vote,
            members: _memberContacts,
          ),
        );
    return _Section(
      tokens: tokens,
      icon: Icons.how_to_vote_outlined,
      title: context.l10n.groupVotingViewVoting,
      open: _openGroup == 'votes',
      onToggle: () => _toggleGroup('votes'),
      pill: activeVotes.isNotEmpty
          ? context.l10n.groupVotingViewOpenPill(activeVotes.length)
          : null,
      pillLive: true,
      children: [
        // Vote cancel: this member withdrew a vote and is in the org's cooldown.
        if (_myCooldownUntil case final until?)
          _SettingsRow(
            tokens: tokens,
            icon: Icons.hourglass_top_rounded,
            title: context.l10n.groupVotingViewInCooldown(
                '${MaterialLocalizations.of(context).formatShortDate(until.toLocal())} '
                '${TimeOfDay.fromDateTime(until.toLocal()).format(context)}'),
          ),
        for (final vote in cardVotes) ...[
          card(vote),
          const SizedBox(height: 8),
        ],
        // Decided in the last 24 hours, at the very bottom.
        if (recentVotes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
            child: Text(
              context.l10n.groupVotingViewRecent,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: tokens.textDim,
              ),
            ),
          ),
          for (final vote in recentVotes) ...[
            card(vote),
            const SizedBox(height: 8),
          ],
        ],
        _SettingsRow(
          tokens: tokens,
          icon: Icons.history_rounded,
          title: context.l10n.groupVotingViewActionHistory,
          subtitle: pastVotes.isEmpty
              ? context.l10n.historySheetNoVotesWeeks(1)
              : context.l10n.groupVotingViewPastProposals,
          trailing: _trailingNumber(tokens, '${pastVotes.length}'),
          onTap: () => showHistorySheet(
                context,
                orgAddress: widget.contact!.publicosAddress!.eip55With0x,
                history: pastVotes,
                since: _historySince,
              ),
        ),
        // Your ballot delegate (default lane). Member-gated.
        if (widget.isOrgMember)
          _SettingsRow(
            tokens: tokens,
            icon: _myDelegatee == null
                ? Icons.person_outline_rounded
                : Icons.how_to_reg_rounded,
            title: context.l10n.groupVotingViewDelegate,
            subtitle: _myDelegatee == null
                ? context.l10n.groupVotingViewDelegateNone
                : context.l10n.groupVotingViewDelegateTo(_delegateeName(_myDelegatee!)),
            trailing: Icon(Icons.chevron_right_rounded, color: tokens.textDim, size: 20),
            onTap: _openDelegateSheet,
          ),
        // Governance knobs — quorum + vote duration (org self-service, 58/59).
        _SettingsRow(
          tokens: tokens,
          icon: Icons.percent_rounded,
          title: context.l10n.groupVotingViewQuorum,
          subtitle: context.l10n.groupVotingViewQuorumSubtitle,
          trailing: _trailingNumber(tokens, '${(_quorumBps / 100).round()}', '%'),
          onTap: widget.isOrgMember
              ? () => _startProposal(ManagementVoteAction.setQuorumBps)
              : null,
        ),
        _SettingsRow(
          tokens: tokens,
          icon: Icons.timer_outlined,
          title: context.l10n.groupVotingViewVoteDuration,
          subtitle: context.l10n.groupVotingViewVoteDurationSubtitle,
          trailing: _trailingNumber(
              tokens, '${(_voteDurationSeconds / 3600).round()}', 'h'),
          onTap: widget.isOrgMember
              ? () => _startProposal(ManagementVoteAction.setVoteDuration)
              : null,
        ),
        // Parallel votes: three more org knobs, each a vote.
        _SettingsRow(
          tokens: tokens,
          icon: Icons.layers_outlined,
          title: context.l10n.groupVotingViewMaxOpen,
          subtitle: context.l10n.groupVotingViewMaxOpenSubtitle,
          trailing: _trailingNumber(tokens, '$_maxOpen'),
          onTap: widget.isOrgMember ? _pickMaxOpen : null,
        ),
        _SettingsRow(
          tokens: tokens,
          icon: Icons.hourglass_bottom_rounded,
          title: context.l10n.groupVotingViewWaitFull,
          subtitle: context.l10n.groupVotingViewWaitFullSubtitle,
          trailing: _trailingNumber(tokens,
              _waitFull ? context.l10n.groupVotingViewOn : context.l10n.groupVotingViewOff),
          onTap: widget.isOrgMember
              ? () => _confirmSettingVote(
                    context.l10n.groupVotingViewWaitFull,
                    !_waitFull ? context.l10n.groupVotingViewOn : context.l10n.groupVotingViewOff,
                    (org) => PublicOSGovernance.startVoteSetWaitFullPeriod(org, !_waitFull),
                  )
              : null,
        ),
        _SettingsRow(
          tokens: tokens,
          icon: Icons.person_pin_outlined,
          title: context.l10n.groupVotingViewProposerCap,
          subtitle: context.l10n.groupVotingViewProposerCapSubtitle,
          trailing: _trailingNumber(tokens,
              _proposerCap ? context.l10n.groupVotingViewOn : context.l10n.groupVotingViewOff),
          onTap: widget.isOrgMember
              ? () => _confirmSettingVote(
                    context.l10n.groupVotingViewProposerCap,
                    !_proposerCap ? context.l10n.groupVotingViewOn : context.l10n.groupVotingViewOff,
                    (org) => PublicOSGovernance.startVoteSetProposerCap(org, !_proposerCap),
                  )
              : null,
        ),
        // Vote cancel: the vetoer and the withdraw cooldown, each a vote,
        // and the cancel-a-vote picker (vote 58).
        _SettingsRow(
          tokens: tokens,
          icon: Icons.gavel_rounded,
          title: context.l10n.groupVotingViewVetoer,
          subtitle: _vetoer != null && !_waitFull
              ? context.l10n.groupVotingViewVetoerAutoRun
              : context.l10n.groupVotingViewVetoerSubtitle,
          trailing: Text(
            _vetoer == null ? context.l10n.groupVotingViewVetoerNone : _delegateeName(_vetoer!),
            style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 13, fontWeight: FontWeight.w700, color: tokens.starkWhite),
          ),
          onTap: widget.isOrgMember ? _pickVetoer : null,
        ),
        _SettingsRow(
          tokens: tokens,
          icon: Icons.hourglass_top_rounded,
          title: context.l10n.groupVotingViewCooldown,
          subtitle: context.l10n.groupVotingViewCooldownSubtitle,
          trailing: _trailingNumber(tokens, _durLabel(_cancelCooldown)),
          onTap: widget.isOrgMember ? _pickCooldown : null,
        ),
        if (widget.isOrgMember)
          _SettingsRow(
            tokens: tokens,
            icon: Icons.block_rounded,
            title: context.l10n.groupVotingViewCancelAVote,
            subtitle: context.l10n.groupVotingViewCancelAVoteSubtitle,
            trailing: Icon(Icons.chevron_right_rounded, color: tokens.textDim, size: 20),
            onTap: _openCancelPicker,
          ),
      ],
    );
  }

  /// Display name for a delegatee address, resolved off the member roster.
  String _delegateeName(String address) {
    final match = _memberContacts.firstWhere(
      (c) => c.publicosAddress?.eip55With0x.toLowerCase() == address.toLowerCase(),
      orElse: () => Contact(displayName: _short(address)),
    );
    return match.displayName;
  }

  Future<void> _openDelegateSheet() async {
    final me = AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;
    if (widget.contact?.publicosAddress == null || me == null) return;
    final changed = await showDelegateVoteSheet(
      context,
      orgAddress: widget.contact!.publicosAddress!.eip55With0x,
      myAddress: me,
      currentDelegatee: _myDelegatee,
      members: _memberContacts.where((c) {
        final a = c.publicosAddress?.eip55With0x.toLowerCase();
        return a != null && a != me.toLowerCase();
      }).toList(),
    );
    if (changed == true) {
      await _loadMyDelegate();
    }
  }

  // ─── Section: Wallets ─────────────────────────────────────────────────

  Widget _walletsSection(GlassTokens tokens) {
    return _Section(
      tokens: tokens,
      icon: Icons.account_balance_wallet_outlined,
      title: context.l10n.groupVotingViewWallets,
      open: _openGroup == 'wallets',
      onToggle: () => _toggleGroup('wallets'),
      pill: _wallets.isEmpty ? null : '${_wallets.length}',
      children: [
        if (_wallets.isEmpty)
          _SettingsRow(
            tokens: tokens,
            icon: Icons.account_balance_wallet_outlined,
            title: context.l10n.groupVotingViewNoWallets,
            subtitle: context.l10n.groupVotingViewNoWalletsSubtitle,
          )
        else
          for (final w in _wallets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _walletRow(tokens, w),
            ),
        if (widget.isOrgMember) ...[
          const SizedBox(height: 4),
          _PillRow(
            tokens: tokens,
            children: [
              _Pill(
                tokens: tokens,
                icon: Icons.add_rounded,
                label: context.l10n.groupVotingViewAddWallet,
                onTap: () =>
                    _startProposal(ManagementVoteAction.registerAdditionalWallet),
              ),
              _Pill(
                tokens: tokens,
                icon: Icons.remove_rounded,
                label: context.l10n.groupVotingViewRemove,
                danger: true,
                onTap: _wallets.where((w) => !w.isMainSafe).isEmpty
                    ? null
                    : () => _startProposal(ManagementVoteAction.removeWallet),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _walletRow(GlassTokens tokens, Wallet w) {
    final title = w.label.isNotEmpty
        ? w.label
        : (w.isMainSafe
            ? context.l10n.groupVotingViewMainSafe
            : context.l10n.groupVotingViewProtocolWallet(w.protocol));
    final subtitle = w.protocol == PublicOSWallets.protoEvm
        ? '${w.protocol} · ${_short(w.addressHex)}'
        : w.toCaip10();
    final tag = w.isMainSafe
        ? context.l10n.groupVotingViewTagPrimary
        : (w.walletType.name == 'safe' ? 'safe' : 'eoa');

    return _SettingsRow(
      tokens: tokens,
      icon: w.isMainSafe
          ? Icons.shield_outlined
          : Icons.account_balance_wallet_outlined,
      title: title,
      subtitle: subtitle,
      mono: true,
      trailing: Text(
        tag,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: tokens.textDim,
        ),
      ),
    );
  }

  // ─── Section: Records ─────────────────────────────────────────────────

  Widget _recordsSection(GlassTokens tokens) {
    final records = widget.contact?.records ?? const [];
    if (records.isEmpty) {
      return _Section(
        tokens: tokens,
        icon: Icons.description_outlined,
        title: context.l10n.groupVotingViewRecords,
        open: _openGroup == 'records',
        onToggle: () => _toggleGroup('records'),
        children: [
          _SettingsRow(
            tokens: tokens,
            icon: Icons.description_outlined,
            title: context.l10n.groupVotingViewNoRecords,
            subtitle: context.l10n.groupVotingViewNoRecordsSubtitle,
          ),
        ],
      );
    }
    return _Section(
      tokens: tokens,
      icon: Icons.description_outlined,
      title: context.l10n.groupVotingViewRecords,
      open: _openGroup == 'records',
      onToggle: () => _toggleGroup('records'),
      pill: '${records.length}',
      children: [
        // Scroll chaining: forward this capped box's overscroll to the outer
        // management list, so when the records hit an end (or the list is short
        // enough that it can't scroll at all) a continued drag scrolls the page
        // instead of dead-ending here. The browser's collapse listener ignores
        // this nested scroller (depth != 0) and only reacts to the resulting
        // outer scroll, so the avatar does not jump to the records' top.
        NotificationListener<OverscrollNotification>(
          onNotification: (n) {
            if (_outerController.hasClients) {
              final pos = _outerController.position;
              final target = (_outerController.offset + n.overscroll)
                  .clamp(pos.minScrollExtent, pos.maxScrollExtent);
              if (target != _outerController.offset) {
                _outerController.jumpTo(target);
              }
            }
            return true;
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final r in records)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _RecordRow(
                        tokens: tokens,
                        record: r,
                        onCopy: () {
                          Clipboard.setData(ClipboardData(text: r.value));
                          _showSnackBar(context.l10n.groupVotingViewValueCopied);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Section: Inbox IDs ───────────────────────────────────────────────

  Widget _inboxIdsSection(GlassTokens tokens) {
    return _Section(
      tokens: tokens,
      icon: Icons.inbox_outlined,
      title: context.l10n.groupVotingViewInboxIds,
      open: _openGroup == 'inboxes',
      onToggle: () => _toggleGroup('inboxes'),
      pill: _registeredInboxIds.isEmpty ? null : '${_registeredInboxIds.length}',
      children: [
        _SettingsRow(
          tokens: tokens,
          icon: Icons.settings_outlined,
          title: context.l10n.groupVotingViewManageInboxIds,
          subtitle: context.l10n.groupVotingViewManageInboxIdsSubtitle,
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: tokens.textDim,
            size: 20,
          ),
          onTap: widget.isOrgMember ? _showInboxIdsSheet : null,
        ),
      ],
    );
  }

  String _short(String addr) {
    if (addr.length < 10) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Layout primitives (section header + settings row + pill row)
// ═══════════════════════════════════════════════════════════════════════

/// A collapsible group:
/// the Settings / Account Center accordion. One group open at a time (the
/// screen's `_openGroup`), the whole header row toggles, the chevron turns
/// 90°, and what matters sits in a pill on the right ([pill]: accent for
/// something live, dim for a plain count).
class _Section extends StatelessWidget {
  final GlassTokens tokens;
  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool open;
  final VoidCallback onToggle;
  final String? pill;
  final bool pillLive;

  const _Section({
    required this.tokens,
    required this.icon,
    required this.title,
    required this.children,
    required this.open,
    required this.onToggle,
    this.pill,
    this.pillLive = false,
  });

  @override
  Widget build(BuildContext context) {
    final pillColor = pillLive ? tokens.connectedAccent : tokens.textDim;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GroupHeader(
            icon: icon,
            title: title,
            open: open,
            onTap: onToggle,
            trailing: pill == null
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: pillColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: pillColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      pill!,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: pillColor,
                      ),
                    ),
                  ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// The tappable header of a collapsible group, copied from the Account Center
/// (itself from the Services page). Grey glyphs that turn white on hover or
/// while open; the title stays white. Teal is never used here: open is a
/// place, not a state.
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

class _SettingsRow extends StatelessWidget {
  final GlassTokens tokens;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool mono;

  const _SettingsRow({
    required this.tokens,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.trailing,
    this.onTap,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(12),
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
              color: tokens.glassFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Icon(icon, color: tokens.connectedAccent, size: 18),
          ),
          const SizedBox(width: 12),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: mono ? 'monospace' : 'SpaceGrotesk',
                      color: tokens.textDim,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// Glass row for a single Record. Collapsed: key + truncated value preview +
/// chevron. Expanded (tap to toggle): full value as monospace block, type
/// chip, expiration if non-default, and a Copy button.
class _RecordRow extends StatefulWidget {
  final GlassTokens tokens;
  final Record record;
  final VoidCallback onCopy;

  const _RecordRow({
    required this.tokens,
    required this.record,
    required this.onCopy,
  });

  @override
  State<_RecordRow> createState() => _RecordRowState();
}

class _RecordRowState extends State<_RecordRow> {
  bool _expanded = false;

  String _typeLabel(AppLocalizations l10n, RecordType t) {
    switch (t) {
      case RecordType.profile:
        return l10n.groupVotingViewRecordTypeProfile;
      case RecordType.settings:
        return l10n.groupVotingViewRecordTypeSettings;
      case RecordType.router:
        return l10n.groupVotingViewRecordTypeRouter;
      case RecordType.custom:
        return l10n.groupVotingViewRecordTypeCustom;
      case RecordType.system:
        return l10n.groupVotingViewRecordTypeSystem;
    }
  }

  String _shortPreview(String v) {
    final oneLine = v.replaceAll('\n', ' ').trim();
    return oneLine.length > 48 ? '${oneLine.substring(0, 48)}…' : oneLine;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final r = widget.record;

    return Container(
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsed header — always visible.
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: tokens.glassFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tokens.borderSubtle),
                      ),
                      child: Icon(
                        Icons.text_snippet_outlined,
                        color: tokens.connectedAccent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.key,
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              color: tokens.starkWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _shortPreview(r.value),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: tokens.textDim,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: tokens.textDim,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expanded body.
          if (_expanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Divider(color: tokens.borderSubtle, height: 1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _MetaChip(
                          tokens: tokens,
                          label: _typeLabel(context.l10n, r.type)),
                      if (r.isExpired) ...[
                        const SizedBox(width: 6),
                        _MetaChip(
                          tokens: tokens,
                          label: context.l10n.groupVotingViewExpired,
                          accent: Theme.of(context).colorScheme.error,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tokens.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: tokens.borderSubtle),
                    ),
                    child: SelectableText(
                      r.value,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: tokens.starkWhite,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: widget.onCopy,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.glassFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: tokens.borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: tokens.textDim,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.l10n.groupVotingViewCopy,
                                style: TextStyle(
                                  fontFamily: 'SpaceGrotesk',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  color: tokens.starkWhite,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Balance text that slides up from the bottom + fades in. Animates on
/// first build and again when the value transitions from null → loaded.
class _AnimatedBalance extends StatefulWidget {
  final double? value;
  final String suffix;
  final String Function(double) format;
  final TextStyle style;

  const _AnimatedBalance({
    required this.value,
    required this.suffix,
    required this.format,
    required this.style,
  });

  @override
  State<_AnimatedBalance> createState() => _AnimatedBalanceState();
}

class _AnimatedBalanceState extends State<_AnimatedBalance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void didUpdateWidget(covariant _AnimatedBalance old) {
    super.didUpdateWidget(old);
    if (old.value == null && widget.value != null) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.value == null
        ? '…${widget.suffix}'
        : '${widget.format(widget.value!)}${widget.suffix}';
    return ClipRect(
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _ctrl,
          child: Text(text, style: widget.style),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final GlassTokens tokens;
  final String label;
  final Color? accent;

  const _MetaChip({
    required this.tokens,
    required this.label,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final fg = accent ?? tokens.textDim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent != null
            ? accent!.withValues(alpha: 0.10)
            : tokens.glassFill,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: accent != null
              ? accent!.withValues(alpha: 0.35)
              : tokens.borderSubtle,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: fg,
        ),
      ),
    );
  }
}

class _PillRow extends StatelessWidget {
  final GlassTokens tokens;
  final List<Widget> children;
  const _PillRow({required this.tokens, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final GlassTokens tokens;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  const _Pill({
    required this.tokens,
    required this.icon,
    required this.label,
    this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final fg = disabled
        ? tokens.textDim
        : (danger ? tokens.fallbackAccent : tokens.starkWhite);
    final border = disabled
        ? tokens.borderSubtle
        : (danger
            ? tokens.fallbackAccent.withValues(alpha: 0.5)
            : tokens.borderMedium);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: tokens.glassFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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

// ═══════════════════════════════════════════════════════════════════════
// Hero row — Members | Parent | Children (three equal thirds)
// ═══════════════════════════════════════════════════════════════════════

/// Headline hero — three dense tiles, top of screen, no section chrome.
/// Members + Parent + Children share the same vertical rhythm so the three
/// tiles read as one unit even though their content shapes differ.
///
/// Mutation surfaces for hierarchy (Request / Cancel / Accept / Release)
/// are not built here.
// Hero row geometry — shared across all three columns so cells line up.
const double _kHeroRow1Height = 42; // number text OR avatar
const double _kHeroRow2Height = 18; // label OR parent display-name
const double _kHeroRow3Height = 36; // carousel OR "parent" label
const double _kHeroGap12 = 2;       // tight — "really close to the number"
const double _kHeroGap23 = 10;

/// Three-column hero row. Members always renders. Parent / Children are
/// **omitted entirely** when absent (no dashed empty-state, no label, no
/// dim count) so the layout reflects only what actually exists. Empty slots
/// remain reserved as 1/3-width sentinels so Members stays anchored to the
/// left and Children to the right regardless of which middle slot exists.
class _HierarchyHeroRow extends StatelessWidget {
  final int memberCount;
  final List<Contact> memberContacts;
  final VoidCallback onMembersTap;

  final Contact? parentContact;
  final VoidCallback? onParentTap;

  final int childCount;
  final List<Contact> childContacts;
  final VoidCallback? onChildrenTap;

  const _HierarchyHeroRow({
    required this.memberCount,
    required this.memberContacts,
    required this.onMembersTap,
    required this.parentContact,
    required this.onParentTap,
    required this.childCount,
    required this.childContacts,
    required this.onChildrenTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasParent = parentContact != null;
    final hasChildren = childCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _MembersHero(
              count: memberCount,
              contacts: memberContacts,
              onTap: onMembersTap,
            ),
          ),
          Expanded(
            child: hasParent
                ? _ParentHero(parent: parentContact!, onTap: onParentTap)
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: hasChildren
                ? _ChildrenHero(
                    count: childCount,
                    contacts: childContacts,
                    onTap: onChildrenTap,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Format a count compactly for hero tiles (`12k`, `1.4M`, etc.).
String _formatHeroCount(int n) {
  if (n < 10000) return '$n';
  if (n < 1000000) {
    final k = n / 1000;
    final str = k >= 100 ? k.toStringAsFixed(0) : k.toStringAsFixed(1);
    return '${str.endsWith('.0') ? str.substring(0, str.length - 2) : str}k';
  }
  final m = n / 1000000;
  final str = m >= 100 ? m.toStringAsFixed(0) : m.toStringAsFixed(1);
  return '${str.endsWith('.0') ? str.substring(0, str.length - 2) : str}M';
}

/// Wraps a 3-row hero tile (number/avatar → label/name → carousel/label) in
/// a uniform-height shell so cells align horizontally across columns.
Widget _heroSlots({
  required Widget row1,
  required Widget row2,
  required Widget row3,
  VoidCallback? onTap,
}) {
  final body = Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(height: _kHeroRow1Height, child: Center(child: row1)),
      const SizedBox(height: _kHeroGap12),
      SizedBox(height: _kHeroRow2Height, child: Center(child: row2)),
      const SizedBox(height: _kHeroGap23),
      SizedBox(height: _kHeroRow3Height, child: row3),
    ],
  );
  if (onTap == null) return body;
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: body,
    ),
  );
}

/// Members tile — number / "members" / carousel.
class _MembersHero extends StatelessWidget {
  final int count;
  final List<Contact> contacts;
  final VoidCallback onTap;

  const _MembersHero({
    required this.count,
    required this.contacts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return _heroSlots(
      onTap: onTap,
      row1: _HeroNumber(
        value: _formatHeroCount(count),
        tokens: tokens,
      ),
      row2: _HeroLabel(text: context.l10n.groupVotingViewMembers, tokens: tokens),
      row3: MembersStack(
        tokens: tokens,
        contacts: contacts,
        onTap: onTap,
      ),
    );
  }
}

/// Parent tile — avatar / display name / "parent" label. Caller guards on
/// `parent != null`, so there's no empty state to render here.
class _ParentHero extends StatelessWidget {
  final Contact parent;
  final VoidCallback? onTap;

  const _ParentHero({required this.parent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return _heroSlots(
      onTap: onTap,
      row1: GlassContactIcon(contact: parent, size: 36),
      row2: Text(
        parent.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: tokens.starkWhite,
        ),
      ),
      row3: Center(
          child: _HeroLabel(
              text: context.l10n.groupVotingViewParent, tokens: tokens)),
    );
  }
}

/// Children tile — count / "children" / carousel. Caller guards on
/// `childCount > 0`, so there's no empty state to render here.
class _ChildrenHero extends StatelessWidget {
  final int count;
  final List<Contact> contacts;
  final VoidCallback? onTap;

  const _ChildrenHero({
    required this.count,
    required this.contacts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return _heroSlots(
      onTap: onTap,
      row1: _HeroNumber(
        value: _formatHeroCount(count),
        tokens: tokens,
      ),
      row2: _HeroLabel(text: context.l10n.groupVotingViewChildren, tokens: tokens),
      row3: MembersStack(
        tokens: tokens,
        contacts: contacts,
        onTap: onTap ?? () {},
      ),
    );
  }
}

class _HeroNumber extends StatelessWidget {
  final String value;
  final GlassTokens tokens;

  const _HeroNumber({
    required this.value,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: tokens.starkWhite,
        height: 1.0,
        letterSpacing: -1.0,
      ),
    );
  }
}

class _HeroLabel extends StatelessWidget {
  final String text;
  final GlassTokens tokens;
  const _HeroLabel({required this.text, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: tokens.textDim,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Live Vote card
// ═══════════════════════════════════════════════════════════════════════

class _LiveVoteCard extends StatelessWidget {
  final GlassTokens tokens;
  final VoteHistoryItem vote;
  /// The engine's live view of this proposal (passed / executable); null when
  /// the read missed — then no status line and no RUN button.
  final ActiveVoteInfo? info;
  final List<Contact> members;
  final bool canVote;
  final ValueChanged<VoteSupport> onCastSupport;
  final VoidCallback? onExecute;
  final VoidCallback onRosterTap;
  /// The org Main Safe's OX balance, for the payment warning (null = unknown).
  final double? safeBalance;
  /// Today's settings + records, for the headline's before → after lines.
  final _OrgNow? now;
  /// A ballot or a run is in flight: buttons give way to a loader.
  final bool busy;
  /// Vote cancel: the proposer's withdraw / the vetoer's veto (null = not for this viewer),
  /// and "Cancelled by … : “reason”" on a cancelled card.
  final VoidCallback? onWithdraw;
  final VoidCallback? onVeto;
  final String? cancelledBy;

  const _LiveVoteCard({
    super.key,
    required this.tokens,
    required this.vote,
    this.info,
    required this.members,
    required this.canVote,
    required this.onCastSupport,
    this.onExecute,
    required this.onRosterTap,
    this.safeBalance,
    this.now,
    this.busy = false,
    this.onWithdraw,
    this.onVeto,
    this.cancelledBy,
  });

  bool get lastRunFailed => vote.parameters['lastRunFailed'] != null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = tokens.fallbackAccent;
    // `vote.voters` is everyone who cast a ballot (For/Against/Abstain under
    // the 3-way engine) — a participation set, not a yes-set.
    final votedAddrsLower =
        vote.voters.map((v) => v.toLowerCase()).toSet();

    // The roster shows only the members who cast a ballot, drawn with the
    // Members tile's own stack (same sizes, no ring, no dimming).
    final voted = members
        .where((c) =>
            c.publicosAddress != null &&
            votedAddrsLower.contains(c.publicosAddress!.eip55With0x.toLowerCase()))
        .toList();

    return Container(
      // Neutral glass: amber reads as an alarm. The accent
      // lives only on the live dot and label.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.borderSubtle),
        color: tokens.glassFill,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: vote.isActive
                ? Row(
                    children: [
                      _Pulse(color: accent),
                      const SizedBox(width: 8),
                      Text(
                        l10n.groupVotingViewLiveVote,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: accent,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.timer_outlined, size: 12, color: tokens.textDim),
                      const SizedBox(width: 4),
                      Text(
                        _countdown(l10n, vote),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: tokens.textDim,
                        ),
                      ),
                    ],
                  )
                : _outcomeHeader(context),
          ),
          Divider(color: accent.withValues(alpha: 0.18), height: 1),
          // What the vote does, in plain words.
          _VoteHeadline(
            key: ValueKey('headline-${vote.id}'),
            tokens: tokens,
            vote: vote,
            members: members,
            safeBalance: safeBalance,
            typeLabel: _actionTypeLabel(l10n, vote),
            now: now,
          ),
          if (cancelledBy != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.block_rounded, size: 14, color: tokens.textDim),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cancelledBy!,
                      style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 12, color: tokens.starkWhite),
                    ),
                  ),
                ],
              ),
            ),
          // Roster
          InkWell(
            onTap: onRosterTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(
                children: [
                  Text(
                    l10n.groupVotingViewVoters,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: tokens.textDim,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: MembersStack(
                        tokens: tokens,
                        contacts: voted,
                        onTap: onRosterTap,
                        shrinkWrap: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tally: one bar for the whole electorate. For fills
          // green from the left, Abstain grey after it, Against red from the
          // right; the white tick is the quorum floor (For + Abstain must
          // reach it, and For must outnumber Against).
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Builder(builder: (context) {
              final forW = info?.forVotes.toDouble() ?? vote.forVotes.toDouble();
              final againstW =
                  info?.againstVotes.toDouble() ?? vote.againstVotes.toDouble();
              final abstainW =
                  info?.abstainVotes.toDouble() ?? vote.abstainVotes.toDouble();
              final floor = vote.requiredThreshold.toDouble();
              final snap = info?.snapshotTotal.toDouble() ?? 0;
              final total = snap > 0 ? snap : members.length.toDouble();
              final missing = (floor - forW - abstainW).ceil();
              final passed = info?.passed ?? false;
              String? sentence;
              if (vote.isActive && !passed && !lastRunFailed) {
                sentence = missing > 0
                    ? l10n.groupVotingViewNeedsMore(missing, vote.requiredThreshold)
                    : (forW <= againstW ? l10n.groupVotingViewForMustLead : null);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TallyBar(
                    tokens: tokens,
                    forW: forW,
                    againstW: againstW,
                    abstainW: abstainW,
                    total: total < floor ? floor : total,
                    floor: floor,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.groupVotingViewTally(
                      vote.forVotes,
                      vote.againstVotes,
                      vote.abstainVotes,
                    ),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: tokens.textDim,
                    ),
                  ),
                  if (sentence != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      sentence,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.starkWhite,
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
          // Parallel votes: what this proposal waits for, and the
          // RUN button when the engine says it can run now — a wait-mode vote
          // after its period, or a passed vote whose last run failed (retry).
          if (info != null && (info!.passed || vote.waitFullPeriod || lastRunFailed))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  Icon(
                    lastRunFailed
                        ? Icons.error_outline_rounded
                        : info!.passed
                            ? Icons.check_circle_outline_rounded
                            : Icons.hourglass_bottom_rounded,
                    size: 14,
                    color: lastRunFailed ? tokens.softDanger : tokens.textDim,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lastRunFailed
                          ? l10n.groupVotingViewRunFailed
                          : info!.executable
                              ? l10n.groupVotingViewReadyToRun
                              : info!.passed
                                  ? l10n.groupVotingViewWaitingToRun
                                  : l10n.groupVotingViewWaitMode,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 11,
                        color: lastRunFailed ? tokens.softDanger : tokens.textDim,
                      ),
                    ),
                  ),
                  if (info!.executable && onExecute != null && !busy)
                    _CastButton(
                      label: l10n.groupVotingViewExecute,
                      background: accent,
                      foreground: const Color(0xFF1A0A00),
                      onTap: onExecute!,
                    ),
                ],
              ),
            ),
          if (busy)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 14),
              child: PixelRainLoadingLabel(label: l10n.groupVotingViewSending),
            )
          else if (canVote && vote.isActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _CastButton(
                      label: l10n.groupVotingViewCastFor,
                      background: accent,
                      foreground: const Color(0xFF1A0A00),
                      onTap: () => onCastSupport(VoteSupport.inFavor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _CastButton(
                      label: l10n.groupVotingViewCastAgainst,
                      background: tokens.glassFill,
                      foreground: tokens.starkWhite,
                      border: tokens.borderSubtle,
                      onTap: () => onCastSupport(VoteSupport.against),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _CastButton(
                      label: l10n.groupVotingViewCastAbstain,
                      background: tokens.glassFill,
                      foreground: tokens.textDim,
                      border: tokens.borderSubtle,
                      onTap: () => onCastSupport(VoteSupport.abstain),
                    ),
                  ),
                ],
              ),
            ),
          if (!busy && vote.isActive && (onWithdraw != null || onVeto != null))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  if (onWithdraw != null)
                    Expanded(
                      child: _CastButton(
                        label: l10n.groupVotingViewWithdraw,
                        background: tokens.glassFill,
                        foreground: tokens.textDim,
                        border: tokens.borderSubtle,
                        onTap: onWithdraw!,
                      ),
                    ),
                  if (onWithdraw != null && onVeto != null) const SizedBox(width: 8),
                  if (onVeto != null)
                    Expanded(
                      child: _CastButton(
                        label: l10n.groupVotingViewVeto,
                        background: tokens.glassFill,
                        foreground: tokens.softDanger,
                        border: tokens.softDanger.withValues(alpha: 0.4),
                        onTap: onVeto!,
                      ),
                    ),
                ],
              ),
            ),
          // The raw call, folded away for anyone who wants to check it.
          if (vote.actionType == VoteActionType.executeSafeTx)
            _TechDetails(tokens: tokens, vote: vote),
        ],
      ),
    );
  }

  /// The engine's reason for a `VoteFailed`, decoded ("defeated", "expired",
  /// or a run's revert text); empty when none.
  static String _failReason(VoteHistoryItem v) {
    final h = v.parameters['failReason'] as String?;
    if (h == null || h.length < 4) return '';
    try {
      final hex = h.startsWith('0x') ? h.substring(2) : h;
      return utf8.decode([
        for (var i = 0; i + 1 < hex.length; i += 2)
          int.parse(hex.substring(i, i + 2), radix: 16),
      ], allowMalformed: true);
    } catch (_) {
      return '';
    }
  }

  /// Header of a decided vote: how it ended + when, in place of
  /// the live dot and countdown.
  Widget _outcomeHeader(BuildContext context) {
    final l10n = context.l10n;
    final reason = _failReason(vote);
    final (IconData icon, Color color, String text) = switch (vote.status) {
      VoteStatus.executed => (Icons.check_circle_rounded, tokens.connectedAccent, l10n.groupVotingViewOutcomeExecuted),
      VoteStatus.cancelled => (Icons.cancel_outlined, tokens.textDim, l10n.groupVotingViewOutcomeCancelled),
      VoteStatus.expired => (Icons.schedule_rounded, tokens.textDim, l10n.groupVotingViewOutcomeExpired),
      _ => reason == 'defeated'
          ? (Icons.cancel_rounded, tokens.softDanger, l10n.groupVotingViewOutcomeDefeated)
          : reason == 'expired'
              ? (Icons.schedule_rounded, tokens.textDim, l10n.groupVotingViewOutcomeExpired)
              : (Icons.error_outline_rounded, tokens.softDanger, l10n.groupVotingViewOutcomeRunFailed),
    };
    final ended = vote.endTime ?? vote.expirationTime;
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: color,
            ),
          ),
        ),
        if (ended != null)
          Text(
            TimeOfDay.fromDateTime(ended.toLocal()).format(context),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: tokens.textDim,
            ),
          ),
      ],
    );
  }

  String _actionTypeLabel(AppLocalizations l10n, VoteHistoryItem v) {
    switch (v.actionType) {
      case VoteActionType.setRecord:
        return l10n.groupVotingViewActionSetRecord;
      case VoteActionType.deleteRecord:
        return l10n.groupVotingViewActionDeleteRecord;
      case VoteActionType.addMember:
        return l10n.groupVotingViewActionAddMember;
      case VoteActionType.removeMember:
        return l10n.groupVotingViewActionRemoveMember;
      case VoteActionType.setThreshold:
        return l10n.groupVotingViewActionSetThreshold;
      case VoteActionType.executeSafeTx:
        return l10n.groupVotingViewActionExecuteSafeTx;
      default:
        return v.actionType.name.toUpperCase();
    }
  }

  String _countdown(AppLocalizations l10n, VoteHistoryItem v) {
    // An active vote has no endTime yet — its clock is the proposal's real
    // expiration (frozen at startVote, surfaced by the VoteStarted event).
    final end = v.expirationTime ?? v.endTime;
    if (end == null) return '';
    final left = end.difference(DateTime.now());
    if (left.isNegative) return l10n.groupVotingViewVoteEnded;
    if (left.inHours >= 1) {
      final m = left.inMinutes % 60;
      return '${left.inHours}h ${m}m';
    }
    return '${left.inMinutes}m';
  }
}

/// One of the three cast buttons (For / Against / Abstain).
class _CastButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final VoidCallback onTap;

  const _CastButton({
    required this.label,
    required this.background,
    required this.foreground,
    this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: border != null ? Border.all(color: border!) : null,
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact "Send" pill on the Main Safe tile — opens the shared send sheet
/// (an org send starts an EXECUTE_SAFE_TX spend vote). Sized to sit inline
/// between the Safe address and its balance.
/// The GroupSplitter action, its own full-width row under the main Safe tile:
/// "Activate split" until the org approved the splitter, then "Split". Same
/// accent chrome as [_SendButton].
class _SplitterButton extends StatelessWidget {
  final GlassTokens tokens;
  final String label;
  final VoidCallback onTap;

  const _SplitterButton({required this.tokens, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: tokens.connectedAccent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tokens.connectedAccent.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.call_split_rounded, size: 14, color: tokens.connectedAccent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: tokens.connectedAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final GlassTokens tokens;
  final VoidCallback onTap;

  const _SendButton({required this.tokens, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: tokens.connectedAccent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: tokens.connectedAccent.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SendCoinsIcon(size: 14, color: tokens.connectedAccent),
              const SizedBox(width: 6),
              Text(
                context.l10n.groupVotingViewSend,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: tokens.connectedAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  final Color color;
  const _Pulse({required this.color});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return SizedBox(
          width: 16,
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 16 * t,
                height: 16 * t,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.4 * (1 - t)),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Empty / error states
// ═══════════════════════════════════════════════════════════════════════

class _NotGroupState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: tokens.glassFill,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Icon(Icons.groups_outlined, size: 44, color: tokens.textDim),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.groupVotingViewIndividualAccount,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: tokens.starkWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.groupVotingViewIndividualAccountBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 44,
              color: tokens.fallbackAccent,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.groupVotingViewTryAgain),
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.starkWhite,
                side: BorderSide(color: tokens.borderMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Today's org settings and records, for the live card's "before → after"
/// lines. Read from what the management view already loaded.
class _OrgNow {
  final int quorumBps;
  final int voteDurationSeconds;
  final int maxOpen;
  final bool waitFull;
  final bool proposerCap;
  /// Vote cancel: the withdraw cooldown in seconds.
  final int cancelCooldown;
  final List<Record> records;

  const _OrgNow({
    required this.quorumBps,
    required this.voteDurationSeconds,
    required this.maxOpen,
    required this.waitFull,
    required this.proposerCap,
    this.cancelCooldown = 0,
    required this.records,
  });

  Record? record(String key) {
    for (final r in records) {
      if (r.key == key) return r;
    }
    return null;
  }
}

/// The live vote's headline: what the vote does, in plain words,
/// parsed in the app from the proposal's parameters (no Core helper).
/// Every vote type gets a sentence:
/// - a Safe payment decodes to "Pay 1 OX to (avatar) jmsl" (+ a warning when
///   the org Safe cannot cover an OX payment);
/// - member / hierarchy / suspension votes name the target with its avatar;
/// - setting votes show today's value → the proposed one;
/// - record votes say what the record is (card, social link, tab, bio,
///   picture, banner, background) and preview a card with the profile's own
///   `RecordButton` at grid size, capped in height;
/// - a batch of records is decoded from its ABI payload and listed;
/// - wallets, chat inboxes and apps name what they add or change;
/// - anything else keeps Core's name plus whatever strings it carries.
class _VoteHeadline extends StatefulWidget {
  final GlassTokens tokens;
  final VoteHistoryItem vote;
  final List<Contact> members;
  /// The org Main Safe's OX balance; null when unknown (no warning then).
  final double? safeBalance;
  final String typeLabel;
  final _OrgNow? now;

  const _VoteHeadline({
    super.key,
    required this.tokens,
    required this.vote,
    required this.members,
    required this.safeBalance,
    required this.typeLabel,
    this.now,
  });

  @override
  State<_VoteHeadline> createState() => _VoteHeadlineState();
}

class _VoteHeadlineState extends State<_VoteHeadline> {
  // Safe payment
  SafeTransactionDetails? _tx;
  Erc20Transfer? _transfer;
  TokenMeta? _meta;
  String? _recipientAddr;
  // Any address the headline names, resolved to a contact.
  final Map<String, Contact> _contacts = {};
  // SET_MULTIPLE_RECORDS, decoded.
  List<Record>? _batch;

  // DELETE_MULTIPLE_RECORDS, decoded: the keys the vote erases.
  List<String>? _deleteKeys;

  static const _targetTypes = {
    VoteActionType.addMember,
    VoteActionType.removeMember,
    VoteActionType.suspendAccount,
    VoteActionType.unsuspendAccount,
    VoteActionType.removeAllVouches,
    VoteActionType.requestParent,
    VoteActionType.cancelParentRequest,
    VoteActionType.acceptChild,
    VoteActionType.releaseChild,
  };

  Map<String, dynamic> get _p => widget.vote.parameters;
  // Today's org values, as the "from" side of a change: only while the vote
  // is open. Once it ran, today's value IS the new one (the card would read
  // "OFF → OFF"), so a closed card shows only what it set.
  _OrgNow? get _liveNow =>
      widget.vote.status == VoteStatus.active ? widget.now : null;
  String get _key => (_p['keyParam'] as String?) ?? '';
  String get _vstr => (_p['valueStringParam'] as String?) ?? '';
  String get _custom => (_p['customTypeParam'] as String?) ?? '';
  BigInt get _val => (_p['valueParam'] as BigInt?) ?? BigInt.zero;
  List<int> get _data => (_p['dataParam'] as List<int>?) ?? const [];
  String? get _target {
    final t = _p['targetAddress'];
    if (t is! EthereumAddress) return null;
    final h = t.eip55With0x;
    return BigInt.parse(h.substring(2), radix: 16) == BigInt.zero ? null : h;
  }

  @override
  void initState() {
    super.initState();
    final type = widget.vote.actionType;
    if (type == VoteActionType.executeSafeTx) {
      try {
        final tx = SafeTransactionAnalyzer.analyzeTransaction(_p);
        _tx = tx;
        _transfer = PublicOSWallets.decodeErc20Transfer(tx.to, tx.data);
        if (_transfer != null) {
          _recipientAddr = _transfer!.recipient;
          _meta = PublicOSWallets.tokenMetaSync(PublicOS.CHAIN_ID, tx.to);
          if (_meta == null) _loadMeta(tx.to);
        } else if (tx.isEthTransfer) {
          _recipientAddr = tx.to;
        }
        if (_recipientAddr != null) _resolve(_recipientAddr!);
        final listed = tx.decodedParameters?['account'];
        if (tx.methodName == 'setRegistrationAllowed' && listed is String) _resolve(listed);
      } catch (_) {
        _tx = null;
      }
    } else if (_targetTypes.contains(type) ||
        type == VoteActionType.setChildLock ||
        type == VoteActionType.setVetoer) {
      final t = _target;
      if (t != null) _resolve(t);
    } else if (type == VoteActionType.setMultipleRecords) {
      _batch = _decodeBatch(_data);
    } else if (type == VoteActionType.deleteMultipleRecords) {
      _deleteKeys = PublicOSGovernance.decodeDeleteRecordKeys(_data);
    }
  }

  Future<void> _loadMeta(String token) async {
    final meta = await PublicOSWallets.resolveTokenMeta(PublicOS.CHAIN_ID, token);
    if (mounted && meta != null) setState(() => _meta = meta);
  }

  Contact? _member(String addr) {
    final a = addr.toLowerCase();
    for (final c in widget.members) {
      if (c.publicosAddress?.eip55With0x.toLowerCase() == a) return c;
    }
    return null;
  }

  Future<void> _resolve(String addr) async {
    final k = addr.toLowerCase();
    Contact? c = _member(addr);
    if (c == null) {
      try {
        c = await PublicOSContacts.searchContacts(addr) ??
            await PublicOSContacts.fetchContact(EthereumAddress.fromHex(addr));
      } catch (_) {}
    }
    if (mounted && c != null) setState(() => _contacts[k] = c!);
  }

  static Record? _parseRecord(String key, String value) {
    if (value.isEmpty) return null;
    try {
      final m = jsonDecode(value);
      if (m is Map<String, dynamic>) return Record.fromJson(m);
    } catch (_) {}
    try {
      return Record.fromJson({'key': key, 'value': value});
    } catch (_) {
      return null;
    }
  }

  /// Same layout Core encodes (`startVoteSetMultipleRecords`):
  /// (string[] keys, string[] values, uint256[] expirations, uint8[] types,
  /// string[] customTypes).
  static List<Record> _decodeBatch(List<int> data) {
    if (data.isEmpty) return const [];
    try {
      const abi = TupleType([
        DynamicLengthArray<String>(type: StringType()),
        DynamicLengthArray<String>(type: StringType()),
        DynamicLengthArray<BigInt>(type: UintType()),
        DynamicLengthArray<BigInt>(type: UintType(length: 8)),
        DynamicLengthArray<String>(type: StringType()),
      ]);
      final res = abi.decode(Uint8List.fromList(data).buffer, 0).data;
      final keys = (res[0] as List).cast<String>();
      final values = (res[1] as List).cast<String>();
      return [
        for (var i = 0; i < keys.length && i < values.length; i++)
          if (_parseRecord(keys[i], values[i]) case final r?) r,
      ];
    } catch (_) {
      return const [];
    }
  }

  static String _short(String a) =>
      a.length > 12 ? '${a.substring(0, 6)}…${a.substring(a.length - 4)}' : a;

  static String _clip(String s, [int max = 60]) =>
      s.length > max ? '${s.substring(0, max)}…' : s;

  static String _pretty(String key) {
    final last = key.split('.').last.replaceAll('_', ' ').trim();
    return last.isEmpty ? key : last;
  }

  static String _hex(List<int> b) =>
      '0x${b.map((x) => x.toRadixString(16).padLeft(2, '0')).join()}';

  static String _pct(int bps) =>
      bps % 100 == 0 ? '${bps ~/ 100}%' : '${(bps / 100).toStringAsFixed(2)}%';

  static String _dur(int s) {
    if (s <= 0) return '0';
    if (s % 86400 == 0) return '${s ~/ 86400} d';
    if (s % 3600 == 0) return '${s ~/ 3600} h';
    if (s % 60 == 0) return '${s ~/ 60} min';
    return '$s s';
  }

  String _onOff(AppLocalizations l10n, bool on) =>
      on ? l10n.groupVotingViewOn : l10n.groupVotingViewOff;

  // ---- pieces --------------------------------------------------------------

  TextStyle get _titleStyle => TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: widget.tokens.starkWhite,
      );

  /// "(prefix) (avatar) name" for a vote that targets an account.
  /// Provider allowlist: 'BSP' / 'SSP' when [tx] targets one of the
  /// provider registry Managers, else null.
  String? _providerRegistry(SafeTransactionDetails tx) {
    final to = tx.to.toLowerCase();
    if (to == PublicOSBsp.bspRegistryManagerAddress?.eip55With0x.toLowerCase()) return 'BSP';
    if (to == PublicOSBsp.socialServerRegistryManagerAddress?.eip55With0x.toLowerCase()) return 'SSP';
    return null;
  }

  Widget _withContact(String prefix, String addr) {
    final c = _contacts[addr.toLowerCase()];
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        Text(prefix, style: _titleStyle),
        if (c != null)
          SizedBox(
            width: 22,
            height: 22,
            child: GlassContactIcon(contact: c, size: 22),
          ),
        Text(c?.displayName ?? _short(addr), style: _titleStyle),
      ],
    );
  }

  /// "old → new", or just "→ new" when today's value is unknown.
  Widget _change(String? from, String to) {
    final t = widget.tokens;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        if (from != null)
          Text(
            from,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 14,
              color: t.textDim,
              decoration: TextDecoration.lineThrough,
              decorationColor: t.textDim,
            ),
          ),
        Icon(Icons.arrow_forward_rounded, size: 14, color: t.textDim),
        Text(
          to,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: t.starkWhite,
          ),
        ),
      ],
    );
  }

  /// The record's current value, small and dim under a "Set X: “new”" line;
  /// null when there is none.
  Widget? _was(AppLocalizations l10n, String? old) {
    if (old == null || old.isEmpty) return null;
    return Text(
      l10n.groupVotingViewDescWas(_clip(old)),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 12,
        color: widget.tokens.textDim,
      ),
    );
  }

  /// A card drawn by the profile's own renderer at its grid footprint, capped
  /// in height; best effort (an NFT or app card may show its placeholder,
  /// since the vote's copy never went through Core's resolvers).
  Widget _cardPreview(Record r, {bool faded = false}) {
    return LayoutBuilder(builder: (context, box) {
      var size = ProfileGridGeometry.cardSize(box.maxWidth, r.width, r.height);
      const maxH = 160.0;
      if (size.height > maxH) {
        final s = maxH / size.height;
        size = Size(size.width * s, size.height * s);
      }
      return Align(
        alignment: Alignment.centerLeft,
        child: Opacity(
          opacity: faded ? 0.45 : 1,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: IgnorePointer(
              child: RecordButton(
                record: r,
                onTap: () {},
                onDelete: () {},
                isEditable: false,
                isEditMode: false,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _imagePreview(String url) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 90,
          width: double.infinity,
          child: ZeroCachedImage(imageUrl: url, fit: BoxFit.cover),
        ),
      );

  /// One record write (or delete, when [delete]) as title + change + preview.
  ({Widget title, Widget? change, Widget? preview}) _record(
      AppLocalizations l10n, Record r, {bool delete = false}) {
    final old = _liveNow?.record(r.key);
    final key = r.key.toLowerCase();
    Text t(String s) =>
        Text(s, style: _titleStyle, maxLines: 4, overflow: TextOverflow.ellipsis);
    final social = SocialLinks.of(key);
    if (key.startsWith('card.')) {
      if (delete) {
        return (
          title: t(l10n.groupVotingViewDescDeleteCard),
          change: null,
          preview: old == null ? null : _cardPreview(old, faded: true),
        );
      }
      return (
        title: t(old == null ? l10n.groupVotingViewDescAddCard : l10n.groupVotingViewDescUpdateCard),
        change: null,
        preview: _cardPreview(r),
      );
    }
    if (social != null) {
      return delete
          ? (title: t(l10n.groupVotingViewDescRemoveSocial(social.name)), change: null, preview: null)
          : (
              title: t(l10n.groupVotingViewDescSetValue(social.name, _clip(r.value))),
              change: _was(l10n, old?.value),
              preview: null,
            );
    }
    if (r.type == RecordType.router || old?.type == RecordType.router) {
      final name = (r.metadata['name'] ?? old?.metadata['name'] ?? _pretty(r.key)).toString();
      if (delete) {
        return (title: t(l10n.groupVotingViewDescRemoveTab(name)), change: null, preview: null);
      }
      return (
        title: t(old == null ? l10n.groupVotingViewDescAddTab(name) : l10n.groupVotingViewDescUpdateTab(name)),
        change: _change(old?.value == null ? null : _clip(old!.value, 40), _clip(r.value, 40)),
        preview: null,
      );
    }
    if (key == 'profile.bio') {
      return delete
          ? (title: t(l10n.groupVotingViewDescDeleteRecord(l10n.groupVotingViewDescBio)), change: null, preview: null)
          : (
              title: t(l10n.groupVotingViewDescSetValue(l10n.groupVotingViewDescBio, _clip(r.value, 160))),
              change: null,
              preview: null,
            );
    }
    final imageTitle = switch (key) {
      'profile.avatar' => l10n.groupVotingViewDescChangeAvatar,
      'profile.banner' => l10n.groupVotingViewDescChangeBanner,
      '_osux_profile_background_url_' => l10n.groupVotingViewDescChangeBackground,
      _ => null,
    };
    if (imageTitle != null) {
      final isUrl = r.value.startsWith('http');
      return (
        title: t(imageTitle),
        change: null,
        preview: !delete && isUrl ? _imagePreview(r.value) : null,
      );
    }
    if (key == 'profile.color') {
      return (
        title: t(l10n.groupVotingViewDescSetValue(l10n.groupVotingViewDescColor, r.value)),
        change: _was(l10n, old?.value),
        preview: null,
      );
    }
    final name = _pretty(r.key);
    if (delete) {
      return (
        title: t(l10n.groupVotingViewDescDeleteRecord(name)),
        change: _was(l10n, old?.value),
        preview: null,
      );
    }
    return (
      title: t(l10n.groupVotingViewDescSetValue(name, _clip(r.value))),
      change: _was(l10n, old?.value),
      preview: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = widget.tokens;
    final vote = widget.vote;
    final now = _liveNow;
    final type = vote.actionType;

    Widget? title;
    Widget? change;
    Widget? preview;
    String? detail;
    String? label;
    String? warning;

    Text t(String s) => Text(s, style: _titleStyle);

    // ---- Safe payment / call ------------------------------------------------
    final tx = _tx;
    final splitter = type == VoteActionType.executeSafeTx && _target != null
        ? PublicOSGovernance.decodeSplitterCall(_target!, _data)
        : null;
    if (splitter != null) {
      // GroupSplitter: the one-time approve, or a split.
      label = l10n.groupVotingViewSplitLabel;
      if (splitter.kind == 'activate') {
        title = t(l10n.groupVotingViewSplitterActivateVote);
      } else {
        final amountText =
            PublicOSWallets.formatTokenAmount(splitter.amount, 18, symbol: 'OX');
        title = t(l10n.groupVotingViewSplitVote(amountText, widget.members.length));
        detail = l10n.groupVotingViewFromOrgSafe;
        final bal = widget.safeBalance;
        final amount = splitter.amount.toDouble() / 1e18;
        if (bal != null && bal < amount) {
          warning = l10n.groupVotingViewSafeShort(PublicOSWallets.formatTokenAmount(
              BigInt.from((bal * 1e6).floor()), 6,
              symbol: 'OX'));
        }
      }
    } else if (type == VoteActionType.executeSafeTx && tx != null) {
      if (_recipientAddr != null) {
        label = l10n.groupVotingViewPayment;
        String amountText;
        double? amount;
        var isOx = false;
        if (_transfer != null) {
          final meta = _meta;
          if (meta != null) {
            amountText = PublicOSWallets.formatTokenAmount(
                _transfer!.rawAmount, meta.decimals, symbol: meta.symbol);
            amount = _transfer!.rawAmount.toDouble() /
                BigInt.from(10).pow(meta.decimals).toDouble();
            isOx = meta.symbol == 'OX';
          } else {
            amountText = _transfer!.rawAmount.toString();
          }
        } else {
          amountText =
              '${PublicOSWallets.formatTokenAmount(tx.value, 18)} ${l10n.groupVotingViewNativeUnit}';
        }
        title = _withContact(l10n.groupVotingViewPayTo(amountText), _recipientAddr!);
        detail = l10n.groupVotingViewFromOrgSafe;
        final bal = widget.safeBalance;
        if (isOx && bal != null && amount != null && bal < amount) {
          warning = l10n.groupVotingViewSafeShort(PublicOSWallets.formatTokenAmount(
              BigInt.from((bal * 1e6).floor()), 6,
              symbol: 'OX'));
        }
      } else if (_providerRegistry(tx) case final registry?) {
        // Provider allowlist: the root Safe changing a registry's allowlist
        final p = tx.decodedParameters ?? const {};
        if (tx.methodName == 'setRegistrationRestricted' && p['restricted'] is bool) {
          title = t(p['restricted'] == true
              ? l10n.groupVotingViewProviderRegRestricted(registry)
              : l10n.groupVotingViewProviderRegOpen(registry));
        } else if (tx.methodName == 'setRegistrationAllowed' && p['account'] is String) {
          title = _withContact(
              p['allowed'] == true
                  ? l10n.groupVotingViewProviderRegAllow(registry)
                  : l10n.groupVotingViewProviderRegDisallow(registry),
              p['account'] as String);
        } else {
          title = t(l10n.groupVotingViewRunCall(tx.methodName ?? '?', _short(tx.to)));
        }
      } else {
        title = t(l10n.groupVotingViewRunCall(tx.methodName ?? '?', _short(tx.to)));
      }
    }

    // ---- an account as the subject -------------------------------------------
    else if (_targetTypes.contains(type) && _target != null) {
      final prefix = switch (type) {
        VoteActionType.addMember => l10n.groupVotingViewDescAdd,
        VoteActionType.removeMember => l10n.groupVotingViewDescRemove,
        VoteActionType.suspendAccount => l10n.groupVotingViewDescSuspend,
        VoteActionType.unsuspendAccount => l10n.groupVotingViewDescUnsuspend,
        VoteActionType.removeAllVouches => l10n.groupVotingViewDescClearVouches,
        VoteActionType.requestParent => l10n.groupVotingViewDescRequestParent,
        VoteActionType.cancelParentRequest => l10n.groupVotingViewDescCancelParent,
        VoteActionType.acceptChild => l10n.groupVotingViewDescAcceptChild,
        _ => l10n.groupVotingViewDescReleaseChild,
      };
      title = _withContact(prefix, _target!);
    }

    // ---- settings: today's value → the proposed one --------------------------
    else if (type == VoteActionType.setQuorumBps) {
      title = t(l10n.groupVotingViewQuorum);
      change = _change(now == null ? null : _pct(now.quorumBps), _pct(_val.toInt()));
    } else if (type == VoteActionType.setVoteDuration) {
      title = t(l10n.groupVotingViewVoteDuration);
      change = _change(now == null ? null : _dur(now.voteDurationSeconds), _dur(_val.toInt()));
    } else if (type == VoteActionType.setMaxOpenVotes) {
      title = t(l10n.groupVotingViewMaxOpen);
      change = _change(now == null ? null : '${now.maxOpen}', '$_val');
    } else if (type == VoteActionType.setWaitFullPeriod) {
      title = t(l10n.groupVotingViewWaitFull);
      change = _change(now == null ? null : _onOff(l10n, now.waitFull), _onOff(l10n, _val != BigInt.zero));
    } else if (type == VoteActionType.setProposerCap) {
      title = t(l10n.groupVotingViewProposerCap);
      change = _change(now == null ? null : _onOff(l10n, now.proposerCap), _onOff(l10n, _val != BigInt.zero));
    } else if (type == VoteActionType.setChildLock) {
      // Names the child: "Stop new children under (avatar) name".
      final child = _target;
      title = child == null
          ? t(l10n.groupVotingViewDescChildLock)
          : _withContact(
              _val != BigInt.zero
                  ? l10n.groupVotingViewDescLockChild
                  : l10n.groupVotingViewDescUnlockChild,
              child);
      change = _change(null, _onOff(l10n, _val != BigInt.zero));
    } else if (type == VoteActionType.setVetoer) {
      // Vote cancel: "Give the veto to (avatar) name" / "Remove the vetoer".
      title = _target == null
          ? t(l10n.groupVotingViewDescClearVetoer)
          : _withContact(l10n.groupVotingViewDescSetVetoer, _target!);
    } else if (type == VoteActionType.cancelVote) {
      title = t(l10n.groupVotingViewDescCancelVote('$_val'));
      if (_vstr.isNotEmpty) detail = '“${_clip(_vstr, 120)}”';
    } else if (type == VoteActionType.setCancelCooldown) {
      String cd(int s) => s <= 0 ? l10n.groupVotingViewCooldownNone : _dur(s);
      title = t(l10n.groupVotingViewCooldown);
      change = _change(now == null ? null : cd(now.cancelCooldown), cd(_val.toInt()));
    } else if (type == VoteActionType.setThreshold) {
      title = t(vote.actionDisplayName);
      change = _change(null, '$_val');
    }

    // ---- records ------------------------------------------------------------
    else if (type == VoteActionType.setRecord) {
      final r = _parseRecord(_key, _vstr);
      if (r != null) {
        final d = _record(l10n, r);
        title = d.title;
        change = d.change;
        preview = d.preview;
      }
    } else if (type == VoteActionType.deleteRecord) {
      final old = _liveNow?.record(_key);
      final d = _record(
          l10n, old ?? Record.fromJson({'key': _key, 'value': ''}), delete: true);
      title = d.title;
      change = d.change;
      preview = d.preview;
    } else if (type == VoteActionType.setMultipleRecords ||
        type == VoteActionType.deleteMultipleRecords) {
      // One card for both batches: each record reads the way its single vote would.
      final deleting = type == VoteActionType.deleteMultipleRecords;
      final batch = deleting
          ? [
              for (final k in _deleteKeys ?? const <String>[])
                _liveNow?.record(k) ?? Record.fromJson({'key': k, 'value': ''}),
            ]
          : _batch ?? const <Record>[];
      title = t(deleting
          ? l10n.groupVotingViewDescDeleteBatch(batch.length)
          : l10n.groupVotingViewDescBatch(batch.length));
      if (batch.isNotEmpty) {
        preview = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final r in batch) ...[
              Builder(builder: (context) {
                final d = _record(l10n, r, delete: deleting);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle.merge(
                      style: const TextStyle(fontSize: 13),
                      child: Transform.scale(
                        scale: 0.85,
                        alignment: Alignment.centerLeft,
                        child: d.title,
                      ),
                    ),
                    if (d.change != null) d.change!,
                    if (d.preview != null) ...[
                      const SizedBox(height: 4),
                      d.preview!,
                    ],
                  ],
                );
              }),
              const SizedBox(height: 8),
            ],
          ],
        );
      }
    }

    // ---- wallets, chat inboxes, apps ------------------------------------------
    else if (type == VoteActionType.registerAdditionalWallet) {
      title = t(l10n.groupVotingViewDescAddWallet(_key));
      final type = (_p['recordTypeValueParam'] as BigInt?)?.toInt() ?? 0;
      detail = [
        if (type == 2) l10n.startNewVoteSheetWalletTypeSafe else if (type == 1) l10n.startNewVoteSheetWalletTypeKey,
        if (_data.isNotEmpty) _short(_hex(_data)),
      ].join(' · ');
    } else if (type == VoteActionType.removeWallet) {
      title = t(l10n.groupVotingViewDescRemoveWallet);
      detail = [if (_key.isNotEmpty) _key, if (_data.isNotEmpty) _short(_hex(_data))].join(' · ');
    } else if (type == VoteActionType.registerInboxId) {
      title = t(l10n.groupVotingViewDescAddInbox(_key));
      if (_data.isNotEmpty) detail = _short(_hex(_data));
    } else if (type == VoteActionType.removeInboxId) {
      title = t(l10n.groupVotingViewDescRemoveInbox);
      if (_data.isNotEmpty) detail = _short(_hex(_data));
    } else if (type == VoteActionType.registerApp) {
      title = t(l10n.groupVotingViewDescRegisterApp(_key));
      if (_vstr.isNotEmpty) detail = '“$_vstr”';
    } else if (type == VoteActionType.removeApp) {
      title = t(l10n.groupVotingViewDescRemoveApp(_key));
    } else if (type == VoteActionType.updateAppDisplayName) {
      title = t(l10n.groupVotingViewDescRenameApp(_key));
      change = _change(null, _vstr);
    } else if (type == VoteActionType.setAppPointer) {
      title = t(l10n.groupVotingViewDescSetAppPointer(_key, _custom));
      change = _change(null, _clip(_vstr, 50));
    } else if (type == VoteActionType.removeAppPointer) {
      title = t(l10n.groupVotingViewDescRemoveAppPointer(_key, _custom));
    }

    // ---- anything else: Core's name + the strings it carries ------------------
    if (title == null) {
      title = t(vote.actionDisplayName);
      final bits = [
        if (_key.isNotEmpty) _clip(_key, 40),
        if (_vstr.isNotEmpty) _clip(_vstr, 40),
        if (_target != null) _short(_target!),
      ];
      if (bits.isNotEmpty) detail = bits.join(' · ');
    }

    final initiator = _member(vote.initiator);
    final proposedBy = l10n.groupVotingViewProposedBy(
        initiator?.displayName ?? _short(vote.initiator));
    final sub = [if (detail != null && detail.isNotEmpty) detail, proposedBy].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label ?? widget.typeLabel,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: tokens.textDim,
            ),
          ),
          const SizedBox(height: 4),
          title,
          if (change != null) ...[
            const SizedBox(height: 4),
            change,
          ],
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 11,
              color: tokens.textDim,
            ),
          ),
          if (preview != null) ...[
            const SizedBox(height: 8),
            preview,
          ],
          if (warning != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: tokens.softDanger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    warning,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 11,
                      color: tokens.softDanger,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One bar for the whole tally. Width = the electorate (the
/// proposal's snapshot weight); For green from the left, Abstain grey after
/// it, Against red from the right; a white tick marks the quorum floor.
class _TallyBar extends StatelessWidget {
  final GlassTokens tokens;
  final double forW;
  final double againstW;
  final double abstainW;
  final double total;
  final double floor;

  const _TallyBar({
    required this.tokens,
    required this.forW,
    required this.againstW,
    required this.abstainW,
    required this.total,
    required this.floor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      double px(double v) => total <= 0 ? 0 : (v / total).clamp(0.0, 1.0) * w;
      final forPx = px(forW);
      final abstainPx = px(abstainW).clamp(0.0, w - forPx);
      final againstPx = px(againstW).clamp(0.0, w - forPx - abstainPx);
      final tick = (px(floor) - 1).clamp(0.0, w - 2);
      return SizedBox(
        height: 14,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 4,
              height: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: Container(color: tokens.glassFillHover)),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: forPx,
                      child: Container(color: tokens.connectedAccent),
                    ),
                    Positioned(
                      left: forPx,
                      top: 0,
                      bottom: 0,
                      width: abstainPx,
                      child: Container(
                          color: tokens.textDim.withValues(alpha: 0.6)),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: againstPx,
                      child: Container(color: tokens.softDanger),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: tick,
              top: 0,
              height: 14,
              width: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: tokens.starkWhite.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// "Technical details" fold on a Safe-transaction vote: the raw
/// target, value, method and calldata, collapsed by default.
class _TechDetails extends StatefulWidget {
  final GlassTokens tokens;
  final VoteHistoryItem vote;
  const _TechDetails({required this.tokens, required this.vote});

  @override
  State<_TechDetails> createState() => _TechDetailsState();
}

class _TechDetailsState extends State<_TechDetails> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = widget.tokens;
    SafeTransactionDetails? tx;
    try {
      tx = SafeTransactionAnalyzer.analyzeTransaction(widget.vote.parameters);
    } catch (_) {}
    if (tx == null) return const SizedBox.shrink();
    final mono =
        TextStyle(fontFamily: 'monospace', fontSize: 10, color: tokens.textDim);
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: Text(k,
                    style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 10,
                        color: tokens.textDim)),
              ),
              Expanded(child: SelectableText(v, style: mono)),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      _open
                          ? Icons.expand_more_rounded
                          : Icons.chevron_right_rounded,
                      size: 16,
                      color: tokens.textDim),
                  const SizedBox(width: 2),
                  Text(l10n.groupVotingViewTechDetails,
                      style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 11,
                          color: tokens.textDim)),
                ],
              ),
            ),
          ),
          if (_open) ...[
            row(l10n.groupVotingViewTechTarget, tx.to),
            row(l10n.groupVotingViewTechValue, tx.value.toString()),
            if (tx.methodName != null)
              row(l10n.groupVotingViewTechMethod, tx.methodName!),
            row(l10n.groupVotingViewTechData, tx.data),
          ],
        ],
      ),
    );
  }
}

// ─── Glass dialog style ─────────────────────────────────────────────────
// surfaceDeep · r16 · borderSubtle · SpaceGrotesk title w800 · textDim body.

AlertDialog _glassDialog(
  BuildContext ctx, {
  required String title,
  required Widget content,
  required List<Widget> actions,
  double maxWidth = DialogWidth.s,
}) {
  final t = GlassTokens.of(ctx);
  return AlertDialog(
    constraints: BoxConstraints(minWidth: DialogWidth.min, maxWidth: maxWidth),
    backgroundColor: t.surfaceDeep,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: t.borderSubtle),
    ),
    title: Text(
      title,
      style: TextStyle(fontFamily: 'SpaceGrotesk', color: t.starkWhite, fontWeight: FontWeight.w800),
    ),
    content: content,
    actions: actions,
  );
}

Widget _dialogBody(BuildContext ctx, String text) => Text(
      text,
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: GlassTokens.of(ctx).textDim,
        fontSize: 13,
        height: 1.4,
      ),
    );

Widget _dialogCancel(BuildContext ctx) => TextButton(
      onPressed: () => Navigator.pop(ctx),
      child: Text(
        ctx.l10n.dlgCancel,
        style: TextStyle(fontFamily: 'SpaceGrotesk', color: GlassTokens.of(ctx).textDim),
      ),
    );

/// Dense-form field.
InputDecoration _dialogField(BuildContext ctx, String hint) {
  final t = GlassTokens.of(ctx);
  OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: t.surfaceElevated,
    hintStyle: TextStyle(fontFamily: 'SpaceGrotesk', color: t.textDim),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: b(t.borderSubtle, 1),
    enabledBorder: b(t.borderSubtle, 1),
    focusedBorder: b(t.borderMedium, 1.5),
  );
}

/// One choice row in a picker dialog; tapping it pops [value].
Widget _dialogOption<T>(
  BuildContext ctx, {
  required T value,
  required bool selected,
  required String label,
  Widget? leading,
}) {
  final t = GlassTokens.of(ctx);
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => Navigator.pop(ctx, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: selected
            ? BoxDecoration(
                color: t.glassFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.borderSubtle),
              )
            : null,
        child: Row(children: [
          if (leading != null) ...[leading, const SizedBox(width: 10)],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: t.starkWhite,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (selected) Icon(Icons.check_rounded, size: 18, color: t.starkWhite),
        ]),
      ),
    ),
  );
}
