import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/members_stack.dart';
import 'package:publicos_desktop/widgets/org_management/members_sheet.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// The scroll-away header item at the top of a single channel's feed
/// (social-reads KPI, Session 3). Behaves like a post: it is the first item in
/// the list and scrolls off as the user moves down — no pinning, no collapse.
///
/// Two independently-optional pieces:
///  - the channel [description] (skipped when empty), and
///  - a [stats] line: "Verified readers" (distinct citizens this week) on the
///    left and the quieter all-time "Total views" on the right. Tapping the
///    line opens a dialog with the daily bar chart and the full breakdown.
///
/// [stats] is null for plain RSS/external feeds, opted-out channels, and
/// channels nobody has read — in which case nothing stats-related renders. If
/// both description and stats are empty/null the whole card collapses to
/// nothing (the caller should simply not insert it).
///
/// A third optional piece: who is
/// behind the feed, as a credits line under the description: "by [writers]
/// · hosted by [owner]" — the [writers] (distinct authors of the received
/// posts) as a small org Members stack, the channel [owner] (the account
/// hosting it on its SSP); tapping the stack lists them in the
/// members sheet. The caller decides when the row is worth showing.
class ChannelHeaderCard extends StatelessWidget {
  final String description;
  final ChannelStats? stats;

  /// The channel owner, or null to skip the people row.
  final Contact? owner;

  /// Distinct authors of the received posts. Empty = owner only (forums, or
  /// a channel only its owner writes in).
  final List<Contact> writers;

  /// True when the owner is the only writer (not a forum): the credits read
  /// "by [owner]" instead of "hosted by [owner]".
  final bool ownerWrites;

  /// Channel accent — the bar chart and "Verified readers" figure tint to it,
  /// falling back to the glass connected-accent when null.
  final Color? accent;

  /// The details line under the description:
  /// `🔗 host · updated 2h · ES`. Each part is optional and comes from the
  /// feed itself — the website it declares, the newest post's relative date
  /// (a feed's own date is not parsed), and its declared language.
  final String? siteUrl;
  final String? updatedAgo;
  final String? language;

  const ChannelHeaderCard({
    super.key,
    required this.description,
    required this.stats,
    this.owner,
    this.writers = const [],
    this.ownerWrites = false,
    this.accent,
    this.siteUrl,
    this.updatedAgo,
    this.language,
    this.onFlag,
  });

  /// Opens the flag sheet for this channel; null = no flag button (own
  /// channel, a mixed list, or not a PublicOS channel).
  final VoidCallback? onFlag;

  /// Whether this card has anything to show. Callers use it to decide whether
  /// to insert the item at all, so an empty card never eats list space.
  static bool hasContent({
    required String description,
    ChannelStats? stats,
    Contact? owner,
    String? siteUrl,
    String? updatedAgo,
    String? language,
  }) =>
      description.trim().isNotEmpty ||
      stats != null ||
      owner != null ||
      _hostOf(siteUrl) != null ||
      (updatedAgo?.isNotEmpty ?? false) ||
      (language?.trim().isNotEmpty ?? false);

