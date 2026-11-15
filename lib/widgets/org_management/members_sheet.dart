import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';

/// Pattern A glass-dark sheet showing every member of an org with a remove
/// affordance per row. Bottom-pinned action opens the Add Member flow.
///
/// Pops a `_MembersResult` with the addresses the caller should act on:
///   - [addressesToRemove] — addresses tapped for remove (vote start handled
///     by caller; this sheet just collects intent)
///   - [requestAdd] — true if the caller should open its Add Member flow
///
/// Caller wires the contract calls so the sheet stays read-only beyond
/// data display + intent capture.
class MembersSheetResult {
  final List<EthereumAddress> addressesToRemove;
  final bool requestAdd;
  const MembersSheetResult({
    this.addressesToRemove = const [],
    this.requestAdd = false,
  });
}

/// Read-only reuse (a channel header's Writers): `canMutate:
/// false` hides remove + add; [title] / [subtitle] replace the Members copy;
/// [onMemberTap] makes each row tappable (the sheet does NOT pop itself —
/// the callback decides).
Future<MembersSheetResult?> showMembersSheet(
  BuildContext context, {
  required List<Contact> members,
  required bool canMutate,
  String? title,
  String? subtitle,
  ValueChanged<Contact>? onMemberTap,
}) {
  return showGlassSheetDialog<MembersSheetResult>(
    context: context,
    width: DialogWidth.l,
    builder: (_) => _MembersSheet(
      members: members,
      canMutate: canMutate,
      title: title,
      subtitle: subtitle,
      onMemberTap: onMemberTap,
    ),
  );
}

class _MembersSheet extends StatefulWidget {
  final List<Contact> members;
  final bool canMutate;
  final String? title;
  final String? subtitle;
  final ValueChanged<Contact>? onMemberTap;

  const _MembersSheet({
    required this.members,
    required this.canMutate,
    this.title,
    this.subtitle,
    this.onMemberTap,
  });

  @override
  State<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends State<_MembersSheet> {
  final List<EthereumAddress> _pendingRemove = [];

  Future<void> _requestRemove(Contact contact) async {
    if (contact.publicosAddress == null) return;
    if (widget.members.length <= 1) return;

    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        title: Text(
          l10n.membersSheetRemoveTitle,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          l10n.membersSheetRemoveBody(contact.displayName),
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.dlgCancel, style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.membersSheetRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _pendingRemove.add(contact.publicosAddress!));
    if (mounted) {
      Navigator.of(context).pop(
        MembersSheetResult(addressesToRemove: List.of(_pendingRemove)),
      );
    }
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
                title: widget.title ?? l10n.membersSheetTitle,
                subtitle: widget.subtitle ??
                    l10n.membersSheetCount(widget.members.length),
                onClose: () => Navigator.pop(context),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  itemCount: widget.members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _MemberRow(
                    tokens: tokens,
                    contact: widget.members[i],
                    canRemove:
                        widget.canMutate && widget.members.length > 1,
                    onRemove: () => _requestRemove(widget.members[i]),
                    onTap: widget.onMemberTap == null
                        ? null
                        : () => widget.onMemberTap!(widget.members[i]),
                  ),
                ),
              ),
              if (widget.canMutate) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: tokens.borderSubtle, height: 1),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: SystemAppActionButton(
                      label: l10n.membersSheetAddMember,
                      icon: Icons.person_add_alt_rounded,
                      onTap: () => Navigator.pop(
                        context,
                        const MembersSheetResult(requestAdd: true),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MemberRow extends StatelessWidget {
  final GlassTokens tokens;
  final Contact contact;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  const _MemberRow({
    required this.tokens,
    required this.contact,
    required this.canRemove,
    required this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final err = Theme.of(context).colorScheme.error;
    final addr = contact.publicosAddress?.eip55With0x ?? '';
    final addrShort = addr.length > 10
        ? '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}'
        : addr;

    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSubtle),
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
                  addrShort,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: tokens.textDim,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (canRemove)
            InkResponse(
              onTap: onRemove,
              radius: 22,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.person_remove_alt_1_rounded,
                  color: err,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: row,
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
              Icons.people_outline_rounded,
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
