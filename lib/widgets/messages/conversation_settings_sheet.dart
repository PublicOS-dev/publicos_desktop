import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
// DELTA(desktop): share sheet → native save dialog (utils/save_file.dart).
import 'package:publicos_desktop/utils/save_file.dart';
import 'package:publicos_desktop/widgets/messages/message_widget.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:zero_cached_thumbnail/zero_cached_thumbnail.dart';
import 'package:publicos_desktop/utils/media_mime.dart';
import 'package:publicos_desktop/utils/doc_types.dart';
import 'package:publicos_desktop/utils/open_file.dart';
import 'package:publicos_desktop/widgets/shimmer_box.dart';
import 'package:publicos_desktop/widgets/media_overlay.dart';
import 'package:publicos_desktop/widgets/tappable_image.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// Slider range for the trim char budget — mirrors the feeds settings
/// sheet's trim slider so the two reading settings feel like one control.
const double _trimMin = 100;
const double _trimMax = 1000;

class ConversationSettingsSheet extends StatefulWidget {
  final String conversationTopic;
  final String? initialConsentState;

  const ConversationSettingsSheet({
    super.key,
    required this.conversationTopic,
    this.initialConsentState,
  });

  @override
  State<ConversationSettingsSheet> createState() => _ConversationSettingsSheetState();
}

