import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/widgets/escape_to_close.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_mentions/zero_mentions.dart';

import 'package:publicos_desktop/widgets/feeds/comment_section.dart';
import 'package:publicos_desktop/widgets/feeds/mention_suggestions.dart';
import 'package:publicos_desktop/widgets/feeds/mention_text.dart';
import 'package:publicos_desktop/widgets/feeds/post_card.dart';
import 'package:publicos_desktop/widgets/media_overlay.dart' show VideoHandoff;
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/write_error_dispatcher.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// Glass push-page for a single post + its comment thread.
///
/// Replaces the old `PostDetailSheet` (which opened as a draggable bottom
/// sheet). Pushed via `Navigator.push(CupertinoPageRoute)` so the
/// horizontal-slide transition + iOS swipe-back gesture match the browser
/// and other glass push-pages.
///
/// Layout:
///   - AppBar with channel name (or "Post")
///   - Scrollable body: PostCard (interactive) → divider → comment list
///   - Pinned-bottom composer (TextField + send) — always visible while
///     the user scrolls comments
///
/// Vote / react / bookmark sync back to the originating feed list happens
/// automatically via the explorer's `RouteAware` hook on `didPopNext` —
/// no callback plumbing needed here.
class PostDetailPage extends StatefulWidget {
  final Post post;
  final Map<String, Contact> resolvedContacts;
  final double titleTextSize;
  final double descriptionTextSize;
  final bool isBookmarked;
  final VoidCallback? onBookmarkToggled;
  /// Reading-layout mode forwarded from the calling PostCard so the focused
  /// post matches whatever the feed is currently rendering (compact/wide).
  /// Defaults to compact for any caller that doesn't thread it through.
  final PostLayoutMode layoutMode;

  /// From the list card that opened this post: the hero page it showed and
  /// its video's state, so the focused post picks up where the list was.
  /// See [PostCard.initialHeroPage] / [PostCard.videoHandoff].
  final int initialHeroPage;
  final VideoHandoff? videoHandoff;

  /// **Desktop delta.** Rendered in-place in the feeds reading column rather
  /// than pushed as a route, so the page cannot pop itself. The host (FeedsPane)
  /// passes the "go back to the post list" action here.
  final VoidCallback? onBack;

  const PostDetailPage({
    super.key,
    required this.post,
    this.resolvedContacts = const {},
    this.titleTextSize = 16.0,
    this.descriptionTextSize = 14.0,
    this.isBookmarked = false,
    this.onBookmarkToggled,
    this.layoutMode = PostLayoutMode.compact,
    this.initialHeroPage = 0,
    this.videoHandoff,
    this.onBack,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  // Comment list state.
  List<Comment> _comments = [];
  bool _isLoadingComments = false;
  int _commentsOffset = 0;
  bool _hasMoreComments = true;
  CommentSort _commentSort = CommentSort.best;

  final ScrollController _scrollController = ScrollController();

  // Composer state. Mention controller: styled @displayname in the field,
  // @[0xAddr] on the wire at serialize() time.
  late final MentionTextEditingController _composerCtrl =
      MentionTextEditingController(
    displayNameFor: _mentionDisplayName,
    // = tokens.connectedAccent — controller is built before context exists.
    mentionStyle: const TextStyle(
      color: Color(0xFF64FFDA),
      fontWeight: FontWeight.w600,
    ),
  );
  final FocusNode _composerFocus = FocusNode();
  bool _isPosting = false;

  /// Local contacts for mention autocomplete + display-name resolution.
  /// Loaded once from the local DB (no chain reads, nothing persisted).
  List<Contact> _storedContacts = const [];

  /// Shared per-page resolver for rendered mention tokens (comment bodies,
  /// reply preview) — every unique address resolves once per page open.
  late final MentionResolver _mentionResolver =
      MentionResolver(seed: widget.resolvedContacts);

  /// When non-null, the next composer submit posts as a reply to this
  /// comment. The composer renders a parent preview above the input.
  Comment? _replyingTo;
  Contact? _replyingToContact;

  /// Local mirror of the bookmark flag so taps from inside the detail page
  /// flip the icon immediately without round-tripping through the parent.
  /// The callback to widget.onBookmarkToggled still fires so the feeds
  /// view updates its own bookmark map.
  late bool _isBookmarked;

  String? get _myAddress =>
      AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;

  /// The post with the server's answers for THIS reader on it: the comments
  /// call (signed) says whether they may comment and react here, and the
  /// card, the composer and the write calls all read that one post. Until
  /// the answer lands, or when the call went unsigned, it is the post as
  /// opened and its own settings decide.
  Post? _answered;
  Post get _post => _answered ?? widget.post;

  /// The composer and the vote/react gates: the server's word when it
  /// spoke, the post's setting otherwise (`PublicOSChannels.canComment`).
  bool get _canComment => PublicOSChannels.canComment(_post);

  /// The thread itself shows whenever the post takes comments at all (a
  /// closed post has none to read); a reader the server turned away still
  /// reads it, they just get no composer.
  bool get _threadOpen {
    final p = _post;
    return p.uid.isNotEmpty &&
        (p.commentsUrl?.isNotEmpty ?? false) &&
        p.commentPolicy != 'closed';
  }

  void _applyAnswer(CommentsAnswer answer) {
    final p = _post;
    if (answer.canComment == p.canCommentAnswer &&
        answer.canReact == p.canReactAnswer) {
      return;
    }
    _answered = p.copyWith(
      canCommentAnswer: answer.canComment,
      canReactAnswer: answer.canReact,
    );
  }

  @override
  void didUpdateWidget(PostDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.post, widget.post)) _answered = null;
  }

