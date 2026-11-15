import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/conversation_row.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Sheet listing conversations in `denied` consent state — the user's
/// blocked DMs and groups. Tapping a row routes into chat via
/// `AppNav.toContact(..., tab: BrowserTab.chat)` so the user can accept
/// (restore) the conversation there; the active `consentState` flips on
/// acceptance and the conversation disappears from this list on the next
/// open.
class DeniedConversationsSheet extends StatefulWidget {
  const DeniedConversationsSheet({super.key});

  @override
  State<DeniedConversationsSheet> createState() =>
      _DeniedConversationsSheetState();
}

class _DeniedConversationsSheetState extends State<DeniedConversationsSheet> {
  List<_ConversationData> _entries = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final conversations = await PublicOSConversations.getConversations(
        consentState: 'denied',
      );
      final resolved = await Future.wait(conversations.map(_stitch));
      resolved.sort(
        (a, b) => b.lastMessage.timestamp.compareTo(a.lastMessage.timestamp),
      );
      if (!mounted) return;
      setState(() {
        _entries = resolved;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entries = const [];
        _loading = false;
      });
    }
  }

  /// Resolve peer contact + last displayable message for one conversation.
  /// Client's existing fallbacks preserved: DM → `findContactInfoOnly`,
  /// group → `Contact.stub(displayName: conv.displayName)`, empty history
  /// → synthetic "No messages yet" placeholder so `ConversationRow` has
  /// something to render.
  Future<_ConversationData> _stitch(XmtpConversation conv) async {
    Contact? contact;
    if (conv.isDm && conv.peerInboxId != null) {
      contact = await PublicOSContacts.findContactInfoOnly(conv.peerInboxId!);
    }
    contact ??= Contact.stub(displayName: conv.displayName);

    final messages = await PublicOSConversations.getLocalMessagesByTopic(
      conv.topic,
      20,
      true,
    );
    final displayable = messages
        .where((m) =>
            m.content.type != MessageType.reaction &&
            m.content.type != MessageType.reply &&
            m.content.type != MessageType.readReceipt)
        .toList();

    final Message lastMessage;
    if (displayable.isNotEmpty) {
      lastMessage = displayable.first;
    } else {
      lastMessage = Message(
        id: 0,
        xmtpConversationTopic: conv.topic,
        timestamp: conv.createdAt ?? DateTime.now(),
        content: const MessageContent(
          type: MessageType.text,
          value: 'No messages yet',
        ),
        senderAddress: contact.mainSession?.address.eip55With0x ?? '',
        isPending: false,
        sendFailed: false,
      );
    }
    return _ConversationData(contact, conv, lastMessage);
  }

  void _handleTap(_ConversationData data) {
    // DELTA(desktop): the client routes into the browser's chat tab
    // (`AppNav.toContact(…, tab: BrowserTab.chat)`); desktop routes the
    // conversation topic through the Messages pane's handler — same landing
    // (the panel on Chat). Pop the dialog first so the panel is visible.
    Navigator.pop(context);
    AppNav.toConversation(context, data.conversation.topic);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // DELTA(desktop): the DraggableScrollableSheet shell (+ drag handle, top
    // radius) becomes a plain glass container — the presenting dialog owns
    // sizing; nothing drags on desktop. Column children verbatim below.
    return Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                _Header(
                  tokens: tokens,
                  onClose: () => Navigator.pop(context),
                ),
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: tokens.starkWhite,
                            strokeWidth: 2,
                          ),
                        )
                      : _entries.isEmpty
                          ? _Empty(tokens: tokens)
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: tokens.starkWhite,
                              backgroundColor: tokens.surfaceElevated,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                itemCount: _entries.length,
                                itemBuilder: (_, i) {
                                  final e = _entries[i];
                                  return ConversationRow(
                                    contact: e.contact,
                                    conversation: e.conversation,
                                    lastMessage: e.lastMessage,
                                    onTap: () => _handleTap(e),
                                    iconSize: 48,
                                    isNew: false,
                                    showBanner: false,
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        );
  }
}

class _ConversationData {
  final Contact contact;
  final XmtpConversation conversation;
  final Message lastMessage;

  _ConversationData(this.contact, this.conversation, this.lastMessage);
}

class _Header extends StatelessWidget {
  final GlassTokens tokens;
  final VoidCallback onClose;
  const _Header({required this.tokens, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Blocked conversations',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Open a conversation to restore it.',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final GlassTokens tokens;
  const _Empty({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: tokens.connectedAccent,
            ),
            const SizedBox(height: 14),
            Text(
              'Nothing is blocked',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Conversations you block show up here so you can restore them later.',
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
}
