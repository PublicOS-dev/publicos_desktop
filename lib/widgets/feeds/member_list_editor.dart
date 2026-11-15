import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/account_resolve_field.dart';
import 'package:publicos_desktop/widgets/feeds/expiration_picker_field.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// One entry in a [MemberListEditor]. The address is the identity; everything
/// else is presentation. `note` renders as a dim secondary line (ban reason),
/// `expiresAt` as the standard expiration chip.
///
/// [isOrg] marks a row that names an ORG rather than a person, which admits
/// every current member of that org. It is DISPLAY ONLY and additive — the
/// server decides it when the row is created (the owner just pastes or resolves
/// an address) and the row keeps its normal rhythm, gaining only a badge.
class MemberEntry {
  final String address;
  final String? note;
  final DateTime? expiresAt;
  final bool isOrg;

  const MemberEntry({
    required this.address,
    this.note,
    this.expiresAt,
    this.isOrg = false,
  });
}

/// The ONE list component: every list
/// in channel settings is managed the same way — a search bar, contact rows
/// (avatar · display name · shortened address), an action per row, and at
/// most ~8 rows tall before it scrolls.
///
/// Two modes, chosen by which callbacks are wired:
///   - **Add/remove** ([onAdd] + [onRemove]): the search bar resolves a
///     display name from local contacts + chain, or passes a raw `0x` address
///     through untouched — a hand-listed bare wallet is a first-class member
///     (the wallet door). Rows carry Remove.
///   - **Tick pool** ([ticked] + [onTick]): the rows are a fixed pool (the
///     read audience) and the action is a checkbox — ticked members are on
///     the target list. The search bar filters the pool instead of adding;
///     the component keeps its shape, the search just changes job.
class MemberListEditor extends StatefulWidget {
  final List<MemberEntry> entries;

  /// Lowercased addresses with an operation in flight — their row action
  /// shows a spinner instead of Remove / the tick.
  final Set<String> busy;

  final String searchHint;
  final String emptyLabel;

  final Future<void> Function(String address)? onAdd;
  final Future<void> Function(String address)? onRemove;

  /// Non-null switches the component to tick-pool mode.
  final Set<String>? ticked;
  final Future<void> Function(String address, bool ticked)? onTick;

  const MemberListEditor({
    super.key,
    required this.entries,
    required this.busy,
    required this.searchHint,
    required this.emptyLabel,
    this.onAdd,
    this.onRemove,
    this.ticked,
    this.onTick,
  });

  @override
  State<MemberListEditor> createState() => _MemberListEditorState();
}

class _MemberListEditorState extends State<MemberListEditor> {
  final _searchCtrl = TextEditingController();
  bool _adding = false;

