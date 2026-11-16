import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_mentions/zero_mentions.dart';

import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/widgets/messages/reaction_details_sheet.dart';
import 'package:publicos_desktop/widgets/feeds/emoji_picker_dialog.dart';
import 'package:publicos_desktop/widgets/feeds/reaction_button.dart';
import 'package:publicos_desktop/widgets/feeds/reaction_quick_bar.dart';
import 'package:publicos_desktop/widgets/feeds/mention_text.dart';
import 'package:publicos_desktop/widgets/feeds/translation_service.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_widget.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/widgets/flag_sheet.dart';

/// A single comment in the thread, with its nested replies rendered
/// recursively. Glass-styled to match the post card + sheet aesthetic.
///
/// Layout (per graph's pattern):
///   - Avatar (28px GlassContactIcon) + author line + content + actions row
///   - Nested replies indented and connected by a 1px borderSubtle rail
///     drawn at left=16
///   - "Load more replies" button when [comment.hasMore]
///   - Author-only context menu (Edit / Delete) on the header row
class CommentCard extends StatefulWidget {
  final Comment comment;
  final Post post;
  final void Function(Comment) onReply;
  final void Function(Comment, int) onVote;
  final void Function(Comment, String) onEdit;
  final void Function(Comment) onDelete;
  final void Function(Comment) onLoadMoreReplies;
  /// The server toggle: true = added, false = removed, null = failed.
  final Future<bool?> Function(Comment, String) onReact;

  /// Optional. When set, surfaces moderation items in the comment's 3-dot
  /// menu for users who are post author OR channel owner but not the
  /// comment's author (e.g. "Block from commenting on this post").
  final void Function(Comment)? onBlockCommenter;

  /// True when the viewer can moderate this thread — author of the post or
  /// owner of the channel. Drives visibility of the moderation items.
  final bool canModerate;
  final String? myAddress;
  final int depth;

  /// The parent comment when this card renders a reply — the reply's
  /// single-bind verification target. Null for top-level comments (which
  /// verify against the post).
  final Comment? replyToParent;

  /// Shared per-page resolver for @[0xAddr] mention tokens in the body.
  /// Null → MentionText falls back to a per-widget resolver.
  final MentionResolver? mentionResolver;

