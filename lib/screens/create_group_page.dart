import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/explorer_chip.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/profile_image_picker.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

/// Full-screen page for creating a new XMTP group. Replaces the phigital
/// `CreateGroupSheet` bottom sheet — the two-step flow with a contact grid
/// and configuration form is too much content for a bottom sheet.
///
/// Flow: page 1 picks members from the stored-contacts list (with search
/// by display name, ETH address or raw inbox ID hex); page 2 captures
/// name, image URL and description; Create calls
/// `PublicOSConversations.createGroup(...)`.
///
/// This page is a pure imperative route — it owns no router knowledge. On
/// success it `Navigator.pop`s with the new conversation's topic; if the
/// user dismisses it (close button, system back) it pops `null`. The
/// caller (which lives on a go_router page) opens the chat.
///
/// **Add-members mode** ([CreateGroupPage.addMembers]): the same page 1
/// picker reused for an *existing* group (group settings → Add members).
/// Page 2 is skipped, already-present members are filtered out, the bottom
/// button reads ADD and calls `PublicOSConversations.addGroupMembers`; the
/// page pops `true` on success (the caller reloads + snacks).
class CreateGroupPage extends StatefulWidget {
  /// Non-null ⇒ add-members mode for this group topic.
  final String? existingGroupTopic;

  /// Inbox IDs already in the group (add-members mode). Never offered.
  final List<String> existingMemberInboxIds;

  const CreateGroupPage({super.key})
      : existingGroupTopic = null,
        existingMemberInboxIds = const [];

  const CreateGroupPage.addMembers({
    super.key,
    required String topic,
    required this.existingMemberInboxIds,
  }) : existingGroupTopic = topic;

  bool get isAddMode => existingGroupTopic != null;

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

/// Pairs a [Contact] with a specific inbox ID selected from its
/// `registeredInboxIDs` list. A single person can contribute multiple
/// picks (one per inbox they own) — the UI tracks them individually so
/// we can add the same contact twice via different devices.
class _GroupMemberPick {
  final Contact contact;
  final String inboxId;
  final String label;
  const _GroupMemberPick({
    required this.contact,
    required this.inboxId,
    required this.label,
  });
}

/// The grid's order: [recent] = the people you last had a 1:1
/// chat with, newest first (the Messages tab's order), then everyone else
/// A→Z; [az] = everyone A→Z.
enum _SortMode { recent, az }

class _CreateGroupPageState extends State<CreateGroupPage> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<Contact> _availableContacts = [];
  final List<_GroupMemberPick> _selectedPicks = [];

  /// Maps `contactId → already-picked inbox IDs for that contact`. Used
  /// to filter the multi-inbox selection dialog so the same device isn't
  /// offered twice.
  final Map<String, List<String>> _pickedInboxIdsByContactId = {};

  /// The contact a search resolved to: an on-chain display
  /// name, an 0x address or an inbox ID, through the same resolver as the
  /// Messages search, or an XMTP peer with no PublicOS account. Shown first
  /// in the grid with a ring; tapping it offers every inbox it publishes,
  /// like any other tile.
  Contact? _searchedContact;
  int _searchGeneration = 0;

  _SortMode _sortMode = _SortMode.recent;

  /// Last 1:1 message time per peer inbox ID (lowercase), for [_SortMode.recent].
  Map<String, DateTime> _lastTalked = const {};

  bool _isLoadingContacts = true;
  bool _isSearching = false;
  bool _isCreating = false;
  int _currentPage = 0;