  static String? _hostOf(String? url) {
    if (url == null) return null;
    final host = Uri.tryParse(url)?.host;
    return (host == null || host.isEmpty) ? null : host;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final accentColor = accent ?? tokens.connectedAccent;
    final desc = description.trim();
    final hasDesc = desc.isNotEmpty;
    final s = stats;
    final host = _hostOf(siteUrl);
    final lang = language?.trim();
    final hasDetails = host != null ||
        (updatedAgo?.isNotEmpty ?? false) ||
        (lang?.isNotEmpty ?? false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The layout: what it's about, who's behind it, then the numbers as
          // one quiet right-aligned line. No line under it: the top post has
          // no divider.
          if (hasDesc)
            Text(
              desc,
              // Brighter than the details line under it (textDim): the
              // description is content, the line below is metadata
              // (title > description > details).
              style: TextStyle(
                color: tokens.starkWhite.withValues(alpha: 0.8),
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          if (hasDesc && hasDetails) const SizedBox(height: 8),
          if (hasDetails)
            _DetailsLine(
              siteUrl: host == null ? null : siteUrl,
              host: host,
              updatedAgo: updatedAgo,
              language: lang,
              tokens: tokens,
            ),
          if ((hasDesc || hasDetails) && owner != null)
            const SizedBox(height: 16),
          if (owner != null)
            _CreditsLine(
              owner: owner!,
              writers: writers,
              ownerWrites: ownerWrites,
              tokens: tokens,
            ),
          if ((hasDesc || hasDetails || owner != null) &&
              (s != null || onFlag != null))
            const SizedBox(height: 14),
          // The counts line, with the flag button to its right: one feed by
          // someone else is where a channel is flagged.
          if (s != null || onFlag != null)
            Row(
              children: [
                Expanded(
                  child: s == null
                      ? const SizedBox.shrink()
                      : _StatsRow(stats: s, accent: accentColor, tokens: tokens),
                ),
                if (onFlag != null) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onFlag,
                    child: Icon(
                      Icons.flag_outlined,
                      size: 15,
                      color: tokens.textDim.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

/// `🔗 host · updated 2h · ES` — the feed's own facts. The host opens the site
/// (the in-app browser where the platform has one, the system browser
/// otherwise — desktop).
class _DetailsLine extends StatelessWidget {
  final String? siteUrl;
  final String? host;
  final String? updatedAgo;
  final String? language;
  final GlassTokens tokens;

  const _DetailsLine({
    required this.siteUrl,
    required this.host,
    required this.updatedAgo,
    required this.language,
    required this.tokens,
  });

  Future<void> _open(BuildContext context, String url) async {
    try {
      final mode = await supportsLaunchMode(LaunchMode.inAppBrowserView)
          ? LaunchMode.inAppBrowserView
          : LaunchMode.externalApplication;
      await launchUrl(Uri.parse(url), mode: mode);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.postCardCouldNotOpenLink(url))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = TextStyle(color: tokens.textDim, fontSize: 12, height: 1.3);
    final site = siteUrl;
    final lang = language;
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (site != null && host != null)
          InkWell(
            onTap: () => _open(context, site),
            borderRadius: BorderRadius.circular(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grey like the rest of the details line: a link is not a
                // connected/active state, so no connectedAccent.
                Icon(Icons.link_rounded, size: 14, color: tokens.textDim),
                const SizedBox(width: 4),
                Text(host!, style: dim),
              ],
            ),
          ),
        if (updatedAgo != null && updatedAgo!.isNotEmpty)
          Text(context.l10n.feedReaderPageUpdated(updatedAgo!), style: dim),
        if (lang != null && lang.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: tokens.borderSubtle),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(lang.toUpperCase(),
                style:
                    dim.copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

/// The credits line: "by [writers] · hosted by [owner]". The writers are the
/// org Members stack, small, plus the first writer's name (and "+N"); the stack
/// and the count open the read-only members sheet, a name opens that profile.
/// No writers: "by [owner]" when only the owner writes, "hosted by [owner]" on
/// a forum. Wraps on a narrow screen.
class _CreditsLine extends StatelessWidget {
  final Contact owner;
  final List<Contact> writers;
  final bool ownerWrites;
  final GlassTokens tokens;

  const _CreditsLine({
    required this.owner,
    required this.writers,
    required this.ownerWrites,
    required this.tokens,
  });

  TextStyle get _word => TextStyle(
        color: tokens.textDim,
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
      );

  TextStyle get _name => TextStyle(
        color: tokens.starkWhite,
        fontSize: 13,
        fontWeight: FontWeight.w600, // w700 competes with the title
      );

  void _openWriters(BuildContext context) {
    final l10n = context.l10n;
    showMembersSheet(
      context,
      members: writers,
      canMutate: false,
      title: l10n.channelHeaderWriters,
      subtitle: l10n.channelHeaderWritersCount(writers.length),
      onMemberTap: (c) {
        Navigator.of(context).pop();
        AppNav.toContact(context, c);
      },
    );
  }

  Widget _tap(VoidCallback onTap, Widget child) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ownerChip = _tap(
      () => AppNav.toContact(context, owner),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassContactIcon(contact: owner, size: 20),
          const SizedBox(width: 6),
          Text(owner.displayName, style: _name),
        ],
      ),
    );
    final children = <Widget>[];
    if (writers.isNotEmpty) {
      final first = writers.first;
      children.addAll([
        Text(l10n.channelHeaderBy, style: _word),
        MembersStack(
          tokens: tokens,
          contacts: writers,
          scale: 0.6,
          shrinkWrap: true,
          onTap: () => _openWriters(context),
        ),
        _tap(
          () => writers.length > 1
              ? _openWriters(context)
              : AppNav.toContact(context, first),
          Text(
            writers.length > 1
                ? '${first.displayName} +${writers.length - 1}'
                : first.displayName,
            style: _name,
          ),
        ),
        Text('·  ${l10n.channelHeaderHostedBy}', style: _word),
        ownerChip,
      ]);
    } else {
      children.addAll([
        Text(
          ownerWrites ? l10n.channelHeaderBy : l10n.channelHeaderHostedBy,
          style: _word,
        ),
        ownerChip,
      ]);
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: children,
    );
  }
}

/// The stats line: "Verified readers" headline left, quiet "Total views"
/// right, space between. Tapping anywhere on it opens the breakdown dialog.
class _StatsRow extends StatelessWidget {
  final ChannelStats stats;
  final Color accent;
  final GlassTokens tokens;

  const _StatsRow({
    required this.stats,
    required this.accent,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Quiet on purpose, so the numbers do not get in the way: one
    // small right-aligned line, the numbers only a step brighter than their
    // words. Still the tap target for the breakdown dialog.
    final word = TextStyle(
      color: tokens.textDim.withValues(alpha: 0.42),
      fontSize: 11,
    );
    final number = TextStyle(
      color: tokens.textDim,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showStatsDialog(context),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
                text: _grouped(stats.verifiedCitizenViews), style: number),
            TextSpan(
              text: ' ${l10n.channelHeaderVerifiedReadersWord(stats.verifiedCitizenViews)}  ·  ',
              style: word,
            ),
            TextSpan(text: _grouped(stats.totalViews), style: number),
            TextSpan(
              text: ' ${l10n.channelHeaderViewsWord(stats.totalViews)} ',
              style: word,
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                Icons.bar_chart_rounded,
                size: 13,
                color: tokens.textDim.withValues(alpha: 0.42),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showStatsDialog(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        title: Text(
          l10n.channelHeaderStatsTitle,
          style: TextStyle(color: tokens.starkWhite),
        ),
        // Fill the dialog; its width comes from `constraints` (DialogWidth.s).
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stats.daily.isNotEmpty) ...[
                  _DailyBars(
                    daily: stats.daily,
                    accent: accent,
                    tokens: tokens,
                  ),
                  const SizedBox(height: 18),
                ],
                _detailRow(
                  l10n.channelHeaderReadersThisWeek,
                  stats.verifiedCitizenViews,
                ),
                _detailRow(l10n.channelHeaderTodayPartial, stats.today),
                _detailRow(l10n.channelHeaderTotalViewsAllTime,
                    stats.totalViews),
                const SizedBox(height: 8),
                _detailRow(
                  l10n.channelHeaderByTypeCitizens,
                  stats.byType.citizen,
                  sub: true,
                ),
                _detailRow(
                  l10n.channelHeaderByTypePrivate,
                  stats.byType.private,
                  sub: true,
                ),
                _detailRow(
                  l10n.channelHeaderByTypeSigned,
                  stats.byType.signedNoAccount,
                  sub: true,
                ),
                _detailRow(
                  l10n.channelHeaderByTypeAnonymous,
                  stats.byType.anonymous,
                  sub: true,
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.channelHeaderVerifiedNote,
                  style: TextStyle(
                    color: tokens.textDim.withValues(alpha: 0.7),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.channelHeaderClose,
              style: TextStyle(color: tokens.textDim),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, int value, {bool sub = false}) {
    return Padding(
      padding: EdgeInsets.only(left: sub ? 12 : 0, top: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: sub
                    ? tokens.textDim.withValues(alpha: 0.75)
                    : tokens.textDim,
                fontSize: sub ? 12.5 : 13,
              ),
            ),
          ),
          Text(
            _grouped(value),
            style: TextStyle(
              color: sub ? tokens.textDim : tokens.starkWhite,
              fontSize: sub ? 12.5 : 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The vertical bar chart of distinct citizens per day, oldest → newest, with
/// the count above each bar and the weekday below it. The last bar is "today";
/// it breathes (a slow opacity pulse) so the number reads as live rather than
/// frozen, and its label says "Today" instead of the weekday.
class _DailyBars extends StatefulWidget {
  final List<int> daily;
  final Color accent;
  final GlassTokens tokens;

  const _DailyBars({
    required this.daily,
    required this.accent,
    required this.tokens,
  });

  @override
  State<_DailyBars> createState() => _DailyBarsState();
}

class _DailyBarsState extends State<_DailyBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  static const double _chartHeight = 64;
  static const double _barWidth = 16;
  static const double _minBarHeight = 3; // a zero day is a visible tick

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = widget.daily;
    final maxVal = data.fold<int>(0, (m, v) => v > m ? v : m);
    final denom = maxVal <= 0 ? 1 : maxVal;
    final lastIndex = data.length - 1;
    final locale = Localizations.localeOf(context).toString();
    final weekdayFmt = DateFormat.E(locale);
    final now = DateTime.now();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < data.length; i++)
          Expanded(
            child: _dayColumn(
              value: data[i],
              denom: denom,
              isToday: i == lastIndex,
              label: i == lastIndex
                  ? l10n.channelHeaderToday
                  : weekdayFmt
                      .format(now.subtract(Duration(days: lastIndex - i))),
            ),
          ),
      ],
    );
  }

  Widget _dayColumn({
    required int value,
    required int denom,
    required bool isToday,
    required String label,
  }) {
    final tokens = widget.tokens;
    final frac = (value / denom).clamp(0.0, 1.0);
    final height = _minBarHeight + frac * (_chartHeight - _minBarHeight);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _grouped(value),
          style: TextStyle(
            color: isToday
                ? widget.accent
                : tokens.textDim.withValues(alpha: value > 0 ? 0.85 : 0.4),
            fontSize: 10,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        _bar(height: height, isToday: isToday),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: isToday
                ? widget.accent.withValues(alpha: 0.9)
                : tokens.textDim.withValues(alpha: 0.6),
            fontSize: 9.5,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _bar({required double height, required bool isToday}) {
    // Past days sit at a calm, dimmer accent; today rides full accent and
    // breathes so the eye catches that it's the live one.
    if (!isToday) {
      return Container(
        width: _barWidth,
        height: height,
        decoration: BoxDecoration(
          color: widget.accent.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _breath,
      builder: (context, _) {
        // Subtle: opacity glides between 0.55 and 1.0.
        final alpha = 0.55 + 0.45 * _breath.value;
        return Container(
          width: _barWidth,
          height: height,
          decoration: BoxDecoration(
            color: widget.accent.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.35 * _breath.value),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Thousands-grouped integer, e.g. 1893 -> "1,893". Small and dependency-free.
String _grouped(int n) {
  if (n < 1000) return '$n';
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return n < 0 ? '-$buf' : buf.toString();
}
