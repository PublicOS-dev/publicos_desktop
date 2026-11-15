import 'package:flutter/material.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_widget.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';

/// Pattern A glass-dark sheet listing every child org of a parent org.
///
/// Read-only — mutation surfaces (Release child / Govern child
/// via EXECUTE_ON_DESCENDANT) are not built here.
/// Renders an initial page of children passed in by the caller, then
/// lazy-paginates the rest via `PublicOSGovernance.getChildOrgs(...)`.
Future<void> showChildrenSheet(
  BuildContext context, {
  required Contact parent,
  required List<Contact> initialChildren,
  required int totalChildCount,
  bool canVote = false,
}) {
  return showGlassSheetDialog(
    context: context,
    width: DialogWidth.l,
    builder: (_) => _ChildrenSheet(
      parent: parent,
      initialChildren: initialChildren,
      totalChildCount: totalChildCount,
      canVote: canVote,
    ),
  );
}

class _ChildrenSheet extends StatefulWidget {
  final Contact parent;
  final List<Contact> initialChildren;
  final int totalChildCount;
  /// A member of the parent: may start the child-lock vote per row.
  final bool canVote;

  const _ChildrenSheet({
    required this.parent,
    required this.initialChildren,
    required this.totalChildCount,
    this.canVote = false,
  });

  @override
  State<_ChildrenSheet> createState() => _ChildrenSheetState();
}

class _ChildrenSheetState extends State<_ChildrenSheet> {
  static const int _pageSize = 25;

  late List<Contact> _children;
  bool _loadingMore = false;
  bool _exhausted = false;

  @override
  void initState() {
    super.initState();
    _children = List<Contact>.from(widget.initialChildren);
    _exhausted = _children.length >= widget.totalChildCount;
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _exhausted) return;
    if (widget.parent.publicosAddress == null) return;

    setState(() => _loadingMore = true);
    try {
      final next = await PublicOSGovernance.getChildOrgs(
        widget.parent.publicosAddress!,
        offset: _children.length,
        limit: _pageSize,
      );
      final resolved = <Contact>[];
      for (final addr in next) {
        try {
          final contact = await PublicOSContacts.searchContacts(addr.eip55With0x);
          resolved.add(contact ??
              Contact(
                publicosAddress: addr,
                displayName: _short(addr.eip55With0x),
              ));
        } catch (_) {
          resolved.add(Contact(
            publicosAddress: addr,
            displayName: _short(addr.eip55With0x),
          ));
        }
      }
      if (!mounted) return;
      setState(() {
        _children.addAll(resolved);
        _loadingMore = false;
        _exhausted = _children.length >= widget.totalChildCount || next.length < _pageSize;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  String _short(String addr) {
    if (addr.length < 10) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

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
                title: context.l10n.childrenSheetTitle,
                subtitle:
                    context.l10n.childrenSheetSubtitle(widget.totalChildCount),
                onClose: () => Navigator.pop(context),
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 120) {
                      _loadMore();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    itemCount: _children.length + (_loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      if (i >= _children.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: tokens.textDim,
                              ),
                            ),
                          ),
                        );
                      }
                      return _ChildRow(
                        key: ValueKey(_children[i].publicosAddress?.eip55With0x ?? i),
                        tokens: tokens,
                        contact: _children[i],
                        parentAddress: widget.parent.publicosAddress?.eip55With0x,
                        canVote: widget.canVote,
                        onVoteStarted: () {},
                      );
                    },
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

/// One child org. It also shows the child lock: a member of
/// the parent can start the SET_CHILD_LOCK vote (55) from the lock button; a
/// locked child takes no new children of its own (its current ones stay).
class _ChildRow extends StatefulWidget {
  final GlassTokens tokens;
  final Contact contact;
  final String? parentAddress;
  final bool canVote;
  final VoidCallback onVoteStarted;

  const _ChildRow({
    super.key,
    required this.tokens,
    required this.contact,
    required this.parentAddress,
    required this.canVote,
    required this.onVoteStarted,
  });

  @override
  State<_ChildRow> createState() => _ChildRowState();
}

class _ChildRowState extends State<_ChildRow> {
  bool? _locked;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final a = widget.contact.publicosAddress;
    if (a != null) {
      PublicOSGovernance.isChildLocked(a).then((v) {
        if (mounted) setState(() => _locked = v);
      });
    }
  }

  Future<void> _toggle() async {
    final child = widget.contact.publicosAddress;
    final parent = widget.parentAddress;
    final locked = _locked;
    if (child == null || parent == null || locked == null) return;
    final l10n = context.l10n;
    final name = widget.contact.displayName;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        title: Text(locked ? l10n.childrenSheetUnlockTitle : l10n.childrenSheetLockTitle),
        content: Text(locked ? l10n.childrenSheetUnlockBody(name) : l10n.childrenSheetLockBody(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.dlgCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.groupVotingViewStartVote)),
        ],
      ),
    );
    if (go != true || !mounted) return;
    setState(() => _busy = true);
    final ok = await PublicOSGovernance.startVoteSetChildLock(parent, child, !locked);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? l10n.groupVotingViewSettingVoteStarted
          : (PublicOS.lastError ?? l10n.groupVotingViewUnableToCastVote)),
    ));
    if (ok) widget.onVoteStarted();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final contact = widget.contact;
    final l10n = context.l10n;
    final addr = contact.publicosAddress?.eip55With0x ?? '';
    final addrShort = addr.length > 10
        ? '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}'
        : addr;
    final locked = _locked == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          GlassContactIcon(contact: contact, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.displayName,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  locked ? l10n.childrenSheetLocked : addrShort,
                  style: TextStyle(
                    fontFamily: locked ? 'SpaceGrotesk' : 'monospace',
                    color: locked ? tokens.fallbackAccent : tokens.textDim,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (_busy)
            const SizedBox(width: 40, height: 40, child: Center(child: PixelRainLoadingWidget(size: 20, showShadows: false)))
          else if (_locked != null && widget.canVote)
            IconButton(
              tooltip: locked ? l10n.childrenSheetUnlockTitle : l10n.childrenSheetLockTitle,
              icon: Icon(
                locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: 18,
                color: locked ? tokens.fallbackAccent : tokens.textDim,
              ),
              onPressed: _toggle,
            )
          else if (locked)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.lock_rounded, size: 18, color: tokens.fallbackAccent),
            ),
        ],
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
              Icons.account_tree_outlined,
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
