// Explore.
//
// What the whole network is reading. The fetch lives in ExplorePostSource
// and the posts tab is the shared
// PostSurface → PostListView, so trending posts scroll, snap and play like
// every other post list. This view keeps what is Explore's own: the Posts |
// Feeds toggle, the window chips, and the feeds tab's channel rows (rows, not
// posts — they never go through the renderer).
//
// Reading this list records nothing. A tap goes to the item's own server, the
// same as anywhere else in the app: a post opens its detail page (comments,
// reactions and the read beacon all point home), a channel opens the feed
// reader on its own server. That is where the read counts.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/explorer_chip.dart';
import 'package:publicos_desktop/widgets/feeds/explore_post_source.dart';
import 'package:publicos_desktop/widgets/feeds/feed_favicon.dart';
import 'package:publicos_desktop/widgets/feeds/post_card.dart'
    show PostLayoutMode;
import 'package:publicos_desktop/widgets/feeds/post_source.dart';
import 'package:publicos_desktop/widgets/feeds/post_surface.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

enum _ExploreTab { posts, feeds }

class ExploreView extends StatefulWidget {
  final Color? color;

  /// Settings overrides — same contract as PostsList / BookmarksView: when
  /// null the surface reads `PublicOSSettings` itself on init.
  final double? titleTextSize;
  final double? descriptionTextSize;
  final int? bodyMaxChars;
  final PostLayoutMode? layoutMode;

  final ScrollController? scrollController;

  /// Same unified-spinner contract as BookmarksView. Explore reports for BOTH
  /// tabs itself (the posts surface is unmounted on the feeds tab), so the
  /// surface gets no callback of its own.
  final bool showFullScreenLoader;
  final ValueChanged<bool>? onLoadingChanged;

  /// The pane bumps it to re-fetch both lists.
  final int refreshTick;
  const ExploreView({
    super.key,
    this.color,
    this.titleTextSize,
    this.descriptionTextSize,
    this.bodyMaxChars,
    this.layoutMode,
    this.scrollController,
    this.showFullScreenLoader = true,
    this.onLoadingChanged,
    this.refreshTick = 0,
  });

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
  final ExplorePostSource _source = ExplorePostSource();
  _ExploreTab _tab = _ExploreTab.posts;

  bool get _isLoading => _source.state is PostsLoading;

  @override
  void initState() {
    super.initState();
    _source.addListener(_onSourceChanged);
    // The surface starts the first load on attach; on the posts tab that is
    // the first build. Start it here so the feeds tab never waits on it.
    _source.load();
    _reportLoading();
  }

