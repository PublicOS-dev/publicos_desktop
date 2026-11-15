import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

import '../l10n/l10n_ext.dart';
import '../router.dart';
import '../theme/glass_tokens.dart';
import '../widgets/glass_contact_icon.dart';
import '../widgets/image_overlay.dart';
import '../widgets/nft_banner.dart';
import '../widgets/nft_info_dialog.dart';
import '../widgets/fullscreen_overlay.dart';
import '../widgets/profile/bio_display_widget.dart';
import '../widgets/profile/create_record_page.dart';
import '../widgets/profile/edit_bio_sheet.dart';
import '../widgets/profile/profile_grid.dart';
import '../widgets/profile/social_strip.dart';

/// A contact's full profile — the right-hand detail pane of the Contacts pane.
///
/// Ported from publicos_client's `pages/profile_page.dart`. Like the client's,
/// this is a pure **display** surface: it fetches nothing and owns no loader.
/// The host (`contacts_pane`) owns the contact lifecycle — local-first render,
/// then a chain sync that pushes a fresh `contact` back down. The one exception
/// is the org founder, which this pane silently resolves from
/// `Contact.founderAddress` and fades in (exactly as the client does).
///
/// **Desktop deltas** (no new logic — the display path is the client's):
///  - **The header is ours.** The client renders banner + avatar inside
///    `browser.dart`'s 4,193-LOC scroll-collapsing address bar — mobile chrome
///    with no desktop analogue. Here it's a static header: [NftBanner] with the
///    avatar straddling its bottom edge (half on the banner, half on the
///    content), matching the client's profile look.
///  - **Read-only.** Every edit path (create/edit record sheets, bio editing,
///    drag-reorder, org-governance write routing) is deferred —
///    that's what `create_record_page.dart` (1,788 LOC) + `edit_bio_sheet.dart`
///    (436 LOC) buy, and they're bottom sheets needing re-shelling as dialogs.
///    So `isEditable`/`isEditMode` are hardwired false and the write methods are
///    absent rather than present-and-dead.
///  - `context.l10n` → English literals (desktop has no l10n), taken verbatim
///    from the client's `app_en.arb`.
///  - `AppNav.toProfile` (founder tap) → the [onOpenContact] callback, so the
///    host selects that contact in the left list instead of pushing a route.
class ProfilePane extends StatefulWidget {
  final Contact contact;

  /// Hard-reload this contact from chain — the host's sync. Pull-to-refresh
  /// routes through this single point; the fresh contact comes back down as
  /// `widget.contact` and `didUpdateWidget` re-renders.
  final Future<void> Function()? onRefresh;

  /// Open another contact's profile (the org-founder row). Null disables the tap.
  final void Function(Contact contact)? onOpenContact;

  /// When true the HOST owns the banner/avatar/name header (the Browser's
  /// animated collapsing header — the client's browser↔ProfilePage split) and
  /// this pane renders content only, starting [topInset] below its top so it
  /// begins under the expanded header and its scroll drives the collapse.
  final bool externalHeader;

  /// Top inset applied when [externalHeader] is true (= the host header's
  /// expanded visual height).
  final double topInset;

  /// Whether the host has profile editing switched on. The host owns the
  /// toggle (Browser's deck cluster) exactly as the client's `browser.dart`
  /// owns `_isEditMode`; this pane only obeys it.
  final bool isEditMode;

  /// Whether the viewer is a member of this org — the second half of
  /// [_ProfilePaneState._canEdit]. Resolved by the host (`browser.dart`).
  final bool isOrgMember;

  /// Set an NFT card's art as this profile's avatar (the card's info dialog
  /// offers it). Owned by the host because it writes the avatar record, which
  /// is a header concern, not a body one.
  final Future<bool> Function(NftAvatarRef ref)? onUseNftAsAvatar;

  const ProfilePane({
    super.key,
    required this.contact,
    this.onRefresh,
    this.onOpenContact,
    this.externalHeader = false,
    this.topInset = 0,
    this.isEditMode = false,
    this.isOrgMember = false,
    this.onUseNftAsAvatar,
  });

  @override
  State<ProfilePane> createState() => _ProfilePaneState();
}

