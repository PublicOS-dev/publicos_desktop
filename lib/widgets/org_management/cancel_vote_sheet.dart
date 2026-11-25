import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_widget.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';

/// What the picker returns — the open vote to cancel and the org it belongs
/// to (this org or a real descendant).
class CancelVotePick {
  final ActiveVoteInfo vote;
  final Contact owner;
  const CancelVotePick(this.vote, this.owner);
}

/// Pattern A glass sheet: pick an open vote of [org] or of any org under it,
/// for a CANCEL_VOTE (58) proposal. Navigational, never a tree fetch:
/// the current org's own votes, then its DIRECT children
/// (paged); a child expands to its open votes, and a left swipe (or the arrow)
/// goes into that child's children. Open-vote counts show only when a row has
/// at most 5 children. The search box resolves a name and checks it is in the
/// tree with one `isAncestorOf` call (no root shortcut).
Future<CancelVotePick?> showCancelVotePickerSheet(
  BuildContext context, {
  required Contact org,
}) {
  // DESKTOP DELTA: hosted as a glass dialog, like children_sheet.dart.
  return showGlassSheetDialog<CancelVotePick>(
    context: context,
    width: DialogWidth.l,
    builder: (_) => _CancelVoteSheet(org: org),
  );
}

/// The reason dialog shared by withdraw, veto and the cancel vote: required,
/// at most 500 UTF-8 bytes (the contract's bound). Null when dismissed.
Future<String?> askCancelReason(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  bool destructive = false,
}) {
  final l10n = context.l10n;
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        final bytes = utf8.encode(ctrl.text.trim()).length;
        final ok = PublicOSGovernance.cancelReasonError(ctrl.text.trim()) == null;
        // The standard glass dialog, with the dense-form field.
        final t = GlassTokens.of(ctx);
        final err = Theme.of(ctx).colorScheme.error;
        OutlineInputBorder edge(Color c, double w) => OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c, width: w),
            );
        return AlertDialog(
          constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
          backgroundColor: t.surfaceDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: t.borderSubtle),
          ),
          title: Text(
            title,
            style: TextStyle(fontFamily: 'SpaceGrotesk', color: t.starkWhite, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                body,
                style: TextStyle(fontFamily: 'SpaceGrotesk', color: t.textDim, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                minLines: 2,
                maxLines: 5,
                style: TextStyle(fontFamily: 'SpaceGrotesk', color: t.starkWhite, fontSize: 15),
                decoration: InputDecoration(
                  hintText: l10n.groupVotingViewCancelReasonHint,
                  filled: true,
                  fillColor: t.surfaceElevated,
                  hintStyle: TextStyle(fontFamily: 'SpaceGrotesk', color: t.textDim),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: edge(t.borderSubtle, 1),
                  enabledBorder: edge(t.borderSubtle, 1),
                  focusedBorder: edge(t.borderMedium, 1.5),
                ),
                onChanged: (_) => setLocal(() {}),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$bytes/${PublicOSGovernance.maxCancelReasonBytes}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: bytes > PublicOSGovernance.maxCancelReasonBytes ? err : t.textDim,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.dlgCancel, style: TextStyle(fontFamily: 'SpaceGrotesk', color: t.textDim)),
            ),
            TextButton(
              onPressed: ok ? () => Navigator.pop(ctx, ctrl.text.trim()) : null,
              style: destructive ? TextButton.styleFrom(foregroundColor: err) : null,
              child: Text(confirm),
            ),
          ],
        );
      },
    ),
  ).whenComplete(ctrl.dispose);
}

/// One level of the navigation: an org, its own open votes, its direct children.
class _Level {
  final Contact org;
  List<ActiveVoteInfo>? votes;
  List<Contact> children = [];
  int childCount = 0;
  bool exhausted = false;
  bool loadingMore = false;
  /// Open-vote counts per child, read only when [childCount] <= 5.
  final Map<String, int> counts = {};
  _Level(this.org);
}