class _ConversationSettingsSheetState extends State<ConversationSettingsSheet>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String? _consentState;
  int _iconTapCount = 0;
  bool _showDebugOption = false;

  // "Trim long messages" — a READING setting, shared by every conversation
  // (this sheet is just where it's reachable from). Stored as a char budget
  // under `messages_trim_chars`: '0' = off, absent = on at the default budget.
  // chat_screen re-reads it when this sheet closes and rebuilds its bubbles.
  bool _trimLongMessages = true;
  bool _trimLoading = true;
  // Where to cut, in chars. Only meaningful while the toggle is on; kept
  // around while off so re-enabling restores the last chosen budget.
  double _trimChars = kMessageTrimMaxChars.toDouble();

  late final TabController _tabController;
  List<_MediaEntry>? _mediaEntries;
  // Docs tab: every shared non-media file. Remote ones list WITHOUT
  // downloading (filename + contentLength ride in the message); the bytes are
  // fetched only when a row is tapped.
  List<_DocEntry>? _docEntries;
  bool _mediaLoading = true;
  // One sweep shared by every skeleton block on the sheet (in-place content
  // loads as a skeleton shimmer, never a spinner).
  late final AnimationController _shimmer = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _consentState = widget.initialConsentState;
    if (_consentState == null) {
      _loadConsentState();
    }
    _loadTrimSetting();
    _loadMedia();
  }

  Future<void> _loadTrimSetting() async {
    try {
      final record = await PublicOSSettings.getSetting('messages_trim_chars');
      final parsed = record == null ? null : int.tryParse(record.value);
      if (!mounted) return;
      setState(() {
        // Absent = on (default). Present = on only if it parses to a budget > 0.
        _trimLongMessages = record == null || (parsed != null && parsed > 0);
        if (parsed != null && parsed > 0) {
          _trimChars = parsed.toDouble().clamp(_trimMin, _trimMax);
        }
        _trimLoading = false;
      });
    } catch (e) {
      print('Error loading message trim setting: $e');
      if (mounted) setState(() => _trimLoading = false);
    }
  }

  /// Persist the budget. Stores 0 when disabled (easier to round-trip than
  /// deleting the key); chat_screen treats 0 as "show full".
  Future<void> _persistTrim(int chars) async {
    const key = 'messages_trim_chars';
    final record = Record.asSettings(
      key: key,
      value: chars.toString(),
      expiration: DateTime.now().add(const Duration(days: 365)),
      isExpired: false,
      isSystem: true,
    );
    await PublicOSSettings.setSetting(key, record);
  }

  Future<void> _setTrimLongMessages(bool value) async {
    setState(() => _trimLongMessages = value);
    await _persistTrim(value ? _trimChars.round() : 0);
  }

  Future<void> _setTrimChars(double value) async {
    setState(() => _trimChars = value);
    await _persistTrim(value.round());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    try {
      final messages = await PublicOSConversations.getLocalMessagesByTopic(
        widget.conversationTopic, null, false,
      );
      final media = <_MediaEntry>[];
      final docs = <_DocEntry>[];
      for (final msg in messages) {
        await _sortMessage(msg, media, docs);
      }
      media.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      docs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (mounted) {
        setState(() {
          _mediaEntries = media;
          _docEntries = docs;
          _mediaLoading = false;
        });
      }
    } catch (e) {
      print('Error loading conversation media: $e');
      if (mounted) {
        setState(() {
          _mediaEntries = const [];
          _docEntries = const [];
          _mediaLoading = false;
        });
      }
    }
  }

  /// Put one message's files into Media (images/videos) or Docs (everything
  /// else). Media needs the bytes, so a remote image/video shows only once it
  /// is in the attachment cache (no download storm). A doc never needs them:
  /// it lists from its metadata and downloads on tap.
  Future<void> _sortMessage(
      Message msg, List<_MediaEntry> media, List<_DocEntry> docs) async {
    final value = msg.content.value;
    final msgId = (msg.idXmtp ?? msg.id).toString();
    if (msg.content.type == MessageType.attachment) {
      final ac = _coerceAttachment(value);
      if (ac == null || ac.data.isEmpty) return;
      // Stickers are chat vocabulary, not media the user shared — they don't
      // belong in the conversation gallery. A captioned sticker still carries
      // isSticker, so it's excluded too.
      if (ac.isSticker) return;
      final m = _mediaEntryFromAttachment(ac, msg);
      if (m != null) {
        media.add(m);
      } else {
        docs.add(_DocEntry(
          filename: ac.filename,
          size: ac.data.length,
          timestamp: msg.timestamp,
          messageId: msgId,
          inline: ac,
        ));
      }
      return;
    }
    if (msg.content.type == MessageType.remoteAttachment) {
      RemoteAttachmentContent? rc;
      if (value is RemoteAttachmentContent) {
        rc = value;
      } else if (value is Map<String, dynamic>) {
        try { rc = RemoteAttachmentContent.fromJson(value); } catch (_) {}
      }
      if (rc != null) await _sortRemote(rc, msg, msgId, media, docs);
      return;
    }
    // A gallery is a list of remote files; each one is sorted on its own.
    if (msg.content.type == MessageType.multiRemoteAttachment &&
        value is MultiRemoteAttachmentContent) {
      for (final rc in value.attachments) {
        await _sortRemote(rc, msg, msgId, media, docs);
      }
    }
  }

  Future<void> _sortRemote(RemoteAttachmentContent rc, Message msg,
      String msgId, List<_MediaEntry> media, List<_DocEntry> docs) async {
    final filename = rc.filename;
    if (isImageFilename(filename) || isVideoFilename(filename)) {
      final cached =
          await PublicOSAttachmentCache.getCachedAttachment(rc.contentDigest);
      if (cached == null || cached.data.isEmpty) return;
      final m = _mediaEntryFromAttachment(cached, msg);
      if (m != null) media.add(m);
      return;
    }
    docs.add(_DocEntry(
      filename: filename,
      size: rc.contentLength,
      timestamp: msg.timestamp,
      messageId: '${msgId}_${rc.contentDigest.substring(0, 8)}',
      remote: rc,
    ));
  }

  AttachmentContent? _coerceAttachment(dynamic v) {
    if (v is AttachmentContent) return v;
    if (v is Map<String, dynamic>) {
      try { return AttachmentContent.fromJson(v); } catch (_) {}
    }
    return null;
  }

  _MediaEntry? _mediaEntryFromAttachment(AttachmentContent ac, Message msg) {
    final isImage = isImageMime(ac.mimeType) || isImageFilename(ac.filename);
    final isVideo = isVideoMime(ac.mimeType) || isVideoFilename(ac.filename);
    if (!isImage && !isVideo) return null;
    return _MediaEntry(
      bytes: ac.data,
      filename: ac.filename,
      isVideo: isVideo && !isImage,
      timestamp: msg.timestamp,
      messageId: (msg.idXmtp ?? msg.id).toString(),
    );
  }

  Future<void> _loadConsentState() async {
    setState(() => _isLoading = true);

    try {
      final state = await PublicOS.xmtpClient!.getConversationConsentState(widget.conversationTopic);
      if (mounted) {
        setState(() {
          _consentState = state;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading consent state: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleConsentState() async {
    if (_consentState == null) return;

    final l10n = context.l10n;
    final newState = _consentState == 'allowed' ? 'denied' : 'allowed';

    setState(() => _isLoading = true);

    try {
      await PublicOS.xmtpClient!.setConversationConsentState(widget.conversationTopic, newState);
      if (mounted) {
        setState(() {
          _consentState = newState;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error updating consent state: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.conversationSettingsSheetConsentUpdateFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onTitleTap() {
    if (_showDebugOption) return;
    setState(() {
      _iconTapCount++;
      if (_iconTapCount >= 10) _showDebugOption = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final isAllowed = _consentState == 'allowed';

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceDeep,
        // DELTA(desktop): full radius + no drag handle — centered dialog.
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHeader(
              title: context.l10n.conversationSettingsSheetTitle,
              tokens: tokens,
              onTitleTap: _onTitleTap,
              onClose: () => Navigator.pop(context),
            ),
            _ToggleRow(
              // Framed as "Block": the switch is ON when the conversation
              // is blocked (denied), OFF when allowed. The subtitle still
              // describes the actual consent state, so it reads coherently
              // either way. _toggleConsentState flips allowed<->denied
              // regardless of which value the switch reports.
              label: context.l10n.conversationSettingsSheetBlockConversation,
              subtitle: isAllowed
                  ? context.l10n.conversationSettingsSheetAllowedSubtitle
                  : context.l10n.conversationSettingsSheetBlockedSubtitle,
              value: !isAllowed,
              onChanged: (_isLoading || _consentState == null)
                  ? null
                  : (_) => _toggleConsentState(),
              tokens: tokens,
            ),
            _ToggleRow(
              // Reading preference, not a property of THIS conversation — the
              // subtitle says so, since the sheet reads as per-chat otherwise.
              label: context.l10n.conversationSettingsSheetTrimMessagesLabel,
              subtitle: _trimLongMessages
                  ? context.l10n.conversationSettingsSheetTrimMessagesOn(
                      _trimChars.round())
                  : context.l10n.conversationSettingsSheetTrimMessagesOff,
              value: _trimLongMessages,
              onChanged: _trimLoading ? null : _setTrimLongMessages,
              tokens: tokens,
            ),
            if (_trimLongMessages)
              _Slider(
                label: context.l10n.conversationSettingsSheetTrimAtLabel,
                value: _trimChars,
                min: _trimMin,
                max: _trimMax,
                valueSuffix:
                    ' ${context.l10n.conversationSettingsSheetTrimUnit}',
                onChanged: _trimLoading ? null : _setTrimChars,
              ),
            const SizedBox(height: 4),
            _MediaTabBar(tabController: _tabController, tokens: tokens),
            SizedBox(
              height: 320,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MediaGrid(
                    entries: _mediaEntries,
                    loading: _mediaLoading,
                    tokens: tokens,
                    shimmer: _shimmer,
                  ),
                  _DocsList(
                    entries: _docEntries,
                    loading: _mediaLoading,
                    tokens: tokens,
                    shimmer: _shimmer,
                  ),
                ],
              ),
            ),
            if (_showDebugOption) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Divider(color: tokens.borderSubtle, height: 1),
              ),
              _ActionTile(
                icon: Icons.bug_report_rounded,
                label: context.l10n.conversationSettingsSheetDebugModeLabel,
                subtitle: context.l10n.conversationSettingsSheetDebugModeSubtitle,
                tokens: tokens,
                onTap: () => Navigator.pop(context, 'debug'),
              ),
              _ActionTile(
                icon: Icons.download_rounded,
                label: context.l10n.conversationSettingsSheetExportMessagesLabel,
                subtitle: context.l10n.conversationSettingsSheetExportMessagesSubtitle,
                tokens: tokens,
                onTap: _exportMessages,
              ),
              _ActionTile(
                icon: Icons.save_alt_rounded,
                label: context.l10n.conversationSettingsSheetDumpLogLabel,
                subtitle: context.l10n.conversationSettingsSheetDumpLogSubtitle,
                tokens: tokens,
                onTap: _dumpLog,
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _dumpLog() async {
    final l10n = context.l10n;
    try {
      final logContent = Log.dump();
      if (logContent.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.conversationSettingsSheetLogBufferEmpty)),
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${dir.path}/publicos_log_$ts.txt');
      await file.writeAsString(logContent);
      // DELTA(desktop): share sheet → native save dialog; cancel is silent.
      await saveFileWithDialog(
        sourcePath: file.path,
        suggestedName: 'publicos_log_$ts.txt',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizedError(l10n, e, fallback: l10n.conversationSettingsSheetDumpLogFailed)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportMessages() async {
    const logTag = 'ChatExport';
    final l10n = context.l10n;
    try {
      Log.d(logTag, 'export start — topic=${widget.conversationTopic}');
      final allMessages = await PublicOSConversations.getLocalMessagesByTopic(
        widget.conversationTopic, null, false,
      );
      Log.d(logTag, 'fetched ${allMessages.length} messages from local DB');
      if (allMessages.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.conversationSettingsSheetNoMessages)),
          );
        }
        return;
      }

      allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final earliest = allMessages.first.timestamp;
      final latest = allMessages.last.timestamp;

      if (!mounted) return;

      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(earliest.year, earliest.month, earliest.day),
        lastDate: DateTime(latest.year, latest.month, latest.day, 23, 59, 59),
        initialDateRange: DateTimeRange(
          start: DateTime(earliest.year, earliest.month, earliest.day),
          end: DateTime(latest.year, latest.month, latest.day),
        ),
        helpText: l10n.conversationSettingsSheetSelectDateRange,
        saveText: l10n.conversationSettingsSheetExportAction,
      );
      if (picked == null || !mounted) return;

      final rangeStart = picked.start;
      final rangeEnd = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      final filtered = allMessages.where((m) =>
        !m.timestamp.isBefore(rangeStart) && !m.timestamp.isAfter(rangeEnd)
      ).toList();
      Log.d(logTag, 'date filter ${rangeStart.toIso8601String()}..'
          '${rangeEnd.toIso8601String()} kept ${filtered.length}/'
          '${allMessages.length} messages');

      if (filtered.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.conversationSettingsSheetNoMessagesInRange)),
          );
        }
        return;
      }

      final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
      final buf = StringBuffer();
      buf.writeln('Chat export — ${fmt.format(rangeStart)} to ${fmt.format(rangeEnd)}');
      buf.writeln('Topic: ${widget.conversationTopic}');
      buf.writeln('Messages: ${filtered.length}');
      buf.writeln('${'=' * 60}\n');

      var written = 0;
      var failed = 0;
      for (var i = 0; i < filtered.length; i++) {
        final msg = filtered[i];
        try {
          buf.writeln('[${fmt.format(msg.timestamp)}]');
          buf.writeln('  id: ${msg.id}');
          if (msg.idXmtp != null) buf.writeln('  idXmtp: ${msg.idXmtp}');
          buf.writeln('  sender: ${msg.senderAddress}');
          if (msg.senderInboxId != null) buf.writeln('  senderInboxId: ${msg.senderInboxId}');
          buf.writeln('  contentType: ${msg.content.type.name}');
          if (msg.content.typeId != null) buf.writeln('  contentTypeId: ${msg.content.typeId}');
          if (msg.content.authorityId != null) buf.writeln('  authorityId: ${msg.content.authorityId}');
          if (msg.body != null) buf.writeln('  body: ${msg.body}');
          if (msg.content.value != null) buf.writeln('  value: ${msg.content.value}');
          if (msg.content.metadata != null && msg.content.metadata!.isNotEmpty) buf.writeln('  metadata: ${msg.content.metadata}');
          if (msg.referenceMessageId != null) buf.writeln('  referenceMessageId: ${msg.referenceMessageId}');
          if (msg.parameters != null && msg.parameters!.isNotEmpty) buf.writeln('  parameters: ${msg.parameters}');
          if (msg.reactions != null && msg.reactions!.isNotEmpty) {
            buf.writeln('  reactions: ${msg.reactions!.map((r) => '${r.emoji}(${r.count})').join(', ')}');
          }
          buf.writeln('  isPending: ${msg.isPending}');
          buf.writeln('  sendFailed: ${msg.sendFailed}');
          final sNotes = _dbgStickerNotes(
            msg,
            i > 0 ? filtered[i - 1] : null,
            i < filtered.length - 1 ? filtered[i + 1] : null,
          );
          if (sNotes.isNotEmpty) buf.write(sNotes);
          buf.writeln();
          written++;
        } catch (e) {
          // Never let one unserializable message (e.g. a reply with an odd
          // payload) truncate the rest of the export.
          failed++;
          Log.w(logTag, 'failed to serialize message $i/${filtered.length} '
              '(id=${msg.id}, idXmtp=${msg.idXmtp}, type=${msg.content.typeId}): $e');
          buf.writeln('[message $i — SERIALIZE ERROR: $e]');
          buf.writeln();
        }
      }
      Log.d(logTag, 'serialized $written messages ($failed failed) — '
          '${buf.length} chars');

      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${dir.path}/chat_export_$ts.txt');
      await file.writeAsString(buf.toString());
      Log.d(logTag, 'wrote export file ${file.path} (${buf.length} chars)');
      // DELTA(desktop): share sheet → native save dialog; cancel is silent.
      await saveFileWithDialog(
        sourcePath: file.path,
        suggestedName: 'chat_export_$ts.txt',
      );
    } catch (e) {
      Log.e(logTag, 'export failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizedError(l10n, e, fallback: l10n.conversationSettingsSheetExportFailed)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Sticker debug instrumentation (export only) ---------------------------
  // Replicates the live sizing/stacking predicates so a dump shows exactly which
  // flags were read and which branch each sticker took. Mirrors message_widget
  // (_buildAttachmentContent sizing) + chat_screen (_buildMessageList stacking).
  AttachmentContent? _dbgParseAtt(dynamic v) {
    if (v is AttachmentContent) return v;
    if (v is Map<String, dynamic>) {
      try {
        return AttachmentContent.fromJson(v);
      } catch (_) {}
    }
    if (v is String && v.startsWith('{')) {
      try {
        return AttachmentContent.fromJson(jsonDecode(v) as Map<String, dynamic>);
      } catch (_) {}
    }
    return null;
  }

  bool _dbgSameMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;

  bool _dbgStackable(Message? m) {
    if (m == null || m.content.type != MessageType.attachment) return false;
    final a = _dbgParseAtt(m.content.value);
    return a != null &&
        a.isSticker &&
        (a.description == null || a.description!.isEmpty);
  }

  String _dbgStickerNotes(Message msg, Message? prev, Message? next) {
    if (msg.content.type != MessageType.attachment) return '';
    final a = _dbgParseAtt(msg.content.value);
    if (a == null) {
      return '  sticker-debug: value is ${msg.content.value.runtimeType}, '
          'NOT parseable to AttachmentContent\n';
    }
    final isGif = a.mimeType == 'image/gif';
    final hasDesc = a.description != null && a.description!.isNotEmpty;
    final isGifGif = !a.isSticker && isGif;
    final stackable = a.isSticker && !hasDesc;
    final clipNote = isGif ? 'rounded corners (gif)' : 'unclipped (alpha shape)';
    final b = StringBuffer();
    b.writeln('  sticker-debug:');
    b.writeln('    valueType: ${msg.content.value.runtimeType}'); // object vs Map vs String → reveals decode/persist path
    b.writeln('    isSticker: ${a.isSticker}');
    b.writeln('    mimeType: ${a.mimeType}   (isGif: $isGif)');
    b.writeln('    hasDescription: $hasDesc');
    b.writeln('    dataBytes: ${a.data.length}');
    b.writeln('    SIZE-decision: ${a.isSticker ? 'sticker -> screen-fraction width, natural-capped, $clipNote' : isGifGif ? 'gif-as-attachment -> FIXED screen-fraction width, proportional' : 'attachment -> fixed 300px box'}');
    b.writeln('    STACK-decision: stackable=$stackable${stackable ? '' : ' (needs isSticker && no-description)'}');
    if (stackable) {
      // Mirror chat_screen: a sticker run is same sender + same clock-minute.
      final prevOk = _dbgStackable(prev) &&
          prev!.senderInboxId == msg.senderInboxId &&
          _dbgSameMinute(prev.timestamp, msg.timestamp);
      final nextOk = _dbgStackable(next) &&
          next!.senderInboxId == msg.senderInboxId &&
          _dbgSameMinute(next.timestamp, msg.timestamp);
      b.writeln('    stacksWithPrev: $prevOk');
      b.writeln('    stacksWithNext: $nextOk  (run = same sender, same clock-minute)');
    }
    return b.toString();
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final GlassTokens tokens;
  final VoidCallback onTitleTap;
  final VoidCallback onClose;
  const _SheetHeader({
    required this.title,
    required this.tokens,
    required this.onTitleTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTitleTap,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// Trim-budget slider row. Literal copy of the feeds settings sheet's
/// `_Slider` (label + monospace value + thin glass track) so the two trim
/// controls read identically; only difference is a nullable [onChanged] to
/// disable the control while the persisted value is still loading.
class _Slider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  /// Unit displayed after the numeric value.
  final String valueSuffix;

  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.valueSuffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: tokens.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '${value.toStringAsFixed(0)}$valueSuffix',
                style: TextStyle(
                  color: tokens.starkWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: tokens.starkWhite,
              inactiveTrackColor: tokens.borderSubtle,
              thumbColor: tokens.starkWhite,
              overlayColor: tokens.starkWhite.withValues(alpha: 0.12),
              trackHeight: 2,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              // ~50 divisions so the thumb doesn't feel jittery at every
              // pixel movement (matches the feeds sheet).
              divisions: (max - min) > 50 ? 50 : (max - min).toInt(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final GlassTokens tokens;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: tokens.connectedAccent,
          ),
        ],
      ),
    );
  }
}

class _MediaEntry {
  final Uint8List bytes;
  final String filename;
  final bool isVideo;
  final DateTime timestamp;
  final String messageId;
  const _MediaEntry({
    required this.bytes,
    required this.filename,
    required this.isVideo,
    required this.timestamp,
    required this.messageId,
  });
}

class _MediaTabBar extends StatelessWidget {
  final TabController tabController;
  final GlassTokens tokens;
  const _MediaTabBar({required this.tabController, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        labelColor: tokens.starkWhite,
        unselectedLabelColor: tokens.textDim,
        indicatorColor: tokens.connectedAccent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        tabs: [
          Tab(text: context.l10n.conversationSettingsSheetMediaTab),
          Tab(text: context.l10n.conversationSettingsSheetDocsTab),
        ],
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  final List<_MediaEntry>? entries;
  final bool loading;
  final GlassTokens tokens;
  final Animation<double> shimmer;
  const _MediaGrid({
    required this.entries,
    required this.loading,
    required this.tokens,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      // Skeleton in the grid's own shape, so nothing jumps when it lands.
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (_, __) => ShimmerBox(
          progress: shimmer,
          height: double.infinity,
          radius: 4,
          base: tokens.glassFill,
          highlight: tokens.borderMedium,
        ),
      );
    }
    final list = entries ?? const [];
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            context.l10n.conversationSettingsSheetNoMedia,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, i) => _MediaTile(entry: list[i], tokens: tokens),
    );
  }
}

/// One shared non-media file. Exactly one of [inline] (bytes in the message)
/// or [remote] (metadata only; fetched + decrypted on tap) is set.
class _DocEntry {
  final String filename;
  final int? size;
  final DateTime timestamp;
  final String messageId;
  final AttachmentContent? inline;
  final RemoteAttachmentContent? remote;
  const _DocEntry({
    required this.filename,
    required this.size,
    required this.timestamp,
    required this.messageId,
    this.inline,
    this.remote,
  });
}

/// Docs tab: a list, newest first. Each row has the type tile on the left,
/// then name.ext and size · date, then an open glyph. Tap opens the file with
/// the system, fetching + decrypting a remote one first (cache-first, then
/// cached for next time), the same path the chat's document chip uses.
class _DocsList extends StatefulWidget {
  final List<_DocEntry>? entries;
  final bool loading;
  final GlassTokens tokens;
  final Animation<double> shimmer;
  const _DocsList({
    required this.entries,
    required this.loading,
    required this.tokens,
    required this.shimmer,
  });

  @override
  State<_DocsList> createState() => _DocsListState();
}

class _DocsListState extends State<_DocsList> {
  String? _opening; // messageId of the row being fetched/opened

  Future<void> _open(_DocEntry e) async {
    if (_opening != null) return;
    setState(() => _opening = e.messageId);
    try {
      AttachmentContent? file = e.inline;
      final rc = e.remote;
      if (file == null && rc != null) {
        file = await PublicOSAttachmentCache.getCachedAttachment(rc.contentDigest);
        if (file == null) {
          file = await RemoteAttachmentCodec.load(rc);
          await PublicOSAttachmentCache.putCachedAttachment(
            contentDigest: rc.contentDigest,
            attachment: file,
          );
        }
      }
      if (file == null) throw StateError('no file');
      final ok = await openFileWithSystem(
        bytes: file.data,
        filename: e.filename,
        mimeType: file.mimeType,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.documentOpenFailed)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.messageWidgetCouldntLoadAttachment)),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    if (widget.loading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            ShimmerBox(
              progress: widget.shimmer,
              width: 40,
              height: 40,
              radius: 10,
              base: tokens.glassFill,
              highlight: tokens.borderMedium,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(progress: widget.shimmer, width: 170, height: 12, radius: 4, base: tokens.glassFill, highlight: tokens.borderMedium),
                  const SizedBox(height: 6),
                  ShimmerBox(progress: widget.shimmer, width: 90, height: 10, radius: 4, base: tokens.glassFill, highlight: tokens.borderMedium),
                ],
              ),
            ),
          ]),
        ),
      );
    }
    final list = widget.entries ?? const <_DocEntry>[];
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            context.l10n.conversationSettingsSheetNoDocs,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      );
    }
    final dateFmt = DateFormat.MMMd(Localizations.localeOf(context).toString());
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final e = list[i];
        final busy = _opening == e.messageId;
        final meta = [
          if (e.size != null && e.size! > 0) formatFileSize(e.size!),
          dateFmt.format(e.timestamp),
        ].join(' · ');
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: busy ? null : () => _open(e),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  DocTypeTile(filename: e.filename),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.filename,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            color: tokens.starkWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            color: tokens.textDim,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    busy ? Icons.hourglass_empty_rounded : Icons.open_in_new_rounded,
                    color: tokens.textDim,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MediaTile extends StatelessWidget {
  final _MediaEntry entry;
  final GlassTokens tokens;
  const _MediaTile({required this.entry, required this.tokens});

  @override
  Widget build(BuildContext context) {
    if (entry.isVideo) {
      final heroTag = 'conv_media_${entry.messageId}_${entry.filename}';
      return GestureDetector(
        onTap: () => _openVideo(context),
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ZeroCachedThumbnailWidget(
                  source: ThumbnailSource.bytes(
                    entry.bytes,
                    cacheKey: 'msg_${entry.messageId}',
                  ),
                  fit: BoxFit.cover,
                  placeholder: (_) => Container(color: Colors.black.withValues(alpha: 0.45)),
                  errorBuilder: (_, __) => Container(color: Colors.black.withValues(alpha: 0.45)),
                ),
                Container(color: Colors.black.withValues(alpha: 0.18)),
                Center(
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    color: tokens.starkWhite,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return TappableImage(
      imageData: entry.bytes,
      heroTag: 'conv_media_${entry.messageId}_${entry.filename}',
      borderRadius: BorderRadius.circular(4),
      fit: BoxFit.cover,
    );
  }

  void _openVideo(BuildContext context) {
    final heroTag = 'conv_media_${entry.messageId}_${entry.filename}';
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (ctx, _, __) => MediaOverlay(
          videoBytes: entry.bytes,
          filename: entry.filename,
          heroTag: heroTag,
          onClose: () => Navigator.pop(ctx),
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final GlassTokens tokens;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Icon(icon, color: tokens.starkWhite, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: tokens.starkWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
              Icon(Icons.chevron_right_rounded, color: tokens.textDim),
            ],
          ),
        ),
      ),
    );
  }
}