/// The profile's horizontal gutter. One constant owns it so the avatar, the
/// name, every section and the card grid all hang off the same left edge — the
/// banner is the only full-bleed element. It equals the Browser header's
/// `_hPad` (browser.dart), which is where the avatar sits in the Browser — so
/// bio text, social strip and the card grid's left edge all start under the
/// avatar, and the grid gets the same gutter on its right so the stack stays
/// centred (matches the client's `_kContentPad`).
const double _kContentPad = 16;

class _ProfilePaneState extends State<ProfilePane> {
  /// Mirror of `widget.contact`, kept in sync via [initState] / [didUpdateWidget].
  Contact? _contact;

  /// The org's founder, silently resolved from `_contact.founderAddress` (local
  /// cache first, chain on miss). Null until resolved — the row fades in.
  Contact? _founderContact;

  /// A group chat's description (from `XmtpConversation`), shown read-only as the
  /// profile "bio". Null for person/account profiles and until resolved.
  String? _groupDescription;

  /// The card being composed in the create/edit dialog, mirrored into the grid
  /// as a live preview cell. Null when no dialog is open.
  Record? _previewRecord;

  /// Who may write to this profile: its owner, or a member of this org.
  bool get _canEdit =>
      _selfProfile || (_contact?.isOrgAccount == true && widget.isOrgMember);

  /// True when the edit affordances should actually be on screen.
  bool get _editing => _canEdit && widget.isEditMode;

