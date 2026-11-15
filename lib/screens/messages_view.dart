import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/conversation_row.dart';
import 'package:publicos_desktop/screens/create_group_page.dart';
import 'package:publicos_desktop/screens/manage_inbox_ids_page.dart';
// DELTA(desktop): route-shaped pages hosted in big dialogs (InlineFlowHost).
import 'package:publicos_desktop/widgets/inline_flow_host.dart';
import 'package:publicos_desktop/widgets/messages/sheets/messages_settings_sheet.dart';
import 'package:publicos_desktop/widgets/messages/messages_chip_bar.dart';
// DELTA(desktop): keychain = the desktop dialog, same as every door.
import 'package:publicos_desktop/widgets/keychain_dialog.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// Internal data wrapper for a conversation + its display state.
class _ConversationData {
  final XmtpConversation conversation;
  Contact contact;
  final Message lastMessage;
  final bool isGroupUpdatedOnly;
  final bool hasNoMessages;
  int unreadCount;

  _ConversationData(
    this.conversation,
    this.contact,
    this.lastMessage, {
    this.isGroupUpdatedOnly = false,
    this.hasNoMessages = false,
    this.unreadCount = 0,
  });

  String get topic => conversation.topic;
  bool get isGroup => conversation.isGroup;
}

/// Messages tab — glass conversation list with chip bar, inline search,
/// pull-to-refresh, live message stream, progressive contact resolution.
///
/// Direct Core throughout (no repo). State machine ported from publicos_client's
/// `XmtpInboxView`.
///
/// Banner-as-row-background is gated on the `messages_show_contact_banner`
/// setting (loaded once in initState, default true). Toggle lives in the
/// settings sheet.
/// One row the search offers: a person AND which of their inboxes it opens.
/// The label rides along so the row can title itself `name/label` — the same
/// grammar the browser header and the conversation list use.
class _SearchHit {
  final Contact contact;
  final String inboxId;
  final String label;
  const _SearchHit({
    required this.contact,
    required this.inboxId,
    required this.label,
  });
}

class MessagesView extends StatefulWidget {
  /// The conversation the pane has open, for the row's [SelectionPill]. The
  /// pane opens by topic (groups, and DMs reached by topic) or by peer inbox
  /// (DMs), so a row matches on either.
  final String? selectedTopic;
  final String? selectedInboxId;

  const MessagesView({super.key, this.selectedTopic, this.selectedInboxId});

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  // Conversation state
  List<_ConversationData> _allowedConversations = [];
  List<_ConversationData> _unknownConversations = [];
  /// Search results, **one per inbox you could write to**.
  /// An account publishing `meta` and `public` offers two rows, titled
  /// `jmsl/meta` and `jmsl/public`, so every label is discoverable (a hit
  /// must not silently open inbox index 0).
  List<_SearchHit> _searchHits = const [];
  /// Bumped per query, so a slow resolve for an older query (typing
  /// `jmsl/meta` fires `jmsl` on the way) cannot paint over a newer one.
  int _resolveGeneration = 0;
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isResolving = false;
  bool _showPersonal = true;
  bool _showGroups = true;
  String _currentConsentFilter = 'allowed'; // 'allowed' or 'unknown'
  StreamSubscription<Message>? _messageSubscription;
  Map<String, int> _unreadCounts = {};

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // Settings-driven UX flags
  bool _showBanner = true;

  List<_ConversationData> get _conversations =>
      _currentConsentFilter == 'allowed'
          ? _allowedConversations
          : _unknownConversations;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadBannerSetting();
    loadConversations();
    _setupMessageListener();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadBannerSetting() async {
    try {
      final setting = await PublicOSSettings.getSetting(
        'messages_show_contact_banner',
      );
      if (!mounted) return;
      setState(() => _showBanner = setting?.value != 'false'); // default true
    } catch (_) {
      // pre-auth or error — leave default
    }
  }

  Future<void> _setupMessageListener() async {
    _messageSubscription?.cancel();
    _messageSubscription = PublicOS.messageStream.listen(
      _handleIncomingMessage,
      onError: (_) {},
    );
  }

