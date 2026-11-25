import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/feeds/add_custom_feed_sheet.dart';
import 'package:publicos_desktop/widgets/dashed_add_button.dart';
import 'package:publicos_desktop/widgets/feeds/edit_list_sheet.dart';
import 'package:publicos_desktop/widgets/feeds/feed_favicon.dart';
// channelStubFromFeedUrl comes from feed_source.dart.
import 'package:publicos_desktop/widgets/feeds/feed_source.dart';
import 'package:publicos_desktop/widgets/feeds/private_feed_locked_widget.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Dialog for browsing, expanding, editing, deleting feed lists.
///
/// Tap a row to expand and see the feeds in that list with a remove icon.
/// Per-row trailing buttons cover edit and delete; the bottom of the dialog
/// has a Create new list CTA.
///
/// Every list expands into the same two-tier body (followed ACCOUNTS +
/// individual feeds), and every list is editable and deletable — there is no
/// auto-managed list that outranks the others.
///
/// Calls Core directly via `PublicOSFeedLists` / `PublicOSContacts`
/// (no repo layer). On any mutation, [onListsChanged] is invoked so the
/// parent (feeds_pane) can re-load its lists + drawer state.
///
/// **DESKTOP DELTA.** The client shows this as a `DraggableScrollableSheet`
/// bottom sheet; desktop has no bottom sheets, so the same widget is re-shelled
/// as a centered glass dialog per the repo's dialog convention (no drag handle,
/// a top-right close X, fixed max size instead of drag-to-size). The body,
/// state, and every Core call are the client's verbatim.
Future<void> showManageListsSheet(
  BuildContext context, {
  required List<FeedList> lists,
  required VoidCallback onListsChanged,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: DialogWidth.l, maxHeight: 720),
        child: _ManageListsSheet(
          initialLists: lists,
          onListsChanged: onListsChanged,
        ),
      ),
    ),
  );
}