class _CancelVoteSheet extends StatefulWidget {
  final Contact org;
  const _CancelVoteSheet({required this.org});

  @override
  State<_CancelVoteSheet> createState() => _CancelVoteSheetState();
}

enum _SearchState { idle, checking, notFound, notInTree, found }

class _CancelVoteSheetState extends State<_CancelVoteSheet> {
  static const int _pageSize = 20;
  /// The "count if no more than 5 children" rule.
  static const int _countLimit = 5;

  final List<_Level> _path = [];
  bool _forward = true;

  // Child rows expanded to their votes, and those votes (lazy, by address).
  final Set<String> _expanded = {};
  final Map<String, List<ActiveVoteInfo>> _childVotes = {};

  final TextEditingController _search = TextEditingController();
  _SearchState _searchState = _SearchState.idle;
  Contact? _found;
  List<ActiveVoteInfo>? _foundVotes;
  String _searched = '';

  @override
  void initState() {
    super.initState();
    _enter(widget.org);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _addr(Contact c) => c.publicosAddress?.eip55With0x ?? '';

  Future<Contact> _contact(EthereumAddress a) async {
    try {
      final c = await PublicOSContacts.searchContacts(a.eip55With0x);
      if (c != null) return c;
    } catch (_) {}
    final h = a.eip55With0x;
    return Contact(publicosAddress: a, displayName: '${h.substring(0, 6)}...${h.substring(h.length - 4)}');
  }

  /// Open votes that can still be cancelled (the contract refuses an expired one).
  Future<List<ActiveVoteInfo>> _openVotes(String org) async {
    final all = await PublicOSGovernance.getOpenVotes(org);
    return all.where((v) => !v.closable).toList();
  }

  Future<void> _enter(Contact org, {bool forward = true}) async {
    final level = _Level(org);
    setState(() {
      _forward = forward;
      _path.add(level);
    });
    final a = org.publicosAddress;
    if (a == null) return;
    final results = await Future.wait<Object?>([
      _openVotes(a.eip55With0x),
      PublicOSGovernance.getChildOrgCount(a),
      PublicOSGovernance.getChildOrgs(a, offset: 0, limit: _pageSize),
    ]);
    final votes = results[0] as List<ActiveVoteInfo>;
    final count = results[1] as int;
    final addrs = results[2] as List<EthereumAddress>;
    final children = await Future.wait(addrs.map(_contact));
    if (!mounted) return;
    setState(() {
      level.votes = votes;
      level.childCount = count;
      level.children = children;
      level.exhausted = children.length >= count || addrs.length < _pageSize;
    });
    if (count > 0 && count <= _countLimit) {
      for (final c in children) {
        final ca = _addr(c);
        _openVotes(ca).then((v) {
          if (!mounted) return;
          setState(() {
            level.counts[ca] = v.length;
            _childVotes[ca] = v;
          });
        });
      }
    }
  }

  Future<void> _more(_Level level) async {
    final a = level.org.publicosAddress;
    if (a == null || level.loadingMore || level.exhausted) return;
    setState(() => level.loadingMore = true);
    final addrs = await PublicOSGovernance.getChildOrgs(a, offset: level.children.length, limit: _pageSize);
    final more = await Future.wait(addrs.map(_contact));
    if (!mounted) return;
    setState(() {
      level.children.addAll(more);
      level.loadingMore = false;
      level.exhausted = level.children.length >= level.childCount || addrs.length < _pageSize;
    });
  }

  void _back() {
    if (_path.length <= 1) return;
    HapticFeedback.selectionClick();
    setState(() {
      _forward = false;
      _path.removeLast();
    });
  }

  void _drill(Contact child) {
    HapticFeedback.selectionClick();
    _enter(child);
  }

  Future<void> _toggle(Contact child) async {
    final a = _addr(child);
    setState(() {
      if (!_expanded.remove(a)) _expanded.add(a);
    });
    if (_expanded.contains(a) && !_childVotes.containsKey(a)) {
      final v = await _openVotes(a);
      if (mounted) setState(() => _childVotes[a] = v);
    }
  }

  Future<void> _runSearch(String text) async {
    final q = text.trim();
    if (q.isEmpty) {
      setState(() => _searchState = _SearchState.idle);
      return;
    }
    setState(() {
      _searched = q;
      _searchState = _SearchState.checking;
      _found = null;
      _foundVotes = null;
    });
    final c = await PublicOSContacts.resolveByIdentifier(q);
    if (!mounted || _searched != q) return;
    if (c == null || c.publicosAddress == null || !c.isOrgAccount) {
      setState(() => _searchState = _SearchState.notFound);
      return;
    }
    final root = widget.org.publicosAddress!;
    final inTree = c.publicosAddress == root ||
        await PublicOSGovernance.isAncestorOf(root, c.publicosAddress!);
    if (!mounted || _searched != q) return;
    if (!inTree) {
      setState(() {
        _found = c;
        _searchState = _SearchState.notInTree;
      });
      return;
    }
    final votes = await _openVotes(_addr(c));
    if (!mounted || _searched != q) return;
    setState(() {
      _found = c;
      _foundVotes = votes;
      _searchState = _SearchState.found;
    });
  }

  void _pick(ActiveVoteInfo v, Contact owner) {
    HapticFeedback.lightImpact();
    Navigator.pop(context, CancelVotePick(v, owner));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 1.0,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8), // DESKTOP DELTA: a dialog has no drag handle
            _Header(
              tokens: tokens,
              title: l10n.cancelVoteSheetTitle,
              subtitle: l10n.cancelVoteSheetSubtitle,
              onClose: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: _runSearch,
                onChanged: (t) {
                  if (t.trim().isEmpty && _searchState != _SearchState.idle) {
                    setState(() => _searchState = _SearchState.idle);
                  }
                },
                style: TextStyle(fontFamily: 'SpaceGrotesk', color: tokens.starkWhite, fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.cancelVoteSheetSearchHint,
                  hintStyle: TextStyle(color: tokens.textDim),
                  prefixIcon: Icon(Icons.search_rounded, color: tokens.textDim, size: 18),
                  suffixIcon: _searchState == _SearchState.idle
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close_rounded, color: tokens.textDim, size: 18),
                          onPressed: () {
                            _search.clear();
                            setState(() => _searchState = _SearchState.idle);
                          },
                        ),
                  filled: true,
                  fillColor: tokens.glassFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _searchState == _SearchState.idle
                  ? _navigation(tokens, scrollCtrl)
                  : _searchResult(tokens, scrollCtrl),
            ),
          ],
        ),
      ),
    );
  }

  // ── Navigation ──────────────────────────────────────────────────────────

  Widget _navigation(GlassTokens tokens, ScrollController scrollCtrl) {
    final level = _path.last;
    return Column(
      children: [
        _Breadcrumb(
          tokens: tokens,
          names: [for (final l in _path) l.org.displayName],
          onBack: _path.length > 1 ? _back : null,
        ),
        Expanded(
          child: GestureDetector(
            // A right swipe anywhere on the page goes back up one level.
            onHorizontalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) > 300) _back();
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(_forward ? 1 : -1, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
              child: KeyedSubtree(
                key: ValueKey('level-${_path.length}-${_addr(level.org)}'),
                child: _levelList(tokens, level, scrollCtrl),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _levelList(GlassTokens tokens, _Level level, ScrollController scrollCtrl) {
    final l10n = context.l10n;
    final votes = level.votes;
    if (votes == null) {
      return const Center(child: PixelRainLoadingWidget(size: 24, showShadows: false));
    }
    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        _Label(tokens: tokens, text: l10n.cancelVoteSheetOpenVotes),
        if (votes.isEmpty)
          _Empty(tokens: tokens, text: l10n.cancelVoteSheetNoVotes)
        else
          for (final v in votes) _VoteRow(tokens: tokens, vote: v, onTap: () => _pick(v, level.org)),
        const SizedBox(height: 12),
        _Label(tokens: tokens, text: l10n.cancelVoteSheetChildren),
        if (level.children.isEmpty)
          _Empty(tokens: tokens, text: l10n.cancelVoteSheetNoChildren)
        else
          for (final c in level.children) ...[
            _ChildRow(
              tokens: tokens,
              contact: c,
              count: level.counts[_addr(c)],
              expanded: _expanded.contains(_addr(c)),
              onToggle: () => _toggle(c),
              onDrill: () => _drill(c),
            ),
            if (_expanded.contains(_addr(c)))
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 4),
                child: switch (_childVotes[_addr(c)]) {
                  null => const Padding(
                      padding: EdgeInsets.all(8),
                      child: PixelRainLoadingWidget(size: 18, showShadows: false),
                    ),
                  final vs when vs.isEmpty => _Empty(tokens: tokens, text: l10n.cancelVoteSheetNoVotes),
                  final vs => Column(
                      children: [
                        for (final v in vs) _VoteRow(tokens: tokens, vote: v, onTap: () => _pick(v, c)),
                      ],
                    ),
                },
              ),
            const SizedBox(height: 6),
          ],
        if (!level.exhausted && level.children.isNotEmpty)
          Center(
            child: level.loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: PixelRainLoadingWidget(size: 18, showShadows: false),
                  )
                : TextButton(
                    onPressed: () => _more(level),
                    child: Text(l10n.cancelVoteSheetShowMore, style: TextStyle(color: tokens.textDim)),
                  ),
          ),
      ],
    );
  }

  // ── Search ──────────────────────────────────────────────────────────────

  Widget _searchResult(GlassTokens tokens, ScrollController scrollCtrl) {
    final l10n = context.l10n;
    final found = _found;
    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        switch (_searchState) {
          _SearchState.checking => Row(
              children: [
                const PixelRainLoadingWidget(size: 18, showShadows: false),
                const SizedBox(width: 10),
                Text(l10n.cancelVoteSheetChecking, style: TextStyle(fontFamily: 'SpaceGrotesk', color: tokens.textDim)),
              ],
            ),
          _SearchState.notFound => _Empty(tokens: tokens, text: l10n.cancelVoteSheetNotFound(_searched)),
          _SearchState.notInTree => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (found != null) _OrgLine(tokens: tokens, contact: found, dim: true),
                _Empty(tokens: tokens, text: l10n.cancelVoteSheetNotInTree),
              ],
            ),
          _SearchState.found => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (found != null) _OrgLine(tokens: tokens, contact: found),
                const SizedBox(height: 8),
                _Label(tokens: tokens, text: l10n.cancelVoteSheetOpenVotes),
                if ((_foundVotes ?? const []).isEmpty)
                  _Empty(tokens: tokens, text: l10n.cancelVoteSheetNoVotes)
                else
                  for (final v in _foundVotes!) _VoteRow(tokens: tokens, vote: v, onTap: () => _pick(v, found!)),
              ],
            ),
          _SearchState.idle => const SizedBox.shrink(),
        },
      ],
    );
  }
}

