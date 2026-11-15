import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/theme/theme_provider.dart' show PhigitalStyle;
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/widgets/domain_store_sheet.dart';
import 'package:publicos_desktop/widgets/citizenship_claim_sheet.dart';
import 'package:publicos_desktop/widgets/system_app_action_button.dart';
import 'package:publicos_desktop/widgets/renounce_citizenship_dialogs.dart';
import 'package:publicos_desktop/widgets/clear_records_dialogs.dart';
import 'package:publicos_desktop/widgets/network_access_sheets.dart'
    show confirmPayPenalties;
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/screens/user_account_settings.dart'
    show AddRecoveryContactSheet;
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/widgets/flag_sheet.dart';

/// Account — the single surface for managing your own account. Identity card,
/// vouch-status progress + trust tree entry, domain status, devices list +
/// add/remove, your recovery contacts, friend-recovery multi-step flow, accent
/// colour, create-new-account helper.
///
/// This page also carries what the browser's self-account Settings tab would
/// (`UserAccountSettings`): the recovery-contacts and accent-colour
/// sections, and the devices list ([_buildDevicesCard]). The browser shows
/// no Settings tab when you
/// browse yourself; it still does for every other contact type.
class AccountCenterPage extends StatefulWidget {
  const AccountCenterPage({super.key});

  @override
  State<AccountCenterPage> createState() => _AccountCenterPageState();
}

class _AccountCenterPageState extends State<AccountCenterPage> {
  bool _isLoading = true;

  BigInt _vouchCount = BigInt.zero;
  bool _isCitizen = false;
  /// Today's vouch threshold, read live.
  BigInt _vouchThreshold = BigInt.from(25);

  // Bootstrap invitation state. When self-serve creation is paused network-wide,
  // the "Create New Account" section becomes an invite-status panel.
  bool _accountCreationPaused = false;
  int _invitesLeft = 0;

  List<EthereumAddress> _sessions = [];
  bool _isAddingSession = false;
  bool _isRemovingSession = false;
  String? _sessionBeingRemoved;

  // Linked wallets. Addresses the user has proven they control,
  // distinct from sessions (devices). Their NFTs can show on the profile.

  // Display-name policy state.
  // Drives the free-change ticket chip on the identity card. Refreshed on
  // every _loadData call.
  BigInt _lastNameChangeAt = BigInt.zero;
  int _bonusCount = 0;
  int _yearWindowSec = 365 * 24 * 60 * 60;

  // Domain status (gates write access). > this sentinel ⇒ lifetime (NEVER).
  static final BigInt _domainNeverSentinel = BigInt.from(32503680000 - 1);
  BigInt _domainPaidUntil = BigInt.zero;

  // My recovery contacts — the friends who can vote to reseed MY account.
  // The mirror image of the friend-recovery state below, where I am the voter
  // on someone else's reseed. Two sections, two directions; don't conflate.
  List<Contact> _myRecoveryContacts = [];
  int _myRecoveryThreshold = 0;
  bool _isAddingRecoveryContact = false;

  // Accent colour, persisted as an on-chain `color` settings record.
  // `_accentColor` is what's on chain; `_stagedAccent` is the unsaved pick.
  // Staged rather than instant-write so the user can read the preview bubble
  // before spending a tx — the swatch and the bubble never look the same.
  Color? _accentColor;
  Color? _stagedAccent;

  bool get _accentDirty =>
      _stagedAccent != null && _stagedAccent != _accentColor;

  // Swatch-strip geometry. `stride == size + gap` is what
  // _scrollAccentToSelection uses to find a swatch by index, so these three
  // must stay together.
  static const double _accentSwatchSize = 44;
  static const double _accentSwatchGap = 10;
  static const EdgeInsets _accentInset = EdgeInsets.symmetric(horizontal: 20);

  final ScrollController _accentScrollCtrl = ScrollController();
  bool _accentScrolledOnce = false;

  // Blocking overlay for in-page writes (colour save, recovery add/remove).
  // Null = no overlay.
  String? _actionStatus;

  // Friend recovery state
  Contact? _recoveryTargetContact;
  bool _isCheckingRecovery = false;
  bool _isRecoveryContactForTarget = false;
  int _recoveryThreshold = 0;
  Map<String, dynamic>? _activeRecoverySession;
  bool _isStartingRecovery = false;
  bool _isCastingVote = false;
  String? _recoveryError;

  // Collapsible groups (the Services / Settings grammar): one open
  // at a time, page state only.
  String? _openGroup = 'devices';

  // Who can add me to groups. `_orgAddAvailable`
  // stays false until the chain answers, so the group is hidden on a chain
  // that has no OrgAddPermitsManager yet.
  bool _orgAddAvailable = false;
  bool _anyoneCanAddMe = true;
  List<({Contact contact, int left})> _orgAdders = [];

  // Community standards: penalties, blacklist, suspension clock.
  // Null until the chain answers (or on a chain without the contracts), so
  // nothing is drawn rather than a false "nothing owed".
  CommunityStanding? _standing;

  // Flags: the ones I filed, and the ones on my content (only
  // the owner sees those). Empty = the group stays hidden.
  List<Flag> _myFlags = const [];
  List<Flag> _flagsOnMe = const [];