  @override
  void didUpdateWidget(ExploreView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != oldWidget.refreshTick) _source.refreshShowingNewest();
  }
  @override
  void dispose() {
    _source.removeListener(_onSourceChanged);
    _source.dispose();
    super.dispose();
  }

  void _onSourceChanged() {
    if (!mounted) return;
    setState(() {});
    _reportLoading();
  }

  bool _lastReportedLoading = false;
  void _reportLoading() {
    final cb = widget.onLoadingChanged;
    if (cb == null) return;
    final v = _isLoading;
    if (v == _lastReportedLoading) return;
    _lastReportedLoading = v;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) cb(v);
    });
  }

  void _selectCut(String cut) {
    if (cut == _source.cut) return;
    HapticFeedback.selectionClick();
    _source.selectCut(cut);
  }

  // -- Build -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GlassTokens.of(context);
    return Column(
      children: [
        _buildControls(tokens),
        Expanded(
          child: _tab == _ExploreTab.posts
              ? PostSurface(
                  source: _source,
                  color: widget.color,
                  titleTextSize: widget.titleTextSize,
                  descriptionTextSize: widget.descriptionTextSize,
                  bodyMaxChars: widget.bodyMaxChars,
                  layoutMode: widget.layoutMode,
                  scrollController: widget.scrollController,
                  showFullScreenLoader: widget.showFullScreenLoader,
                )
              : _buildChannels(theme, tokens),
        ),
      ],
    );
  }

  Widget _buildControls(GlassTokens tokens) {
    final l10n = context.l10n;
    final labels = {
      TrendingCut.now: l10n.exploreWindowNow,
      TrendingCut.hour: l10n.exploreWindowHour,
      TrendingCut.h12: l10n.exploreWindow12h,
      TrendingCut.h24: l10n.exploreWindow24h,
    };
    final cut = _source.cut;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _TabToggle(
            current: _tab,
            postsLabel: l10n.exploreTabPosts,
            feedsLabel: l10n.exploreTabFeeds,
            onChanged: (t) {
              if (t == _tab) return;
              HapticFeedback.selectionClick();
              setState(() => _tab = t);
            },
            ),
          ),
          // The explorer chips every other view uses.
          ExplorerChipBar(
            children: [
              for (final c in TrendingCut.all) ...[
                ExplorerChip(
                  label: labels[c]!,
                  active: c == cut,
                  onTap: () => _selectCut(c),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// The feeds tab: channel rows, Explore's own list (not posts).
  Widget _buildChannels(ThemeData theme, GlassTokens tokens) {
    if (_isLoading) {
      return widget.showFullScreenLoader
          ? const Center(child: PhigitalLoadingWidget())
          : const SizedBox.shrink();
    }
    final items = _source.channels?.items ?? const <TrendingChannel>[];
    if (items.isEmpty) return _buildEmpty(theme, tokens);
    return RefreshIndicator(
      onRefresh: _source.load,
      color: widget.color ?? theme.colorScheme.primary,
      child: ListView.builder(
        controller: widget.scrollController,
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, i) => _ChannelRow(
          rank: i + 1,
          item: items[i],
          readersLabel: context.l10n.exploreReaders,
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, GlassTokens tokens) {
    return RefreshIndicator(
      onRefresh: _source.load,
      color: widget.color ?? theme.colorScheme.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
        children: [
          Icon(Icons.explore_outlined, size: 40, color: tokens.textDim),
          const SizedBox(height: 14),
          Text(
            context.l10n.exploreEmptyTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tokens.starkWhite,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.exploreEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: tokens.textDim, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Posts | Feeds — two labels over a hairline, with a white underline that
/// slides under the selected one (a filled segment is hard to tell apart).
class _TabToggle extends StatelessWidget {
  final _ExploreTab current;
  final String postsLabel;
  final String feedsLabel;
  final ValueChanged<_ExploreTab> onChanged;

  const _TabToggle({
    required this.current,
    required this.postsLabel,
    required this.feedsLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    Widget label(_ExploreTab tab, String text) {
      final active = tab == current;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(tab),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: active ? tokens.starkWhite : tokens.textDim,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              child: Text(text, textAlign: TextAlign.center),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(height: 1, color: tokens.borderSubtle),
        ),
        Row(
          children: [
            label(_ExploreTab.posts, postsLabel),
            label(_ExploreTab.feeds, feedsLabel),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: current == _ExploreTab.posts
                  ? Alignment.bottomLeft
                  : Alignment.bottomRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Center(
                  heightFactor: 1,
                  child: Container(
                    width: 48,
                    height: 2,
                    decoration: BoxDecoration(
                      color: tokens.starkWhite,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One trending channel: favicon, name, description, readers. A click opens
/// the feed on the channel's own server, where the read counts.
class _ChannelRow extends StatelessWidget {
  final int rank;
  final TrendingChannel item;
  final String Function(int count) readersLabel;

  const _ChannelRow({
    required this.rank,
    required this.item,
    required this.readersLabel,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final ch = item.channel;
    final name = ch.name.isNotEmpty ? ch.name : ch.slug;
    return InkWell(
      // DELTA (desktop): the Feeds pane on this feed, ← back to Explore.
      onTap: () =>
          AppNav.onOpenFeedUrl?.call(item.feedUrl, name, item.ownerAddress, null),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: tokens.textDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FeedFavicon(feedUrl: item.feedUrl, size: 36, faviconFirst: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.starkWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (ch.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      ch.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tokens.textDim, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              readersLabel(item.value),
              style: TextStyle(
                color: tokens.textDim,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