  bool get _tickMode => widget.ticked != null;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAdd() async {
    final onAdd = widget.onAdd;
    if (onAdd == null || _adding) return;
    final raw = _searchCtrl.text.trim();
    if (raw.length < 2) return;
    setState(() => _adding = true);
    // Username → account address; raw 0x input passes through untouched
    // (the whitelist endpoints never validate that an address is an account).
    final resolved = await resolveAccountInput(raw);
    if (!mounted) return;
    if (resolved == null) {
      setState(() => _adding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accountResolveNoMatch)),
      );
      return;
    }
    await onAdd(resolved);
    if (!mounted) return;
    _searchCtrl.clear();
    setState(() => _adding = false);
  }

  List<MemberEntry> get _visibleEntries {
    if (!_tickMode) return widget.entries;
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return widget.entries;
    return widget.entries
        .where((e) => e.address.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final entries = _visibleEntries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: _tickMode
              ? _FilterField(controller: _searchCtrl, hint: widget.searchHint)
              : Row(
                  children: [
                    Expanded(
                      child: AccountResolveField(
                        controller: _searchCtrl,
                        hint: widget.searchHint,
                        dense: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _AddButton(
                      enabled: _searchCtrl.text.trim().length >= 2 && !_adding,
                      loading: _adding,
                      onPressed: _submitAdd,
                    ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 320),
            decoration: BoxDecoration(
              border: Border.all(color: tokens.borderSubtle),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: entries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    child: Text(
                      widget.emptyLabel,
                      style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: tokens.borderSubtle,
                    ),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      final lower = e.address.toLowerCase();
                      return MemberRow(
                        entry: e,
                        busy: widget.busy.contains(lower),
                        ticked: _tickMode
                            ? widget.ticked!.contains(lower)
                            : null,
                        onTick: _tickMode
                            ? (v) => widget.onTick?.call(e.address, v)
                            : null,
                        onRemove: !_tickMode && widget.onRemove != null
                            ? () => widget.onRemove!(e.address)
                            : null,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

/// Plain filter field for tick-pool mode — same visual shell as the resolve
/// field but with no overlay panel: the pool is already on screen, typing
/// just narrows it.
class _FilterField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _FilterField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return TextField(
      controller: controller,
      maxLines: 1,
      style: TextStyle(
        color: tokens.starkWhite,
        fontSize: 12,
        fontFamily: 'monospace',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: tokens.textDim,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
        prefixIcon: Icon(Icons.search_rounded, size: 16, color: tokens.textDim),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 34, minHeight: 34),
        filled: true,
        fillColor: tokens.surfaceElevated,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderMedium, width: 1.5),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  const _AddButton({
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: enabled ? tokens.surfaceElevated : tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: enabled ? tokens.borderMedium : tokens.borderSubtle,
        ),
      ),
      child: InkWell(
        onTap: enabled && !loading ? onPressed : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: loading
              ? const SizedBox(
                  width: 13,
                  height: 13,
                  child: PhigitalLoadingWidget(size: 13, showShadows: false),
                )
              : Text(
                  context.l10n.chsAdd,
                  style: TextStyle(
                    color: enabled ? tokens.starkWhite : tokens.textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
        ),
      ),
    );
  }
}

/// One contact row: avatar · display name · shortened address, plus the
/// per-mode action. Resolves the address to a local/chain contact for the
/// name + avatar; an unresolved address renders as its shortened hex — the
/// hand-listed bare wallet case.
class MemberRow extends StatefulWidget {
  final MemberEntry entry;
  final bool busy;
  final bool? ticked;
  final ValueChanged<bool>? onTick;
  final VoidCallback? onRemove;

  const MemberRow({
    super.key,
    required this.entry,
    required this.busy,
    this.ticked,
    this.onTick,
    this.onRemove,
  });

  @override
  State<MemberRow> createState() => _MemberRowState();
}

class _MemberRowState extends State<MemberRow> {
  Contact? _contact;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final c = await lookupMemberContact(widget.entry.address);
    if (!mounted || c == null) return;
    setState(() => _contact = c);
  }

  void _openProfile() {
    final c = _contact;
    if (c != null) {
      AppNav.toContact(context, c);
    } else {
      AppNav.toProfile(context, widget.entry.address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final address = widget.entry.address;
    final short = shortMemberAddress(address);
    final displayName = _contact?.displayName;
    final hasName = displayName != null && displayName.isNotEmpty;

    Widget action;
    if (widget.busy) {
      action = const SizedBox(
        width: 14,
        height: 14,
        child: PhigitalLoadingWidget(size: 14, showShadows: false),
      );
    } else if (widget.ticked != null) {
      action = _TickBox(
        on: widget.ticked!,
        onTap: () => widget.onTick?.call(!widget.ticked!),
      );
    } else if (widget.onRemove != null) {
      action = InkWell(
        onTap: widget.onRemove,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            context.l10n.chsRemove,
            style: TextStyle(
              color: tokens.fallbackAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    } else {
      action = const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      child: Row(
        children: [
          GlassContactIcon(
            contact: _contact,
            address: address,
            size: 28,
            onTap: _openProfile,
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
                        hasName ? displayName : short,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.starkWhite,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: hasName ? null : 'monospace',
                        ),
                      ),
                    ),
                    if (widget.entry.isOrg) ...[
                      const SizedBox(width: 6),
                      _OrgBadge(tokens: tokens),
                    ],
                  ],
                ),
                if (hasName)
                  Text(
                    short,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                if (widget.entry.note != null &&
                    widget.entry.note!.isNotEmpty)
                  Text(
                    widget.entry.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                if (widget.entry.expiresAt != null) ...[
                  const SizedBox(height: 3),
                  ExpirationChip(value: widget.entry.expiresAt!),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          action,
        ],
      ),
    );
  }
}

class _TickBox extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;

  const _TickBox({required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final accent = tokens.connectedAccent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: on ? accent : tokens.borderMedium,
            width: 1.5,
          ),
          color: on ? accent.withValues(alpha: 0.18) : null,
        ),
        child: on
            ? Icon(Icons.check_rounded, size: 13, color: accent)
            : null,
      ),
    );
  }
}

String shortMemberAddress(String address) => address.length > 14
    ? '${address.substring(0, 8)}…${address.substring(address.length - 4)}'
    : address;

/// Address → contact, local first then chain, persisting a chain hit so the
/// next row render is instant. Same helper the manage page used.
Future<Contact?> lookupMemberContact(String address) async {
  try {
    var c = await PublicOSContacts.searchContacts(address);
    if (c == null) {
      c = await PublicOSContacts.resolveByIdentifier(address);
      if (c != null) await PublicOSContacts.saveContact(c);
    }
    return c;
  } catch (_) {
    return null;
  }
}

/// The ORG marker on a member row.
///
/// Additive by design: the row keeps its avatar, name and action exactly as a
/// person's row has them, and gains one small pill. An org row admits every
/// current member of that org, so the owner is curating ORGS here while the org
/// curates its own members — the badge is what makes that visible without
/// giving org rows a different shape.
class _OrgBadge extends StatelessWidget {
  const _OrgBadge({required this.tokens});

  final GlassTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: tokens.connectedAccent.withValues(alpha: 0.12),
        border: Border.all(
          color: tokens.connectedAccent.withValues(alpha: 0.40),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'ORG',
        style: TextStyle(
          color: tokens.connectedAccent,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