  // Cached my-contact (not read from AppStateNotifier — graph reads from
  // PublicOS.myPublicosAddress directly, then resolves a Contact on load).
  Contact? _myContact;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _accentScrollCtrl.dispose();
    super.dispose();
  }

  /// The claim sheet, then a full reload: the pill, the ticket chip, the
  /// create-account card and the domain status all follow citizenship.
  Future<void> _claimCitizenship() async {
    final claimed = await showCitizenshipClaimSheet(context);
    if (!mounted || !claimed) return;
    await _loadData();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    final myAddrHex = PublicOS.myPublicosAddress;
    if (myAddrHex == null) {
      if (mounted && !silent) setState(() => _isLoading = false);
      return;
    }
    final myAddress = EthereumAddress.fromHex(myAddrHex);

    try {
      final results = await Future.wait([
        PublicOSAccounts.getVouchCount(myAddress),
        PublicOSAccounts.isCitizen(myAddress),
        PublicOSAccounts.getMySessions(),
        PublicOSAccounts.getLastDisplayNameChangeAt(myAddress),
        PublicOSAccounts.getBonusNameChanges(myAddress),
        PublicOSAccounts.getNameChangeYearWindow(),
        PublicOSTreasury.getDomainPaidUntil(myAddress),
        PublicOSAccounts.isAccountCreationPaused(),
        PublicOSAccounts.myInvites(),
        PublicOSAccounts.getVouchThreshold(),
      ]);

      Contact? myContact;
      try {
        myContact = await PublicOSContacts.getContact(myAddress);
      } catch (_) {}

      // Kept out of the Future.wait above: a throw in either would fail the
      // whole batch and blank the page. Both degrade to empty/default.
      final recovery = await _fetchMyRecoveryContacts();
      final accent = await _fetchAccentColor(myAddress);
      final orgAdd = await _fetchOrgAddPermits(myAddress);
      CommunityStanding? standing;
      try {
        standing = await PublicOSCommunityStandards.getStanding(myAddress);
      } catch (_) {}
      var myFlags = const <Flag>[];
      var flagsOnMe = const <Flag>[];
      try {
        final f = await Future.wait([
          PublicOSCommunityStandards.getFlagsBy(myAddress),
          PublicOSCommunityStandards.getFlagsOn(myAddress),
        ]);
        myFlags = f[0];
        flagsOnMe = f[1];
      } catch (_) {}


      if (mounted) {
        setState(() {
          _vouchCount = results[0] as BigInt;
          _isCitizen = results[1] as bool;
          _sessions = results[2] as List<EthereumAddress>;
          _lastNameChangeAt = results[3] as BigInt;
          _bonusCount = (results[4] as BigInt).toInt();
          _yearWindowSec = (results[5] as BigInt).toInt();
          _domainPaidUntil = results[6] as BigInt;
          _accountCreationPaused = results[7] as bool;
          _invitesLeft = results[8] as int;
          _vouchThreshold = results[9] as BigInt;
          _myContact = myContact;
          _myRecoveryContacts = recovery.contacts;
          _myRecoveryThreshold = recovery.threshold;
          _accentColor = accent;
          _orgAddAvailable = orgAdd != null;
          _anyoneCanAddMe = orgAdd?.anyone ?? true;
          _orgAdders = orgAdd?.adders ?? [];
          _standing = standing;
          _myFlags = myFlags;
          _flagsOnMe = flagsOnMe;
          if (!silent) _isLoading = false;
        });

        // The strip only exists once _isLoading flips, so this waits a frame.
        if (!_accentScrolledOnce) {
          _accentScrolledOnce = true;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollAccentToSelection());
        }
      }
    } catch (_) {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  /// Resolve my recovery contacts to displayable Contacts. An address that
  /// won't resolve falls back to a truncated-address stub rather than
  /// vanishing — a recovery contact you can't see is one you can't revoke.
  Future<({List<Contact> contacts, int threshold})>
      _fetchMyRecoveryContacts() async {
    try {
      final data = await PublicOSRecovery.getMyRecoveryContacts();
      if (data == null) return (contacts: <Contact>[], threshold: 0);

      final resolved = <Contact>[];
      for (final address in data.contacts) {
        try {
          resolved.add(await PublicOSContacts.fetchContact(address));
        } catch (_) {
          final short = _truncateAddress(address.eip55With0x);
          resolved.add(Contact(
            displayName: short,
            publicosDisplayName: short,
            publicosAddress: address,
          ));
        }
      }
      return (contacts: resolved, threshold: data.threshold);
    } catch (_) {
      return (contacts: <Contact>[], threshold: 0);
    }
  }

  /// The switch and the list, each person resolved to a Contact (a stub
  /// when it won't resolve: someone on your list you can't see is someone you
  /// can't remove). Null when the chain has no OrgAddPermitsManager.
  Future<({bool anyone, List<({Contact contact, int left})> adders})?>
      _fetchOrgAddPermits(EthereumAddress me) async {
    try {
      final anyone = await PublicOSGovernance.anyoneCanAddMe(me);
      final addrs = await PublicOSGovernance.getPermittedAdders(me);
      final rows = <({Contact contact, int left})>[];
      for (final a in addrs) {
        final left = await PublicOSGovernance.getAddPermitQuota(me, a);
        Contact c;
        try {
          c = await PublicOSContacts.fetchContact(a);
        } catch (_) {
          final short = _truncateAddress(a.eip55With0x);
          c = Contact(
            displayName: short,
            publicosDisplayName: short,
            publicosAddress: a,
          );
        }
        rows.add((contact: c, left: left));
      }
      return (anyone: anyone, adders: rows);
    } catch (_) {
      return null;
    }
  }

  Future<Color?> _fetchAccentColor(EthereumAddress myAddress) async {
    try {
      final record = await PublicOSContacts.getRecord('color', myAddress);
      if (record == null) return null;
      return Color(int.parse(record.value));
    } catch (_) {
      return null;
    }
  }

  // ── Display-name policy helpers ──────────────────────────────────────

  /// Earliest unix-second the user can perform a free user-initiated change.
  int get _nextFreeNameChangeAtSec =>
      _lastNameChangeAt.toInt() + _yearWindowSec;

  bool get _annualWindowOpen {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= _nextFreeNameChangeAtSec;
  }

  // ── Device management ────────────────────────────────────────────────
  //
  // No `_addSession(address)` here: addSession requires an EIP-712 sig
  // from the new session's
  // key — which lives on the other device. The flow: the new
  // device shows a `publicos-claim:` QR (see select_account_screen
  // _showTempKeyQR), this device's OS scanner reads it, the OS dispatches
  // a `publicos://add_session/<payload>` deep link, and AddSessionDialog
  // submits with the pre-built sig. There is no in-app "type an address"
  // path; _showAddSessionSheet just explains the flow.

  Future<void> _removeSession(EthereumAddress sessionAddress) async {
    if (_isRemovingSession) return;
    final l10n = context.l10n;
    setState(() {
      _isRemovingSession = true;
      _sessionBeingRemoved = sessionAddress.eip55With0x;
    });
    try {
      final success = await PublicOSAccounts.removeSession(sessionAddress);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.accountCenterSessionRemoved)),
        );
        await Future.delayed(const Duration(seconds: 2));
        final sessions = await PublicOSAccounts.getMySessions();
        if (mounted) setState(() => _sessions = sessions);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizedError(context.l10n, PublicOS.lastError,
                fallback: context.l10n.errRemoveSessionFailed)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(context.l10n, e,
              fallback: context.l10n.errRemoveSessionFailed))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRemovingSession = false;
          _sessionBeingRemoved = null;
        });
      }
    }
  }

  void _showAddSessionSheet() {
    showGlassSheetDialog(
      context: context,
      width: DialogWidth.m,
      builder: (sheetContext) {
        final tokens = GlassTokens.of(sheetContext);
        final l10n = sheetContext.l10n;
        return _GlassSheet(
          tokens: tokens,
          title: l10n.accountCenterAddNewSession,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoCallout(
                  tokens,
                  icon: Icons.qr_code_scanner_rounded,
                  title: l10n.accountCenterLinkNewDeviceTitle,
                  body: l10n.accountCenterLinkNewDeviceBody,
                ),
                const SizedBox(height: 16),
                _infoCallout(
                  tokens,
                  icon: Icons.lock_outline_rounded,
                  title: l10n.accountCenterWhyQrTitle,
                  body: l10n.accountCenterWhyQrBody,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmRemoveSession(EthereumAddress sessionAddress) async {
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
          l10n.accountCenterRemoveSessionTitle,
          style: TextStyle(
              fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.accountCenterRemoveSessionConfirm,
              style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.glassFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.devices_other_rounded,
                    size: 18,
                    color: tokens.textDim,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _truncateAddress(sessionAddress.eip55With0x),
                      style: TextStyle(
                    fontFamily: 'monospace',
                        color: tokens.starkWhite,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tokens.fallbackAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: tokens.fallbackAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: tokens.fallbackAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.accountCenterRemoveSessionWarning,
                      style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                        fontSize: 11,
                        color: tokens.fallbackAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              l10n.accountCenterRemove,
              style: TextStyle(
              fontFamily: 'SpaceGrotesk',color: tokens.fallbackAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _removeSession(sessionAddress);
    }
  }

  // ── Create account ───────────────────────────────────────────────────
  // Lives in `lib/components/new_account_dialog.dart`. Account Center
  // pushes `/new_account`; QR scan pushes `/new_account/<address>`.
  // Both surfaces share the same dialog (rules card + validator +
  // cooldown pre-check + humanized chain-revert errors).


  // ── Friend recovery ──────────────────────────────────────────────────

  Future<void> _checkRecoveryStatus(Contact contact) async {
    final l10n = context.l10n;
    final targetAddress = contact.publicosAddress;
    if (targetAddress == null) return;

    setState(() {
      _recoveryTargetContact = contact;
      _isCheckingRecovery = true;
      _recoveryError = null;
      _isRecoveryContactForTarget = false;
      _activeRecoverySession = null;
    });

    try {
      final myAddrHex = PublicOS.myPublicosAddress;
      if (myAddrHex == null) {
        if (mounted) {
          setState(() {
            _isCheckingRecovery = false;
            _recoveryError = l10n.accountCenterNoAccountAddress;
          });
        }
        return;
      }
      final myAddress = EthereumAddress.fromHex(myAddrHex);

      final results = await Future.wait([
        PublicOSRecovery.getAccountRecoveryContacts(targetAddress),
        PublicOSRecovery.getActiveRecoverySession(targetAddress),
      ]);

      final recoveryInfo =
          results[0] as ({List<EthereumAddress> contacts, int threshold});
      final session = results[1] as Map<String, dynamic>?;

      final isContact = recoveryInfo.contacts.any(
        (c) =>
            c.eip55With0x.toLowerCase() == myAddress.eip55With0x.toLowerCase(),
      );

      if (mounted) {
        setState(() {
          _isRecoveryContactForTarget = isContact;
          _recoveryThreshold = recoveryInfo.threshold;
          _activeRecoverySession = session;
          _isCheckingRecovery = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCheckingRecovery = false;
          _recoveryError = l10n.accountCenterRecoveryStatusError;
        });
      }
    }
  }

  void _showRecoveryContactSearchSheet() {
    showGlassSheetDialog(
      context: context,
      width: DialogWidth.m,
      builder: (_) => _RecoveryContactSearchSheet(
        onSelected: (contact) {
          Navigator.pop(context);
          _checkRecoveryStatus(contact);
        },
      ),
    );
  }

  void _showStartRecoverySheet() {
    // Recovery starts by SCANNING the recovering user's `publicos-claim:`
    // QR (the same k=1 claim used to link a device). The scan routes to
    // AddSessionDialog, which detects the claim is for another account and — if
    // this user is a recovery contact — offers to start the reseed vote.
    // See add_session_dialog.dart.
    showGlassSheetDialog(
      context: context,
      width: DialogWidth.m,
      builder: (sheetContext) {
        final tokens = GlassTokens.of(sheetContext);
        final l10n = sheetContext.l10n;
        return _GlassSheet(
          tokens: tokens,
          title: l10n.accountCenterStartRecoveryTitle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: _infoCallout(
              tokens,
              icon: Icons.qr_code_scanner_rounded,
              title: l10n.accountCenterScanRecoveryQrTitle,
              body: l10n.accountCenterScanRecoveryQrBody,
            ),
          ),
        );
      },
    );
  }

  // ignore: unused_element
  Future<void> _startRecovery(
    EthereumAddress proposedSession, {
    required BigInt deadline,
    required Uint8List sig,
  }) async {
    final targetAddress = _recoveryTargetContact?.publicosAddress;
    if (targetAddress == null || _isStartingRecovery) return;
    final l10n = context.l10n;
    setState(() => _isStartingRecovery = true);
    try {
      await HapticFeedback.lightImpact();
      final success = await PublicOSRecovery.startRecoveryVote(
        targetAccountAddress: targetAddress,
        proposedSessionAddress: proposedSession,
        deadline: deadline,
        sig: sig,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.accountCenterRecoveryVoteStarted)),
        );
        await Future.delayed(const Duration(seconds: 3));
        await _checkRecoveryStatus(_recoveryTargetContact!);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizedError(context.l10n, PublicOS.lastError,
                fallback: context.l10n.revertRecoveryFailed)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(context.l10n, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingRecovery = false);
    }
  }

  Future<void> _castVote(bool voteToAdd) async {
    final targetAddress = _recoveryTargetContact?.publicosAddress;
    if (targetAddress == null || _isCastingVote) return;
    final l10n = context.l10n;
    setState(() => _isCastingVote = true);
    try {
      await HapticFeedback.lightImpact();
      final success = await PublicOSRecovery.castRecoveryVote(
        targetAccountAddress: targetAddress,
        voteToAdd: voteToAdd,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              voteToAdd
                  ? l10n.accountCenterVotedApprove
                  : l10n.accountCenterVotedReject,
            ),
          ),
        );
        await Future.delayed(const Duration(seconds: 3));
        await _checkRecoveryStatus(_recoveryTargetContact!);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizedError(context.l10n, PublicOS.lastError,
                fallback: context.l10n.errCastVoteFailed)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(context.l10n, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isCastingVote = false);
    }
  }

  void _clearRecoverySelection() {
    setState(() {
      _recoveryTargetContact = null;
      _isCheckingRecovery = false;
      _isRecoveryContactForTarget = false;
      _recoveryThreshold = 0;
      _activeRecoverySession = null;
      _recoveryError = null;
    });
  }

  // ── My recovery contacts ─────────────────────────────────────────────
  //
  // The picker sheet is reused from UserAccountSettings' file rather than
  // re-implemented.

  void _showAddRecoveryContactSheet() {
    final tokens = GlassTokens.of(context);
    showGlassSheetDialog<void>(
      context: context,
      width: DialogWidth.m,
      builder: (sheetContext) => AddRecoveryContactSheet(
        accentColor: tokens.starkWhite,
        onContactSelected: (contact) {
          Navigator.pop(sheetContext);
          _confirmAddRecoveryContact(contact);
        },
      ),
    );
  }

  Future<void> _addRecoveryContact(EthereumAddress contactAddress) async {
    if (_isAddingRecoveryContact) return;
    final l10n = context.l10n;
    setState(() {
      _isAddingRecoveryContact = true;
      _actionStatus = l10n.acctSettingsAddingConfirming;
    });
    try {
      final success = await PublicOSRecovery.addRecoveryContact(contactAddress);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.acctSettingsRecoveryContactAdded)),
        );
        await _loadData(silent: true);
      } else {
        _errorSnack(PublicOS.lastError, (l) => l.errAddRecoveryFailed);
      }
    } catch (e) {
      _errorSnack(e, (l) => l.errAddRecoveryFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isAddingRecoveryContact = false;
          _actionStatus = null;
        });
      }
    }
  }

  Future<void> _removeRecoveryContact(EthereumAddress contactAddress) async {
    final l10n = context.l10n;
    final tokens = GlassTokens.of(context);
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
          l10n.acctSettingsRemoveRecoveryTitle,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          l10n.acctSettingsRemoveRecoveryConfirm(
            _truncateAddress(contactAddress.eip55With0x),
          ),
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
                  fontFamily: 'SpaceGrotesk', color: tokens.textDim),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.acctSettingsRemove,
              style: TextStyle(
                  fontFamily: 'SpaceGrotesk', color: tokens.fallbackAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionStatus = l10n.acctSettingsRemove);
    try {
      final success =
          await PublicOSRecovery.removeRecoveryContact(contactAddress);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.acctSettingsRecoveryContactRemoved)),
        );
        await _loadData(silent: true);
      } else {
        _errorSnack(PublicOS.lastError, (l) => l.errRemoveRecoveryFailed);
      }
    } catch (e) {
      _errorSnack(e, (l) => l.errRemoveRecoveryFailed);
    } finally {
      if (mounted) setState(() => _actionStatus = null);
    }
  }

  void _confirmAddRecoveryContact(Contact contact) {
    final l10n = context.l10n;
    final tokens = GlassTokens.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        title: Text(
          l10n.acctSettingsAddRecoveryContactTitle,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.acctSettingsAddRecoveryIntro,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            _recoveryContactRow(tokens, contact),
            const SizedBox(height: 14),
            _infoCallout(
              tokens,
              icon: Icons.warning_amber_rounded,
              title: l10n.acctSettingsRecoveryPermissionsTitle,
              body: l10n.acctSettingsRecoveryPermissionsBody,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.dlgCancel,
              style: TextStyle(
                  fontFamily: 'SpaceGrotesk', color: tokens.textDim),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _addRecoveryContact(contact.publicosAddress!);
            },
            child: Text(
              l10n.acctSettingsAddRecoveryContactTitle,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Who can add me to groups ─────────────────────────────────────────
  //
  // The switch, and when it is off the list of
  // people who may add me (5 adds each, burned per add). Every write is one
  // tx behind the blocking overlay, then a full reload.

  Future<void> _orgAddWrite(Future<bool> Function() send) async {
    final l10n = context.l10n;
    setState(() => _actionStatus = l10n.orgAddSaving);
    try {
      final ok = await send();
      if (!mounted) return;
      if (ok) {
        await _loadData(silent: true);
      } else {
        _errorSnack(PublicOS.lastError, (l) => l.orgAddFailed);
      }
    } catch (e) {
      _errorSnack(e, (l) => l.orgAddFailed);
    } finally {
      if (mounted) setState(() => _actionStatus = null);
    }
  }

  /// The recovery friends sheet, reused with its own wording; orgs and the
  /// people already on the list are left out.
  void _showAllowFriendSheet() {
    final l10n = context.l10n;
    final tokens = GlassTokens.of(context);
    showGlassSheetDialog<void>(
      context: context,
      width: DialogWidth.m,
      builder: (sheetContext) => AddRecoveryContactSheet(
        accentColor: tokens.starkWhite,
        title: l10n.orgAddSheetTitle,
        heading: l10n.orgAddSheetHeading,
        description: l10n.orgAddSheetBody,
        excludeAddresses: {
          for (final r in _orgAdders)
            if (r.contact.publicosAddress != null)
              r.contact.publicosAddress!.eip55With0x.toLowerCase(),
        },
        individualsOnly: true,
        onContactSelected: (contact) {
          Navigator.pop(sheetContext);
          final adder = contact.publicosAddress;
          if (adder == null) return;
          _orgAddWrite(() => PublicOSGovernance.permitAdder(adder));
        },
      ),
    );
  }

  Future<void> _revokeOrgAdder(Contact contact) async {
    final adder = contact.publicosAddress;
    if (adder == null) return;
    final l10n = context.l10n;
    final tokens = GlassTokens.of(context);
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
          l10n.orgAddRemoveTitle,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          l10n.orgAddRemoveBody(contact.displayName),
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
                  fontFamily: 'SpaceGrotesk', color: tokens.textDim),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.acctSettingsRemove,
              style: TextStyle(
                  fontFamily: 'SpaceGrotesk', color: tokens.fallbackAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _orgAddWrite(() => PublicOSGovernance.revokeAdder(adder));
  }

  // ── Account tags (client twin) ───────────────────────────────────────
  // Self-declared labels other apps read: `mature_content` (viewers confirm
  // 18+ first) and `automated_account` (a robot replaces the ghost; private
  // accounts only, so citizens never see the row). On = a profile record
  // `true`; off = the record deleted.

  Future<void> _setAccountTag(String key, bool on) async {
    if (_actionStatus != null) return;
    final l10n = context.l10n;
    setState(() => _actionStatus = l10n.accountTagSaving);
    try {
      // Both answer false on failure rather than throwing.
      final ok = on
          ? await PublicOSContacts.setRecord(Record.asProfile(
              key: key,
              value: 'true',
              expiration: DateTime.now().add(const Duration(days: 5 * 365)),
            ))
          : await PublicOSContacts.deleteRecord(key);
      if (!ok) throw StateError('account tag $key not written');
      if (!mounted) return;
      setState(() => _actionStatus = l10n.acctSettingsRefreshingProfile);
      await AppStateNotifier.loadMyContact();
      if (!mounted) return;
      await _loadData(silent: true);
    } catch (e) {
      _errorSnack(e, (l) => l.errAccountTagFailed);
    } finally {
      if (mounted) setState(() => _actionStatus = null);
    }
  }

  Widget _buildAccountTagsCard(GlassTokens tokens) {
    final l10n = context.l10n;
    final c = _myContact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toggleRow(
          tokens,
          title: l10n.accountTagMature,
          subtitle: l10n.accountTagMatureSub,
          value: c?.isMatureContent ?? false,
          onChanged: (on) => _setAccountTag('mature_content', on),
        ),
        if (!_isCitizen) ...[
          const SizedBox(height: 8),
          _toggleRow(
            tokens,
            title: l10n.accountTagAutomated,
            subtitle: l10n.accountTagAutomatedSub,
            value: c?.isAutomatedAccount ?? false,
            onChanged: (on) => _setAccountTag('automated_account', on),
          ),
        ],
      ],
    );
  }

  // ── Accent colour ────────────────────────────────────────────────────

  Future<void> _updateAccentColor(Color color) async {
    final l10n = context.l10n;
    setState(() => _actionStatus = l10n.acctSettingsSavingColor);
    try {
      await PublicOSContacts.setRecord(Record.asSettings(
        key: 'color',
        // Same 32-bit ARGB int the deprecated Color.value produced, so records
        // written by the old settings screen still parse.
        value: color.toARGB32().toString(),
        isSystem: true,
        expiration: DateTime.now().add(const Duration(days: 365)),
      ));
      if (!mounted) return;
      setState(() => _actionStatus = l10n.acctSettingsRefreshingProfile);
      // Repaints the whole app's accent, not just this page.
      await AppStateNotifier.loadMyContact();
      if (!mounted) return;
      await _loadData(silent: true);
      if (!mounted) return;
      // Only now does the staged pick become the saved one. On a throw it
      // stays staged, so the user doesn't silently lose their choice.
      setState(() => _stagedAccent = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accentColorSaved)),
      );
    } catch (e) {
      _errorSnack(e, (l) => l.errUpdateColorFailed);
    } finally {
      if (mounted) setState(() => _actionStatus = null);
    }
  }

  /// Localized error snackbar. Reads `context.l10n` synchronously so async
  /// catch sites stay free of use_build_context_synchronously.
  void _errorSnack(Object? error, String Function(AppLocalizations) fallback) {
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(localizedError(l10n, error, fallback: fallback(l10n))),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ── Formatters ───────────────────────────────────────────────────────

  String _truncateAddress(String address) {
    if (address.length < 12) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
  }

  String _formatExpiration(int timestamp) {
    final l10n = context.l10n;
    final expiration = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    if (expiration.isBefore(now)) return l10n.accountCenterExpired;
    final diff = expiration.difference(now);
    if (diff.inDays > 0) {
      return l10n.accountCenterRemainingDays(diff.inDays, diff.inHours % 24);
    }
    if (diff.inHours > 0) {
      return l10n.accountCenterRemainingHours(diff.inHours, diff.inMinutes % 60);
    }
    return l10n.accountCenterRemainingMinutes(diff.inMinutes);
  }

  // ──────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SystemAppScaffold(
      // DESKTOP DELTA: centre in a 720px column instead of
      // stretching to the window edge — same width as `settings_pane`.
      maxContentWidth: 720,
      // DESKTOP DELTA: the body's RefreshIndicator is a PULL
      // gesture — a mouse cannot trigger it, so without this button the page
      // has no way to refresh at all. Mirrors the refresh action bsp_dialog
      // already uses (`bsp_dialog.dart:418`).
      actions: [
        Builder(
          builder: (context) => IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded,
                size: 19, color: GlassTokens.of(context).textDim),
            onPressed: () => _loadData(silent: true),
          ),
        ),
      ],
      title: context.l10n.accountCenterTitle,
      icon: Icons.badge_rounded,
      asset: 'assets/system_apps/account.png',
      pinHeader: true,
      builder: (context, scrollController, tokens) {
        return Stack(
          children: [
            if (!_isLoading)
              RefreshIndicator(
                onRefresh: () => _loadData(silent: true),
                color: tokens.starkWhite,
                backgroundColor: tokens.surfaceElevated,
                // Body extends behind the AppBar (extendBodyBehindAppBar: true);
                // without this offset the spinner renders behind the AppBar.
                edgeOffset:
                    MediaQuery.of(context).padding.top + kToolbarHeight,
                child: _buildLoaded(scrollController, tokens),
              ),
            if (_isLoading)
              const Positioned(
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: PhigitalLoadingWidget(size: 28, showShadows: false),
                ),
              ),
            if (_actionStatus != null)
              Positioned.fill(
                child: Container(
                  color: tokens.background.withValues(alpha: 0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PhigitalLoadingWidget(
                          size: 56,
                          pulse: true,
                          showShadows: false,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          _actionStatus!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
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
        );
      },
    );
  }

  Widget _buildLoaded(
    ScrollController scrollController,
    GlassTokens tokens,
  ) {
    final l10n = context.l10n;
    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        SizedBox(height: kToolbarHeight + 60),
        // The Services / Settings grammar:
        // the identity block stays on top, always visible (it carries the
        // domain status, so an overdue domain is never folded away); every
        // other card is a collapsible group, one open at a time.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _buildIdentityCard(tokens),
        ),
        // Like the domain status: a debt or a suspension clock is never
        // folded away inside a group.
        ..._standingAlerts(tokens).map((a) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: a,
            )),
        for (final section in [
          if (_showPenaltiesGroup)
            _group(
              tokens,
              id: 'penalties',
              icon: Icons.gavel_rounded,
              title: l10n.accountCenterPenaltiesSection,
              trailing: _standing!.owed > BigInt.zero
                  ? _pillBadge(tokens, l10n.penaltiesOwedPill(_ox(_standing!.owed)),
                      _standing!.hasOverdue ? tokens.softDanger : tokens.fallbackAccent)
                  : null,
              children: [_buildPenaltiesCard(tokens)],
            ),
          if (_myFlags.isNotEmpty || _flagsOnMe.isNotEmpty)
            _group(
              tokens,
              id: 'flags',
              icon: Icons.flag_outlined,
              title: l10n.accountCenterFlagsSection,
              trailing: _flagsOnMe.any((f) => f.isOpen)
                  ? _pillBadge(
                      tokens,
                      l10n.flagsPillOpen(
                          _flagsOnMe.where((f) => f.isOpen).length.toString()),
                      tokens.softDanger)
                  : null,
              children: [_buildFlagsCard(tokens)],
            ),
          _group(
            tokens,
            id: 'devices',
            icon: Icons.devices_rounded,
            title: l10n.accountCenterDevices,
            trailing: _pillBadge(
                tokens, '${_sessions.length}', tokens.connectedAccent),
            children: [_buildDevicesCard(tokens)],
          ),
          // My recovery contacts (who can reseed me) sits directly above the
          // friend-recovery group (whose reseed I vote on). Adjacent on
          // purpose: the pairing is what makes the two directions legible.
          _group(
            tokens,
            id: 'recovery',
            icon: Icons.shield_rounded,
            title: l10n.acctSettingsRecoveryContacts,
            trailing: _myRecoveryContacts.isEmpty
                ? null
                : _pillBadge(tokens, '${_myRecoveryContacts.length}',
                    tokens.connectedAccent),
            children: [_buildMyRecoveryContactsCard(tokens)],
          ),
          _group(
            tokens,
            id: 'helpRecover',
            icon: Icons.health_and_safety_rounded,
            title: l10n.accountCenterHelpFriendRecover,
            trailing: _helpRecoverPill(tokens),
            children: [_buildRecoveryCard(tokens)],
          ),
          if (_orgAddAvailable)
            _group(
              tokens,
              id: 'orgs',
              icon: Icons.groups_rounded,
              title: l10n.accountCenterOrgsSection,
              // Green label: who can add me, at a glance.
              trailing: _pillBadge(
                tokens,
                _anyoneCanAddMe
                    ? l10n.orgAddPillAnyone
                    : l10n.orgAddPillFriends(_orgAdders.length),
                tokens.connectedAccent,
              ),
              children: [_buildOrgAddCard(tokens)],
            ),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: section,
          ),
        // Full bleed: the swatch strip runs edge to edge and pads its own
        // children, so only the header takes the page gutter.
        _group(
          tokens,
          id: 'accent',
          icon: Icons.palette_rounded,
          title: l10n.acctSettingsAccentColor,
          headerPadding: const EdgeInsets.symmetric(horizontal: 20),
          trailing: _accentDirty
              ? _pillBadge(
                  tokens, l10n.accentColorUnsaved, tokens.fallbackAccent)
              : null,
          children: [_buildAccentColorCard(tokens)],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _group(
            tokens,
            id: 'tags',
            icon: Icons.sell_outlined,
            title: l10n.accountTagsSection,
            children: [_buildAccountTagsCard(tokens)],
          ),
        ),
        // Account creation is a citizens-only sponsor flow, and the exit is
        // last on purpose.
        if (_isCitizen)
          for (final section in [
            _group(
              tokens,
              id: 'create',
              icon: _accountCreationPaused
                  ? Icons.confirmation_number_rounded
                  : Icons.person_add_rounded,
              title: _accountCreationPaused
                  ? l10n.accountCenterCreateAccountInvite
                  : l10n.accountCenterCreateNewAccount,
              children: [_buildCreateAccountCard(tokens)],
            ),
            _group(
              tokens,
              id: 'renounce',
              icon: Icons.logout_rounded,
              title: l10n.accountCenterRenounceSection,
              children: [_buildRenounceCard(tokens)],
            ),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: section,
            ),
        // Delete all records: the very bottom, every individual.
        // Orange, two dialogs and a wait.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _group(
            tokens,
            id: 'clearRecords',
            icon: Icons.delete_sweep_rounded,
            title: l10n.accountCenterClearRecordsSection,
            children: [_buildClearRecordsCard(tokens)],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Community standards (penalties · suspension) ─────────────────────

  /// The group shows once the account has ever had a penalty or is
  /// blacklisted; a clean account never sees it.
  bool get _showPenaltiesGroup =>
      _standing != null &&
      (_standing!.penalties.isNotEmpty || _standing!.blacklisted);

  /// OX with two decimals, the way the Services page shows amounts.
  String _ox(BigInt wei) => (wei.toDouble() / 1e18).toStringAsFixed(2);

  /// Always-visible lines under the identity block: suspended, a pending
  /// suspension date, what is owed, the blacklist. Empty for a clean account.
  List<Widget> _standingAlerts(GlassTokens tokens) {
    final s = _standing;
    if (s == null) return const [];
    final l10n = context.l10n;
    return [
      if (s.suspendedSince != null)
        _alertTile(tokens, Icons.block_rounded, tokens.softDanger,
            l10n.standingSuspendedAlert(_fmtDate(s.suspendedSince!))),
      if (s.suspensionAppliesAt != null)
        _alertTile(tokens, Icons.schedule_rounded, tokens.softDanger,
            l10n.standingNoticeAlert(_fmtDate(s.suspensionAppliesAt!))),
      if (s.owed > BigInt.zero)
        _alertTile(tokens, Icons.gavel_rounded, tokens.fallbackAccent,
            l10n.standingOwedAlert(_ox(s.owed)),
            onTap: () => setState(() => _openGroup = 'penalties')),
      if (s.blacklisted)
        _alertTile(tokens, Icons.gavel_rounded, tokens.fallbackAccent,
            l10n.standingBlacklistedAlert),
    ];
  }

  Widget _alertTile(GlassTokens tokens, IconData icon, Color color, String text,
      {VoidCallback? onTap}) {
    return _tile(
      tokens,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// What I owe: the open
  /// penalties with their reason, progress and deadline, PAY, the overdue
  /// warning for a private, then the closed ones as history.
  Widget _buildPenaltiesCard(GlassTokens tokens) {
    final l10n = context.l10n;
    final s = _standing!;
    final open = s.open;
    final closed =
        s.penalties.where((p) => p.status != PenaltyStatus.open).toList();
    final bodyStyle = TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: tokens.textDim,
      fontSize: 13,
      height: 1.4,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.penaltiesBody, style: bodyStyle),
        const SizedBox(height: 18),
        _miniLabel(tokens, l10n.penaltiesOpenLabel),
        const SizedBox(height: 10),
        if (open.isEmpty)
          Text(l10n.penaltiesNothingOwed, style: bodyStyle)
        else
          _tile(
            tokens,
            child: Column(
              children: [
                for (var i = 0; i < open.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  _penaltyRow(tokens, open[i]),
                ],
              ],
            ),
          ),
        if (open.isNotEmpty) ...[
          if (s.hasOverdue && !_isCitizen) ...[
            const SizedBox(height: 10),
            Text(l10n.penaltiesOverdueWarning,
                style: bodyStyle.copyWith(color: tokens.softDanger)),
          ],
          const SizedBox(height: 14),
          SystemAppActionButton(
            label: l10n.penaltiesPayButton,
            icon: Icons.payments_rounded,
            onTap: _actionStatus == null ? _payPenalties : null,
          ),
        ],
        if (closed.isNotEmpty) ...[
          const SizedBox(height: 18),
          _miniLabel(tokens, l10n.penaltiesHistoryLabel),
          const SizedBox(height: 10),
          _tile(
            tokens,
            child: Column(
              children: [
                for (var i = 0; i < closed.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  _penaltyRow(tokens, closed[i]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Flags on my content (first: they are about me), then the ones I filed.
  /// Tapping one of mine reopens the flag sheet (status + WITHDRAW).
  Widget _buildFlagsCard(GlassTokens tokens) {
    final l10n = context.l10n;
    final bodyStyle = TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: tokens.textDim,
      fontSize: 13,
      height: 1.4,
    );
    Widget list(List<Flag> flags, {required bool mine}) => _tile(
          tokens,
          child: Column(
            children: [
              for (var i = 0; i < flags.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                _flagRow(tokens, flags[i], mine: mine),
              ],
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _miniLabel(tokens, l10n.flagsOnMeLabel),
        const SizedBox(height: 6),
        Text(l10n.flagsOnMeBody, style: bodyStyle),
        const SizedBox(height: 10),
        if (_flagsOnMe.isEmpty)
          Text(l10n.flagsNoneOnMe, style: bodyStyle)
        else
          list(_flagsOnMe, mine: false),
        const SizedBox(height: 18),
        _miniLabel(tokens, l10n.flagsMineLabel),
        const SizedBox(height: 10),
        if (_myFlags.isEmpty)
          Text(l10n.flagsNoneMine, style: bodyStyle)
        else
          list(_myFlags, mine: true),
      ],
    );
  }

  /// One flag: category · kind, the address it points at, then its status.
  Widget _flagRow(GlassTokens tokens, Flag f, {required bool mine}) {
    final l10n = context.l10n;
    final kind = flagKindOf(f);
    final row = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${flagCategoryLabel(l10n, f.category)} · ${flagKindLabel(l10n, kind)}',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        if (f.url.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            f.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontFamily: 'SpaceGrotesk', color: tokens.textDim, fontSize: 11),
          ),
        ],
        if (f.note.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(f.note,
              style: TextStyle(
                  fontFamily: 'SpaceGrotesk', color: tokens.textDim, fontSize: 12)),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                flagDate(context, f.createdAt),
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk', color: tokens.textDim, fontSize: 12),
              ),
            ),
            Text(
              flagStatusText(context, f),
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: f.isOpen ? tokens.softDanger : tokens.textDim,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
    if (!mine || !f.isOpen) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final changed = await showFlagSheet(context,
            owner: f.owner, kind: kind, url: f.url, target: f.target);
        if (changed && mounted) await _loadData();
      },
      child: row,
    );
  }

  /// One penalty: the court's reason, then amount + paid, then the deadline
  /// (open) or how it closed.
  Widget _penaltyRow(GlassTokens tokens, Penalty p) {
    final l10n = context.l10n;
    final String status;
    Color statusColor = tokens.textDim;
    switch (p.status) {
      case PenaltyStatus.open:
        if (p.isOverdue) {
          status = l10n.penaltyOverdueSince(_fmtDate(p.payBefore));
          statusColor = tokens.softDanger;
        } else {
          status = l10n.penaltyPayBy(_fmtDate(p.payBefore));
        }
      case PenaltyStatus.paid:
        status = l10n.penaltyStatusPaid;
      case PenaltyStatus.cancelled:
        status = l10n.penaltyStatusCancelled;
      case PenaltyStatus.promoted:
        status = l10n.penaltyStatusPromoted;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.evidence,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.penaltyPaidOf(_ox(p.paid), _ox(p.amount)),
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              status,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _payPenalties() async {
    final me = PublicOS.myPublicosAddress;
    final s = _standing;
    if (me == null || s == null) return;
    final l10n = context.l10n;
    final paid = await confirmPayPenalties(
      context,
      account: EthereumAddress.fromHex(me),
      owed: s.owed,
    );
    if (!paid || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.penaltiesPaid)));
    await _loadData();
  }

  /// Header pill for the friend-recovery group, by the card's branch.
  Widget? _helpRecoverPill(GlassTokens tokens) {
    final l10n = context.l10n;
    if (_recoveryTargetContact == null ||
        _isCheckingRecovery ||
        _recoveryError != null ||
        !_isRecoveryContactForTarget) {
      return null;
    }
    if (_activeRecoverySession != null) {
      return _pillBadge(
          tokens, l10n.accountCenterActiveVote, tokens.fallbackAccent);
    }
    return _pillBadge(tokens, l10n.accountCenterTrusted, tokens.connectedAccent);
  }

  /// Who can add me to groups: the switch, the list (dashed "empty" when
  /// there is no one), and the wide button that opens the friend picker.
  Widget _buildOrgAddCard(GlassTokens tokens) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toggleRow(
          tokens,
          title: l10n.orgAddAnyoneTitle,
          subtitle: _anyoneCanAddMe
              ? l10n.orgAddAnyoneOnSub
              : l10n.orgAddAnyoneOffSub,
          value: _anyoneCanAddMe,
          onChanged: (on) =>
              _orgAddWrite(() => PublicOSGovernance.setAnyoneCanAddMe(on)),
        ),
        const SizedBox(height: 18),
        _miniLabel(tokens, l10n.orgAddListLabel),
        if (_anyoneCanAddMe) ...[
          const SizedBox(height: 4),
          Text(
            l10n.orgAddListOnHint,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (_orgAdders.isEmpty)
          CustomPaint(
            painter: DashedRRectPainter(color: tokens.borderSubtle, radius: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  l10n.orgAddListEmpty,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          )
        else
          _tile(
            tokens,
            child: Column(
              children: [
                for (var i = 0; i < _orgAdders.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _orgAdderRow(tokens, _orgAdders[i]),
                ],
              ],
            ),
          ),
        const SizedBox(height: 14),
        SystemAppActionButton(
          label: l10n.orgAddAllowFriend,
          icon: Icons.person_add_alt_1_rounded,
          onTap: _showAllowFriendSheet,
        ),
      ],
    );
  }

  /// One person on the list: icon, name, adds left, delete. No top-up button
  /// on purpose.
  Widget _orgAdderRow(GlassTokens tokens, ({Contact contact, int left}) row) {
    final l10n = context.l10n;
    final address = row.contact.publicosAddress?.eip55With0x ?? '';
    return Row(
      children: [
        GlassContactIcon(contact: row.contact, address: address, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            row.contact.displayName,
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
        const SizedBox(width: 10),
        Text(
          l10n.orgAddLeft(row.left),
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: l10n.acctSettingsRemove,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            Icons.delete_outline_rounded,
            color: tokens.fallbackAccent,
            size: 20,
          ),
          onPressed: () => _revokeOrgAdder(row.contact),
        ),
      ],
    );
  }

  /// The citizen's own exit (renounceCitizenship). Two dialogs in front of
  /// it, see
  /// `renounce_citizenship_dialogs.dart`; the write itself is one tx, then a
  /// full reload so the pill, the ticket chip, the create-account card and
  /// the domain status all follow.
  Widget _buildRenounceCard(GlassTokens tokens) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountCenterRenounceBody,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        SystemAppActionButton(
          label: l10n.accountCenterRenounceButton,
          icon: Icons.logout_rounded,
          onTap: _renounceCitizenship,
          accent: tokens.softDanger,
        ),
      ],
    );
  }

  /// Erase every record of this account. Two dialogs in
  /// front (`clear_records_dialogs.dart`), then `clearAllMyRecords` in passes
  /// of 50 with a live count, then a full reload.
  Widget _buildClearRecordsCard(GlassTokens tokens) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountCenterClearRecordsBody,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        SystemAppActionButton(
          label: l10n.accountCenterClearRecordsButton,
          icon: Icons.delete_sweep_rounded,
          onTap: _actionStatus == null ? _clearAllRecords : null,
          accent: tokens.fallbackAccent,
        ),
      ],
    );
  }

  Future<void> _clearAllRecords() async {
    final l10n = context.l10n;
    final confirmed = await confirmClearAllRecords(context);
    if (!confirmed || !mounted) return;
    setState(() => _actionStatus = l10n.clearRecordsWorking(0, 0));
    int? removed;
    try {
      removed = await PublicOSContacts.clearAllMyRecords(
        onProgress: (done, left) {
          if (mounted) {
            setState(() => _actionStatus = l10n.clearRecordsWorking(done, left));
          }
        },
      );
    } finally {
      if (mounted) setState(() => _actionStatus = null);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(removed != null
          ? l10n.clearRecordsDone(removed)
          : localizedError(l10n, PublicOS.lastError, fallback: l10n.clearRecordsFailed)),
    ));
    if (removed != null) await _loadData();
  }

  Future<void> _renounceCitizenship() async {
    final l10n = context.l10n;
    // The contract takes this from a permanent key only; say so before the
    // two dialogs rather than after them.
    final permanent = await PublicOSAccounts.isActiveSessionPermanent();
    if (!mounted) return;
    if (permanent == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.renounceNeedsPermanentKey)),
      );
      return;
    }
    final confirmed = await confirmRenounceCitizenship(context);
    if (!confirmed || !mounted) return;
    setState(() => _actionStatus = l10n.renounceWorking);
    bool ok = false;
    try {
      ok = await PublicOSAccounts.renounceCitizenship();
    } finally {
      if (mounted) setState(() => _actionStatus = null);
    }
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.renounceDone)),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizedError(context.l10n, PublicOS.lastError,
              fallback: l10n.renounceFailed)),
        ),
      );
    }
  }

  // ── Cards ────────────────────────────────────────────────────────────

  Widget _buildIdentityCard(GlassTokens tokens) {
    final l10n = context.l10n;
    final name = _myContact?.publicosDisplayName ??
        _myContact?.displayName ??
        l10n.accountCenterUnknown;
    final address = _myContact?.publicosAddress?.eip55With0x ??
        PublicOS.myPublicosAddress ??
        '';

    // Free-change tickets (citizens only — their 5+ names rename for free).
    final freeCount =
        _isCitizen ? (_annualWindowOpen ? 1 : 0) + _bonusCount : 0;

    // Domain status — drives the DOMAIN pill + the "paid until" line.
    final nowSec = BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final lifetime = _domainPaidUntil > _domainNeverSentinel;
    final active = !lifetime && _domainPaidUntil > nowSec;
    final notSet = !lifetime && _domainPaidUntil == BigInt.zero;
    final overdue = !lifetime && !active && !notSet;
    final (statusLabel, statusColor) = lifetime
        ? (l10n.accountCenterStatusLifetime, tokens.connectedAccent)
        : active
            ? (l10n.accountCenterStatusActive, tokens.connectedAccent)
            : notSet
                ? (l10n.accountCenterStatusNotSet, tokens.textDim)
                : (l10n.accountCenterStatusOverdue, const Color(0xFFFFAB40));
    final paidUntilText = lifetime
        ? l10n.accountCenterNever
        : notSet
            ? '—'
            : _fmtDate(DateTime.fromMillisecondsSinceEpoch(
                _domainPaidUntil.toInt() * 1000));
    final freeText = freeCount > 0 ? '🎫 $freeCount' : l10n.accountCenterNone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GlassContactIcon(
              contact: _myContact,
              address: address,
              size: 52,
            ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: tokens.starkWhite,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        if (address.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: address));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(l10n.accountCenterAddressCopied)),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            _truncateAddress(address),
                            style: TextStyle(
                    fontFamily: 'monospace',
                              fontSize: 12,
                              color: tokens.textDim,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.copy_rounded,
                            size: 11,
                            color: tokens.textDim,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 10),
            _isCitizen
                ? _pillBadge(
                    tokens, l10n.accountCenterCitizen, tokens.connectedAccent)
                : _pillBadge(tokens,
                    '${_vouchCount.toInt()} / ${_vouchThreshold.toInt()}',
                    tokens.fallbackAccent),
          ],
        ),
        // Citizenship is opt-in: enough vouches make the account
        // eligible, and the claim (agreement + grant, one tx) runs in the same
        // sheet the onboarding flow shows first to an eligible private.
        if (!_isCitizen && _vouchCount >= _vouchThreshold) ...[
          const SizedBox(height: 12),
          SystemAppActionButton(
            label: l10n.accountCenterClaimCitizenship,
            icon: Icons.verified_rounded,
            onTap: _claimCitizenship,
          ),
        ],
        // ── Domain (your name; gates write access) — label / value rows ───
        const SizedBox(height: 16),
        _domainStatRow(tokens, l10n.accountCenterDomainStatus,
            _pillBadge(tokens, statusLabel, statusColor)),
        _domainStatRow(
          tokens,
          l10n.accountCenterPaidUntil,
          Text(
            paidUntilText,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: overdue ? const Color(0xFFFFAB40) : tokens.starkWhite,
            ),
          ),
        ),
        _domainStatRow(
          tokens,
          l10n.accountCenterFreeNameChanges,
          Text(
            freeText,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: tokens.starkWhite,
            ),
          ),
        ),
        if (_myContact != null) ...[
          const SizedBox(height: 14),
          SystemAppActionButton(
            label: l10n.accountCenterManageDomain,
            icon: Icons.travel_explore_rounded,
            onTap: _openManageDomain,
          ),
        ],
      ],
    );
  }


  /// Opens the unified Domain Store sheet (search / renew / claim). The account
  /// center shows its own domain status above, so the sheet header is hidden
  /// (showStatus:false); onChanged refreshes this page after a successful tx.
  void _openManageDomain() {
    showDomainStoreSheet(
      context,
      showStatus: false,
      onChanged: () => _loadData(silent: true),
    );
  }

  /// One domain label / value row — title left (dim), value pushed far right.
  Widget _domainStatRow(GlassTokens tokens, String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: tokens.textDim,
            ),
          ),
          const Spacer(),
          value,
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _buildDevicesCard(GlassTokens tokens) {
    final l10n = context.l10n;
    final currentSessionAddress =
        PublicOS.sessionBlockchainAddress?.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoChip(
            tokens,
            Icons.info_outline_rounded,
            l10n.accountCenterSessionsInfo,
          ),
          const SizedBox(height: 12),
          ..._sessions.map((sessionAddress) {
            final isCurrent =
                sessionAddress.eip55With0x.toLowerCase() == currentSessionAddress;
            final isBeingRemoved =
                _sessionBeingRemoved == sessionAddress.eip55With0x;
            final canRemove = _sessions.length > 1 && !isCurrent;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: tokens.glassFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrent
                              ? tokens.connectedAccent.withValues(alpha: 0.5)
                              : tokens.borderSubtle,
                        ),
                      ),
                      child: Icon(
                        isCurrent
                            ? Icons.smartphone_rounded
                            : Icons.devices_other_rounded,
                        color: isCurrent
                            ? tokens.connectedAccent
                            : tokens.textDim,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: sessionAddress.eip55With0x,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text(l10n.accountCenterAddressCopied),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _truncateAddress(
                                      sessionAddress.eip55With0x,
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: tokens.starkWhite,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.copy_rounded,
                                  size: 11,
                                  color: tokens.textDim,
                                ),
                              ],
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(height: 6),
                            _pillBadge(
                              tokens,
                              l10n.accountCenterCurrent,
                              tokens.connectedAccent,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (canRemove)
                      isBeingRemoved
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: tokens.fallbackAccent,
                                strokeWidth: 2,
                              ),
                            )
                          : GestureDetector(
                              onTap: () => _confirmRemoveSession(sessionAddress),
                              child: Icon(
                                Icons.remove_circle_outline_rounded,
                                color: tokens.fallbackAccent,
                                size: 18,
                              ),
                            ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          SystemAppActionButton(
            label: _isAddingSession
                ? l10n.accountCenterAdding
                : l10n.accountCenterAddSession,
            icon: Icons.add_rounded,
            onTap: _isAddingSession ? null : _showAddSessionSheet,
          ),
        ],
      );
  }

  /// The friends who can vote to reseed MY account. Not to be confused with
  /// [_buildRecoveryCard] below, where I am the voter on someone else's.
  Widget _buildMyRecoveryContactsCard(GlassTokens tokens) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_myRecoveryContacts.isEmpty) ...[
          _infoChip(
            tokens,
            Icons.info_outline_rounded,
            l10n.acctSettingsAddTrustedContactsHint,
          ),
        ] else ...[
          if (_myRecoveryThreshold > 0)
            _infoChip(
              tokens,
              Icons.info_outline_rounded,
              l10n.acctSettingsRecoveryThreshold(
                _myRecoveryThreshold,
                _myRecoveryContacts.length,
              ),
            ),
          const SizedBox(height: 12),
          ..._myRecoveryContacts.map(
            (contact) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _myRecoveryContactTile(tokens, contact),
            ),
          ),
        ],
        const SizedBox(height: 6),
        SystemAppActionButton(
          label: _isAddingRecoveryContact
              ? l10n.acctSettingsAddingConfirming
              : l10n.acctSettingsAddRecoveryContact,
          icon: Icons.person_add_alt_1_rounded,
          onTap: _isAddingRecoveryContact ? null : _showAddRecoveryContactSheet,
        ),
      ],
    );
  }

  Widget _myRecoveryContactTile(GlassTokens tokens, Contact contact) {
    final address = contact.publicosAddress?.eip55With0x ?? '';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        children: [
          GlassContactIcon(contact: contact, address: address, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.displayName,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tokens.starkWhite,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _truncateAddress(address),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: tokens.textDim,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _removeRecoveryContact(contact.publicosAddress!),
            child: Icon(
              Icons.remove_circle_outline_rounded,
              color: tokens.fallbackAccent,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// Accent colour, staged. Picking a swatch only moves [_stagedAccent]; the
  /// on-chain write waits for SAVE, so the preview bubble can be consulted
  /// first. The colour is a public record, and the copy says so.
  ///
  /// The swatch strip is the one full-bleed element on this page: it scrolls
  /// edge-to-edge, so every child here carries its own [_accentInset] padding
  /// rather than inheriting the page's.
  Widget _buildAccentColorCard(GlassTokens tokens) {
    final l10n = context.l10n;
    final shown = _stagedAccent ?? _accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: _accentInset,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoChip(
                  tokens, Icons.public_rounded, l10n.accentColorRecordNotice),
              const SizedBox(height: 14),
              // _infoChip(
              //     tokens, Icons.opacity_rounded, l10n.accentColorBubbleNotice),
              // const SizedBox(height: 14),
              _accentPreviewBubble(tokens, shown),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _accentSwatchStrip(tokens, shown),
        if (_accentDirty) ...[
          const SizedBox(height: 14),
          Padding(
            padding: _accentInset,
            child: Row(
              children: [
                Expanded(
                  child: SystemAppActionButton(
                    label: l10n.accentColorSave,
                    icon: Icons.check_rounded,
                    onTap: () => _updateAccentColor(_stagedAccent!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SystemAppActionButton(
                    label: l10n.accentColorDiscard,
                    icon: Icons.undo_rounded,
                    onTap: () => setState(() => _stagedAccent = null),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Full-bleed horizontal swatch strip. Scrolls to the screen edges; the 20pt
  /// gutter lives in the scroll view's `padding`, so the first and last swatch
  /// line up with the copy above while the strip itself can run off-screen.
  Widget _accentSwatchStrip(GlassTokens tokens, Color? shown) {
    return SizedBox(
      height: _accentSwatchSize,
      // DESKTOP DELTA: Flutter's default ScrollBehavior only lets
      // touch/stylus DRAG a scrollable, so with a mouse the swatches past the
      // pane edge would be unreachable by dragging — and with 53 presets most
      // of the ramp is off-screen. Same fix as the Messages
      // chip bar (`explorer_chip.dart`). ⚠ The wheel does not work on its
      // own either (a mouse wheel sends dy
      // only, a horizontal list ignores it). [HorizontalWheel] fixes that.
      child: HorizontalWheel(
        child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListView.separated(
          controller: _accentScrollCtrl,
          scrollDirection: Axis.horizontal,
          padding: _accentInset,
          itemCount: PhigitalStyle.colorPresets.length,
          separatorBuilder: (_, __) => const SizedBox(width: _accentSwatchGap),
          itemBuilder: (_, i) =>
              _accentSwatch(tokens, PhigitalStyle.colorPresets[i], shown),
        ),
        ),
      ),
    );
  }

  /// Bring the saved colour into view once, after the first load paints. With
  /// 53 swatches the current pick is usually off-screen, and a picker that
  /// opens without showing your own selection is a picker you can't trust.
  void _scrollAccentToSelection() {
    final target = _stagedAccent ?? _accentColor;
    if (target == null || !_accentScrollCtrl.hasClients) return;
    final index = PhigitalStyle.colorPresets.indexOf(target);
    if (index < 0) return; // legacy colour, not in the ramp

    const stride = _accentSwatchSize + _accentSwatchGap;
    final viewport = _accentScrollCtrl.position.viewportDimension;
    final offset = (index * stride) - (viewport / 2) + (_accentSwatchSize / 2);
    _accentScrollCtrl.jumpTo(
      offset.clamp(0.0, _accentScrollCtrl.position.maxScrollExtent),
    );
  }

  /// A faithful still of an outgoing chat bubble.
  ///
  /// Values copied from `message_widget.dart` — keep them in lockstep: fill
  /// `_bubbleFill` at full opacity, foreground `_bubbleFg` (black or white by
  /// max contrast, crossover at luminance 0.179), radius 12 with a 4pt top-right
  /// notch, padding 8/8, timestamp `Colors.white70` @12 *outside* the bubble and
  /// therefore on the page background, right-aligned.
  ///
  /// The bubble IS the swatch (no tint), so this widget does not exist to
  /// reveal a discrepancy — it exists to show the text contrast
  /// the fill implies, which is the one thing a swatch can't tell you.
  Widget _accentPreviewBubble(GlassTokens tokens, Color? brand) {
    final l10n = context.l10n;
    final fill = brand ?? Colors.blue.shade700;
    final fg = _foregroundFor(fill);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(64, 16, 8, 12),
      decoration: BoxDecoration(
        // The real chat scaffold.
        color: tokens.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Text(
              l10n.accentColorPreviewSample,
              style: TextStyle(color: fg, fontSize: 16),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              l10n.accentColorPreviewTime,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Mirror of `message_widget.dart::_bubbleFg`. Pure black or pure white,
  /// whichever contrasts more — NOT the naive `computeLuminance() < 0.5`
  /// midpoint, which would put white on amber at 2.15:1.
  Color _foregroundFor(Color fill) =>
      fill.computeLuminance() < 0.179 ? Colors.white : Colors.black;

  /// Swatches are the bubble now — full opacity, no tint. A tick mark in the
  /// swatch's own foreground doubles as a contrast preview.
  Widget _accentSwatch(GlassTokens tokens, Color color, Color? shown) {
    final isSelected = color == shown;

    return GestureDetector(
      onTap: () => setState(() => _stagedAccent = color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // No margin — the strip's separator owns the gap, so `stride` in
        // _scrollAccentToSelection stays == _accentSwatchSize + _accentSwatchGap.
        width: _accentSwatchSize,
        height: _accentSwatchSize,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? tokens.starkWhite : tokens.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isSelected
            ? Icon(
                Icons.check_rounded,
                color: _foregroundFor(color),
                size: 20,
              )
            : null,
      ),
    );
  }

  Widget _buildRecoveryCard(GlassTokens tokens) {
    final l10n = context.l10n;
    final target = _recoveryTargetContact;

    // No contact selected
    if (target == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoChip(
            tokens,
            Icons.info_outline_rounded,
            l10n.accountCenterRecoveryInfo,
          ),
          const SizedBox(height: 14),
          SystemAppActionButton(
            label: l10n.accountCenterSelectFriend,
            icon: Icons.person_search_rounded,
            onTap: _showRecoveryContactSearchSheet,
          ),
        ],
      );
    }

    // Loading
    if (_isCheckingRecovery) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _recoveryContactRow(tokens, target),
          const SizedBox(height: 14),
          Center(
            child: CircularProgressIndicator(
              color: tokens.starkWhite,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l10n.accountCenterCheckingRecoveryStatus,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                color: tokens.textDim,
              ),
            ),
          ),
        ],
      );
    }

    // Error
    if (_recoveryError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _recoveryContactRow(tokens, target),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tokens.fallbackAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: tokens.fallbackAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: tokens.fallbackAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _recoveryError!,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 12,
                      color: tokens.fallbackAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SystemAppActionButton(
                  label: l10n.accountCenterRetry,
                  icon: Icons.refresh_rounded,
                  onTap: () => _checkRecoveryStatus(target),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SystemAppActionButton(
                  label: l10n.accountCenterChange,
                  icon: Icons.swap_horiz_rounded,
                  onTap: _clearRecoverySelection,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Not a recovery contact
    if (!_isRecoveryContactForTarget) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _recoveryContactRow(tokens, target),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tokens.fallbackAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: tokens.fallbackAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: tokens.fallbackAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.accountCenterNotRecoveryContact,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 12,
                      color: tokens.fallbackAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SystemAppActionButton(
            label: l10n.accountCenterChangeFriend,
            icon: Icons.swap_horiz_rounded,
            onTap: _showRecoveryContactSearchSheet,
          ),
        ],
      );
    }

    // Active recovery session
    if (_activeRecoverySession != null) {
      final session = _activeRecoverySession!;
      final addVotes = session['addVotesCount'] as int? ?? 0;
      final cancelVotes = session['cancelVotesCount'] as int? ?? 0;
      final threshold =
          session['requiredThreshold'] as int? ?? _recoveryThreshold;
      final expirationTs = session['expirationTimestamp'] as int? ?? 0;
      final proposedSession =
          session['proposedSessionAddress'] as String? ?? '';
      final isExpired = expirationTs > 0 &&
          DateTime.fromMillisecondsSinceEpoch(expirationTs * 1000)
              .isBefore(DateTime.now());

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _recoveryContactRow(tokens, target),
          const SizedBox(height: 12),
          _kvRow(tokens, l10n.accountCenterProposed,
              _truncateAddress(proposedSession)),
          const SizedBox(height: 6),
          _kvRow(
            tokens,
            l10n.accountCenterVotes,
            l10n.accountCenterVotesValue(addVotes, cancelVotes, threshold),
          ),
          if (expirationTs > 0) ...[
            const SizedBox(height: 6),
            _kvRow(tokens, l10n.accountCenterExpires,
                _formatExpiration(expirationTs)),
          ],
          if (isExpired) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tokens.fallbackAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_off_rounded,
                    color: tokens.fallbackAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.accountCenterSessionExpired,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 12,
                      color: tokens.fallbackAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (isExpired)
            SystemAppActionButton(
              label: l10n.accountCenterChangeFriend,
              icon: Icons.swap_horiz_rounded,
              onTap: _showRecoveryContactSearchSheet,
            )
          else
            Row(
              children: [
                Expanded(
                  child: SystemAppActionButton(
                    label: _isCastingVote
                        ? l10n.accountCenterVoting
                        : l10n.accountCenterApprove,
                    icon: Icons.check_circle_rounded,
                    onTap: _isCastingVote ? null : () => _castVote(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SystemAppActionButton(
                    label: _isCastingVote
                        ? l10n.accountCenterVoting
                        : l10n.accountCenterReject,
                    icon: Icons.cancel_rounded,
                    onTap: _isCastingVote ? null : () => _castVote(false),
                  ),
                ),
              ],
            ),
        ],
      );
    }

    // Recovery contact, no active session
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recoveryContactRow(tokens, target),
        const SizedBox(height: 12),
        _kvRow(tokens, l10n.accountCenterThreshold,
            l10n.accountCenterThresholdValue(_recoveryThreshold)),
        const SizedBox(height: 10),
        _infoChip(
          tokens,
          Icons.check_circle_outline_rounded,
          l10n.accountCenterNoActiveSession,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SystemAppActionButton(
                label: _isStartingRecovery
                    ? l10n.accountCenterStarting
                    : l10n.accountCenterStartRecoveryAction,
                icon: _isStartingRecovery
                    ? Icons.hourglass_top_rounded
                    : Icons.restore_rounded,
                onTap: _isStartingRecovery ? null : _showStartRecoverySheet,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SystemAppActionButton(
                label: l10n.accountCenterChange,
                icon: Icons.swap_horiz_rounded,
                onTap: _showRecoveryContactSearchSheet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Account creation is never self-serve from this device — it's a citizens-only
  // sponsor flow with NO button. Onboarding happens only when the citizen scans
  // a newcomer's `publicos://new_account/<claim>` QR with the OS camera, which
  // deep-links to `/new_account/:payload` and opens the (invite-aware) confirm
  // dialog. This card is informational; private accounts never see it (gated in
  // _buildLoaded), so both branches below assume the viewer is a citizen.
  Widget _buildCreateAccountCard(GlassTokens tokens) {
    final l10n = context.l10n;
    // Invite season: self-serve creation is paused network-wide, so onboarding a
    // newcomer spends one of the citizen's wave invites.
    if (_accountCreationPaused) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoChip(
            tokens,
            Icons.confirmation_number_rounded,
            _invitesLeft > 0
                ? l10n.accountCenterInviteSeasonHave
                : l10n.accountCenterInviteSeasonNone,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: tokens.connectedAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: tokens.connectedAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.confirmation_number_rounded,
                    color: tokens.connectedAccent, size: 20),
                const SizedBox(width: 12),
                Text(
                  '$_invitesLeft',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: tokens.starkWhite,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.accountCenterInvitesLeftLabel(_invitesLeft),
                  style: TextStyle(fontSize: 13, color: tokens.textDim),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Open creation: no invites needed, but onboarding is still camera-scan only.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoChip(
          tokens,
          Icons.qr_code_scanner_rounded,
          l10n.accountCenterCreateAccountInfo,
        ),
      ],
    );
  }

  Widget _recoveryContactRow(GlassTokens tokens, Contact contact) {
    final address = contact.publicosAddress?.eip55With0x ?? '';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        children: [
          GlassContactIcon(contact: contact, address: address, size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.displayName,
                  style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tokens.starkWhite,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _truncateAddress(address),
                    style: TextStyle(
                    fontFamily: 'monospace',
                      fontSize: 10,
                      color: tokens.textDim,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Leaf helpers ─────────────────────────────────────────────────────

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

  /// Collapsible group, copied from the Services page: one group
  /// open at a time, the whole header row toggles, the chevron turns 90°.
  /// [headerPadding] insets only the header, for a full-bleed body.
  Widget _group(
    GlassTokens tokens, {
    required String id,
    required IconData icon,
    required String title,
    Widget? trailing,
    EdgeInsets headerPadding = EdgeInsets.zero,
    required List<Widget> children,
  }) {
    final open = _openGroup == id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: headerPadding,
          child: _GroupHeader(
            icon: icon,
            title: title,
            trailing: trailing,
            open: open,
            onTap: () => setState(() => _openGroup = open ? null : id),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: open
              ? Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Borderless settings tile (Services / Settings): tiles hold rows; chips
  /// and buttons sit beside them, never inside.
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

  /// Settings' toggle row: the whole tile flips the switch.
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

  Widget _kvRow(GlassTokens tokens, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: tokens.textDim,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.starkWhite,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoChip(GlassTokens tokens, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: tokens.textDim),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                fontSize: 11,
                color: tokens.textDim,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCallout(
    GlassTokens tokens, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.connectedAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tokens.connectedAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tokens.connectedAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: tokens.connectedAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 12,
              color: tokens.connectedAccent.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

}

// ── Group header ──────────────────────────────────────────────────────────────

/// The tappable header of a collapsible group, copied from the Services
/// page. Grey glyphs that turn white on hover or while open; the title
/// stays white. Teal is never used here: open is a place, not a state.
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

// ═══════════════════════════════════════════════════════════════════════════
// Recovery contact search sheet
// ═══════════════════════════════════════════════════════════════════════════

class _RecoveryContactSearchSheet extends StatefulWidget {
  final void Function(Contact) onSelected;
  const _RecoveryContactSearchSheet({required this.onSelected});

  @override
  State<_RecoveryContactSearchSheet> createState() =>
      _RecoveryContactSearchSheetState();
}

class _RecoveryContactSearchSheetState
    extends State<_RecoveryContactSearchSheet> {
  List<Contact> _allContacts = [];
  List<Contact> _filtered = [];
  Contact? _searchResult;
  bool _isLoading = true;
  bool _isSearching = false;
  String _query = '';
  int _resolveGeneration = 0;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadContacts();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final stored = await PublicOSContacts.getStoredContacts();
      final myAddress =
          PublicOS.myPublicosAddress?.toLowerCase();
      final seen = <String>{};
      final contacts = <Contact>[];
      for (final contact in stored) {
        if (contact.isOrgAccount) continue;
        final addr = contact.publicosAddress;
        if (addr == null) continue;
        final lower = addr.eip55With0x.toLowerCase();
        if (lower == myAddress) continue;
        if (seen.contains(lower)) continue;
        seen.add(lower);
        contacts.add(contact);
      }
      if (mounted) {
        setState(() {
          _allContacts = contacts;
          _filtered = contacts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final next = _searchCtrl.text;
    if (next == _query) return;
    _query = next;
    _filter();
    _resolveOnChain();
  }

  void _filter() {
    final q = _query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _allContacts;
      } else {
        _filtered = _allContacts.where((c) {
          final nameMatch = c.displayName.toLowerCase().contains(q);
          final addrMatch =
              c.publicosAddress?.eip55With0x.toLowerCase().contains(q) ?? false;
          return nameMatch || addrMatch;
        }).toList();
      }
    });
  }

  /// When the local filter would come up empty — or the user typed a real
  /// identifier (address / inbox / on-chain name) — reach to Core and surface
  /// the match as a single result card prepended to the list. Same pattern
  /// as the contacts view in the explorer.
  Future<void> _resolveOnChain() async {
    final trimmed = _query.trim();
    final gen = ++_resolveGeneration;

    if (trimmed.isEmpty) {
      if (_searchResult != null || _isSearching) {
        setState(() {
          _searchResult = null;
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
        setState(() {
          _searchResult = null;
          _isSearching = false;
        });
        return;
      }

      // Skip orgs and self — recovery target must be a personal account.
      final myAddress = PublicOS.myPublicosAddress?.toLowerCase();
      final resolvedAddr =
          resolved.publicosAddress?.eip55With0x.toLowerCase();
      if (resolved.isOrgAccount ||
          resolvedAddr == null ||
          resolvedAddr == myAddress) {
        setState(() {
          _searchResult = null;
          _isSearching = false;
        });
        return;
      }

      // Suppress if already in the loaded list.
      final alreadyLocal = _allContacts.any((c) =>
          c.publicosAddress?.eip55With0x.toLowerCase() == resolvedAddr);

      setState(() {
        _searchResult = alreadyLocal ? null : resolved;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted || gen != _resolveGeneration) return;
      setState(() {
        _searchResult = null;
        _isSearching = false;
      });
    }
  }

  List<Contact> get _displayList {
    final list = List<Contact>.from(_filtered);
    if (_searchResult != null && _query.trim().isNotEmpty) {
      list.insert(0, _searchResult!);
    }
    return list;
  }

  String _truncateAddress(String address) {
    if (address.length < 12) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 1.0,
      maxChildSize: 1.0,
      expand: false,
      builder: (ctx, sheetController) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.accountCenterSelectFriendTitle,
                          style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                            color: tokens.starkWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: tokens.starkWhite,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: tokens.glassFill,
                      border: Border.all(color: tokens.borderSubtle, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
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
                        hintText: l10n.accountCenterSearchHint,
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
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: tokens.starkWhite,
                            strokeWidth: 2,
                          ),
                        )
                      : _displayList.isEmpty
                          ? Center(
                              child: _isSearching
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            color: tokens.starkWhite,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          l10n.accountCenterSearchingOnChain,
                                          style: TextStyle(
                                            fontFamily: 'SpaceGrotesk',
                                            fontSize: 13,
                                            color: tokens.textDim,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      l10n.accountCenterNoContacts,
                                      style: TextStyle(
                                        fontFamily: 'SpaceGrotesk',
                                        fontSize: 13,
                                        color: tokens.textDim,
                                      ),
                                    ),
                            )
                          : ListView.builder(
                              controller: sheetController,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _displayList.length,
                              itemBuilder: (_, i) {
                                final contact = _displayList[i];
                                final address =
                                    contact.publicosAddress?.eip55With0x ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => widget.onSelected(contact),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: tokens.glassFill,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: tokens.borderSubtle,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            GlassContactIcon(
                                              contact: contact,
                                              address: address,
                                              size: 42,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    contact.displayName,
                                                    style:
                                                        TextStyle(
              fontFamily: 'SpaceGrotesk',
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: tokens.starkWhite,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (address.isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      _truncateAddress(address),
                                                      style: TextStyle(
                                                        fontFamily: 'monospace',
                                                        fontSize: 10,
                                                        color: tokens.textDim,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              size: 20,
                                              color: tokens.textDim,
                                            ),
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
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Glass sheet shell for the add-session / create-account / start-recovery
// mini sheets. Matches the bottom-sheet chrome used elsewhere.
// ═══════════════════════════════════════════════════════════════════════════

class _GlassSheet extends StatelessWidget {
  final GlassTokens tokens;
  final String title;
  final Widget child;

  const _GlassSheet({
    required this.tokens,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                          color: tokens.starkWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: tokens.starkWhite,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}