  Future<void> _handleIncomingMessage(Message message) async {
    if (!mounted) return;

    if (message.content.type == MessageType.reaction ||
        message.content.type == MessageType.reply ||
        message.content.type == MessageType.readReceipt ||
        message.content.type == MessageType.group_updated) {
      return;
    }

    final allowedIndex = _allowedConversations.indexWhere(
        (conv) => conv.topic == message.xmtpConversationTopic);
    final unknownIndex = _unknownConversations.indexWhere(
        (conv) => conv.topic == message.xmtpConversationTopic);

    if (allowedIndex != -1) {
      final existingConv = _allowedConversations[allowedIndex];
      final isFromOther = message.senderInboxId != PublicOS.clientXmtpInboxId;
      final isActiveConversation = message.xmtpConversationTopic ==
          PublicOSConversations.activeConversationTopic;
      final updatedConv = _ConversationData(
        existingConv.conversation,
        existingConv.contact,
        message,
        isGroupUpdatedOnly: false,
        hasNoMessages: false,
        unreadCount: (isFromOther && !isActiveConversation)
            ? existingConv.unreadCount + 1
            : existingConv.unreadCount,
      );
      setState(() {
        _allowedConversations.removeAt(allowedIndex);
        _allowedConversations.insert(0, updatedConv);
      });
      if (!message.isPending) HapticFeedback.lightImpact();
    } else if (unknownIndex != -1) {
      final existingConv = _unknownConversations[unknownIndex];
      final isFromOther = message.senderInboxId != PublicOS.clientXmtpInboxId;
      final isActiveConversation = message.xmtpConversationTopic ==
          PublicOSConversations.activeConversationTopic;
      final updatedConv = _ConversationData(
        existingConv.conversation,
        existingConv.contact,
        message,
        isGroupUpdatedOnly: false,
        hasNoMessages: false,
        unreadCount: (isFromOther && !isActiveConversation)
            ? existingConv.unreadCount + 1
            : existingConv.unreadCount,
      );
      setState(() {
        _unknownConversations.removeAt(unknownIndex);
        _unknownConversations.insert(0, updatedConv);
      });
      if (!message.isPending) HapticFeedback.lightImpact();
    } else {
      if (!message.isPending) {
        await loadConversations();
        HapticFeedback.mediumImpact();
      }
    }
  }

  Future<void> loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final allowedConversations = await PublicOSConversations.getConversations(
        consentState: 'allowed',
      );
      final allowedData = await _processConversations(allowedConversations);

      _unreadCounts = await PublicOSConversations.getUnreadCounts();
      for (final conv in allowedData) {
        if (_unreadCounts.containsKey(conv.topic)) {
          conv.unreadCount = _unreadCounts[conv.topic]!;
        }
      }

      if (mounted) {
        setState(() {
          _allowedConversations = _sortWithGroupUpdatedAtBottom(allowedData);
          _isLoading = false;
        });
      }

      _resolveContactsProgressively(_allowedConversations);

      final unknownConversations = await PublicOSConversations.getConversations(
        consentState: 'unknown',
      );
      final unknownData = await _processConversations(unknownConversations);
      for (final conv in unknownData) {
        if (_unreadCounts.containsKey(conv.topic)) {
          conv.unreadCount = _unreadCounts[conv.topic]!;
        }
      }

      if (mounted) {
        setState(() {
          _unknownConversations = _sortWithGroupUpdatedAtBottom(unknownData);
          if (_currentConsentFilter == 'unknown' &&
              _unknownConversations.isEmpty) {
            _currentConsentFilter = 'allowed';
          }
        });
      }

      _resolveContactsProgressively(_unknownConversations);