  // Tracks an image upload made during this wizard that hasn't been
  // committed via a successful Create yet. If the user cancels/backs out
  // without creating the group, we delete the file from the SSP on
  // dispose so it doesn't sit on their quota.
  int? _pendingImageUploadId;
  bool _groupCreated = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_handleSearch);
    _pageController.addListener(_onPageChanged);
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    final pending = _pendingImageUploadId;
    if (pending != null && !_groupCreated) {
      // Fire and forget — page is gone, no UI to wait for.
      PublicOSSsp.deleteMedia(pending);
    }
    super.dispose();
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (_currentPage != page) {
      setState(() => _currentPage = page);
    }
  }

  // ---- loading + search -----------------------------------------------------

  Future<void> _loadContacts() async {
    setState(() => _isLoadingContacts = true);
    try {
      final stored = await PublicOSContacts.getStoredContacts();

      // Your own account stays in: to XMTP your other inboxes
      // are separate members you can add. Only the inbox this device has
      // loaded is dropped, in [_availableInboxesFor].
      final filtered = <Contact>[];
      final seenIds = <String>{};
      for (final contact in stored) {
        final registered = contact.registeredInboxIDs;
        if (registered == null || registered.isEmpty) continue;
        final id = _contactId(contact);
        if (seenIds.contains(id)) continue;
        seenIds.add(id);
        filtered.add(contact);
      }

      if (!mounted) return;
      setState(() {
        _availableContacts = filtered;
        _isLoadingContacts = false;
      });
      _loadRecency();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _availableContacts = const [];
        _isLoadingContacts = false;
      });
      _snack(localizedError(context.l10n, e));
    }
  }

  /// Last 1:1 message time per peer inbox, read from the local message
  /// store (no network). Failures leave the grid A→Z.
  Future<void> _loadRecency() async {
    try {
      final convs =
          await PublicOSConversations.getConversations(consentState: 'allowed');
      final out = <String, DateTime>{};
      for (final c in convs) {
        final peer = c.peerInboxId;
        if (!c.isDm || peer == null || peer.isEmpty) continue;
        final last =
            await PublicOSConversations.getLocalMessagesByTopic(c.topic, 1, true);
        if (last.isEmpty) continue;
        final key = peer.toLowerCase();
        final t = last.first.timestamp;
        final prev = out[key];
        if (prev == null || t.isAfter(prev)) out[key] = t;
      }
      if (!mounted) return;
      setState(() => _lastTalked = out);
    } catch (_) {}
  }

  /// Local names filter as you type; the same text also goes to the chain
  /// (exact display name, 0x account or session address, inbox ID), and an
  /// address or inbox ID with no PublicOS account is probed on XMTP. The hit
  /// is shown first, with every inbox it publishes.
  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    final gen = ++_searchGeneration;
    if (query.isEmpty) {
      setState(() {
        _searchedContact = null;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    Contact? found;
    try {
      found = await PublicOSContacts.resolveByIdentifier(query);

      final isEthAddress = query.startsWith('0x') && query.length == 42;
      final isInboxId = _isValidInboxIdFormat(query);
      if (found == null && (isEthAddress || isInboxId)) {
        String? inboxId;
        if (isEthAddress) {
          inboxId = await PublicOSConversations.inboxIdFromAddress(query);
        } else if (await PublicOSConversations.canMessageByInboxId(query)) {
          inboxId = query;
        }
        if (inboxId != null && inboxId.isNotEmpty) {
          found = Contact(
            displayName: '${query.substring(0, 10)}…',
            registeredInboxIDs: [InboxEntry(inboxId: inboxId, label: '')],
          );
        }
      }
    } catch (_) {
      found = null;
    }
    if (!mounted || gen != _searchGeneration) return;

    // A hit you already have as a contact: use that tile (it carries the
    // picks already made for it), lifted to the top.
    if (found != null) {
      final id = _contactId(found);
      for (final c in _availableContacts) {
        if (_contactId(c) == id) {
          found = c;
          break;
        }
      }
    }
    setState(() {
      _searchedContact = found;
      _isSearching = false;
    });
  }

  bool _isValidInboxIdFormat(String query) {
    if (query.length != 64) return false;
    if (query.startsWith('0x')) return false;
    final hex = RegExp(r'^[0-9a-fA-F]+$');
    return hex.hasMatch(query);
  }

  // ---- selection mechanics --------------------------------------------------

  String _contactId(Contact contact) {
    return contact.publicosAddress?.eip55With0x ??
        contact.registeredInboxIDs?.firstOrNull?.inboxId ??
        contact.displayName;
  }

  List<InboxEntry> _availableInboxesFor(Contact contact) {
    final entries = contact.registeredInboxIDs;
    if (entries == null || entries.isEmpty) return const [];
    final picked = _pickedInboxIdsByContactId[_contactId(contact)] ?? const [];
    // The inbox this device has loaded is you, already in the group; your
    // other inboxes are separate XMTP members (same rule as the Messages search).
    final own = PublicOS.clientXmtpInboxId?.toLowerCase();
    return entries
        .where((e) =>
            !picked.contains(e.inboxId) &&
            !widget.existingMemberInboxIds.contains(e.inboxId) &&
            e.inboxId.toLowerCase() != own)
        .toList();
  }

  List<Contact> get _filteredContacts {
    final query = _searchController.text.trim().toLowerCase();
    final searched = _searchedContact;
    final searchedId = searched == null ? null : _contactId(searched);
    final list = _availableContacts.where((c) {
      if (_availableInboxesFor(c).isEmpty) return false;
      if (searchedId != null && _contactId(c) == searchedId) return false;
      if (query.isEmpty) return true;
      return c.displayName.toLowerCase().contains(query);
    }).toList();

    int byName(Contact a, Contact b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    if (_sortMode == _SortMode.az) return list..sort(byName);

    final last = <String, DateTime?>{};
    for (final c in list) {
      DateTime? best;
      for (final e in c.registeredInboxIDs ?? const <InboxEntry>[]) {
        final t = _lastTalked[e.inboxId.toLowerCase()];
        if (t != null && (best == null || t.isAfter(best))) best = t;
      }
      last[_contactId(c)] = best;
    }
    return list
      ..sort((a, b) {
        final ta = last[_contactId(a)];
        final tb = last[_contactId(b)];
        if (ta != null && tb != null) return tb.compareTo(ta);
        if (ta != null) return -1;
        if (tb != null) return 1;
        return byName(a, b);
      });
  }

  /// The searched hit, while it still has an inbox left to pick.
  Contact? get _visibleSearchedContact {
    final c = _searchedContact;
    if (c == null || _availableInboxesFor(c).isEmpty) return null;
    return c;
  }

  Future<void> _addContactFromTile(Contact contact) async {
    final available = _availableInboxesFor(contact);
    if (available.isEmpty) {
      _snack(context.l10n.createGroupPageAllDevicesAdded(contact.displayName));
      return;
    }

    if (available.length == 1) {
      _commitPick(_GroupMemberPick(
        contact: contact,
        inboxId: available.first.inboxId,
        label: available.first.label,
      ));
      return;
    }

    final choice = await showDialog<InboxEntry>(
      context: context,
      builder: (_) => _InboxIdSelectionDialog(
        contact: contact,
        available: available,
      ),
    );
    if (choice != null) {
      _commitPick(_GroupMemberPick(
        contact: contact,
        inboxId: choice.inboxId,
        label: choice.label,
      ));
    }
  }

  void _commitPick(_GroupMemberPick pick) {
    setState(() {
      _selectedPicks.add(pick);
      final id = _contactId(pick.contact);
      _pickedInboxIdsByContactId.putIfAbsent(id, () => []).add(pick.inboxId);
    });
  }

  void _removePick(_GroupMemberPick pick) {
    setState(() {
      _selectedPicks.remove(pick);
      final id = _contactId(pick.contact);
      final list = _pickedInboxIdsByContactId[id];
      if (list != null) {
        list.remove(pick.inboxId);
        if (list.isEmpty) _pickedInboxIdsByContactId.remove(id);
      }
    });
  }

  // ---- create --------------------------------------------------------------

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack(context.l10n.createGroupPageNameRequired);
      return;
    }
    if (_selectedPicks.isEmpty) {
      _snack(context.l10n.createGroupPageSelectContact);
      return;
    }

    setState(() => _isCreating = true);
    try {
      final inboxIds = _selectedPicks
          .map((p) => p.inboxId)
          .where((id) => id.isNotEmpty)
          .toList();
      if (inboxIds.isEmpty) {
        _snack(context.l10n.createGroupPageNoValidInboxIds);
        setState(() => _isCreating = false);
        return;
      }

      final result = await PublicOSConversations.createGroup(inboxIds, {
        'name': name,
        'imageUrl': _imageUrlController.text.trim(),
        'description': _descriptionController.text.trim(),
        'pinnedFrameUrl': '',
      });

      if (!mounted) return;
      if (result['id'] != null) {
        _groupCreated = true;
        final topic = result['topic'] as String?;
        // Hand the new conversation's topic back to the caller and close.
        // The caller opens the chat via the router. A null/empty topic is
        // degenerate (id without topic) — pop null, the caller just shows
        // nothing; the group still exists and a later list refresh picks
        // it up.
        Navigator.of(context).pop(
          topic != null && topic.isNotEmpty ? topic : null,
        );
      } else {
        _snack(context.l10n.createGroupPageCreationNoId);
        setState(() => _isCreating = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      _snack(localizedError(context.l10n, e));
    }
  }

  /// Add-members mode: push the picked inbox IDs into the existing group
  /// and pop `true`. The caller (group settings) reloads and snacks.
  Future<void> _addMembersToGroup() async {
    final topic = widget.existingGroupTopic;
    if (topic == null || _selectedPicks.isEmpty) return;

    setState(() => _isCreating = true);
    try {
      final inboxIds = _selectedPicks
          .map((p) => p.inboxId)
          .where((id) => id.isNotEmpty)
          .toList();
      if (inboxIds.isEmpty) {
        _snack(context.l10n.createGroupPageNoValidInboxIds);
        setState(() => _isCreating = false);
        return;
      }
      await PublicOSConversations.addGroupMembers(topic, inboxIds);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      _snack(localizedError(context.l10n, e));
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ---- navigation helpers --------------------------------------------------

  void _goToNextPage() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToPreviousPage() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<bool> _handleBack() async {
    if (_currentPage == 1) {
      _goToPreviousPage();
      return false;
    }
    return true;
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToPreviousPage();
      },
      child: Scaffold(
        backgroundColor: tokens.background,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              _currentPage == 0
                  ? Icons.close_rounded
                  : Icons.arrow_back_rounded,
              color: tokens.starkWhite,
            ),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final shouldPop = await _handleBack();
              if (shouldPop && mounted) navigator.pop();
            },
          ),
          title: Text(
            _currentPage == 0
                ? context.l10n.createGroupPageAddMembersTitle
                : context.l10n.createGroupPageDetailsTitle,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: tokens.background,
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MembersPage(
                    tokens: tokens,
                    searchController: _searchController,
                    isSearching: _isSearching,
                    isLoadingContacts: _isLoadingContacts,
                    selectedPicks: _selectedPicks,
                    filteredContacts: _filteredContacts,
                    searchedContact: _visibleSearchedContact,
                    sortMode: _sortMode,
                    onSortChanged: (m) => setState(() => _sortMode = m),
                    onAddFromTile: _addContactFromTile,
                    onRemovePick: _removePick,
                  ),
                  _DetailsPage(
                    tokens: tokens,
                    nameController: _nameController,
                    imageUrlController: _imageUrlController,
                    descriptionController: _descriptionController,
                    isCreating: _isCreating,
                    onImageUploaded: (id) => _pendingImageUploadId = id,
                    onImageUploadDeleted: () => _pendingImageUploadId = null,
                  ),
                ],
              ),
            ),
            _BottomActionBar(
              tokens: tokens,
              currentPage: _currentPage,
              isAddMode: widget.isAddMode,
              canGoNext: _selectedPicks.isNotEmpty && !_isCreating,
              canCreate: _nameController.text.trim().isNotEmpty &&
                  _selectedPicks.isNotEmpty &&
                  !_isCreating,
              isCreating: _isCreating,
              onNext: widget.isAddMode ? _addMembersToGroup : _goToNextPage,
              onCreate: _createGroup,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Page 1 — Member selection
// ============================================================================

class _MembersPage extends StatelessWidget {
  final GlassTokens tokens;
  final TextEditingController searchController;
  final bool isSearching;
  final bool isLoadingContacts;
  final List<_GroupMemberPick> selectedPicks;
  final List<Contact> filteredContacts;
  final Contact? searchedContact;
  final _SortMode sortMode;
  final ValueChanged<_SortMode> onSortChanged;
  final Future<void> Function(Contact) onAddFromTile;
  final void Function(_GroupMemberPick) onRemovePick;

  const _MembersPage({
    required this.tokens,
    required this.searchController,
    required this.isSearching,
    required this.isLoadingContacts,
    required this.selectedPicks,
    required this.filteredContacts,
    required this.searchedContact,
    required this.sortMode,
    required this.onSortChanged,
    required this.onAddFromTile,
    required this.onRemovePick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchField(
          controller: searchController,
          isSearching: isSearching,
          tokens: tokens,
        ),
        _SortChips(mode: sortMode, onChanged: onSortChanged),
        if (selectedPicks.isNotEmpty)
          _SelectedMembersStrip(
            picks: selectedPicks,
            tokens: tokens,
            onRemove: onRemovePick,
          ),
        Expanded(
          child: _ContactGrid(
            tokens: tokens,
            isLoading: isLoadingContacts,
            contacts: filteredContacts,
            searchedContact: searchedContact,
            onTapContact: onAddFromTile,
          ),
        ),
      ],
    );
  }
}

class _SortChips extends StatelessWidget {
  final _SortMode mode;
  final ValueChanged<_SortMode> onChanged;
  const _SortChips({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          ExplorerChip(
            label: context.l10n.createGroupPageSortRecent,
            icon: Icons.schedule_rounded,
            active: mode == _SortMode.recent,
            onTap: () => onChanged(_SortMode.recent),
          ),
          const SizedBox(width: 8),
          ExplorerChip(
            label: context.l10n.contactsViewSortAsc,
            icon: Icons.sort_by_alpha_rounded,
            active: mode == _SortMode.az,
            onTap: () => onChanged(_SortMode.az),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final GlassTokens tokens;
  const _SearchField({
    required this.controller,
    required this.isSearching,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: controller,
        style: TextStyle(
              fontFamily: 'SpaceGrotesk',color: tokens.starkWhite),
        decoration: InputDecoration(
          hintText: context.l10n.createGroupPageSearchHint,
          hintStyle: TextStyle(
              fontFamily: 'SpaceGrotesk',color: tokens.textDim),
          prefixIcon: Icon(Icons.search_rounded, color: tokens.textDim),
          suffixIcon: isSearching
              ? Padding(
                  padding: const EdgeInsets.all(10),
                  child: PhigitalLoadingWidget(
                    size: 8,
                    showShadows: false,
                    color: tokens.textDim,
                  ),
                )
              : null,
          filled: true,
          fillColor: tokens.glassFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: tokens.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: tokens.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: tokens.borderMedium),
          ),
        ),
      ),
    );
  }
}

class _SelectedMembersStrip extends StatelessWidget {
  final List<_GroupMemberPick> picks;
  final GlassTokens tokens;
  final void Function(_GroupMemberPick) onRemove;
  const _SelectedMembersStrip({
    required this.picks,
    required this.tokens,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: HorizontalWheel(child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: picks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final pick = picks[i];
          return _SelectedChip(
            pick: pick,
            tokens: tokens,
            onRemove: () => onRemove(pick),
          );
        },
      )),
    );
  }
}

