import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/feeds/edit_list_sheet.dart';
import 'package:publicos_desktop/widgets/feeds/feed_favicon.dart';
import 'package:publicos_desktop/widgets/feeds/list_header_card.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Bottom sheet for picking which lists a FEED belongs to + creating /
/// removing a single-flagged list that wraps this feed.
///
/// Layout (top → bottom):
///   1. "Single follow" section — one row representing this feed as a
///      single follow. Affordance flips on whether a single already exists:
///        - `+` (no single yet) → tap creates is_single list + adds feed,
///          dismisses sheet
///        - `x` (single already exists) → tap → confirm "Unfollow X?" →
///          cascade-delete feed row + list row
///   2. "Lists" section — every multi-feed list, with checkbox toggle. No
///      list is filtered out by name; single-flagged lists aren't shown
///      because singles aren't valid add-targets.
///   3. CTA: "+ Create a new list" → opens edit-list sheet, adds feed to the
///      new (multi-feed) list, dismisses.
///   4. CTA: "Save" — commits checkbox changes.
///
/// Returns `true` if any change was committed, `false` if nothing changed,
/// `null` if dismissed without saving.
Future<bool?> showAddToListsSheet(
  BuildContext context, {
  String? feedUrl,
  String? feedTitle,
  String? feedDescription,
  String? feedFoundAtAccountAddress,

  /// The owner's `record.key` when this feed is a CHANNEL (browser channel
  /// tab). Null for a raw URL. Stored so the follow re-resolves.
  String? feedRecordKey,

  /// ACCOUNT MODE. When set (eip55With0x), the sheet manages which lists this
  /// ACCOUNT belongs to instead of a feed: rows are pre-checked with current
  /// memberships, checking adds, unchecking removes. Accounts can never be
  /// singles, so the single-follow section is hidden.
  String? accountAddress,
}) {
  assert((feedUrl != null) ^ (accountAddress != null),
      'the sheet targets exactly one of a feed or an account');
  // DESKTOP DELTA: re-shelled from the client's bottom sheet to a centered
  // glass dialog. Same widget, same args, same return contract (true =
  // something committed, false = nothing changed, null = dismissed).
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: DialogWidth.m, maxHeight: 660),
        child: _AddToListsSheet(
          feedUrl: feedUrl ?? '',
          accountAddress: accountAddress,
          feedTitle: feedTitle,
          feedDescription: feedDescription,
          feedFoundAtAccountAddress: feedFoundAtAccountAddress,
          feedRecordKey: feedRecordKey,
        ),
      ),
    ),
  );
}

class _AddToListsSheet extends StatefulWidget {
  final String feedUrl;
  final String? accountAddress;
  final String? feedTitle;
  final String? feedDescription;
  final String? feedFoundAtAccountAddress;
  final String? feedRecordKey;

  const _AddToListsSheet({
    required this.feedUrl,
    this.accountAddress,
    this.feedTitle,
    this.feedDescription,
    this.feedFoundAtAccountAddress,
    this.feedRecordKey,
  });

  @override
  State<_AddToListsSheet> createState() => _AddToListsSheetState();
}

class _AddToListsSheetState extends State<_AddToListsSheet> {
  /// Multi-feed user lists (singles are not valid add-targets).
  List<FeedList> _lists = [];

  /// listId → membership at sheet open
  Map<int, bool> _initialSelected = {};

  /// listId → current membership (toggled by user)
  Map<int, bool> _selected = {};

  /// listId → row id of the feed entry in that list (needed for removal)
  final Map<int, int> _feedIdInList = {};

  /// listId → feed count for display
  final Map<int, int> _feedCount = {};

  /// Who each list follows, people + feeds, for its row: a list's feed count
  /// alone would leave out the people it follows.
  final Map<int, ListFollowSummary> _summaries = {};

  /// The single-flagged list currently containing this feed (if any).
  /// Drives the single-follow row's affordance: null → `+`, non-null → `x`.
  FeedList? _existingSingle;

  /// Resolved contact for `feedFoundAtAccountAddress` — used to render the
  /// via line on the single-follow row.
  Contact? _foundAtContact;

  bool _loading = true;
  bool _saving = false;
  bool _singlePending = false;

  /// True when the sheet is managing an ACCOUNT's list memberships rather
  /// than a feed's. Accounts are never singles, so the single-follow section
  /// is suppressed and the commit path writes FollowedAccounts rows.
  bool get _accountMode => widget.accountAddress != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final allLists = await PublicOSFeedLists.getUserLists();
      final initial = <int, bool>{};
      _feedIdInList.clear();
      _feedCount.clear();
      _summaries.clear();

