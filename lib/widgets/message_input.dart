import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cross_file/cross_file.dart';
import 'package:publicos_desktop/utils/image_utils.dart';
import 'package:publicos_desktop/utils/media_picker.dart';
import 'package:publicos_desktop/utils/clipboard_media.dart';
import 'package:publicos_desktop/utils/document_picker.dart';
import 'package:publicos_desktop/widgets/transactions/send_sheet.dart';
import 'package:publicos_desktop/widgets/transactions/request_payment_sheet.dart';
// DELTA(desktop): the client mounts KeychainSheet as a bottom sheet; desktop's
// keychain is a dialog (widgets/keychain_dialog.dart) behind
// every door — same one the sidebar row and the wallet open.
import 'package:publicos_desktop/widgets/keychain_dialog.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_widget.dart';
import 'package:publicos_desktop/widgets/send_icon.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/quality_toggle.dart';
import 'package:publicos_desktop/widgets/sticker_gif_toggle.dart';
import 'package:publicos_desktop/widgets/sticker_icon.dart';
import 'package:publicos_desktop/widgets/messages/sticker_panel.dart';
import 'package:publicos_desktop/widgets/tappable_media.dart';
import 'package:xmtp_plugin/codecs.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

/// Kinds offered in the composer's attachment options row (spawned by the
/// attach icon). Image is wired to the existing media flow; the rest are
/// placeholders until their steps land.
enum _AttachOption { image, document, send, request, contact, location }

/// Floating chips row — meant to be overlaid on the messages area.
/// Chips float with no background; messages scroll behind them.
/// Key / attach live in the input bar (`MessageInput`) and settings in the
/// browser address-bar gear; only the jump-to-bottom chip floats here.
class FloatingChipsRow extends StatefulWidget {
  final bool showScrollToBottom;
  final VoidCallback? onScrollToBottom;

  const FloatingChipsRow({
    super.key,
    this.showScrollToBottom = false,
    this.onScrollToBottom,
  });

  @override
  State<FloatingChipsRow> createState() => _FloatingChipsRowState();
}

