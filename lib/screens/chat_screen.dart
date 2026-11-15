import 'dart:async';
import 'dart:convert';
import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:publicos_desktop/widgets/message_input.dart';
import 'package:publicos_desktop/widgets/messages/date_separator.dart';
import 'package:publicos_desktop/widgets/messages/message_widget.dart';
import 'package:publicos_desktop/widgets/messages/group_event_line.dart';
import 'package:publicos_desktop/widgets/messages/debug_chat_view.dart';
import 'package:publicos_desktop/widgets/chat_appearance.dart';
import 'package:publicos_desktop/widgets/messages/conversation_settings_sheet.dart';
import 'package:publicos_desktop/widgets/messages/unread_divider.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

class SimpleChatScreen extends StatefulWidget {
  final Contact? contact; // New input for the contact
  final String? inboxId; // Peer inbox ID for DMs
  final String? topic;   // Defensive fallback for DM-via-notification taps
                         // when [inboxId] resolution didn't populate (e.g.
                         // browser failed Phase-1/Phase-2 propagation).
                         // Group chats carry their topic on the Contact;
                         // this field is for the DM case only.
  final VoidCallback? onActiveKeyChanged; // Bubbled from the input bar when the
                         // user switches the active XMTP key — lets the host
                         // (Browser) re-check self-chat and redirect to profile.
  final ValueChanged<VoidCallback?>? onChatSettingsAvailable; // Hands the host
                         // (Browser) an opener for the conversation-settings
                         // sheet once a topic resolves (null = no topic yet),
                         // so the address-bar gear can drive it. The gear lives
                         // on the address bar, not the input bar.
  final String? messageDraft; // Pre-fills the composer once on mount (deep-link ?message=).

  const SimpleChatScreen({
    super.key,
    this.contact, // Make it optional
    this.inboxId,
    this.topic,
    this.onActiveKeyChanged,
    this.onChatSettingsAvailable,
    this.messageDraft,
  });

  @override
  State<SimpleChatScreen> createState() => _SimpleChatScreenState();
}