  /// True when this profile is the signed-in user's own. You do not follow
  /// yourself, so the button is hidden entirely.
  bool get _selfProfile {
    final mine = PublicOS.myPublicosAddress?.toLowerCase();
    final theirs = _contact?.publicosAddress?.eip55With0x.toLowerCase();
    return mine != null && theirs != null && mine == theirs;
  }

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
    _resolveFounder();
    _resolveGroupDescription();
  }

  @override
  void didUpdateWidget(ProfilePane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.contact, widget.contact)) {
      _contact = widget.contact;
      if (oldWidget.contact.founderAddress != widget.contact.founderAddress) {
        _resolveFounder();
      }
      if (oldWidget.contact.xmtpConversationTopic !=
          widget.contact.xmtpConversationTopic) {
        _resolveGroupDescription();
      }
    }
  }

  /// Silently resolve the org founder into a full Contact for display — local
  /// cache first, chain on miss, then persisted. Never blocks the pane; the row
  /// fades in when this lands. No-op without a `founderAddress`.
  Future<void> _resolveFounder() async {
    final addr = _contact?.founderAddress;
    if (addr == null) {
      if (_founderContact != null && mounted) {
        setState(() => _founderContact = null);
      }
      return;
    }
    // Already resolved to this founder — nothing to do.
    if (_founderContact?.publicosAddress?.eip55With0x.toLowerCase() ==
        addr.eip55With0x.toLowerCase()) {
      return;
    }
    Contact? resolved = await PublicOSContacts.searchContacts(addr.eip55With0x);
    if (resolved == null) {
      try {
        resolved = await PublicOSContacts.fetchContact(addr);
        await PublicOSContacts.saveContact(resolved);
      } catch (_) {
        return; // leave unresolved — retried on next visit
      }
    }
    if (!mounted) return;
    // Bail if the contact changed underneath us while we were resolving.
    if (_contact?.founderAddress?.eip55With0x.toLowerCase() !=
        addr.eip55With0x.toLowerCase()) {
      return;
    }
    setState(() => _founderContact = resolved);
  }

  /// Silently resolve a group chat's description from its `XmtpConversation`
  /// (local DB, no network) for read-only display as the profile "bio".
  Future<void> _resolveGroupDescription() async {
    final topic = _contact?.xmtpConversationTopic;
    if (topic == null) {
      if (_groupDescription != null && mounted) {
        setState(() => _groupDescription = null);
      }
      return;
    }
    final conv = await PublicOSConversations.getConversation(topic);
    if (!mounted) return;
    if (_contact?.xmtpConversationTopic != topic) return;
    setState(() => _groupDescription = conv?.groupDescription?.trim());
  }

  /// Put [child] on the profile's single left edge.
  ///
  /// Several of the ported client widgets carry their own internal horizontal
  /// padding (RecordButton draws inside a 2px margin).
  /// Left alone they'd each land on a *different* edge — which is exactly the
  /// ragged look this fixes. [inset] is how much padding the child already has,
  /// and is subtracted, so every section's **visible** left edge is _kContentPad.
  Widget _gutter({required Widget child, double inset = 0}) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: (_kContentPad - inset).clamp(0, _kContentPad),
    ),
    child: child,
  );

  // ---------------------------------------------------------------------------
  // Writes -- ported from publicos_client `pages/profile_page.dart`
  // ---------------------------------------------------------------------------
  //
  // Every write forks the same way: own profile -> a direct Core write; org
  // profile with a member viewer -> the same change proposed as a governance
  // vote. `startVote*` resolves once the startVote tx is mined, so a
  // threshold-1 org has already applied the change by the time it returns while
  // a threshold-N org has an open vote -- which is what `_orgWriteMessage` asks
  // about before choosing the confirmation copy.

  /// Refresh the in-memory own-contact cache so sibling surfaces see the edit.
  /// Core's `setRecord` / `deleteRecord` already write through to the DB; this
  /// only invalidates the snapshot. This pane itself re-renders through the
  /// `widget.onRefresh` -> host sync -> `didUpdateWidget` round trip.
  Future<void> _refreshOwnContact() async {
    await AppStateNotifier.loadMyContact();
  }

  Future<String> _orgWriteMessage(
      String appliedMessage, String voteStartedMessage) async {
    final addr = _contact?.publicosAddress;
    if (addr == null) return appliedMessage;
    try {
      final voteOpen =
          await PublicOSGovernance.hasPendingVoteBy(
          addr.eip55With0x, PublicOS.myPublicosAddress);
      return voteOpen ? voteStartedMessage : appliedMessage;
    } catch (_) {
      return appliedMessage;
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.fixed),
    );
  }

  /// Attach a fractional-index rank to a card/social record on write. A new
  /// record gets a rank after the current maximum; editing an already-ranked
  /// record keeps its rank so it stays put. Non-grid records pass through.
  Record _withRank(Record record) {
    final isSortable = record.type == RecordType.profile &&
        (record.profileSubtype == ProfileSubtype.card ||
            record.profileSubtype == ProfileSubtype.social);
    if (!isSortable || record.rank != null) return record;

    final existing = _contact?.records;
    if (existing == null) return record.copyWith(rank: keyBetween(null, null));

    for (final r in existing) {
      if (r.key == record.key && r.rank != null) {
        return record.copyWith(rank: r.rank);
      }
    }
    String? maxRank;
    for (final r in existing) {
      final rr = r.rank;
      if (rr != null && (maxRank == null || rr.compareTo(maxRank) > 0)) {
        maxRank = rr;
      }
    }
    return record.copyWith(rank: keyBetween(maxRank, null));
  }

  Future<void> _updateRecord(Record recordToUpdate) async {
    if (!_canEdit || _contact == null) return;
    final l10n = context.l10n;
    recordToUpdate = _withRank(recordToUpdate);
    final overlay = FullscreenOverlay.showTransaction(
        context, l10n.profilePageSavingToChain);
    try {
      bool success = false;
      if (_selfProfile) {
        success = await PublicOSContacts.setRecord(recordToUpdate);
        if (success) {
          overlay.updateMessage(l10n.profilePageRefreshingProfile);
          await _refreshOwnContact();
        }
      } else if (_contact?.isOrgAccount == true &&
          widget.isOrgMember &&
          _contact?.publicosAddress != null) {
        overlay.updateMessage(l10n.profilePageStartingVote);
        success = await PublicOSGovernance.startVoteSetRecord(
          _contact!.publicosAddress!,
          key: recordToUpdate.key,
          value: jsonEncode(recordToUpdate.toChainValue()),
          expiration:
              BigInt.from(recordToUpdate.expiration.millisecondsSinceEpoch),
          recordType: BigInt.from(recordToUpdate.type.index),
          customType: recordToUpdate.subtype ?? '',
        );
      }

      if (success) {
        await widget.onRefresh?.call();
        final isOrgVote = _contact?.isOrgAccount == true && !_selfProfile;
        _snack(isOrgVote
            ? await _orgWriteMessage(
                l10n.profilePageProfileUpdated, l10n.profilePageVoteStarted)
            : l10n.profilePageProfileUpdated);
      } else {
        _snack(l10n.profilePageBlockchainError);
      }
    } catch (_) {
      _snack(l10n.profilePageBlockchainError);
    } finally {
      overlay.dismiss();
    }
  }

  /// Drag-reorder handler. [newOrder] is the full linear card order after the
  /// move; [moved] is the dragged card. A legacy profile with any unranked card
  /// is baked in one batch (the move is already in [newOrder]); a fully ranked
  /// one is a single write of the moved card between its new neighbours.
  Future<void> _onReorderCards(List<Record> newOrder, Record moved) async {
    if (!_canEdit || _contact == null) return;

    final anyUnranked = newOrder.any((r) => r.rank == null);
    if (anyUnranked) {
      await _bakeRecords(PublicOSContacts.withRanks(newOrder));
      return;
    }

    final i = newOrder.indexWhere((r) => r.key == moved.key);
    if (i < 0) return;
    final prev = i > 0 ? newOrder[i - 1].rank : null;
    final next = i < newOrder.length - 1 ? newOrder[i + 1].rank : null;
    if (prev == next) return; // single card / no movement
    await _updateRecord(moved.copyWith(rank: keyBetween(prev, next)));
  }

  /// One-shot batch write of [records] with their new ranks -- the profile
  /// "bake". Own profile -> one `setMultipleRecords` tx; org -> one
  /// `SET_MULTIPLE_RECORDS` vote.
  Future<void> _bakeRecords(List<Record> records) async {
    if (!_canEdit || _contact == null || records.isEmpty) return;
    final l10n = context.l10n;
    final overlay = FullscreenOverlay.showTransaction(
        context, l10n.profilePageSavingLayout);
    try {
      bool success = false;
      if (_selfProfile) {
        success = await PublicOSContacts.setMultipleRecords(records);
        if (success) {
          overlay.updateMessage(l10n.profilePageRefreshingProfile);
          await _refreshOwnContact();
        }
      } else if (_contact?.isOrgAccount == true &&
          widget.isOrgMember &&
          _contact?.publicosAddress != null) {
        overlay.updateMessage(l10n.profilePageStartingVote);
        success = await PublicOSGovernance.startVoteSetMultipleRecords(
          _contact!.publicosAddress!,
          records,
        );
      }

      if (success) {
        await widget.onRefresh?.call();
        final isOrgVote = _contact?.isOrgAccount == true && !_selfProfile;
        _snack(isOrgVote
            ? await _orgWriteMessage(
                l10n.profilePageLayoutSaved, l10n.profilePageVoteStarted)
            : l10n.profilePageLayoutSaved);
      } else {
        _snack(l10n.profilePageBlockchainError);
      }
    } catch (_) {
      _snack(l10n.profilePageBlockchainError);
    } finally {
      overlay.dismiss();
    }
  }

  Future<void> _deleteRecord(Record record) async {
    if (!_canEdit || _contact == null) return;
    final l10n = context.l10n;
    final overlay = FullscreenOverlay.showTransaction(
        context, l10n.profilePageDeletingFromChain);
    try {
      bool success = false;
      if (_selfProfile) {
        success = await PublicOSContacts.deleteRecord(record.key);
        if (success) {
          overlay.updateMessage(l10n.profilePageRefreshingProfile);
          await _refreshOwnContact();
        }
      } else if (_contact?.isOrgAccount == true &&
          widget.isOrgMember &&
          _contact?.publicosAddress != null) {
        overlay.updateMessage(l10n.profilePageStartingVote);
        success = await PublicOSGovernance.startVoteDeleteRecord(
          _contact!.publicosAddress!,
          record.key,
        );
      }

      if (success) {
        await widget.onRefresh?.call();
        final isOrgVote = _contact?.isOrgAccount == true && !_selfProfile;
        _snack(isOrgVote
            ? await _orgWriteMessage(
                l10n.profilePageRecordDeleted, l10n.profilePageVoteStarted)
            : l10n.profilePageRecordDeleted);
      } else {
        _snack(l10n.profilePageBlockchainError);
      }
    } catch (_) {
      _snack(l10n.profilePageBlockchainError);
    } finally {
      overlay.dismiss();
    }
  }

  void _setSocialRichMode(bool rich) {
    final record = Record.asSettings(
      key: 'settings.social_display',
      value: rich ? 'rich' : 'icon',
      isSystem: false,
      expiration: DateTime.now().add(const Duration(days: 3650)),
    );
    _updateRecord(record);
  }

  void _onPreviewChanged(Record? preview) {
    // Deferred: CreateRecordSheet.dispose calls this synchronously, which would
    // otherwise be a setState during tree finalization.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _previewRecord = preview);
    });
  }

  /// The org whose governance a write should route through, or null for a
  /// direct write. Both create/edit dialogs need it so they can prefetch the
  /// org's active-vote state and disable Save while one is already open.
  EthereumAddress? get _orgAddressForWrite =>
      (_contact?.isOrgAccount == true && !_selfProfile)
          ? _contact?.publicosAddress
          : null;

  void _openCreateSheet() {
    showCreateRecordSheet(
      context,
      onSave: (record) async {
        Navigator.of(context).pop();
        await _updateRecord(record);
      },
      onPreviewChanged: _onPreviewChanged,
      orgAddress: _orgAddressForWrite,
    ).then((_) {
      if (mounted) setState(() => _previewRecord = null);
    });
  }

  void _openEditSheet(Record record) {
    showCreateRecordSheet(
      context,
      record: record,
      onSave: (updated) async {
        Navigator.of(context).pop();
        await _updateRecord(updated);
      },
      onPreviewChanged: _onPreviewChanged,
      orgAddress: _orgAddressForWrite,
    ).then((_) {
      if (mounted) setState(() => _previewRecord = null);
    });
  }

  void _showBioDialog() {
    if (!_canEdit) return;
    Record? existingBioRecord;
    try {
      existingBioRecord = _contact?.records
          .firstWhere((rec) => rec.profileSubtype == ProfileSubtype.text);
    } catch (_) {
      existingBioRecord = null;
    }
    final Record bioRecord = existingBioRecord ??
        Record.asProfile(
          key: 'profile.bio',
          value: context.l10n.profilePageBioPlaceholder,
          expiration: DateTime.now().add(const Duration(days: 365)),
          icon: Icons.person_rounded.codePoint,
          customMetadataAttributes: {
            'bioTextColor': Colors.white.toARGB32(),
            'bioBorderVisible': false,
            'bioBorderColor': Colors.grey.toARGB32(),
            'bioBorderWidth': 1.0,
            'borderRadius': 16.0,
          },
        );

    showEditBioSheet(
      context,
      record: bioRecord,
      onSave: (updatedRecord) async {
        Navigator.of(context).pop();
        await _updateRecord(updatedRecord);
      },
    );
  }

  Widget? _buildBioSection() {
    // Group chats show their description as a read-only bio (resolved async).
    if (_contact?.isGroupChat == true) {
      final desc = _groupDescription;
      if (desc == null || desc.isEmpty) return null; // no bio, no dead space
      return BioDisplayWidget(
        record: Record.asProfile(
          key: 'profile.bio',
          value: desc,
          expiration: DateTime.now().add(const Duration(days: 365)),
          // BioDisplayWidget's `record.bioTextColor ?? Colors.white` fallback is
          // dead — the getter returns transparent (not null) when unset — so the
          // text renders invisible without an explicit colour.
          customMetadataAttributes: {'bioTextColor': Colors.white.toARGB32()},
        ),
      );
    }

    // Person / account profiles: the bio record, if any.
    Record? bioRecord;
    final contact = _contact;
    if (contact != null) {
      try {
        bioRecord = contact.records.firstWhere(
          (rec) => rec.profileSubtype == ProfileSubtype.text,
        );
        if (bioRecord.value.isEmpty) bioRecord = null;
      } catch (_) {
        bioRecord = null;
      }
    }

    // No bio and nothing to add one with — drop the section (no dead space).
    if (bioRecord == null && !_editing) return null;

    return GestureDetector(
      onTap: _editing ? _showBioDialog : null,
      child: MouseRegion(
        // Desktop delta: a GestureDetector does not change the cursor, and only
        // in edit mode is this actually a tap target.
        cursor: _editing ? SystemMouseCursors.click : MouseCursor.defer,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            BioDisplayWidget(record: bioRecord),
            if (_editing)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 32,
                  height: 32,
                  // The edit pencil must NEVER borrow the bio record's colour:
                  // a broken record whose `bioTextColor` is unset resolves to
                  // transparent, which would draw the one control that lets the
                  // user FIX that record invisibly. Fixed white, always visible.
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinedSection() {
    // The space stays reserved even while createdAt is null — otherwise sections
    // below jump when chain enrichment lands.
    final createdAt = _contact?.createdAt;
    final months = [
      context.l10n.profilePageMonthJanuary,
      context.l10n.profilePageMonthFebruary,
      context.l10n.profilePageMonthMarch,
      context.l10n.profilePageMonthApril,
      context.l10n.profilePageMonthMay,
      context.l10n.profilePageMonthJune,
      context.l10n.profilePageMonthJuly,
      context.l10n.profilePageMonthAugust,
      context.l10n.profilePageMonthSeptember,
      context.l10n.profilePageMonthOctober,
      context.l10n.profilePageMonthNovember,
      context.l10n.profilePageMonthDecember,
    ];
    final label = createdAt == null
        ? null
        : context.l10n.profilePageJoined(months[createdAt.month - 1], createdAt.year);

    // No padding of its own — the content wrapper owns the gutter (_kContentPad).
    return Row(
      children: [
        Opacity(
          opacity: label == null ? 0 : 1,
          child: Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          // Zero-width space when unknown keeps the line at its natural height
          // without painting a glyph.
          label ?? '​',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget? _buildFounderSection() {
    if (_contact?.isOrgAccount != true) return null;

    final memberCount = _contact?.orgMemberCount;
    final founder = _founderContact;
    if (memberCount == null && founder == null) return null;

    // No padding of its own — the content wrapper owns the gutter (_kContentPad).
    return Row(
      children: [
        // The client's top:8 padding is dropped on both halves of this row — it
        // existed to line the two text runs up against each other on mobile, and
        // here the Row's default centre cross-alignment does that against the
        // 28px founder avatar.
        if (memberCount != null) ...[
          Icon(
            Icons.people_outline,
            size: 16,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            '$memberCount ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            context.l10n.profilePageMemberCountWord(memberCount),
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
        // Expanded + Align, NOT a Spacer. The founder name must be able to
        // ellipsize, and a Flexible child is only legal inside a Row whose own
        // incoming width is bounded. After a Spacer, the switcher sat in the
        // Row's *unbounded* main axis, so the Flexible below blew up with
        // "RenderFlex children have non-zero flex but incoming width
        // constraints are unbounded" — on orgs only, since only they have a
        // founder. Expanded gives the block a finite width; Align keeps it
        // hugging the right edge exactly as the Spacer did.
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            // Founder fades in once silently resolved from founderAddress.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: founder == null
                  ? const SizedBox.shrink()
                  : MouseRegion(
                      key: ValueKey(founder.publicosAddress?.eip55With0x),
                      cursor: widget.onOpenContact == null
                          ? MouseCursor.defer
                          : SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => widget.onOpenContact?.call(founder),
                        // Flat — no nested Row. A nested Row would be a
                        // non-flex child of this one and would therefore be
                        // handed unbounded width again, re-creating the bug one
                        // level deeper.
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GlassContactIcon(contact: founder, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              context.l10n.profilePageFoundedBy,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            // Long founder names ellipsize instead of running
                            // off the pane's right edge.
                            Flexible(
                              child: Text(
                                founder.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
    );
  }

  /// The banner surface, mirroring the client's `browser.dart` `_buildBanner`
  /// branch: **a `profile.banner.nft` pointer wins over the plain URL** and
  /// renders as verified art; otherwise the plain `profile.banner` URL renders
  /// through ZeroCachedImage; an empty banner leaves the header background.
  ///
  /// Tap behaviour is the client's too — a verified NFT banner opens the shared
  /// NFT info dialog (no "use as avatar": it's a banner, not a pfp); a plain
  /// image banner opens full-screen. An NFT banner whose verdict hasn't been
  /// computed yet, and an empty banner, are untappable.
  Widget _buildBanner(GlassTokens tokens, Contact c) {
    final nftBanner = c.nftBanner;
    final nftVerdict = c.verifiedNftBannerData;
    final bannerUrl = c.displayBannerUrl;

    if (nftBanner != null) {
      final Widget art = NftBanner(contact: c);
      if (nftVerdict == null) return art;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => showNftInfoDialogFor(
            context,
            ref: nftBanner,
            cache: nftVerdict,
            owner: c,
          ),
          child: art,
        ),
      );
    }

    if (bannerUrl.isEmpty) {
      return ColoredBox(color: tokens.surfaceDeep);
    }

    final heroTag = 'banner_image_$bannerUrl';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.transparent,
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (ctx, _, __) => ImageOverlay(
              imageUrl: bannerUrl,
              heroTag: heroTag,
              onClose: () => Navigator.pop(ctx),
            ),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        child: Hero(
          tag: heroTag,
          child: ZeroCachedImage(
            imageUrl: bannerUrl,
            alignment: c.bannerIsBackground ? Alignment.topCenter : Alignment.center,
            // Desktop delta: the client uses fitWidth inside its width-derived
            // header strip; the desktop pane is a fixed-height band on a canvas
            // of any width, so cover is what keeps it filled and uncropped-odd.
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => ColoredBox(color: tokens.surfaceDeep),
          ),
        ),
      ),
    );
  }

  /// Banner + the avatar straddling its bottom edge (half on the banner, half on
  /// the content), then name + address. Desktop's static answer to the client's
  /// collapsing browser header.
  Widget _buildHeader(GlassTokens tokens, Contact c) {
    const bannerHeight = 190.0;
    const avatarSize = 104.0;
    final addr = c.publicosAddress?.eip55With0x;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          // Room for the half of the avatar that hangs below the banner.
          height: bannerHeight + avatarSize / 2,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: bannerHeight,
                width: double.infinity,
                child: _buildBanner(tokens, c),
              ),
              // Wash the banner's lower edge so the avatar keeps contrast against
              // a bright banner. IgnorePointer goes INSIDE the Positioned —
              // wrapping a Positioned throws `Incorrect use of ParentDataWidget`
              // — so the wash can't swallow the banner's tap.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: bannerHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          tokens.background.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: _kContentPad,
                top: bannerHeight - avatarSize / 2,
                child: GlassContactIcon(contact: c, size: avatarSize),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kContentPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      c.displayName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: tokens.starkWhite,
                      ),
                    ),
                  ),
                  // Follow lives in the deck cluster (browser.dart) to match
                  // the client's address bar.
                ],
              ),
              if (addr != null) ...[
                const SizedBox(height: 4),
                _AddressChip(address: addr),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileContent(GlassTokens tokens) {
    final contact = _contact;
    if (contact == null) return const SizedBox.shrink();

    final socialRecords = contact.records
        .where(
          (r) =>
              r.type == RecordType.profile &&
              r.profileSubtype == ProfileSubtype.social,
        )
        .toList();

    final socialRichMode =
        contact.getRecordValue('settings.social_display') == 'rich';

    final cardRecords = contact.records
        .where(
          (r) =>
              r.type == RecordType.profile &&
              r.profileSubtype == ProfileSubtype.card &&
              r.key != '_osux_profile_background_url_',
        )
        .toList();

    // A card being composed in the create/edit dialog is mirrored into whichever
    // section will hold it, so the preview lands where the real record will.
    Record? socialPreview;
    Record? cardPreview;
    if (_previewRecord != null) {
      if (_previewRecord!.profileSubtype == ProfileSubtype.social) {
        socialPreview = _previewRecord;
      } else {
        cardPreview = _previewRecord;
      }
    }

    // Each section is built only when present; an absent one returns null and is
    // filtered out, so it contributes no spacing. One uniform gap between
    // consecutive sections is the single source of truth for vertical rhythm.
    // The social strip is the exception to the uniform gap: `socialGap` above
    // AND below (mirrors publicos_client) so it reads as its own
    // block between the joined row and the grid.
    const sectionGap = 8.0;
    const socialGap = 12.0;
    // In edit mode both blocks appear even when empty — otherwise there is
    // nowhere to press to add the first social link or the first card.
    final showSocial =
        socialRecords.isNotEmpty || socialPreview != null || _editing;
    final showGrid = _editing || cardRecords.isNotEmpty || cardPreview != null;
    final gridGap = showSocial ? socialGap : sectionGap;

    // Each section carries its own gutter, compensated for whatever internal
    // padding the ported widget already has — so every visible left edge lines
    // up with the avatar and the name.
    final founder = _buildFounderSection();
    final bio = _buildBioSection();
    final Widget? socialStrip = !showSocial
        ? null
        // SocialStrip carries no horizontal inset of its own.
        : _gutter(
            child: SocialStrip(
              records: socialRecords,
              previewRecord: socialPreview,
              richMode: socialRichMode,
              isEditMode: _editing,
              onAddSocial: _editing ? _openCreateSheet : null,
              onEditSocial: _editing ? _openEditSheet : null,
              onDeleteSocial: _editing ? _deleteRecord : null,
              onRichModeChanged: _editing ? _setSocialRichMode : null,
            ),
          );

    // Bio first, then an org's members + founder row (both apps).
    final sections = <Widget>[
      // Plain text (no card padding), so no inset.
      if (bio != null) _gutter(child: bio),
      if (founder != null) _gutter(child: founder),
      _gutter(child: _buildJoinedSection()),
      if (socialStrip != null) socialStrip,
    ];

    // Gap *before* section i: socialGap when either neighbour is the strip.
    double gapBefore(int i) => (identical(sections[i], socialStrip) ||
            (i > 0 && identical(sections[i - 1], socialStrip)))
        ? socialGap
        : sectionGap;

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        // No side padding here: _kContentPad is the only gutter, or content
        // drifts right of the Browser header's avatar.
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The banner is the only full-bleed element; everything below it
            // hangs off the single gutter. Under an external header (the
            // Browser's animated one) the whole header block is the
            // host's — content starts topInset down and scrolls under it.
            if (widget.externalHeader)
              SizedBox(height: widget.topInset)
            else
              _buildHeader(tokens, contact),
            for (int i = 0; i < sections.length; i++) ...[
              SizedBox(height: gapBefore(i)),
              sections[i],
            ],
            if (showGrid) ...[
              SizedBox(height: gridGap),
              // KEYED, and it is load-bearing -- twin of the
              // client's. `sections` above is built from CONDITIONAL
              // entries, so when the chain sync lands and adds a bio, a social
              // record or the founder row, every later child of this Column
              // shifts one slot. Unkeyed children are matched positionally, so
              // an unkeyed grid is matched against a different widget, its
              // State destroyed, and `_ProfileGridState._entered` reset --
              // which makes EVERY card replay its entrance cascade on every
              // refresh.
              //
              // The key sits on the OUTERMOST widget of the slot: key matching
              // happens between siblings, so keying ProfileGrid itself would
              // not save it from an unkeyed _gutter rebuilt around it.
              KeyedSubtree(
                key: const ValueKey('profile.cards.grid'),
                child: _gutter(
                inset: 2,
                child: ProfileGrid(
                  records: cardRecords,
                  previewRecord: cardPreview,
                  onRecordTap: _editing ? _openEditSheet : null,
                  onRecordDeleted: _deleteRecord,
                  isEditable: _canEdit,
                  isEditMode: widget.isEditMode,
                  onAddTap: _editing ? _openCreateSheet : null,
                  onReorder: _editing ? _onReorderCards : null,
                  onUseNftAsAvatar: widget.onUseNftAsAvatar,
                  nftOwner: contact,
                ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      constraints: const BoxConstraints.expand(),
      child: _buildProfileContent(tokens),
    );
  }
}

class _AddressChip extends StatefulWidget {
  final String address;
  const _AddressChip({required this.address});

  @override
  State<_AddressChip> createState() => _AddressChipState();
}

class _AddressChipState extends State<_AddressChip> {
  bool _hover = false;
  bool _copied = false;

  String get _short {
    final a = widget.address;
    // 0x + 6 … 4 — enough of both ends to verify by eye.
    return a.length <= 14
        ? a
        : '${a.substring(0, 8)}…${a.substring(a.length - 6)}';
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.address));
    if (!mounted) return;
    setState(() => _copied = true);
    // Revert the tick without a snackbar — the chip IS the feedback.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _copy,
        child: Tooltip(
          message: widget.address,
          waitDuration: const Duration(milliseconds: 400),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _hover ? tokens.glassFillHover : tokens.glassFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _short,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: tokens.textDim,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _copied ? Icons.check_rounded : Icons.copy_rounded,
                  size: 13,
                  color: _copied ? tokens.connectedAccent : tokens.textDim,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