/// "Manage [list]": ONE list's body from the dialog above (people, with their
/// per-channel mutes, then individual feeds, then add-a-feed), opened from the
/// list header in the feed. [onChanged] fires on every change so the host can
/// reload the list the user is looking at. DESKTOP DELTA: a centered glass
/// dialog, same as Manage lists.
Future<void> showManageListSheet(
  BuildContext context, {
  required FeedList list,
  required VoidCallback onChanged,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      final tokens = GlassTokens.of(dialogContext);
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: DialogWidth.l, maxHeight: 720),
          child: Container(
            decoration: BoxDecoration(
              color: tokens.surfaceDeep,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.borderSubtle, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetHeader(
                  title: dialogContext.l10n.manageListSheetTitle(list.name),
                  onClose: () => Navigator.pop(dialogContext),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    // The body is indented under the Manage-lists row icon;
                    // here there is no row, so it sits at the dialog's margin.
                    child: _BodyInset(
                      inset: 20,
                      child: _ListExpanded(
                        listId: list.id,
                        listName: list.name,
                        onChanged: onChanged,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Left indent of a list's body. 60 under a Manage-lists row (clears the row's
/// icon); the one-list dialog sets its own, since it has no row above.
class _BodyInset extends InheritedWidget {
  final double inset;
  const _BodyInset({required this.inset, required super.child});

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_BodyInset>()?.inset ?? 60;

  @override
  bool updateShouldNotify(_BodyInset old) => old.inset != inset;
}

class _ManageListsSheet extends StatefulWidget {
  final List<FeedList> initialLists;
  final VoidCallback onListsChanged;
  const _ManageListsSheet({
    required this.initialLists,
    required this.onListsChanged,
  });

  @override
  State<_ManageListsSheet> createState() => _ManageListsSheetState();
}

class _ManageListsSheetState extends State<_ManageListsSheet> {
  late List<FeedList> _lists;
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _lists = List<FeedList>.from(widget.initialLists);
  }

  Future<void> _refreshLists() async {
    try {
      final updated = await PublicOSFeedLists.getUserLists();
      if (!mounted) return;
      setState(() => _lists = updated);
    } catch (_) {
      // Silent — sheet stays usable with stale local state.
    }
    widget.onListsChanged();
  }

  Future<void> _create() async {
    final created = await showEditListSheet(context);
    if (created == null || !mounted) return;
    await _refreshLists();
  }

  /// Follow an arbitrary RSS feed as its own `is_single` list — the
  /// standalone "Add a feed" affordance. No `listId`, so the add-custom-feed
  /// sheet takes the `followFeedAsSingle` path. On success, refresh so the
  /// new single shows up.
  Future<void> _addFeedAsSingle() async {
    final added = await showAddCustomFeedSheet(context);
    if (!added || !mounted) return;
    await _refreshLists();
  }

  Future<void> _edit(FeedList list) async {
    final updated =
        await showEditListSheet(context, existing: list);
    if (updated == null || !mounted) return;
    await _refreshLists();
  }

  Future<void> _confirmDelete(FeedList list) async {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        title: Text(
          l10n.manageListsSheetDeleteListTitle,
          style: TextStyle(color: tokens.starkWhite),
        ),
        content: Text(
          l10n.manageListsSheetDeleteListBody(list.name),
          style: TextStyle(color: tokens.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.dlgCancel, style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.manageListsSheetDelete,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await PublicOSFeedLists.deleteList(list.id);
    if (!mounted) return;
    if (ok) {
      setState(() => _expanded.remove(list.id));
      await _refreshLists();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.manageListsSheetFailedDeleteList)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // DESKTOP DELTA: a fixed card, not a draggable sheet. No handle (nothing to
    // drag), all four corners rounded (it floats rather than anchoring to the
    // bottom edge), and the ListView owns its own controller since there is no
    // sheet controller to thread.
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceDeep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
              _SheetHeader(
                title: context.l10n.manageListsSheetTitle,
                onClose: () => Navigator.pop(context),
              ),
              Expanded(
                child: _lists.isEmpty
                    ? _Empty(tokens: tokens)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _lists.length,
                        itemBuilder: (context, index) {
                          final list = _lists[index];
                          return _ListRow(
                            list: list,
                            expanded: _expanded.contains(list.id),
                            onToggleExpanded: () => setState(() {
                              if (_expanded.contains(list.id)) {
                                _expanded.remove(list.id);
                              } else {
                                _expanded.add(list.id);
                              }
                            }),
                            onEdit: () => _edit(list),
                            onDelete: () => _confirmDelete(list),
                            onFeedRemoved: widget.onListsChanged,
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: tokens.borderSubtle, height: 1),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DashedAddButton(
                      label: context.l10n.manageListsSheetAddFeed,
                      onTap: _addFeedAsSingle,
                    ),
                    const SizedBox(height: 10),
                    _CreateButton(onTap: _create),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

// DESKTOP DELTA: the client's `_SheetHandle` drag pill is gone — a dialog has
// nothing to drag. `_SheetHeader`'s close X is the only dismiss affordance.

class _SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _SheetHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: tokens.starkWhite,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _ListRow extends StatefulWidget {
  final FeedList list;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onFeedRemoved;

  const _ListRow({
    required this.list,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onEdit,
    required this.onDelete,
    required this.onFeedRemoved,
  });

  @override
  State<_ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<_ListRow> {
  Future<int>? _countFuture;
  /// For is_single rows, the first (and only) feed in the list. Populated
  /// once and drives feed-icon + feed-title rendering at the row level.
  ListFeed? _singleFeed;
  /// Resolved discovery account for the single feed (if its
  /// `feedFoundAtAccountAddress` is non-null and resolvable). Drives the
  /// `via [icon] displayName` sub-line on single-flagged rows.
  Contact? _singleFoundAt;

  @override
  void initState() {
    super.initState();
    _countFuture = _loadCount();
    if (widget.list.isSingle) _loadSingleFeed();
  }

  Future<int> _loadCount() async {
    try {
      // EVERY list's real count is the MERGED set — its stored feeds UNION
      // every account followed in it (unmuted) — not just the `list_feeds`
      // rows. resolveListItems already dedupes and subtracts mutes.
      return (await PublicOSFollows.resolveListItems(widget.list.id)).length;
    } catch (_) {
      return 0;
    }
  }

  /// Lazy per-row fetch: pull the first feed of the single-flagged list +
  /// resolve its discovery contact. Single setState on completion; the row
  /// degrades gracefully to feed-URL host + no via line while pending.
  Future<void> _loadSingleFeed() async {
    try {
      final feeds = await PublicOSFeedLists.getFeedsInList(widget.list.id);
      if (feeds.isEmpty) return;
      final feed = feeds.first;
      Contact? foundAt;
      final addr = feed.feedFoundAtAccountAddress;
      if (addr != null && addr.isNotEmpty) {
        try {
          foundAt = await PublicOSContacts.searchContacts(addr);
          foundAt ??= await PublicOSContacts.resolveByIdentifier(addr);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _singleFeed = feed;
        _singleFoundAt = foundAt;
      });
    } catch (_) {}
  }

  void _refreshCount() {
    setState(() {
      _countFuture = _loadCount();
    });
    if (widget.list.isSingle) _loadSingleFeed();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // Single-flagged lists are renamed by the feed they wrap, not by the
    // user — hide the edit affordance and the row badge says SINGLE
    // instead of DEFAULT. Delete still works (cascades to the feed entry).
    final isSingle = widget.list.isSingle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: isSingle ? null : widget.onToggleExpanded,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Center(
                    child: isSingle && _singleFeed != null
                        ? FeedFavicon(
                            feedUrl: _singleFeed!.feedUrl,
                            size: 22,
                          )
                        : (widget.list.icon != null &&
                                widget.list.icon!.isNotEmpty
                            ? Text(
                                widget.list.icon!,
                                style: const TextStyle(fontSize: 22),
                              )
                            : Icon(
                                Icons.list_alt_rounded,
                                size: 20,
                                color: tokens.starkWhite,
                              )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isSingle && _singleFeed != null
                                  ? ((_singleFeed!.feedTitle != null &&
                                          _singleFeed!.feedTitle!.isNotEmpty)
                                      ? _singleFeed!.feedTitle!
                                      : widget.list.name)
                                  : widget.list.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tokens.starkWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isSingle && _singleFoundAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: _RowViaLine(contact: _singleFoundAt!),
                        )
                      else if (!isSingle)
                        FutureBuilder<int>(
                          future: _countFuture,
                          builder: (context, snap) {
                            final count = snap.data ?? 0;
                            return Text(
                              context.l10n.manageListsSheetFeedCount(count),
                              style: TextStyle(
                                color: tokens.textDim,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                // Single-flagged lists derive their name from the wrapped
                // feed — the user shouldn't rename them. Delete is still
                // exposed (cascades to the feed entry via FK).
                if (!isSingle)
                  _RowAction(
                    icon: Icons.edit_outlined,
                    tooltip: context.l10n.manageListsSheetEditTooltip,
                    onTap: widget.onEdit,
                  ),
                _RowAction(
                    icon: Icons.delete_outline_rounded,
                    tooltip: isSingle
                        ? context.l10n.manageListsSheetUnfollowTooltip
                        : context.l10n.manageListsSheetDelete,
                    destructive: true,
                    onTap: widget.onDelete,
                  ),
                // Single-flagged lists hold exactly one feed (it IS the
                // row), so there's nothing to expand. Hide the chevron and
                // skip the expansion block below.
                if (!isSingle)
                  _RowAction(
                    icon: widget.expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    tooltip: widget.expanded
                        ? context.l10n.manageListsSheetCollapseTooltip
                        : context.l10n.manageListsSheetExpandTooltip,
                    onTap: widget.onToggleExpanded,
                  ),
              ],
            ),
          ),
        ),
        if (!isSingle && widget.expanded)
          // EVERY list is two-tiered now (followed ACCOUNTS + individual
          // feeds). It needs both counts to decide what to show — the "you
          // follow nothing" nudge, or only the non-empty sections. A list with
          // no accounts renders exactly as a feeds-only list did, so nothing
          // regressed for plain lists; _ExpandedFeeds survives EMBEDDED inside
          // this view as the "individual feeds" sub-section.
          _ListExpanded(
            listId: widget.list.id,
            listName: widget.list.name,
            onChanged: () {
              _refreshCount();
              widget.onFeedRemoved();
            },
          ),
      ],
    );
  }
}

class _ExpandedFeeds extends StatefulWidget {
  final int listId;
  final String listName;
  final VoidCallback onChanged;
  const _ExpandedFeeds({
    required this.listId,
    required this.listName,
    required this.onChanged,
  });

  @override
  State<_ExpandedFeeds> createState() => _ExpandedFeedsState();
}

class _ExpandedFeedsState extends State<_ExpandedFeeds> {
  late Future<List<ListFeed>> _future;
  final Map<String, Contact> _resolvedContacts = {};
  // feedUrl → access state. Hydrated lazily after feeds load via the
  // existing `getChannelsByAddress` metadata endpoint, batched per
  // (server, owner) group. Transient — never persisted.
  final Map<String, FeedAccessState> _access = {};
  // feedUrls currently mid-`requestFollow` so the compact CTA can disable.
  final Set<String> _requesting = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ListFeed>> _load() async {
    final lwf = await PublicOSFeedLists.getListWithFeeds(widget.listId);
    final feeds = lwf?.feeds ?? const <ListFeed>[];
    _resolveContacts(feeds);
    _hydrateAccess(feeds);
    return feeds;
  }

  Future<void> _hydrateAccess(List<ListFeed> feeds) async {
    if (feeds.isEmpty) return;
    final urls = feeds.map((f) => f.feedUrl).toList();
    final access = await hydrateFeedAccess(
      urls,
      userAddress: PublicOS.myPublicosAddress,
    );
    if (!mounted) return;
    setState(() {
      _access
        ..clear()
        ..addAll(access);
    });
  }

  Future<void> _requestAccess(ListFeed feed) async {
    final l10n = context.l10n;
    final stub = channelStubFromFeedUrl(feed.feedUrl);
    final owner = stub?.ownerAddress;
    if (owner == null || owner.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.manageListsSheetFailedRequestAccess)),
      );
      return;
    }
    if (_requesting.contains(feed.feedUrl)) return;
    setState(() => _requesting.add(feed.feedUrl));

    final resp = await PublicOSChannels.requestFollow(
      ownerAddress: owner,
      slug: stub!.slug,
      serverAddress: stub.serverAddress,
    );
    if (!mounted) return;

    final code = resp.error?['code'] as String? ?? '';
    final ok = resp.success || code == 'FOLLOW_REQUEST_EXISTS';
    setState(() {
      _requesting.remove(feed.feedUrl);
      if (ok) {
        final prev = _access[feed.feedUrl];
        _access[feed.feedUrl] = FeedAccessState(
          isPrivate: true,
          followStatus: 'pending',
          postCount: prev?.postCount,
        );
      }
    });
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (resp.error?['message'] as String?) ??
                l10n.manageListsSheetFailedRequestAccess,
          ),
        ),
      );
    }
  }


  Future<void> _resolveContacts(List<ListFeed> feeds) async {
    final addresses = <String>{};
    for (final f in feeds) {
      final addr = f.feedFoundAtAccountAddress;
      if (addr != null && addr.isNotEmpty && !_resolvedContacts.containsKey(addr)) {
        addresses.add(addr);
      }
    }
    if (addresses.isEmpty) return;
    final fresh = <String, Contact>{};
    for (final addr in addresses) {
      try {
        final c = await PublicOSContacts.searchContacts(addr);
        if (c != null) fresh[addr] = c;
      } catch (_) {}
    }
    if (mounted && fresh.isNotEmpty) {
      setState(() => _resolvedContacts.addAll(fresh));
    }
  }

  Future<void> _confirmRemove(ListFeed feed) async {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        title: Text(l10n.manageListsSheetRemoveFeedTitle,
            style: TextStyle(color: tokens.starkWhite)),
        content: Text(
          l10n.manageListsSheetRemoveFeedBody(
            feed.feedTitle?.isNotEmpty == true
                ? feed.feedTitle!
                : (Uri.tryParse(feed.feedUrl)?.host ?? feed.feedUrl),
            widget.listName,
          ),
          style: TextStyle(color: tokens.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.dlgCancel, style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.manageListsSheetRemove,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _remove(feed);
  }

  Future<void> _remove(ListFeed feed) async {
    final l10n = context.l10n;
    final ok =
        await PublicOSFeedLists.removeFeedFromList(widget.listId, feed.id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _future = _load();
      });
      widget.onChanged();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.manageListsSheetFailedRemoveFeed)),
      );
    }
  }

  Future<void> _addFeed() async {
    final added = await showAddCustomFeedSheet(context, listId: widget.listId);
    if (!added || !mounted) return;
    setState(() {
      _future = _load();
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return FutureBuilder<List<ListFeed>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Padding(
            padding: EdgeInsets.fromLTRB(_BodyInset.of(context), 4, 16, 12),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(tokens.textDim),
              ),
            ),
          );
        }
        final feeds = snapshot.data ?? const <ListFeed>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (feeds.isEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(_BodyInset.of(context), 0, 16, 8),
                child: Text(
                  context.l10n.manageListsSheetNoFeedsYet,
                  style: TextStyle(color: tokens.textDim, fontSize: 12),
                ),
              )
            else
              ...feeds.map((f) {
            final host = Uri.tryParse(f.feedUrl)?.host ?? f.feedUrl;
            final addr = f.feedFoundAtAccountAddress;
            final contact = (addr != null && addr.isNotEmpty)
                ? _resolvedContacts[addr]
                : null;
            final access = _access[f.feedUrl];
            final showNoAccess =
                access != null && access.isLockedNoAccess && !access.isPending;
            final showPending = access != null && access.isLockedAndPending;
            return Padding(
              padding: EdgeInsets.fromLTRB(_BodyInset.of(context), 0, 16, 8),
              child: Row(
                  children: [
                    if (contact != null)
                      GlassContactIcon(opensProfile: true, contact: contact, size: 32)
                    else if (addr != null && addr.isNotEmpty)
                      GlassContactIcon(opensProfile: true, address: addr, size: 32)
                    else
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: tokens.borderSubtle, width: 1),
                          borderRadius: BorderRadius.circular(8),
                          color: tokens.glassFill,
                        ),
                        child: Icon(
                          Icons.rss_feed_rounded,
                          size: 16,
                          color: tokens.starkWhite,
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  f.feedTitle?.isNotEmpty == true
                                      ? f.feedTitle!
                                      : host,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: tokens.starkWhite,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (showNoAccess) ...[
                                const SizedBox(width: 6),
                                _AccessBadge(
                                  tokens: tokens,
                                  label: context.l10n.manageListsSheetNoAccessBadge,
                                  color: tokens.fallbackAccent,
                                ),
                              ] else if (showPending) ...[
                                const SizedBox(width: 6),
                                _AccessBadge(
                                  tokens: tokens,
                                  label: context.l10n.manageListsSheetPendingBadge,
                                  color: tokens.fallbackAccent,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            contact != null
                                ? '${contact.displayName} • $host'
                                : host,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tokens.textDim,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showNoAccess)
                      _requesting.contains(f.feedUrl)
                          ? Padding(
                              padding: const EdgeInsets.all(8),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      tokens.textDim),
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.vpn_key_rounded,
                                size: 18,
                                color: tokens.textDim,
                              ),
                              tooltip: context.l10n.manageListsSheetRequestAccessTooltip,
                              onPressed: () => _requestAccess(f),
                            ),
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 18,
                        color: tokens.textDim,
                      ),
                      tooltip: context.l10n.manageListsSheetRemoveFromListTooltip,
                      onPressed: () => _confirmRemove(f),
                    ),
                  ],
                ),
            );
          }),
            Padding(
              padding: EdgeInsets.fromLTRB(_BodyInset.of(context), 4, 16, 12),
              child: DashedAddButton(
                label: context.l10n.manageListsSheetAddFeed,
                onTap: _addFeed,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AccessBadge extends StatelessWidget {
  final GlassTokens tokens;
  final String label;
  final Color color;
  const _AccessBadge({
    required this.tokens,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}


/// Short `0x1234…abcd` label for an account with no resolved display name.
String _shortAddr(String a) => a.length > 12
    ? '${a.substring(0, 6)}…${a.substring(a.length - 4)}'
    : a;

/// A list's expanded body. Coordinates the two sub-stores so the
/// empty states read honestly:
///   • follow nothing (no accounts AND no feeds) → one friendly nudge
///   • follow an account but no individual feeds → accounts only, no "no feeds"
///   • both present → FOLLOWED ACCOUNTS then INDIVIDUAL FEEDS
/// Only the two counts are loaded here to pick the layout; the sub-widgets own
/// their own data + reloads.
class _ListExpanded extends StatefulWidget {
  final int listId;
  final String listName;
  final VoidCallback onChanged;
  const _ListExpanded({
    required this.listId,
    required this.listName,
    required this.onChanged,
  });

  @override
  State<_ListExpanded> createState() => _ListExpandedState();
}

class _ListExpandedState extends State<_ListExpanded> {
  late Future<({int accounts, int feeds})> _counts;

  @override
  void initState() {
    super.initState();
    _counts = _load();
  }

  Future<({int accounts, int feeds})> _load() async {
    final session = PublicOS.sessionBlockchainAddress;
    final accounts = session == null
        ? 0
        : (await PublicOS.database.listFollowedAccounts(
            session: session,
            listId: widget.listId,
          ))
            .length;
    final feeds =
        (await PublicOSFeedLists.getFeedsInList(widget.listId)).length;
    return (accounts: accounts, feeds: feeds);
  }

  void _reload() {
    // Block body on purpose: an arrow would RETURN the Future, which
    // debug Flutter rejects (assert) before scheduling the rebuild
    // (the sheet would stay stale until dragged).
    setState(() {
      _counts = _load();
    });
    widget.onChanged();
  }

  Future<void> _addFeed() async {
    final added =
        await showAddCustomFeedSheet(context, listId: widget.listId);
    if (!added || !mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return FutureBuilder<({int accounts, int feeds})>(
      future: _counts,
      builder: (context, snapshot) {
        // Spinner on the FIRST load only. A recount keeps the old counts on
        // screen, so a mute or a removal doesn't tear down the sections (and
        // collapse the row the user was working in).
        if (!snapshot.hasData) {
          return Padding(
            padding: EdgeInsets.fromLTRB(_BodyInset.of(context), 4, 16, 12),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(tokens.textDim),
              ),
            ),
          );
        }
        final counts = snapshot.data ?? (accounts: 0, feeds: 0);
        final hasAccounts = counts.accounts > 0;
        final hasFeeds = counts.feeds > 0;

        // Following nothing at all — one friendly nudge, plus the add-feed path
        // (the "individual URLs" half of it).
        if (!hasAccounts && !hasFeeds) {
          return Padding(
            padding: EdgeInsets.fromLTRB(_BodyInset.of(context), 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.manageListsSheetFollowingEmpty,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                DashedAddButton(
                  label: context.l10n.manageListsSheetAddFeed,
                  onTap: _addFeed,
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasAccounts)
              _FollowedAccountsTier(
                listId: widget.listId,
                listName: widget.listName,
                // The header only earns its keep separating two sections.
                showHeader: hasFeeds,
                onChanged: _reload,
              ),
            if (hasFeeds) ...[
              if (hasAccounts)
                Padding(
                  padding: EdgeInsets.fromLTRB(_BodyInset.of(context), 4, 16, 4),
                  child: Text(
                    context.l10n.manageListsSheetIndividualFeeds,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              // _ExpandedFeeds carries its own "add feed" button at the bottom.
              _ExpandedFeeds(
                listId: widget.listId,
                listName: widget.listName,
                onChanged: _reload,
              ),
            ] else
              // Accounts but no individual feeds — offer to add one, without the
              // "no feeds in this list yet" language.
              Padding(
                padding: EdgeInsets.fromLTRB(_BodyInset.of(context), 6, 16, 12),
                child: DashedAddButton(
                  label: context.l10n.manageListsSheetAddFeed,
                  onTap: _addFeed,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The accounts tier of the list manager: every account followed IN THIS
/// LIST, each
/// expandable to its enlisted channels with a per-channel mute toggle. Renders
/// above the individual single-feed follows. Empty (collapses to nothing) when
/// the user follows no accounts.
class _FollowedAccountsTier extends StatefulWidget {
  /// The list whose accounts these are. Accounts are per-list members, so this
  /// tier is scoped — it is NOT the global follow set.
  final int listId;
  final String listName;
  final VoidCallback onChanged;

  /// Show the "FOLLOWED ACCOUNTS" section header. Suppressed when this tier is
  /// the only section on screen (no individual feeds) — a lone divider over the
  /// only content reads as noise.
  final bool showHeader;
  const _FollowedAccountsTier({
    required this.listId,
    required this.listName,
    required this.onChanged,
    this.showHeader = true,
  });

  @override
  State<_FollowedAccountsTier> createState() => _FollowedAccountsTierState();
}

class _FollowedAccountsTierState extends State<_FollowedAccountsTier> {
  late Future<List<FollowedAccount>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<FollowedAccount>> _load() async {
    final session = PublicOS.sessionBlockchainAddress;
    if (session == null) return const [];
    return PublicOS.database
        .listFollowedAccounts(session: session, listId: widget.listId);
  }

  /// Same confirm shape as a feed's, naming the person ([name] is the row's
  /// resolved display name, or the short address while it resolves).
  Future<void> _confirmUnfollow(FollowedAccount account, String name) async {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        title: Text(l10n.manageListsSheetRemovePersonTitle,
            style: TextStyle(color: tokens.starkWhite)),
        content: Text(
          l10n.manageListsSheetRemovePersonBody(name, widget.listName),
          style: TextStyle(color: tokens.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.dlgCancel, style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.manageListsSheetRemove,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _unfollow(account);
  }

  Future<void> _unfollow(FollowedAccount account) async {
    final session = PublicOS.sessionBlockchainAddress;
    if (session == null) return;
    // unfollowAccount cascades THIS LIST's mutes for the account in one
    // transaction. The account stays followed in any other list it's in.
    await PublicOS.database.unfollowAccount(
      session: session,
      account: account.accountAddress,
      listId: widget.listId,
    );
    final left = await _load();
    if (!mounted) return;
    // Block body: see _ListExpanded._reload.
    setState(() {
      _future = Future.value(left);
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return FutureBuilder<List<FollowedAccount>>(
      future: _future,
      builder: (context, snapshot) {
        final accounts = snapshot.data ?? const <FollowedAccount>[];
        if (accounts.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeader)
              Padding(
                padding: EdgeInsets.fromLTRB(_BodyInset.of(context), 0, 16, 4),
                child: Text(
                  context.l10n.manageListsSheetFollowedAccounts,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ...accounts.map((a) => _FollowedAccountRow(
                  key: ValueKey(a.accountAddress),
                  account: a,
                  onUnfollow: (name) => _confirmUnfollow(a, name),
                  // A mute changes the list's roster just like an unfollow.
                  onMuteChanged: widget.onChanged,
                )),
          ],
        );
      },
    );
  }
}

/// One followed account in the manager. Resolves its display contact and its
/// channel set (from the profile, the same source the feed view merges), and
/// exposes a per-channel mute toggle (`on` = audible; toggling `off` inserts an
/// `(accountAddress, feedUrl)` mute).
class _FollowedAccountRow extends StatefulWidget {
  final FollowedAccount account;
  /// Gets the name the row shows, so the confirm names the same person.
  final void Function(String name) onUnfollow;
  final VoidCallback onMuteChanged;
  const _FollowedAccountRow({
    super.key,
    required this.account,
    required this.onUnfollow,
    required this.onMuteChanged,
  });

  @override
  State<_FollowedAccountRow> createState() => _FollowedAccountRowState();
}

class _FollowedAccountRowState extends State<_FollowedAccountRow> {
  bool _expanded = false;
  Contact? _contact;
  List<ResolvedChannel>? _channels;
  final Set<String> _muted = {};

  @override
  void initState() {
    super.initState();
    _resolveContact();
    _loadChannels(); // eager, for the channel count + instant expand
  }

  Future<void> _resolveContact() async {
    try {
      final c = await PublicOSContacts.getContact(
          EthereumAddress.fromHex(widget.account.accountAddress));
      if (mounted && c != null) setState(() => _contact = c);
    } catch (_) {}
  }

  Future<void> _loadChannels() async {
    try {
      final account = EthereumAddress.fromHex(widget.account.accountAddress);
      final channels = await PublicOSFollows.resolveProfileChannels(account);
      final session = PublicOS.sessionBlockchainAddress;
      final mutes = session == null
          ? const <String, Set<String>>{}
          : await PublicOS.database.allMutedKeys(
              session: session,
              listId: widget.account.listId,
            );
      if (!mounted) return;
      setState(() {
        _channels = channels;
        _muted
          ..clear()
          ..addAll(mutes[widget.account.accountAddress.toLowerCase()] ?? const {});
      });
    } catch (_) {
      if (mounted) setState(() => _channels = const []);
    }
  }

  Future<void> _toggleMute(ResolvedChannel c) async {
    final session = PublicOS.sessionBlockchainAddress;
    if (session == null) return;
    // Mutes are anchored on the STABLE record.key, not the current URL, so a
    // mute survives the author re-pointing the channel.
    final isMuted = _muted.contains(c.key);
    if (isMuted) {
      await PublicOS.database.unmuteChannel(
        session: session,
        account: widget.account.accountAddress,
        listId: widget.account.listId,
        recordKey: c.key,
      );
    } else {
      await PublicOS.database.muteChannel(
        session: session,
        account: widget.account.accountAddress,
        listId: widget.account.listId,
        recordKey: c.key,
      );
    }
    if (!mounted) return;
    setState(() {
      if (isMuted) {
        _muted.remove(c.key);
      } else {
        _muted.add(c.key);
      }
    });
    widget.onMuteChanged();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final addr = widget.account.accountAddress;
    final name = _contact?.displayName ?? _shortAddr(addr);
    final channels = _channels;
    // Subline reflects how many of the account's channels are actually followed
    // (i.e. not muted): "following all N channels" when none are muted, else
    // "following X/Y channels". Plain "Following" while the set is still loading
    // or the account enlists none.
    final total = channels?.length ?? 0;
    final followedCount =
        channels?.where((c) => !_muted.contains(c.key)).length ?? 0;
    final subline = (channels == null || total == 0)
        ? l10n.manageListsSheetFollowingAccount
        : (followedCount == total
            ? l10n.manageListsSheetFollowingAllChannels(total)
            : l10n.manageListsSheetFollowingSomeChannels(followedCount, total));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(_BodyInset.of(context), 0, 16, 8),
          child: Row(
            children: [
              // The person (avatar + name) opens their profile; the trailing
              // buttons keep their own taps. Desktop delta: the pane switch
              // happens under this sheet, so the sheet closes first.
              Expanded(
                child: InkWell(
                  onTap: () {
                    final contact = _contact;
                    Navigator.of(context, rootNavigator: true)
                        .popUntil((r) => r.isFirst);
                    if (contact != null) {
                      AppNav.toContact(context, contact);
                    } else {
                      AppNav.toProfile(context, addr);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      _contact != null
                          ? GlassContactIcon(contact: _contact!, size: 32)
                          : GlassContactIcon(address: addr, size: 32),
                      const SizedBox(width: 10),
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
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              subline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: tokens.textDim, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline_rounded,
                    size: 18, color: tokens.textDim),
                tooltip: context.l10n.manageListsSheetUnfollowTooltip,
                onPressed: () => widget.onUnfollow(name),
              ),
              if (channels != null && channels.isNotEmpty)
                IconButton(
                  icon: Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: tokens.textDim,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
            ],
          ),
        ),
        if (_expanded && channels != null)
          ...channels.map((c) {
            final muted = _muted.contains(c.key);
            return Padding(
              padding: EdgeInsets.fromLTRB(_BodyInset.of(context) + 24, 0, 16, 8),
              child: Row(
                children: [
                  FeedFavicon(feedUrl: c.feedUrl, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (c.title != null && c.title!.isNotEmpty)
                          ? c.title!
                          : (Uri.tryParse(c.feedUrl)?.host ?? c.feedUrl),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted ? tokens.textDim : tokens.starkWhite,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (muted)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        context.l10n.manageListsSheetMutedBadge,
                        style: TextStyle(
                          color: tokens.textDim,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  Switch.adaptive(
                    value: !muted, // on = audible / unmuted
                    onChanged: (_) => _toggleMute(c),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _RowAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool destructive;
  final VoidCallback onTap;

  const _RowAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final color = destructive
        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.85)
        : tokens.textDim;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: tokens.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tokens.borderMedium, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: tokens.starkWhite,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.manageListsSheetCreateNewList,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
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

class _Empty extends StatelessWidget {
  final GlassTokens tokens;
  const _Empty({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.list_alt_rounded,
            size: 56,
            color: tokens.textDim,
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.manageListsSheetNoListsYet,
            style: TextStyle(color: tokens.textDim, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// `via [12px GlassContactIcon] displayName` — tappable, opens the contact's
/// profile. Mirrors the shape used in the drawer + add-to-lists sheet +
/// post-card subtitle so single-flagged surfaces read the same.
class _RowViaLine extends StatelessWidget {
  final Contact contact;
  const _RowViaLine({required this.contact});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final hasProfile = contact.publicosAddress != null &&
        contact.publicosAddress!.eip55With0x !=
            '0x0000000000000000000000000000000000000000';
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.manageListsSheetVia,
            style: TextStyle(color: tokens.textDim, fontSize: 11)),
        const SizedBox(width: 5),
        GlassContactIcon(contact: contact, size: 12),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(
            contact.displayName,
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
    if (!hasProfile) return row;
    return InkWell(
      onTap: () => AppNav.toContact(context, contact),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: row,
      ),
    );
  }
}
