import 'package:flutter/material.dart';

import 'package:publicos_desktop/theme/glass_tokens.dart';

/// The single reaction button of a post or a comment.
///
///   [♡] 😂❤️👍🔥 14
///
/// - The **empty heart** shows only while the reader has not reacted; it is
///   the one "you haven't reacted" sign (no tint, no badge). Tapping it calls
///   [onHeart] (the caller adds the reader's default reaction, optimistically).
/// - Then the **top emojis**, overlapped, most popular first, and the
///   **total**. Tapping either calls [onOpen] (the reactions sheet, where the
///   reader adds more or removes theirs).
/// - When [mine] goes from empty to not empty, the heart turns into the
///   reader's emoji and slides into the row (the merge), and every change of
///   [pulse] plays the jelly on the whole button. The caller bumps [pulse]
///   whenever the reader adds a reaction, from anywhere (heart, double tap,
///   the sheet, the quick row), so the animation always plays HERE.
/// - A **long press** (a long left click on desktop) calls [onLongPress] with
///   the pressed part's context, so the caller grows the quick row out of it:
///   the heart while not reacted, the emojis/count after. A tap adds a
///   heart at once; the long press opens the row.
class ReactionButton extends StatefulWidget {
  /// Every reaction the card shows (server counts + this session's
  /// optimistic changes), most popular first.
  final List<(String, int)> reactions;

  /// The reader's own emojis on this item, in the order they were added.
  final List<String> mine;

  /// False hides the heart; the emojis still open the sheet.
  final bool canReact;

  final VoidCallback? onHeart;
  final VoidCallback? onOpen;

  /// Long press / long left click: the anchor is the pressed part's context.
  final void Function(BuildContext anchor)? onLongPress;

  /// Bumped by the caller on every add: plays the jelly.
  final int pulse;

  final double heartSize;
  final double emojiSize;
  final double countSize;

  /// Padding around the heart glyph: its tap area.
  final EdgeInsets heartPadding;

  /// Vertical nudge for the emojis only; an emoji font can draw its glyph
  /// off the text line (Segoe UI Emoji on desktop sits ~1.5 px low).
  final double emojiNudge;

  /// Most emojis shown in the row.
  static const int clusterSize = 4;

  /// How much of its own width each emoji after the first keeps, so the
  /// next one tucks under it (no hardcoded advance: it varies by font).
  static const double overlap = 0.74;

  const ReactionButton({
    super.key,
    required this.reactions,
    required this.mine,
    required this.canReact,
    required this.onHeart,
    required this.onOpen,
    required this.pulse,
    this.onLongPress,
    this.heartSize = 18,
    this.emojiSize = 15,
    this.countSize = 14,
    this.heartPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    this.emojiNudge = 0,
  });

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton>
    with TickerProviderStateMixin {
  late final AnimationController _jelly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final AnimationController _merge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  /// The emoji the heart turns into during the merge.
  String? _mergeEmoji;

  // The jelly's keyframes: squash wide, stretch tall,
  // settle. x and y scale separately.
  static final _sx = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.85), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.06), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 30),
  ]);
  static final _sy = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.15), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.94), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0), weight: 30),
  ]);

  @override
  void didUpdateWidget(ReactionButton old) {
    super.didUpdateWidget(old);
    if (widget.pulse != old.pulse) _jelly.forward(from: 0);
    // The merge only when others had reacted: from zero there is no row to
    // merge into, and the heart just becomes the first reaction.
    final hadOthers = old.reactions.any((r) => r.$2 > 0);
    if (old.mine.isEmpty &&
        widget.mine.isNotEmpty &&
        widget.canReact &&
        hadOthers) {
      _mergeEmoji = widget.mine.first;
      _merge.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _jelly.dispose();
    _merge.dispose();
    super.dispose();
  }

  Widget _emoji(String e) {
    final t = Text(e, style: TextStyle(fontSize: widget.emojiSize));
    return widget.emojiNudge == 0
        ? t
        : Transform.translate(offset: Offset(0, widget.emojiNudge), child: t);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final top = widget.reactions.take(ReactionButton.clusterSize).toList();
    final total = widget.reactions.fold<int>(0, (s, r) => s + r.$2);
    final showHeart = widget.canReact && widget.mine.isEmpty;
    if (!widget.canReact && total == 0) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: Listenable.merge([_jelly, _merge]),
      builder: (context, _) {
        final merging = _merge.isAnimating && _mergeEmoji != null;
        final t = Curves.easeInOut.transform(_merge.value);
        final heartSlot = showHeart
            ? Builder(builder: (anchor) => InkResponse(
                onTap: widget.onHeart,
                onLongPress: widget.onLongPress == null
                    ? null
                    : () => widget.onLongPress!(anchor),
                radius: 18,
                child: Padding(
                  padding: widget.heartPadding,
                  child: Icon(Icons.favorite_border,
                      size: widget.heartSize, color: tokens.textDim),
                ),
              ))
            : merging
                // The heart becomes the reader's emoji and slides right into
                // the row: the slot narrows to nothing, its content pinned to
                // the right, so the first emoji of the row paints over it.
                ? ClipRect(
                    child: Align(
                      alignment: Alignment.centerRight,
                      widthFactor: 1 - t,
                      child: Padding(
                        padding: widget.heartPadding,
                        child: SizedBox(
                          width: widget.heartSize,
                          height: widget.heartSize,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              Opacity(
                                opacity: (1 - t * 2).clamp(0.0, 1.0),
                                child: Icon(Icons.favorite_border,
                                    size: widget.heartSize,
                                    color: tokens.textDim),
                              ),
                              Opacity(
                                opacity: (t * 2).clamp(0.0, 1.0),
                                child: _emoji(_mergeEmoji!),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : null;

        final group = total == 0
            ? null
            : Builder(builder: (anchor) => InkWell(
                onTap: widget.onOpen,
                onLongPress: widget.onLongPress == null
                    ? null
                    : () => widget.onLongPress!(anchor),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      heartSlot == null ? 6 : 2, 2, 6, 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < top.length; i++)
                        Align(
                          widthFactor: i == 0 ? 1.0 : ReactionButton.overlap,
                          alignment: Alignment.centerRight,
                          child: _emoji(top[i].$1),
                        ),
                      const SizedBox(width: 5),
                      Text(
                        '$total',
                        style: TextStyle(
                          color: tokens.textDim,
                          fontSize: widget.countSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ));

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
              _sx.evaluate(_jelly), _sy.evaluate(_jelly), 1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (heartSlot != null) heartSlot,
              if (group != null) group,
            ],
          ),
        );
      },
    );
  }
}
