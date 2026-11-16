import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';

/// Pattern A glass-dark sheet rendering an org's action history, a week at a
/// time: it opens on the week the management tab already
/// read ([history], the closed proposals started since [since]), and "Load the
/// week before" reads one more week, until the window reaches the org's
/// creation. Specialised org tools may load everything at once; the apps page.
Future<void> showHistorySheet(
  BuildContext context, {
  required String orgAddress,
  required List<VoteHistoryItem> history,
  required DateTime since,
}) {
  return showGlassSheetDialog<void>(
    context: context,
    width: DialogWidth.l,
    builder: (_) => _HistorySheet(orgAddress: orgAddress, history: history, since: since),
  );
}

class _HistorySheet extends StatefulWidget {
  final String orgAddress;
  final List<VoteHistoryItem> history;
  final DateTime since;

  const _HistorySheet({required this.orgAddress, required this.history, required this.since});

  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  static const _week = Duration(days: 7);
  late List<VoteHistoryItem> _items = List.of(widget.history);
  late DateTime _since = widget.since;
  int _weeks = 1;
  DateTime? _createdAt;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    PublicOSGovernance.getOrgCreatedAt(widget.orgAddress).then((t) {
      if (mounted && t != null) setState(() => _createdAt = t);
    });
  }

  /// More to load while the window has not reached the org's creation (unknown = assume more).
  bool get _hasOlder => _createdAt == null || _since.isAfter(_createdAt!);

  Future<void> _loadWeekBefore() async {
    if (_loading) return;
    setState(() => _loading = true);
    final until = _since;
    final since = _since.subtract(_week);
    final older = await PublicOSGovernance.getVotingHistory(widget.orgAddress, since: since, until: until);
    if (!mounted) return;
    setState(() {
      final known = {for (final v in _items) v.id};
      _items = [..._items, ...older.where((v) => !v.isActive && !known.contains(v.id))];
      _since = since;
      _weeks++;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final sorted = List<VoteHistoryItem>.from(_items)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    final loadMore = !_hasOlder
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Center(
              child: _loading
                  ? const PhigitalLoadingWidget(size: 22, showShadows: false)
                  : TextButton.icon(
                      onPressed: _loadWeekBefore,
                      icon: Icon(Icons.expand_more_rounded, color: tokens.connectedAccent, size: 18),
                      label: Text(
                        l10n.historySheetLoadWeekBefore,
                        style: TextStyle(fontFamily: 'SpaceGrotesk', color: tokens.connectedAccent, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
            ),
          );

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
                title: l10n.historySheetTitle,
                subtitle: '${l10n.historySheetPastActions(sorted.length)} · ${l10n.historySheetWindow(_weeks)}',
                onClose: () => Navigator.pop(context),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    if (sorted.isEmpty) _Empty(tokens: tokens, weeks: _weeks),
                    for (final item in sorted) ...[
                      _Row(tokens: tokens, item: item),
                      const SizedBox(height: 6),
                    ],
                    if (loadMore != null) loadMore,
                  ],
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
  final int weeks;
  const _Empty({required this.tokens, required this.weeks});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
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
              context.l10n.historySheetNoVotesWeeks(weeks),
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