  /// True when the viewer can moderate this thread — they authored the post
  /// or own the channel. Drives moderation items in the comment menus.
  /// `uid` gate keeps RSS posts (no server uid) from triggering it.
  bool get _canModerate {
    final me = _myAddress;
    final post = _post;
    if (me == null || post.uid.isEmpty) return false;
    final author = post.feedFoundAtAccountAddress?.toLowerCase();
    final owner = post.channelOwnerAddress?.toLowerCase();
    final mine = me.toLowerCase();
    return author == mine || owner == mine;
  }

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.isBookmarked;
    _composerCtrl.addListener(() => setState(() {}));
    _loadComments(refresh: true);
    _refreshPost();
    _scrollController.addListener(_onScroll);
    PublicOSContacts.getStoredContacts().then((contacts) {
      if (mounted) setState(() => _storedContacts = contacts);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _composerCtrl.dispose();
    _composerFocus.dispose();
    _mentionResolver.dispose();
    super.dispose();
  }

  Future<void> _loadComments({bool refresh = false}) async {
    print('[COMMENT_SORT] _loadComments(refresh=$refresh) sort=${_commentSort.name} loading=$_isLoadingComments');
    // BEACON: guard commented out so the comments GET fires
    // on EVERY post open — the request IS the interaction signal, even on
    // closed-comment posts. INTERIM: twin guard in PublicOSChannels.getComments
    // (publicos_channels.dart, `if (!canComment(post)) return []`) must also be
    // relaxed for the request to actually reach the server. Replace this whole
    // piggyback with the dedicated interaction-signal endpoint when it lands.
    // if (!_canComment) return;
    if (_isLoadingComments) {
      print('[COMMENT_SORT]   -> bailing because already loading');
      return;
    }
    setState(() => _isLoadingComments = true);
    try {
      final offset = refresh ? 0 : _commentsOffset;
      // The thread, and the server's can_comment / can_react for this
      // reader when the call went signed (null otherwise).
      final answer = await PublicOSChannels.getCommentsAnswer(
        _post,
        sort: _commentSort,
        offset: offset,
        limit: 100,
      );
      final newComments = answer.comments;
      print('[COMMENT_SORT]   -> got ${newComments.length} comments. first 3 dates: ${newComments.take(3).map((c) => c.createdAt.toIso8601String()).toList()}');
      if (!mounted) return;
      setState(() {
        _applyAnswer(answer);
        if (refresh) {
          _comments = newComments;
          _commentsOffset = newComments.length;
        } else {
          _comments.addAll(newComments);
          _commentsOffset += newComments.length;
        }
        _hasMoreComments = newComments.length == 100;
        _isLoadingComments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingComments = false);
      _snack(localizedError(context.l10n, e));
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMoreComments && !_isLoadingComments) {
        _loadComments();
      }
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([_loadComments(refresh: true), _refreshPost()]);
  }

  /// The post's own counts and the reader's facts, fetched anew. The object
  /// the feed hands over carries the feed's counts from its last fetch, and a
  /// reaction made on the card (the double-tap heart) lives only in the
  /// card's optimistic state, so without this the page would show no heart
  /// until the whole feed reloaded. Runs on open and on
  /// pull-to-refresh; one interactions call, no document fetch.
  Future<void> _refreshPost() async {
    final p = _post;
    final url = p.interactionsUrl;
    if (p.uid.isEmpty || url == null || url.isEmpty) return;
    try {
      final signed = await PublicOSChannelSignin.shouldSign(url);
      final ix = await RssParser.fetchInteractions(url, signed: signed);
      final mine = ix?.items[p.uid];
      if (!mounted || mine == null) return;
      setState(() => _answered = mine.applyTo(_post));
    } catch (_) {
      // The counts the feed handed over stand.
    }
  }

  Future<void> _voteComment(Comment comment, int value) async {
    try {
      final result = await PublicOSChannels.voteComment(
        post: _post,
        comment: comment,
        value: value,
      );
      if (!mounted) return;
      final updated = comment.copyWith(
        score: result['score'] as int,
        upvotes: result['upvotes'] as int,
        downvotes: result['downvotes'] as int,
        userVote: result['user_vote'] as int?,
      );
      setState(() {
        _comments = _updateCommentInList(_comments, updated);
      });
    } catch (e) {
      if (!mounted) return;
      handleWriteError(context, e, fallbackMessage: 'Failed to vote: $e');
    }
  }

  Future<void> _editComment(Comment comment, String newContent) async {
    try {
      final updated = await PublicOSChannels.editComment(
        post: _post,
        comment: comment,
        newContent: newContent,
      );
      if (!mounted) return;
      setState(() {
        _comments = _updateCommentInList(_comments, updated);
      });
    } catch (e) {
      if (!mounted) return;
      handleWriteError(context, e, fallbackMessage: 'Failed to edit: $e');
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    try {
      await PublicOSChannels.deleteComment(
        post: _post,
        comment: comment,
      );
      if (!mounted) return;
      final deleted =
          comment.copyWith(content: '[deleted]', isDeleted: true);
      setState(() {
        _comments = _updateCommentInList(_comments, deleted);
      });
    } catch (e) {
      if (!mounted) return;
      handleWriteError(context, e, fallbackMessage: 'Failed to delete: $e');
    }
  }

  Future<void> _loadMoreReplies(Comment comment) async {
    try {
      final replies = await PublicOSChannels.getCommentReplies(
        _post,
        comment,
        sort: _commentSort,
        offset: comment.replies.length,
      );
      if (!mounted) return;
      final updatedReplies = [...comment.replies, ...replies];
      final updated = comment.copyWith(
        replies: updatedReplies,
        hasMore: replies.length >= 20,
      );
      setState(() {
        _comments = _updateCommentInList(_comments, updated);
      });
    } catch (e) {
      if (!mounted) return;
      _snack(localizedError(context.l10n, e));
    }
  }

  /// Permanently deny [comment]'s author from commenting on this post by
  /// adding a per-post comment rule. Hits the same endpoint the comment
  /// rules sheet uses, so the new rule shows up there for adjustment or
  /// removal. Surfaced from the comment 3-dot menu for moderators only.
  Future<void> _blockCommenter(Comment comment) async {
    final slug = _post.channelSlug;
    if (slug == null || slug.isEmpty) {
      _snack(context.l10n.postDetailPageCannotBlockMissingSlug);
      return;
    }
    final resp = await PublicOSChannels.addPostInteractionRule(
      slug: slug,
      postUid: _post.uid,
      address: comment.accountAddress,
      type: PostInteractionRuleType.deny,
      serverAddress: _post.serverAddress,
    );
    if (!mounted) return;
    if (resp.success) {
      _snack(context.l10n.postDetailPageBlockedFromCommenting);
    } else {
      handleWriteError(context, resp.error ?? 'Unknown error',
          fallbackMessage:
              'Failed to block: ${resp.error?['message'] as String? ?? 'Unknown error'}');
    }
  }

  Future<void> _reactToComment(Comment comment, String emoji) async {
    try {
      final wasAdded = await PublicOSChannels.toggleCommentReaction(
        post: _post,
        comment: comment,
        emoji: emoji,
      );
      if (!mounted) return;
      final reactions = List<CommentReaction>.from(comment.reactions);
      final emojis = List<String>.from(comment.userReactionEmojis);
      if (wasAdded) {
        final idx = reactions.indexWhere((r) => r.emoji == emoji);
        if (idx >= 0) {
          reactions[idx] =
              reactions[idx].copyWith(count: reactions[idx].count + 1);
        } else {
          reactions.add(CommentReaction(uid: '', emoji: emoji, count: 1));
        }
        if (!emojis.contains(emoji)) emojis.add(emoji);
      } else {
        final idx = reactions.indexWhere((r) => r.emoji == emoji);
        if (idx >= 0) {
          if (reactions[idx].count <= 1) {
            reactions.removeAt(idx);
          } else {
            reactions[idx] =
                reactions[idx].copyWith(count: reactions[idx].count - 1);
          }
        }
        emojis.remove(emoji);
      }
      final updated =
          comment.copyWith(reactions: reactions, userReactionEmojis: emojis);
      setState(() {
        _comments = _updateCommentInList(_comments, updated);
      });
    } catch (e) {
      if (!mounted) return;
      handleWriteError(context, e, fallbackMessage: 'Failed to react: $e');
    }
  }

  List<Comment> _updateCommentInList(List<Comment> list, Comment updated) {
    return list.map((c) {
      if (c.uid == updated.uid) return updated;
      if (c.replies.isNotEmpty) {
        return c.copyWith(replies: _updateCommentInList(c.replies, updated));
      }
      return c;
    }).toList();
  }

  void _onSortChanged(CommentSort sort) {
    print('[COMMENT_SORT] onSortChanged called with: ${sort.name} (current: ${_commentSort.name}) loading=$_isLoadingComments');
    if (sort == _commentSort) return;
    setState(() => _commentSort = sort);
    _loadComments(refresh: true);
  }

  // ------------------------------------------------------------- mentions

  Iterable<Comment> _flatComments(List<Comment> list) sync* {
    for (final c in list) {
      yield c;
      yield* _flatComments(c.replies);
    }
  }

  Contact? _contactFor(String address) {
    final lower = address.toLowerCase();
    for (final e in widget.resolvedContacts.entries) {
      if (e.key.toLowerCase() == lower) return e.value;
    }
    for (final c in _storedContacts) {
      if (c.publicosAddress?.eip55With0x.toLowerCase() == lower) return c;
    }
    return null;
  }

  /// Local-only display-name resolution for the controller (rehydrate/paste)
  /// and the candidates list. Never reads the chain, never persists.
  String _mentionDisplayName(String address) {
    final contact = _contactFor(address);
    if (contact != null && contact.displayName.isNotEmpty) {
      return contact.displayName;
    }
    final lower = address.toLowerCase();
    for (final c in _flatComments(_comments)) {
      if (c.accountAddress.toLowerCase() == lower &&
          (c.username?.isNotEmpty ?? false)) {
        return c.username!;
      }
    }
    return truncatedAddress(address);
  }

  /// Candidates for the active trigger: other commenters on this post first
  /// (most likely reply targets), then stored contacts. Deduped by address,
  /// filtered by the query against name or address prefix.
  List<MentionCandidate> get _mentionCandidates {
    final t = _composerCtrl.trigger;
    if (t == null) return const [];
    final q = t.query.toLowerCase();
    final out = <MentionCandidate>[];
    final seen = <String>{};

    void add(String address, String display, Contact? contact) {
      if (address.isEmpty || display.isEmpty) return;
      final k = address.toLowerCase();
      if (!seen.add(k)) return;
      if (q.isNotEmpty &&
          !display.toLowerCase().contains(q) &&
          !k.startsWith(q)) {
        return;
      }
      out.add(
          MentionCandidate(address: address, display: display, contact: contact));
    }

    for (final c in _flatComments(_comments)) {
      final addr = c.accountAddress;
      if (addr.isEmpty) continue;
      add(addr, _mentionDisplayName(addr), _contactFor(addr));
    }
    for (final c in _storedContacts) {
      final addr = c.publicosAddress?.eip55With0x;
      if (addr == null) continue;
      add(addr, c.displayName, c);
    }
    return out.length > 8 ? out.sublist(0, 8) : out;
  }

  void _pickMention(MentionCandidate c) {
    final t = _composerCtrl.trigger;
    if (t == null) return;
    _composerCtrl.insertMention(
      address: c.address,
      display: c.display,
      trigger: t,
    );
    _composerFocus.requestFocus();
  }

  Future<void> _submitComposer() async {
    // serialize() emits the wire form: mention runs become @[0xAddr] tokens.
    final content = _composerCtrl.serialize().trim();
    if (content.isEmpty || _isPosting) return;
    final replyTarget = _replyingTo;
    setState(() => _isPosting = true);
    try {
      final created = await PublicOSChannels.createComment(
        post: _post,
        content: content,
        // Pass the full Comment so Core can emit reply_to_hash (binds the
        // reply to the parent comment's signed bytes, not just its uid).
        replyTo: replyTarget,
      );
      if (!mounted) return;
      _composerCtrl.clear();
      _composerFocus.unfocus();
      setState(() {
        _isPosting = false;
        _replyingTo = null;
        _replyingToContact = null;
        // Append the new comment locally — avoids a refresh round-trip and
        // sidesteps any pagination/sort surprises that were collapsing the
        // existing list when the refresh came back. Pull-to-refresh still
        // available if the user wants the canonical server ordering.
        if (replyTarget != null) {
          _comments = _attachReply(_comments, replyTarget.uid, created);
        } else {
          // Prepend top-level — newest first matches the default sort
          // visually; the next refresh will re-order if needed.
          _comments = [created, ..._comments];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      handleWriteError(context, e, fallbackMessage: 'Failed to post: $e');
    }
  }

  /// Recursively walk the comment tree and attach [reply] to the parent
  /// matching [parentUid]. Returns a new list — pure transformation.
  List<Comment> _attachReply(List<Comment> list, String parentUid, Comment reply) {
    return list.map((c) {
      if (c.uid == parentUid) {
        return c.copyWith(replies: [...c.replies, reply]);
      }
      if (c.replies.isNotEmpty) {
        return c.copyWith(
          replies: _attachReply(c.replies, parentUid, reply),
        );
      }
      return c;
    }).toList();
  }

  Future<void> _enterReplyMode(Comment comment) async {
    setState(() {
      _replyingTo = comment;
      _replyingToContact = null;
    });
    _composerFocus.requestFocus();
    try {
      var c = await PublicOSContacts.searchContacts(comment.accountAddress);
      if (c == null) {
        c = await PublicOSContacts.resolveByIdentifier(comment.accountAddress);
        if (c != null) await PublicOSContacts.saveContact(c);
      }
      if (mounted && c != null && _replyingTo?.uid == comment.uid) {
        setState(() => _replyingToContact = c);
      }
    } catch (_) {}
  }

  void _cancelReplyMode() {
    setState(() {
      _replyingTo = null;
      _replyingToContact = null;
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final theme = Theme.of(context);
    final post = _post;
    final appBarTitle = post.feedTitle ??
        (post.channelSlug != null
            ? '#${post.channelSlug}'
            : context.l10n.postDetailPagePostFallback);

    // DESKTOP DELTA: Escape closes the focused post, the same
    // way as the back arrow: `onBack` in the Feeds column, a pop as a route.
    return EscapeToClose(
      onEscape: widget.onBack ?? () => Navigator.of(context).maybePop(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: tokens.background,
        appBar: AppBar(
          backgroundColor: tokens.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: tokens.starkWhite),
          // DESKTOP DELTA. On mobile this page is PUSHED, so Scaffold derives a
          // back button from the route stack automatically. Desktop renders it
          // IN PLACE inside the feeds reading column -- there is no route to pop,
          // so Flutter would give it no back affordance at all. [onBack] supplies
          // one; falling back to Navigator.pop keeps it correct if it is ever
          // pushed after all.
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            appBarTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tokens.starkWhite,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          centerTitle: false,
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: tokens.starkWhite,
                backgroundColor: tokens.surfaceElevated,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Post itself — interactive so vote/react/menu/share/etc.
                    // all work from here too. RouteAware on the explorer
                    // handles refresh-on-pop.
                    SliverToBoxAdapter(
                      // interactive=false suppresses the outer tap-to-open
                      // wrapper so we don't re-push the same page when the
                      // user taps the post header inside detail view. The
                      // inner action chips (vote/react/share/bookmark) keep
                      // working because they have their own tap handlers.
                      child: PostCard(
                        post: post,
                        theme: theme,
                        resolvedContacts: widget.resolvedContacts,
                        titleTextSize: widget.titleTextSize,
                        descriptionTextSize: widget.descriptionTextSize,
                        layoutMode: widget.layoutMode,
                        showCommentsIndicator: false,
                        // "on <account>/<feed>" under the name, as the
                        // focused media shows it.
                        showFeedContext: true,
                        interactive: false,
                        initialHeroPage: widget.initialHeroPage,
                        videoHandoff: widget.videoHandoff,
                        isBookmarked: _isBookmarked,
                        onBookmarkToggled: () {
                          setState(() => _isBookmarked = !_isBookmarked);
                          widget.onBookmarkToggled?.call();
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        height: 0.5,
                        color: tokens.borderSubtle,
                      ),
                    ),
                    if (_threadOpen)
                      SliverList(
                        delegate: CommentSection(
                          post: post,
                          comments: _comments,
                          isLoading: _isLoadingComments,
                          hasMore: _hasMoreComments,
                          onLoadMore: _loadComments,
                          commentSort: _commentSort,
                          onSortChanged: _onSortChanged,
                          onReply: _enterReplyMode,
                          onVote: _voteComment,
                          onEdit: _editComment,
                          onDelete: _deleteComment,
                          onLoadMoreReplies: _loadMoreReplies,
                          onReact: _reactToComment,
                          onBlockCommenter: _blockCommenter,
                          canModerate: _canModerate,
                          myAddress: _myAddress,
                          mentionResolver: _mentionResolver,
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              context.l10n.postDetailPageCommentsUnavailable,
                              style: TextStyle(color: tokens.textDim),
                            ),
                          ),
                        ),
                      ),
                    // Bottom spacer so the last comment isn't hidden by the
                    // pinned composer.
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  ],
                ),
              ),
            ),
            if (_canComment) _buildComposer(tokens),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildComposer(GlassTokens tokens) {
    final canSend = _composerCtrl.text.trim().isNotEmpty && !_isPosting;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.background,
          // border: Border(
          //   top: BorderSide(color: tokens.borderSubtle, width: 1),
          // ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_replyingTo != null)
              _buildReplyPreview(tokens, _replyingTo!, _replyingToContact),
            // Mention autocomplete — options column directly above the input.
            if (_mentionCandidates.isNotEmpty)
              MentionSuggestionsPanel(
                candidates: _mentionCandidates,
                onPick: _pickMention,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 42,
                        maxHeight: 140,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surfaceDeep,
                        borderRadius: BorderRadius.circular(22),
                        border:
                            Border.all(color: tokens.borderSubtle, width: 1),
                      ),
                      child: TextField(
                        controller: _composerCtrl,
                        focusNode: _composerFocus,
                        minLines: 1,
                        maxLines: 6,
                        maxLength: 5000,
                        enabled: !_isPosting,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          color: tokens.starkWhite,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: _replyingTo != null
                              ? context.l10n.postDetailPageAddReplyHint
                              : context.l10n.postDetailPageAddCommentHint,
                          hintStyle: TextStyle(color: tokens.textDim),
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          counterText: '',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Borderless send — graph pattern. Vertically centered in
                  // the row because crossAxisAlignment.center on the parent
                  // Row keeps it aligned regardless of how tall the
                  // multi-line input grows.
                  Material(
                    color: Colors.transparent,
                    child: InkResponse(
                      onTap: canSend ? _submitComposer : null,
                      radius: 22,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: _isPosting
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      tokens.connectedAccent),
                                ),
                              )
                            : Icon(
                                Icons.arrow_upward_rounded,
                                size: 22,
                                color: canSend
                                    ? tokens.connectedAccent
                                    : tokens.textDim,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Replying to <name>: <content snippet>" preview rendered above the
  /// composer when [_replyingTo] is set. Tap × to cancel.
  Widget _buildReplyPreview(GlassTokens tokens, Comment parent, Contact? parentContact) {
    final name = parentContact?.displayName ??
        parent.username ??
        _shortAddress(parent.accountAddress);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: tokens.surfaceDeep,
        border: Border(
          bottom: BorderSide(color: tokens.borderSubtle, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 36,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              color: tokens.connectedAccent.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (parentContact != null)
            GlassContactIcon(contact: parentContact, size: 28)
          else
            GlassContactIcon(address: parent.accountAddress, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      context.l10n.postDetailPageReplyingTo,
                      style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.starkWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                MentionText(
                  parent.content,
                  resolver: _mentionResolver,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: tokens.textDim),
            tooltip: context.l10n.postDetailPageCancelReplyTooltip,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: _cancelReplyMode,
          ),
        ],
      ),
    );
  }

  static String _shortAddress(String a) {
    if (a.length < 10) return a;
    return '${a.substring(0, 6)}…${a.substring(a.length - 4)}';
  }
}