      // Every multi-feed list is a valid target. Only `is_single` lists are
      // excluded: a single IS one feed rendered as itself, so adding a second
      // feed would silently turn it into a normal list. The dedicated
      // single-follow row above the section covers that case.
      final multiLists = allLists.where((l) => !l.isSingle).toList();

      // ACCOUNT MODE: membership comes from FollowedAccounts, so the sheet
      // doubles as the "where is this account followed" manager.
      var accountLists = <int>{};
      if (_accountMode) {
        final session = PublicOS.sessionBlockchainAddress;
        if (session != null) {
          accountLists = await PublicOS.database.listsContainingAccount(
            session: session,
            account: widget.accountAddress!,
          );
        }
      }

      for (final list in multiLists) {
        final feeds = await PublicOSFeedLists.getFeedsInList(list.id);
        _feedCount[list.id] = feeds.length;
        _summaries[list.id] = await ListFollowSummary.load(list.id);
        if (_accountMode) {
          initial[list.id] = accountLists.contains(list.id);
          continue;
        }
        final match =
            feeds.where((f) => f.feedUrl == widget.feedUrl).firstOrNull;
        initial[list.id] = match != null;
        if (match != null) _feedIdInList[list.id] = match.id;
      }

      // Existing single for this feed (if any) — drives the +/x affordance.
      // Never in account mode: accounts can't be singles.
      final existingSingle = _accountMode
          ? null
          : await PublicOSFeedLists.findSingleListForFeed(widget.feedUrl);

