import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/feeds/channel_icon.dart';
import 'package:publicos_desktop/widgets/dashed_add_button.dart';
import 'package:publicos_desktop/widgets/feeds/feed_favicon.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/selection_pill.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// The two payload-less feeds views. The feeds selection model is a single
/// `Object?` that is one of these enum values, a [FeedList], a [Channel], or
/// null (cold start) — see `RssFeedsViewState._selected`. Defined here
/// because the drawer is the lowest-level widget that needs it, and
/// `feeds_view` imports this file already.
enum FeedsView { discover, bookmarks, explore }

/// JSON-feed URL for [channel], or null if we can't synthesize it. Must
/// match the shape used by `RssFeedsViewState._channelJsonUrl` and by
/// `ManageServerPage._channelJsonUrl` so equality on stored router
/// records round-trips.
String? _channelJsonUrl(Channel channel) {
  final addr = PublicOS.myPublicosAddress;
  final server = channel.serverAddress;
  if (addr == null || server == null) return null;
  return '$server/api/$addr/channels/${channel.slug}/json';
}

/// Full-screen left drawer for the feeds tab.
///
/// Takes plain props (lists / channels / selection) instead of a
/// repository, so it drops into a setState-based feeds view without
/// pulling in the repo pattern.
class FeedsNavigationDrawer extends StatelessWidget {
  final List<FeedList> lists;
  final List<Channel> channels;

  /// The current feeds selection — a [FeedList], a [Channel], a [FeedsView]
  /// enum value (discover / bookmarks), or null on cold start. Single source
  /// of truth: each row derives its own highlight by content-checking this
  /// one field, so the modes can't desync.
  final Object? selected;
  final ValueChanged<FeedList> onListSelected;
  final ValueChanged<Channel> onChannelSelected;
  final VoidCallback onBookmarksSelected;

  /// Open the Discover catalogue body. Sits above the LISTS section.
  final VoidCallback onDiscoverSelected;

  /// Open Explore (what the network is reading). Sits above the LISTS section.
  final VoidCallback onExploreSelected;
  final VoidCallback onManageLists;
  /// null = no close button (desktop: the drawer is a fixed column, there is
  /// nothing to close).
  final VoidCallback? onClose;
  final ValueChanged<FeedList>? onEditList;
  final VoidCallback? onCreateChannel;
  final VoidCallback? onSettings;
  final VoidCallback? onManageServer;
  final ValueChanged<Channel>? onManageChannel;

  /// JSON-feed URLs for channels the user has pinned as router tabs.
  /// Drives the Add-as-Tab toggle on each `_ChannelRow`. Updated by the
  /// parent after each mutation completes.
  final Set<String> tabUrls;

  /// Pin the channel as a tab. Returns a Future so the row can show a
  /// busy spinner while the chain write is in flight.
  final Future<void> Function(Channel)? onAddAsTab;

  /// Drop the channel's router-tab record. Returns a Future so the row
  /// can show a busy spinner while the chain write is in flight.
  final Future<void> Function(Channel)? onRemoveFromTab;

  /// Pre-fetched first feed for each `is_single` list — keyed by list id.
  /// Only consulted when `list.isSingle` is true; missing entries fall back
  /// to the multi-feed shape, which is still legible.
  final Map<int, ListFeed> singleFeedByListId;

  /// Resolved Contact lookup keyed by EIP-55 address. Used to render the
  /// `via [contactIcon] displayName` line on single-flagged rows.
  final Map<String, Contact> resolvedContacts;

