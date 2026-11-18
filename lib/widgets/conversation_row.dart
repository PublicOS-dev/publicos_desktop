import 'package:flutter/material.dart';
import 'contact_banner.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/selection_pill.dart';

/// Conversation row in the messages list. Glass-themed.
///
/// `showBanner` gates the contact's banner image as a 12%-opacity full-bleed
/// background. Default true (preserves existing UX). Toggle persisted by the
/// Messages settings sheet under `messages_show_contact_banner`.
class ConversationRow extends StatefulWidget {
  final Contact contact;
  final XmtpConversation? conversation;
  final Message lastMessage;
  final VoidCallback? onTap;
  final double iconSize;
  final bool isNew;
  final String? heroTag;
  final int unreadCount;
  final bool showBanner;
  final bool selected;

  const ConversationRow({
    super.key,
    required this.contact,
    this.conversation,
    required this.lastMessage,
    this.onTap,
    this.iconSize = 56,
    this.isNew = false,
    this.heroTag,
    this.unreadCount = 0,
    this.showBanner = true,
    this.selected = false,
  });

  @override
  State<ConversationRow> createState() => _ConversationRowState();
}

class _ConversationRowState extends State<ConversationRow> {
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else {
      return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
    }
  }

  String _getLastMessagePreview() {
    switch (widget.lastMessage.content.type) {
      case MessageType.attachment:
        final content = widget.lastMessage.content.value;
        if (content is AttachmentContent) {
          if (content.mimeType.startsWith('image/')) {
            return '📷 Sent an image';
          } else {
            return '📎 Sent an attachment: ${content.filename}';
          }
        }
        return '📎 Sent an attachment';

      case MessageType.remoteAttachment:
        final content = widget.lastMessage.content.value;
        if (content is RemoteAttachmentContent) {
          return '📷 Sent an image: ${content.filename}';
        }
        return '📎 Sent an attachment';

      case MessageType.multiRemoteAttachment:
        final content = widget.lastMessage.content.value;
        if (content is MultiRemoteAttachmentContent) {
          final n = content.attachments.length;
          final caption = content.description ?? '';
          return caption.isNotEmpty
              ? '📷 ${_truncateMessage(caption)}'
              : '📷 Sent $n photo${n == 1 ? '' : 's'}';
        }
        return '📎 Sent attachments';

      case MessageType.text:
        if (widget.lastMessage.content.value == null) {
          return '';
        }
        if (widget.lastMessage.content.value is ActionsContent) {
          return _truncateMessage(
            (widget.lastMessage.content.value as ActionsContent)
                    .description
                    .isNotEmpty
                ? (widget.lastMessage.content.value as ActionsContent)
                      .description
                : 'Menu',
          );
        }
        if (widget.lastMessage.content.value is IntentContent) {
          final intent = widget.lastMessage.content.value as IntentContent;
          return _truncateMessage(
            'Tapped: ${intent.metadata?['actionLabel'] as String? ?? intent.actionId}',
          );
        }
        if (widget.lastMessage.content.value is TransactionReference) {
          return 'Transaction receipt';
        }
        if (widget.lastMessage.content.value is WalletSendCalls) {
          return 'Transaction request';
        }
        return _truncateMessage(widget.lastMessage.content.value.toString());

      case MessageType.group_updated:
        // No per-member contact cache here, so previews stay name-less and
        // count-based. The in-chat timeline (GroupEventLine) shows full names.
        final gu = widget.lastMessage.content.value;
        if (gu is GroupUpdated) {
          if (gu.addedInboxes.isNotEmpty) {
            return gu.addedInboxes.length == 1
                ? 'A member joined'
                : '${gu.addedInboxes.length} members joined';
          }
          if (gu.removedInboxes.isNotEmpty) {
            return gu.removedInboxes.length == 1
                ? 'A member left'
                : '${gu.removedInboxes.length} members left';
          }
          if (gu.metadataFieldChanges.isNotEmpty) {
            switch (gu.metadataFieldChanges.first.fieldName) {
              case 'group_name':
                return 'Conversation renamed';
              case 'group_image_url_square':
                return 'Conversation photo changed';
              case 'description':
                return 'Description changed';
            }
          }
        }
        return 'Conversation updated';

      default:
        return 'Message';
    }
  }

  String _truncateMessage(String message) {
    return message.length <= 30 ? message : '${message.substring(0, 27)}...';
  }

  /// Inbox ID label for the conversation's peer ("main", "work", ...) — DM only.
  String? _getInboxIdLabel() {
    final peerInboxId = widget.conversation?.peerInboxId;
    if (peerInboxId == null || widget.contact.registeredInboxIDs == null) {
      return null;
    }
    return widget.contact.labelForInboxId(peerInboxId);
  }

  String _getDisplayNameWithLabel() {
    final displayName =
        widget.contact.publicosDisplayName ?? widget.contact.displayName;

    if (widget.contact.publicosDisplayName != null) {
      final label = _getInboxIdLabel();
      if (label != null && label.isNotEmpty) {
        return '$displayName/$label';
      }
    }

    return displayName;
  }

  Widget _buildPreviewText(GlassTokens tokens) {
    if (widget.isNew) {
      return Text(
        widget.contact.mainSession?.address.eip55With0x ?? '',
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.textDim,
          fontSize: 13,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }

    final topic = widget.conversation?.topic;
    if (topic != null && PublicOSConversations.hasDraft(topic)) {
      final draft = PublicOSConversations.getDraft(topic)!;
      final truncated = draft.length <= 30
          ? draft
          : '${draft.substring(0, 27)}...';
      return Row(
        children: [
          Text(
            'Draft: ',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.connectedAccent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              truncated,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    }

    return Text(
      _getLastMessagePreview(),
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: tokens.textDim,
        fontSize: 13,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _buildStatusIndicator(GlassTokens tokens) {
    if (widget.lastMessage.isPending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: tokens.textDim,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'sending...',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim.withValues(alpha: 0.7),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    if (widget.isNew) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: tokens.connectedAccent.withValues(alpha: 0.12),
          border: Border.all(
            color: tokens.connectedAccent.withValues(alpha: 0.4),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'New Contact',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.connectedAccent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Text(
      _formatTime(widget.lastMessage.timestamp),
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: tokens.textDim,
        fontSize: 11,
      ),
    );
  }

  /// Unread count: a monochrome rounded square on the preview line, bottom
  /// right, so the time keeps the top-right corner on every row. 16px tall,
  /// under the preview's line height, so an unread row is no taller.
  Widget _buildUnreadBadge(GlassTokens tokens) {
    return Container(
      height: 16,
      constraints: const BoxConstraints(minWidth: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.starkWhite,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        widget.unreadCount > 99 ? '99+' : '${widget.unreadCount}',
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.background,
          fontSize: 10,
          height: 1.0,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return SelectionPill(
      selected: widget.selected,
      child: Material(
        color: widget.selected ? tokens.glassFill : Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Stack(
            children: [
              if (widget.showBanner)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.12,
                    child: ClipRect(
                      child: ContactBanner(
                        contact: widget.contact,
                        fallback: const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: widget.iconSize + 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GlassContactIcon(
                        contact: widget.contact,
                        size: widget.iconSize,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _getDisplayNameWithLabel(),
                                    style: TextStyle(
                                      fontFamily: 'SpaceGrotesk',
                                      fontWeight: widget.unreadCount > 0
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      fontSize: 15,
                                      color: tokens.starkWhite,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildStatusIndicator(tokens),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(child: _buildPreviewText(tokens)),
                                if (widget.unreadCount > 0) ...[
                                  const SizedBox(width: 8),
                                  _buildUnreadBadge(tokens),
                                ],
                              ],
                            ),
                            if (widget.isNew &&
                                widget.contact.publicosDisplayName != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: tokens.connectedAccent.withValues(
                                    alpha: 0.12,
                                  ),
                                  border: Border.all(
                                    color: tokens.connectedAccent.withValues(
                                      alpha: 0.4,
                                    ),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'OSUX Contact',
                                  style: TextStyle(
                                    fontFamily: 'SpaceGrotesk',
                                    color: tokens.connectedAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
    );
  }
}