/// `[<- …/suborg2/suborg3]`: the path faded to the left,
/// only the last two names in full.
class _Breadcrumb extends StatelessWidget {
  final GlassTokens tokens;
  final List<String> names;
  final VoidCallback? onBack;
  const _Breadcrumb({required this.tokens, required this.names, this.onBack});

  @override
  Widget build(BuildContext context) {
    final truncated = names.length > 2;
    final shown = truncated ? names.sublist(names.length - 2) : names;
    final text = '${truncated ? '…/' : ''}${shown.join('/')}';
    final style = TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 13, fontWeight: FontWeight.w700, color: tokens.starkWhite);
    Widget label = Text(text, style: style, maxLines: 1, softWrap: false, overflow: TextOverflow.visible, textAlign: TextAlign.right);
    if (truncated) {
      label = ShaderMask(
        shaderCallback: (r) => const LinearGradient(
          colors: [Colors.transparent, Colors.white],
          stops: [0.0, 0.3],
        ).createShader(r),
        blendMode: BlendMode.dstIn,
        child: label,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, size: 18, color: onBack == null ? tokens.borderMedium : tokens.starkWhite),
            onPressed: onBack,
          ),
          Expanded(
            child: ClipRect(
              child: Align(alignment: Alignment.centerRight, child: label),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildRow extends StatelessWidget {
  final GlassTokens tokens;
  final Contact contact;
  final int? count;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onDrill;
  const _ChildRow({
    required this.tokens,
    required this.contact,
    required this.count,
    required this.expanded,
    required this.onToggle,
    required this.onDrill,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // A left swipe on a child goes into its children.
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < -300) onDrill();
      },
      child: Material(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                GlassContactIcon(contact: contact, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    contact.displayName,
                    style: TextStyle(fontFamily: 'SpaceGrotesk', color: tokens.starkWhite, fontSize: 13, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (count != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: count! > 0 ? tokens.fallbackAccent.withValues(alpha: 0.18) : tokens.glassFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: count! > 0 ? tokens.fallbackAccent : tokens.textDim),
                    ),
                  ),
                Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: tokens.textDim, size: 20),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.chevron_right_rounded, color: tokens.starkWhite, size: 20),
                  onPressed: onDrill,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoteRow extends StatelessWidget {
  final GlassTokens tokens;
  final ActiveVoteInfo vote;
  final VoidCallback onTap;
  const _VoteRow({required this.tokens, required this.vote, required this.onTap});

  static String _pretty(String camel) => camel
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceFirstMapped(RegExp(r'^[a-z]'), (m) => m[0]!.toUpperCase());

  @override
  Widget build(BuildContext context) {
    final left = vote.timeRemaining;
    final when = left == Duration.zero
        ? ''
        : left.inHours >= 1
            ? '${left.inHours}h ${left.inMinutes % 60}m'
            : '${left.inMinutes}m';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.how_to_vote_outlined, size: 16, color: tokens.fallbackAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '#${vote.proposalId} · ${_pretty(vote.actionType.name)}',
                    style: TextStyle(fontFamily: 'SpaceGrotesk', color: tokens.starkWhite, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (when.isNotEmpty)
                  Text(when, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: tokens.textDim)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrgLine extends StatelessWidget {
  final GlassTokens tokens;
  final Contact contact;
  final bool dim;
  const _OrgLine({required this.tokens, required this.contact, this.dim = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Opacity(opacity: dim ? 0.5 : 1, child: GlassContactIcon(opensProfile: true, contact: contact, size: 32)),
            const SizedBox(width: 10),
            Expanded(
              child: ContactProfileTap(contact: contact, child: Text(
                contact.displayName,
                style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 14, fontWeight: FontWeight.w700, color: dim ? tokens.textDim : tokens.starkWhite),
              )),
            ),
          ],
        ),
      );
}

class _Label extends StatelessWidget {
  final GlassTokens tokens;
  final String text;
  const _Label({required this.tokens, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
        child: Text(
          text,
          style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: tokens.textDim),
        ),
      );
}

class _Empty extends StatelessWidget {
  final GlassTokens tokens;
  final String text;
  const _Empty({required this.tokens, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Text(text, style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 12, color: tokens.textDim)),
      );
}

class _Header extends StatelessWidget {
  final GlassTokens tokens;
  final String title;
  final String subtitle;
  final VoidCallback onClose;
  const _Header({required this.tokens, required this.title, required this.subtitle, required this.onClose});

  @override
  Widget build(BuildContext context) => Padding(
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
              child: Icon(Icons.block_rounded, color: tokens.softDanger, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontFamily: 'SpaceGrotesk', color: tokens.starkWhite, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                  Text(subtitle, style: TextStyle(fontFamily: 'SpaceGrotesk', color: tokens.textDim, fontSize: 11)),
                ],
              ),
            ),
            IconButton(icon: Icon(Icons.close_rounded, color: tokens.starkWhite), onPressed: onClose),
          ],
        ),
      );
}
