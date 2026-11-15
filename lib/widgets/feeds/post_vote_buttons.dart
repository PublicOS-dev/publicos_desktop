import 'package:flutter/material.dart';

/// Vertical vote buttons for forum posts. Up arrow, score, down arrow.
class PostVoteButtons extends StatelessWidget {
  final int score;
  final int? userVote; // +1, -1, or null
  final Function(int value) onVote;

  const PostVoteButtons({
    super.key,
    required this.score,
    this.userVote,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUpvoted = userVote == 1;
    final isDownvoted = userVote == -1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Upvote
        GestureDetector(
          onTap: () => onVote(1),
          child: Icon(
            Icons.arrow_upward_rounded,
            size: 20,
            color: isUpvoted ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        // Score
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '$score',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isUpvoted
                  ? theme.colorScheme.primary
                  : isDownvoted
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        // Downvote
        GestureDetector(
          onTap: () => onVote(-1),
          child: Icon(
            Icons.arrow_downward_rounded,
            size: 20,
            color: isDownvoted ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
