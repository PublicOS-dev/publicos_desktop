import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// Self-contained debug view that replaces the chat screen.
/// Shows every message (including reactions, read receipts, group_updated)
/// as dense expandable rows with raw metadata.
/// Designed for easy removal — zero coupling to message rendering logic.
class DebugChatView extends StatelessWidget {
  final String topic;
  final String myInboxId;
  final VoidCallback onClose;

  const DebugChatView({
    super.key,
    required this.topic,
    required this.myInboxId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return _DebugChatViewBody(
      topic: topic,
      myInboxId: myInboxId,
      onClose: onClose,
    );
  }
}

class _DebugChatViewBody extends StatefulWidget {
  final String topic;
  final String myInboxId;
  final VoidCallback onClose;

  const _DebugChatViewBody({
    required this.topic,
    required this.myInboxId,
    required this.onClose,
  });

  @override
  State<_DebugChatViewBody> createState() => _DebugChatViewBodyState();
}

class _DebugChatViewBodyState extends State<_DebugChatViewBody> {
  List<Message> _allMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final messages = await PublicOSConversations.getLocalMessagesByTopic(
      widget.topic,
      500,
      true,
    );
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (mounted) setState(() { _allMessages = messages; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // SizedBox(height: MediaQuery.of(context).padding.top),
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade900,
            border: Border(bottom: BorderSide(color: Colors.orange.shade700)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DEBUG  ·  ${_allMessages.length} messages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),

        // Topic info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: theme.colorScheme.surfaceContainerHighest,
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.topic));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.debugChatViewTopicCopied), duration: const Duration(seconds: 1)),
              );
            },
            child: Text(
              'topic: ${widget.topic}',
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Message list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _allMessages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _allMessages.length) {
                      return const SizedBox(height: 40);
                    }
                    return _DebugMessageRow(
                      message: _allMessages[index],
                      myInboxId: widget.myInboxId,
                      index: index,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DebugMessageRow extends StatefulWidget {
  final Message message;
  final String myInboxId;
  final int index;

  const _DebugMessageRow({
    required this.message,
    required this.myInboxId,
    required this.index,
  });

  @override
  State<_DebugMessageRow> createState() => _DebugMessageRowState();
}

class _DebugMessageRowState extends State<_DebugMessageRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isMe = msg.senderInboxId == widget.myInboxId;
    final type = msg.content.type.name;
    final hint = _getHint(msg);
    final typeColor = _typeColor(msg.content.type);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        onLongPress: () {
          final data = _buildFullDump(msg);
          Clipboard.setData(ClipboardData(text: data));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.debugChatViewMessageDataCopied), duration: const Duration(seconds: 1)),
          );
        },
        child: Container(
          margin: EdgeInsets.only(
            left: isMe ? 48 : 4,
            right: isMe ? 4 : 48,
            top: 2,
            bottom: 2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.blue.shade900.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isMe
                  ? Colors.blue.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Collapsed: type badge + hint + expand arrow
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Index
                  Text(
                    '#${widget.index}',
                    style: TextStyle(
                      fontSize: 9,
                      fontFamily: 'monospace',
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Sender short id
                  Text(
                    _shortId(msg.senderInboxId),
                    style: TextStyle(
                      fontSize: 9,
                      fontFamily: 'monospace',
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Status flags
                  if (msg.isPending) _flag('P', Colors.orange),
                  if (msg.sendFailed) _flag('F', Colors.red),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
              // Content hint
              if (hint.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    hint,
                    maxLines: _expanded ? 50 : 1,
                    overflow: _expanded ? TextOverflow.clip : TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, height: 1.3),
                  ),
                ),
              // Expanded details
              if (_expanded) ...[
                const Divider(height: 8),
                _detail('xmtpId', msg.idXmtp),
                _detail('localId', '${msg.id}'),
                _detail('senderInboxId', msg.senderInboxId),
                _detail('senderAddr', msg.senderAddress),
                _detail('timestamp', msg.timestamp.toIso8601String()),
                _detail('typeId', msg.content.typeId),
                _detail('authorityId', msg.content.authorityId),
                _detail('refMsgId', msg.referenceMessageId),
                _detail('isPending', '${msg.isPending}'),
                _detail('sendFailed', '${msg.sendFailed}'),
                _detail('encodedLen', '${msg.encodedContent?.length ?? 'null'}'),
                _detail('reactions', '${msg.reactions?.length ?? 0}'),
                if (msg.parameters != null && msg.parameters!.isNotEmpty)
                  _detail('params', '${msg.parameters}'),
                const SizedBox(height: 4),
                // Raw content value
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'value: ${_valueToString(msg.content.value)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _flag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _detail(String label, String? value) {
    if (value == null || value.isEmpty || value == 'null') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  String _shortId(String? id) {
    if (id == null || id.length < 8) return id ?? '?';
    return '${id.substring(0, 4)}..${id.substring(id.length - 4)}';
  }

  String _getHint(Message msg) {
    try {
      return _hintForType(msg);
    } catch (e) {
      // This is a debug inspector for (often malformed) messages — one weird
      // payload must never take down the whole list with a red error screen.
      return '⚠ hint error: $e';
    }
  }

  String _hintForType(Message msg) {
    switch (msg.content.type) {
      case MessageType.text:
        return msg.body ?? msg.content.value?.toString() ?? '';
      case MessageType.reaction:
        if (msg.content.value is Reaction) {
          final r = msg.content.value as Reaction;
          return '${r.content} → ${_shortId(r.reference)}';
        }
        return msg.content.value?.toString() ?? '';
      case MessageType.reply:
        if (msg.content.value is Reply) {
          final r = msg.content.value as Reply;
          // r.content is the decoded nested content: a plain String for a text
          // reply, a Reaction/Attachment/etc. otherwise. It does NOT have a
          // `.value` getter — assuming it did crashed the whole list on the
          // first reply ("String has no instance getter 'value'").
          if (r.content == null) return '↩ (empty reply)';
          return '↩ ${_valueToString(r.content)}';
        }
        return msg.content.value?.toString() ?? '';
      case MessageType.attachment:
        return '[attachment]';
      case MessageType.remoteAttachment:
        return '[remote attachment]';
      case MessageType.multiRemoteAttachment:
        final v = msg.content.value;
        return v is MultiRemoteAttachmentContent
            ? '[${v.attachments.length} remote attachments]'
            : '[multi attachment]';
      case MessageType.readReceipt:
        return '[read receipt]';
      case MessageType.group_updated:
        return '[group updated]';
    }
  }

  String _valueToString(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return value;
    if (value is Reaction) return 'Reaction(content: ${value.content}, ref: ${value.reference}, action: ${value.action})';
    if (value is Reply) return 'Reply(ref: ${value.reference}, content: ${value.content})';
    if (value is GroupUpdated) return 'GroupUpdated(${value.toString()})';
    if (value is AttachmentContent) {
      return 'AttachmentContent(filename: ${value.filename}, mimeType: ${value.mimeType}, '
          'isSticker: ${value.isSticker}, description: ${value.description ?? '(none)'}, '
          'bytes: ${value.data.length})';
    }
    return value.toString();
  }

  Color _typeColor(MessageType type) {
    switch (type) {
      case MessageType.text:
        return Colors.blue;
      case MessageType.reaction:
        return Colors.amber;
      case MessageType.reply:
        return Colors.purple;
      case MessageType.attachment:
      case MessageType.remoteAttachment:
      case MessageType.multiRemoteAttachment:
        return Colors.teal;
      case MessageType.readReceipt:
        return Colors.grey;
      case MessageType.group_updated:
        return Colors.orange;
    }
  }

  String _buildFullDump(Message msg) {
    return '''
id: ${msg.id}
xmtpId: ${msg.idXmtp}
topic: ${msg.xmtpConversationTopic}
senderInboxId: ${msg.senderInboxId}
senderAddress: ${msg.senderAddress}
timestamp: ${msg.timestamp.toIso8601String()}
type: ${msg.content.type.name}
typeId: ${msg.content.typeId}
authorityId: ${msg.content.authorityId}
isPending: ${msg.isPending}
sendFailed: ${msg.sendFailed}
refMsgId: ${msg.referenceMessageId}
encodedLen: ${msg.encodedContent?.length}
body: ${msg.body}
value: ${_valueToString(msg.content.value)}
''';
  }
}
