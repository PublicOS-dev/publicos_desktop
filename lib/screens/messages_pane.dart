import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/screens/messages_view.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/chat_settings_dialog.dart';
import 'package:publicos_desktop/widgets/browser.dart';
import 'package:publicos_desktop/widgets/browser/tab_deck.dart'
    show DeckSelectionMemory;
import 'package:publicos_desktop/widgets/contact_settings_dialog.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_label.dart';
import 'package:publicos_desktop/widgets/shell_split.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// The Messages door (nav index 2): dual-pane — the ported client
/// `MessagesView` (conversation list, requests chips, menu actions) on the
/// left, the shared [Browser] on the right, landing on Chat.
///
/// The ported list routes conversation opens through `AppNav.toConversation` /
/// `AppNav.toInbox` (the client's own shim — zero body edits); this pane
/// registers those handlers while mounted and resolves them with the
/// browser's recipe (group stub by topic first, else conversation →
/// peer-inbox contact).
class MessagesPane extends StatefulWidget {
  /// The list card's width — public so the shell can morph into it.
  static const double listWidth = 380;

  const MessagesPane({super.key});

  @override
  State<MessagesPane> createState() => _MessagesPaneState();
}

class _MessagesPaneState extends State<MessagesPane> {

  /// Where the Browser deck's selection slab last rested. Held here because
  /// the Browser remounts per contact and this pane does not: contact →
  /// contact slides the slab from it; a fresh pane (arrived from another rail
  /// screen) starts without one and the slab enters from the left.
  final DeckSelectionMemory _deckMemory = DeckSelectionMemory();

  Contact? _selected;
  String? _selectedInboxId;
  String? _selectedTopic;

  /// Chain-sync state for the panel's Profile tab — the contacts_pane
  /// pattern: local copy stays on screen, generation counter strands stale
  /// reads (a Future can't be cancelled; the generation IS the cancellation).
  bool _syncing = false;
  int _selectGen = 0;

  /// Bumped on an active-XMTP-key switch → remounts the conversation list
  /// (full reload; the panel's chat remounts itself via its ValueKey).
  int _listEpoch = 0;

  /// The browser's content-width caps — the same settings the Contacts door
  /// reads, applied by the panel per tab group.
  BrowserWidths _widths = const BrowserWidths.defaults();

  @override
  void initState() {
    super.initState();
    AppNav.onOpenConversationTopic = _openByTopic;
    AppNav.onOpenInbox = _openByInbox;
    _loadWidthSetting();
  }

  @override
  void dispose() {
    // Only clear our own registration — a successor pane may already have
    // re-registered by the time this dispose runs.
    if (AppNav.onOpenConversationTopic == _openByTopic) {
      AppNav.onOpenConversationTopic = null;
    }
    if (AppNav.onOpenInbox == _openByInbox) {
      AppNav.onOpenInbox = null;
    }
    super.dispose();
  }

  /// All three browser width groups.
  ///
  /// ⚠ This door READS the widths but has no way to change them: the Settings
  /// dialog is fired from the contacts-list footer, and Messages has no
  /// footer.
  Future<void> _loadWidthSetting() async {
    final widths = await BrowserWidths.load();
    if (!mounted) return;
    setState(() => _widths = widths);
  }

  // ── Conversation opens (the browser's recipe) ─────────────────────────────

  void _openByInbox(String inboxId) async {
    final contact = await PublicOSContacts.findContactByInboxId(inboxId);
    if (!mounted || contact == null) return;
    _selectGen++;
    setState(() {
      _selected = contact;
      _selectedInboxId = inboxId;
      _selectedTopic = null;
      _syncing = false;
    });
  }

  Future<void> _openByTopic(String topic) async {
    // Group stub first (topic-keyed Contact); on miss, resolve the
    // conversation locally and fall back to the peer-inbox-id contact —
    // verbatim recipe from browser.dart's xmtpConversationTopic branch.
    Contact? contact = await PublicOSContacts.findContactByTopic(topic);
    String? inboxId;
    if (contact == null) {
      final conv = await PublicOSConversations.getConversation(topic);
      if (conv != null &&
          conv.type != ConversationType.group &&
          conv.peerInboxId != null) {
        contact =
            await PublicOSContacts.findContactByInboxId(conv.peerInboxId!);
        inboxId = conv.peerInboxId;
      }
    }
    if (!mounted || contact == null) return;
    _selectGen++;
    setState(() {
      _selected = contact;
      _selectedInboxId = inboxId;
      _selectedTopic = topic;
      _syncing = false;
    });
  }