  const FeedsNavigationDrawer({
    super.key,
    required this.lists,
    required this.channels,
    this.selected,
    required this.onListSelected,
    required this.onChannelSelected,
    required this.onBookmarksSelected,
    required this.onDiscoverSelected,
    required this.onExploreSelected,
    required this.onManageLists,
    this.onClose,
    this.onEditList,
    this.onCreateChannel,
    this.onSettings,
    this.onManageServer,
    this.onManageChannel,
    this.tabUrls = const <String>{},
    this.onAddAsTab,
    this.onRemoveFromTab,
    this.singleFeedByListId = const {},
    this.resolvedContacts = const {},
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // Local copy so the `is` checks below promote — `selected` is a public
    // field and public fields aren't promotable.
    final sel = selected;
    // Single "My Channels" section. Feeds first, then forums, preserving
    // server order within each group. Forum channels get a small glyph
    // badge inside the row instead of a separate section — the server
    // doesn't actually distinguish them as types (it's derived from
    // posting_policy), so the drawer shouldn't either. Only `open`
    // channels (anyone can post) count as forums; `approved` and `owner`
    // both group with feeds.
    final feedChannels = channels.where((c) => !c.isOpen).toList();
    final forumChannels = channels.where((c) => c.isOpen).toList();
    final sortedChannels = [...feedChannels, ...forumChannels];

    return Material(
      // Transparent (desktop delta): the
      // drawer is mounted inside the feeds pane's floating list panel, whose
      // ShellTones.list fill must show through — a solid tokens.background
      // here would repaint the card content-black and break the tonal ladder.
      // (The client's twin stays solid; it is a real overlay drawer there.)
      color: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DrawerHeader(onClose: onClose),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  // Discover hidden for now — re-enable by
                  // uncommenting. The cold-start fallback in feeds_view.dart
                  // can still land on FeedsView.discover when Following is
                  // empty.
                  // _ListRow(
                  //   icon: Icons.explore_rounded,
                  //   iconColor: tokens.connectedAccent,
                  //   label: 'Discover',
                  //   selected: sel == FeedsView.discover,
                  //   onTap: onDiscoverSelected,
                  // ),
                  // const SizedBox(height: 6),
                  _ListRow(
                    icon: Icons.explore_rounded,
                    iconColor: tokens.connectedAccent,
                    label: context.l10n.feedsNavigationDrawerExplore,
                    selected: sel == FeedsView.explore,
                    onTap: onExploreSelected,
                  ),
                  const SizedBox(height: 6),
                  _SectionHeader(
                    label: context.l10n.feedsNavigationDrawerSectionLists,
                    trailing: _HeaderIconButton(
                      icon: Icons.tune_rounded,
                      tooltip:
                          context.l10n.feedsNavigationDrawerManageListsTooltip,
                      onTap: onManageLists,
                    ),
                  ),
                  if (lists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
                      child: Text(
                        context.l10n.feedsNavigationDrawerNoListsYet,
                        style: TextStyle(
                          color: tokens.textDim,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    )
                  else
                    ...lists.map((list) {
                      // A list row is selected iff the single selection IS
                      // this list — no sibling-flag bookkeeping, the model
                      // makes "list selected" and "Discover active" mutually
                      // exclusive by construction.
                      final isSelected = sel is FeedList && sel.id == list.id;
                      if (list.isSingle &&
                          singleFeedByListId.containsKey(list.id)) {
                        final feed = singleFeedByListId[list.id]!;
                        final foundAt = feed.feedFoundAtAccountAddress != null
                            ? resolvedContacts[feed.feedFoundAtAccountAddress!]
                            : null;
                        return _SingleListRow(
                          list: list,
                          feed: feed,
                          foundAt: foundAt,
                          selected: isSelected,
                          onTap: () => onListSelected(list),
                          onLongPress: onEditList == null
                              ? null
                              : () => onEditList!(list),
                        );
                      }
                      return _ListRow(
                        emoji: list.icon,
                        label: list.name,
                        selected: isSelected,
                        onTap: () => onListSelected(list),
                        onLongPress: onEditList == null
                            ? null
                            : () => onEditList!(list),
                      );
                    }),
                  const SizedBox(height: 14),
                  _SectionHeader(
                    label: context.l10n.feedsNavigationDrawerSectionMyChannels,
                  ),
                  ...sortedChannels.map((ch) {
                    final url = _channelJsonUrl(ch);
                    final isInTabs = url != null && tabUrls.contains(url);
                    return _ChannelRow(
                      channel: ch,
                      selected: sel is Channel && sel.id == ch.id,
                      onTap: () => onChannelSelected(ch),
                      onManage: onManageChannel == null
                          ? null
                          : () => onManageChannel!(ch),
                      canToggleTab: url != null,
                      isInTabs: isInTabs,
                      onAddAsTab: onAddAsTab,
                      onRemoveFromTab: onRemoveFromTab,
                    );
                  }),
                  if (onCreateChannel != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                      child: DashedAddButton(
                        label: context.l10n.feedsNavigationDrawerCreateChannel,
                        onTap: onCreateChannel!,
                      ),
                    ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(color: tokens.borderSubtle, height: 1),
                  ),
                  const SizedBox(height: 6),
                  _ListRow(
                    icon: Icons.bookmark_rounded,
                    iconColor: tokens.connectedAccent,
                    label: context.l10n.feedsNavigationDrawerBookmarks,
                    selected: sel == FeedsView.bookmarks,
                    onTap: onBookmarksSelected,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: tokens.borderSubtle, height: 1),
            ),
            if (onManageServer != null)
              _ListRow(
                icon: Icons.dns_outlined,
                label: context.l10n.feedsNavigationDrawerManageServer,
                onTap: onManageServer!,
              ),
            if (onSettings != null)
              _ListRow(
                icon: Icons.format_size_rounded,
                label: context.l10n.feedsNavigationDrawerReadingSettings,
                onTap: onSettings!,
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final VoidCallback? onClose;
  const _DrawerHeader({this.onClose});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      child: Row(
        children: [
          Text(
            context.l10n.feedsNavigationDrawerHeaderTitle,
            style: TextStyle(
              color: tokens.starkWhite,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
          const Spacer(),
          if (onClose != null)
            IconButton(
              icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;
  const _SectionHeader({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final labelText = Text(
      label,
      style: TextStyle(
        color: tokens.textDim,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );
    if (trailing == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
        child: labelText,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [labelText, trailing!],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: tokens.starkWhite),
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String label;
  final bool selected;
  final Color? iconColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ListRow({
    required this.label,
    this.icon,
    this.emoji,
    this.selected = false,
    this.iconColor,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return SelectionPill(
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? tokens.glassFill : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Same 36 px slot as the feed favicon + ChannelIcon rows, so
                // every title in the drawer starts on one line.
                SizedBox(
                  width: 36,
                  child: Center(
                    child: emoji != null && emoji!.isNotEmpty
                        ? Text(emoji!, style: const TextStyle(fontSize: 18))
                        : Icon(
                            icon ?? Icons.list_alt_rounded,
                            size: 19,
                            color: selected
                                ? tokens.starkWhite
                                : (iconColor ?? tokens.starkWhite),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: tokens.starkWhite,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Drawer row for a single-flagged list — renders as the contained feed
/// (icon from feed metadata, name from feed title) with a stacked
/// `via [contactIcon] displayName` sub-line. Mirrors the post-card via
/// shape so the user reads the same identity grammar across surfaces.
class _SingleListRow extends StatelessWidget {
  final FeedList list;
  final ListFeed feed;
  final Contact? foundAt;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _SingleListRow({
    required this.list,
    required this.feed,
    this.foundAt,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final feedName = (feed.feedTitle != null && feed.feedTitle!.isNotEmpty)
        ? feed.feedTitle!
        : (Uri.tryParse(feed.feedUrl)?.host ?? feed.feedUrl);
    return SelectionPill(
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? tokens.glassFill : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                FeedFavicon(feedUrl: feed.feedUrl, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.starkWhite,
                          fontSize: 15,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      if (foundAt != null) ...[
                        const SizedBox(height: 2),
                        _ViaLine(contact: foundAt!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline `via [12px contactIcon] displayName`. Display-only inside the
/// drawer — sits on the row's tap hitspot, so absorbing the tap would
/// steal the gesture meant to open the list/feed. The post-card via-line
/// remains tappable; profile navigation is reachable there.
class _ViaLine extends StatelessWidget {
  final Contact contact;
  const _ViaLine({required this.contact});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.feedsNavigationDrawerVia,
          style: TextStyle(color: tokens.textDim, fontSize: 11),
        ),
        const SizedBox(width: 5),
        GlassContactIcon(contact: contact, size: 12),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            contact.displayName ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tokens.starkWhite.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChannelRow extends StatefulWidget {
  final Channel channel;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onManage;

  /// True when we have enough info (server address + my address) to
  /// build a JSON URL. False suppresses the tab toggle entirely.
  final bool canToggleTab;

  /// Whether this channel currently has a router-tab record. Comes from
  /// the parent's `_tabUrls` set; drives the toggle icon + tooltip.
  final bool isInTabs;
  final Future<void> Function(Channel)? onAddAsTab;
  final Future<void> Function(Channel)? onRemoveFromTab;

  const _ChannelRow({
    required this.channel,
    this.selected = false,
    this.onTap,
    this.onManage,
    this.canToggleTab = false,
    this.isInTabs = false,
    this.onAddAsTab,
    this.onRemoveFromTab,
  });

  @override
  State<_ChannelRow> createState() => _ChannelRowState();
}

class _ChannelRowState extends State<_ChannelRow> {
  /// Count of `pending` follow requests created in the last 14 days.
  /// Null while loading or when the row isn't a private owned channel
  /// (which is the only case where the badge has any meaning).
  int? _pendingCount;

  /// True while the tab-toggle chain write is in flight. The icon swaps
  /// to a spinner and re-taps are ignored.
  bool _tabBusy = false;

  Future<void> _toggleTab() async {
    if (_tabBusy) return;
    final ch = widget.channel;
    final action = widget.isInTabs ? widget.onRemoveFromTab : widget.onAddAsTab;
    if (action == null) return;
    setState(() => _tabBusy = true);
    try {
      await action(ch);
    } finally {
      if (mounted) setState(() => _tabBusy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _maybeLoadPending();
  }

  /// Lazy per-row fetch: fires once on mount for private channels the user
  /// owns. N requests on drawer open scales with channel count, fine at
  /// alpha sizes (< 10 channels per user). Reopening the drawer re-fires
  /// (rows re-mount), which doubles as the user-controlled refresh.
  Future<void> _maybeLoadPending() async {
    final ch = widget.channel;
    if (!ch.isPrivate) return;
    final me = PublicOS.myPublicosAddress;
    if (me == null || ch.ownerAddress == null) return;
    if (me.toLowerCase() != ch.ownerAddress!.toLowerCase()) return;

    final since = DateTime.now().subtract(const Duration(days: 14));
    final resp = await PublicOSChannels.listFollowers(
      slug: ch.slug,
      serverAddress: ch.serverAddress,
      statuses: const ['pending'],
      startDate: since,
    );
    if (!mounted) return;
    if (resp.success && resp.data != null) {
      setState(() => _pendingCount = resp.data!.count);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final channel = widget.channel;
    final selected = widget.selected;
    final onTap = widget.onTap;
    final onManage = widget.onManage;
    return SelectionPill(
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? tokens.glassFill : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                ChannelIcon(channel: channel),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.starkWhite,
                          fontSize: 14.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      if (channel.description.isNotEmpty)
                        Text(
                          channel.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: tokens.textDim, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (channel.isOpen)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, right: 2),
                    child: Icon(
                      Icons.forum_outlined,
                      size: 14,
                      color: tokens.textDim,
                    ),
                  ),
                if (channel.isPrivate)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, right: 2),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: tokens.textDim,
                    ),
                  ),
                // Pending-requests badge — only renders when the per-row fetch
                // came back with a positive count. Owner-only, private-only,
                // last 14 days. Reopening the drawer re-fetches.
                if ((_pendingCount ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, right: 2),
                    child: _PendingBadge(count: _pendingCount!),
                  ),
                if (widget.canToggleTab &&
                    (widget.onAddAsTab != null ||
                        widget.onRemoveFromTab != null))
                  InkResponse(
                    onTap: _tabBusy ? null : _toggleTab,
                    radius: 18,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: _tabBusy
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: tokens.connectedAccent,
                              ),
                            )
                          : Icon(
                              widget.isInTabs
                                  ? Icons.tab_unselected
                                  : Icons.tab_rounded,
                              size: 16,
                              color: widget.isInTabs
                                  ? tokens.fallbackAccent
                                  : tokens.connectedAccent,
                            ),
                    ),
                  ),
                if (onManage != null)
                  InkResponse(
                    onTap: onManage,
                    radius: 18,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.settings_outlined,
                        size: 16,
                        color: tokens.textDim,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact pill rendering a positive count of open follow requests on a
/// private channel row. Tinted with the connected-accent color so it
/// pulls the eye the same way the selected-channel highlight does.
class _PendingBadge extends StatelessWidget {
  final int count;
  const _PendingBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final accent = tokens.connectedAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: accent,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          height: 1.2,
        ),
      ),
    );
  }
}

/// "+ Create channel" CTA placed at the end of the MY CHANNELS section.
/// Dashed rounded-rect border so it reads as a placeholder slot for a
/// channel the user hasn't created yet.