      // Resolve foundAt contact for the via line.
      Contact? foundAt;
      final addr = widget.feedFoundAtAccountAddress;
      if (addr != null && addr.isNotEmpty) {
        try {
          foundAt = await PublicOSContacts.searchContacts(addr);
          foundAt ??= await PublicOSContacts.resolveByIdentifier(addr);
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _lists = multiLists;
        _initialSelected = initial;
        _selected = Map<int, bool>.from(initial);
        _existingSingle = existingSingle;
        _foundAtContact = foundAt;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool get _hasChanges {
    for (final id in _selected.keys) {
      if (_selected[id] != _initialSelected[id]) return true;
    }
    return false;
  }

  Future<void> _save() async {
    if (!_hasChanges) {
      Navigator.pop(context, false);
      return;
    }
    final l10n = context.l10n;
    setState(() => _saving = true);
    int added = 0;
    int removed = 0;
    int failed = 0;
    for (final id in _selected.keys) {
      final was = _initialSelected[id] ?? false;
      final now = _selected[id] ?? false;
      if (was == now) continue;
      if (_accountMode) {
        final session = PublicOS.sessionBlockchainAddress;
        if (session == null) {
          failed++;
          continue;
        }
        try {
          if (!was && now) {
            await PublicOS.database.followAccount(
              session: session,
              account: widget.accountAddress!,
              listId: id,
            );
            added++;
          } else {
            await PublicOS.database.unfollowAccount(
              session: session,
              account: widget.accountAddress!,
              listId: id,
            );
            removed++;
          }
        } catch (_) {
          failed++;
        }
        continue;
      }
      if (!was && now) {
        final ok = await PublicOSFeedLists.addFeedToList(
          id,
          widget.feedUrl,
          widget.feedTitle,
          widget.feedDescription,
          feedFoundAtAccountAddress: widget.feedFoundAtAccountAddress,
          feedRecordKey: widget.feedRecordKey,
        );
        ok ? added++ : failed++;
      } else if (was && !now) {
        final feedId = _feedIdInList[id];
        if (feedId == null) {
          failed++;
          continue;
        }
        final ok = await PublicOSFeedLists.removeFeedFromList(id, feedId);
        ok ? removed++ : failed++;
      }
    }
    if (!mounted) return;
    Navigator.pop(context, added + removed > 0);
    final parts = <String>[
      if (added > 0) l10n.addToListsSheetAddedToLists(added),
      if (removed > 0) l10n.addToListsSheetRemovedFromLists(removed),
      if (failed > 0) l10n.addToListsSheetFailedCount(failed),
    ];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          parts.isEmpty ? l10n.addToListsSheetNoChanges : parts.join(' · '),
        ),
      ),
    );
  }

  /// Pre-fills the new list's name with the feed title (or URL host as
  /// fallback). If a list with that name already exists, appends `_1`,
  /// `_2`, ... until it's unique.
  String _candidateListName() {
    final base = (widget.feedTitle?.isNotEmpty ?? false)
        ? widget.feedTitle!
        : (_accountMode
            ? 'Following'
            : (Uri.tryParse(widget.feedUrl)?.host ?? widget.feedUrl));
    final taken = _lists.map((l) => l.name).toSet();
    if (!taken.contains(base)) return base;
    var i = 1;
    while (taken.contains('${base}_$i')) {
      i++;
    }
    return '${base}_$i';
  }

  Future<void> _createList() async {
    final l10n = context.l10n;
    final created = await showEditListSheet(
      context,
      defaultName: _candidateListName(),
    );
    if (created == null || !mounted) return;
    bool ok;
    if (_accountMode) {
      final session = PublicOS.sessionBlockchainAddress;
      if (session == null) {
        ok = false;
      } else {
        try {
          await PublicOS.database.followAccount(
            session: session,
            account: widget.accountAddress!,
            listId: created.id,
          );
          ok = true;
        } catch (_) {
          ok = false;
        }
      }
    } else {
      ok = await PublicOSFeedLists.addFeedToList(
        created.id,
        widget.feedUrl,
        widget.feedTitle,
        widget.feedDescription,
        feedFoundAtAccountAddress: widget.feedFoundAtAccountAddress,
        feedRecordKey: widget.feedRecordKey,
      );
    }
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      // Re-load so the new (empty) list still appears for manual toggle.
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addToListsSheetCreatedButFailedToAdd)),
      );
    }
  }

  /// Single-follow `+` action: create an is_single list named after the
  /// feed, add the feed, dismiss. No extra confirm.
  Future<void> _followAsSingle() async {
    final l10n = context.l10n;
    setState(() => _singlePending = true);
    final created = await PublicOSFeedLists.followFeedAsSingle(
      widget.feedUrl,
      feedTitle: widget.feedTitle,
      feedDescription: widget.feedDescription,
      feedFoundAtAccountAddress: widget.feedFoundAtAccountAddress,
      feedRecordKey: widget.feedRecordKey,
    );
    if (!mounted) return;
    if (created != null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _singlePending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addToListsSheetFailedToCreateSingle)),
      );
    }
  }

  /// Single-follow `x` action: confirm "Unfollow <feed>?" → cascade-delete
  /// the list (which CASCADEs to ListFeeds via FK).
  Future<void> _unfollowSingle() async {
    final single = _existingSingle;
    if (single == null) return;
    final l10n = context.l10n;
    final tokens = GlassTokens.of(context);
    final feedName = (widget.feedTitle?.isNotEmpty ?? false)
        ? widget.feedTitle!
        : single.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        title: Text(
          l10n.addToListsSheetUnfollowTitle(feedName),
          style: TextStyle(color: tokens.starkWhite),
        ),
        content: Text(
          l10n.addToListsSheetUnfollowBody,
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
              l10n.addToListsSheetUnfollowAction,
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
    setState(() => _singlePending = true);
    final ok = await PublicOSFeedLists.deleteList(single.id);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _singlePending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addToListsSheetFailedToUnfollow)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final subtitle = (widget.feedTitle?.isNotEmpty ?? false)
        ? widget.feedTitle!
        : (Uri.tryParse(widget.feedUrl)?.host ?? widget.feedUrl);
    // DESKTOP DELTA: fixed card, no drag handle, all corners rounded.
    return Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.addToListsSheetTitle,
                            style: TextStyle(
                              color: tokens.starkWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tokens.textDim,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: tokens.starkWhite),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(tokens.textDim),
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        children: [
                          // Accounts can never be singles — a single IS one
                          // feed rendered as itself, and an account is a set
                          // of channels. Feed mode only.
                          if (!_accountMode) ...[
                            _SectionLabel(
                              label: _existingSingle != null
                                  ? context
                                      .l10n.addToListsSheetSectionSingleFollow
                                  : context
                                      .l10n.addToListsSheetSectionFollowAsSingle,
                            ),
                            _SingleFollowRow(
                              feedUrl: widget.feedUrl,
                              feedTitle: widget.feedTitle,
                              foundAt: _foundAtContact,
                              existing: _existingSingle != null,
                              pending: _singlePending,
                              onTap: _singlePending
                                  ? null
                                  : (_existingSingle != null
                                      ? _unfollowSingle
                                      : _followAsSingle),
                            ),
                          ],
                          if (_lists.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _SectionLabel(
                                label: context.l10n.addToListsSheetSectionLists),
                            ..._lists.map((list) {
                              final checked = _selected[list.id] ?? false;
                              return _ListRow(
                                list: list,
                                feedCount: _feedCount[list.id] ?? 0,
                                summary: _summaries[list.id],
                                checked: checked,
                                enabled: !_saving,
                                onTap: () => setState(() {
                                  _selected[list.id] = !checked;
                                }),
                              );
                            }),
                          ],
                        ],
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
                    _CreateAndAddButton(
                      onTap: _saving ? null : _createList,
                    ),
                    if (!_loading && _lists.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _SaveButton(
                        enabled: _hasChanges && !_saving,
                        saving: _saving,
                        onPressed: _save,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Text(
        label,
        style: TextStyle(
          color: tokens.textDim,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

/// Single-follow row: feed icon + feed name + via line + +/x affordance.
/// Visual cousin of `_SingleListRow` in feeds_navigation_drawer.
class _SingleFollowRow extends StatelessWidget {
  final String feedUrl;
  final String? feedTitle;
  final Contact? foundAt;
  final bool existing;
  final bool pending;
  final VoidCallback? onTap;

  const _SingleFollowRow({
    required this.feedUrl,
    required this.feedTitle,
    required this.foundAt,
    required this.existing,
    required this.pending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final name = (feedTitle?.isNotEmpty ?? false)
        ? feedTitle!
        : (Uri.tryParse(feedUrl)?.host ?? feedUrl);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Center(
                child: FeedFavicon(feedUrl: feedUrl, size: 22),
              ),
            ),
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
                  if (foundAt != null) ...[
                    const SizedBox(height: 3),
                    _SheetViaLine(contact: foundAt!),
                  ],
                ],
              ),
            ),
            _Affordance(remove: existing, pending: pending),
          ],
        ),
      ),
    );
  }
}