  /// Panel identity — a new conversation selection remounts the panel (the
  /// contacts_pane keyed-panel pattern).
  String get _panelKey =>
      _selectedTopic ??
      _selectedInboxId ??
      _selected?.publicosAddress?.eip55With0x ??
      '';

  // ── Chain sync for the Profile tab ────────────────────────────────────────

  Future<void> _syncSelectedFromChain() async {
    final addr = _selected?.publicosAddress;
    if (addr == null) return; // XMTP-only / group: nothing on chain.
    final g = ++_selectGen;
    if (mounted) setState(() => _syncing = true);
    try {
      final fetched = await PublicOSContacts.fetchContact(addr);
      if (!mounted || g != _selectGen) return;
      // The "Joined" row: keep the date we already hold on screen, and let
      // the chain read replace it only if it comes back different.
      final fresh = await _withCreatedAt(
        fetched.copyWith(createdAt: _selected?.createdAt),
      );
      if (!mounted || g != _selectGen) return;
      // Stored, as contacts_pane does: without this a profile only ever
      // opened from Messages never kept its date and showed blank each visit.
      await PublicOSContacts.saveContact(fresh);
      if (!mounted || g != _selectGen) return;
      setState(() => _selected = fresh);
    } catch (_) {
      // Local copy stays on screen (client parity — no blocking loader).
    } finally {
      if (mounted && g == _selectGen) setState(() => _syncing = false);
    }
  }

  /// Port of publicos_client `browser.dart` `_withCreatedAt`: returns [c] with
  /// `Contact.createdAt` read from chain. The stored value is what the profile
  /// shows while this runs; it is replaced only when the chain answers with a
  /// different date. Pure: no setState, no save. A failed or empty read
  /// returns [c] unchanged.
  Future<Contact> _withCreatedAt(Contact c) async {
    final addr = c.publicosAddress;
    if (addr == null) return c;
    try {
      final created = await PublicOSAccounts.getAccountCreatedAt(
        addr,
        isOrg: c.isOrgAccount,
      );
      if (created == null) return c;
      final held = c.createdAt;
      if (held != null && held.isAtSameMomentAs(created)) return c;
      return c.copyWith(createdAt: created);
    } catch (_) {
      return c;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // Two floating shell panels.
    return ShellSplit(
      listWidth: MessagesPane.listWidth,
      list: Column(
        children: [
          Expanded(
            child: MessagesView(
              key: ValueKey('messages-list:$_listEpoch'),
              selectedTopic: _selectedTopic,
              selectedInboxId: _selectedInboxId,
            ),
          ),
          // Footer: Chat settings (desktop-only) — the Contacts
          // pane's Contact-settings row, twinned: appearance overrides +
          // the message chime. The dialog floats over the pane so picking
          // a swatch restyles the visible chat live.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: tokens.borderSubtle, height: 1),
          ),
          _chatSettingsRow(tokens),
          const SizedBox(height: 8),
        ],
      ),
      content: _detail(tokens),
    );
  }

  Widget _chatSettingsRow(GlassTokens tokens) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showChatSettingsDialog(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 17, color: tokens.textDim),
              const SizedBox(width: 12),
              Text(
                context.l10n.desktopChatSettings,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(GlassTokens tokens) {
    final c = _selected;
    if (c == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 56, color: tokens.textDim),
            const SizedBox(height: 14),
            Text(
              context.l10n.desktopSelectConversationTitle,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.desktopSelectConversationHint,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Browser(
            key: ValueKey('panel:$_panelKey'),
            contact: c,
            door: BrowserDoor.messages,
            initialInboxId: _selectedInboxId,
            topic: _selectedTopic,
            widths: _widths,
            onRefresh: _syncSelectedFromChain,
            onOpenContact: (contact) => AppNav.toContact(context, contact),
            onActiveKeyChanged: () => setState(() => _listEpoch++),
            deckMemory: _deckMemory,
          ),
        ),
        // Same affordance, same event, same widget as the Contacts pane's
        // profile sync. Placement lives inside the widget.
        if (_syncing) const PixelRainLoadingCorner(),
      ],
    );
  }
}
