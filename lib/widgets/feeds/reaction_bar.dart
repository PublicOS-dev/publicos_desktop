import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/feeds/emoji_picker_dialog.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
class ReactionBar extends StatefulWidget {
  final Post post;
  final ReactionsData? reactionsData;
  final bool isLoading;
  final VoidCallback? onReactionChanged;

  const ReactionBar({
    super.key,
    required this.post,
    this.reactionsData,
    this.isLoading = false,
    this.onReactionChanged,
  });

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  // Reuse the same emojis from message_widget.dart:1331
  static const _commonEmojis = ['❤️', '👍', '👎', '😂', '😮', '😢', '😡', '🔥', '💯', '👏', '🎉', '✨'];

  // Track optimistic reactions (emoji -> pending state)
  final Map<String, bool> _optimisticReactions = {};
  bool _isReacting = false;

  String? get _currentUserAddress => AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: PhigitalLoadingWidget(size: 24)),
      );
    }

    final reactionsData = widget.reactionsData;
    if (reactionsData == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Show existing reactions
          ...reactionsData.reactions.map((reaction) {
            // Use server-curated currentUserReactions (since
            // unified_interaction_rules / Core 0.4.0). The signer's reaction
            // state arrives populated; no need to filter user_reactions[]
            // by self.
            final hasReacted =
                reactionsData.currentUserHasReaction(reaction.emoji);

            // Check for optimistic state
            final isOptimistic = _optimisticReactions.containsKey(reaction.emoji);
            final displayCount = isOptimistic
                ? (_optimisticReactions[reaction.emoji]! ? reaction.count + 1 : reaction.count - 1)
                : reaction.count;

            // Don't show if count would be 0
            if (displayCount <= 0) return const SizedBox.shrink();

            return _ReactionChip(
              emoji: reaction.emoji,
              count: displayCount,
              isActive: isOptimistic ? _optimisticReactions[reaction.emoji]! : hasReacted,
              onTap: () => _handleReaction(reaction.emoji),
            );
          }).where((w) => w is! SizedBox),

          // Add reaction button
          _AddReactionButton(
            onEmojiSelected: _handleReaction,
            isReacting: _isReacting,
          ),
        ],
      ),
    );
  }

  Future<void> _handleReaction(String emoji) async {
    if (_isReacting) return;

    HapticFeedback.mediumImpact();

    final userAddress = _currentUserAddress;
    if (userAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.signInToReact)),
      );
      return;
    }

    // Optimistic update — use server-curated currentUserReactions for
    // current state (since unified_interaction_rules / Core 0.4.0).
    final reactionsData = widget.reactionsData;
    final hasReacted =
        reactionsData?.currentUserHasReaction(emoji) ?? false;

    setState(() {
      _optimisticReactions[emoji] = !hasReacted; // Toggle
      _isReacting = true;
    });

    try {
      await PublicOSChannels.toggleReaction(
        post: widget.post,
        emoji: emoji,
      );

      // Success - remove optimistic state and refresh
      setState(() {
        _optimisticReactions.remove(emoji);
        _isReacting = false;
      });

      widget.onReactionChanged?.call();
    } catch (e) {
      // Rollback optimistic update
      setState(() {
        _optimisticReactions.remove(emoji);
        _isReacting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(context.l10n, e))),
        );
      }
    }
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: theme.colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddReactionButton extends StatelessWidget {
  final Function(String) onEmojiSelected;
  final bool isReacting;

  const _AddReactionButton({
    required this.onEmojiSelected,
    required this.isReacting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: isReacting ? null : () => _showEmojiPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: isReacting ? 0.3 : 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              'React',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: isReacting ? 0.3 : 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show glass categorized emoji picker.
  Future<void> _showEmojiPicker(BuildContext context) async {
    final emoji = await showEmojiPickerDialog(context);
    if (emoji != null) onEmojiSelected(emoji);
  }
}
