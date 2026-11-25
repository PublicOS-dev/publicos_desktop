import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:publicos_desktop/widgets/hover_grow.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

import 'package:publicos_desktop/widgets/browser/signature_request_sheet.dart';
import 'package:publicos_desktop/widgets/feeds/emoji_picker_dialog.dart';
import 'package:publicos_desktop/widgets/chain_icon.dart';
import 'package:publicos_desktop/widgets/crypto_icon.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/sticker_icon.dart';
import 'package:publicos_desktop/widgets/transactions/send_sheet.dart';
import 'package:publicos_desktop/data/chain_registry.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/media_mime.dart';
import 'package:publicos_desktop/utils/doc_types.dart';
import 'package:publicos_desktop/utils/open_file.dart';
import 'package:publicos_desktop/utils/save_file.dart';
import 'package:publicos_desktop/widgets/chat_video_bubble.dart';
import 'package:publicos_desktop/widgets/natural_ratio_media.dart';
import 'package:publicos_desktop/widgets/tappable_image.dart';
import 'package:publicos_desktop/widgets/tappable_media.dart';
import 'package:publicos_desktop/widgets/shimmer_box.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/chat_appearance.dart';
import 'link_preview_widget.dart';
import 'reaction_details_sheet.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

/// Default char budget for the "trim long messages" reading setting. A bubble's
/// text past this collapses behind an inline "Show more". Persisted (as an int,
/// `0` = off) under `messages_trim_chars`; read once per chat by chat_screen and
/// passed down as [MessageWidget.trimMaxChars].
const int kMessageTrimMaxChars = 280;

/// Where to cut [text] under a [budget] of chars, or null when it isn't
/// trimmable (no budget, or the text already fits).
///
/// A cut landing inside a URL backs up to that URL's start, so half a link is
/// never rendered as a tappable (and wrong) one. If that leaves nothing to show
/// — a lone over-budget URL — the text isn't trimmable at all.
int? messageTrimCut(String text, int? budget) {
  if (budget == null || budget <= 0) return null;
  if (text.length <= budget) return null;
  int cut = budget;
  for (final m in LinkPreviewUtils.urlRegex.allMatches(text)) {
    if (m.start >= cut) break;
    if (m.end > cut) {
      cut = m.start;
      break;
    }
  }
  return cut > 0 ? cut : null;
}

class MessageWidget extends StatefulWidget {
  final Message message;
  final Message? previousMessage; // For grouping
  final Message? nextMessage; // For grouping
  final String? myInboxId;
  final Contact? senderContact;
  final bool isGroupChat;
  final String? peerInboxId; // Peer's inbox ID for direct message reactions
  final Function(Message)? onReplySelected; // Callback when user selects to reply
  final bool showSeenIndicator; // Show "seen" indicator for read receipts
  final Contact? peerContact; // Peer contact for seen indicator avatar
  final Contact? Function(String inboxId)? contactLookup; // Lookup contact from chat screen's cache
  final void Function(dynamic content, String authorityId, String typeId)? onSendTextMessage; // Send a message (for interactive actions)
  // Aspect-ratio cache for ChatVideoBubble, owned by _SimpleChatScreenState
  // so lookups are shared across bubbles in the same conversation. Dies on
  // conversation leave. Null in non-chat callers — they fall back to the
  // old NaturalRatioMedia path (which probes via VideoPlayerController).
  final Map<String, double>? videoAspectCache;

  // When true, this widget is one cell of a horizontal sticker stack: it
  // shrink-wraps to its sticker so siblings fit on the same row. The stack's
  // single timestamp is rendered by the parent (chat_screen), not the cell.
  final bool inStack;

  // Whether this message shows its own timestamp. Decided centrally by
  // chat_screen's grouping pass — the widget does not compute it itself.
  final bool showTimestamp;

  // "Trim long messages" reading setting, shared across every chat. Text in a
  // bubble (message body, attachment caption, reply body) longer than this many
  // chars renders cut with an inline "Show more". Null/<=0 = never trim.
  final int? trimMaxChars;
  /// The chat's bookmarked message ids (network `idXmtp`s), shared by every
  /// bubble and mutated in place by a toggle. Null = bookmarks unavailable.
  final Set<String>? bookmarkIds;
  /// Called after a toggle mutated [bookmarkIds], so the chat persists it.
  final VoidCallback? onBookmarksChanged;

  const MessageWidget({
    Key? key,
    required this.message,
    this.previousMessage, // For grouping
    this.nextMessage, // For grouping
    required this.myInboxId,
    this.senderContact,
    required this.isGroupChat,
    this.peerInboxId, // Peer's inbox ID for direct message reactions
    this.onReplySelected, // Callback for reply selection
    this.showSeenIndicator = false, // Default to not show
    this.peerContact, // Peer contact for avatar
    this.contactLookup, // Lookup from chat screen's contact cache
    this.onSendTextMessage,
    this.videoAspectCache,
    this.inStack = false,
    this.showTimestamp = true,
    this.trimMaxChars,
    this.bookmarkIds,
    this.onBookmarksChanged,
  }) : super(key: key);

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  // Cache commonly computed values
  late final bool isMe;
  late final EdgeInsets marginInsets;
  late final BorderRadius bubbleBorderRadius;
  late final bool _showAvatarAndName; // Cache for avatar/name visibility
  late final bool _showTimestamp; // Cache for timestamp visibility

  // Cache futures to prevent rebuilds
  Future<Message?>? _referencedMessageFuture;
  Future<AttachmentContent>? _remoteAttachmentFuture;
  // One load per gallery item (multi-attachment), keyed by contentDigest.
  final Map<String, Future<AttachmentContent>> _galleryFutures = {};

  // True while a remote document is being fetched+decrypted for "open with"
  // (tap-to-download on the document chip).
  bool _docDownloading = false;

  // "Show more" state for this bubble's text. One flag per bubble: a message
  // carries a single block of trimmable text (body, caption, or reply body).
  bool _textExpanded = false;