  const CommentCard({
    super.key,
    required this.comment,
    required this.post,
    required this.onReply,
    required this.onVote,
    required this.onEdit,
    required this.onDelete,
    required this.onLoadMoreReplies,
    required this.onReact,
    this.onBlockCommenter,
    this.canModerate = false,
    this.myAddress,
    this.depth = 0,
    this.replyToParent,
    this.mentionResolver,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  static const double _avatarSize = 28;
  static const int _maxDepth = 4;

  Contact? _authorContact;
  bool _showReplies = true;

  /// This session's reaction changes laid over the comment's counts until
  /// the parent hands a new comment back: emoji -> added (true) / removed
  /// (false). Comments are optimistic.
  final Map<String, bool> _optimistic = {};

  /// Bumped on every add: [ReactionButton] jellies on it.
  int _reactPulse = 0;
  bool _editing = false;
  // Mention-aware: stored @[0xAddr] tokens rehydrate to styled @displayname
  // (names come from the shared per-page resolver's cache — warm by the time
  // anyone edits, since the body render already resolved them). serialize()
  // restores the wire form on save.
  late final MentionTextEditingController _editCtrl;

  String _mentionEditName(String address) =>
      widget.mentionResolver?.nameOf(address) ?? truncatedAddress(address);

  // ---- Translation state (transient — zero persistence) -----------------
  // Mirrors the post-card affordance: detect on init, a translate icon on the
  // name row, in-place swap, original<->translation toggle.
  final _translator = TranslationService.instance;
  String? _detectedLang;
  bool _translating = false;
  String _translatingLabel = 'Translating…';
  bool _showingTranslation = false;
  String? _tContent;
  String? _translateError;

  // ---- Signature / binding verification (memoized — ecRecover is not
  // free, and build() runs often). Recomputed when the comment instance
  // changes (edit applied, refresh). Only bad outcomes surface UI; unsigned
  // and legacy-unbound comments render exactly as before.
  CommentVerificationResult? _verification;
  CommentVerificationResult get _verifyResult =>
      _verification ??= CommentSignatureVerifier.verify(
        widget.comment,
        widget.post,
        replyToParent: widget.replyToParent,
      );

  String get _targetLang => _translator.deviceLanguage;
  bool get _canTranslateComment =>
      TranslationService.isSupported &&
      _detectedLang != null &&
      _detectedLang != _targetLang &&
      _translator.supportsPair(_detectedLang!, _targetLang);
  bool get _hasTranslation => _tContent != null;

  @override
  void initState() {
    super.initState();
    _editCtrl = MentionTextEditingController.fromRaw(
      widget.comment.content,
      displayNameFor: _mentionEditName,
      mentionStyle: const TextStyle(
        color: Color(0xFF64FFDA),
        fontWeight: FontWeight.w600,
      ),
    );
    _resolveAuthor();
    _detectCommentLanguage();
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CommentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.comment, widget.comment)) _verification = null;
    // The server spoke (the parent's new comment carries the counts): the
    // optimistic layer is settled, keeping it would count twice.
    if (oldWidget.comment.uid != widget.comment.uid ||
        !identical(oldWidget.comment.reactions, widget.comment.reactions)) {
      _optimistic.clear();
    }
    // A card can be handed a different comment (a new one landing above it):
    // never keep the previous comment's author, or one account's comment
    // shows as another account's.
    if (oldWidget.comment.accountAddress.toLowerCase() !=
        widget.comment.accountAddress.toLowerCase()) {
      setState(() => _authorContact = null);
      _resolveAuthor();
    }
    if (oldWidget.comment.content != widget.comment.content && !_editing) {
      _editCtrl.loadRaw(widget.comment.content);
      // Content changed (edit applied) — drop any cached translation and
      // re-detect against the new text.
      setState(() {
        _tContent = null;
        _showingTranslation = false;
        _translateError = null;
      });
      _detectCommentLanguage();
    }
  }

  Future<void> _detectCommentLanguage() async {
    if (!TranslationService.isSupported) return;
    if (!await TranslationPrefs.isEnabled()) return;
    final src = widget.comment.content;
    if (src.trim().isEmpty) return;
    var code = await _translator.detect(src);
    if (code != null && !await TranslationPrefs.isSourceSuggested(code)) {
      code = null;
    }
    if (mounted) setState(() => _detectedLang = code);
  }