      // Kick off ENS / chain resolution for every member of every visible
      // group in the background. `resolveGroupMembers` is internally
      // rate-limited (100ms/member) and cached 12h per member, so safe to
      // call on each loadConversations. Results land in the contacts table
      // and surface on next message render (sender avatars / names).
      final groupStubs = [
        ..._allowedConversations,
        ..._unknownConversations,
      ]
          .where((c) => c.conversation.isGroup)
          .map((c) => c.contact)
          .toList();
      if (groupStubs.isNotEmpty) {
        unawaited(PublicOSContacts.resolveGroupMembers(groupStubs));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allowedConversations = [];
        _unknownConversations = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _resolveContactsProgressively(
    List<_ConversationData> conversations,
  ) async {
    if (_isResolving) return;
    _isResolving = true;

    for (int i = 0; i < conversations.length; i++) {
      if (!mounted) break;
      final conversationData = conversations[i];
      final conv = conversationData.conversation;
      if (conv.isGroup) continue;
      final peerInboxId = conv.peerInboxId;
      if (peerInboxId == null) continue;

      try {
        Contact? resolved =
            await PublicOSContacts.findContactByInboxId(peerInboxId);
        resolved ??= await PublicOSContacts.findContactInfoOnly(peerInboxId);
        if (resolved != null) {
          resolved = await PublicOSContacts.resolveContact(resolved);
        }
        if (mounted &&
            resolved != null &&
            resolved != conversationData.contact) {
          setState(() {
            final allowedIndex =
                _allowedConversations.indexWhere((c) => c.topic == conv.topic);
            if (allowedIndex >= 0) {
              _allowedConversations[allowedIndex].contact = resolved!;
            }
            final unknownIndex =
                _unknownConversations.indexWhere((c) => c.topic == conv.topic);
            if (unknownIndex >= 0) {
              _unknownConversations[unknownIndex].contact = resolved!;
            }
          });
        }
      } catch (_) {
        // continue
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _isResolving = false;
  }

  Future<void> _onRefresh() async {
    await PublicOSConversations.syncAll(consentStates: ['allowed', 'unknown']);
    await loadConversations();
  }

  /// Sort into 3 tiers: real conversations, group-updated-only, no-messages.
  List<_ConversationData> _sortWithGroupUpdatedAtBottom(
    List<_ConversationData> data,
  ) {
    final realConversations = data
        .where((c) => !c.isGroupUpdatedOnly && !c.hasNoMessages)
        .toList();
    final groupUpdatedOnly =
        data.where((c) => c.isGroupUpdatedOnly && !c.hasNoMessages).toList();
    final noMessages = data.where((c) => c.hasNoMessages).toList();

    realConversations.sort(
      (a, b) => b.lastMessage.timestamp.compareTo(a.lastMessage.timestamp),
    );
    groupUpdatedOnly.sort(
      (a, b) => b.lastMessage.timestamp.compareTo(a.lastMessage.timestamp),
    );
    noMessages.sort(
      (a, b) => b.lastMessage.timestamp.compareTo(a.lastMessage.timestamp),
    );

    return [...realConversations, ...groupUpdatedOnly, ...noMessages];
  }

  Future<List<_ConversationData>> _processConversations(
    List<XmtpConversation> conversations,
  ) async {
    return await Future.wait(
      conversations.map((conv) async {
        Contact contact;
        if (conv.isDm && conv.peerInboxId != null) {
          final resolved =
              await PublicOSContacts.findContactByInboxId(conv.peerInboxId!);
          contact = resolved ??
              Contact(
                displayName: conv.displayName,
                registeredInboxIDs: [
                  InboxEntry(inboxId: conv.peerInboxId!, label: 'main'),
                ],
              );
        } else if (conv.isGroup) {
          // Prefer the persisted group-stub Contact — it carries the group's
          // name + avatar record (seeded by `ensureGroupStub` on sync) so the
          // list row renders with the correct image, not just initials.
          final stub = await PublicOSContacts.findContactByTopic(conv.topic);
          contact = stub ?? Contact(displayName: conv.displayName);
        } else {
          contact = Contact(displayName: conv.displayName);
        }

        final messages = await PublicOSConversations.getLocalMessagesByTopic(
          conv.topic,
          20,
          true,
        );
        final nonReactionMessages = messages
            .where((message) =>
                message.content.type != MessageType.reaction &&
                message.content.type != MessageType.reply &&
                message.content.type != MessageType.readReceipt &&
                !(message.content.type == MessageType.text &&
                    message.content.value == null))
            .toList();

        Message lastMessage;
        bool isGroupUpdatedOnly = false;
        bool hasNoMessages = false;

        if (nonReactionMessages.isNotEmpty) {
          lastMessage = nonReactionMessages.first;
          if (nonReactionMessages.length == 1 &&
              nonReactionMessages.first.content.type ==
                  MessageType.group_updated) {
            isGroupUpdatedOnly = true;
          }
        } else {
          hasNoMessages = true;
          lastMessage = Message(
            id: 0,
            xmtpConversationTopic: conv.topic,
            timestamp: conv.createdAt ?? DateTime.now(),
            content: const MessageContent(
                type: MessageType.text, value: 'No messages yet'),
            senderAddress: conv.isGroup
                ? conv.topic
                : (contact.mainSession?.address.eip55With0x ?? ''),
            isPending: false,
            sendFailed: false,
          );
        }
        return _ConversationData(
          conv,
          contact,
          lastMessage,
          isGroupUpdatedOnly: isGroupUpdatedOnly,
          hasNoMessages: hasNoMessages,
        );
      }),
    );
  }

  void _onSearchChanged() {
    final next = _searchCtrl.text;
    if (next == _query) return;
    setState(() => _query = next);
    _handleSearchResolution();
  }

  Future<void> _handleSearchResolution() async {
    final gen = ++_resolveGeneration;
    final trimmed = _query.trim();
    if (trimmed.isEmpty) {
      if (_searchHits.isNotEmpty || _isSearching) {
        setState(() {
          _searchHits = const [];
          _isSearching = false;
        });
      }
      return;
    }

    // `name/label` addresses ONE inbox of an account: the browser's
    // domain/tab shape. `/` is in neither
    // the display-name nor the inbox-label charset, so the first `/` splits
    // cleanly. A trailing `jmsl/` (still typing) searches the plain name.
    final slash = trimmed.indexOf('/');
    final name = slash < 0 ? trimmed : trimmed.substring(0, slash);
    final rawLabel = slash < 0 ? '' : trimmed.substring(slash + 1);
    final String? label = rawLabel.isEmpty ? null : rawLabel.toLowerCase();

    setState(() => _isSearching = true);
    try {
      final hits = <String, _SearchHit>{};

      // 1. Locally stored people, matched on a SUBSTRING of the name:
      //    a peer resolved as `pedroLopez.eth` has to appear
      //    for `pedro`. Core's `resolveByIdentifier` is exact-match, so
      //    it finds nothing for a partial name.
      if (name.isNotEmpty) {
        for (final c in await PublicOSContacts.searchContactsByName(name)) {
          _collectHits(hits, c, label);
        }
        if (!mounted || gen != _resolveGeneration) return;
      }

      // 2. The exact identifiers: an on-chain display name, a `0x` account or
      //    session address, a 64-hex inbox ID.
      Contact? resolved = name.isEmpty
          ? null
          : await PublicOSContacts.resolveByIdentifier(name);

      // 3. Fallback: an address / inbox ID with no PublicOS account may still
      //    be a reachable XMTP peer (Converse.xyz, other apps on the network).
      //    Probe XMTP and persist a minimal stub Contact so the DM works.
      if (label == null && name.isNotEmpty) {
        resolved ??= await _resolveNonPublicosXmtpPeer(name);
      }

      if (!mounted || gen != _resolveGeneration) return;
      if (resolved != null) _collectHits(hits, resolved, label);

      setState(() {
        _searchHits = hits.values.toList();
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted || gen != _resolveGeneration) return;
      setState(() {
        _searchHits = const [];
        _isSearching = false;
      });
    }
  }

  /// One hit per inbox this contact publishes, keyed by inbox ID so the local
  /// and on-chain passes cannot list the same conversation twice.
  ///
  /// Dropped here: a contact with no registered inbox (nothing to open —
  /// `resolveByIdentifier` happily returns an account that never published
  /// one), any inbox whose label does not match an explicit `name/label`
  /// query, and **the inbox this device has loaded** (you cannot message
  /// yourself; same rule as the profile's chat tabs).
  void _collectHits(
      Map<String, _SearchHit> into, Contact contact, String? label) {
    final own = PublicOS.clientXmtpInboxId?.toLowerCase();
    for (final entry in contact.registeredInboxIDs ?? const <InboxEntry>[]) {
      final id = entry.inboxId;
      if (id.isEmpty) continue;
      if (label != null && entry.label.toLowerCase() != label) continue;
      if (own != null && id.toLowerCase() == own) continue;
      into.putIfAbsent(
        id.toLowerCase(),
        () => _SearchHit(contact: contact, inboxId: id, label: entry.label),
      );
    }
  }

  /// If [query] is an ETH address or XMTP inbox ID belonging to a peer that
  /// has no PublicOS account, probe XMTP and hand off to
  /// `PublicOSContacts.findContactInfoOnly` — which persists a minimal stub
  /// Contact on network hit. Returns null for plain-text queries or XMTP
  /// misses.
  Future<Contact?> _resolveNonPublicosXmtpPeer(String query) async {
    final isEthAddress = query.startsWith('0x') && query.length == 42;
    final isInboxId = _isValidInboxIdFormat(query);
    if (!isEthAddress && !isInboxId) return null;

    try {
      String? inboxId;
      if (isEthAddress) {
        inboxId = await PublicOSConversations.inboxIdFromAddress(query);
      } else {
        final canMessage =
            await PublicOSConversations.canMessageByInboxId(query);
        if (canMessage) inboxId = query;
      }
      if (inboxId == null || inboxId.isEmpty) return null;
      return await PublicOSContacts.findContactInfoOnly(inboxId);
    } catch (_) {
      return null;
    }
  }

  bool _isValidInboxIdFormat(String query) {
    if (query.length != 64) return false;
    if (query.startsWith('0x')) return false;
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(query);
  }

  List<_ConversationData> get _filteredData {
    List<_ConversationData> filtered = _conversations;

    if (!_showPersonal || !_showGroups) {
      filtered = filtered.where((conv) {
        final isGroup = conv.isGroup;
        if (isGroup && !_showGroups) return false;
        if (!isGroup && !_showPersonal) return false;
        return true;
      }).toList();
    }

    final trimmedQuery = _query.trim();
    if (trimmedQuery.isNotEmpty) {
      final query = trimmedQuery.toLowerCase();
      filtered = filtered.where((conv) {
        final contact = conv.contact;
        final sessionAddressMatch = contact.sessions?.any((c) =>
                c.address.eip55With0x.toLowerCase().contains(query)) ??
            false;
        final peerInboxId = conv.conversation.peerInboxId;
        // The row's own title, `name/label` (conversation_row), so typing
        // `jmsl/meta` keeps that chat in the list.
        final peerLabel =
            peerInboxId == null ? null : contact.labelForInboxId(peerInboxId);
        final inboxAddress = (peerLabel == null || peerLabel.isEmpty)
            ? null
            : '${contact.publicosDisplayName ?? contact.displayName}/$peerLabel'
                .toLowerCase();
        return contact.displayName.toLowerCase().contains(query) ||
            contact.publicosDisplayName?.toLowerCase().contains(query) == true ||
            inboxAddress?.contains(query) == true ||
            peerInboxId?.toLowerCase().contains(query) == true ||
            conv.topic.toLowerCase().contains(query) ||
            sessionAddressMatch;
      }).toList();
    }

    // Each hit becomes a start-a-conversation row, unless that inbox is
    // already a chat in the list above. Insertion order is preserved
    // (local matches first, then the exact/on-chain resolve).
    for (final hit in _searchHits.reversed) {
      final exists = filtered
          .any((conv) => conv.conversation.peerInboxId == hit.inboxId);
      if (exists) continue;
      final dummyMessage = Message(
        id: 0,
        xmtpConversationTopic: hit.inboxId,
        timestamp: hit.contact.createdAt ?? DateTime.now(),
        content: const MessageContent(
            type: MessageType.text, value: 'Tap to start conversation'),
        senderAddress: hit.contact.mainSession?.address.eip55With0x ?? '',
        isPending: false,
        sendFailed: false,
      );
      final dummyConv = XmtpConversation(
        topic: hit.inboxId,
        type: ConversationType.dm,
        peerInboxId: hit.inboxId,
        contact: hit.contact,
      );
      filtered.insert(
        0,
        _ConversationData(dummyConv, hit.contact, dummyMessage),
      );
    }
    return filtered;
  }

  bool _isSelected(_ConversationData data) {
    final topic = widget.selectedTopic;
    if (topic != null) return data.topic == topic;
    final inbox = widget.selectedInboxId;
    return inbox != null &&
        !data.conversation.isGroup &&
        data.conversation.peerInboxId == inbox;
  }

  void _handleConversationSelection(_ConversationData data) {
    final topic = data.topic;
    // Opening a chat ends the search: coming back should
    // show the whole list, not the stale query. [data] is already captured,
    // so clearing (which drops the search-result row via the listener) cannot
    // change where this tap goes.
    if (_searchCtrl.text.isNotEmpty) _searchCtrl.clear();
    final idx = _allowedConversations.indexWhere((c) => c.topic == topic);
    if (idx >= 0 && _allowedConversations[idx].unreadCount > 0) {
      setState(() => _allowedConversations[idx].unreadCount = 0);
    }
    final unkIdx = _unknownConversations.indexWhere((c) => c.topic == topic);
    if (unkIdx >= 0 && _unknownConversations[unkIdx].unreadCount > 0) {
      setState(() => _unknownConversations[unkIdx].unreadCount = 0);
    }

    if (data.conversation.isGroup) {
      AppNav.toConversation(context, topic);
    } else {
      final peerInboxId = data.conversation.peerInboxId;
      if (peerInboxId != null) {
        AppNav.toInbox(context, peerInboxId);
      } else {
        AppNav.toConversation(context, topic);
      }
    }
  }

  // ---- chip actions ---------------------------------------------------------

  void _openSettings() {
    showMessagesSettingsSheet(context).then((restored) {
      if (!mounted) return;
      // Setting may have changed — reload + propagate to rows.
      _loadBannerSetting();
      // A restored backup imported new conversations into the MLS store —
      // force a full reload so libxmtp surfaces them (full-reload-after-tx).
      if (restored == true) loadConversations();
    });
  }

  Future<void> _openKeychain() async {
    // DELTA(desktop): the client's KeychainSheet pops `true` on a real switch;
    // the desktop dialog reports through `onKeysChanged` (broader — also fires
    // on add/remove/rename — but the key-label comparison below keeps the
    // reload gated on an ACTUAL active-key change, exactly the client's
    // contract).
    final keyBefore = PublicOS.currentXmtpKeyLabel;
    var changed = false;
    await showKeychainDialog(
      context,
      myContact: AppStateNotifier.currentMyContact,
      onKeysChanged: () => changed = true,
    );
    if (changed &&
        mounted &&
        PublicOS.currentXmtpKeyLabel != keyBefore) {
      setState(() {
        _allowedConversations = [];
        _unknownConversations = [];
        _isLoading = true;
        _isResolving = false;
      });
      _setupMessageListener();
      loadConversations();
    }
  }

  Future<void> _openCreateGroup() async {
    // CreateGroupPage is a pure imperative route: it pops with the new
    // conversation's topic on success, or null if dismissed.
    // DELTA(desktop): hosted in a big dialog via InlineFlowHost (the SSP
    // MANAGE pattern) instead of a CupertinoPageRoute push; the pop-topic
    // contract and the client's follow-up flow are unchanged.
    final topic = await showFlowPageDialog<String>(
      context,
      page: const CreateGroupPage(),
    );
    if (topic == null || !mounted) return;
    // Open the chat just like tapping a conversation; refresh the list
    // when the user pops back so the new group shows up.
    await AppNav.toConversation(context, topic);
    if (!mounted) return;
    loadConversations();
  }

  Future<void> _openInboxIds() async {
    // DELTA(desktop): big-dialog host, same as create-group.
    await showFlowPageDialog<void>(
      context,
      page: const ManageInboxIdsPage(),
    );
  }

  // ---- build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    return Column(
      children: [
        _SearchField(
          controller: _searchCtrl,
          tokens: tokens,
          isSearching: _isSearching,
        ),
        MessagesChipBar(
          isShowingRequests: _currentConsentFilter == 'unknown',
          showPersonal: _showPersonal,
          showGroups: _showGroups,
          unknownCount: _unknownConversations.length,
          currentKeyLabel: PublicOS.currentXmtpKeyLabel,
          onTapRequests: () => setState(() {
            // Toggle: tap Requests to view pending, tap again to go back
            // to the allowed inbox. No explicit "All" chip — Requests is
            // its own visible/hidden pair.
            _currentConsentFilter =
                _currentConsentFilter == 'unknown' ? 'allowed' : 'unknown';
          }),
          onTogglePersonal: () => setState(() {
            if (!_showPersonal && _showGroups == false) _showGroups = true;
            _showPersonal = !_showPersonal;
          }),
          onToggleGroups: () => setState(() {
            if (!_showGroups && _showPersonal == false) _showPersonal = true;
            _showGroups = !_showGroups;
          }),
          onTapNewGroup: _openCreateGroup,
          onTapSettings: _openSettings,
          onTapKeys: _openKeychain,
          onTapInboxIds: _openInboxIds,
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: tokens.starkWhite,
                    strokeWidth: 2,
                  ),
                )
              : _buildList(tokens),
        ),
      ],
    );
  }