  // Constants
  static const double _bubbleRadius = 12;
  static const double _bubbleRadiusSmall = 4;
  // Bubble padding is split by content kind so each can be tuned in one place.
  // Text (and non-media bubbles) keep the roomy padding that "feels nice"; media
  // attachments get a tight padding so the image isn't swimming in space.
  static const EdgeInsets _textBubblePadding =
      EdgeInsets.symmetric(vertical: 8, horizontal: 8);
  static const EdgeInsets _attachmentBubblePadding = EdgeInsets.all(2);
  static const double _senderIconSize = 28;
  static const Duration _groupingTimeThreshold = Duration(seconds: 60);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _computeLayout();
    _cacheFutures();
    if (widget.showSeenIndicator) {
      _seenPeer = widget.peerContact;
      _ensureSeenCtrl().value = 1; // already seen on first build: no motion
    }
  }

  // -- Seen indicator motion ------------------------------------------------
  // The marker slides in from the bubble's outer edge (avatar leads, label
  // trails) and out in reverse when it moves to a newer message. The two
  // bubbles never talk: the arriving one simply waits out the leaving one's
  // exit (same duration). Controller is lazy: only the bubbles that ever carry
  // the marker pay for one.
  static const Duration _seenDuration = Duration(milliseconds: 300);
  AnimationController? _seenCtrl;
  Timer? _seenEntryTimer;
  // peerContact goes null the moment the marker moves; keep it for the exit.
  Contact? _seenPeer;

  AnimationController _ensureSeenCtrl() => _seenCtrl ??=
      AnimationController(vsync: this, duration: _seenDuration);

  @override
  void didUpdateWidget(covariant MessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.peerContact != null) _seenPeer = widget.peerContact;
    if (widget.showSeenIndicator == oldWidget.showSeenIndicator) return;
    _seenEntryTimer?.cancel();
    final ctrl = _ensureSeenCtrl();
    if (widget.showSeenIndicator) {
      _seenEntryTimer = Timer(_seenDuration, () {
        if (mounted) ctrl.forward();
      });
    } else {
      ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _seenEntryTimer?.cancel();
    _seenCtrl?.dispose();
    super.dispose();
  }

  void _computeLayout() {
    isMe = widget.myInboxId != null && widget.message.senderInboxId != null && widget.message.senderInboxId == widget.myInboxId;

    // Determine if avatar and name should be shown
    _showAvatarAndName = widget.isGroupChat &&
        !isMe &&
        (widget.previousMessage == null || widget.previousMessage!.senderInboxId != widget.message.senderInboxId || widget.message.timestamp.difference(widget.previousMessage!.timestamp) > _groupingTimeThreshold);

    // Timestamp visibility is decided by chat_screen's grouping pass (one source
    // of truth) and passed in; the widget does not compute it from prev/next.
    _showTimestamp = widget.showTimestamp;

    // Adjust margins for grouped messages
    final bool isGroupedWithPrevious =
        widget.previousMessage != null && widget.previousMessage!.senderInboxId == widget.message.senderInboxId && widget.message.timestamp.difference(widget.previousMessage!.timestamp) <= _groupingTimeThreshold;

    final bool isNotGroupedWithPrevious =
        widget.previousMessage == null || widget.previousMessage!.senderInboxId != widget.message.senderInboxId || widget.message.timestamp.difference(widget.previousMessage!.timestamp) > _groupingTimeThreshold;

    // Uniform 2px margins — both ternary branches are 2, so every
    // inter-message gap is a flat 4px (2+2), regardless of grouping. The
    // conditions are kept so grouped/ungrouped gaps can diverge again.
    final double topMargin = isGroupedWithPrevious ? 2 : 2;
    final double bottomMargin = _showTimestamp ? 2 : 2;

    marginInsets = EdgeInsets.only(
      top: topMargin,
      bottom: bottomMargin,
      left: isMe ? 64 : 4,
      right: isMe ? 8 : 64,
    );

    // Adjust bubble radius for grouped messages
    final bool shouldModifyTopCorner = isNotGroupedWithPrevious;

    bubbleBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(isMe
          ? _bubbleRadius
          : (shouldModifyTopCorner ? _bubbleRadiusSmall : _bubbleRadius)),
      topRight: Radius.circular(isMe
          ? (shouldModifyTopCorner ? _bubbleRadiusSmall : _bubbleRadius)
          : _bubbleRadius),
      bottomLeft: const Radius.circular(_bubbleRadius),
      bottomRight: const Radius.circular(_bubbleRadius),
    );
  }

  void _cacheFutures() {
    // Cache referenced message future if needed (local DB fetch — fast)
    if (widget.message.referenceMessageId != null) {
      _referencedMessageFuture = PublicOSConversations.getMessageByXmtpId(widget.message.referenceMessageId);
    }
  }

  /// Per-user brand color (read from the contact's `color` record). Keeping
  /// identity tint in bubbles is a feature — each peer has their own color.
  /// Falls back to a neutral blue/indigo when the contact hasn't set one.
  Color _brandColor(BuildContext context) {
    if (isMe) {
      return Color(int.tryParse(AppStateNotifier.currentMyContact?.getRecordValue('color') ?? '') ?? Colors.blue.shade700.value);
    } else {
      return Color(int.tryParse(widget.senderContact?.getRecordValue("color") ?? '') ?? Colors.indigo.shade700.value);
    }
  }

  /// Relative luminance at which pure white and pure black contrast equally
  /// against a fill — `sqrt(1.05 * 0.05) - 0.05`. Picking the better of the
  /// two on either side of it guarantees **>= 4.5:1 against any fill at all**
  /// (the worst case is a fill sitting exactly here, where both give 4.5).
  ///
  /// This is NOT the same as `computeLuminance() < 0.5 ? white : black`. That
  /// naive midpoint puts white text on amber `#fbbf24` at 2.15:1, and fails 23
  /// of the 46 presets. `Color.computeLuminance()` is already WCAG relative
  /// luminance, so the comparison is direct.
  static const double _fgCrossover = 0.179;

  /// The bubble is painted with the sender's `color` record at **full opacity**
  /// — the bubble is exactly the swatch the
  /// user picked in the Account app, no tint, no surprise. Consequence: every
  /// foreground *inside* the bubble must follow the fill, for peers as well as
  /// for me. Anything drawn on the page background (timestamp, status row,
  /// reaction picker, seen indicator) still uses the fixed light-on-dark colors.
  // DELTA(desktop): the ChatAppearance seam — per-side LOCAL overrides
  // layered over the identity tint; null = the client's behavior verbatim.
  // The auto black/white foreground keeps working because it derives from
  // whatever fill wins.
  Color get _bubbleFill =>
      ChatAppearance.instance.bubbleColorFor(isMe) ?? _brandColor(context);

  Color get _bubbleFg =>
      ChatAppearance.instance.textColorFor(isMe) ??
      (_bubbleFill.computeLuminance() < _fgCrossover
          ? Colors.white
          : Colors.black);

  /// Secondary text / dividers inside the bubble.
  Color get _bubbleFgSub => _bubbleFg.withValues(alpha: 0.7);

  /// Faint surfaces inside the bubble (reply quote, placeholder fills).
  Color get _bubbleFgFaint => _bubbleFg.withValues(alpha: 0.12);


  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatSenderAddress(String address) {
    if (address.length > 10) {
      return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
    }
    return address;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final hasReactions = widget.message.reactions != null && widget.message.reactions!.isNotEmpty;
    // Still mounted while the marker animates out of this bubble.
    final seenVisible = widget.showSeenIndicator ||
        (_seenCtrl != null && !_seenCtrl!.isDismissed);
    // A bookmarked message always gets the bottom row, even mid-group where the
    // time is hidden (then the mark stands alone in the time's place).
    final hasBottomRow = _showTimestamp || seenVisible || _bookmarked;
    // No extra spacer/margin bump for reactions: _withReactionOverlay now
    // wraps the bubble in `Padding(bottom: 20)` so the chip's overhang lives
    // *inside* the bubble Row's reported height. Default 4px spacer between
    // bubble Row and timestamp Row is enough.
    final double spacerBeforeBottom = hasBottomRow ? 4.0 : 0.0;

    return RepaintBoundary(
      child: Container(
        // In a stack we shrink-wrap to the sticker so siblings share the row;
        // the parent Wrap handles sender-side alignment. Otherwise fill width.
        width: widget.inStack ? null : double.infinity,
        margin: marginInsets,
        // color: Colors.purple,
        child: Column(
          mainAxisSize: widget.inStack ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Row containing message bubble and reaction button
            Row(
              mainAxisSize: widget.inStack ? MainAxisSize.min : MainAxisSize.max,
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Flexible only works under a bounded width; a shrink-wrapped
                // stack cell has none, so drop it there.
                widget.inStack
                    ? Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: _buildMessageContent(context, hasReactions),
                      )
                    : Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: _buildMessageContent(context, hasReactions),
                        ),
                      ),
              ],
            ),
            if (hasBottomRow) ...[
              _buildBottomSpacer(spacerBeforeBottom),
              isMe
                  ? Row(
                      // In a stack the cell must shrink-wrap; a full-width
                      // timestamp row would force the cell wide and break the
                      // side-by-side Wrap layout.
                      mainAxisSize:
                          widget.inStack ? MainAxisSize.min : MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_bookmarked) ...[
                          _buildBookmarkMark(),
                          const SizedBox(width: 4),
                        ],
                        if (_showTimestamp) ...[
                          _buildStatus(),
                          _buildTimestamp(),
                        ],
                        if (seenVisible) _buildSeenIndicator(), // carries its own 8px gap
                        const SizedBox(width: 4),
                      ],
                    )
                  : Row(
                      mainAxisSize:
                          widget.inStack ? MainAxisSize.min : MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if(widget.isGroupChat) SizedBox(width: widget.isGroupChat ? 28.0 : 0.0),
                        if (_showTimestamp) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: _buildTimestamp(),
                          ),
                          _buildStatus(),
                        ],
                        if (_bookmarked)
                          Padding(
                            padding: EdgeInsets.only(left: _showTimestamp ? 4.0 : 8.0),
                            child: _buildBookmarkMark(),
                          ),
                      ],
                    ),
            ] else ...[
              // If timestamp is hidden, we still want to show status if needed
              if (widget.message.isPending || widget.message.sendFailed) ...[
                const SizedBox(height: 2),
                isMe
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildStatus(),
                          const SizedBox(width: 8),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: widget.isGroupChat ? 32.0 : 8.0),
                          _buildStatus(),
                        ],
                      ),
              ]
            ]
          ],
        ),
      ),
    );
  }

  /// Wrap [bubble] in a Stack with the reactions chip floating at its outer
  /// bottom corner (right for my messages, left for theirs) when there are
  /// reactions. No reactions → return [bubble] unwrapped so the common path
  /// stays byte-identical to the pre-overlap layout.
  Widget _withReactionOverlay(Widget bubble, bool hasReactions) {
    if (!hasReactions) return bubble;
    // Bubble gets 20px of bottom padding so the Stack's bounding box includes
    // the chip's overhang. Chip is then at Positioned(bottom: 0) — fully in
    // bounds, so its entire area receives taps. Visual position matches the
    // earlier `bottom: -20` + clipBehavior.none version, but without the
    // dead-zone on the chip's lower half (Stack hit-testing is gated by its
    // own bbox; out-of-bounds children paint but don't receive hits).
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: bubble,
        ),
        Positioned(
          bottom: 0,
          right: isMe ? 4 : null,
          left: isMe ? null : 4,
          child: _buildReactionsChip(context),
        ),
      ],
    );
  }

  Widget _buildMessageContent(BuildContext context, bool hasReactions) {
    // Check for image / video attachments to decide whether to skip the bubble.
    // Inline media without a description renders bare (just clipped to the
    // bubble's corner radius); anything with a description, or non-media,
    // keeps the colored bubble so the description has a frame.
    bool isImageAttachment = false;
    bool isVideoAttachment = false;
    bool isSticker = false;
    bool hasDescription = false;

    if (widget.message.content.type == MessageType.attachment) {
      isImageAttachment = _isImageAttachment(widget.message.content.value);
      isVideoAttachment = _isVideoAttachment(widget.message.content.value);
      isSticker = _isStickerAttachment(widget.message.content.value);
      hasDescription = _hasAttachmentDescription(widget.message.content.value);
    } else if (widget.message.content.type == MessageType.remoteAttachment) {
      isImageAttachment = _mightBeImageAttachment(widget.message.content.value);
      isVideoAttachment = _mightBeVideoAttachment(widget.message.content.value);
      hasDescription = _hasRemoteAttachmentDescription(widget.message.content.value);
    } else if (widget.message.content.type == MessageType.multiRemoteAttachment) {
      // A gallery renders bare like a photo; with a caption it takes the bubble.
      final v = widget.message.content.value;
      isImageAttachment = v is MultiRemoteAttachmentContent;
      hasDescription = v is MultiRemoteAttachmentContent &&
          (v.description ?? '').isNotEmpty;
    }

    // Stickers render bare like inline media — and stay bare even WITH a caption.
    final bool isInlineMedia = isImageAttachment || isVideoAttachment || isSticker;

    // Conditionally build sender info
    Widget? senderInfoWidget;
    if (_showAvatarAndName) {
      // Use cached value
      senderInfoWidget = _buildSenderInfo(context);
    }

    // Extra left padding for message content in group chats (not for sender info)
    final double groupChatContentPadding = (widget.isGroupChat && !isMe) ? (Random().nextDouble()*8) + 24.0 : 0.0;

    // Inline media (image or video) WITHOUT description → no colored bubble,
    // just clip the content to the bubble corner radius. Description present →
    // fall through to the bubble path so the description has a frame.
    if (isInlineMedia && !hasDescription) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (senderInfoWidget != null) senderInfoWidget,
          Padding(
            padding: EdgeInsets.only(left: groupChatContentPadding),
            child: GestureDetector(
              onLongPressStart: (details) {
                HapticFeedback.mediumImpact();
                _showReactionPicker(context, details.globalPosition.dy);
              },
              // DELTA(desktop): right-click opens the reaction menu too —
              // long-press kept (client parity), onSecondaryTapDown added
              // (the standing desktop right-click convention).
              onSecondaryTapDown: (details) {
                _showReactionPicker(context, details.globalPosition.dy);
              },
              child: _withReactionOverlay(
                ClipRRect(
                  // Stickers render unclipped so the alpha defines the shape;
                  // photos/videos keep the bubble corner radius.
                  borderRadius:
                      isSticker ? BorderRadius.zero : bubbleBorderRadius,
                  child: _buildContent(context),
                ),
                hasReactions,
              ),
            ),
          ),
        ],
      );
    } else {
      // For text and non-image/described attachments, use the colored bubble.
      // Media attachments take a tighter padding than text — tune the two
      // _*BubblePadding constants independently.
      final EdgeInsets bubblePadding =
          (widget.message.content.type == MessageType.attachment ||
                  widget.message.content.type == MessageType.remoteAttachment ||
                  widget.message.content.type == MessageType.multiRemoteAttachment)
              ? _attachmentBubblePadding
              : _textBubblePadding;
      return Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (senderInfoWidget != null) senderInfoWidget,
          Padding(
            padding: EdgeInsets.only(left: groupChatContentPadding),
            child: GestureDetector(
              onLongPressStart: (details) {
                HapticFeedback.mediumImpact();
                _showReactionPicker(context, details.globalPosition.dy);
              },
              // DELTA(desktop): right-click opens the reaction menu too —
              // long-press kept (client parity), onSecondaryTapDown added
              // (the standing desktop right-click convention).
              onSecondaryTapDown: (details) {
                _showReactionPicker(context, details.globalPosition.dy);
              },
              child: _withReactionOverlay(
                Container(
                  padding: bubblePadding,
                  decoration: BoxDecoration(
                    // Solid, full-opacity brand color: the bubble IS the swatch
                    // the sender picked. Under a translucent glass tint the
                    // color you choose is never the color you get — white
                    // comes out grey, and every dark tone comes out black.
                    // See _bubbleFg for the contrast rule that makes this safe.
                    color: _bubbleFill,
                    borderRadius: bubbleBorderRadius,
                  ),
                  child: _buildContent(context),
                ),
                hasReactions,
              ),
            ),
          ),
        ],
      );
    }
  }

  void _navigateToContactProfile(BuildContext context, Contact contact) {
    AppNav.toContact(context, contact);
  }

  Widget _buildSenderInfo(BuildContext context) {
    // This method is called only if isGroupChat && !isMe
    final tokens = GlassTokens.of(context);
    final nameStyle = TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: tokens.starkWhite,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    if (widget.message.senderInboxId == null || widget.message.senderInboxId!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
        child: Text(
          _formatSenderAddress(widget.message.senderAddress),
          style: nameStyle,
        ),
      );
    }

    // Use senderContact provided by chat screen (from its cache)
    if (widget.senderContact != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0, left: 0.0),
        child: GestureDetector(
          onTap: () => _navigateToContactProfile(context, widget.senderContact!),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GlassContactIcon(
                contact: widget.senderContact!,
                size: _senderIconSize,
              ),
              const SizedBox(width: 6),
              Text(
                widget.senderContact!.displayName,
                style: nameStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    // Fallback: no contact resolved yet — show truncated address
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
      child: Text(
        _formatSenderAddress(widget.message.senderInboxId ?? widget.message.senderAddress),
        style: nameStyle,
      ),
    );
  }

  // Helper to check if attachment is an image
  bool _isImageAttachment(dynamic content) {
    AttachmentContent? attachmentContent = _parseAttachmentContent(content);
    return attachmentContent != null && attachmentContent.mimeType.startsWith('image/') && attachmentContent.data.isNotEmpty;
  }

  // Local attachment carries the sticker flag → render bubble-less + unclipped.
  bool _isStickerAttachment(dynamic content) {
    AttachmentContent? attachmentContent = _parseAttachmentContent(content);
    return attachmentContent != null && attachmentContent.isSticker;
  }

  // Helper to check if attachment has a description
  bool _hasAttachmentDescription(dynamic content) {
    AttachmentContent? attachmentContent = _parseAttachmentContent(content);
    return attachmentContent != null &&
           attachmentContent.description != null &&
           attachmentContent.description!.isNotEmpty;
  }

  // Helper to check if remote attachment might be an image
  bool _mightBeImageAttachment(dynamic content) {
    // We'll just check if the filename ends with a common image extension
    if (content is Map<String, dynamic> && content.containsKey('filename')) {
      String filename = content['filename'].toString().toLowerCase();
      return filename.endsWith('.jpg') || filename.endsWith('.jpeg') || filename.endsWith('.png') || filename.endsWith('.gif') || filename.endsWith('.webp');
    } else if (content is RemoteAttachmentContent) {
      String filename = content.filename.toLowerCase();
      return filename.endsWith('.jpg') || filename.endsWith('.jpeg') || filename.endsWith('.png') || filename.endsWith('.gif') || filename.endsWith('.webp');
    }
    return false;
  }

  // Local attachment is a renderable video — used by _buildMessageContent to
  // skip the colored bubble for bare video sends. Mirrors _isImageAttachment.
  bool _isVideoAttachment(dynamic content) {
    AttachmentContent? attachmentContent = _parseAttachmentContent(content);
    return attachmentContent != null &&
           (isVideoMime(attachmentContent.mimeType) || isVideoFilename(attachmentContent.filename)) &&
           attachmentContent.data.isNotEmpty;
  }

  // Remote attachment might be a video (filename-only check, since remote
  // payload isn't fetched yet). Mirrors _mightBeImageAttachment.
  bool _mightBeVideoAttachment(dynamic content) {
    if (content is Map<String, dynamic> && content.containsKey('filename')) {
      return isVideoFilename(content['filename'].toString());
    } else if (content is RemoteAttachmentContent) {
      return isVideoFilename(content.filename);
    }
    return false;
  }

  // Helper to check if remote attachment has a description
  bool _hasRemoteAttachmentDescription(dynamic content) {
    if (content is RemoteAttachmentContent) {
      return content.description != null && content.description!.isNotEmpty;
    } else if (content is Map<String, dynamic>) {
      final desc = content['description'];
      return desc != null && desc.toString().isNotEmpty;
    }
    return false;
  }

  // Helper to parse AttachmentContent from various formats
  AttachmentContent? _parseAttachmentContent(dynamic content) {
    if (content is AttachmentContent) {
      return content;
    } else if (content is Map<String, dynamic>) {
      try {
        return AttachmentContent.fromJson(content);
      } catch (e) {
      }
    } else if (content is String && content.startsWith('{')) {
      try {
        final Map<String, dynamic> jsonData = jsonDecode(content);
        return AttachmentContent.fromJson(jsonData);
      } catch (e) {
      }
    }
    return null;
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    switch (widget.message.content.type) {
      case MessageType.text:
        if (widget.message.content.value == null) {
          return Text(
            context.l10n.messageWidgetUnsupportedMessage,
            style: TextStyle(
              color: _bubbleFg.withValues(alpha: 0.5),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          );
        }
        // Interactive bot messages (decoded by ActionsCodec / IntentCodec)
        if (widget.message.content.value is ActionsContent) {
          return _buildInteractiveMenu(widget.message.content.value as ActionsContent, theme);
        }
        if (widget.message.content.value is IntentContent) {
          return _buildInteractiveActionResponse(widget.message.content.value as IntentContent, theme);
        }
        // On-chain transaction content types (XIP-21 / XIP-59). Decoded by the
        // xmtp_plugin codecs; mapped to text like ActionsContent/IntentContent.
        if (widget.message.content.value is TransactionReference) {
          return _buildTransactionReceipt(
              widget.message.content.value as TransactionReference, theme);
        }
        if (widget.message.content.value is WalletSendCalls) {
          return _buildTransactionRequest(
              widget.message.content.value as WalletSendCalls, theme);
        }
        final textContent = widget.message.content.value.toString();
        return _buildTextWithLinkPreview(textContent);
      case MessageType.attachment:
        return _buildAttachmentContent(widget.message.content.value, theme, context);
      case MessageType.remoteAttachment:
        return _buildRemoteAttachmentContent(widget.message.content.value, theme);
      case MessageType.multiRemoteAttachment:
        return _buildMultiAttachmentContent(widget.message.content.value, theme);
      case MessageType.reply:
        return _buildReplyContent(widget.message.content.value, theme, context);
      default:
        return Text(
          context.l10n.messageWidgetUnsupportedMessageType(
              widget.message.content.type.toString()),
          style: TextStyle(
            color: _bubbleFg,
            fontSize: 16,
          ),
        );
    }
  }

  // ===================== Interactive Messages =====================

  Widget _buildInteractiveMenu(ActionsContent menu, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (menu.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                menu.description,
                style: TextStyle(
                  color: _bubbleFg,
                  fontSize: 15,
                ),
              ),
            ),
          ...menu.actions.map((action) {
            final isPrimary = action.style == 'primary';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _HoldToSendActionButton(
                label: action.label,
                imageUrl: action.imageUrl,
                isPrimary: isPrimary,
                foreground: _bubbleFg,
                onComplete: widget.onSendTextMessage != null
                    ? () {
                        // Send coinbase.com/intent with the selected action
                        widget.onSendTextMessage!(
                          IntentContent(
                            id: menu.id,
                            actionId: action.id,
                            metadata: {
                              'actionLabel': action.label,
                              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
                            },
                          ),
                          'coinbase.com',
                          'intent',
                        );
                      }
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInteractiveActionResponse(IntentContent response, ThemeData theme) {
    final label = response.metadata?['actionLabel'] as String? ?? response.actionId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        context.l10n.messageWidgetTapped(label),
        style: TextStyle(
          color: _bubbleFgSub,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // ==========================================================================
  // On-chain transaction content types (XIP-21 receipt / XIP-59 invoice)
  // ==========================================================================

  /// EIP-155 chain id (hex or decimal string) → display name + explorer base.
  ({String name, String? explorer}) _chainInfo(String chainId) {
    switch (_parseChainId(chainId)) {
      case 1:
        return (name: 'Ethereum', explorer: 'https://etherscan.io');
      case 8453:
        return (name: 'Base', explorer: 'https://basescan.org');
      case 10:
        return (name: 'Optimism', explorer: 'https://optimistic.etherscan.io');
      case 42161:
        return (name: 'Arbitrum', explorer: 'https://arbiscan.io');
      case 137:
        return (name: 'Polygon', explorer: 'https://polygonscan.com');
      default:
        return (
          name: chainId.isEmpty
              ? context.l10n.messageWidgetUnknownChain
              : context.l10n.messageWidgetChainNumbered(chainId),
          explorer: null,
        );
    }
  }

  int? _parseChainId(String chainId) {
    if (chainId.isEmpty) return null;
    if (chainId.startsWith('0x') || chainId.startsWith('0X')) {
      return int.tryParse(chainId.substring(2), radix: 16);
    }
    return int.tryParse(chainId);
  }

  String _shortHex(String hex, {int head = 8, int tail = 6}) {
    if (hex.length <= head + tail + 1) return hex;
    return '${hex.substring(0, head)}…${hex.substring(hex.length - tail)}';
  }

  /// XIP-21 amount is an integer scaled by `decimals` (e.g. 1000000 @ 6 = 1).
  String _formatAmount(double amount, int? decimals, String? currency) {
    final d = decimals ?? 0;
    final value = d > 0 ? amount / pow(10, d) : amount;
    var formatted = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(4);
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return currency != null && currency.isNotEmpty
        ? '$formatted $currency'
        : formatted;
  }

  Future<void> _launchExplorer(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  /// A from/to party row — a small label, an avatar (resolved contact, else an
  /// address identicon), and the resolved name (else a short address). Mirrors
  /// the Send-OX sheet's recipient rows.
  // Account/wallet → wallet label ("main" / custom). Static so many receipts in
  // a chat (same parties) resolve getWallets once, not per card.
  static final Map<String, Future<String?>> _walletNameCache = {};
  Future<String?> _resolveWalletName(
      EthereumAddress account, String walletAddress) {
    final key = '${account.eip55With0x}/$walletAddress'.toLowerCase();
    return _walletNameCache[key] ??= () async {
      try {
        final wallets = await PublicOSWallets.getWallets(account);
        final lower = walletAddress.toLowerCase();
        for (final w in wallets) {
          if (w.addressHex.toLowerCase() == lower) {
            if (w.isMainSafe) return 'main';
            return w.label.isNotEmpty ? w.label : null;
          }
        }
      } catch (_) {}
      return null;
    }();
  }

  /// A rich party row — avatar + label + display name + "walletName · address",
  /// matching the Send-OX sheet's recipient rows. The wallet name resolves
  /// on-chain (getWallets) when the contact + address are both known.
  Widget _buildTxParty({
    required String label,
    required Contact? contact,
    required String? address,
    required Color? fg,
    required Color? subFg,
  }) {
    final hasAddr = address != null && address.isNotEmpty;
    final displayName = contact?.displayName ??
        (hasAddr ? _shortHex(address!, head: 6, tail: 4) : '—');
    final short = hasAddr ? _shortHex(address!, head: 6, tail: 4) : '';
    final account = contact?.publicosAddress;
    return Row(
      children: [
        if (contact != null)
          GlassContactIcon(opensProfile: true, contact: contact, size: 38)
        else if (hasAddr)
          GlassContactIcon(opensProfile: true, address: address!, size: 38)
        else
          const SizedBox(width: 38, height: 38),
        const SizedBox(width: 10),
        Expanded(
          child: ContactProfileTap(contact: contact, address: address, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      color: subFg,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const SizedBox(height: 1),
              Text(displayName,
                  style: TextStyle(
                      color: fg, fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              if (contact != null && hasAddr)
                FutureBuilder<String?>(
                  future: account != null
                      ? _resolveWalletName(account, address!)
                      : Future.value(null),
                  builder: (context, snap) {
                    final n = snap.data;
                    final line =
                        (n != null && n.isNotEmpty) ? '$n · $short' : short;
                    return Text(line,
                        style: TextStyle(color: subFg, fontSize: 12),
                        overflow: TextOverflow.ellipsis);
                  },
                ),
            ],
          )),
        ),
      ],
    );
  }

  /// A labeled key/value row for the transaction "what" list.
  Widget _kvRow(String label, Widget value, Color? subFg) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              child: Text(label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(color: subFg, fontSize: 12)),
            ),
            const SizedBox(width: 4),
            Expanded(child: value),
          ],
        ),
      );

  /// Chain display value — the known name (e.g. "Base") or the bare chain id
  /// (e.g. "4489"); avoids a "Chain: Chain 4489" double-label for unknown ids.
  String _chainValue(String networkId) {
    final cid = _parseChainId(networkId);
    if (cid != null) {
      // Registry name covers all our chains (PublicOS, Ethereum, Base, …).
      final c = chainById(cid);
      if (c != null) return c.name;
    }
    return cid?.toString() ?? networkId;
  }

  /// A value cell with a leading brand icon (chain mark / coin mark).
  Widget _iconValue(Widget icon, String text, TextStyle style) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      );

  // Receipt token+amount, decoded on-chain then symbol-resolved. Memoized.
  Future<({String symbol, String amount})?>? _receiptWhatCache;
  Future<({String symbol, String amount})?> _receiptWhatFuture(
      TransactionReference ref, int chainId, TransactionMetadata? meta) {
    return _receiptWhatCache ??= () async {
      final symbol = (meta?.currency != null && meta!.currency!.isNotEmpty)
          ? meta.currency!
          : 'OX';
      final decimals = meta?.decimals ?? 18;
      // Amount from the transaction itself (the source of truth) — handles both
      // a direct transfer and a Safe-wrapped executeCall. The native `value` is
      // 0 for an ERC-20 transfer and metadata.amount is only advisory.
      final raw =
          await PublicOSWallets.fetchTxTransferRawAmount(chainId, ref.reference);
      if (raw != null) {
        return (
          symbol: symbol,
          amount:
              PublicOSWallets.formatTokenAmount(raw, decimals, symbol: symbol)
        );
      }
      // Fallback: metadata amount (XIP-21 = smallest units; our sender now
      // emits raw, so divide by 10^decimals here too).
      if (meta?.amount != null) {
        return (
          symbol: symbol,
          amount: _formatAmount(meta!.amount!, decimals, symbol)
        );
      }
      return null;
    }();
  }

  // Request token+amount (transfer already decoded from calldata). Memoized.
  Future<({String symbol, String amount})?>? _requestWhatCache;
  Future<({String symbol, String amount})?> _requestWhatFuture(
      int chainId, Erc20Transfer? transfer) {
    return _requestWhatCache ??= () async {
      if (transfer == null) return null;
      final m = await PublicOSWallets.resolveTokenMeta(chainId, transfer.token);
      final symbol = m?.symbol ?? _shortHex(transfer.token, head: 6, tail: 4);
      final amount = PublicOSWallets.formatTokenAmount(
          transfer.rawAmount, m?.decimals ?? 0,
          symbol: symbol);
      return (symbol: symbol, amount: amount);
    }();
  }

  /// XIP-21 receipt — From → To (resolved parties), the chain / token / amount
  /// (amount decoded ON-CHAIN — the tx hash is the source of truth; the native
  /// `value` is 0 for ERC-20 transfers), and a View-on-explorer link.
  Widget _buildTransactionReceipt(TransactionReference ref, ThemeData theme) {
    final info = _chainInfo(ref.networkId);
    final url = (info.explorer != null && ref.reference.isNotEmpty)
        ? '${info.explorer}/tx/${ref.reference}'
        : null;
    final fg = _bubbleFg;
    final subFg = fg.withValues(alpha: 0.6);
    final meta = ref.metadata;
    final chainId = _parseChainId(ref.networkId) ?? 0;
    final valueStyle =
        TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w500);
    final amountStyle =
        TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w700);

    final myContact = AppStateNotifier.currentMyContact;
    final peerContact = widget.contactLookup?.call(widget.peerInboxId ?? '');
    final fromContact = isMe ? myContact : widget.senderContact;
    final toContact = isMe ? peerContact : myContact;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(context.l10n.messageWidgetTransactionReceipt,
                  style: TextStyle(
                      color: fg, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          _buildTxParty(
              label: context.l10n.messageWidgetTxFrom,
              contact: fromContact,
              address: meta?.fromAddress,
              fg: fg,
              subFg: subFg),
          const SizedBox(height: 8),
          _buildTxParty(
              label: context.l10n.messageWidgetTxTo,
              contact: toContact,
              address: meta?.toAddress,
              fg: fg,
              subFg: subFg),
          const SizedBox(height: 10),
          _kvRow(
              context.l10n.messageWidgetTxChain,
              _iconValue(NftChainIcon(chain: chainId, size: 18),
                  _chainValue(ref.networkId), valueStyle),
              subFg),
          FutureBuilder<({String symbol, String amount})?>(
            future: _receiptWhatFuture(ref, chainId, meta),
            builder: (context, snap) {
              final w = snap.data;
              if (w == null) return const SizedBox.shrink();
              return Column(
                children: [
                  _kvRow(
                      context.l10n.messageWidgetTxToken,
                      _iconValue(CoinIcon(symbol: w.symbol, size: 18), w.symbol,
                          valueStyle),
                      subFg),
                  _kvRow(context.l10n.messageWidgetTxAmount,
                      Text(w.amount, style: amountStyle), subFg),
                ],
              );
            },
          ),
          if (url != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _launchExplorer(url),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new, size: 13, color: subFg),
                  const SizedBox(width: 4),
                  Text(context.l10n.messageWidgetViewOnExplorer,
                      style: TextStyle(
                          color: subFg,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// XIP-59 invoice — To (the requester's receiving wallet, resolved), the
  /// chain / token / amount requested, and a Review-&-Pay button for the payer.
  Widget _buildTransactionRequest(WalletSendCalls wsc, ThemeData theme) {
    final fg = _bubbleFg;
    final subFg = fg.withValues(alpha: 0.6);
    final chainId = _parseChainId(wsc.chainId) ?? 0;
    final valueStyle =
        TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w500);
    final amountStyle =
        TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w700);

    // The requester (message sender) is paid; their receiving wallet is the
    // first transfer call's recipient.
    final requester =
        isMe ? AppStateNotifier.currentMyContact : widget.senderContact;
    final firstCall = wsc.calls.isNotEmpty ? wsc.calls.first : null;
    final firstTransfer = (firstCall?.to != null)
        ? PublicOSWallets.decodeErc20Transfer(firstCall!.to!, firstCall.data)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.request_quote_rounded, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(context.l10n.messageWidgetTransactionRequest,
                  style: TextStyle(
                      color: fg, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          _buildTxParty(
              label: context.l10n.messageWidgetTxTo,
              contact: requester,
              address: firstTransfer?.recipient,
              fg: fg,
              subFg: subFg),
          const SizedBox(height: 10),
          _kvRow(
              context.l10n.messageWidgetTxChain,
              _iconValue(NftChainIcon(chain: chainId, size: 18),
                  _chainValue(wsc.chainId), valueStyle),
              subFg),
          FutureBuilder<({String symbol, String amount})?>(
            future: _requestWhatFuture(chainId, firstTransfer),
            builder: (context, snap) {
              final w = snap.data;
              if (w == null) {
                final desc = firstCall?.metadata?.description;
                if (desc != null && desc.isNotEmpty) {
                  return _kvRow(context.l10n.messageWidgetTxAmount,
                      Text(desc, style: amountStyle), subFg);
                }
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  _kvRow(
                      context.l10n.messageWidgetTxToken,
                      _iconValue(CoinIcon(symbol: w.symbol, size: 18), w.symbol,
                          valueStyle),
                      subFg),
                  _kvRow(context.l10n.messageWidgetTxAmount,
                      Text(w.amount, style: amountStyle), subFg),
                ],
              );
            },
          ),
          // Only the recipient pays; an invoice you sent shows read-only.
          if (!isMe) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              // Sits on the solid brand fill, so it derives from the bubble's
              // foreground — colorScheme.primary would clash with (or vanish
              // into) whatever colour the sender picked.
              child: OutlinedButton(
                onPressed: () => _payRequestViaSendSheet(wsc),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _bubbleFgFaint,
                  side: BorderSide(color: _bubbleFg.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(context.l10n.messageWidgetReviewAndPay,
                    style: TextStyle(
                        color: _bubbleFg,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Hand the request to the existing multi-chain signature sheet, one call at a
  /// time. NOTE: the sheet's actual signing/broadcast is being reworked
  /// separately — this is the review/approve connection point for now.
  Future<void> _handleWalletSendCalls(WalletSendCalls wsc) async {
    final l10n = context.l10n;
    for (final call in wsc.calls) {
      final approved = await SignatureRequestSheet.show(
        context: context,
        requestType: SignatureRequestType.sendTransaction,
        transactionData: {
          'from': wsc.from,
          if (call.to != null) 'to': call.to,
          if (call.data != null) 'data': call.data,
          'value': call.value ?? '0x0',
          if (call.gas != null) 'gas': call.gas,
          'chainId': wsc.chainId,
        },
        requestingOrigin: l10n.messageWidgetXmtpTxRequestOrigin,
      );
      if (!mounted || !approved) break; // user rejected → stop the batch
    }
  }

  /// Pay a chat payment-request through the prefilled Send sheet (multi-chain
  /// picker, decimals, the Safe-target guard all apply). Single-transfer
  /// requests on a known chain route here; everything else falls back to the
  /// raw signature sheet.
  ///
  /// TODO(multi-call): the Send sheet sends ONE transfer. A batched
  /// WalletSendCalls (calls.length > 1) still uses [_handleWalletSendCalls];
  /// revisit to support batches in the sheet.
  Future<void> _payRequestViaSendSheet(WalletSendCalls wsc) async {
    final chainId = _parseChainId(wsc.chainId) ?? 0;
    final chain = chainById(chainId);
    final firstCall = wsc.calls.isNotEmpty ? wsc.calls.first : null;
    final transfer = (firstCall?.to != null)
        ? PublicOSWallets.decodeErc20Transfer(firstCall!.to!, firstCall.data)
        : null;
    if (wsc.calls.length != 1 || transfer == null || chain == null) {
      await _handleWalletSendCalls(wsc);
      return;
    }

    // Resolve the requested token: registry first, else its on-chain meta
    // (custom token). If neither resolves, fall back to the raw sheet.
    TokenDef? token = tokenForAddress(chainId, transfer.token);
    if (token == null) {
      final meta =
          await PublicOSWallets.resolveTokenMeta(chainId, transfer.token);
      if (meta == null) {
        await _handleWalletSendCalls(wsc);
        return;
      }
      token = TokenDef(
          symbol: meta.symbol,
          decimals: meta.decimals,
          address: transfer.token);
    }
    if (!mounted) return;

    final recipient = EthereumAddress.fromHex(transfer.recipient);
    await showSendSheet(
      context: context,
      config: SendSheetConfig(
        targetMode: SendTargetMode.fixed,
        // The candidate supplies the SENDING TO identity (the requester); the
        // exact wallet that gets paid is the request's transfer recipient.
        candidates: [
          SendCandidate(address: recipient, contact: widget.senderContact)
        ],
        exactTargetAddress: recipient.eip55With0x,
        defaultChain: chain,
        defaultToken: token,
        requestedAmount: transfer.rawAmount,
        tipChips: const [1.0, 1.10, 1.15, 1.20],
        lockChainToken: true,
        title: context.l10n.messageWidgetPayRequestTitle,
        confirmLabel: context.l10n.messageWidgetPayRequestConfirm,
        confirmIcon: Icons.check_rounded,
        // Post the on-chain receipt back to the chat. (Stage 4 makes this a
        // reply to the request so the card can flip to "Paid".)
        onSent: (info) async => _postRequestReceipt(info),
      ),
    );
  }

  /// Build + post the XIP-21 receipt for a paid request via the chat-screen
  /// send callback (any chain/token, BigInt-safe scaling).
  void _postRequestReceipt(SentTxInfo info) {
    final raw = _humanToRaw(info.amount, info.decimals);
    final ref = TransactionReference(
      networkId: info.chainId.toString(),
      reference: info.txHash,
      metadata: TransactionMetadata(
        transactionType: 'transfer',
        currency: info.tokenSymbol,
        amount: raw.toDouble(),
        decimals: info.decimals,
        fromAddress: info.fromAddress,
        toAddress: info.toAddress,
      ),
    );
    widget.onSendTextMessage?.call(ref, 'xmtp.org', 'transactionReference');
  }

  BigInt _humanToRaw(String text, int decimals) {
    final parts = text.trim().split('.');
    final whole = parts[0].isEmpty ? '0' : parts[0];
    var frac = parts.length > 1 ? parts[1] : '';
    if (frac.length > decimals) frac = frac.substring(0, decimals);
    frac = frac.padRight(decimals, '0');
    return BigInt.parse('$whole$frac');
  }

  Widget _buildAttachmentContent(dynamic content, ThemeData theme, BuildContext context) {
    // Try to convert to AttachmentContent if it's not already
    AttachmentContent? attachmentContent = _parseAttachmentContent(content);

    // If we successfully got AttachmentContent, process it
    if (attachmentContent != null) {
      // Sizing. Any isSticker renders at its natural size capped at
      // [stickerWidth] (a fraction of screen width). A GIF sent as a plain
      // attachment (isSticker=false) renders at a FIXED [stickerWidth],
      // proportional. All other attachments keep the 300px box.
      final bool isSticker = attachmentContent.isSticker;
      final bool isGifAttachment =
          !isSticker && attachmentContent.mimeType == 'image/gif';
      // PNG/WebP stickers render unclipped — their alpha defines the shape. GIF
      // stickers are opaque rectangles, so they take the same rounded corners as
      // a normal attachment.
      final bool stickerUnclipped =
          isSticker && attachmentContent.mimeType != 'image/gif';
      // Sticker / gif-as-gif display width — a fraction of screen width.
      // Tune the multiplier to resize all stickers + gifs at once.
      final double stickerWidth = MediaQuery.of(context).size.width * 0.28;
      final double gifWidth = MediaQuery.of(context).size.width * 0.52;
      final String caption = attachmentContent.description ?? '';
      final bool isImage = (isImageMime(attachmentContent.mimeType) ||
              isImageFilename(attachmentContent.filename)) &&
          attachmentContent.data.isNotEmpty;
      if (isImage && !isSticker && caption.isNotEmpty) {
        return _buildCaptionedImage(
          bytes: attachmentContent.data,
          filename: attachmentContent.filename,
          description: caption,
          theme: theme,
        );
      }
      if (widget.message.isPending && content is AttachmentContent && content.mimeType.startsWith('image/') && content.data.isNotEmpty) {
        // Pending image — bytes already in memory; route through
        // NaturalRatioMedia for consistent sizing with confirmed.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NaturalRatioMedia(
              imageBytes: content.data,
              filename: content.filename,
              heroTag: 'attachment_hero_${widget.message.idXmtp ?? widget.message.id}_${content.filename}',
              width: isSticker ? null : (isGifAttachment ? gifWidth : 300),
              maxWidth: isSticker ? stickerWidth : null,
              maxHeight: isSticker ? stickerWidth : (isGifAttachment ? null : 300),
              borderRadius: stickerUnclipped ? BorderRadius.zero : BorderRadius.circular(8),
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorContainer(
                    theme, context.l10n.messageWidgetFailedToLoadImage, '');
              },
            ),
            if (content.description != null && content.description!.isNotEmpty)
              _buildAttachmentDescription(content.description!, theme),
          ],
        );
      } else if ((isImageMime(attachmentContent.mimeType) ||
              isImageFilename(attachmentContent.filename)) &&
          attachmentContent.data.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NaturalRatioMedia(
              imageBytes: attachmentContent.data,
              filename: attachmentContent.filename,
              heroTag: 'attachment_hero_${widget.message.idXmtp ?? widget.message.id}_${attachmentContent.filename}',
              width: isSticker ? stickerWidth : (isGifAttachment ? gifWidth : 300),
              maxWidth: isSticker ? stickerWidth : null,
              maxHeight: isSticker ? stickerWidth : (isGifAttachment ? null : 300),
              borderRadius: stickerUnclipped ? BorderRadius.zero : BorderRadius.circular(8),
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorContainer(
                    theme, context.l10n.messageWidgetFailedToLoadImage, '');
              },
            ),
            if (attachmentContent.description != null && attachmentContent.description!.isNotEmpty)
              _buildAttachmentDescription(attachmentContent.description!, theme),
          ],
        );
      } else if ((isVideoMime(attachmentContent.mimeType) ||
              isVideoFilename(attachmentContent.filename)) &&
          attachmentContent.data.isNotEmpty) {
        // Inline video attachment — bytes from XMTP (or decrypted from a
        // RemoteAttachment via _loadRemoteAttachment). ChatVideoBubble
        // renders a thumbnail-first poster + tap-to-load player so idle
        // bubbles don't pin a VideoPlayerController each (keepalive=true on
        // every MessageWidget would otherwise hold N controllers resident).
        final msgId = widget.message.idXmtp ?? widget.message.id.toString();
        final aspectCache = widget.videoAspectCache;
        final videoChild = (aspectCache != null)
            ? ChatVideoBubble(
                videoBytes: attachmentContent.data,
                messageId: msgId,
                filename: attachmentContent.filename,
                heroTag: 'attachment_hero_${msgId}_${attachmentContent.filename}',
                width: 300,
                maxHeight: 300,
                borderRadius: BorderRadius.circular(8),
                videoAspectCache: aspectCache,
              )
            : NaturalRatioMedia(
                videoBytes: attachmentContent.data,
                filename: attachmentContent.filename,
                heroTag: 'attachment_hero_${msgId}_${attachmentContent.filename}',
                width: 300,
                maxHeight: 300,
                borderRadius: BorderRadius.circular(8),
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            videoChild,
            if (attachmentContent.description != null &&
                attachmentContent.description!.isNotEmpty)
              _buildAttachmentDescription(attachmentContent.description!, theme),
          ],
        );
      } else {
        // Document / non-media attachment with bytes already in hand (inline,
        // or an already-decrypted remote). Tappable chip → OS "open with".
        final att = attachmentContent;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDocumentChip(
              theme: theme,
              filename: att.filename,
              sizeBytes: att.data.lengthInBytes,
              loading: false,
              onTap: () => _openLocalDocument(att),
              onSave: () => _saveDocument(att),
            ),
            if (att.description != null && att.description!.isNotEmpty)
              _buildAttachmentDescription(att.description!, theme),
          ],
        );
      }
    }

    // Fallback for invalid attachment format
    return Text(
      context.l10n.messageWidgetInvalidAttachmentFormat,
      style: TextStyle(
        color: _bubbleFg,
        fontSize: 16,
      ),
    );
  }

  /// Messaging-style document chip: a doc icon, the filename, and a
  /// "SIZE · EXT" subtitle. Tap opens the file with the OS "open with"; for a
  /// not-yet-downloaded remote doc, tap downloads+decrypts first ([loading]
  /// shows the spinner during that fetch). The trailing button saves the file
  /// through the OS save dialog ([onSave]), for when no app can open it.
  Widget _buildDocumentChip({
    required ThemeData theme,
    required String filename,
    required int? sizeBytes,
    required bool loading,
    required VoidCallback onTap,
    required VoidCallback onSave,
  }) {
    final ext =
        filename.contains('.') ? filename.split('.').last.toUpperCase() : '';
    final subtitle = <String>[
      if (sizeBytes != null && sizeBytes > 0) _formatFileSize(sizeBytes),
      if (ext.isNotEmpty) ext,
    ].join(' · ');
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: loading ? null : onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260, minWidth: 180),
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The type tile from the ONE extension list (utils/doc_types.dart),
            // shared with the settings sheet's Docs tab.
            loading
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: docTypeFor(filename).color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.hourglass_empty_rounded,
                        color: docTypeFor(filename).color, size: 20),
                  )
                : DocTypeTile(filename: filename),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filename,
                    style: TextStyle(
                      color: _bubbleFg,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _bubbleFg.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            if (loading)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.hourglass_empty_rounded,
                    color: _bubbleFg.withValues(alpha: 0.5), size: 18),
              )
            else
              IconButton(
                tooltip: context.l10n.documentSave,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.download_rounded,
                    color: _bubbleFg.withValues(alpha: 0.7), size: 20),
                onPressed: onSave,
              ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    final kb = bytes / 1024;
    if (kb >= 1024) return '${(kb / 1024).toStringAsFixed(1)} MB';
    return '${kb.toStringAsFixed(0)} KB';
  }

  /// Open an in-hand document (inline, or already-decrypted remote) with the OS.
  Future<void> _openLocalDocument(AttachmentContent att) async {
    final ok = await openFileWithSystem(
      bytes: att.data,
      filename: att.filename,
      mimeType: att.mimeType,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.documentOpenFailed)),
      );
    }
  }

  /// Save an in-hand document where the user picks (OS save dialog).
  /// Cancel is silent; only a real write failure shows an error.
  Future<void> _saveDocument(AttachmentContent att) async {
    try {
      final saved =
          await saveBytesWithDialog(bytes: att.data, filename: att.filename);
      if (saved != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.documentSaved)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.documentSaveFailed)),
        );
      }
    }
  }

  /// Fetch + decrypt a remote document on demand (tap), then open it.
  Future<void> _downloadAndOpenRemoteDoc(RemoteAttachmentContent remote) =>
      _withRemoteDoc(remote, _openLocalDocument);

  /// Fetch + decrypt a remote document on demand, then save it.
  Future<void> _downloadAndSaveRemoteDoc(RemoteAttachmentContent remote) =>
      _withRemoteDoc(remote, _saveDocument);

  Future<void> _withRemoteDoc(RemoteAttachmentContent remote,
      Future<void> Function(AttachmentContent att) action) async {
    if (_docDownloading) return;
    setState(() => _docDownloading = true);
    try {
      final att = await _loadRemoteAttachment(remote);
      if (!mounted) return;
      await action(att);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(context.l10n.messageWidgetCouldntLoadAttachment)),
        );
      }
    } finally {
      if (mounted) setState(() => _docDownloading = false);
    }
  }

  /// A captioned image fills its bubble: full bubble width, cover-cropped
  /// (capped at 300 tall), top corners following the bubble's own radius (minus
  /// the 2px media padding), square bottom edge meeting the caption, and the
  /// caption wrapped to that same width. Without this the image keeps its
  /// natural shape inside a 300x300 box, so a tall screenshot shrinks to a
  /// narrow strip while the caption stretches the bubble wider (twin of
  /// publicos_client).
  Widget _buildCaptionedImage({
    required Uint8List bytes,
    required String filename,
    required String description,
    required ThemeData theme,
  }) {
    final double pad = _attachmentBubblePadding.top;
    Radius inner(Radius r) => Radius.circular(max(0, r.x - pad));
    final BorderRadius imageRadius = BorderRadius.only(
      topLeft: inner(bubbleBorderRadius.topLeft),
      topRight: inner(bubbleBorderRadius.topRight),
    );
    return LayoutBuilder(builder: (context, constraints) {
      final double w = constraints.hasBoundedWidth
          ? min(constraints.maxWidth, 320.0)
          : 300.0;
      return SizedBox(
        width: w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NaturalRatioMedia(
              imageBytes: bytes,
              filename: filename,
              heroTag: 'attachment_hero_${widget.message.idXmtp ?? widget.message.id}_$filename',
              width: w,
              maxHeight: 300,
              fillWidth: true,
              borderRadius: imageRadius,
              errorBuilder: (context, error, stackTrace) => _buildErrorContainer(
                  theme, context.l10n.messageWidgetFailedToLoadImage, ''),
            ),
            _buildAttachmentDescription(description, theme),
          ],
        ),
      );
    });
  }

  /// Build the description text widget for attachments
  /// When inside a colored bubble, we don't need extra container styling
  Widget _buildAttachmentDescription(String description, ThemeData theme) {
    // The caption lives inside the tight attachment-padded bubble (media stays at
    // _attachmentBubblePadding). Add the delta back so the caption text lines up
    // with the roomy text padding, like a plain text bubble. Assumes
    // _attachmentBubblePadding <= _textBubblePadding.
    final double dx = _textBubblePadding.left - _attachmentBubblePadding.left;
    final double db = _textBubblePadding.bottom - _attachmentBubblePadding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(dx, _textBubblePadding.top, dx, db),
      child: _buildTrimmableText(description, fontSize: 15),
    );
  }

  Widget _buildRemoteAttachmentContent(dynamic content, ThemeData theme) {
    // Convert to RemoteAttachmentContent if it's a Map
    RemoteAttachmentContent? remoteContent;
    if (content is RemoteAttachmentContent) {
      remoteContent = content;
    } else if (content is Map<String, dynamic>) {
      try {
        remoteContent = RemoteAttachmentContent.fromJson(content);
      } catch (e) {
        // Silently handle error
      }
    }

    if (remoteContent == null) {
      return Text(
        context.l10n.messageWidgetInvalidRemoteAttachmentFormat,
        style: TextStyle(
          color: _bubbleFg,
          fontSize: 16,
        ),
      );
    }

    // Replace old IPFS gateway with current gateway
    var modifiedUrl = remoteContent.url.replaceAll('https://teal-binding-beaver-907.mypinata.cloud', 'https://gateway.pinata.cloud');

    final modifiedRemoteContent = RemoteAttachmentContent(
      url: modifiedUrl,
      contentDigest: remoteContent.contentDigest,
      secret: remoteContent.secret,
      salt: remoteContent.salt,
      nonce: remoteContent.nonce,
      scheme: remoteContent.scheme,
      contentLength: remoteContent.contentLength,
      filename: remoteContent.filename,
      description: remoteContent.description,
    );

    // Check if it might be inline media based on filename (image or video) —
    // controls the loading placeholder's rounding so it matches the no-bubble
    // render path in _buildMessageContent.
    bool mightBeImage = _mightBeImageAttachment(modifiedRemoteContent);
    bool mightBeVideo = _mightBeVideoAttachment(modifiedRemoteContent);

    // Documents are NOT auto-downloaded (they can be large). Render a chip from
    // the filename + contentLength (both ride in the XMTP params, no fetch
    // needed) and fetch+decrypt only when the user taps to open.
    if (!mightBeImage && !mightBeVideo) {
      final docChip = _buildDocumentChip(
        theme: theme,
        filename: modifiedRemoteContent.filename,
        sizeBytes: modifiedRemoteContent.contentLength,
        loading: _docDownloading,
        onTap: () => _downloadAndOpenRemoteDoc(modifiedRemoteContent),
        onSave: () => _downloadAndSaveRemoteDoc(modifiedRemoteContent),
      );
      if (modifiedRemoteContent.description != null &&
          modifiedRemoteContent.description!.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            docChip,
            _buildAttachmentDescription(modifiedRemoteContent.description!, theme),
          ],
        );
      }
      return docChip;
    }

    // Cache the future on first access
    _remoteAttachmentFuture ??= _loadRemoteAttachment(modifiedRemoteContent);

    // Try to get from cache first, then load from network if not cached
    return FutureBuilder<AttachmentContent>(
      future: _remoteAttachmentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Calculate 16:9 height based on a width of 200
          double height = 200 * 9 / 16;

          return Container(
            width: 200,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[300]?.withValues(alpha: 0.12),
              borderRadius: (mightBeImage || mightBeVideo) ? bubbleBorderRadius : null,
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorContainer(theme, context.l10n.messageWidgetCouldntLoadAttachment, '');
        }

        if (snapshot.hasData) {
          // The caption travels in the XMTP params, not inside the encrypted
          // file. Hand it to the decrypted attachment (when that carries none)
          // so ONE builder lays out media + caption, which a captioned image
          // needs to share one width (_buildCaptionedImage).
          final AttachmentContent decrypted = snapshot.data!;
          final String remoteCaption = modifiedRemoteContent.description ?? '';
          final AttachmentContent withCaption =
              (remoteCaption.isNotEmpty && (decrypted.description ?? '').isEmpty)
                  ? AttachmentContent(
                      data: decrypted.data,
                      mimeType: decrypted.mimeType,
                      filename: decrypted.filename,
                      description: remoteCaption,
                      isSticker: decrypted.isSticker,
                    )
                  : decrypted;
          return _buildAttachmentContent(withCaption, theme, context);
        }

        return _buildErrorContainer(theme, context.l10n.messageWidgetCouldntLoadAttachment, '');
      },
    );
  }

  /// Several files in one message (xmtp.org/multiRemoteStaticAttachment).
  /// 1 → one wide tile · 2 → side by side · 3 → one wide on top, two below ·
  /// 4+ → 2×2, the 4th tile showing "+N" and opening the full list. Each tile
  /// goes through the same cache-then-network loader as a single remote
  /// attachment; tap → MediaOverlay. The caption (our non-standard
  /// `description` parameter) sits below, and the grid's top corners follow
  /// the bubble like [_buildCaptionedImage].
  Widget _buildMultiAttachmentContent(dynamic content, ThemeData theme) {
    final multi = content is MultiRemoteAttachmentContent ? content : null;
    if (multi == null || multi.attachments.isEmpty) {
      return Text(
        context.l10n.messageWidgetInvalidRemoteAttachmentFormat,
        style: TextStyle(color: _bubbleFg, fontSize: 16),
      );
    }
    final items = multi.attachments;
    final String caption = multi.description ?? '';
    const double gap = 2;
    final double pad = _attachmentBubblePadding.top;
    Radius inner(Radius r) => Radius.circular(max(0, r.x - pad));
    // Bare (no caption): the outer ClipRRect already rounds the whole grid.
    final BorderRadius gridRadius = caption.isEmpty
        ? BorderRadius.zero
        : BorderRadius.only(
            topLeft: inner(bubbleBorderRadius.topLeft),
            topRight: inner(bubbleBorderRadius.topRight),
          );
    return LayoutBuilder(builder: (context, constraints) {
      final double w = constraints.hasBoundedWidth
          ? min(constraints.maxWidth, 320.0)
          : 300.0;
      final double half = (w - gap) / 2;
      Widget tile(int i, double tw, double th, {int more = 0}) =>
          _buildGalleryTile(items, i, tw, th, theme, more: more);
      Widget pair(int a, int b, {int more = 0}) => Row(children: [
            tile(a, half, half),
            const SizedBox(width: gap),
            tile(b, half, half, more: more),
          ]);
      final Widget grid;
      switch (items.length) {
        case 1:
          grid = tile(0, w, w * 0.75);
        case 2:
          grid = pair(0, 1);
        case 3:
          grid = Column(children: [
            tile(0, w, half),
            const SizedBox(height: gap),
            pair(1, 2),
          ]);
        default:
          grid = Column(children: [
            pair(0, 1),
            const SizedBox(height: gap),
            pair(2, 3, more: items.length - 4),
          ]);
      }
      return SizedBox(
        width: w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(borderRadius: gridRadius, child: grid),
            if (caption.isNotEmpty) _buildAttachmentDescription(caption, theme),
          ],
        ),
      );
    });
  }

  /// One gallery tile: shimmer while loading, then the image (or a video /
  /// document tile) cover-cropped to [w]×[h]. [more] > 0 dims the tile with
  /// "+N" and opens every item in a scrollable page instead.
  Widget _buildGalleryTile(List<RemoteAttachmentContent> items, int index,
      double w, double h, ThemeData theme, {int more = 0}) {
    final item = items[index];
    final future = _galleryFutures.putIfAbsent(
        item.contentDigest, () => _loadRemoteAttachment(item));
    final msgId = widget.message.idXmtp ?? widget.message.id.toString();
    final tokens = GlassTokens.of(context);
    final Widget body = FutureBuilder<AttachmentContent>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _GalleryShimmer(
              width: w, height: h, base: tokens.glassFill, highlight: tokens.borderMedium);
        }
        final att = snap.data;
        if (att == null) {
          return ColoredBox(
            color: Colors.grey.withValues(alpha: 0.12),
            child: Center(
              child: Icon(Icons.broken_image,
                  color: _bubbleFg.withValues(alpha: 0.6)),
            ),
          );
        }
        final heroTag = 'attachment_hero_${msgId}_${item.contentDigest}';
        if (isImageMime(att.mimeType) || isImageFilename(att.filename)) {
          return TappableImage(
            imageData: att.data,
            heroTag: heroTag,
            width: w,
            height: h,
            fit: BoxFit.cover,
          );
        }
        if (isVideoMime(att.mimeType) || isVideoFilename(att.filename)) {
          return TappableMedia(
            videoBytes: att.data,
            filename: att.filename,
            heroTag: heroTag,
            width: w,
            height: h,
            fit: BoxFit.cover,
            showExpandButton: false,
          );
        }
        return InkWell(
          onTap: () => _openLocalDocument(att),
          child: ColoredBox(
            color: docTypeFor(att.filename).color.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(docTypeFor(att.filename).icon,
                      color: docTypeFor(att.filename).color, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    att.filename,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _bubbleFg, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (more <= 0) return SizedBox(width: w, height: h, child: body);
    return SizedBox(
      width: w,
      height: h,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openGalleryPage(items, theme),
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(child: body),
            ColoredBox(
              color: Colors.black54,
              child: Center(
                child: Text(
                  '+$more',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Every item of a multi-attachment, one per row at full width. Reached from
  /// the "+N" tile; each row taps through to MediaOverlay like the grid.
  void _openGalleryPage(List<RemoteAttachmentContent> items, ThemeData theme) {
    Navigator.of(context).push(MaterialPageRoute(builder: (pageContext) {
      final double w = MediaQuery.of(pageContext).size.width;
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(pageContext.l10n.messageWidgetGalleryTitle(items.length)),
        ),
        body: ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 2),
          itemBuilder: (_, i) => _buildGalleryTile(items, i, w, w * 0.75, theme),
        ),
      );
    }));
  }

  /// Load remote attachment: check cache first, then fetch from network
  Future<AttachmentContent> _loadRemoteAttachment(RemoteAttachmentContent remoteContent) async {
    // 1. Check cache first
    final cached = await PublicOSAttachmentCache.getCachedAttachment(remoteContent.contentDigest);
    if (cached != null) {
      return cached;
    }

    // 2. Cache miss - fetch from network
    final attachment = await RemoteAttachmentCodec.load(remoteContent);

    // 3. Store in cache for next time
    await PublicOSAttachmentCache.putCachedAttachment(
      contentDigest: remoteContent.contentDigest,
      attachment: attachment,
    );

    return attachment;
  }

  Widget _buildErrorContainer(ThemeData theme, String errorMessage, String filename) {
    // Container that adapts to message size
    return Container(
      constraints: BoxConstraints(
        maxWidth: 250,
        minWidth: 200,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[300]?.withValues(alpha: 0.12),
        borderRadius: bubbleBorderRadius,
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image, color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Text(
            errorMessage,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============ Reply Message Methods ============

  /// Build the complete reply message UI (quoted message + reply content)
  Widget _buildReplyContent(dynamic content, ThemeData theme, BuildContext context) {

    Reply? reply = _parseReplyContent(content);

    if (reply == null) {
      return Text(
        context.l10n.messageWidgetInvalidReplyFormat,
        style: TextStyle(
          color: _bubbleFg,
          fontSize: 16,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show the quoted/referenced message
        _buildReferencedMessageContainer(context, theme),
        const SizedBox(height: 8),
        // Show the reply content
        _buildReplyContentText(reply, theme),
      ],
    );
  }

  /// Parse Reply object from various formats
  Reply? _parseReplyContent(dynamic content) {
    if (content is Reply) {
      return content;
    } else if (content is Map<String, dynamic>) {
      try {
        return Reply.fromJson(content);
      } catch (e) {
      }
    } else if (content is String && content.startsWith('{')) {
      try {
        final Map<String, dynamic> jsonData = jsonDecode(content);
        return Reply.fromJson(jsonData);
      } catch (e) {
      }
    }
    return null;
  }

  /// Container that fetches and displays the referenced message
  Widget _buildReferencedMessageContainer(BuildContext context, ThemeData theme) {
    if (widget.message.referenceMessageId == null) {
      return _buildReferencedMessageNotFound(theme);
    }

    return FutureBuilder<Message?>(
      future: _referencedMessageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildReferencedMessageLoading(theme);
        }

        if (snapshot.hasError) {
          return _buildReferencedMessageNotFound(theme);
        }

        if (snapshot.hasData && snapshot.data != null) {
          return _buildQuotedMessage(snapshot.data!, context, theme);
        }

        return _buildReferencedMessageNotFound(theme);
      },
    );
  }

  /// Display the quoted/referenced message
  Widget _buildQuotedMessage(Message refMsg, BuildContext context, ThemeData theme) {
    // Determine content preview based on message type
    String contentPreview;
    IconData? contentIcon;

    switch (refMsg.content.type) {
      case MessageType.text:
        contentPreview = _truncateText(refMsg.content.value.toString(), 150);
        break;
      case MessageType.attachment:
        contentPreview = context.l10n.messageWidgetQuotedAttachment;
        contentIcon = Icons.attach_file;
        break;
      case MessageType.remoteAttachment:
      case MessageType.multiRemoteAttachment:
        contentPreview = context.l10n.messageWidgetQuotedAttachment;
        contentIcon = Icons.attach_file;
        break;
      case MessageType.reaction:
        contentPreview = context.l10n.messageWidgetQuotedReaction;
        break;
      case MessageType.reply:
        contentPreview = context.l10n.messageWidgetQuotedReply;
        break;
      default:
        contentPreview = context.l10n.messageWidgetMessage;
    }

    // The quote sits inside the bubble, so its rule and wash derive from the
    // bubble's foreground — a white wash is invisible on a light fill.
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: _bubbleFg.withValues(alpha: 0.4),
            width: 3,
          ),
        ),
        color: _bubbleFgFaint,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show sender name in group chats
          if (widget.isGroupChat && refMsg.senderInboxId != null) ...[
            _buildQuotedSender(refMsg),
            const SizedBox(height: 4),
          ],
          // Show content preview
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (contentIcon != null) ...[
                Icon(
                  contentIcon,
                  size: 14,
                  color: _bubbleFgSub,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  contentPreview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: _bubbleFgSub,
                    fontStyle: contentIcon != null ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Display sender info for quoted message in group chats
  Widget _buildQuotedSender(Message refMsg) {
    // For my own messages
    if (widget.myInboxId != null && refMsg.senderInboxId == widget.myInboxId) {
      return Text(
        context.l10n.messageWidgetYou,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _bubbleFg,
        ),
      );
    }

    // Look up sender from chat screen's contact cache
    final contact = widget.contactLookup?.call(refMsg.senderInboxId!);
    final senderName = contact?.displayName ?? _formatSenderAddress(refMsg.senderAddress);

    return Text(
      senderName,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _bubbleFgSub,
      ),
    );
  }

  /// Show loading state while fetching referenced message
  Widget _buildReferencedMessageLoading(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: _bubbleFg.withValues(alpha: 0.4),
            width: 3,
          ),
        ),
        color: _bubbleFgFaint,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: _bubbleFg),
          ),
          const SizedBox(width: 8),
          Text(
            context.l10n.messageWidgetLoading,
            style: TextStyle(
              fontSize: 13,
              color: _bubbleFgSub,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Show placeholder when referenced message not found.
  ///
  /// Deliberately NOT red: this quote frame sits on the sender's brand fill, and
  /// red-on-red is invisible. The error-outline icon and the italic copy carry
  /// the meaning; a colour that disappears carries nothing.
  Widget _buildReferencedMessageNotFound(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: _bubbleFg.withValues(alpha: 0.4),
            width: 3,
          ),
        ),
        color: _bubbleFgFaint,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 14,
            color: _bubbleFgSub,
          ),
          const SizedBox(width: 8),
          Text(
            context.l10n.messageWidgetMessageNotAvailable,
            style: TextStyle(
              fontSize: 13,
              color: _bubbleFgSub,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Display the actual reply content text
  Widget _buildReplyContentText(Reply reply, ThemeData theme) {
    // Handle different content types in the reply
    String replyText;

    if (reply.content is String) {
      replyText = reply.content as String;
    } else if (reply.content is Map) {
      // If it's a complex content type, show it appropriately
      replyText = reply.content.toString();
    } else {
      replyText = reply.content.toString();
    }

    // The reply's own body is text in a bubble like any other — trim it. The
    // quoted message above keeps its own fixed 150-char preview.
    return _buildTrimmableText(replyText, fontSize: 16);
  }

  /// Truncate text to a maximum length
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Build text content — single-URL messages get a preview card, mixed text gets clickable links only.
  Widget _buildTextWithLinkPreview(String text) {
    final trimmed = text.trim();
    final urlMatch = LinkPreviewUtils.urlRegex.firstMatch(trimmed);

    // Single URL, nothing else → show clickable link + preview card
    if (urlMatch != null &&
        urlMatch.start == 0 &&
        urlMatch.end == trimmed.length) {
      final url = urlMatch.group(0)!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextWithClickableLinks(text),
          LinkPreviewWidget(url: url),
        ],
      );
    }

    return _buildTextWithClickableLinks(text);
  }

  /// Build text with clickable URL links, honoring the trim setting.
  Widget _buildTextWithClickableLinks(String text) =>
      _buildTrimmableText(text, fontSize: 16);

  /// Text in a bubble — the one place the "trim long messages" reading setting
  /// applies. Over budget, the text renders cut and its last line FADES out,
  /// with a chevron in its own row underneath that expands it in place (and
  /// flips up to collapse it back). URLs stay clickable in both states.
  ///
  /// The chevron sits BELOW the text, never on the faded line. The "Show
  /// more / Show less" strings are the chevron's semantics label.
  Widget _buildTrimmableText(String text, {required double fontSize}) {
    // DELTA(desktop): per-side text metrics through the ChatAppearance
    // seam; null = the client's defaults (the fontSize param, theme font).
    final baseStyle = TextStyle(
      color: _bubbleFg,
      fontSize: ChatAppearance.instance.textSizeFor(isMe) ?? fontSize,
      fontFamily: ChatAppearance.instance.fontFamilyFor(isMe),
      fontWeight: ChatAppearance.instance.fontWeightFor(isMe),
    );
    // Non-null = trimmable. _textExpanded only decides whether the cut is
    // applied; a trimmable text always carries the chevron.
    final cut = messageTrimCut(text, widget.trimMaxChars);
    final collapsed = cut != null && !_textExpanded;
    final visible = collapsed ? text.substring(0, cut).trimRight() : text;

    final Widget body =
        Text.rich(TextSpan(children: _linkSpans(visible, baseStyle)));
    if (cut == null) return body;

    void toggle() => setState(() => _textExpanded = !_textExpanded);

    // Collapsed: fade only the LAST line (~1.8 line-heights of ramp), not a
    // fixed share of the text. A 280-char cut runs 5+ lines, and a 45% fade
    // would dim half the message. DELTA(desktop): measured off the EFFECTIVE
    // size (ChatAppearance may override the fontSize param).
    final double lineSize = baseStyle.fontSize ?? fontSize;
    final Widget shown = collapsed
        ? GestureDetector(
            onTap: toggle,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) {
                final double fadeStart = rect.height <= 0
                    ? 0
                    : (1 - (lineSize * 1.8) / rect.height).clamp(0.0, 1.0);
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [Colors.white, Colors.white, Colors.transparent],
                  stops: [0, fadeStart, 1],
                ).createShader(rect);
              },
              child: body,
            ),
          )
        : body;

    // The chevron is drawn in its own 22 px row; the TAP target is a separate
    // transparent layer over that row, spanning the full text width and 4 px
    // up into the text, so the hit area is bigger than the glyph. Layout is
    // identical to the bare icon. A target can't extend below, into the
    // bubble's padding: that's outside this widget, and hit tests stop at
    // its bounds.
    const double chevronRow = 22;
    const double hitAbove = 4;
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            shown,
            AnimatedRotation(
              turns: collapsed ? 0 : 0.5,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: chevronRow,
                color: _bubbleFg,
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: chevronRow + hitAbove,
          child: Semantics(
            button: true,
            label: collapsed
                ? context.l10n.messageWidgetShowMore
                : context.l10n.messageWidgetShowLess,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: toggle,
            ),
          ),
        ),
      ],
    );
  }

  /// Split [text] into plain runs + clickable URL runs.
  List<InlineSpan> _linkSpans(String text, TextStyle baseStyle) {
    final matches = LinkPreviewUtils.urlRegex.allMatches(text).toList();
    if (matches.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before the URL
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      // Add the clickable URL
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        // Links take the bubble's foreground, not blue: a blue link on a blue
        // bubble is invisible, and on the light half of the palette it fails
        // contrast outright. The underline carries the affordance instead.
        style: baseStyle.copyWith(
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: _bubbleFg,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
      ));

      lastEnd = match.end;
    }

    // Add remaining text after last URL
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    return spans;
  }

  Widget _buildStatus() {
    if (widget.message.sendFailed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            context.l10n.messageWidgetFailedToSend,
            style: TextStyle(
              color: Colors.red.shade300,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    if (widget.message.isPending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          const SizedBox(width: 6),
          Text(
            context.l10n.messageWidgetSending,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // ---------------------------------------------------------------------------
  // Bookmarks
  // ---------------------------------------------------------------------------
  // The chat owns ONE Set of bookmarked network ids (widget.bookmarkIds,
  // loaded/persisted by chat_screen) and hands it down like the video-aspect
  // cache. The toggle mutates that Set and repaints THIS bubble via its own
  // setState: a parent setState would not reach it, because chat_screen
  // caches MessageWidget instances (gotcha "chat_screen.dart caches
  // MessageWidgets").

  bool get _canBookmark =>
      widget.bookmarkIds != null &&
      widget.onBookmarksChanged != null &&
      widget.message.idXmtp != null &&
      !widget.message.isPending;

  bool get _bookmarked =>
      widget.message.idXmtp != null &&
      (widget.bookmarkIds?.contains(widget.message.idXmtp) ?? false);

  void _toggleBookmark() {
    final id = widget.message.idXmtp;
    final ids = widget.bookmarkIds;
    if (id == null || ids == null) return;
    setState(() {
      if (!ids.remove(id)) ids.add(id);
    });
    widget.onBookmarksChanged?.call();
  }

  /// The small bookmark mark beside the time: LEFT of it on my messages,
  /// RIGHT of it on incoming ones (the outer side, away from the time).
  Widget _buildBookmarkMark() => Icon(
        Icons.bookmark_rounded,
        size: 13,
        color: GlassTokens.dark.connectedAccent,
      );

  Widget _buildTimestamp() {
    return Text(
      _formatTime(widget.message.timestamp),
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
      ),
    );
  }

  /// The "seen" marker: small peer avatar + label, animated by [_seenCtrl].
  /// Entry: the clip box widens from the outer edge, the avatar slides in
  /// first and the label trails it, with a soft fade on the edge (not a hard
  /// clip line) while moving. Exit runs the same timeline backwards. When the
  /// timestamp is hidden the marker is the whole bottom row, so it also grows
  /// the row's height (see [_buildBottomSpacer]) instead of popping it.
  Widget _buildSeenIndicator() {
    final ctrl = _ensureSeenCtrl();
    final peer = _seenPeer;
    final avatar = peer != null
        ? GlassContactIcon(contact: peer, size: 16)
        : CircleAvatar(
            radius: 6,
            backgroundColor: Colors.grey[600],
            child: const Icon(Icons.person, size: 16, color: Colors.white70),
          );
    final label = Text(
      context.l10n.messageWidgetSeen,
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey[400],
      ),
    );
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final t = ctrl.value;
        if (t == 0) return const SizedBox.shrink();
        final w = const Interval(0.0, 0.6, curve: Curves.easeOutCubic).transform(t);
        final a = const Interval(0.0, 0.7, curve: Curves.easeOutCubic).transform(t);
        final b = const Interval(0.25, 1.0, curve: Curves.easeOutCubic).transform(t);
        final h = _showTimestamp
            ? 1.0
            : const Interval(0.0, 0.5, curve: Curves.easeOut).transform(t);
        Widget marker = ClipRect(
          child: Align(
            alignment: Alignment.centerRight,
            widthFactor: w,
            heightFactor: h,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FractionalTranslation(
                // a = 0: the row starts just past the outer edge.
                translation: Offset(1 - a, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    avatar,
                    const SizedBox(width: 4),
                    FractionalTranslation(
                      // The label lags the avatar, then catches up.
                      translation: Offset(1.5 * (1 - b), 0),
                      child: label,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        // Soft edge while moving; gone at rest so the label is never faded.
        final fade = 10.0 * (1 - b);
        if (fade > 0.1) {
          marker = ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) {
              final stop =
                  rect.width <= fade ? 0.0 : (rect.width - fade) / rect.width;
              return LinearGradient(
                colors: const [Colors.white, Colors.transparent],
                stops: [stop, 1.0],
              ).createShader(rect);
            },
            child: marker,
          );
        }
        return marker;
      },
    );
  }

  /// Gap above the bottom row. When the seen marker is the row's only content
  /// (timestamp hidden) it grows with the marker's height.
  Widget _buildBottomSpacer(double height) {
    final ctrl = _seenCtrl;
    if (_showTimestamp || ctrl == null) return SizedBox(height: height);
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) => SizedBox(
        height: height *
            const Interval(0.0, 0.5, curve: Curves.easeOut).transform(ctrl.value),
      ),
    );
  }

  /// Glass-pill chip that floats at the bubble's outer bottom corner via the
  /// Stack in [_withReactionOverlay]. Surface is dark + bordered so the chip
  /// stays legible regardless of the bubble's per-user brand tint.
  Widget _buildReactionsChip(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final reactions = widget.message.reactions ?? [];
    return Container(
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.map((reaction) {
          return GestureDetector(
            onTap: () => _showReactionDetails(context, reaction.emoji),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reaction.emoji,
                    style: TextStyle(
                      fontSize: 16,
                      shadows: reaction.hasMyReaction
                          ? [
                              Shadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  if (reaction.count > 1) ...[
                    const SizedBox(width: 2),
                    Text(
                      '${reaction.count}',
                      style: TextStyle(
                        fontSize: 10,
                        color: reaction.hasMyReaction ? Colors.blue.shade300 : Colors.white60,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showReactionDetails(BuildContext context, String emoji) {
    final reactions = widget.message.reactions;
    if (reactions == null || reactions.isEmpty) return;

    // DELTA(desktop): centered card dialog instead of a bottom sheet — the
    // same `asCard` presentation post_card uses.
    showDialog(
      context: context,
      builder: (sheetCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: DialogWidth.m, maxHeight: 560),
          child: ReactionDetailsSheet(
            onContactTap: (c) {
              Navigator.of(sheetCtx).pop();
              AppNav.toContact(context, c);
            },
            asCard: true,
            reactions: reactions,
            contactLookup: widget.contactLookup,
            initialEmoji: emoji,
          ),
        ),
      ),
    );
  }

  void _sendReaction(BuildContext context, String emoji) async {
    if (widget.message.idXmtp == null) {
      return;
    }

    try {
      final reaction = Reaction(
        reference: widget.message.idXmtp!,
        content: emoji,
        action: ReactionAction.added,
      );

      // Find the target to send the reaction to
      if (widget.isGroupChat) {
        // For group chats, send to the group topic
        await PublicOSConversations.sendGroupMessage(
          widget.message.xmtpConversationTopic,
          reaction,
          'xmtp.org',
          'reaction',
        );
      } else {
        // For direct chats, send to the peer (not the message sender)
        final targetInboxId = widget.peerInboxId;
        if (targetInboxId == null || targetInboxId.isEmpty) {
          return;
        }
        await PublicOSConversations.sendMessageByInboxId(
          targetInboxId,
          widget.message.xmtpConversationTopic,
          reaction,
          'xmtp.org',
          'reaction',
        );
      }
    } catch (e) {
      // Silently handle error
    }
  }

  /// Save the long-pressed sticker into the user's local library.
  ///
  /// A sticker's bytes are already here — intake is inline-only under a 1 MB
  /// cap, so this is a byte copy with no network. The message's `description`
  /// is deliberately not carried over: a caption belonged to the message, not
  /// to the sticker.
  ///
  /// Dedup is silent (the `{digest, sessionAddress}` unique index), so a
  /// re-save reports "already saved" rather than failing.
  void _saveSticker(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final attachment = _parseAttachmentContent(widget.message.content.value);
    if (attachment == null || attachment.data.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.messageWidgetStickerSaveFailed),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final isNew = await PublicOSStickers.saveSticker(attachment);
      messenger.showSnackBar(SnackBar(
        content: Text(isNew
            ? l10n.messageWidgetStickerSaved
            : l10n.messageWidgetStickerAlreadySaved),
      ));
    } catch (e) {
      print('MessageWidget: Failed to save sticker: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.messageWidgetStickerSaveFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyMessageToClipboard(BuildContext context) {
    String textToCopy = '';

    // Determine what to copy based on message type
    switch (widget.message.content.type) {
      case MessageType.text:
        textToCopy = widget.message.content.value.toString();
        break;
      case MessageType.reply:
        // For reply messages, copy the reply content
        final reply = _parseReplyContent(widget.message.content.value);
        if (reply != null) {
          if (reply.content is String) {
            textToCopy = reply.content as String;
          } else {
            textToCopy = reply.content.toString();
          }
        } else {
          textToCopy = widget.message.content.value.toString();
        }
        break;
      case MessageType.attachment:
        // For attachments, copy the filename
        final attachmentContent = _parseAttachmentContent(widget.message.content.value);
        if (attachmentContent != null) {
          textToCopy = attachmentContent.filename;
        } else {
          textToCopy = context.l10n.messageWidgetClipboardAttachment;
        }
        break;
      case MessageType.remoteAttachment:
        // For remote attachments, copy the filename
        if (widget.message.content.value is RemoteAttachmentContent) {
          textToCopy = (widget.message.content.value as RemoteAttachmentContent).filename;
        } else if (widget.message.content.value is Map<String, dynamic>) {
          textToCopy = widget.message.content.value['filename']?.toString() ?? context.l10n.messageWidgetClipboardRemoteAttachment;
        } else {
          textToCopy = context.l10n.messageWidgetClipboardRemoteAttachment;
        }
        break;
      case MessageType.multiRemoteAttachment:
        // The caption when there is one, else the filenames.
        final v = widget.message.content.value;
        textToCopy = v is MultiRemoteAttachmentContent
            ? ((v.description ?? '').isNotEmpty
                ? v.description!
                : v.attachments.map((a) => a.filename).join(', '))
            : context.l10n.messageWidgetClipboardRemoteAttachment;
        break;
      case MessageType.reaction:
        textToCopy = context.l10n.messageWidgetClipboardReaction;
        break;
      default:
        textToCopy = widget.message.content.value.toString();
    }

    if (textToCopy.isEmpty) {
      textToCopy = context.l10n.messageWidgetMessage;
    }

    // Copy to clipboard
    // Not awaited, so a platform failure would otherwise be an unhandled
    // async error that no hook logs.
    Clipboard.setData(ClipboardData(text: textToCopy)).catchError(
      (Object e) => Log.e('MessageWidget', 'clipboard write failed: $e'),
    );
  }

  Future<void> _showReactionPicker(
      BuildContext context, double tapGlobalY) async {
    // History first, then the defaults not already in it: the same
    // `emoji_picker_history` the feed pickers read, so one habit list drives
    // every quick row. Same 12 slots, so the bar's width math is unchanged.
    const defaults = ['❤️', '👍', '👎', '😂', '😮', '😢', '😡', '🔥', '💯', '👏', '🎉', '✨'];
    final history = await mostUsedEmojis(limit: defaults.length);
    if (!context.mounted) return;
    final commonEmojis = [
      ...history,
      ...defaults.where((e) => !history.contains(e)),
    ].take(defaults.length).toList();
    // Captured for after the bar pops: opening the full emoji picker needs a
    // still-mounted context, and the dialog's own context dies on pop.
    final outerContext = context;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    // Responsive sizing — scale down for narrow screens
    final isCompact = screenWidth < 380;
    // DELTA(desktop): a tighter bar than the client's touch sizing; a mouse
    // needs no 48 px target.
    final barHeight = isCompact ? 40.0 : 42.0;
    final emojiSize = isCompact ? 20.0 : 22.0;
    final emojiItemWidth = isCompact ? 28.0 : 30.0;
    final actionButtonWidth = isCompact ? 30.0 : 32.0;
    final actionIconSize = isCompact ? 18.0 : 20.0;
    const edgePadding = 12.0;
    const dividerGap = 8.0;

    // Determine which action buttons are shown
    final hasReply = !widget.message.isPending &&
        widget.message.idXmtp != null &&
        widget.onReplySelected != null;
    // Bookmark needs a stable id (the network one) and the chat's store.
    final hasBookmark = _canBookmark;
    // Save-sticker shows for any sticker, sent or received, captioned or not
    // (isSticker and description are independent — a caption never clears the
    // flag). Unlike reply it needs no idXmtp: the bytes are already local, so a
    // still-pending sticker is just as savable.
    final isSticker = widget.message.content.type == MessageType.attachment &&
        _isStickerAttachment(widget.message.content.value);

    // Calculate available width for the emoji area
    final actionButtonsWidth = actionButtonWidth // copy
        + (hasReply ? actionButtonWidth : 0) // reply
        + (hasBookmark ? actionButtonWidth : 0) // bookmark
        + (isSticker ? actionButtonWidth : 0) // save sticker
        + dividerGap * 2; // divider padding
    // commonEmojis + the trailing "+" (full picker) all scroll together, so the
    // "+" counts as one more item that can scroll into view at the end.
    final scrollItemCount = commonEmojis.length + 1;
    final maxBarWidth = screenWidth - edgePadding * 2;
    final emojiAreaMaxWidth = maxBarWidth - actionButtonsWidth;
    final visibleEmojiCount =
        (emojiAreaMaxWidth / emojiItemWidth).floor().clamp(4, scrollItemCount);
    final emojiAreaWidth = (visibleEmojiCount * emojiItemWidth) + 12; // +12 for scroll padding
    final totalBarWidth =
        (emojiAreaWidth + actionButtonsWidth).clamp(0.0, maxBarWidth);

    // Vertical position: just above the user's finger, clamped to safe area.
    // tapGlobalY is the long-press contact point; lift the bar fully above it
    // (plus a gap) so the finger never occludes the emoji row.
    const fingerGap = 16.0;
    final barTop = (tapGlobalY - barHeight - fingerGap).clamp(
      topPadding + 8,
      screenHeight - barHeight - 16,
    );

    // Horizontal position: align to the message's own edge, clamped to screen.
    // DELTA(desktop): anchored to this widget's global rect, not the window.
    // The chat is a pane right of the sidebar, so a window-left anchor throws
    // incoming bars over the contact list. The client is
    // full-screen, where the two coincide.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final regionLeft = box == null ? edgePadding : origin.dx;
    final regionRight =
        box == null ? screenWidth - edgePadding : origin.dx + box.size.width;
    double barLeft;
    if (isMe) {
      barLeft = regionRight - totalBarWidth;
    } else {
      barLeft = regionLeft;
    }
    barLeft = barLeft.clamp(edgePadding, screenWidth - totalBarWidth - edgePadding);

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.05),
      barrierDismissible: true,
      barrierLabel: context.l10n.messageWidgetDismissReactions,
      transitionDuration: const Duration(milliseconds: 120),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        final tokens = GlassTokens.of(context);
        return Stack(
          children: [
            // Tap-to-dismiss layer
            GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
            // Unified action bar — glass pill matching the rest of the app
            Positioned(
              top: barTop,
              left: barLeft,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: barHeight,
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  decoration: BoxDecoration(
                    color: tokens.background,
                    borderRadius: BorderRadius.circular(barHeight / 2),
                    border: Border.all(
                      color: tokens.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(barHeight / 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Scrollable emoji row
                        SizedBox(
                          width: emojiAreaWidth,
                          child: HorizontalWheel(child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...commonEmojis.map((emoji) => GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                        // Counts as a use, like a pick in
                                        // the feed pickers.
                                        recordEmojiUse(emoji);
                                        _sendReaction(context, emoji);
                                      },
                                      child: Container(
                                        width: emojiItemWidth,
                                        height: barHeight,
                                        alignment: Alignment.center,
                                        // height 1 + even leading: the emoji
                                        // font's tall descent otherwise sits
                                        // the glyph below the bar's midline.
                                        // Grows 4 px under the pointer
                                        // (the pickers' hover).
                                        child: HoverGrow(
                                          size: emojiSize,
                                          child: Text(
                                            emoji,
                                            style: TextStyle(
                                              fontSize: emojiSize,
                                              height: 1.0,
                                              leadingDistribution:
                                                  TextLeadingDistribution.even,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )),
                                // "+" — the LAST scrolling item; opens the full
                                // emoji picker (same one used for feed icons) and
                                // sends whatever is selected.
                                GestureDetector(
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final picked =
                                        await showEmojiPickerDialog(outerContext);
                                    if (picked != null &&
                                        picked.isNotEmpty &&
                                        outerContext.mounted) {
                                      _sendReaction(outerContext, picked);
                                    }
                                  },
                                  child: Container(
                                    width: emojiItemWidth,
                                    height: barHeight,
                                    alignment: Alignment.center,
                                    child: HoverGrow(
                                      size: actionIconSize,
                                      child: Icon(
                                        Icons.add_rounded,
                                        color: Colors.white70,
                                        size: actionIconSize,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ),
                        // Thin divider between emojis and actions
                        Container(
                          width: 1,
                          height: barHeight * 0.45,
                          margin: EdgeInsets.symmetric(horizontal: dividerGap),
                          color: tokens.borderSubtle,
                        ),
                        // Save sticker — left of Reply. Only for stickers.
                        if (isSticker)
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _saveSticker(outerContext);
                              // Popping this dialog hands focus back to the
                              // composer, which pops the keyboard open behind
                              // the snackbar. Same guard the Copy button uses.
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            child: SizedBox(
                              width: actionButtonWidth,
                              height: barHeight,
                              child: HoverGrow(
                                size: actionIconSize - 2,
                                child: StickerAddIcon(
                                  size: actionIconSize - 2,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        // Bookmark toggle — left of Reply.
                        if (hasBookmark)
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _toggleBookmark();
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            child: SizedBox(
                              width: actionButtonWidth,
                              height: barHeight,
                              child: HoverGrow(
                                size: actionIconSize - 1,
                                child: Icon(
                                  _bookmarked
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  color: _bookmarked
                                      ? GlassTokens.dark.connectedAccent
                                      : Colors.white70,
                                  size: actionIconSize - 1,
                                ),
                              ),
                            ),
                          ),
                        // Reply button
                        if (hasReply)
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              widget.onReplySelected!(widget.message);
                            },
                            child: SizedBox(
                              width: actionButtonWidth,
                              height: barHeight,
                              child: HoverGrow(
                                size: actionIconSize,
                                child: Icon(
                                  Icons.reply_rounded,
                                  color: Colors.white70,
                                  size: actionIconSize,
                                ),
                              ),
                            ),
                          ),
                        // Copy button
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _copyMessageToClipboard(context);
                            // Prevent input from gaining focus after dialog dismiss
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          child: SizedBox(
                            width: actionButtonWidth,
                            height: barHeight,
                            child: HoverGrow(
                              size: actionIconSize - 2,
                              child: Icon(
                                Icons.copy_rounded,
                                color: Colors.white70,
                                size: actionIconSize - 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Hold-to-confirm button for interactive bot menu actions. A plain tap is
/// too easy to fire by accident while scrolling a conversation, so the
/// intent is only sent after a continuous 500 ms press. While held, a
/// slightly lighter fill sweeps left to right as progress feedback; lifting
/// early animates the fill back to zero and sends nothing.
///
/// Gesture model: this is driven by a **long-press** recognizer, not a tap.
/// The button sits inside the message bubble's own `onLongPress` reaction
/// picker — a nested long-press recognizer is resolved first in the gesture
/// arena, so pressing a button WINS over (and suppresses) the bubble's
/// reaction picker. That's deliberate: holding a button must fire only its
/// intent, never the reaction menu (the bubble stays reactable everywhere
/// else — description, padding, the rest of the message). The fill is driven
/// from `onLongPressDown` (press contact) and the intent from `onLongPress`
/// (the recognized hold), so the send is decoupled from the fill controller.
/// Loading skeleton for one gallery tile: a [ShimmerBox] with its own
/// repeating sweep (a tile loads independently of its siblings).
class _GalleryShimmer extends StatefulWidget {
  final double width;
  final double height;
  final Color base;
  final Color highlight;

  const _GalleryShimmer({
    required this.width,
    required this.height,
    required this.base,
    required this.highlight,
  });

  @override
  State<_GalleryShimmer> createState() => _GalleryShimmerState();
}

class _GalleryShimmerState extends State<_GalleryShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ShimmerBox(
        progress: _c,
        width: widget.width,
        height: widget.height,
        radius: 0,
        base: widget.base,
        highlight: widget.highlight,
      );
}

class _HoldToSendActionButton extends StatefulWidget {
  final String label;
  final String? imageUrl;
  final bool isPrimary;

  /// The bubble's foreground (black or white, per `_bubbleFg`). The button sits
  /// on the solid brand fill, so it can't reach for theme colors or assume
  /// light-on-dark — it derives everything from this.
  final Color foreground;
  final VoidCallback? onComplete;

  const _HoldToSendActionButton({
    required this.label,
    this.imageUrl,
    required this.isPrimary,
    required this.foreground,
    this.onComplete,
  });

  @override
  State<_HoldToSendActionButton> createState() => _HoldToSendActionButtonState();
}

class _HoldToSendActionButtonState extends State<_HoldToSendActionButton>
    with SingleTickerProviderStateMixin {
  static const Duration _holdDuration = Duration(milliseconds: 500);
  static const Duration _releaseDuration = Duration(milliseconds: 200);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _holdDuration,
    reverseDuration: _releaseDuration,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Press contact (fires immediately on pointer-down, before the long-press is
  // recognized) — begin the fill sweep so progress shows under the finger.
  void _onPressStart() {
    if (widget.onComplete == null) return;
    HapticFeedback.selectionClick();
    _controller.forward(from: 0);
  }

  // Long-press recognized (held ~`kLongPressTimeout`, matched to the fill
  // duration) — THIS is where the intent fires. Firing off the long-press
  // recognizer (rather than the controller's completion) is what lets the
  // button win the gesture arena over the bubble's reaction-picker long-press.
  void _onFire() {
    if (widget.onComplete == null) return;
    HapticFeedback.mediumImpact();
    widget.onComplete?.call();
    _controller.reverse();
  }

  // Lifted / aborted before the press was recognized — animate the fill back,
  // send nothing.
  void _onPressEnd() {
    if (_controller.status == AnimationStatus.forward) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.isPrimary;
    final fg = widget.foreground;

    final backgroundColor =
        isPrimary ? fg.withValues(alpha: 0.2) : Colors.transparent;
    final borderColor = fg.withValues(alpha: isPrimary ? 0.6 : 0.4);
    // The hold-to-send progress sweep.
    final fillColor = fg.withValues(alpha: 0.35);
    final borderRadius = BorderRadius.circular(10);

    // Long-press callbacks only when the button can actually fire. When it
    // can't (read-only / no send handler) we attach no recognizer, so a
    // long-press there falls through to the bubble's reaction picker as before.
    final canFire = widget.onComplete != null;
    return GestureDetector(
      onLongPressDown: canFire ? (_) => _onPressStart() : null,
      onLongPressCancel: canFire ? _onPressEnd : null,
      onLongPress: canFire ? _onFire : null,
      onLongPressUp: canFire ? _onPressEnd : null,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _controller.value,
                      heightFactor: 1,
                      child: ColoredBox(color: fillColor),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: ZeroCachedImage(
                          imageUrl: widget.imageUrl!,
                          width: 20,
                          height: 20,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          color: fg,
                          fontSize: 14,
                          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
