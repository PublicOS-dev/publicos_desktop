import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';

/// Pattern A glass-dark sheet rendering the full action history of an org.
/// Read-only timeline; the section row tap on the main screen opens this.
Future<void> showHistorySheet(
  BuildContext context, {
  required List<VoteHistoryItem> history,
}) {
  return showGlassSheetDialog<void>(
    context: context,
    width: DialogWidth.l,
    builder: (_) => _HistorySheet(history: history),
  );
}

class _HistorySheet extends StatelessWidget {
  final List<VoteHistoryItem> history;

  const _HistorySheet({required this.history});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // Most-recent first (defensive — caller may not sort).
    final sorted = List<VoteHistoryItem>.from(history)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 1.0,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _Header(
                tokens: tokens,
                title: context.l10n.historySheetTitle,
                subtitle: context.l10n.historySheetPastActions(sorted.length),
                onClose: () => Navigator.pop(context),
              ),
              Expanded(
                child: sorted.isEmpty
                    ? _Empty(tokens: tokens)
                    : ListView.separated(
                        controller: scrollCtrl,
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 6),
                        itemBuilder: (_, i) => _Row(
                          tokens: tokens,
                          item: sorted[i],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  final GlassTokens tokens;
  final VoteHistoryItem item;

  const _Row({required this.tokens, required this.item});

  @override
  Widget build(BuildContext context) {
    final err = Theme.of(context).colorScheme.error;
    final (glyph, glyphColor, glyphBg, statusText) = switch (item.status) {
      VoteStatus.executed => (
          '✓',
          tokens.connectedAccent,
          tokens.connectedAccent.withValues(alpha: 0.12),
          null,
        ),
      VoteStatus.cancelled => (
          '✕',
          err,
          err.withValues(alpha: 0.12),
          context.l10n.historySheetStatusCancelled,
        ),
      VoteStatus.expired => (
          '⊘',
          tokens.textDim,
          tokens.surfaceElevated,
          context.l10n.historySheetStatusExpired,
        ),
      VoteStatus.failed => (
          '✕',
          err,
          err.withValues(alpha: 0.12),
          context.l10n.historySheetStatusFailed,
        ),
      VoteStatus.active => (
          '●',
          tokens.fallbackAccent,
          tokens.fallbackAccent.withValues(alpha: 0.12),
          context.l10n.historySheetStatusActive,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: glyphBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              glyph,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: glyphColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.actionDisplayName,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _summaryLine(item, statusText),
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _ago(item.startTime),
            style: TextStyle(
              fontFamily: 'monospace',
              color: tokens.textDim,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _summaryLine(VoteHistoryItem v, String? statusText) {
    final parts = <String>[];
    if (v.yesVotes > 0 || v.requiredThreshold > 0) {
      parts.add('${v.yesVotes}/${v.requiredThreshold}');
    }
    if (statusText != null) parts.add(statusText);
    // A cancelled vote keeps its reason on record.
    if (v.isCancelled && (v.cancelReason ?? '').isNotEmpty) parts.add('“${v.cancelReason}”');
    return parts.join(' · ');
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 30) return '${d.inDays}d';
    if (d.inDays < 365) return '${(d.inDays / 30).floor()}mo';
    return '${(d.inDays / 365).floor()}y';
  }
}

class _Empty extends StatelessWidget {
  final GlassTokens tokens;
  const _Empty({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tokens.glassFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 28,
                color: tokens.textDim,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.historySheetEmptyTitle,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.historySheetEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final GlassTokens tokens;
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _Header({
    required this.tokens,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tokens.glassFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Icon(
              Icons.history_rounded,
              color: tokens.connectedAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