class _FloatingChipsRowState extends State<FloatingChipsRow>
    with SingleTickerProviderStateMixin {
  // Owning the reveal controller (instead of AnimatedSize) keeps the chip
  // mounted through the exit, so scroll-away plays the entry in reverse;
  // a tap snaps the value to 0 so the chip vanishes with the jump.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: widget.showScrollToBottom ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant FloatingChipsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showScrollToBottom != oldWidget.showScrollToBottom) {
      if (widget.showScrollToBottom) {
        _reveal.forward();
      } else {
        _reveal.reverse();
      }
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _handleScrollToBottomTap() {
    _reveal.value = 0; // instant — the chip leaves with the jump
    widget.onScrollToBottom?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8),
      child: Row(
        children: [
          const Spacer(),
          // Jump-to-bottom — SizeTransition (clip + align) anchored left so
          // the right edge is what reveals on entry and hides in reverse.
          SizeTransition(
            sizeFactor:
                CurvedAnimation(parent: _reveal, curve: Curves.easeInOut),
            axis: Axis.horizontal,
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildActionChip(
                tokens: tokens,
                icon: Icons.keyboard_arrow_down_rounded,
                onTap: _handleScrollToBottomTap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Canonical glass chip-bar pattern — `surfaceElevated` fill when active /
  /// highlighted, transparent otherwise; border tightens from `borderSubtle`
  /// to `borderMedium` on emphasis. Pass `label: null` for an icon-only chip.
  Widget _buildActionChip({
    required GlassTokens tokens,
    required IconData icon,
    required VoidCallback? onTap,
    String? label,
    bool highlight = false,
  }) {
    final enabled = onTap != null;
    final active = highlight && enabled;

    final fillColor = active ? tokens.surfaceElevated : tokens.background;
    final borderColor = active ? tokens.borderMedium : tokens.borderSubtle;
    final fgColor = enabled ? tokens.starkWhite : tokens.textDim;
    final iconColor = active ? tokens.connectedAccent : fgColor;

    return Material(
      color: fillColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: label == null ? 8 : 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: label == null ? 18 : 14, color: iconColor),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    letterSpacing: 0.3,
                    color: fgColor,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MessageInput extends StatefulWidget {
  final bool isInputEnabled;
  final Contact? contact; // Used for fallback display / recipient resolution
  final String? targetInboxId; // Peer's inbox ID for 1-on-1 chats
  final String? conversationTopic; // DM topic if already known
  final Message? replyToMessage; // Message being replied to
  final VoidCallback? onClearReply; // Callback to clear reply state
  final Function(String topic)? onConversationCreated; // Called when DM topic resolved on first send
  final VoidCallback? onAttach; // External attach trigger (from floating chips)
  final VoidCallback? onActiveKeyChanged; // Called after the user switches the active XMTP key (host re-checks self-chat)
  final String? initialDraft; // Pre-fills the composer once on mount (e.g. a deep-link ?message=). Never overrides a saved draft.

  const MessageInput({
    super.key,
    this.isInputEnabled = true,
    this.contact,
    this.targetInboxId, // For sending to a specific inbox ID
    this.conversationTopic,
    this.replyToMessage,
    this.onClearReply,
    this.onConversationCreated,
    this.onAttach,
    this.onActiveKeyChanged,
    this.initialDraft,
  });

  @override
  MessageInputState createState() => MessageInputState();
}

class MessageInputState extends State<MessageInput> with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  bool _isComposing = false;
  bool _isSending = false;

  // Pending attachment state
  AttachmentContent? _pendingAttachment;
  Uint8List? _pendingOriginalBytes; // Full-resolution bytes for HD upload
  // True while a large image is being compressed in the background. The preview
  // shows instantly (with the original bytes) but sending is blocked until the
  // optimized bytes land. _compressSeq invalidates an in-flight compress when
  // the user clears/replaces the attachment mid-pass.
  bool _compressingAttachment = false;
  int _compressSeq = 0;
  bool _hdMode = false;
  // HD toggle is only meaningful when the original is big enough that inline
  // would compress it AND the compressed version still fits inline. Hidden when
  // the original already fits (no quality choice) or when compression can't get
  // under the cap (server-forced, no choice). Set at stage time.
  bool _showHdToggle = false;
  // For an inserted GIF, the compose preview offers a Sticker|GIF toggle so the
  // user picks how it sends. PNG/WebP are always stickers (no toggle).
  bool _pendingIsGif = false;
  bool _sendAsSticker = true;
  bool _hasServer = false; // Whether a feed server is configured
  bool _showAttachOptions = false; // Attachment options row open/closed

  // Several media picked at once → ONE multi-attachment message
  // (xmtp.org/multiRemoteStaticAttachment). Every file is uploaded, so this
  // only exists with a feed server; the text field becomes the caption.
  // Mutually exclusive with _pendingAttachment.
  static const int _maxGalleryItems = 10;
  List<PickedMedia> _pendingGallery = const [];
  bool get _hasPending => _pendingAttachment != null || _pendingGallery.isNotEmpty;

  // --- Sticker panel -------------------------------------------------------
  // The panel and the keyboard are mutually exclusive: exactly one of them
  // occupies the bottom of the screen at a time. Focusing the field closes the
  // panel; opening the panel unfocuses the field. Both transitions run through
  // _openStickerPanel / _closeStickerPanel so the invariant lives in one place.
  bool _showStickerPanel = false;
  final FocusNode _inputFocus = FocusNode();
  // Last observed keyboard height, so the panel can stand in for the keyboard
  // at exactly its size and the swap reads as one surface replacing another.
  // Only knowable after the keyboard has been shown once; until then, and on
  // desktop/web where there is no software keyboard, _fallbackPanelHeight.
  double _lastKeyboardHeight = 0;
  static const double _fallbackPanelHeight = 280;
  // Floor for BOTH the measured keyboard height and the rendered panel. Doubles
  // as the "is this a real keyboard?" test in didChangeMetrics — Android
  // animates the IME inset, so without a floor we latch a sub-pixel tail frame.
  static const double _minPanelHeight = 180;

  // Private variable to hold the contact
  Contact? _selectedChatContact;
  String? _currentTopic;

  @override
  void initState() {
    super.initState();
    // Initialize _selectedChatContact from widget.contact or fall back to PublicOS.selectedProfile
    _selectedChatContact = widget.contact;
    _currentTopic = widget.conversationTopic;
    _textController.addListener(_handleTextChange);
    // The field taking focus means the keyboard is coming up — the panel must
    // get out of its way. The other direction (panel opening → keyboard down)
    // is driven from _openStickerPanel.
    _inputFocus.addListener(_handleFocusChange);
    // Desktop: Enter sends, Shift+Enter is a newline (see _handleInputKey).
    _inputFocus.onKeyEvent = _handleInputKey;
    // Observe window metrics to learn the keyboard's height (see
    // didChangeMetrics — the inset is unreadable from our own MediaQuery).
    WidgetsBinding.instance.addObserver(this);

    // Load a saved draft if one exists; otherwise seed the initial draft passed
    // in (e.g. a deep-link ?message=). A saved draft always wins, so we never
    // clobber something the user was mid-typing.
    final topic = _currentTopic;
    String? draft;
    if (topic != null) {
      draft = PublicOSConversations.getDraft(topic);
    }
    draft ??= widget.initialDraft;
    if (draft != null && draft.isNotEmpty) {
      _textController.text = draft;
      _textController.selection = TextSelection.collapsed(offset: draft.length);
    }

    // Check if a feed server is configured (for HD mode)
    _checkServerAvailability();
  }

  @override
  void didUpdateWidget(covariant MessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contact != oldWidget.contact) {
      _selectedChatContact = widget.contact;
    }
    if (widget.conversationTopic != oldWidget.conversationTopic) {
      _currentTopic = widget.conversationTopic;
    }
  }

  /// Send a payload over the current conversation. Branches on chat type:
  /// groups use `sendGroupMessage(topic, …)`; DMs use
  /// `sendMessageByInboxId(inboxId, topic, …)`. Throws if neither path can
  /// fire (caller shows a recipient-missing error).
  Future<void> _send(dynamic content, String authorityId, String typeId) async {
    final isGroup = _selectedChatContact?.isGroupChat == true;
    if (isGroup) {
      if (_currentTopic == null) {
        throw StateError('Group chat missing conversation topic');
      }
      await PublicOSConversations.sendGroupMessage(
        _currentTopic!, content, authorityId, typeId,
      );
      return;
    }
    if (widget.targetInboxId != null &&
        widget.targetInboxId!.isNotEmpty &&
        _currentTopic != null) {
      final sent = await PublicOSConversations.sendMessageByInboxId(
        widget.targetInboxId!, _currentTopic!, content, authorityId, typeId,
      );
      // Send is find-or-create: if it resolved a different (live) topic than
      // the stale one we cached, adopt it and let the chat screen re-point.
      final live = sent?.xmtpConversationTopic;
      if (live != null && live.isNotEmpty && live != _currentTopic) {
        setState(() => _currentTopic = live);
        widget.onConversationCreated?.call(live);
      }
      return;
    }
    throw StateError('DM missing targetInboxId or topic');
  }

  Future<void> _checkServerAvailability() async {
    // "Has a server" means anything uploadMedia could resolve: SSP
    // subscription OR a custom feed server. getFeedServers() only sees the
    // local custom-servers table, which misses subscribed-only users.
    final activeUrl = await PublicOSSsp.getActiveFeedServerUrl();
    if (mounted) {
      setState(() => _hasServer = activeUrl != null);
    }
  }

  void _handleTextChange() {
    final text = _textController.text;
    final shouldBeComposing = text.isNotEmpty || _hasPending;
    if (_isComposing != shouldBeComposing) {
      setState(() => _isComposing = shouldBeComposing);
    }
    // Save draft (debounced)
    final topic = _currentTopic;
    if (topic != null) {
      PublicOSConversations.saveDraft(topic, text);
    }
  }

  void _clearPendingAttachment() {
    _compressSeq++; // invalidate any in-flight background compress
    setState(() {
      _pendingAttachment = null;
      _pendingOriginalBytes = null;
      _pendingGallery = const [];
      _compressingAttachment = false;
      _hdMode = false;
      _showHdToggle = false;
      _pendingIsGif = false;
      _sendAsSticker = true;
      _isComposing = _textController.text.isNotEmpty;
    });
  }

  void _clearReply() {
    widget.onClearReply?.call();
  }

  /// Same gate the send button uses.
  bool get _canSend =>
      _isComposing &&
      widget.isInputEnabled &&
      !_isSending &&
      !_compressingAttachment;

  /// Desktop keyboard: the field is multiline, so a
  /// bare Enter would insert a newline and `onSubmitted` never fires. Enter
  /// sends when [_canSend]; with nothing to send it is swallowed so it doesn't
  /// leave a stray blank line. Shift+Enter falls through as a newline, and an
  /// Enter that commits IME composition is left to the IME.
  KeyEventResult _handleInputKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    // Ctrl+V / Shift+Insert with an image (or Explorer files) on the clipboard
    // → attachment. Checked here, ahead of the field's own paste shortcut;
    // with plain text on the clipboard it falls through to a normal paste.
    final keys = HardwareKeyboard.instance;
    final isPaste = (key == LogicalKeyboardKey.keyV && keys.isControlPressed) ||
        (key == LogicalKeyboardKey.insert && keys.isShiftPressed);
    if (isPaste && ClipboardMedia.hasMedia()) {
      if (event is KeyDownEvent) _pasteClipboardMedia();
      return KeyEventResult.handled;
    }
    if (key != LogicalKeyboardKey.enter &&
        key != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) return KeyEventResult.ignored;
    if (_textController.value.composing.isValid) return KeyEventResult.ignored;
    if (_canSend && event is KeyDownEvent) {
      _handleSubmitted(_textController.text);
    }
    return KeyEventResult.handled;
  }

  Future<void> _handleSubmitted(String text) async {
    final l10n = context.l10n;
    // Ensure we have a contact to send to
    if (_selectedChatContact == null) {
      _showError(l10n.messageInputNoRecipientSelected);
      return;
    }

    final hasPendingAttachment = _pendingAttachment != null;
    final hasPendingGallery = _pendingGallery.isNotEmpty;
    final hasText = text.trim().isNotEmpty;

    // If there's a pending attachment, send it (text is optional as description)
    // If no attachment, require text
    if (!hasPendingAttachment && !hasPendingGallery && !hasText) return;
    if (!widget.isInputEnabled || _isSending) return;
    // A large image is still compressing — the staged bytes are the un-sendable
    // full-res original. Block until the optimized bytes land.
    if (_compressingAttachment) return;

    setState(() => _isSending = true);

    // If no conversation topic yet, create DM now. Groups always carry a
    // topic on the stub Contact, so we only run this for DMs.
    if (_currentTopic == null &&
        widget.targetInboxId != null &&
        _selectedChatContact?.isGroupChat != true) {
      try {
        print('MessageInput: No conversation topic — creating DM for first message to ${widget.targetInboxId}');
        final conv = await PublicOSConversations.ensureConversation(widget.targetInboxId!);
        setState(() {
          _currentTopic = conv.topic;
        });
        // Notify parent (chat_screen) so it can update its state
        widget.onConversationCreated?.call(conv.topic);
        print('MessageInput: DM created, topic: ${conv.topic}');
      } catch (e) {
        print('MessageInput: Failed to create DM: $e');
        _showError(l10n.messageInputFailedStartConversation);
        setState(() => _isSending = false);
        return;
      }
    }
    final trimmedText = text.trim();
    _textController.clear();

    // Clear draft on send
    final topic = _currentTopic;
    if (topic != null) {
      PublicOSConversations.deleteDraft(topic);
    }

    // Several files → upload each, then ONE multi-attachment message whose
    // caption is the typed text (our `description` parameter).
    if (hasPendingGallery) {
      try {
        final description = trimmedText.isNotEmpty ? trimmedText : null;
        final items = <RemoteAttachmentContent>[];
        for (final m in _pendingGallery) {
          final filename = _sanitizeFilename(m.filename);
          final remote = await PublicOSConversations.prepareRemoteAttachment(
            m.bytes,
            filename,
            mimeType: m.mimeType,
          );
          // Seed the cache so the sender sees every tile without a re-download.
          await PublicOSAttachmentCache.putCachedAttachment(
            contentDigest: remote.contentDigest,
            attachment: AttachmentContent(
                data: m.bytes, mimeType: m.mimeType, filename: filename),
          );
          items.add(remote);
        }
        try {
          await _send(
            MultiRemoteAttachmentContent(attachments: items, description: description),
            'xmtp.org',
            'multiRemoteStaticAttachment',
          );
        } catch (_) {
          _showError(l10n.messageInputFailedSendAttachmentRecipient);
          setState(() => _isSending = false);
          return;
        }
        setState(() {
          _pendingGallery = const [];
          _isComposing = false;
          _isSending = false;
        });
      } catch (e) {
        print('MessageInput: Error sending gallery: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.messageInputFailedSendAttachment),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSending = false);
        }
      }
      return;
    }

    // If we have a pending attachment, send it with description
    if (hasPendingAttachment) {
      try {
        final description = trimmedText.isNotEmpty ? trimmedText : null;
        final isVideo = _pendingAttachment!.mimeType.startsWith('video/');
        // Video always takes the remote path — XMTP envelope is too small
        // for a video payload regardless of how short the clip is.
        final goRemote = isVideo || (_hdMode && _pendingOriginalBytes != null);

        if (goRemote) {
          // HD/video: encrypt original bytes, upload to feed server, send
          // as remote attachment.
          final remoteContent = await PublicOSConversations.prepareRemoteAttachment(
            _pendingOriginalBytes!,
            _pendingAttachment!.filename,
            mimeType: _pendingAttachment!.mimeType,
            description: description,
          );

          // Seed cache so sender sees the media instantly (no re-download).
          await PublicOSAttachmentCache.putCachedAttachment(
            contentDigest: remoteContent.contentDigest,
            attachment: AttachmentContent(
              data: _pendingOriginalBytes!,
              mimeType: _pendingAttachment!.mimeType,
              filename: _pendingAttachment!.filename,
              description: description,
            ),
          );

          try {
            await _send(remoteContent, 'xmtp.org', 'remoteStaticAttachment');
          } catch (_) {
            _showError(l10n.messageInputFailedSendAttachmentRecipient);
            setState(() => _isSending = false);
            return;
          }
        } else {
          // Low mode: send compressed bytes inline as attachment (image or
          // sticker). Preserve isSticker so the receiver renders it bubble-less.
          final attachmentWithDescription = AttachmentContent(
            data: _pendingAttachment!.data,
            mimeType: _pendingAttachment!.mimeType,
            filename: _pendingAttachment!.filename,
            description: description,
            isSticker: _pendingAttachment!.isSticker,
          );

          try {
            await _send(attachmentWithDescription, 'xmtp.org', 'attachment');
          } catch (_) {
            _showError(l10n.messageInputFailedSendAttachmentRecipient);
            setState(() => _isSending = false);
            return;
          }
        }

        // Clear pending attachment after successful send
        setState(() {
          _pendingAttachment = null;
          _pendingOriginalBytes = null;
          _hdMode = false;
          _showHdToggle = false;
          _pendingIsGif = false;
          _sendAsSticker = true;
          _isComposing = false;
          _isSending = false;
        });
        return;
      } catch (e) {
        print('MessageInput: Error sending attachment: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.messageInputFailedSendAttachment),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSending = false);
        }
        return;
      }
    }

    // No pending attachment, send as text message

    try {

      // Check if we're replying to a message
      if (widget.replyToMessage != null) {

        // Create Reply object
        final reply = Reply(
          reference: widget.replyToMessage!.idXmtp!,
          content: trimmedText,
          contentType: ContentType(
            authorityId: 'xmtp.org',
            typeId: 'text',
            versionMajor: 1,
          ),
        );

        // Send reply
        try {
          await _send(reply, 'xmtp.org', 'reply');
        } catch (e) {
          print('MessageInput Error sending reply: $e');
          _showError(l10n.messageInputFailedSendReply);
          setState(() => _isSending = false);
          return;
        }

        // Clear reply state after sending
        _clearReply();
      } else {
        // Regular text message (not a reply)
        try {
          await _send(trimmedText, 'xmtp.org', 'text');
        } catch (e) {
          print('MessageInput Error sending text: $e');
          _showError(l10n.messageInputFailedSendRecipient);
          setState(() => _isSending = false);
          return;
        }
      }

      // If send was successful (no exception thrown and not returned early)
      setState(() {
        _isComposing = false;
        _isSending = false;
      });
    } catch (e) {
      print('MessageInput: Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.messageInputFailedSendMessage),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSending = false);
      }
    }
  }

  /// Replace an OS-picker filename with `media.<ext>` so we don't ship the
  /// user's device asset id / WhatsApp save name to the recipient or feed
  /// server. Preserves extension so the receiver's MIME fallback (and the
  /// server's `ExtensionForMime` URL extension) still pick the right
  /// renderer. No extension → bare `media`.
  String _sanitizeFilename(String original) {
    final dot = original.lastIndexOf('.');
    if (dot < 0 || dot == original.length - 1) return 'media';
    return 'media${original.substring(dot).toLowerCase()}';
  }

  /// Paste from the clipboard as an attachment (Ctrl+V or the context menu's
  /// Paste, when [ClipboardMedia.hasMedia]). Pasted media JOINS what is staged:
  /// with a feed server it adds to the gallery (a single staged image/video
  /// becomes the gallery's first tile); without one there is no gallery, so it
  /// replaces the single attachment, same as picking again.
  Future<void> _pasteClipboardMedia() async {
    if (_selectedChatContact == null) {
      _showError(context.l10n.messageInputNoRecipientAttachment);
      return;
    }
    if (!widget.isInputEnabled || _isSending) return;

    final picks = await ClipboardMedia.read(
      context: context,
      kind: _hasServer ? MediaPickerKind.imageAndVideo : MediaPickerKind.imageOnly,
      limit: _hasServer ? _maxGalleryItems : 1,
    );
    if (!mounted || picks.isEmpty) return;

    final pending = _pendingAttachment;
    final List<PickedMedia> staged;
    if (!_hasServer) {
      staged = const [];
    } else if (_pendingGallery.isNotEmpty) {
      staged = _pendingGallery;
    } else if (pending != null &&
        _pendingOriginalBytes != null &&
        !pending.isSticker &&
        !_pendingIsGif &&
        (pending.mimeType.startsWith('image/') ||
            pending.mimeType.startsWith('video/'))) {
      final bytes = _pendingOriginalBytes!;
      staged = [
        PickedMedia(
          file: XFile.fromData(bytes,
              name: pending.filename, mimeType: pending.mimeType),
          bytes: bytes,
          filename: pending.filename,
          mimeType: pending.mimeType,
          isVideo: pending.mimeType.startsWith('video/'),
        ),
      ];
    } else {
      staged = const [];
    }

    final all = [...staged, ...picks].take(_maxGalleryItems).toList();
    if (all.length == 1) {
      final pick = all.first;
      await _stageMediaAttachment(
        bytes: pick.bytes,
        mimeType: pick.mimeType,
        filename: pick.filename,
        isVideo: pick.isVideo,
      );
      return;
    }
    _compressSeq++; // a single image mid-compress is now a gallery tile
    setState(() {
      _pendingAttachment = null;
      _pendingOriginalBytes = null;
      _compressingAttachment = false;
      _hdMode = false;
      _showHdToggle = false;
      _pendingIsGif = false;
      _sendAsSticker = true;
      _pendingGallery = all;
      _isComposing = true;
    });
  }

  /// The field's right-click menu, with Paste routed to
  /// [_pasteClipboardMedia] when the clipboard holds media. The stock menu
  /// only offers Paste for text, so an image-only clipboard gets one added.
  Widget _buildContextMenu(
      BuildContext context, EditableTextState editableTextState) {
    final items = [...editableTextState.contextMenuButtonItems];
    if (ClipboardMedia.hasMedia()) {
      final pasteMedia = ContextMenuButtonItem(
        type: ContextMenuButtonType.paste,
        onPressed: () {
          editableTextState.hideToolbar();
          _pasteClipboardMedia();
        },
      );
      final i = items.indexWhere((b) => b.type == ContextMenuButtonType.paste);
      if (i >= 0) {
        items[i] = pasteMedia;
      } else {
        items.add(pasteMedia);
      }
    }
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: items,
    );
  }

  Future<void> handleAttachment() async {
    final l10n = context.l10n;
    // Ensure we have a contact to send to
    if (_selectedChatContact == null) {
      _showError(l10n.messageInputNoRecipientAttachment);
      return;
    }

    if (!widget.isInputEnabled || _isSending) return;

    try {
      // Picker only surfaces video when the user has a feed server (HD path
      // is the only practical send route for video). With no server, image
      // is the only option — same picker, narrower kind.
      // With a server the picker allows several at once (→ one gallery
      // message); without one it stays at a single inline image.
      final picks = await pickMedia(
        context: context,
        limit: _hasServer ? _maxGalleryItems : 1,
        kind: _hasServer
            ? MediaPickerKind.imageAndVideo
            : MediaPickerKind.imageOnly,
      );
      if (!mounted || picks.isEmpty) return;
      if (picks.length > 1) {
        setState(() {
          _pendingAttachment = null;
          _pendingOriginalBytes = null;
          _pendingGallery = picks.take(_maxGalleryItems).toList();
          _isComposing = true;
        });
        return;
      }
      final pick = picks.first;
      await _stageMediaAttachment(
        bytes: pick.bytes,
        mimeType: pick.mimeType,
        filename: pick.filename,
        isVideo: pick.isVideo,
      );
    } catch (e) {
      print('MessageInput: Error picking attachment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.messageInputFailedSelectAttachment),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Stage a picked image/video into the composer — compress / inline / HD
  /// logic. Shared by [handleAttachment] (the Image flow) and [handleDocument],
  /// which routes an image/video the file picker couldn't filter out straight
  /// here, so picking a photo under "Document" behaves exactly like "Image".
  Future<void> _stageMediaAttachment({
    required Uint8List bytes,
    required String mimeType,
    required String filename,
    required bool isVideo,
  }) async {
    final l10n = context.l10n;
    // OS pickers leak the device path / asset id in the filename; strip it to
    // media.<ext> so the only PII shared is the file type. (The name travels in
    // the RemoteAttachment XMTP params + the upload's original_filename.)
    final safeFilename = _sanitizeFilename(filename);

    // Video → HD/remote path (needs a feed server). No compression.
    if (isVideo) {
      if (!_hasServer) {
        _showError(l10n.messageInputVideoNeedsServer);
        return;
      }
      setState(() {
        _pendingAttachment = AttachmentContent(
            data: bytes, mimeType: mimeType, filename: safeFilename);
        _pendingOriginalBytes = bytes;
        _hdMode = true;
        _showHdToggle = false;
        _pendingIsGif = false;
        _compressingAttachment = false;
        _isComposing = true;
      });
      return;
    }

    // Image that already fits inline → stage as-is, no compression.
    if (bytes.length <= ImageUtils.MAX_SIZE_BYTES) {
      setState(() {
        _pendingAttachment = AttachmentContent(
            data: bytes, mimeType: mimeType, filename: safeFilename);
        _pendingOriginalBytes = bytes;
        _hdMode = false;
        _showHdToggle = false;
        _pendingIsGif = false;
        _compressingAttachment = false;
        _isComposing = true;
      });
      return;
    }

    // Large image → show the preview INSTANTLY with the original bytes, then
    // compress in the background and swap in the optimized bytes. Sending is
    // blocked while _compressingAttachment is true (the staged bytes are the
    // un-sendable full-res original until compression lands).
    final mySeq = ++_compressSeq;
    setState(() {
      _pendingAttachment = AttachmentContent(
          data: bytes, mimeType: mimeType, filename: safeFilename);
      _pendingOriginalBytes = bytes;
      _hdMode = false;
      _showHdToggle = false;
      _pendingIsGif = false;
      _compressingAttachment = true;
      _isComposing = true;
    });

    final c = await ImageUtils.compressForInline(bytes, mimeType, filename);
    // Bail if the user cleared the attachment or staged a new one mid-compress.
    if (!mounted || mySeq != _compressSeq) return;

    if (c.bytes.length <= ImageUtils.MAX_SIZE_BYTES) {
      // Compressed fits inline → that's the default; offer HD (full-res via
      // server) as the alternative.
      setState(() {
        _pendingAttachment = AttachmentContent(
            data: c.bytes, mimeType: c.mimeType, filename: safeFilename);
        _hdMode = false;
        _showHdToggle = true;
        _compressingAttachment = false;
      });
    } else if (_hasServer) {
      // Couldn't get under the cap → server-only (HD); send uses the original.
      setState(() {
        _pendingAttachment = AttachmentContent(
            data: c.bytes, mimeType: c.mimeType, filename: safeFilename);
        _hdMode = true;
        _showHdToggle = false;
        _compressingAttachment = false;
      });
    } else {
      // Too big to inline, no server for HD → can't send it. Unstage.
      setState(() {
        _pendingAttachment = null;
        _pendingOriginalBytes = null;
        _compressingAttachment = false;
        _isComposing = _textController.text.isNotEmpty;
      });
      _showError(l10n.messageInputImageTooLarge);
    }
  }

  /// Document attachment flow — the Document option in the attach row. Picks a
  /// file; an image/video the picker couldn't filter out is routed through the
  /// image flow ([_stageMediaAttachment]). A real document stages like any
  /// attachment — no compression: small docs send inline, large docs take the
  /// feed-server (remote) path (same machinery as a video / HD image).
  Future<void> handleDocument() async {
    final l10n = context.l10n;
    if (_selectedChatContact == null) {
      _showError(l10n.messageInputNoRecipientAttachment);
      return;
    }
    if (!widget.isInputEnabled || _isSending) return;

    try {
      final pick = await pickDocument(context: context);
      if (!mounted || pick == null) return;

      // The file picker can't exclude images/videos. If the user picked one,
      // run it through the exact image/video flow instead of erroring.
      final isVideo = pick.mimeType.startsWith('video/');
      if (pick.mimeType.startsWith('image/') || isVideo) {
        await _stageMediaAttachment(
          bytes: pick.bytes,
          mimeType: pick.mimeType,
          filename: pick.filename,
          isVideo: isVideo,
        );
        return;
      }

      final isLarge = pick.bytes.length > ImageUtils.MAX_SIZE_BYTES;
      if (isLarge && !_hasServer) {
        // Too big to inline and no feed server to host it remotely.
        _showError(l10n.documentTooLargeNoServer);
        return;
      }

      setState(() {
        _pendingAttachment = AttachmentContent(
          data: pick.bytes,
          mimeType: pick.mimeType,
          filename: pick.filename,
        );
        // The remote send path reads _pendingOriginalBytes; only large docs
        // go remote, so leave it null for the inline case.
        _pendingOriginalBytes = isLarge ? pick.bytes : null;
        _hdMode = isLarge; // large doc → feed-server (remote) send
        _showHdToggle = false; // docs have no quality choice
        _pendingIsGif = false;
        _isComposing = true;
      });
    } catch (e) {
      print('MessageInput: Error picking document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.messageInputFailedSelectAttachment),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Send OX to the chat recipient — opens the OX send sheet (the tip sheet in
  /// "Send" mode) and posts an XIP-21 receipt when the transfer lands.
  /// 1-1: the peer is the single recipient (sheet skips selection). Group:
  /// pending — needs per-member ETH-identity resolution (next step).
  Future<void> handleSendTokens() async {
    final l10n = context.l10n;
    final contact = _selectedChatContact;
    if (contact == null) {
      _showError(l10n.messageInputNoRecipientSelected);
      return;
    }
    if (!widget.isInputEnabled || _isSending) return;

    if (contact.isGroupChat == true) {
      // Group: resolve members, keep only those with a PublicOS account (an EVM
      // identity → can actually receive OX), and let the user pick one. The
      // sheet's multi-select handles >1 candidate.
      final candidates = await _withMemberLoading(_resolveGroupSendCandidates);
      if (!mounted || candidates == null) return;
      if (candidates.isEmpty) {
        _showError(l10n.messageInputNoSendableMembers);
        return;
      }
      await showSendSheet(
        context: context,
        config: SendSheetConfig(
          targetMode: SendTargetMode.pickFrom,
          candidates: candidates,
          title: l10n.messageInputSendOx,
          confirmLabel: l10n.messageInputSendOx,
          confirmIcon: Icons.send_rounded,
          onSent: _postTransferReceipt,
        ),
      );
      return;
    }

    final addr = contact.publicosAddress;
    if (addr == null) {
      _showError(l10n.messageInputRecipientNoAddress);
      return;
    }

    await showSendSheet(
      context: context,
      config: SendSheetConfig(
        targetMode: SendTargetMode.fixed,
        candidates: [SendCandidate(address: addr, contact: contact)],
        title: l10n.messageInputSendOx,
        confirmLabel: l10n.messageInputSendOx,
        confirmIcon: Icons.send_rounded,
        onSent: _postTransferReceipt,
      ),
    );
  }

  /// Run [task] behind a blocking loading spinner (member resolution can hit the
  /// RPC for not-yet-cached members). Returns null if we unmounted mid-load.
  Future<T?> _withMemberLoading<T>(Future<T> Function() task) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: PhigitalLoadingWidget(size: 32, showShadows: false)),
    );
    try {
      return await task();
    } finally {
      if (mounted) Navigator.of(context).pop(); // dismiss the spinner
    }
  }

  /// Group members that can receive OX: resolve each member's Contact and keep
  /// those with a PublicOS account address (a member with no `publicosAddress`
  /// is a non-EVM / unresolvable inbox and can't be an OX target).
  Future<List<SendCandidate>> _resolveGroupSendCandidates() async {
    final topic = _currentTopic ?? widget.conversationTopic;
    if (topic == null) return [];
    try {
      final members = await PublicOSConversations.listGroupMembers(topic);
      final own = PublicOS.clientXmtpInboxId;
      final seen = <String>{};
      final candidates = <SendCandidate>[];
      for (final m in members) {
        final inboxId = m['inboxId'] as String?;
        if (inboxId == null || inboxId.isEmpty || inboxId == own) continue;
        Contact? c = await PublicOSContacts.searchContacts(inboxId);
        c ??= await PublicOSContacts.findContactInfoOnly(inboxId);
        final addr = c?.publicosAddress;
        if (c == null || addr == null) continue;
        if (!seen.add(addr.eip55With0x.toLowerCase())) continue;
        candidates.add(SendCandidate(address: addr, contact: c));
      }
      return candidates;
    } catch (e) {
      print('MessageInput: group send candidate resolution failed: $e');
      return [];
    }
  }

  /// Build + send the XIP-21 receipt for a completed OX transfer. Best-effort:
  /// the transfer already succeeded, so a receipt-send failure (e.g. no topic
  /// yet on a brand-new DM) must not surface as an error.
  Future<void> _postTransferReceipt(SentTxInfo info) async {
    // XIP-21 `amount` is in SMALLEST units (raw), `decimals` separate — the
    // renderer does amount / 10^decimals. Scale the human value by the token's
    // decimals (OX=18, USDC=6, WBTC=8…) and reference the chain + token the
    // transfer actually used, so non-OX sends post a correct receipt.
    final rawAmount = _humanToRaw(info.amount, info.decimals);
    final ref = TransactionReference(
      networkId: info.chainId.toString(),
      reference: info.txHash,
      metadata: TransactionMetadata(
        transactionType: 'transfer',
        currency: info.tokenSymbol,
        amount: rawAmount.toDouble(),
        decimals: info.decimals,
        fromAddress: info.fromAddress,
        toAddress: info.toAddress,
      ),
    );
    try {
      await _send(ref, 'xmtp.org', 'transactionReference');
    } catch (_) {}
  }

  /// BigInt-safe human→raw scaling (no float drift; the old `human * 1e18`
  /// assumed 18 decimals).
  BigInt _humanToRaw(String text, int decimals) {
    final parts = text.trim().split('.');
    final whole = parts[0].isEmpty ? '0' : parts[0];
    var frac = parts.length > 1 ? parts[1] : '';
    if (frac.length > decimals) frac = frac.substring(0, decimals);
    frac = frac.padRight(decimals, '0');
    return BigInt.parse('$whole$frac');
  }

  /// Request payment — opens the request sheet (pick which of MY wallets gets
  /// paid + amount) and sends a WalletSendCalls invoice the recipient can pay
  /// via the existing Review-&-Pay card.
  Future<void> handleRequestPayment() async {
    final l10n = context.l10n;
    if (_selectedChatContact == null) {
      _showError(l10n.messageInputNoRecipientSelected);
      return;
    }
    if (!widget.isInputEnabled || _isSending) return;

    await showRequestPaymentSheet(
      context: context,
      onRequest: (payToAddress, amountWei, asset) async {
        final peer = _selectedChatContact;
        final isGroup = peer?.isGroupChat == true;
        // The expected payer: the peer in a DM; left empty in a group (any
        // member's wallet fills it when they pay).
        final from = (!isGroup && peer?.publicosAddress != null)
            ? peer!.publicosAddress!.eip55With0x
            : '';
        final wsc = WalletSendCalls(
          version: '1.0',
          chainId: asset.chainIdHex,
          from: from,
          calls: [
            WalletCall(
              to: asset.tokenAddress,
              data: _encodeErc20Transfer(payToAddress, amountWei),
              value: '0x0',
              // Self-describing metadata so a RECEIVER can render "requested
              // 5 OX" without decoding the calldata AND without knowing our
              // token registry. The amount is authoritatively in `data` (and
              // Android decodes it from there — metadata is never trusted over
              // calldata); this is purely so thin surfaces can read it too —
              // notably the **iOS Notification Service Extension**, which is
              // Swift, has no registry, and can't afford a chain read.
              // Mirrors the shape a transactionReference receipt already puts
              // on the wire (currency + raw amount + decimals).
              metadata: WalletCallMetadata(
                transactionType: 'transfer',
                extra: {
                  'currency': asset.symbol,
                  'amount': amountWei.toString(), // RAW base units
                  'decimals': asset.decimals,
                },
              ),
            ),
          ],
        );
        // Throws on failure → the sheet keeps itself open with an error.
        await _send(wsc, 'xmtp.org', 'walletSendCalls');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.requestPaymentSent)),
          );
        }
      },
    );
  }

  /// ERC-20 `transfer(address,uint256)` calldata: selector + 32-byte-padded
  /// recipient + 32-byte-padded amount.
  String _encodeErc20Transfer(String to, BigInt amount) {
    final addr = (to.startsWith('0x') ? to.substring(2) : to).toLowerCase();
    final addrPad = addr.padLeft(64, '0');
    final amtPad = amount.toRadixString(16).padLeft(64, '0');
    return '0xa9059cbb$addrPad$amtPad';
  }

  /// Accept a sticker handed over by the keyboard's content-insertion API
  /// (Gboard / Samsung / IME, Android). No keyboard exposes a "sticker" bit
  /// Flutter can read, so provenance is the signal: anything arriving here is
  /// a sticker. Inline-only — png/webp/gif, hard 1 MB cap, raw bytes
  /// (NO compression, which would flatten an animated WebP/GIF to one frame).
  void _ingestInsertedContent(KeyboardInsertedContent content) {
    if (!widget.isInputEnabled || _isSending) return;
    final bytes = content.data;
    if (bytes == null || bytes.isEmpty) return;
    final mime = content.mimeType;

    // MIME gate — only alpha-capable image formats count as stickers.
    const allowed = {'image/png', 'image/webp', 'image/gif'};
    if (!allowed.contains(mime)) return;

    // XMTP recommends inline Attachment < 1 MB. Stickers are inline-only, so we
    // hard-cap and reject larger. Sticker packs sit well under it; the usual
    // offender is a Tenor GIF from Gboard's GIF-search.
    const maxStickerBytes = 1024 * 1024; // 1 MB
    if (bytes.length > maxStickerBytes) {
      _showError(context.l10n.messageInputStickerTooLarge);
      return;
    }

    final ext = mime == 'image/gif'
        ? '.gif'
        : mime == 'image/png'
            ? '.png'
            : '.webp';

    final isGif = mime == 'image/gif';
    if (!mounted) return;
    setState(() {
      // Default to sticker (it came from the sticker tray). A GIF can be
      // flipped to "send as GIF" via the preview toggle (→ isSticker=false).
      _pendingAttachment = AttachmentContent(
        data: bytes,
        mimeType: mime,
        filename: 'sticker$ext',
        isSticker: true,
      );
      _pendingOriginalBytes = bytes;
      _hdMode = false; // small → inline 'attachment' path
      _showHdToggle = false; // stickers never offer HD
      _pendingIsGif = isGif; // only GIFs get the Sticker|GIF toggle
      _sendAsSticker = true;
      _isComposing = true;
    });
  }

  /// Flip an inserted GIF between sending as a sticker (isSticker=true) and a
  /// normal attachment (isSticker=false). Rebuilds the pending content so the
  /// send path (which reads `_pendingAttachment.isSticker`) carries the choice.
  void _onStickerGifToggle(bool asSticker) {
    final p = _pendingAttachment;
    if (p == null) return;
    setState(() {
      _sendAsSticker = asSticker;
      _pendingAttachment = AttachmentContent(
        data: p.data,
        mimeType: p.mimeType,
        filename: p.filename,
        description: p.description,
        isSticker: asSticker,
      );
    });
  }

  Widget _buildStickerGifToggle() {
    return StickerGifToggle(
      sendAsSticker: _sendAsSticker,
      onChanged: _onStickerGifToggle,
    );
  }

  // ===========================================================================
  // Sticker panel — the keyboard's understudy
  // ===========================================================================

  /// The field gained focus, so the keyboard is on its way up. Only one of the
  /// two may hold the bottom of the screen.
  void _handleFocusChange() {
    if (_inputFocus.hasFocus && _showStickerPanel) {
      setState(() => _showStickerPanel = false);
    }
  }

  /// Open the panel and put the keyboard away. Unfocusing is what dismisses the
  /// IME; the panel then stands in at the height the keyboard just vacated, so
  /// the two never stack and the bottom of the screen never double-counts.
  void _openStickerPanel() {
    _inputFocus.unfocus();
    setState(() {
      _showStickerPanel = true;
      _showAttachOptions = false; // never two expanders at once
    });
  }

  void _closeStickerPanel() => setState(() => _showStickerPanel = false);

  void _toggleStickerPanel() {
    if (!widget.isInputEnabled || _isSending) return;
    if (_showStickerPanel) {
      _closeStickerPanel();
    } else {
      _openStickerPanel();
    }
  }

  /// Send a saved sticker straight from the gallery. The panel stays open, so a
  /// run of taps lands as one horizontal sticker stack (same sender, same
  /// clock-minute — see chat_screen's grouping).
  ///
  /// This does NOT route through _handleSubmitted: that path is built around
  /// the composer's text + _pendingAttachment, and a gallery send carries
  /// neither. It reuses _send() directly, the same primitive _handleSubmitted
  /// calls, so DM-creation-on-first-message still happens.
  Future<void> _sendSavedSticker(AttachmentContent sticker) async {
    if (!widget.isInputEnabled || _isSending) return;
    final l10n = context.l10n;
    if (_selectedChatContact == null) {
      _showError(l10n.messageInputNoRecipientSelected);
      return;
    }

    setState(() => _isSending = true);

    // First message in a DM that has no conversation yet — same bootstrap the
    // text path runs. Groups always carry a topic on the stub Contact.
    if (_currentTopic == null &&
        widget.targetInboxId != null &&
        _selectedChatContact?.isGroupChat != true) {
      try {
        final conv =
            await PublicOSConversations.ensureConversation(widget.targetInboxId!);
        setState(() => _currentTopic = conv.topic);
        widget.onConversationCreated?.call(conv.topic);
      } catch (e) {
        print('MessageInput: Failed to create DM for sticker: $e');
        _showError(l10n.messageInputFailedStartConversation);
        setState(() => _isSending = false);
        return;
      }
    }

    try {
      await _send(sticker, 'xmtp.org', 'attachment');
    } catch (e) {
      print('MessageInput: Error sending sticker: $e');
      _showError(l10n.messageInputFailedSendAttachmentRecipient);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Stage a saved sticker in the compose preview so the user can type a
  /// description before sending. Closes the panel and hands focus to the field —
  /// that's the whole point of the action. Reuses the existing pending-
  /// attachment machinery, so the preview, the close button and the send path
  /// all work unchanged.
  void _stageSavedSticker(AttachmentContent sticker) {
    setState(() {
      _pendingAttachment = sticker;
      _pendingOriginalBytes = sticker.data;
      _hdMode = false;
      _showHdToggle = false; // stickers never offer HD
      // No Sticker|GIF toggle: this sticker is already in the library AS a
      // sticker. The toggle exists to classify fresh keyboard insertions.
      _pendingIsGif = false;
      _sendAsSticker = true;
      _isComposing = true;
      _showStickerPanel = false;
    });
    _inputFocus.requestFocus();
  }

  /// The panel stands in for the keyboard at exactly its height. Before the
  /// keyboard has ever been shown this session (cold open, or desktop/web where
  /// there is none) fall back to a sensible constant.
  /// The panel stands in for the keyboard at its height, clamped to something
  /// sane. Never trust [_lastKeyboardHeight] raw — see [didChangeMetrics].
  double _resolvePanelHeight() {
    final measured =
        _lastKeyboardHeight > 0 ? _lastKeyboardHeight : _fallbackPanelHeight;
    // A keyboard never sensibly occupies more than half-ish the screen; a tall
    // IME (emoji pane, split view) shouldn't push the composer off the top.
    final screenHeight = MediaQuery.of(context).size.height;
    final ceiling = screenHeight * 0.55;
    if (measured > ceiling && ceiling > _minPanelHeight) return ceiling;
    if (measured < _minPanelHeight) return _minPanelHeight;
    return measured;
  }

  /// Remember how tall the keyboard is, so the panel can take its exact place.
  ///
  /// Read from the **FlutterView**, not from this widget's MediaQuery: we sit
  /// inside the Scaffold's body, and `resizeToAvoidBottomInset` has already
  /// consumed the bottom inset by the time it reaches us — `MediaQuery.of(context)
  /// .viewInsets.bottom` is permanently 0 down here. `chat_screen` learned the
  /// same lesson for its keyboard re-pin (see its didChangeMetrics).
  ///
  /// `view.viewInsets` is in physical pixels; the panel is laid out in logical
  /// ones.
  ///
  /// **Android animates the IME inset**, so this fires once per animation frame
  /// and the value sweeps the whole range on the way in AND on the way out. A
  /// naive `if (inset > 0)` latches the last frame before zero — a fraction of
  /// a pixel — and the panel silently collapses to nothing (the sticker sheet
  /// then never opens). Two defenses:
  ///
  /// 1. **Ignore anything below [_minPanelHeight]** — no real keyboard is that
  ///    short, so every tail-of-the-animation frame is discarded.
  /// 2. **Only ever grow.** Mid-animation frames above the floor are still
  ///    wrong (a keyboard caught at 60% of its travel), and a shrinking value
  ///    would visibly collapse an already-open panel. Keeping the max means the
  ///    settled, fully-extended height is what sticks.
  ///
  /// Consequence worth knowing: swapping to a shorter IME within one session
  /// leaves the panel at the taller height until the widget is rebuilt fresh.
  /// That is the trade for never rendering an invisible panel.
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final view = View.maybeOf(context);
    if (view == null) return;
    final inset = view.viewInsets.bottom / view.devicePixelRatio;
    if (inset >= _minPanelHeight && inset > _lastKeyboardHeight) {
      _lastKeyboardHeight = inset;
    }
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

  void showXmtpKeySelector() async {
    // DELTA(desktop): the client's KeychainSheet pops `true` on a real active-
    // key switch; the desktop dialog reports through `onKeysChanged` instead
    // (which also fires on add/remove/rename — broader, but the host's
    // re-check is idempotent: it either rebinds the DM via the ValueKey
    // remount or redirects a now-self-chat to the profile). `myContact` is
    // passed so the session-key tile renders the real account (omit it and
    // the dialog looks like a sparser duplicate).
    var changed = false;
    await showKeychainDialog(
      context,
      myContact: AppStateNotifier.currentMyContact,
      onKeysChanged: () => changed = true,
    );
    // Refresh UI after potential key change
    if (mounted) {
      setState(() {});
    }
    if (changed) {
      widget.onActiveKeyChanged?.call();
    }
  }

  /// Staged gallery: a horizontal strip of 96px thumbnails, each with its own
  /// remove button. Removing down to one item keeps it a (1-item) gallery;
  /// removing the last clears the stage.
  Widget _buildGalleryPreview() {
    final tokens = GlassTokens.of(context);
    Widget removeButton(int i) => Material(
          color: Colors.black.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              final next = [..._pendingGallery]..removeAt(i);
              if (next.isEmpty) {
                _clearPendingAttachment();
              } else {
                setState(() => _pendingGallery = next);
              }
            },
            child: const SizedBox(
              width: 24,
              height: 24,
              child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
            ),
          ),
        );
    return Container(
      height: 112,
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: HorizontalWheel(child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _pendingGallery.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final m = _pendingGallery[i];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: TappableMedia(
                    imageData: m.isVideo ? null : m.bytes,
                    videoBytes: m.isVideo ? m.bytes : null,
                    filename: m.filename,
                    heroTag: 'pending_gallery_${i}_${m.filename}',
                    fit: BoxFit.cover,
                    showExpandButton: false,
                  ),
                ),
              ),
              Positioned(top: 4, right: 4, child: removeButton(i)),
            ],
          );
        },
      )),
    );
  }

  Widget _buildAttachmentPreview() {
    if (_pendingAttachment == null) return const SizedBox.shrink();

    final tokens = GlassTokens.of(context);
    final isImage = _pendingAttachment!.mimeType.startsWith('image/');
    final isVideo = _pendingAttachment!.mimeType.startsWith('video/');

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Media preview with overlaid controls. Fixed 180-tall so the
          // input bar height stays predictable; BoxFit.contain inside lets
          // a portrait video/image letterbox without taking over the
          // screen.
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: (isImage || isVideo) && _pendingAttachment!.data.isNotEmpty
                    ? SizedBox(
                        width: double.infinity,
                        height: 180,
                        child: TappableMedia(
                          imageData: isImage ? _pendingAttachment!.data : null,
                          videoBytes: isVideo ? _pendingAttachment!.data : null,
                          filename: _pendingAttachment!.filename,
                          heroTag: 'pending_attachment_${_pendingAttachment!.filename}',
                          fit: BoxFit.contain,
                          // Pending = staging, not consuming. The close button
                          // (top-right) does the room duty here; expand-to-
                          // fullscreen pre-send isn't needed.
                          showExpandButton: false,
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: 120,
                        color: tokens.surfaceElevated,
                        child: Icon(Icons.attach_file_rounded,
                            color: tokens.textDim, size: 40),
                      ),
              ),
              // Compressing overlay — the large-image preview shows instantly
              // with the original bytes while compression runs in the
              // background; a scrim + spinner signals "optimizing", and the send
              // button stays disabled (canSend gates on _compressingAttachment).
              // Before the close button + IgnorePointer so Close stays usable.
              if (_compressingAttachment)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(13)),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.35),
                        alignment: Alignment.center,
                        child: const PhigitalLoadingWidget(
                            size: 28, showShadows: false),
                      ),
                    ),
                  ),
                ),
              // Close button — top right (dark scrim for legibility on photos)
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _clearPendingAttachment,
                    child: const SizedBox(
                      width: 28,
                      height: 28,
                      child: Icon(Icons.close_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
              // Low / HD toggle — bottom left, overlaid on image. Only shown
              // when there's an actual quality choice to make (see _showHdToggle).
              if (isImage && _showHdToggle)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: _buildQualityToggle(),
                ),
              // Sticker / GIF toggle — for an inserted GIF, the user picks how
              // it sends. A GIF sticker never shows the HD toggle, so these two
              // never collide.
              if (isImage && _pendingIsGif)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: _buildStickerGifToggle(),
                ),
            ],
          ),
          // Server chip + filename row below the image
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Server chip (visible when HD)
                if (_hdMode && _hasServer) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: tokens.surfaceElevated,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: tokens.borderSubtle, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.dns_outlined,
                            size: 12, color: tokens.connectedAccent),
                        const SizedBox(width: 5),
                        Text(
                          context.l10n.messageInputFeedServer,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: tokens.starkWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Filename
                Expanded(
                  child: Text(
                    _pendingAttachment!.filename,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: tokens.starkWhite,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // File size indicator
                Text(
                  _hdMode && _pendingOriginalBytes != null
                      ? _formatBytes(_pendingOriginalBytes!.length)
                      : _formatBytes(_pendingAttachment!.data.length),
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: tokens.textDim,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityToggle() {
    return QualityToggle(
      hdMode: _hdMode,
      hdEnabled: _hasServer,
      onChanged: (hd) => setState(() => _hdMode = hd),
      onHdDisabledTap: () => _showError(
        context.l10n.messageInputSubscribeForHd,
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildReplyPreview() {
    if (widget.replyToMessage == null) return const SizedBox.shrink();

    final tokens = GlassTokens.of(context);

    // Determine content preview based on message type
    String contentPreview;
    IconData? contentIcon;

    switch (widget.replyToMessage!.content.type) {
      case MessageType.text:
        contentPreview = widget.replyToMessage!.content.value.toString().replaceAll('\n', ' ');
        if (contentPreview.length > 100) {
          contentPreview = '${contentPreview.substring(0, 100)}...';
        }
        break;
      case MessageType.attachment:
        contentPreview = context.l10n.messageInputReplyAttachment;
        contentIcon = Icons.attach_file_rounded;
        break;
      case MessageType.remoteAttachment:
      case MessageType.multiRemoteAttachment:
        contentPreview = context.l10n.messageInputReplyAttachment;
        contentIcon = Icons.attach_file_rounded;
        break;
      case MessageType.reaction:
        contentPreview = context.l10n.messageInputReplyReaction;
        contentIcon = Icons.favorite_border_rounded;
        break;
      case MessageType.reply:
        contentPreview = context.l10n.messageInputReplyReply;
        contentIcon = Icons.reply_rounded;
        break;
      default:
        contentPreview = context.l10n.messageInputReplyMessage;
    }

    return Container(
      padding: const EdgeInsets.only(left: 12.0, right: 4.0, top: 8.0, bottom: 6.0),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: tokens.borderMedium, width: 3),
        ),
        color: tokens.glassFill,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.messageInputReplyingTo,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: tokens.textDim,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (contentIcon != null) ...[
                      Icon(contentIcon, size: 14, color: tokens.textDim),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        contentPreview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: tokens.starkWhite,
                          fontStyle: contentIcon != null
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkResponse(
            radius: 18,
            onTap: _clearReply,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.close_rounded, size: 18, color: tokens.textDim),
            ),
          ),
        ],
      ),
    );
  }

  /// Whether there's a pending attachment (exposed for the chat screen)
  bool get hasPendingAttachment => _hasPending;
  bool get isSending => _isSending;

  /// Key selector — bare icon with the active key's name below it, no chip
  /// chrome. Far-left anchor of the input bar; hidden when no key is active.
  Widget _buildKeyChip(GlassTokens tokens) {
    // Group chats send via the shared group conversation, not your DM inbox
    // identity, so the active-key selector is meaningless here — hide it and
    // let the text field grow into the space.
    if (_selectedChatContact?.isGroupChat == true) return const SizedBox.shrink();
    final label = PublicOS.currentXmtpKeyLabel;
    if (label == null || label.isEmpty) return const SizedBox.shrink();

    return InkResponse(
      radius: 24,
      onTap: showXmtpKeySelector,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sim_card_outlined,
                size: 16, color: tokens.connectedAccent),
            const SizedBox(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 52),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: 0.3,
                  color: tokens.starkWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Height of the input bar's single-line band. Icons are anchored inside a
  /// box of this height at the BOTTOM of the row, so when the text field
  /// grows multiline only the field (and its background) rises — every icon
  /// stays exactly where it sits in the single-line layout.
  static const double _barUnit = 40;

  /// Bottom-anchored, vertically-centered slot for the bar's icons.
  Widget _anchored(Widget child) =>
      SizedBox(height: _barUnit, child: Center(child: child));

  /// Borderless utility icon for the input bar (settings / attach) — same
  /// tap-target language as the send icon.
  Widget _buildBarIcon({
    required GlassTokens tokens,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return InkResponse(
      radius: 20,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? tokens.starkWhite : tokens.textDim,
        ),
      ),
    );
  }

  /// Toggle the attachment options row. The attach icon spawns this row of
  /// kinds (Image / Document / Send / Contact / Location) instead of opening
  /// the media picker directly.
  void _toggleAttachOptions() {
    if (!widget.isInputEnabled || _isSending || _hasPending) {
      return;
    }
    setState(() {
      _showAttachOptions = !_showAttachOptions;
      // Only one expander below the field at a time — the sticker panel and
      // the attach row would otherwise stack and push the bar off-screen.
      if (_showAttachOptions) _showStickerPanel = false;
    });
  }

  /// Dispatch a chosen attachment kind. Image runs the existing media flow; the
  /// rest are placeholders until their steps land.
  void _onAttachOption(_AttachOption kind) {
    setState(() => _showAttachOptions = false);
    switch (kind) {
      case _AttachOption.image:
        handleAttachment();
        break;
      case _AttachOption.document:
        handleDocument();
        break;
      case _AttachOption.send:
        handleSendTokens();
        break;
      case _AttachOption.request:
        handleRequestPayment();
        break;
      case _AttachOption.contact:
      case _AttachOption.location:
        // Neutral (not error-red) snackbar — these are wired in later steps.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.messageInputAttachComingSoon)),
          );
        }
        break;
    }
  }

  /// The attachment options row — horizontally scrollable so future kinds don't
  /// overflow narrow screens. Glass-dark icon-over-label tiles.
  Widget _buildAttachOptionsRow(GlassTokens tokens) {
    final l10n = context.l10n;
    final options = <({IconData icon, String label, _AttachOption kind})>[
      (icon: Icons.image_outlined, label: l10n.messageInputAttachImage, kind: _AttachOption.image),
      (icon: Icons.description_outlined, label: l10n.messageInputAttachDocument, kind: _AttachOption.document),
      (icon: Icons.toll_outlined, label: l10n.messageInputAttachSend, kind: _AttachOption.send),
      (icon: Icons.request_quote_outlined, label: l10n.messageInputAttachRequest, kind: _AttachOption.request),
      (icon: Icons.person_outline_rounded, label: l10n.messageInputAttachContact, kind: _AttachOption.contact),
      (icon: Icons.location_on_outlined, label: l10n.messageInputAttachLocation, kind: _AttachOption.location),
    ];
    return HorizontalWheel(child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final o in options)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildAttachOptionTile(tokens, o.icon, o.label, o.kind),
            ),
        ],
      ),
    ));
  }

  Widget _buildAttachOptionTile(
      GlassTokens tokens, IconData icon, String label, _AttachOption kind) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _onAttachOption(kind),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tokens.glassFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.borderSubtle, width: 1),
              ),
              child: kind == _AttachOption.send
                  ? SendCoinsIcon(size: 22, color: tokens.connectedAccent)
                  : Icon(icon, size: 22, color: tokens.connectedAccent),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 64,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: tokens.starkWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final canSend = _canSend;

    return Container(
      color: tokens.background,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Attachment preview — hidden while sending: the message has been
            // handed to the list, so the preview would just duplicate it. State
            // is kept (not cleared), so a failed send brings the preview back.
            if (_pendingAttachment != null && !_isSending)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 12.0, right: 12.0),
                child: _buildAttachmentPreview(),
              ),
            if (_pendingGallery.isNotEmpty && !_isSending)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 12.0, right: 12.0),
                child: _buildGalleryPreview(),
              ),
            // Reply preview (no chips row — chips are now floating)
            if (widget.replyToMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 12.0, right: 12.0),
                child: _buildReplyPreview(),
              ),
            // Attachment options row — spawned by the attach icon (replaces the
            // old open-the-picker-directly behavior). AnimatedSize reveals it
            // from the bottom edge so it grows up off the input bar.
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.bottomCenter,
              child: _showAttachOptions
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6.0, bottom: 2.0),
                      child: _buildAttachOptionsRow(tokens),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
            // Input row — the collapsed chips live here:
            // [key chip · name below] [field] [attach] [send]
            // (settings are in the browser address-bar gear)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 4.0, bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _anchored(_buildKeyChip(tokens)),
                  const SizedBox(width: 0),
                  // Text field — dark grey rounded surface; attach lives
                  // inside it, at the right edge. Material (not Container)
                  // so the attach ripple draws ON the surface, not under it.
                  Expanded(
                    child: Material(
                      color: tokens.glassFill,
                      borderRadius: BorderRadius.circular(22),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Sticker — mirrors attach at the far edge. Fills
                          // while the panel is open, so the button reads as the
                          // panel's own toggle.
                          _anchored(Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                            child: InkResponse(
                              radius: 20,
                              onTap: (widget.isInputEnabled && !_isSending)
                                  ? _toggleStickerPanel
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: StickerIcon(
                                  size: 20,
                                  color: !(widget.isInputEnabled && !_isSending)
                                      ? tokens.textDim
                                      : _showStickerPanel
                                          ? tokens.connectedAccent
                                          : tokens.starkWhite,
                                ),
                              ),
                            ),
                          )),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              focusNode: _inputFocus,
                              enabled: widget.isInputEnabled && !_isSending,
                              onSubmitted: canSend ? _handleSubmitted : null,
                              contextMenuBuilder: _buildContextMenu,
                              cursorColor: tokens.connectedAccent,
                              decoration: InputDecoration(
                                hintText: _isSending
                                    ? context.l10n.messageInputHintSending
                                    : _hasPending
                                        ? context.l10n.messageInputHintAddDescription
                                        : context.l10n.messageInputHintTypeMessage,
                                filled: false,
                                isDense: true,
                                // Left padding is small: the sticker button
                                // already stands off the field's left edge.
                                contentPadding: const EdgeInsets.only(
                                    left: 4, right: 14, top: 10, bottom: 10),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                hintStyle: TextStyle(
                                  fontFamily: 'SpaceGrotesk',
                                  color: tokens.textDim,
                                  fontSize: 14,
                                ),
                              ),
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                color: tokens.starkWhite,
                                fontSize: 14,
                              ),
                              maxLines: 5,
                              minLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              keyboardType: TextInputType.multiline,
                              // Accept keyboard stickers (Gboard / Samsung /
                              // IME) on Android. Declaring these MIME types is
                              // what makes the sticker tray light up; content
                              // arriving here is a sticker by provenance.
                              contentInsertionConfiguration:
                                  ContentInsertionConfiguration(
                                allowedMimeTypes: const [
                                  'image/png',
                                  'image/webp',
                                  'image/gif',
                                ],
                                onContentInserted: _ingestInsertedContent,
                              ),
                            ),
                          ),
                          _anchored(Padding(
                            padding: const EdgeInsets.only(right: 4, bottom:4),
                            child: _buildBarIcon(
                              tokens: tokens,
                              // Closes to an X while the options row is open.
                              icon: _showAttachOptions
                                  ? Icons.close_rounded
                                  : Icons.attach_file_rounded,
                              onTap: (widget.isInputEnabled &&
                                      !_isSending &&
                                      _pendingAttachment == null)
                                  ? _toggleAttachOptions
                                  : null,
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  // Send — glass icon-only tap target
                  _anchored(InkResponse(
                    radius: 22,
                    onTap: canSend
                        ? () => _handleSubmitted(_textController.text)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _isSending
                          ? PixelRainLoadingWidget(
                              size: 24,
                              showShadows: false,
                              // Match the settings gear to the field's left.
                              color: tokens.starkWhite,
                            )
                          : Padding(
                            padding: const EdgeInsets.only(left:4, right:1, top:1, bottom: 4),
                            child: Icon(
                                Icons.send_rounded,
                                size: 20,
                                color: canSend
                                    ? tokens.connectedAccent
                                    : tokens.textDim,
                              ),
                          ),
                    ),
                  )),
                ],
              ),
            ),
            // Sticker panel — stands exactly where the keyboard would be.
            // Inside this Column (not a bottom sheet), so it grows the input
            // bar upward like the attach-options row and rides chat_screen's
            // SizeChangedLayoutNotifier re-pin. Never co-exists with the
            // keyboard: opening it unfocused the field.
            if (_showStickerPanel)
              StickerPanel(
                height: _resolvePanelHeight(),
                onSend: _sendSavedSticker,
                onAddDescription: _stageSavedSticker,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.removeListener(_handleTextChange);
    _textController.dispose();
    _inputFocus.removeListener(_handleFocusChange);
    _inputFocus.dispose();
    super.dispose();
  }

  // Placeholder for UI trigger:
  // This method would be called by a new button or option in the UI
  // for sending remote attachments.
  // For now, it can be called programmatically for testing.
  Future<void> _handleRemoteAttachmentLink(String remoteUrl) async {
    final l10n = context.l10n;
    if (_selectedChatContact == null) {
      _showError(l10n.messageInputNoRecipientRemote);
      return;
    }

    if (remoteUrl.trim().isEmpty) {
      _showError(l10n.messageInputRemoteUrlEmpty);
      return;
    }

    if (!widget.isInputEnabled || _isSending) return;
    setState(() => _isSending = true);

    try {
      final String authorityId = 'xmtp.org'; // Or a more specific one if defined for remote attachments
      final String typeId = 'remoteStaticAttachment';

      try {
        await _send(remoteUrl, authorityId, typeId);
      } catch (e) {
        print('MessageInput Error sending remote attachment: $e');
        _showError(l10n.messageInputFailedSendRemoteRecipient);
        setState(() => _isSending = false);
        return;
      }
      // Successfully sent
      setState(() {
        _isSending = false;
      });
    } catch (e) {
      print('MessageInput: Error sending remote attachment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.messageInputFailedSendRemote),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Ensure _isSending is reset in case of error before finally block
      // (though finally should also catch it)
      if (mounted) {
        setState(() => _isSending = false);
      }
    } finally {
      // Ensure _isSending is always reset
      if (mounted && _isSending) {
        setState(() => _isSending = false);
      }
    }
  }
}
