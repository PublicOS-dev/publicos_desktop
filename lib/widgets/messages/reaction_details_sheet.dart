import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/shimmer_box.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

/// What [ReactionDetailsSheet.load] resolves to: the full per-reactor
/// summaries plus the contacts found for their addresses.
typedef ReactionDetailsLoad = Future<
    ({List<MessageReactionSummary> reactions, Map<String, Contact> contacts})?>
  Function();

/// Bottom sheet listing the accounts that reacted, filterable by emoji.
///
/// A leftmost "All" tab merges every reaction; each emoji after it filters
/// down to just that emoji's reactors. Title is the literal "Reactions" —
/// not the count or the selected emoji.
///
/// Used for both post reactions (post_card) and message reactions
/// (message_widget). Caller pre-builds the [reactions] summaries and
/// optionally provides a [contactLookup] callback so we can resolve
/// addresses/inbox IDs to Contact objects for avatars + display names.
class ReactionDetailsSheet extends StatefulWidget {
  final List<MessageReactionSummary> reactions;
  final Contact? Function(String inboxId)? contactLookup;
  final String? initialEmoji;
  final String? currentUserId;

  /// Optional removal callback. When provided, rows belonging to the current
  /// user render a trash button that invokes this. Should return true when
  /// the server removed the reaction, false on failure (sheet rolls back).
  /// Pass null to hide the trash button entirely (e.g., XMTP message
  /// reactions where removal flow lives elsewhere).
  final Future<bool> Function(String emoji)? onRemoveMyReaction;

  /// Optional: a tap on a reactor who has a PublicOS profile. The caller
  /// closes the sheet and opens the profile in the Browser.
  final void Function(Contact contact)? onContactTap;

  /// **Desktop delta.** Render as a plain fixed-size card instead of a draggable
  /// bottom sheet. Set when hosted inside a `Dialog` (desktop has no bottom
  /// sheets); leave false for any true bottom-sheet use.
  final bool asCard;

  /// Optional slow half. When set, [reactions] is what the caller
  /// already knows (counts, no senders) and the sheet opens on it at once,
  /// shows a skeleton in the list, then swaps in what [load] returns — the
  /// per-reactor lists and their contacts. Null means the caller had it all
  /// up front (XMTP message reactions are local).
  final ReactionDetailsLoad? load;

  /// Optional: a reactor that neither [load] nor [contactLookup]
  /// knows (not in this device's contacts) is looked up through this after the
  /// list lands, and its row fills in place. Post reactions pass a chain lookup.
  final Future<Contact?> Function(String id)? resolveMissing;

  /// Optional: a tap on a row that is still unresolved. Post
  /// reactions open the profile by address, and the Browser resolves it there.
  final void Function(String id)? onUnresolvedTap;

  const ReactionDetailsSheet({
    super.key,
    required this.reactions,
    this.contactLookup,
    this.initialEmoji,
    this.currentUserId,
    this.onRemoveMyReaction,
    this.onContactTap,
    this.asCard = false,
    this.load,
    this.resolveMissing,
    this.onUnresolvedTap,
  });

  @override
  State<ReactionDetailsSheet> createState() => _ReactionDetailsSheetState();
}