  Widget _buildList(GlassTokens tokens) {
    final conversations = _filteredData;
    if (conversations.isEmpty) {
      // No key set loaded → the inbox can't exist yet. Show a "load your keys"
      // screen instead of the generic "no conversations" copy. A live search
      // still shows the normal empty state.
      final noKeys = (PublicOS.currentXmtpKeyLabel ?? '').isEmpty &&
          _query.trim().isEmpty;
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: tokens.starkWhite,
        backgroundColor: tokens.surfaceElevated,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * (noKeys ? 0.6 : 0.5),
              child: noKeys
                  ? _NoKeysEmptyState(tokens: tokens, onLoadKeys: _openKeychain)
                  : _EmptyState(
                      tokens: tokens,
                      hasQuery: _query.trim().isNotEmpty,
                      isRequests: _currentConsentFilter == 'unknown',
                    ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: tokens.starkWhite,
      backgroundColor: tokens.surfaceElevated,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversationData = conversations[index];
          return ConversationRow(
            contact: conversationData.contact,
            conversation: conversationData.conversation,
            lastMessage: conversationData.lastMessage,
            onTap: () => _handleConversationSelection(conversationData),
            iconSize: 56,
            isNew: false,
            unreadCount: conversationData.unreadCount,
            showBanner: _showBanner,
            selected: _isSelected(conversationData),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search field
// ---------------------------------------------------------------------------

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final GlassTokens tokens;
  final bool isSearching;

  const _SearchField({
    required this.controller,
    required this.tokens,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        // Borderless, matching the contacts pane's field and the shell's
        // borderless direction: one tone step down from the list
        // panel carries the edge, no hairline, so the two columns read as
        // one design.
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
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
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (isSearching) {
                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: tokens.textDim,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: tokens.textDim,
                  ),
                  splashRadius: 16,
                  onPressed: controller.clear,
                );
              },
            ),
            hintText: context.l10n.messagesViewSearchHint,
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
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final GlassTokens tokens;
  final bool hasQuery;
  final bool isRequests;

  const _EmptyState({
    required this.tokens,
    required this.hasQuery,
    required this.isRequests,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String title;
    final String subtitle;
    if (hasQuery) {
      icon = Icons.search_off_rounded;
      title = context.l10n.messagesViewEmptyNoMatchesTitle;
      subtitle = context.l10n.messagesViewEmptyNoMatchesSubtitle;
    } else if (isRequests) {
      icon = Icons.mail_outline_rounded;
      title = context.l10n.messagesViewEmptyNoRequestsTitle;
      subtitle = context.l10n.messagesViewEmptyNoRequestsSubtitle;
    } else {
      icon = Icons.message_outlined;
      title = context.l10n.messagesViewEmptyNoConversationsTitle;
      subtitle = context.l10n.messagesViewEmptyNoConversationsSubtitle;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: tokens.textDim),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// No-keys empty state
// ---------------------------------------------------------------------------

/// Shown in the conversation area when no XMTP key set is loaded. Tapping it
/// (or the Keys chip above) opens the keychain.
class _NoKeysEmptyState extends StatelessWidget {
  final GlassTokens tokens;
  final VoidCallback onLoadKeys;

  const _NoKeysEmptyState({required this.tokens, required this.onLoadKeys});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onLoadKeys,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PhigitalLoadingWidget(
                size: 72,
                showShadows: false,
                rotate: false,
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.messagesViewNoKeysTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                        text: context.l10n.messagesViewNoKeysSubtitleBefore),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        Icons.sim_card_outlined,
                        size: 15,
                        color: tokens.starkWhite,
                      ),
                    ),
                    TextSpan(
                        text: context.l10n.messagesViewNoKeysSubtitleAfter),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