  Future<void> _onTapTranslate() async {
    if (_hasTranslation) {
      setState(() => _showingTranslation = !_showingTranslation);
      return;
    }
    final from = _detectedLang!, to = _targetLang;
    final needsDownload = !await _translator.isModelReady(from, to);
    if (needsDownload) {
      final ok = await _confirmModelDownload(from, to);
      if (ok != true) return;
    }
    final wifiOnly = await TranslationPrefs.wifiOnly();
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      _translating = true;
      _translateError = null;
      _translatingLabel = needsDownload
          ? (wifiOnly
              ? l10n.commentCardTranslateWaitingWifi
              : l10n.commentCardTranslateDownloadingLang)
          : l10n.commentCardTranslating;
    });
    try {
      if (needsDownload) {
        await _translator.ensureModel(from, to, requireWifi: wifiOnly);
        if (!mounted) return;
        setState(() => _translatingLabel = l10n.commentCardTranslating);
      }
      final translated = await _translator.translate(widget.comment.content,
          from: from, to: to, requireWifi: wifiOnly);
      if (!mounted) return;
      setState(() {
        _tContent = translated;
        _showingTranslation = true;
        _translating = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _translateError =
              localizedError(l10n, e, fallback: l10n.errTranslateFailed);
          _translating = false;
        });
      }
    }
  }

  Future<bool?> _confirmModelDownload(String from, String to) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final fromName = kPostLangNames[from] ?? from.toUpperCase();
    final toName = kPostLangNames[to] ?? to.toUpperCase();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        constraints: const BoxConstraints(
            minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        title: Text(l10n.commentCardDownloadLangPackTitle,
            style: TextStyle(color: tokens.starkWhite)),
        content: Text(
          l10n.commentCardDownloadLangPackBody(fromName, toName),
          style: TextStyle(color: tokens.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text(l10n.dlgCancel, style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.commentCardDownload,
              style: TextStyle(
                color: tokens.connectedAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _showTranslateButton =>
      _translating || _translateError != null || _canTranslateComment;

  /// The header's trailing actions, mirroring the post card: the
  /// translate button (when this comment can be translated),
  /// then the 3-dot menu. Passed into `_buildHeader`'s name row, which
  /// centres them on the name.
  Widget _buildHeaderActions(GlassTokens tokens, Comment comment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!comment.isDeleted && !_editing && _showTranslateButton)
          _buildTranslateButton(tokens),
        if (!comment.isDeleted)
          SizedBox(width: 26, height: 17, child: _buildMenu(tokens)),
      ],
    );
  }

  /// Translate, collapsed to one icon left of the 3-dot menu. Same states
  /// as the post
  /// card's, with the words in the tooltip:
  ///  - can translate → dim icon;
  ///  - working (download / translate) → the bare pixel rain (peripheral);
  ///  - showing the translation → accent icon (tap = show original);
  ///  - failed → error-tinted icon (tap = retry).
  Widget _buildTranslateButton(GlassTokens tokens) {
    final l10n = context.l10n;
    if (_translating) {
      return Tooltip(
        message: _translatingLabel,
        child: const SizedBox(
          width: 24,
          height: 17,
          child: Center(child: PixelRainLoadingWidget(size: 12)),
        ),
      );
    }
    final String tip;
    final Color color;
    if (_translateError != null) {
      tip = l10n.commentCardTranslateFailed;
      color = Theme.of(context).colorScheme.error;
    } else {
      final detectedName =
          kPostLangNames[_detectedLang!] ?? _detectedLang!.toUpperCase();
      if (!_hasTranslation) {
        tip = l10n.commentCardTranslateFrom(detectedName);
        color = tokens.textDim;
      } else if (_showingTranslation) {
        tip = l10n.commentCardTranslatedFrom(detectedName);
        color = tokens.connectedAccent;
      } else {
        tip = l10n.commentCardShowTranslation(
            kPostLangNames[_targetLang] ?? _targetLang.toUpperCase());
        color = tokens.textDim;
      }
    }
    return Tooltip(
      message: tip,
      child: InkResponse(
        onTap: _onTapTranslate,
        radius: 14,
        child: SizedBox(
          width: 24,
          height: 17,
          child: Icon(Icons.translate_rounded, size: 14, color: color),
        ),
      ),
    );
  }

  Future<void> _resolveAuthor() async {
    final addr = widget.comment.accountAddress;
    if (addr.isEmpty) return;
    try {
      var c = await PublicOSContacts.searchContacts(addr);
      if (c == null) {
        c = await PublicOSContacts.resolveByIdentifier(addr);
        if (c != null) await PublicOSContacts.saveContact(c);
      }
      // Drop a late answer for an address this card no longer shows.
      if (mounted && c != null && addr == widget.comment.accountAddress) {
        setState(() => _authorContact = c);
      }
    } catch (_) {}
  }

  /// The avatar opens the author's profile in the Browser, like a post's.
  VoidCallback? get _openAuthorProfile {
    final c = _authorContact;
    final a = c?.publicosAddress?.eip55With0x;
    if (c == null || a == null ||
        a == '0x0000000000000000000000000000000000000000') {
      return null;
    }
    return () => AppNav.toContact(context, c);
  }

  /// The comment's own address, the flag target (null off-network).
  String? get _flagUrl =>
      RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(widget.comment.accountAddress)
          ? commentFlagUrl(widget.comment.targetUrl, widget.comment.uid)
          : null;

  bool get _isOwn =>
      widget.myAddress != null &&
      widget.comment.accountAddress.toLowerCase() ==
          widget.myAddress!.toLowerCase();

  void _startEdit() {
    _editCtrl.loadRaw(widget.comment.content);
    setState(() => _editing = true);
  }

  void _cancelEdit() => setState(() => _editing = false);

  void _saveEdit() {
    // Wire form — mention runs back to @[0xAddr] tokens.
    final next = _editCtrl.serialize().trim();
    if (next.isEmpty || next == widget.comment.content) {
      _cancelEdit();
      return;
    }
    setState(() => _editing = false);
    widget.onEdit(widget.comment, next);
  }

  Future<void> _confirmDelete() async {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        constraints: const BoxConstraints(
            minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        title: Text(l10n.commentCardDeleteTitle,
            style: TextStyle(color: tokens.starkWhite)),
        content: Text(
          l10n.commentCardDeleteBody,
          style: TextStyle(color: tokens.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text(l10n.dlgCancel, style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.commentCardDelete,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true) widget.onDelete(widget.comment);
  }

  // ---- Reactions: one button + the sheet ----------------------------------

  /// The comment's counts plus this session's changes, most popular first.
  List<(String, int)> _displayedReactions() {
    final m = <String, int>{
      for (final r in widget.comment.reactions) r.emoji: r.count,
    };
    _optimistic.forEach((e, added) {
      final n = (m[e] ?? 0) + (added ? 1 : -1);
      if (n > 0) {
        m[e] = n;
      } else {
        m.remove(e);
      }
    });
    final out = [for (final e in m.entries) (e.key, e.value)];
    out.sort((a, b) => b.$2.compareTo(a.$2));
    return out;
  }

  /// The post author's reaction badge: the server's word, except when the
  /// reader IS the post's author, whose own reactions show at once (their
  /// first emoji), optimistic like the button.
  CommentAuthorReaction? get _authorReaction {
    final me = widget.myAddress?.toLowerCase();
    final author = (widget.post.authorAddress ??
            widget.post.channelOwnerAddress)
        ?.toLowerCase();
    if (me != null && author != null && me == author) {
      final mine = _myEmojis();
      return mine.isEmpty
          ? null
          : CommentAuthorReaction(address: widget.myAddress!, emoji: mine.first);
    }
    return widget.comment.postAuthorReaction;
  }

  /// The reader's emojis here, in the order added; empty = the empty heart.
  List<String> _myEmojis() {
    final out = <String>[
      for (final e in widget.comment.userReactionEmojis)
        if (_optimistic[e] != false) e,
    ];
    _optimistic.forEach((e, added) {
      if (added && !out.contains(e)) out.add(e);
    });
    return out;
  }

  /// ADD-only, optimistic: the count and the jelly land at once. The parent's
  /// verb is a toggle, so a "removed" answer (it was there already) is sent
  /// again; a failure rolls back. True = the reaction is on.
  Future<bool> _addReaction(String emoji) async {
    if (!PublicOSChannels.canReact(widget.post)) return false;
    if (_myEmojis().contains(emoji)) return true;
    HapticFeedback.mediumImpact();
    setState(() {
      _optimistic[emoji] = true;
      _reactPulse++;
    });
    var r = await widget.onReact(widget.comment, emoji);
    if (r == false) r = await widget.onReact(widget.comment, emoji);
    if (r != true) {
      if (mounted) setState(() => _optimistic.remove(emoji));
      return false;
    }
    return true;
  }

  /// The sheet's trash: the toggle again. True = it is gone.
  Future<bool> _removeReaction(String emoji) async {
    final r = await widget.onReact(widget.comment, emoji);
    if (r == true) {
      // It added (we were wrong about having it): put it back.
      await widget.onReact(widget.comment, emoji);
      return false;
    }
    return r == false;
  }

  /// The who-reacted sheet, the post's own: opens at once on the card's
  /// counts, then fills its list
  /// from `GET …/comments/:uid/reactions`.
  void _showReactionSheet() {
    final mine = _myEmojis();
    final instant = [
      for (final (e, n) in _displayedReactions())
        MessageReactionSummary(
          emoji: e,
          count: n,
          hasMyReaction: mine.contains(e),
          senderInboxIds: const [],
        ),
    ];
    // DESKTOP DELTA: the post card's host, a centered card in a Dialog
    // (`asCard`), not the client's bottom sheet. Same widget, same args.
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (sheetCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              maxWidth: DialogWidth.m, maxHeight: 560),
          child: ReactionDetailsSheet(
            asCard: true,
            reactions: instant,
            load: _loadReactionDetails,
            onContactTap: (c) {
              Navigator.of(sheetCtx).pop();
              AppNav.toContact(context, c);
            },
            resolveMissing: (addr) async {
              final c = await PublicOSContacts.resolveByIdentifier(addr);
              if (c != null) await PublicOSContacts.saveContact(c);
              return c;
            },
            onUnresolvedTap: (addr) {
              Navigator.of(sheetCtx).pop();
              AppNav.toProfile(context, addr);
            },
            currentUserId: widget.myAddress,
            onRemoveMyReaction: _removeReaction,
            onAddReaction: _addReaction,
          ),
        ),
      ),
    );
  }

  Future<({List<MessageReactionSummary> reactions, Map<String, Contact> contacts})?>
      _loadReactionDetails() async {
    final data = await PublicOSChannels.getCommentReactions(
        post: widget.post, comment: widget.comment);
    if (data == null) return null;
    final me = widget.myAddress?.toLowerCase();
    final byEmoji = <String, List<String>>{};
    for (final ur in data.userReactions) {
      byEmoji.putIfAbsent(ur.emoji, () => []).add(ur.accountAddress);
    }
    final summaries = [
      for (final r in data.reactions)
        MessageReactionSummary(
          emoji: r.emoji,
          count: r.count,
          hasMyReaction: me != null &&
              (byEmoji[r.emoji] ?? const []).any((a) => a.toLowerCase() == me),
          senderInboxIds: byEmoji[r.emoji] ?? const [],
        ),
    ];
    final addrs = byEmoji.values.expand((a) => a).toSet().toList();
    final found = await Future.wait(addrs.map(PublicOSContacts.searchContacts));
    final contacts = <String, Contact>{
      for (var i = 0; i < addrs.length; i++)
        if (found[i] != null) addrs[i]: found[i]!,
    };
    return (reactions: summaries, contacts: contacts);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final comment = widget.comment;
    final isRoot = widget.depth == 0;
    final hasChildren = comment.replies.isNotEmpty || comment.hasMore;
    final displayName = _authorContact?.displayName ??
        comment.username ??
        _shortAddress(comment.accountAddress);

    return Padding(
      padding: EdgeInsets.only(
        left: isRoot ? 16 : 36,
        right: isRoot ? 16 : 0,
        top: 10,
        bottom: 2,
      ),
      // The reply rail belongs to the PARENT: it starts 4 px under this
      // comment's avatar and runs down past its replies, centred on the
      // avatar. Drawn behind the column, so nothing moves.
      child: Stack(
        children: [
          if (hasChildren && _showReplies)
            Positioned(
              left: _avatarSize / 2 - 0.5,
              top: _avatarSize + 4,
              bottom: 0,
              child: Container(width: 1, color: tokens.borderSubtle),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + content. The 3-dot menu (and translate) ride the name row
              // inside `_buildHeader`, in fixed 17 px boxes so they centre on the
              // name without inflating the row much.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_authorContact != null && !comment.isDeleted)
                    GlassContactIcon(
                      contact: _authorContact,
                      size: _avatarSize,
                      onTap: _openAuthorProfile,
                    )
                  else
                    GlassContactIcon(
                      address: comment.accountAddress,
                      size: _avatarSize,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(tokens, comment, displayName),
                        const SizedBox(height: 4),
                        if (_editing)
                          _buildEditor(tokens)
                        else if (comment.isDeleted)
                          Text(
                            context.l10n.commentCardDeleted,
                            style: TextStyle(
                              color: tokens.textDim,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          MentionText(
                            (_showingTranslation && _tContent != null)
                                ? _tContent!
                                : comment.content,
                            resolver: widget.mentionResolver,
                            style: TextStyle(
                              color: tokens.starkWhite.withValues(alpha: 0.92),
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                        if (!comment.isDeleted && !_editing) ...[
                          const SizedBox(height: 6),
                          _buildActionsRow(tokens, comment, hasChildren),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Nested replies — the rail is drawn by the Stack above.
              if (hasChildren && _showReplies)
                Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...comment.replies.map(
                          (r) => CommentCard(
                            key: ValueKey(r.uid),
                            comment: r,
                            post: widget.post,
                            onReply: widget.onReply,
                            onVote: widget.onVote,
                            onEdit: widget.onEdit,
                            onDelete: widget.onDelete,
                            onLoadMoreReplies: widget.onLoadMoreReplies,
                            onReact: widget.onReact,
                            onBlockCommenter: widget.onBlockCommenter,
                            canModerate: widget.canModerate,
                            myAddress: widget.myAddress,
                            mentionResolver: widget.mentionResolver,
                            depth: (widget.depth + 1).clamp(0, _maxDepth),
                            replyToParent: comment,
                          ),
                        ),
                        if (comment.hasMore)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 6, 0, 6),
                            child: InkWell(
                              onTap: () => widget.onLoadMoreReplies(comment),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.more_horiz_rounded,
                                      size: 14,
                                      color: tokens.textDim,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      context.l10n.commentCardLoadMoreReplies,
                                      style: TextStyle(
                                        color: tokens.textDim,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(GlassTokens tokens, Comment comment, String displayName) {
    // Explicit height: 1.2 on every text style — without it, the default
    // font leading inflates the row and the name visually drifts below the
    // avatar's vertical center. Mirrors the post card's author line.
    return DefaultTextStyle.merge(
      style: const TextStyle(height: 1.2),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    comment.isDeleted
                        ? context.l10n.commentCardDeleted
                        : displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: comment.isDeleted
                          ? tokens.textDim
                          : tokens.starkWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontStyle: comment.isDeleted ? FontStyle.italic : null,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('·',
                    style: TextStyle(
                        color: tokens.textDim, fontSize: 12, height: 1.2)),
                const SizedBox(width: 6),
                Flexible(
                  flex: 0,
                  child: Text(
                    comment.formattedDate +
                        (comment.dateModified != null
                            ? '  ${context.l10n.commentCardEdited}'
                            : ''),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: tokens.textDim, fontSize: 12, height: 1.2),
                  ),
                ),
                // The post's author reacted to this comment: their mini avatar
                // with their emoji in front, right of the time.
                if (!comment.isDeleted && _authorReaction != null) ...[
                  // 8, not the row's 6: it sits 2 px further right.
                  const SizedBox(width: 8),
                  _AuthorReactionBadge(reaction: _authorReaction!),
                ],
                // Content-hash-binding check: badge only on bad outcomes (bad
                // signature, or a comment re-pointed at content it never signed).
                // Unsigned / legacy / edited-since states stay invisible.
                if (!comment.isDeleted && _verifyResult.isBad) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: _verifyResult.reason,
                    child: Icon(
                      Icons.gpp_bad_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildHeaderActions(tokens, comment),
        ],
      ),
    );
  }

  Widget _buildMenu(GlassTokens tokens) {
    final showAuthorActions = _isOwn;
    final showModerationActions =
        widget.canModerate && !_isOwn && widget.onBlockCommenter != null;
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 14,
        color: tokens.textDim,
      ),
      padding: EdgeInsets.zero,
      tooltip: '',
      iconSize: 14,
      splashRadius: 14,
      color: tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tokens.borderSubtle),
      ),
      onSelected: (v) {
        if (v == 'edit') _startEdit();
        if (v == 'delete') _confirmDelete();
        if (v == 'copy') _copyText();
        if (v == 'block') _confirmBlock();
        if (v == 'flag') {
          showFlagSheet(context,
              owner: EthereumAddress.fromHex(widget.comment.accountAddress),
              kind: FlagTargetKind.comment,
              url: _flagUrl!);
        }
      },
      itemBuilder: (_) => [
        _commentMenuItem(
          value: 'copy',
          icon: Icons.content_copy_rounded,
          label: context.l10n.commentCardCopyText,
          tokens: tokens,
        ),
        if (showAuthorActions)
          _commentMenuItem(
            value: 'edit',
            icon: Icons.edit_outlined,
            label: context.l10n.commentCardEdit,
            tokens: tokens,
          ),
        if (showAuthorActions)
          _commentMenuItem(
            value: 'delete',
            icon: Icons.delete_outline_rounded,
            label: context.l10n.commentCardDelete,
            destructive: true,
            tokens: tokens,
          ),
        if (!_isOwn && widget.myAddress != null && _flagUrl != null)
          _commentMenuItem(
            value: 'flag',
            icon: Icons.flag_outlined,
            label: context.l10n.flagAction,
            tokens: tokens,
          ),
        if (showModerationActions)
          _commentMenuItem(
            value: 'block',
            icon: Icons.block_rounded,
            label: context.l10n.commentCardBlockFromCommenting,
            destructive: true,
            tokens: tokens,
          ),
      ],
    );
  }

  PopupMenuItem<String> _commentMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required GlassTokens tokens,
    bool destructive = false,
  }) {
    final color =
        destructive ? Theme.of(context).colorScheme.error : tokens.starkWhite;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: widget.comment.content));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.commentCardCommentCopied),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmBlock() async {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final addr = widget.comment.accountAddress;
    final shortAddr = addr.length >= 10
        ? '${addr.substring(0, 6)}…${addr.substring(addr.length - 4)}'
        : addr;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        constraints: const BoxConstraints(
            minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        title: Text(l10n.commentCardBlockTitle,
            style: TextStyle(color: tokens.starkWhite)),
        content: Text(
          l10n.commentCardBlockBody(shortAddr),
          style: TextStyle(color: tokens.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text(l10n.dlgCancel, style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.commentCardBlock,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true) widget.onBlockCommenter?.call(widget.comment);
  }

  Widget _buildEditor(GlassTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: TextField(
            controller: _editCtrl,
            autofocus: true,
            minLines: 1,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: tokens.starkWhite, fontSize: 14),
            decoration: InputDecoration(
              hintStyle: TextStyle(color: tokens.textDim),
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _cancelEdit,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                context.l10n.dlgCancel,
                style: TextStyle(color: tokens.textDim, fontSize: 12),
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: _saveEdit,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                context.l10n.commentCardSave,
                style: TextStyle(
                  color: tokens.connectedAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionsRow(
      GlassTokens tokens, Comment comment, bool hasChildren) {
    final upActive = comment.userVote == 1;
    final downActive = comment.userVote == -1;
    final scoreColor = upActive
        ? tokens.connectedAccent
        : downActive
            ? tokens.fallbackAccent
            : tokens.textDim;
    return Row(
      children: [
        _Chip(
          icon: Icons.arrow_upward_rounded,
          label: comment.score == 0
              ? context.l10n.commentCardVote
              : '${comment.score}',
          color: upActive
              ? tokens.connectedAccent
              : downActive
                  ? tokens.fallbackAccent
                  : tokens.textDim,
          activeColor: scoreColor,
          onTap: () => widget.onVote(comment, 1),
        ),
        const SizedBox(width: 6),
        _Chip(
          icon: Icons.arrow_downward_rounded,
          label: '',
          color: downActive ? tokens.fallbackAccent : tokens.textDim,
          activeColor: scoreColor,
          onTap: () => widget.onVote(comment, -1),
        ),
        const SizedBox(width: 14),
        _Chip(
          icon: Icons.reply_rounded,
          label: context.l10n.commentCardReply,
          color: tokens.textDim,
          onTap: () => widget.onReply(comment),
        ),
        const SizedBox(width: 14),
        // The single reaction button.
        // Desktop: the emoji 17 / count 14 match the heart, nudged up 1.5 px
        // (Segoe UI Emoji sits low), and the whole button sits 2 px lower to
        // share Vote / Reply's line.
        Flexible(
          child: Transform.translate(
            offset: const Offset(0, 2),
            child: ReactionButton(
              reactions: _displayedReactions(),
              mine: _myEmojis(),
              canReact: PublicOSChannels.canReact(widget.post),
              pulse: _reactPulse,
              onHeart: () => _addReaction(ReactionPrefs.doubleTapEmojiSync),
              onOpen: _showReactionSheet,
              // Long press / long left click: the quick row.
              onLongPress: PublicOSChannels.canReact(widget.post)
                  ? (anchor) => ReactionQuickBar.show(
                        anchor,
                        onPick: _addReaction,
                        onMore: () async {
                          final e = await showEmojiPickerDialog(context);
                          if (e != null && mounted) _addReaction(e);
                        },
                      )
                  : null,
              // The heart 18 px, padding 8/6: a ~34 x 30 tap area.
              emojiSize: 17,
              countSize: 14,
              emojiNudge: -1.5,
            ),
          ),
        ),
        if (hasChildren) ...[
          const SizedBox(width: 14),
          _Chip(
            icon: _showReplies
                ? Icons.unfold_less_rounded
                : Icons.unfold_more_rounded,
            label: _showReplies
                ? ''
                : context.l10n.commentCardReplyCount(comment.replies.length),
            color: tokens.textDim,
            onTap: () => setState(() => _showReplies = !_showReplies),
          ),
        ],
      ],
    );
  }

  static String _shortAddress(String addr) {
    if (addr.length <= 14) return addr;
    return '${addr.substring(0, 6)}…${addr.substring(addr.length - 4)}';
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? activeColor;
  final VoidCallback onTap;


  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

/// The post's author's reaction on a comment: their mini avatar, their emoji
/// overlapping its lower right, in front. The author is looked up
/// once per address for the whole thread (local contacts, then the chain).
class _AuthorReactionBadge extends StatefulWidget {
  final CommentAuthorReaction reaction;

  const _AuthorReactionBadge({required this.reaction});

  static final Map<String, Future<Contact?>> _lookups = {};

  static Future<Contact?> _lookup(String address) =>
      _lookups.putIfAbsent(address.toLowerCase(), () async {
        try {
          var c = await PublicOSContacts.searchContacts(address);
          if (c == null) {
            c = await PublicOSContacts.resolveByIdentifier(address);
            if (c != null) await PublicOSContacts.saveContact(c);
          }
          return c;
        } catch (_) {
          return null;
        }
      });

  @override
  State<_AuthorReactionBadge> createState() => _AuthorReactionBadgeState();
}

class _AuthorReactionBadgeState extends State<_AuthorReactionBadge> {
  /// DESKTOP DELTA: both 4 px bigger than the phone's 16 / 7.
  static const double _avatar = 20;

  /// The phone's 7 is a third of a 12 px emoji by area; no background circle.
  static const double _emoji = 11;

  Contact? _contact;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_AuthorReactionBadge old) {
    super.didUpdateWidget(old);
    if (old.reaction.address != widget.reaction.address) {
      _contact = null;
      _load();
    }
  }

  void _load() {
    final address = widget.reaction.address;
    _AuthorReactionBadge._lookup(address).then((c) {
      if (mounted && c != null && address == widget.reaction.address) {
        setState(() => _contact = c);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // +2: the emoji sits 2 px further right of the avatar.
      width: _avatar + _emoji * 0.5 + 2,
      height: _avatar,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: _contact != null
                ? GlassContactIcon(contact: _contact, size: _avatar)
                : GlassContactIcon(
                    address: widget.reaction.address, size: _avatar),
          ),
          // The emoji at the avatar's lower right, in front, hanging a little
          // below it.
          Positioned(
            right: 0,
            bottom: -4,
            child: Text(
              widget.reaction.emoji,
              style: const TextStyle(fontSize: _emoji, height: 1.0),
            ),
          ),
        ],
      ),
    );
  }
}