class _ReactionDetailsSheetState extends State<ReactionDetailsSheet>
    with SingleTickerProviderStateMixin {
  /// Contacts the [ReactionDetailsSheet.load] step resolved; consulted before
  /// the caller's `contactLookup`.
  final Map<String, Contact> _contacts = {};

  /// True while `load` is in flight; the list shows a skeleton meanwhile.
  bool _loading = false;
  bool _loadFailed = false;
  late final AnimationController _shimmerCtrl;

  Contact? _lookup(String id) => _contacts[id] ?? widget.contactLookup?.call(id);

  Future<void> _runLoad(ReactionDetailsLoad load) async {
    ({List<MessageReactionSummary> reactions, Map<String, Contact> contacts})?
        result;
    try {
      result = await load();
    } catch (e) {
      print('[REACTIONS] details load failed: $e');
      result = null;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _shimmerCtrl.stop();
      if (result == null) {
        _loadFailed = true;
        return;
      }
      _localReactions = List<MessageReactionSummary>.from(result.reactions);
      _contacts
        ..clear()
        ..addAll(result.contacts);
      if (_selectedEmoji != null &&
          !_localReactions.any((r) => r.emoji == _selectedEmoji)) {
        _selectedEmoji = null;
      }
    });
    if (result != null) _resolveMissing();
  }

  /// Every reactor still without a contact goes through
  /// [ReactionDetailsSheet.resolveMissing], all at once; each row fills in as
  /// its answer lands.
  void _resolveMissing() {
    final resolve = widget.resolveMissing;
    if (resolve == null) return;
    final ids = <String>{
      for (final r in _localReactions) ...r.senderInboxIds,
    }.where((id) => _lookup(id) == null);
    for (final id in ids) {
      resolve(id).then((c) {
        if (c != null && mounted) setState(() => _contacts[id] = c);
      }).catchError((Object e) {
        print('[REACTIONS] resolve $id failed: $e');
      });
    }
  }

  /// The list while `load` runs: one row per expected reactor (capped), the
  /// final row's geometry in ShimmerBoxes on one shared controller.
  Widget _skeleton(GlassTokens tokens, {bool shrinkWrap = false}) {
    final expected = _selectedEmoji == null
        ? _totalCount
        : _localReactions
            .where((r) => r.emoji == _selectedEmoji)
            .fold<int>(0, (s, r) => s + r.count);
    final n = expected.clamp(1, 6);
    final highlight = Color.alphaBlend(
      tokens.starkWhite.withValues(alpha: 0.10),
      tokens.surfaceElevated,
    );
    ShimmerBox box(double w, double h, double r) => ShimmerBox(
          progress: _shimmerCtrl,
          width: w,
          height: h,
          radius: r,
          base: tokens.surfaceElevated,
          highlight: highlight,
        );
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: n,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            box(40, 40, 16),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(140, 14, 6),
                const SizedBox(height: 6),
                box(90, 10, 5),
              ],
            ),
          ],
        ),
      ),
    );
  }

  VoidCallback? _tapFor(String id, Contact? c) {
    final cb = widget.onContactTap;
    final a = c?.publicosAddress?.eip55With0x;
    if (cb == null || c == null || a == null ||
        a == '0x0000000000000000000000000000000000000000') {
      final open = widget.onUnresolvedTap;
      if (open != null && RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(id)) {
        return () => open(id);
      }
      return null;
    }
    return () => cb(c);
  }

  /// null = All tab.
  String? _selectedEmoji;

  /// Mutable copy of the source reactions so the sheet can update locally
  /// on a successful "remove my reaction" without waiting for a parent
  /// reload. Initial copy in initState; mutated only by [_handleRemove].
  late List<MessageReactionSummary> _localReactions;

  /// Emojis currently being removed (suppresses double-tap + dims the row).
  final Set<String> _removingEmojis = {};

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.initialEmoji;
    _localReactions = List<MessageReactionSummary>.from(widget.reactions);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final load = widget.load;
    if (load != null) {
      _loading = true;
      _shimmerCtrl.repeat();
      _runLoad(load);
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  String? get _currentUser =>
      widget.currentUserId ?? PublicOS.clientXmtpInboxId;

  int get _totalCount =>
      _localReactions.fold<int>(0, (sum, r) => sum + r.count);

  /// Builds the row list for the current filter. Each entry is
  /// (id, emoji the person reacted with). Current user's rows are sorted
  /// to the top in both All and per-emoji views.
  List<(String, String)> _currentRows() {
    final out = <(String, String)>[];
    if (_selectedEmoji == null) {
      for (final r in _localReactions) {
        for (final id in r.senderInboxIds) {
          out.add((id, r.emoji));
        }
      }
    } else {
      final match = _localReactions.firstWhere(
        (r) => r.emoji == _selectedEmoji,
        orElse: () => MessageReactionSummary(
          emoji: _selectedEmoji!,
          count: 0,
          hasMyReaction: false,
          senderInboxIds: const [],
        ),
      );
      for (final id in match.senderInboxIds) {
        out.add((id, match.emoji));
      }
    }
    final me = _currentUser;
    if (me != null) {
      out.sort((a, b) {
        final aIsMe = a.$1 == me ? 0 : 1;
        final bIsMe = b.$1 == me ? 0 : 1;
        return aIsMe - bIsMe;
      });
    }
    return out;
  }

  Future<void> _handleRemove(String emoji) async {
    final cb = widget.onRemoveMyReaction;
    if (cb == null || _removingEmojis.contains(emoji)) return;
    setState(() => _removingEmojis.add(emoji));
    final ok = await cb(emoji);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _removingEmojis.remove(emoji);
        // Drop the user from the senders list for that emoji; if the count
        // would hit zero, drop the emoji row entirely.
        final me = _currentUser;
        if (me == null) return;
        final updated = <MessageReactionSummary>[];
        for (final r in _localReactions) {
          if (r.emoji != emoji) {
            updated.add(r);
            continue;
          }
          final newSenders =
              r.senderInboxIds.where((id) => id != me).toList();
          final newCount = r.count - 1;
          if (newCount > 0) {
            updated.add(MessageReactionSummary(
              emoji: r.emoji,
              count: newCount,
              hasMyReaction: false,
              senderInboxIds: newSenders,
            ));
          }
        }
        _localReactions = updated;
        // If we just dropped the selected emoji, fall back to All.
        if (_selectedEmoji != null &&
            !_localReactions.any((r) => r.emoji == _selectedEmoji)) {
          _selectedEmoji = null;
        }
      });
    } else {
      setState(() => _removingEmojis.remove(emoji));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.reactionDetailsSheetRemoveFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // DESKTOP DELTA. In card mode the mobile bottom-sheet chrome is gone (drag
    // handle, top-only rounded corners) and the DraggableScrollableSheet is
    // replaced by a plain fixed-size card. Without this the sheet, hosted inside
    // a Dialog, bottom-anchors WITHIN the dialog box and renders as a little
    // sheet floating in the middle of the screen. The
    // content Column is identical either way.
    if (widget.asCard) {
      final tokens = GlassTokens.of(context);
      return Container(
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: _content(context, null),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollCtrl) {
        final tokens = GlassTokens.of(context);
        return Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: Column(
            children: [
              const _Handle(),
              Expanded(child: _content(context, scrollCtrl)),
            ],
          ),
        );
      },
    );
  }

  /// The shared body — header, emoji tabs, divider, reactor list. `scrollCtrl`
  /// is the DraggableScrollableSheet's controller on mobile; null in card mode,
  /// where the list scrolls on its own.
  Widget _content(BuildContext context, ScrollController? scrollCtrl) {
    final tokens = GlassTokens.of(context);
    final rows = _currentRows();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(title: context.l10n.reactionDetailsSheetTitle),
        _EmojiTabs(
          reactions: _localReactions,
          selected: _selectedEmoji,
          onSelect: (e) => setState(() => _selectedEmoji = e),
          totalCount: _totalCount,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(color: tokens.borderSubtle, height: 1),
        ),
        Flexible(
          child: _loading
              ? _skeleton(tokens, shrinkWrap: true)
              : rows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    _loadFailed
                        ? context.l10n.reactionDetailsSheetLoadFailed
                        : context.l10n.reactionDetailsSheetNoReactions,
                    style: TextStyle(color: tokens.textDim, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  controller: scrollCtrl,
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final (id, emoji) = rows[index];
                    final me = _currentUser;
                    final isMe = me != null && id == me;
                    final contact = _lookup(id);
                    return _ReactorRow(
                      inboxId: id,
                      contact: contact,
                      emoji: _selectedEmoji == null ? emoji : null,
                      currentUserId: widget.currentUserId,
                      onRemove: (isMe && widget.onRemoveMyReaction != null)
                          ? () => _handleRemove(emoji)
                          : null,
                      isRemoving: _removingEmojis.contains(emoji),
                      onTap: _tapFor(id, contact),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: tokens.borderMedium,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: tokens.starkWhite,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _EmojiTabs extends StatelessWidget {
  final List<MessageReactionSummary> reactions;
  final String? selected;
  final ValueChanged<String?> onSelect;
  final int totalCount;

  const _EmojiTabs({
    required this.reactions,
    required this.selected,
    required this.onSelect,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        height: 34,
        child: HorizontalWheel(child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _AllTab(
              selected: selected == null,
              count: totalCount,
              onTap: () => onSelect(null),
            ),
            for (final r in reactions)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _EmojiTab(
                  emoji: r.emoji,
                  count: r.count,
                  selected: selected == r.emoji,
                  onTap: () => onSelect(r.emoji),
                ),
              ),
          ],
        )),
      ),
    );
  }
}