class _SelectedChip extends StatelessWidget {
  final _GroupMemberPick pick;
  final GlassTokens tokens;
  final VoidCallback onRemove;
  const _SelectedChip({
    required this.pick,
    required this.tokens,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final label = pick.label.isNotEmpty
        ? '${pick.contact.displayName}/${pick.label}'
        : pick.contact.displayName;
    return SizedBox(
      width: 68,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassContactIcon(contact: pick.contact, size: 44),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                  fontSize: 11,
                  color: tokens.starkWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Positioned(
            right: 4,
            top: -4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: tokens.softDanger,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.background, width: 2),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: tokens.starkWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactGrid extends StatelessWidget {
  final GlassTokens tokens;
  final bool isLoading;
  final List<Contact> contacts;
  final Contact? searchedContact;
  final Future<void> Function(Contact) onTapContact;

  const _ContactGrid({
    required this.tokens,
    required this.isLoading,
    required this.contacts,
    required this.searchedContact,
    required this.onTapContact,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: PhigitalLoadingWidget(size: 32));
    }

    final searched = searchedContact;
    final effectiveContacts = [
      if (searched != null) searched,
      ...contacts,
    ];

    if (effectiveContacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search_outlined,
                  size: 48, color: tokens.textDim),
              const SizedBox(height: 12),
              Text(
                context.l10n.createGroupPageNoContactsMatch,
                style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.createGroupPageNoContactsHint,
                textAlign: TextAlign.center,
                style: TextStyle(
              fontFamily: 'SpaceGrotesk',
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

    final screenWidth = MediaQuery.of(context).size.width;
    final columns = screenWidth >= 600 ? 6 : 4;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.70, // two-line names
      ),
      itemCount: effectiveContacts.length,
      itemBuilder: (_, i) {
        final contact = effectiveContacts[i];
        return _ContactTile(
          contact: contact,
          tokens: tokens,
          isSearched: searched != null && i == 0,
          onTap: () => onTapContact(contact),
        );
      },
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final GlassTokens tokens;
  final bool isSearched;
  final VoidCallback onTap;
  const _ContactTile({
    required this.contact,
    required this.tokens,
    required this.isSearched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // No card chrome — bare icon + name. A contact resolved from the
    // network (searched by address / inbox ID, not a stored contact) is
    // marked with a thin connected-teal ring around the icon.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: isSearched
                  ? BoxDecoration(
                      // Tracks GlassContactIcon's person radius (0.40·size)
                      // plus the ring's own padding + stroke.
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: tokens.connectedAccent,
                        width: 1.5,
                      ),
                    )
                  : null,
              child: GlassContactIcon(contact: contact, size: 48),
            ),
            const SizedBox(height: 8),
            Text(
              contact.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                color: tokens.starkWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Page 2 — Group details
// ============================================================================

class _DetailsPage extends StatelessWidget {
  final GlassTokens tokens;
  final TextEditingController nameController;
  final TextEditingController imageUrlController;
  final TextEditingController descriptionController;
  final bool isCreating;
  final void Function(int fileId) onImageUploaded;
  final VoidCallback onImageUploadDeleted;

  const _DetailsPage({
    required this.tokens,
    required this.nameController,
    required this.imageUrlController,
    required this.descriptionController,
    required this.isCreating,
    required this.onImageUploaded,
    required this.onImageUploadDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(
              text: context.l10n.createGroupPageFieldNameLabel, tokens: tokens),
          const SizedBox(height: 6),
          _GlassTextField(
            controller: nameController,
            hint: context.l10n.createGroupPageNameHint,
            tokens: tokens,
          ),
          const SizedBox(height: 18),
          _FieldLabel(
              text: context.l10n.createGroupPageFieldImageLabel,
              tokens: tokens),
          const SizedBox(height: 8),
          ProfileImagePicker(
            controller: imageUrlController,
            isAvatar: true,
            enabled: !isCreating,
            onUploaded: onImageUploaded,
            onUploadDeleted: onImageUploadDeleted,
            noServerMessage: context.l10n.createGroupPageNoSspMessage,
            dismissedWarningPrefsKey:
                'dismissed_no_ssp_warning_create_group_image',
            emptyState: _GroupInitialsEmptyState(
              nameController: nameController,
              tokens: tokens,
            ),
          ),
          const SizedBox(height: 18),
          _FieldLabel(
              text: context.l10n.createGroupPageFieldDescriptionLabel,
              tokens: tokens),
          const SizedBox(height: 6),
          _GlassTextField(
            controller: descriptionController,
            hint: context.l10n.createGroupPageDescriptionHint,
            tokens: tokens,
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}

/// Empty-state preview for the group image picker — mirrors
/// [GlassContactIcon] for groups: a circular tile with the group's
/// initials, color-seeded from the typed name, falling back to a
/// neutral "?" before the user types anything.
class _GroupInitialsEmptyState extends StatefulWidget {
  final TextEditingController nameController;
  final GlassTokens tokens;

  const _GroupInitialsEmptyState({
    required this.nameController,
    required this.tokens,
  });

  @override
  State<_GroupInitialsEmptyState> createState() =>
      _GroupInitialsEmptyStateState();
}

class _GroupInitialsEmptyStateState extends State<_GroupInitialsEmptyState> {
  @override
  void initState() {
    super.initState();
    widget.nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    widget.nameController.removeListener(_onNameChanged);
    super.dispose();
  }

  void _onNameChanged() {
    if (mounted) setState(() {});
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    final first = parts[0];
    if (first.length >= 2) return first.substring(0, 2).toUpperCase();
    return first.substring(0, 1).toUpperCase();
  }

  Color _seedColor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return widget.tokens.textDim;
    final hash = trimmed.hashCode;
    return HSLColor.fromAHSL(
      1.0,
      (hash % 360).toDouble(),
      0.7,
      0.6,
    ).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.nameController.text;
    final color = _seedColor(name);
    final initials = _initials(name);
    return Container(
      color: color.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 56,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final GlassTokens tokens;
  const _FieldLabel({required this.text, required this.tokens});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
              fontFamily: 'SpaceGrotesk',
        color: tokens.textDim,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final GlassTokens tokens;
  final int maxLines;
  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.tokens,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
              fontFamily: 'SpaceGrotesk',color: tokens.starkWhite),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
              fontFamily: 'SpaceGrotesk',color: tokens.textDim),
        filled: true,
        fillColor: tokens.glassFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.borderMedium),
        ),
      ),
    );
  }
}

// ============================================================================
// Bottom action bar
// ============================================================================

class _BottomActionBar extends StatelessWidget {
  final GlassTokens tokens;
  final int currentPage;
  final bool isAddMode;
  final bool canGoNext;
  final bool canCreate;
  final bool isCreating;
  final VoidCallback onNext;
  final VoidCallback onCreate;
  const _BottomActionBar({
    required this.tokens,
    required this.currentPage,
    required this.isAddMode,
    required this.canGoNext,
    required this.canCreate,
    required this.isCreating,
    required this.onNext,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final isPageOne = currentPage == 0;
    final enabled = isPageOne ? canGoNext : canCreate;
    final label = isPageOne
        ? (isAddMode
            ? context.l10n.createGroupPageAddButton
            : context.l10n.createGroupPageNextButton)
        : context.l10n.createGroupPageCreateButton;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.starkWhite,
              foregroundColor: tokens.background,
              disabledBackgroundColor:
                  tokens.starkWhite.withValues(alpha: 0.25),
              disabledForegroundColor:
                  tokens.background.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: enabled
                ? (isPageOne ? onNext : onCreate)
                : null,
            child: isCreating
                ? PhigitalLoadingWidget(
                    size: 9,
                    showShadows: false,
                    color: tokens.background,
                  )
                : Text(
                    label,
                    style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Inbox ID selection dialog (multi-device contacts)
// ============================================================================

class _InboxIdSelectionDialog extends StatelessWidget {
  final Contact contact;
  final List<InboxEntry> available;
  const _InboxIdSelectionDialog({
    required this.contact,
    required this.available,
  });

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
              context.l10n.createGroupPagePickInboxTitle,
              style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n
                  .createGroupPageMultipleDevices(contact.displayName),
              style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 12,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: available.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final entry = available[i];
                  final shortId = entry.inboxId.length > 12
                      ? '${entry.inboxId.substring(0, 6)}..${entry.inboxId.substring(entry.inboxId.length - 6)}'
                      : entry.inboxId;
                  final title = entry.label.isNotEmpty
                      ? '${contact.displayName}/${entry.label}'
                      : contact.displayName;
                  return InkWell(
                    onTap: () => Navigator.pop(context, entry),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tokens.glassFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tokens.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          GlassContactIcon(contact: contact, size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                                    color: tokens.starkWhite,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  shortId,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ).copyWith(color: tokens.textDim),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: tokens.textDim,
                          ),
                        ],
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
