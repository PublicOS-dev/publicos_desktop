import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/feeds/comment_card.dart';
import 'package:publicos_desktop/widgets/feeds/mention_text.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// Sliver delegate that renders the comment thread under a post.
///
/// Header: glass-styled "X comments" + sort PopupMenuButton (graph pattern).
/// There is no "Add" button — the parent page owns a pinned-bottom
/// composer that handles BOTH top-level comments and replies. Tapping
/// "Reply" on a comment surfaces it in the composer's reply preview rather
/// than opening a separate dialog.
class CommentSection extends SliverChildBuilderDelegate {
  CommentSection({
    required Post post,
    required List<Comment> comments,
    required bool isLoading,
    required bool hasMore,
    required VoidCallback onLoadMore,
    required CommentSort commentSort,
    required void Function(CommentSort) onSortChanged,
    required void Function(Comment) onReply,
    required void Function(Comment, int) onVote,
    required void Function(Comment, String) onEdit,
    required void Function(Comment) onDelete,
    required void Function(Comment) onLoadMoreReplies,
    required void Function(Comment, String) onReact,
    void Function(Comment)? onBlockCommenter,
    bool canModerate = false,
    String? myAddress,
    MentionResolver? mentionResolver,
  }) : super(
          (BuildContext context, int index) {
            final tokens = GlassTokens.of(context);

            // Header
            if (index == 0) {
              return _CommentsHeader(
                count: comments.length,
                sort: commentSort,
                onSortChanged: onSortChanged,
                tokens: tokens,
              );
            }

            final commentIndex = index - 1;

            // Comment card
            if (commentIndex < comments.length) {
              return CommentCard(
                // Keyed by uid: a new comment landing above must not inherit
                // this slot's state (its resolved author).
                key: ValueKey(comments[commentIndex].uid),
                comment: comments[commentIndex],
                post: post,
                onReply: onReply,
                onVote: onVote,
                onEdit: onEdit,
                onDelete: onDelete,
                onLoadMoreReplies: onLoadMoreReplies,
                onReact: onReact,
                onBlockCommenter: onBlockCommenter,
                canModerate: canModerate,
                myAddress: myAddress,
                mentionResolver: mentionResolver,
              );
            }

            // Load more / end / empty trailing slot
            if (commentIndex == comments.length) {
              if (hasMore) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(tokens.textDim),
                            ),
                          )
                        : InkWell(
                            onTap: onLoadMore,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.surfaceElevated,
                                border: Border.all(
                                    color: tokens.borderMedium, width: 1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                context.l10n.commentSectionLoadMore,
                                style: TextStyle(
                                  color: tokens.starkWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                  ),
                );
              }
              if (comments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  child: Center(
                    child: Text(
                      isLoading
                          ? context.l10n.commentSectionLoading
                          : context.l10n.commentSectionEmpty,
                      style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }
              // Bottom spacer for the no-more case so the last comment isn't
              // flush with the composer.
              return const SizedBox(height: 16);
            }

            return null;
          },
          childCount: 1 + comments.length + 1,
        );

}

/// Glass header rendered above the comment list. Shows the count + a sort
/// PopupMenuButton.
class _CommentsHeader extends StatelessWidget {
  final int count;
  final CommentSort sort;
  final ValueChanged<CommentSort> onSortChanged;
  final GlassTokens tokens;

  const _CommentsHeader({
    required this.count,
    required this.sort,
    required this.onSortChanged,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            count == 0
                ? context.l10n.commentSectionTitle
                : context.l10n.commentSectionCount(count),
            style: TextStyle(
              color: tokens.starkWhite,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          PopupMenuButton<CommentSort>(
            initialValue: sort,
            onSelected: onSortChanged,
            color: tokens.surfaceDeep,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: tokens.borderSubtle),
            ),
            itemBuilder: (_) => CommentSort.values
                .map(
                  (s) => PopupMenuItem<CommentSort>(
                    value: s,
                    child: Text(
                      _sortLabel(context, s),
                      style: TextStyle(color: tokens.starkWhite),
                    ),
                  ),
                )
                .toList(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _sortLabel(context, sort),
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.unfold_more_rounded,
                  size: 16,
                  color: tokens.textDim,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The sort menu's words, translated here: Core's [CommentSort.label] is
/// English-only.
String _sortLabel(BuildContext context, CommentSort s) {
  final l = context.l10n;
  switch (s) {
    case CommentSort.best:
      return l.commentSortBest;
    case CommentSort.top:
      return l.commentSortTop;
    case CommentSort.newest:
      return l.commentSortNewest;
    case CommentSort.oldest:
      return l.commentSortOldest;
  }
}