class _AllTab extends StatelessWidget {
  final bool selected;
  final int count;
  final VoidCallback onTap;

  const _AllTab({
    required this.selected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final fg = selected ? tokens.starkWhite : tokens.textDim;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? tokens.surfaceElevated : Colors.transparent,
          border: Border.all(
            color: selected ? tokens.borderMedium : tokens.borderSubtle,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.reactionDetailsSheetAllTab,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiTab extends StatelessWidget {
  final String emoji;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _EmojiTab({
    required this.emoji,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final fg = selected ? tokens.starkWhite : tokens.textDim;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? tokens.surfaceElevated : Colors.transparent,
          border: Border.all(
            color: selected ? tokens.borderMedium : tokens.borderSubtle,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactorRow extends StatelessWidget {
  final VoidCallback? onTap;
  final String inboxId;
  final Contact? contact;
  final String? emoji;
  final String? currentUserId;
  final VoidCallback? onRemove;
  final bool isRemoving;

  const _ReactorRow({
    required this.inboxId,
    required this.contact,
    required this.emoji,
    required this.currentUserId,
    this.onRemove,
    this.isRemoving = false,
    this.onTap,
  });

  String _formatId(String id) {
    if (id.length <= 14) return id;
    return '${id.substring(0, 6)}…${id.substring(id.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final isMe =
        inboxId == (currentUserId ?? PublicOS.clientXmtpInboxId);
    final displayName = contact?.displayName ?? _formatId(inboxId);
    final showSubtitle =
        contact?.displayName != null && contact!.displayName.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (contact != null)
            GlassContactIcon(contact: contact, size: 40)
          else
            GlassContactIcon(address: inboxId, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.starkWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: tokens.borderSubtle,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context.l10n.reactionDetailsSheetYouBadge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: tokens.textDim,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (showSubtitle)
                  Text(
                    _formatId(inboxId),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),
          if (emoji != null) ...[
            const SizedBox(width: 8),
            Text(emoji!, style: const TextStyle(fontSize: 16)),
          ],
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: context.l10n.reactionDetailsSheetRemoveTooltip,
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Theme.of(context)
                    .colorScheme
                    .error
                    .withValues(alpha: isRemoving ? 0.4 : 0.85),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              onPressed: isRemoving ? null : onRemove,
            ),
          ],
        ],
      ),
    ),
    );
  }
}