class _Affordance extends StatelessWidget {
  final bool remove;
  final bool pending;
  const _Affordance({required this.remove, required this.pending});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final color = remove
        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.85)
        : tokens.connectedAccent;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: pending
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            )
          : Icon(
              remove ? Icons.close_rounded : Icons.add_rounded,
              size: 18,
              color: color,
            ),
    );
  }
}

class _SheetViaLine extends StatelessWidget {
  final Contact contact;
  const _SheetViaLine({required this.contact});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final hasProfile = contact.publicosAddress != null &&
        contact.publicosAddress!.eip55With0x !=
            '0x0000000000000000000000000000000000000000';
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.addToListsSheetVia,
            style: TextStyle(color: tokens.textDim, fontSize: 11)),
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

class _ListRow extends StatelessWidget {
  final FeedList list;
  final int feedCount;

  /// People + feeds the list follows; null while loading (the feed count
  /// shows meanwhile).
  final ListFollowSummary? summary;
  final bool checked;
  final bool enabled;
  final VoidCallback onTap;

  const _ListRow({
    required this.list,
    required this.feedCount,
    this.summary,
    required this.checked,
    required this.enabled,
    required this.onTap,
  });

  /// The header's mini stack, smaller, then the counts: the people this list
  /// follows and its feeds, as `[icons][count]`.
  Widget _subtitle(BuildContext context, GlassTokens tokens) {
    final s = summary;
    final style = TextStyle(color: tokens.textDim, fontSize: 12);
    if (s == null) {
      return Text(context.l10n.addToListsSheetFeedCount(feedCount),
          style: style);
    }
    if (s.isEmpty) return Text(context.l10n.listHeaderEmpty, style: style);
    final l10n = context.l10n;
    final counts = [
      if (s.people.isNotEmpty)
        '${s.people.length} ${l10n.listHeaderPeopleWord(s.people.length)}',
      if (s.feeds.isNotEmpty)
        '${s.feeds.length} ${l10n.listHeaderFeedsWord(s.feeds.length)}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          ListMiniStack(
            summary: s,
            tokens: tokens,
            scale: 0.7,
            onTap: () {
              if (enabled) onTap();
            },
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(counts,
                style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Center(
                child: list.icon != null && list.icon!.isNotEmpty
                    ? Text(list.icon!, style: const TextStyle(fontSize: 22))
                    : Icon(
                        Icons.list_alt_rounded,
                        size: 20,
                        color: tokens.starkWhite,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    style: TextStyle(
                      color: tokens.starkWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _subtitle(context, tokens),
                ],
              ),
            ),
            _CheckBox(checked: checked),
          ],
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  final bool checked;
  const _CheckBox({required this.checked});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? tokens.starkWhite : Colors.transparent,
        border: Border.all(
          color: checked ? tokens.starkWhite : tokens.borderMedium,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: checked
          ? Icon(
              Icons.check_rounded,
              size: 16,
              color: tokens.background,
            )
          : null,
    );
  }
}

class _CreateAndAddButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _CreateAndAddButton({required this.onTap});

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
                  Icons.playlist_add_rounded,
                  size: 18,
                  color: tokens.starkWhite,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.addToListsSheetCreateNewList,
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

class _SaveButton extends StatelessWidget {
  final bool enabled;
  final bool saving;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.enabled,
    required this.saving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: enabled ? tokens.surfaceElevated : tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: enabled ? tokens.borderMedium : tokens.borderSubtle,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(tokens.starkWhite),
                    ),
                  )
                : Text(
                    context.l10n.addToListsSheetSave,
                    style: TextStyle(
                      color: enabled ? tokens.starkWhite : tokens.textDim,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