class _SimpleChatScreenState extends State<SimpleChatScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<MessageInputState> _inputKey = GlobalKey<MessageInputState>();
  final List<Message> _messages = []; // Only non-reaction messages for display
  final List<Message> _reactions = []; // Reaction messages stored separately
  // One entry per calendar day; each renders as a SliverMainAxisGroup whose
  // PinnedHeaderSliver (the DateSeparator pill) sticks to the viewport top
  // until the next day's group pushes it off.
  final List<_DayGroup> _dayGroups = [];
  // Drives the jump-to-bottom chip AND gates the keyboard-follow: while this is
  // false the user is within ~1000px of the bottom (chip hidden), so opening the
  // keyboard re-pins the list to the bottom. Once they've scrolled into history
  // (chip visible) the keyboard leaves their place alone. One threshold, one
  // source of truth — see _setupScrollListener / didChangeMetrics.
  bool _showScrollToBottom = false;
  // Last raw keyboard inset (physical px, read from the FlutterView in
  // didChangeMetrics). Lets the keyboard-follow re-pin ONLY when the keyboard
  // actually shows/hides — not on unrelated window-metrics churn (e.g. returning
  // from the system "open with" sheet fires didChangeMetrics repeatedly with
  // focus/status-bar changes but no keyboard change; re-pinning on those snapped
  // the list to the bottom of a transiently-resized viewport → a one-frame flash).
  double _lastKeyboardInset = 0.0;
  StreamSubscription<Message>? _messageSubscription;
  String? _currentTopic;

  // Contact cache to avoid repeated lookups
  final Map<String, Contact> _contactCache = {};
  // Aspect-ratio cache for ChatVideoBubble, shared across every MessageWidget
  // in this conversation. Dies with this state when the user leaves the chat.
  // Per-bubble "expanded" lives on _ChatVideoBubbleState itself — that state
  // is preserved across scroll via MessageWidget's AutomaticKeepAliveClientMixin
  // and dies with the conversation, so tapped videos stay tapped during the
  // visit and reset on next visit.
  final Map<String, double> _videoAspectCache = {};
  // Bookmarked message ids (network idXmtp) for THIS conversation. Shared with
  // every bubble like _videoAspectCache; a bubble's toggle mutates it in place
  // and repaints itself (reactive state can't live up here, see the
  // MessageWidget-cache note), then calls _persistBookmarks. Stored per topic
  // under the generic setting `message_bookmarks_<topic>` (a JSON list).
  final Set<String> _bookmarkIds = {};
  bool _isLoading = true;

  Contact? _selectedChatContact; // Private variable to hold the contact
  Message? _replyToMessage; // Message being replied to
  String? _consentState; // Track conversation consent state
  String? _seenMessageId; // ID of the last message confirmed seen by peer
  bool _displayReadReceipts = true; // Whether to display read receipts (user setting)
  // Char budget for the shared "trim long messages" reading setting. null =
  // show every message in full. Loaded before the first list build.
  int? _messageTrimChars = kMessageTrimMaxChars;
  bool _debugMode = false;
  int? _unreadDividerIndex; // Index in displayable messages where the unread divider should be inserted

  // Scroll-up pagination over the local DB (Core's query takes a `before:`
  // cursor, so no Core changes). The loaded window grows by _olderPageSize per
  // page; full-reload paths re-fetch the WHOLE window so a rebuild (background
  // sync, reactions) never snaps back to just the newest 300.
  static const int _initialWindowSize = 300;
  static const int _olderPageSize = 100;
  int _loadedWindowSize = _initialWindowSize;
  bool _loadingOlder = false;
  bool _hasMoreOlder = true;

  @override
  void initState() {
    super.initState();

    // Observe window metrics so we can re-pin the conversation to the bottom
    // when the keyboard opens. Reading viewInsets from this widget's MediaQuery
    // doesn't work — the Scaffold's resizeToAvoidBottomInset consumes the bottom
    // inset for everything inside its body — so we listen at the binding level.
    WidgetsBinding.instance.addObserver(this);

    // DELTA(desktop): the bubbles are built widgets cached in _dayGroups,
    // so a chat-appearance change (the settings dialog floating over the
    // pane) only shows after a rebuild — listen and rebuild live.
    ChatAppearance.instance.addListener(_onAppearanceChanged);

    // Initialize _selectedChatContact from widget.contact or fall back to PublicOS.selectedProfile
    _selectedChatContact = widget.contact;

    // Seed cache so the first _buildMessageList has the peer's color immediately.
    // Prefer the inbox ID we were opened with (widget.inboxId), since a Contact
    // can have multiple inboxes — the chat is bound to one.
    if (widget.contact != null && widget.inboxId != null) {
      _contactCache[widget.inboxId!] = widget.contact!;
    }

    _initialize();
    _setupScrollListener();
  }

  // Get contact with caching - always returns a Contact, never null
  Future<Contact> _getContactWithCache(String inboxId) async {
    print("Chat Screen: Getting contact for $inboxId");
    // If this is my address, use my contact
    if (inboxId == PublicOS.clientXmtpInboxId) {
      _contactCache[inboxId] = AppStateNotifier.currentMyContact!;
      return AppStateNotifier.currentMyContact!;
    }

    // Check cache first
    if (_contactCache.containsKey(inboxId)) {
      print("Returning contact from cache for $inboxId");
      return _contactCache[inboxId]!;
    }

    // Try to get from local database only
    final localContact = await PublicOSContacts.searchContacts(inboxId);
    if (localContact != null) {
      _contactCache[inboxId] = localContact;
      print("Chat Screen: Contact ${localContact.displayName} added to cache from local DB");
      return localContact;
    }

    // Contact not found in local DB - create a stub via findContactInfoOnly (saved to DB)
    print("Chat Screen: No local contact for $inboxId, creating stub via findContactInfoOnly()");
    final stub = await PublicOSContacts.findContactInfoOnly(inboxId);
    if (stub != null) {
      _contactCache[inboxId] = stub;
      print("Chat Screen: Stub created and cached for $inboxId: ${stub.displayName}");
      return stub;
    }

    // Absolute fallback - in-memory only if findContactInfoOnly fails
    print("Chat Screen: ⚠️ findContactInfoOnly() returned null for $inboxId, using in-memory fallback");
    print("Chat Screen: ⚠️ This contact will have NO sessions, NO records — browser will show old Manage Contact screen");
    final fallbackContact = Contact.stub(
      displayName: '${inboxId.substring(0, 6)}...${inboxId.substring(inboxId.length - 4)}',
    );
    _contactCache[inboxId] = fallbackContact;
    return fallbackContact;
  }

  void _handleReplyToMessage(Message message) {
    setState(() {
      _replyToMessage = message;
    });
  }

  void _clearReply() {
    setState(() {
      _replyToMessage = null;
    });
  }

  /// Send a message programmatically (used by interactive action buttons).
  /// Codecs are registered at init — no on-the-fly registration needed.
  Future<void> _sendTextMessage(dynamic content, String authorityId, String typeId) async {
    if (_currentTopic == null) return;
    try {
      final isGroup = _selectedChatContact?.isGroupChat ?? false;
      if (isGroup) {
        await PublicOSConversations.sendGroupMessage(
          _currentTopic!, content, authorityId, typeId,
        );
      } else if (widget.inboxId != null && widget.inboxId!.isNotEmpty) {
        final sent = await PublicOSConversations.sendMessageByInboxId(
          widget.inboxId!, _currentTopic!, content, authorityId, typeId,
        );
        // Send is find-or-create; adopt the live topic if it healed a stale one.
        final live = sent?.xmtpConversationTopic;
        if (live != null && live.isNotEmpty && live != _currentTopic) {
          _handleConversationCreated(live);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizedError(context.l10n, e,
                fallback: context.l10n.chatScreenFailedToSend)),
          ),
        );
      }
    }
  }

  /// Called by MessageInput when a DM topic is resolved — either on first-send
  /// (new DM) or when a send healed a stale topic onto the live one. Re-points
  /// chat state, reloads the (possibly migrated) history, and refreshes consent
  /// so a banner stuck on a dead topic clears.
  void _handleConversationCreated(String topic) {
    if (topic == _currentTopic) return;
    print('Chat Screen: Conversation topic resolved/healed — topic: $topic');
    setState(() {
      _currentTopic = topic;
    });
    PublicOSConversations.activeConversationTopic = topic;
    // A first-send/heal just produced a topic — let the host enable the gear.
    _publishSettingsAvailability();
    // Set up the stream for the new topic, then load migrated history + consent.
    _setupMessageStream();
    _refreshAfterTopicChange();
  }

  /// Reload messages and consent after the topic changes (heal / first-send).
  Future<void> _refreshAfterTopicChange() async {
    try {
      // New topic = new history — reset the pagination window.
      _loadedWindowSize = _initialWindowSize;
      _hasMoreOlder = true;
      await _loadMessages();
      await _buildMessageList();
      await _checkConsentState();
    } catch (e) {
      print('Error refreshing after topic change: $e');
    }
  }

  /// Tell the host whether the conversation-settings sheet can be opened: a
  /// live opener once a topic exists (DM resolved / group / healed), null
  /// otherwise so the host hides the address-bar gear (e.g. on a brand-new
  /// DM). Method tear-offs of the same instance compare equal, so the host
  /// dedupes redundant publishes.
  void _publishSettingsAvailability() {
    widget.onChatSettingsAvailable?.call(
      _currentTopic != null ? _openConversationSettings : null,
    );
  }

  /// Open the conversation-settings sheet (consent, shared media, and the
  /// hidden debug tools). Lives here so the address-bar gear can drive it; the
  /// sheet's 'debug' result flips this chat straight into DebugChatView.
  Future<void> _openConversationSettings() async {
    if (!mounted) return;
    final topic = _currentTopic;
    if (topic == null) return;
    // DELTA(desktop): centered glass dialog instead of a bottom sheet; the
    // client's post-sheet handling below is verbatim.
    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: DialogWidth.l,
            maxHeight: MediaQuery.of(dialogCtx).size.height * 0.85,
          ),
          child: ConversationSettingsSheet(conversationTopic: topic),
        ),
      ),
    );
    if (result == 'debug' && mounted) {
      setState(() => _debugMode = true);
      return;
    }
    // "Trim long messages" lives in that sheet but is shared across every chat.
    // The bubbles are built widgets cached in _dayGroups, so a changed budget
    // only takes effect on a rebuild.
    if (!mounted) return;
    final before = _messageTrimChars;
    await _loadTrimSetting();
    if (mounted && _messageTrimChars != before) {
      await _buildMessageList();
    }
  }

  @override
  void didUpdateWidget(covariant SimpleChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When browser rebuilds after _syncFromChain, the contact may have updated records (color, name, etc.)
    if (widget.contact != null && widget.contact != oldWidget.contact) {
      _selectedChatContact = widget.contact;
      if (widget.inboxId != null) {
        _contactCache[widget.inboxId!] = widget.contact!;
      }
      _buildMessageList();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Topic resolution happens in _initialize() (async via inbox id), so
    // there is nothing to re-check here.
  }

  /// Window metrics changed. We only care about the KEYBOARD sliding in/out
  /// (which resizes the Scaffold body and grows/shrinks the scroll viewport) —
  /// NOT every metrics churn. Returning from a system sheet (e.g. the "open
  /// with" chooser) fires didChangeMetrics repeatedly with focus/status-bar
  /// changes but no keyboard change; re-pinning on those snapped the list to a
  /// transiently-resized viewport bottom and back (a visible flash). So gate on
  /// the raw keyboard inset actually changing. Read it from the FlutterView, not
  /// MediaQuery — the Scaffold body zeroes the bottom inset for its descendants.
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted) return;
    final view = View.maybeOf(context);
    if (view == null) return;
    final keyboardInset = view.viewInsets.bottom; // physical px
    if (keyboardInset == _lastKeyboardInset) return; // not a keyboard change
    _lastKeyboardInset = keyboardInset;
    if (_showScrollToBottom) return; // scrolled into history → leave it alone
    _instantScrollToBottom(); // jumps to maxScrollExtent post-frame
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _isLoading = true;
      });
      // Resolve the conversation topic:
      //   - Group chat: topic is carried on the stub Contact directly.
      //   - DM: look up topic from the peer inbox ID. If no DM exists yet,
      //     _currentTopic stays null and gets created on first send (see
      //     MessageInput.onConversationCreated).
      try {
        if (_selectedChatContact?.isGroupChat == true) {
          _currentTopic = _selectedChatContact!.xmtpConversationTopic;
        } else if (widget.inboxId != null && widget.inboxId!.isNotEmpty) {
          final conv = await PublicOSConversations.getConversationByPeerInboxId(widget.inboxId!);
          _currentTopic = conv?.topic;
        } else if (widget.topic != null && widget.topic!.isNotEmpty) {
          // Defensive: caller passed a topic directly (notification tap on
          // a DM where the browser couldn't resolve _selectedChatInboxId).
          // Look up the conversation by topic as a last resort.
          final conv = await PublicOSConversations.getConversation(widget.topic!);
          _currentTopic = conv?.topic;
        }
      } catch (e) {
        print('Error resolving conversation topic: $e');
        _currentTopic = null;
      }
      print('Osux Chat init: ${_selectedChatContact?.displayName} topic: $_currentTopic');
      PublicOSConversations.activeConversationTopic = _currentTopic;
      // Opening the chat = the user has "seen" any pending notif thread for
      // this conversation. Clear the per-topic notif-history so the next
      // incoming message starts a fresh MessagingStyle thread rather than
      // stacking onto already-read context.
      if (_currentTopic != null && _currentTopic!.isNotEmpty) {
        unawaited(PublicOSConversations.clearNotifHistory(_currentTopic!));
      }
      await PublicOSConversations.initializeMessages();

      // Read before any list build — the budget is baked into each bubble.
      await _loadTrimSetting();
      await _loadBookmarks();

      // Local-first paint: everything here reads the local DB (messages,
      // contacts, consent, settings), so the conversation renders immediately.
      // The XMTP network sync for this topic runs AFTER, unawaited — it used
      // to be awaited here, which kept the loading spinner up for the whole
      // network round-trip while the already-built local list sat hidden.
      if (_currentTopic != null) {
        await _loadMessages();
        await _loadContactsAndUpdateMessages();

        // Check consent state for this conversation
        await _checkConsentState();

        // Load read receipt display setting
        await _loadReadReceiptDisplaySetting();
      } else {
        // No topic yet (e.g. group member stub) — show empty chat, ready to send first message
        print('Chat Screen: No conversation topic yet — showing empty chat for ${widget.inboxId}');
        await _buildMessageList();
      }

      // Local history is ready — drop the spinner now (the finally below only
      // matters for the error paths), pin to the bottom, start the live stream.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Auto scroll to bottom on initial load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _instantScrollToBottom();
        _setupMessageStream();
        // Post-frame (past build) so notifying the host is a safe setState —
        // the group path resolves its topic synchronously inside initState.
        _publishSettingsAvailability();
      });

      // Background XMTP sync — fetch network history, then reload + rebuild.
      if (_currentTopic != null) {
        unawaited(_syncMessagesInBackground(_currentTopic!));
      }
    } catch (e) {
      print('Chat init error: $e');
      if (mounted) {
        _showError(context.l10n.chatScreenFailedToInit);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Background XMTP sync after the local-first paint: pull network history
  /// for [topic], reload from the DB, rebuild, and only then send the opening
  /// read receipt so it covers the just-fetched messages too. Bails if the
  /// topic changed mid-sync (a first-send heal repoints the chat — that path
  /// does its own reload). Re-pins to the bottom only when the user hasn't
  /// scrolled into history — same gate as the keyboard-follow.
  Future<void> _syncMessagesInBackground(String topic) async {
    try {
      await PublicOSConversations.syncMessagesByTopic(topic);
      if (!mounted || topic != _currentTopic) return;
      await _loadMessages();
      await _buildMessageList();
      // Sync may have pulled the peer's consent-state change (e.g. they
      // allowed us) — refresh so a stale banner clears.
      await _checkConsentState();
      if (!_showScrollToBottom) {
        _instantScrollToBottom();
      }
      _maybeSendReadReceipt();
    } catch (e) {
      print('Chat Screen: background message sync error: $e');
    }
  }

  Future<void> _checkConsentState() async {
    if (_currentTopic == null) return;

    try {
      final state = await PublicOS.xmtpClient!.getConversationConsentState(_currentTopic!);
      if (mounted) {
        setState(() {
          _consentState = state;
        });
      }
    } catch (e) {
      print('Error checking consent state: $e');
    }
  }

  Future<void> _loadReadReceiptDisplaySetting() async {
    try {
      final displaySetting = await PublicOSSettings.getSetting('read_receipt_display');
      if (mounted) {
        setState(() {
          // Default to true if not set
          _displayReadReceipts = displaySetting?.value != 'false';
        });
      }
    } catch (e) {
      print('Error loading read receipt display setting: $e');
    }
  }

  /// "Trim long messages" — an app-wide reading setting edited from the
  /// conversation-settings sheet. Stored as a char budget ('0' = off, absent =
  /// the kMessageTrimMaxChars default), and handed to every bubble.
  Future<void> _loadTrimSetting() async {
    try {
      final record = await PublicOSSettings.getSetting('messages_trim_chars');
      final parsed = record == null ? null : int.tryParse(record.value);
      final chars = record == null
          ? kMessageTrimMaxChars
          : (parsed != null && parsed > 0 ? parsed : null);
      if (mounted) setState(() => _messageTrimChars = chars);
    } catch (e) {
      print('Error loading message trim setting: $e');
    }
  }

  String? get _bookmarksKey =>
      (_currentTopic == null || _currentTopic!.isEmpty)
          ? null
          : 'message_bookmarks_$_currentTopic';

  /// Load this chat's bookmarks into [_bookmarkIds] (in place: bubbles hold
  /// the same Set). Read before the first list build.
  Future<void> _loadBookmarks() async {
    final key = _bookmarksKey;
    if (key == null) return;
    try {
      final record = await PublicOSSettings.getSetting(key);
      final ids = record == null
          ? const <String>[]
          : List<String>.from(jsonDecode(record.value) as List);
      _bookmarkIds
        ..clear()
        ..addAll(ids);
    } catch (e) {
      print('Error loading message bookmarks: $e');
    }
  }

  Future<void> _persistBookmarks() async {
    final key = _bookmarksKey;
    if (key == null) return;
    try {
      await PublicOSSettings.setSetting(
        key,
        Record.asSettings(
          key: key,
          value: jsonEncode(_bookmarkIds.toList()),
          // A bookmark is the user's own keepsake, so it doesn't age out.
          expiration: DateTime.now().add(const Duration(days: 36500)),
          isExpired: false,
          isSystem: true,
        ),
      );
    } catch (e) {
      print('Error saving message bookmarks: $e');
    }
  }

  Future<void> _setConsentState(String state) async {
    if (_currentTopic == null) return;

    try {
      await PublicOS.xmtpClient!.setConversationConsentState(_currentTopic!, state);
      if (mounted) {
        setState(() {
          _consentState = state;
        });
      }
    } catch (e) {
      print('Error setting consent state: $e');
      if (mounted) {
        _showError(context.l10n.chatScreenFailedToUpdateConsent);
      }
    }
  }

  /// Send a read receipt if this is a DM and settings allow it. Groups
  /// don't send read receipts (no single peer to target).
  Future<void> _maybeSendReadReceipt() async {
    if (_currentTopic == null || widget.inboxId == null) return;
    if (_selectedChatContact?.isGroupChat == true) return;

    await PublicOSConversations.sendReadReceipt(
      _currentTopic!,
      widget.inboxId!,
    );
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!mounted) return;

      // Show/hide scroll button based on scroll position. This same flag gates
      // the keyboard-follow (didChangeMetrics): hidden chip == near bottom.
      final showButton = _scrollController.position.maxScrollExtent -
              _scrollController.offset >
          1000.0;
      if (_showScrollToBottom != showButton) {
        setState(() => _showScrollToBottom = showButton);
      }

      // Near the top → pull the previous page of local history. Self-guarded
      // (in-flight / exhausted / still initializing), so firing every scroll
      // tick is fine.
      if (_scrollController.offset < 400.0) {
        _maybeLoadOlderMessages();
      }
    });
  }

  /// Scroll-up pagination: fetch the page of local rows older than the oldest
  /// loaded one and prepend it. The viewport is re-anchored by the
  /// content-height delta post-frame so the user keeps reading the same
  /// message — the delta is exact because day groups are eager Columns
  /// (extents are never estimated).
  Future<void> _maybeLoadOlderMessages() async {
    if (_loadingOlder || !_hasMoreOlder || _isLoading) return;
    if (_currentTopic == null || _messages.isEmpty) return;
    setState(() => _loadingOlder = true);
    try {
      // Cursor = oldest loaded row across messages AND reactions — reactions
      // ride the same query, so cursoring on displayables alone could re-fetch
      // reaction rows we already hold.
      DateTime oldest = _messages.first.timestamp;
      for (final r in _reactions) {
        if (r.timestamp.isBefore(oldest)) oldest = r.timestamp;
      }
      final older = await PublicOSConversations.getLocalMessagesByTopic(
        _currentTopic!,
        _olderPageSize,
        true, // desc — walks backward from the cursor
        before: oldest,
      );
      if (!mounted) return;
      if (older.length < _olderPageSize) _hasMoreOlder = false;
      if (older.isEmpty) return;
      _loadedWindowSize += older.length;

      // Resolve contacts the prepended page references (old group members may
      // have left — they won't be in the cache from the live window).
      final unresolved = <String>{};
      for (final m in older) {
        final sender = m.senderInboxId;
        if (sender != null && sender.isNotEmpty) unresolved.add(sender);
        final gu = m.content.value;
        if (gu is GroupUpdated) {
          if (gu.initiatedByInboxId.isNotEmpty) {
            unresolved.add(gu.initiatedByInboxId);
          }
          for (final a in gu.addedInboxes) {
            if (a.inboxId.isNotEmpty) unresolved.add(a.inboxId);
          }
          for (final r in gu.removedInboxes) {
            if (r.inboxId.isNotEmpty) unresolved.add(r.inboxId);
          }
        }
      }
      unresolved.removeWhere(_contactCache.containsKey);
      if (unresolved.isNotEmpty) {
        await Future.wait(unresolved.map(_getContactWithCache));
      }

      var prependedDisplayable = 0;
      for (final m in older) {
        if (m.content.type == MessageType.reaction) {
          _reactions.add(m);
        } else if (m.content.type == MessageType.readReceipt) {
          // Receipts only drive the seen-indicator on recent messages — skip.
        } else {
          _messages.add(m);
          prependedDisplayable++;
        }
      }
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _reactions.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      // The divider is an index into the displayable list — shift it past the
      // prepended page. Index 0 means "everything unread"; older history is
      // unread too, so it stays 0.
      if (_unreadDividerIndex != null && _unreadDividerIndex! > 0) {
        _unreadDividerIndex = _unreadDividerIndex! + prependedDisplayable;
      }

      final bool hadClients = _scrollController.hasClients;
      final double oldMax =
          hadClients ? _scrollController.position.maxScrollExtent : 0.0;
      final double oldOffset = hadClients ? _scrollController.offset : 0.0;
      await _buildMessageList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients || !hadClients) return;
        final delta = _scrollController.position.maxScrollExtent - oldMax;
        if (delta > 0) {
          _scrollController.jumpTo(oldOffset + delta);
        }
      });
    } catch (e) {
      print('Chat Screen: load-older error: $e');
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;

    final peerInboxId = widget.inboxId; // This is the targetInboxId for 1-on-1 from widget initialization
    final currentUserInboxId = PublicOS.clientXmtpInboxId;

    if (_currentTopic == null) {
      print('ChatScreen: Current topic is null, cannot load messages.');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.clear(); // Clear messages if topic is invalid
          _reactions.clear(); // Clear reactions too
          _buildMessageList(); // Rebuild to show empty or error state
        });
      }
      return;
    }

    // Ensure currentUserInboxId is available for direct chat query logic
    // For group chats or topic-only chats, currentUserInboxId is not strictly needed by getLocalMessagesByTopic itself
    // but good to check if we are in a state where it should be available.
    if (PublicOS.clientXmtpInboxId == null) {
        print('ChatScreen: Current user inbox ID is null. This might affect message operations.');
        // Potentially show an error or prevent loading if critical
    }

    try {
      List<Message> messages;
      // Core 1.0: chat_screen only handles DMs (1-on-1). Groups are a
      // different surface.
      print('ChatScreen: Loading messages for 1-on-1 chat. Topic: $_currentTopic, UserInboxID: $currentUserInboxId, PeerInboxID: $peerInboxId');
      messages = await PublicOSConversations.getLocalMessagesByTopic(
        _currentTopic!,
        _loadedWindowSize, // newest window; grows as scroll-up pages load
        true, // desc = true for newest first (sorted chronologically after load)
      );
      // Fewer rows than requested ⇒ the local DB has no older history —
      // disarms the scroll-up trigger (also covers short conversations).
      _hasMoreOlder = messages.length >= _loadedWindowSize;
      // group_updated is not filtered out — membership + metadata events
      // render as centered system lines (GroupEventLine) in _buildMessageList.
      // leave_request is already dropped upstream by Core.
      // for (final message in messages) {
      //   // This print is fine for debugging.
      //   print('Message loaded: ${message.id} - SenderInboxID: ${message.senderInboxId} - Type: ${message.content.typeId}');
      //   if (message.content.type == MessageType.attachment) {
      //     print('Chat Screen: Attachment.type ${message.content.type}');
      //     print('Chat Screen: Attachment.value ${message.content.value}');
      //     print('Chat Screen: Attachment.value length ${message.content.value.toString().length}');
      //   }
      // }

      if (!mounted) return;

      // Separate reaction messages and read receipts from displayable messages
      final displayableMessages = <Message>[];
      final reactionMessages = <Message>[];
      for (final message in messages) {
        if (message.content.type == MessageType.reaction) {
          reactionMessages.add(message);
        } else if (message.content.type == MessageType.readReceipt) {
          // Filtered out — tracked below by position
        } else {
          // group_updated falls through here → kept for the timeline.
          displayableMessages.add(message);
        }
      }

      // Sort displayable messages by timestamp
      displayableMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Find the latest read receipt from peer
      final myInboxId = PublicOS.clientXmtpInboxId;
      DateTime? latestReceiptTime;
      for (final m in messages) {
        if (m.content.type == MessageType.readReceipt &&
            m.senderInboxId == peerInboxId) {
          if (latestReceiptTime == null || m.timestamp.isAfter(latestReceiptTime)) {
            latestReceiptTime = m.timestamp;
          }
        }
      }

      // Find my last confirmed message before that receipt
      String? seenMsgId;
      if (latestReceiptTime != null && myInboxId != null) {
        for (int i = displayableMessages.length - 1; i >= 0; i--) {
          final msg = displayableMessages[i];
          if (msg.senderInboxId == myInboxId &&
              msg.idXmtp != null &&
              !msg.timestamp.isAfter(latestReceiptTime)) {
            seenMsgId = msg.idXmtp;
            break;
          }
        }
      }

      // Find the unread divider position: the isRead bookmark message
      int? unreadIdx;
      final readBookmarkIdx = displayableMessages.indexWhere((m) => m.isRead);
      if (readBookmarkIdx >= 0 && readBookmarkIdx < displayableMessages.length - 1) {
        // Divider goes after the bookmarked message (only if it's not the last message)
        unreadIdx = readBookmarkIdx + 1;
      } else if (readBookmarkIdx < 0 && displayableMessages.isNotEmpty) {
        // No bookmark at all — check if there are messages from others
        final myInbox = PublicOS.clientXmtpInboxId;
        final hasOtherMessages = displayableMessages.any((m) => m.senderInboxId != myInbox);
        if (hasOtherMessages) {
          unreadIdx = 0; // Everything is unread
        }
      }

      setState(() {
        _messages.clear();
        _messages.addAll(displayableMessages);

        _reactions.clear();
        _reactions.addAll(reactionMessages);
        _reactions.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        _seenMessageId = seenMsgId;
        _unreadDividerIndex = unreadIdx;
      });

      // Mark conversation as read now that the user has opened it
      if (_currentTopic != null) {
        PublicOSConversations.markAsRead(_currentTopic!);
      }
    } catch (e) {
      print('Load messages error: $e');
      if (mounted) {
        _showError(context.l10n.chatScreenFailedToLoadMessages);
      }
    }
  }


  // Then load contacts and update UI
  Future<void> _loadContactsAndUpdateMessages() async {
    // Pre-fetch contacts for all messages in batch for efficiency. Beyond
    // message senders, group_updated events reference participants (added /
    // removed / initiator) that the centered system line needs a name+avatar
    // for, so resolve those too.
    final uniqueInboxIds = <String>{};
    for (final message in _messages) {
      final sender = message.senderInboxId;
      if (sender != null && sender.isNotEmpty) uniqueInboxIds.add(sender);
      final gu = message.content.value;
      if (gu is GroupUpdated) {
        if (gu.initiatedByInboxId.isNotEmpty) {
          uniqueInboxIds.add(gu.initiatedByInboxId);
        }
        for (final a in gu.addedInboxes) {
          if (a.inboxId.isNotEmpty) uniqueInboxIds.add(a.inboxId);
        }
        for (final r in gu.removedInboxes) {
          if (r.inboxId.isNotEmpty) uniqueInboxIds.add(r.inboxId);
        }
      }
    }
    if (uniqueInboxIds.isEmpty) return;

    print("Chat Screen: Resolving ${uniqueInboxIds.length} unique inboxIds");

    // Pre-populate cache with contacts
    await Future.wait(uniqueInboxIds.map((inboxId) => _getContactWithCache(inboxId)));

    // Debug: show what we resolved
    for (final id in uniqueInboxIds) {
      final c = _contactCache[id];
      if (c != null) {
        print("Chat Screen: Resolved $id → ${c.displayName} | sessions: ${c.sessions?.length ?? 0} | records: ${c.records.length} | publicosAddr: ${c.publicosAddress}");
      }
    }

    await _buildMessageList(); // Rebuild the list with contact info and message context
  }

  Future<void> _setupMessageStream() async {
    _messageSubscription?.cancel();
    _messageSubscription = PublicOS.messageStream.listen(
      _handleNewMessage,
      onError: (e) => print('Message stream error: $e'),
    );
  }

  String _generateMessageKey(Message message) {
    if (message.idXmtp != null) {
      return 'xmtp-${message.idXmtp}';
    }
    return 'local-${message.id}-${message.timestamp.millisecondsSinceEpoch}';
  }

  Future<void> _buildMessageList() async {
    if (!mounted) return;

    final newGroups = <_DayGroup>[];
    DateTime? lastDate;
    // Widgets for the current calendar day land in the open group's children.
    List<Widget> dayChildren() => newGroups.last.children;

    // First pass: Aggregate reactions by target message
    final messagesWithReactions = _aggregateReactions(_messages, _reactions);

    final bool isGroupChat = _selectedChatContact?.isGroupChat ?? false;

    // Iterate through messagesWithReactions using an index to access previous and next messages
    for (int i = 0; i < messagesWithReactions.length; i++) {
      final message = messagesWithReactions[i];
      final messageDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );

      // Day changed → open a new group. The DateSeparator pill is not an
      // in-flow widget here; it renders as the group's pinned header in build().
      if (lastDate == null || messageDate.day != lastDate.day || messageDate.month != lastDate.month || messageDate.year != lastDate.year) {
        newGroups.add(_DayGroup(messageDate));
        lastDate = messageDate;
      }

      // Insert unread divider before this message if this is the divider position
      if (_unreadDividerIndex != null && i == _unreadDividerIndex) {
        dayChildren().add(const UnreadDivider(key: ValueKey('unread-divider')));
      }

      // group_updated (membership + metadata) renders as a centered system
      // line, not a chat bubble — no sender, reactions, or seen indicator.
      final groupEvent = message.content.value;
      if (groupEvent is GroupUpdated) {
        dayChildren().add(
          GroupEventLine(
            key: ValueKey(_generateMessageKey(message)),
            event: groupEvent,
            myInboxId: PublicOS.clientXmtpInboxId ?? '',
            contactLookup: (inboxId) => _contactCache[inboxId],
          ),
        );
        continue;
      }

      // Stickers are their own unit: a run of consecutive stickers from the same
      // sender in the same clock-minute lays out left-to-right in a Wrap with ONE
      // timestamp below it. A lone sticker is a run of 1 (still its own unit).
      if (_isStackableSticker(message)) {
        int runEnd = i;
        while (runEnd + 1 < messagesWithReactions.length) {
          final next = messagesWithReactions[runEnd + 1];
          if (!_isStackableSticker(next)) break;
          if (next.senderInboxId != message.senderInboxId) break;
          if (!_sameMinute(next.timestamp, message.timestamp)) break;
          if (_unreadDividerIndex != null &&
              _unreadDividerIndex == runEnd + 1) break;
          runEnd++;
        }
        final bool isMeRun = PublicOS.clientXmtpInboxId != null &&
            message.senderInboxId == PublicOS.clientXmtpInboxId;
        final stack = <Widget>[];
        for (int k = i; k <= runEnd; k++) {
          final m = messagesWithReactions[k];
          stack.add(MessageWidget(
            key: ValueKey(_generateMessageKey(m)),
            message: m,
            previousMessage: k > 0 ? messagesWithReactions[k - 1] : null,
            nextMessage: k < messagesWithReactions.length - 1
                ? messagesWithReactions[k + 1]
                : null,
            myInboxId: PublicOS.clientXmtpInboxId ?? '',
            senderContact: _contactCache[m.senderInboxId],
            isGroupChat: isGroupChat,
            peerInboxId: widget.inboxId,
            onReplySelected: _handleReplyToMessage,
            contactLookup: (inboxId) => _contactCache[inboxId],
            onSendTextMessage: _sendTextMessage,
            videoAspectCache: _videoAspectCache,
            bookmarkIds: _bookmarkIds,
            onBookmarksChanged: _persistBookmarks,
            inStack: true,
            showTimestamp: true, // every sticker shows its own time
            trimMaxChars: _messageTrimChars,
          ));
        }
        dayChildren().add(
          Padding(
            key: ValueKey('sticker-stack-${_generateMessageKey(message)}'),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            // Full width so the Wrap's alignment can push the run to the sender's
            // side; otherwise it shrink-wraps and the parent centers it. Each
            // sticker cell renders its own timestamp.
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: isMeRun ? WrapAlignment.end : WrapAlignment.start,
                spacing: 6,
                runSpacing: 2,
                children: stack,
              ),
            ),
          ),
        );
        i = runEnd; // for-loop's i++ advances past the run
        continue;
      }

      final senderContact = _contactCache[message.senderInboxId];
      final Message? prevMessage = i > 0 ? messagesWithReactions[i - 1] : null;
      final Message? nxtMessage = i < messagesWithReactions.length - 1 ? messagesWithReactions[i + 1] : null;

      // Timestamp: a (non-sticker) message shows its time only when it's the last
      // of its group — a consecutive same-sender, same-clock-minute run. The next
      // being a different sender, a different minute, a sticker, or a group event
      // closes the group and reveals the time.
      final bool showTs = nxtMessage == null ||
          nxtMessage.senderInboxId != message.senderInboxId ||
          !_sameMinute(nxtMessage.timestamp, message.timestamp) ||
          _isStackableSticker(nxtMessage) ||
          nxtMessage.content.type == MessageType.group_updated;

      // Determine if this message should show "seen" indicator
      final hasBeenRead = _displayReadReceipts &&
          !isGroupChat &&
          message.idXmtp != null &&
          _seenMessageId == message.idXmtp;

      dayChildren().add(
        Container(
          child: Padding(
            key: ValueKey(_generateMessageKey(message)),
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: MessageWidget(
              key: ValueKey(_generateMessageKey(message)),
              message: message,
              previousMessage: prevMessage,
              nextMessage: nxtMessage,
              myInboxId: PublicOS.clientXmtpInboxId ?? '',
              senderContact: senderContact,
              isGroupChat: isGroupChat,
              peerInboxId: widget.inboxId,
              onReplySelected: _handleReplyToMessage,
              showSeenIndicator: hasBeenRead,
              peerContact: hasBeenRead ? _selectedChatContact : null,
              contactLookup: (inboxId) => _contactCache[inboxId],
              onSendTextMessage: _sendTextMessage,
              videoAspectCache: _videoAspectCache,
              bookmarkIds: _bookmarkIds,
              onBookmarksChanged: _persistBookmarks,
              showTimestamp: showTs,
              trimMaxChars: _messageTrimChars,
            ),
          ),
        ),
      );
    }

    setState(() {
      _dayGroups.clear();
      _dayGroups.addAll(newGroups);
    });
  }

  /// Parse [content] into an AttachmentContent if possible (mirrors
  /// MessageWidget's parsing so stacking decisions match what renders).
  AttachmentContent? _tryParseAttachment(dynamic content) {
    if (content is AttachmentContent) return content;
    if (content is Map<String, dynamic>) {
      try {
        return AttachmentContent.fromJson(content);
      } catch (_) {}
    }
    if (content is String && content.startsWith('{')) {
      try {
        return AttachmentContent.fromJson(
            jsonDecode(content) as Map<String, dynamic>);
      } catch (_) {}
    }
    return null;
  }

  // The base grouping unit: same calendar day + same clock-minute (xx:00-xx:59).
  // A bucket, not a rolling window, so far-apart messages never chain together.
  bool _sameMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;

  /// A "sticker" for grouping: any isSticker (no MIME distinction) with no
  /// caption. A captioned sticker or gif-as-gif is a regular message.
  bool _isStackableSticker(Message m) {
    if (m.content.type != MessageType.attachment) return false;
    final att = _tryParseAttachment(m.content.value);
    if (att == null || !att.isSticker) return false;
    if (att.description != null && att.description!.isNotEmpty) return false;
    return true;
  }

  List<Message> _aggregateReactions(List<Message> displayMessages, List<Message> reactionMessages) {
    // Group reactions by target message ID
    final Map<String, List<Message>> reactionsByTarget = {};

    for (final message in reactionMessages) {
      if (message.content.value is Reaction) {
        final reaction = message.content.value as Reaction;
        final targetId = reaction.reference;
        
        if (!reactionsByTarget.containsKey(targetId)) {
          reactionsByTarget[targetId] = [];
        }
        reactionsByTarget[targetId]!.add(message);
      }
    }

    // Now process display messages and attach reactions
    final List<Message> messagesWithReactions = displayMessages.map((message) {
      if (message.idXmtp == null) return message;

      final reactions = reactionsByTarget[message.idXmtp] ?? [];
      if (reactions.isEmpty) return message;

      // Aggregate reactions by emoji
      final Map<String, int> reactionCounts = {};
      final Map<String, bool> hasMyReaction = {};
      final Map<String, List<String>> sendersByEmoji = {};
      final myInboxId = PublicOS.clientXmtpInboxId;

      for (final reactionMessage in reactions) {
        if (reactionMessage.content.value is Reaction) {
          final reaction = reactionMessage.content.value as Reaction;

          // Only count "added" reactions, ignore "removed" ones
          if (reaction.action == ReactionAction.added) {
            final emoji = reaction.content;
            reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;

            // Track sender inbox IDs per emoji
            final senderId = reactionMessage.senderInboxId;
            if (senderId != null) {
              sendersByEmoji.putIfAbsent(emoji, () => []);
              if (!sendersByEmoji[emoji]!.contains(senderId)) {
                sendersByEmoji[emoji]!.add(senderId);
              }
            }

            // Check if this is my reaction
            if (reactionMessage.senderInboxId == myInboxId) {
              hasMyReaction[emoji] = true;
            }
          }
        }
      }

      // Convert to MessageReactionSummary list
      final List<MessageReactionSummary> reactionSummaries = reactionCounts.entries
          .where((entry) => entry.value > 0)
          .map((entry) => MessageReactionSummary(
                emoji: entry.key,
                count: entry.value,
                hasMyReaction: hasMyReaction[entry.key] ?? false,
                senderInboxIds: sendersByEmoji[entry.key] ?? [],
              ))
          .toList();

      // Return message with reactions attached
      return message.copyWith(reactions: reactionSummaries);
    }).toList();

    return messagesWithReactions;
  }

  Future<void> _handleNewMessage(Message message) async {
    // Use _currentTopic for comparison
    if (!mounted || message.xmtpConversationTopic != _currentTopic) return;

    if (message.xmtpConversationTopic != _currentTopic) return;

    final distanceToBottom = _scrollController.hasClients ? _scrollController.position.maxScrollExtent - _scrollController.offset : 0;

    // Handle read receipt messages - update tracking but don't display
    if (message.content.type == MessageType.readReceipt) {
      if (message.senderInboxId == widget.inboxId) {
        // Peer sent a read receipt — find my last CONFIRMED message before this receipt.
        // Only messages with idXmtp are confirmed on the XMTP network; pending messages
        // have local-clock timestamps that can't be compared to network timestamps.
        final myInboxId = PublicOS.clientXmtpInboxId;
        for (int i = _messages.length - 1; i >= 0; i--) {
          final msg = _messages[i];
          if (msg.senderInboxId == myInboxId &&
              msg.idXmtp != null &&
              !msg.timestamp.isAfter(message.timestamp)) {
            if (_seenMessageId != msg.idXmtp) {
              setState(() { _seenMessageId = msg.idXmtp; });
              await _buildMessageList();
            }
            break;
          }
        }
      }
      return;
    }

    // Handle reaction messages separately
    if (message.content.type == MessageType.reaction) {
      // Check if this reaction already exists
      int? reactionIndex;
      for (int i = 0; i < _reactions.length; i++) {
        if ((_reactions[i].id != 0 && _reactions[i].id == message.id) || (_reactions[i].idXmtp != null && _reactions[i].idXmtp == message.idXmtp)) {
          reactionIndex = i;
          break;
        }
      }
      
      if (reactionIndex == null) {
        _reactions.add(message);
        _reactions.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _loadedWindowSize++; // new row at the tail — keep reloads covering the paged head
      } else {
        _reactions[reactionIndex] = message;
      }
      
      // Rebuild message list to update reaction displays
      await _buildMessageList();
      return;
    }

    // Ensure sender contact is cached before building widgets
    if (message.senderInboxId != null && !_contactCache.containsKey(message.senderInboxId)) {
      await _getContactWithCache(message.senderInboxId!);
    }

    // For a live group_updated, also resolve the inboxIds it references
    // (added / removed / initiator) so the centered system line renders names +
    // avatars immediately instead of short ids until the next reload.
    final liveGroupEvent = message.content.value;
    if (liveGroupEvent is GroupUpdated) {
      final ids = <String>{
        if (liveGroupEvent.initiatedByInboxId.isNotEmpty)
          liveGroupEvent.initiatedByInboxId,
        for (final a in liveGroupEvent.addedInboxes)
          if (a.inboxId.isNotEmpty) a.inboxId,
        for (final r in liveGroupEvent.removedInboxes)
          if (r.inboxId.isNotEmpty) r.inboxId,
      }..removeWhere(_contactCache.containsKey);
      if (ids.isNotEmpty) {
        await Future.wait(ids.map(_getContactWithCache));
      }
    }

    // Handle regular messages
    int? messageIndex;
    for (int i = 0; i < _messages.length; i++) {
      if ((_messages[i].id != 0 && _messages[i].id == message.id) || (_messages[i].idXmtp != null && _messages[i].idXmtp == message.idXmtp)) {
        messageIndex = i;
        break;
      }
    }

    // Commenting out widgetIndex loop as it's not used for current logic
    // for (int i = 0; i < _widgets.length; i++) {
    //   if (_widgets[i] is Padding && (_widgets[i] as Padding).child is MessageWidget) {
    //     final messageWidget = (_widgets[i] as Padding).child as MessageWidget;
    //     if ((message.id != 0 && messageWidget.message.id == message.id) || (message.idXmtp != null && messageWidget.message.idXmtp == message.idXmtp)) {
    //       widgetIndex = i;
    //       break;
    //     }
    //   }
    // }

    // final messageDate = DateTime( // messageDate seems unused here
    //   message.timestamp.year,
    //   message.timestamp.month,
    //   message.timestamp.day,
    // );

    // Get sender contact information (will use cache if available)
    // final senderContact = await _getContactWithCache(message.senderInboxId!); // senderContact seems unused here for the scroll logic

    // Use synchronized way to update state
    if (!mounted) return;

    // Adding new message
    if (messageIndex == null) {
      _messages.add(message);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _loadedWindowSize++; // new row at the tail — keep reloads covering the paged head
      await _buildMessageList();

      // Send read receipt when receiving new message from peer
      if (message.senderInboxId == widget.inboxId) {
        _maybeSendReadReceipt();
      }

      // Move read bookmark forward while user is in the conversation
      if (_currentTopic != null) {
        PublicOSConversations.markAsRead(_currentTopic!);
      }
    }
    // Replacing existing message
    else {
      _messages[messageIndex] = message;
      await _buildMessageList();
    }

    // Auto-scroll for new messages when near bottom
    if (_scrollController.hasClients) {
      // Ensure maxScrollExtent is positive to avoid division by zero or negative thresholds.
      // A maxScrollExtent of 0 typically means content is not scrollable or empty.
      if (_scrollController.position.maxScrollExtent > 0) {
        // User is considered "at the bottom" if their scroll position is within 5% of the end.
        // Or if they are exactly at the maxScrollExtent (which distanceToBottom <= 0 would cover)
        // Or if distanceToBottom is very small (e.g. < 1.0 pixel, to handle floating point inaccuracies)
        double bottomThreshold = _scrollController.position.maxScrollExtent * 0.05;
        // distanceToBottom is scrollController.position.maxScrollExtent - scrollController.offset
        if (distanceToBottom <= bottomThreshold) {
          _scrollToBottom(); // Uses addPostFrameCallback for reliability
        }
      } else {
        // If content isn't scrollable (e.g., very few messages), new message should make it scroll to bottom.
         _scrollToBottom();
      }
    }
  }

  Future<void> _scrollToBottom() async {
    if (!_scrollController.hasClients || !mounted) return;

    // Using addPostFrameCallback to ensure layout is complete before scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _instantScrollToBottom() {
    if (!
    _scrollController.hasClients || !mounted) return;
    
    // Using addPostFrameCallback to ensure layout is complete before scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        try {
          // Jump directly to the end. The +80 was likely to deal with
          // maxScrollExtent not being updated quickly enough.
          // Let's try without it first, relying on addPostFrameCallback.
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } catch (e) {
          print('Instant scroll error: $e');
          // It's possible that maxScrollExtent is 0 if there's no content or it's not scrollable.
        }
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildConsentBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.chatScreenConsentPrompt,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // No button
          TextButton(
            onPressed: () => _setConsentState('denied'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              context.l10n.chatScreenConsentNo,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Yes button
          FilledButton(
            onPressed: () => _setConsentState('allowed'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: theme.colorScheme.primary,
            ),
            child: Text(
              context.l10n.chatScreenConsentYes,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_debugMode && _currentTopic != null) {
      return Scaffold(
        body: DebugChatView(
          topic: _currentTopic!,
          myInboxId: PublicOS.clientXmtpInboxId ?? '',
          onClose: () => setState(() => _debugMode = false),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,

      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            if (_isLoading)
              const Center(
                child: PhigitalLoadingWidget(size: 32, showShadows: true),
              )
            else
              Column(
                  children: [
                    // Consent banner (shown when conversation is not allowed)
                    if (_consentState != null && _consentState != 'allowed')
                      _buildConsentBanner(theme),
                    // Messages area with floating chips overlay
                    Expanded(
                      child: Stack(
                        children: [
                          // Messages list
                          _messages.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 64,
                                        color: theme.colorScheme.primary.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        context.l10n.chatScreenNoMessages,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.l10n.chatScreenStartConversation,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              // One SliverMainAxisGroup per calendar day: the
                              // DateSeparator pill rides a PinnedHeaderSliver,
                              // so it sticks to the viewport top until the next
                              // day's group pushes it off. Each day's messages
                              // stay an eager Column (SliverToBoxAdapter) so
                              // maxScrollExtent is exact and every
                              // jump-to-bottom path (initial pin, keyboard
                              // re-pin, new-message follow) behaves as before.
                              : CustomScrollView(
                                  controller: _scrollController,
                                  slivers: [
                                    for (final group in _dayGroups)
                                      SliverMainAxisGroup(
                                        key: ValueKey(
                                            'day-${group.day.millisecondsSinceEpoch}'),
                                        slivers: [
                                          PinnedHeaderSliver(
                                            // The pill has no tap behavior and
                                            // its flanks are transparent — let
                                            // hits fall through to the messages
                                            // it floats over while pinned.
                                            child: IgnorePointer(
                                              child: Padding(
                                                padding: const EdgeInsets
                                                    .symmetric(vertical: 16.0),
                                                child: DateSeparator(
                                                    date: group.day),
                                              ),
                                            ),
                                          ),
                                          SliverToBoxAdapter(
                                            child: Column(
                                                children: group.children),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                          // Top fade gradient
                          
                          // Floating chips — jump-to-bottom only; key / attach
                          // collapsed into the input bar, settings on the
                          // browser address-bar gear.
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: FloatingChipsRow(
                              showScrollToBottom: _showScrollToBottom,
                              onScrollToBottom: _instantScrollToBottom,
                            ),
                          ),
                          // Floating top indicator while a scroll-up page
                          // loads — overlaid, not in the scroll flow, so it
                          // never disturbs the prepend anchor math.
                          if (_loadingOlder)
                            const Positioned(
                              top: 12,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: PhigitalLoadingWidget(
                                    size: 20, showShadows: true),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Input bar — just text field + send icon. Wrapped so any
                    // growth of the input area (attach-options row, reply
                    // preview, attachment preview) re-pins the conversation to
                    // the bottom when the user is near it — same behavior as the
                    // keyboard, but driven by a widget-tree size change instead
                    // of a window-metrics change (didChangeMetrics never fires
                    // for an in-tree layout change). SizeChangedLayoutNotifier
                    // fires every frame the input's height changes, so the
                    // AnimatedSize reveal is tracked smoothly. Gated on
                    // !_showScrollToBottom: scrolled into history → left alone.
                    NotificationListener<SizeChangedLayoutNotification>(
                      onNotification: (_) {
                        if (!_showScrollToBottom) {
                          _instantScrollToBottom(); // jumps post-frame
                        }
                        return false;
                      },
                      child: SizeChangedLayoutNotifier(
                        child: MessageInput(
                          key: _inputKey,
                          contact: _selectedChatContact,
                          targetInboxId: widget.inboxId,
                          conversationTopic: _currentTopic,
                          replyToMessage: _replyToMessage,
                          onClearReply: _clearReply,
                          onConversationCreated: _handleConversationCreated,
                          onActiveKeyChanged: widget.onActiveKeyChanged,
                          initialDraft: widget.messageDraft,
                        ),
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ChatAppearance.instance.removeListener(_onAppearanceChanged);
    PublicOSConversations.activeConversationTopic = null;
    _messageSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // DELTA(desktop): live restyle for the chat-appearance dialog.
  void _onAppearanceChanged() {
    if (mounted) _buildMessageList();
  }
}

/// One calendar day of the conversation: [day] renders as the pinned
/// DateSeparator header, [children] as the day's message widgets.
class _DayGroup {
  final DateTime day;
  final List<Widget> children = [];
  _DayGroup(this.day);
}
