import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/account_resolve_field.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/feeds/expiration_picker_field.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/screens/channel_settings_page.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/write_error_dispatcher.dart';

/// RETIRED: replaced by ChannelSettingsPage — no dispatch site pushes this
/// page. Delete on next touch.
///
/// Full-screen channel moderation page. 4 tabs — Posters / Bans / Whitelist /
/// Requests — plus an overflow menu with Edit channel + Copy {JSON/RSS/Atom}
/// URL + Delete channel.
///
/// Design notes:
///   - No moderation repository — every tab calls Core directly via
///     setState, same pattern as the rest of the client glass port.
///   - Edit pushes `CreateChannelPage(existing:)` via `Navigator.push` (not a
///     go_router `/channel/edit` route), awaits the returned Channel, and
///     refreshes the in-page state so the title + overflow export URLs
///     reflect the new slug/name immediately.
///   - Delete pops back to the caller with `true` so `feeds_view.dart` can
///     drop the selected channel + reload its list.
class ManageChannelPage extends StatefulWidget {
  final Channel channel;

  const ManageChannelPage({super.key, required this.channel});

  @override
  State<ManageChannelPage> createState() => _ManageChannelPageState();
}

class _ManageChannelPageState extends State<ManageChannelPage> {
  late Channel _channel = widget.channel;
  bool _isDeleting = false;

  String get _slug => _channel.slug;
  String? get _serverAddress => _channel.serverAddress;
  String get _ownerAddress =>
      _channel.ownerAddress ?? PublicOS.myPublicosAddress ?? '';

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: tokens.background,
        appBar: AppBar(
          backgroundColor: tokens.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: tokens.starkWhite),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  _channel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                context.l10n.manageChannelPageManageLabel,
                style: TextStyle(
                  color: tokens.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          actions: [
            _OverflowMenu(
              onEdit: _onEditChannel,
              onCopyJson: () => _copyExport('json', 'JSON Feed'),
              onCopyRss: () => _copyExport('rss', 'RSS'),
              onCopyAtom: () => _copyExport('atom', 'Atom'),
              onDelete: _isDeleting ? null : _onDeleteChannel,
            ),
            const SizedBox(width: 4),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(44),
            child: _ModTabs(),
          ),
        ),
        body: TabBarView(
          // Key each tab by slug so a channel rename forces a re-mount +
          // re-fetch against the new endpoint. Config-only edits (policy,
          // privacy toggles, verified gates) don't remount — the banner
          // just recomputes from the new `channel` prop on rebuild.
          children: [
            _PostersTab(
              key: ValueKey('posters:$_slug'),
              channel: _channel,
              onEditChannel: _onEditChannel,
            ),
            _BansTab(
              key: ValueKey('bans:$_slug'),
              channel: _channel,
            ),
            _ReadAccessTab(
              key: ValueKey('read:$_slug'),
              channel: _channel,
              onEditChannel: _onEditChannel,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Edit
  // ---------------------------------------------------------------------------

  Future<void> _onEditChannel() async {
    // Retired path — the settings screen IS the editor now.
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => ChannelSettingsPage(channel: _channel),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Export URLs (JSON Feed / RSS / Atom)
  // ---------------------------------------------------------------------------

  String? _exportUrl(String format) {
    final server = _serverAddress;
    final owner = _ownerAddress;
    if (server == null || server.isEmpty || owner.isEmpty || _slug.isEmpty) {
      return null;
    }
    final base = server.endsWith('/') ? server.substring(0, server.length - 1) : server;
    return '$base/api/$owner/channels/$_slug/$format';
  }

  Future<void> _copyExport(String format, String label) async {
    final l10n = context.l10n;
    final url = _exportUrl(format);
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.manageChannelPageMissingServerInfo),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.manageChannelPageExportUrlCopied(label)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  Future<void> _onDeleteChannel() async {
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
        title: Text(
          l10n.manageChannelPageDeleteTitle,
          style: TextStyle(color: tokens.starkWhite),
        ),
        content: Text(
          l10n.manageChannelPageDeleteBody(_channel.name),
          style: TextStyle(color: tokens.textDim, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.dlgCancel, style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.manageChannelPageDelete,
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
    setState(() => _isDeleting = true);
    try {
      final response = await PublicOSChannels.deleteChannel(
        slug: _slug,
        serverAddress: _serverAddress,
      );
      if (!mounted) return;
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.manageChannelPageDeleted(_channel.name)),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // signal caller to refresh
      } else {
        handleWriteError(
          context,
          response.error ?? l10n.manageChannelPageUnknownError,
          fallbackMessage: l10n.manageChannelPageFailDelete(
              response.error?['message']?.toString() ??
                  l10n.manageChannelPageUnknownError),
        );
        setState(() => _isDeleting = false);
      }
    } catch (e) {
      if (!mounted) return;
      handleWriteError(context, e);
      setState(() => _isDeleting = false);
    }
  }
}

// ============================================================================
// AppBar helpers — tabs + overflow menu
// ============================================================================

class _ModTabs extends StatelessWidget {
  const _ModTabs();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: tokens.borderSubtle, width: 0.5),
        ),
      ),
      child: TabBar(
        isScrollable: false,
        labelColor: tokens.starkWhite,
        unselectedLabelColor: tokens.textDim,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
        indicatorColor: tokens.starkWhite,
        indicatorWeight: 2,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: context.l10n.manageChannelPageTabPosters),
          Tab(text: context.l10n.manageChannelPageTabBans),
          Tab(text: context.l10n.manageChannelPageTabReadAccess),
        ],
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onCopyJson;
  final VoidCallback onCopyRss;
  final VoidCallback onCopyAtom;
  final VoidCallback? onDelete;

  const _OverflowMenu({
    required this.onEdit,
    required this.onCopyJson,
    required this.onCopyRss,
    required this.onCopyAtom,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, color: tokens.starkWhite),
      color: tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tokens.borderSubtle),
      ),
      onSelected: (v) {
        switch (v) {
          case 'edit':
            onEdit();
            break;
          case 'json':
            onCopyJson();
            break;
          case 'rss':
            onCopyRss();
            break;
          case 'atom':
            onCopyAtom();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (_) => [
        _menuItem(tokens, 'edit', Icons.edit_outlined,
            context.l10n.manageChannelPageEditChannel),
        const PopupMenuDivider(),
        _menuItem(tokens, 'json', Icons.rss_feed_rounded,
            context.l10n.manageChannelPageMenuCopyJson),
        _menuItem(tokens, 'rss', Icons.rss_feed_rounded,
            context.l10n.manageChannelPageMenuCopyRss),
        _menuItem(tokens, 'atom', Icons.rss_feed_rounded,
            context.l10n.manageChannelPageMenuCopyAtom),
        if (onDelete != null) const PopupMenuDivider(),
        if (onDelete != null)
          _menuItem(tokens, 'delete', Icons.delete_outline_rounded,
              context.l10n.manageChannelPageMenuDelete,
              destructive: true),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
    GlassTokens tokens,
    String value,
    IconData icon,
    String label, {
    bool destructive = false,
  }) {
    final color = destructive ? const Color(0xFFE57373) : tokens.starkWhite;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Shared primitives — section header, address entry bar, small button, row
// ============================================================================

class _AddressEntryBar extends StatefulWidget {
  /// Optional — when non-null, the bar shows an `ExpirationPickerField` for
  /// granting temporary access (Posters / Whitelist). When null, the bar
  /// skips expiration (Bans — indefinite).
  final bool showExpiration;

  /// Optional — when true, the bar shows an extra "Reason" field (Bans).
  final bool showReason;

  final String addHint;
  final String addButtonLabel;

  final Future<bool> Function({
    required String address,
    DateTime? expiresAt,
    String? reason,
  }) onSubmit;

  const _AddressEntryBar({
    required this.showExpiration,
    required this.showReason,
    required this.addHint,
    required this.addButtonLabel,
    required this.onSubmit,
  });

  @override
  State<_AddressEntryBar> createState() => _AddressEntryBarState();
}

class _AddressEntryBarState extends State<_AddressEntryBar> {
  final _addressCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  DateTime? _expiresAt;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _addressCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_submitting) return false;
    return _addressCtrl.text.trim().length >= 2;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    // Username → account address; raw 0x input passes through untouched.
    final resolved = await resolveAccountInput(_addressCtrl.text);
    if (!mounted) return;
    if (resolved == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accountResolveNoMatch)),
      );
      return;
    }
    final ok = await widget.onSubmit(
      address: resolved,
      expiresAt: widget.showExpiration ? _expiresAt : null,
      reason: widget.showReason && _reasonCtrl.text.trim().isNotEmpty
          ? _reasonCtrl.text.trim()
          : null,
    );
    if (!mounted) return;
    if (ok) {
      _addressCtrl.clear();
      _reasonCtrl.clear();
      setState(() {
        _expiresAt = null;
        _submitting = false;
      });
    } else {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: tokens.borderSubtle, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccountResolveField(
            controller: _addressCtrl,
            hint: widget.addHint,
          ),
          if (widget.showReason) ...[
            const SizedBox(height: 8),
            _ReasonField(controller: _reasonCtrl),
          ],
          if (widget.showExpiration) ...[
            const SizedBox(height: 8),
            ExpirationPickerField(
              value: _expiresAt,
              onChanged: (v) => setState(() => _expiresAt = v),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _GlassActionButton(
              label: widget.addButtonLabel,
              enabled: _canSubmit,
              loading: _submitting,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonField extends StatelessWidget {
  final TextEditingController controller;

  const _ReasonField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return TextField(
      controller: controller,
      maxLength: 140,
      maxLines: 2,
      style: TextStyle(color: tokens.starkWhite, fontSize: 13),
      decoration: InputDecoration(
        hintText: context.l10n.manageChannelPageReasonHint,
        hintStyle: TextStyle(color: tokens.textDim, fontSize: 13),
        filled: true,
        fillColor: tokens.surfaceElevated,
        isDense: true,
        counterStyle: TextStyle(color: tokens.textDim, fontSize: 10),
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

class _GlassActionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  const _GlassActionButton({
    required this.label,
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
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: enabled ? tokens.borderMedium : tokens.borderSubtle,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: enabled && !loading ? onPressed : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: PhigitalLoadingWidget(size: 14, showShadows: false),
                )
              : Text(
                  label,
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

class _ModEntryRow extends StatefulWidget {
  final String address;
  final DateTime? expiresAt;
  final String? secondaryLine;
  final VoidCallback onRemove;
  final bool removing;

  const _ModEntryRow({
    required this.address,
    required this.onRemove,
    this.expiresAt,
    this.secondaryLine,
    this.removing = false,
  });

  @override
  State<_ModEntryRow> createState() => _ModEntryRowState();
}

class _ModEntryRowState extends State<_ModEntryRow> {
  Contact? _contact;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final c = await _lookupContact(widget.address);
    if (!mounted || c == null) return;
    setState(() => _contact = c);
  }

  void _openProfile() {
    final c = _contact;
    if (c != null) {
      AppNav.toContact(context, c);
    } else {
      AppNav.toProfile(context, widget.address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final address = widget.address;
    final short = address.length > 14
        ? '${address.substring(0, 8)}…${address.substring(address.length - 4)}'
        : address;
    final displayName = _contact?.displayName;
    final hasName = displayName != null && displayName.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GlassContactIcon(
            contact: _contact,
            address: address,
            size: 36,
            onTap: _openProfile,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? displayName : short,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: hasName ? null : 'monospace',
                  ),
                ),
                if (hasName) ...[
                  const SizedBox(height: 2),
                  Text(
                    short,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                if (widget.secondaryLine != null &&
                    widget.secondaryLine!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.secondaryLine!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
                if (widget.expiresAt != null) ...[
                  const SizedBox(height: 4),
                  ExpirationChip(value: widget.expiresAt!),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: context.l10n.manageChannelPageRemoveTooltip,
            onPressed: widget.removing ? null : widget.onRemove,
            icon: widget.removing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: PhigitalLoadingWidget(size: 14, showShadows: false),
                  )
                : Icon(Icons.close_rounded, size: 18, color: tokens.textDim),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Contextual header rendered at the top of each moderation tab.
/// Tells the user what the current channel config means for THIS tab so
/// they don't have to cross-reference the access-control matrix themselves.
///
/// Layout:
///  - small uppercase label ("WHO CAN POST")
///  - bold verdict line ("Only you can post")
///  - dim explainer sentence
///  - optional "gate" chips for additive constraints (verified / rent)
class _SectionStatus extends StatelessWidget {
  final String label;
  final String verdict;
  final String explainer;
  final List<({IconData icon, String text})> gates;
  final bool warning;
  /// Optional inline CTA pill — shown bottom-right of the banner. Wire to
  /// the parent's "Edit channel" push when the tab is in an inert state so
  /// the user has a one-tap fix.
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionStatus({
    required this.label,
    required this.verdict,
    required this.explainer,
    this.gates = const [],
    this.warning = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        border: Border.all(
          color: warning ? tokens.fallbackAccent : tokens.borderSubtle,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: tokens.textDim,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            verdict,
            style: TextStyle(
              color: tokens.starkWhite,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            explainer,
            style: TextStyle(
              color: tokens.textDim,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (gates.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: gates.map((g) => _GateChip(icon: g.icon, text: g.text)).toList(),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _InlineAction(label: actionLabel!, onTap: onAction!),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _InlineAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.borderMedium, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined, size: 12, color: tokens.starkWhite),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: tokens.starkWhite,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GateChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _GateChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: tokens.borderSubtle, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: tokens.textDim),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: tokens.textDim,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// A gate chip for one rung of the identity ladder, or null when the rung is
/// `anyone` and there is nothing to say.
///
/// Reading the retired booleans here would make the badge LIE by omission: a
/// channel set to `signed`, `account` or `standing` is gated, but none of those
/// flips require_verified_*, so the banner would show no constraint at all and
/// the owner would believe their channel is open.
({IconData icon, String text})? _tierChip(BuildContext context, String tier) {
  final l10n = context.l10n;
  switch (tier) {
    case GateTier.signed:
      return (icon: Icons.key_rounded, text: l10n.gateTierSignedLabel);
    case GateTier.account:
      return (icon: Icons.badge_outlined, text: l10n.gateTierAccountLabel);
    case GateTier.standing:
      return (icon: Icons.verified_outlined, text: l10n.gateTierStandingLabel);
    case GateTier.citizen:
      return (icon: Icons.how_to_reg_rounded, text: l10n.gateTierCitizenLabel);
    default:
      return null; // anyone - no constraint to show
  }
}

/// Additive constraint chips applied on top of whatever the base policy
/// allows. Shared between POSTERS and WHITELIST banners.
List<({IconData icon, String text})> _postingGates(
    BuildContext context, Channel channel) {
  final gates = <({IconData icon, String text})>[];
  // ONE chip, not two: posting_identity covers both verified posting and
  // rent, which are two rungs of the same ladder.
  final chip = _tierChip(context, channel.postingTier);
  if (chip != null) gates.add(chip);
  return gates;
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // Scrollable so a keyboard-squeezed viewport clips instead of striping.
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: tokens.textDim),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(color: tokens.textDim, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: PhigitalLoadingWidget());
  }
}

// ============================================================================
// POSTERS tab — `post_permissions` table (who can post in the channel).
// Uses PublicOSChannels.{listPosters, addPoster, removePoster}.
// ============================================================================

class _PostersTab extends StatefulWidget {
  final Channel channel;
  final VoidCallback onEditChannel;

  const _PostersTab({
    super.key,
    required this.channel,
    required this.onEditChannel,
  });

  @override
  State<_PostersTab> createState() => _PostersTabState();
}

class _PostersTabState extends State<_PostersTab> {
  List<PostPermissionEntry> _entries = [];
  bool _loading = true;
  final Set<String> _removing = {};

  String get _slug => widget.channel.slug;
  String? get _serverAddress => widget.channel.serverAddress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await PublicOSChannels.listPosters(
      slug: _slug,
      serverAddress: _serverAddress,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _entries = r.success ? (r.data ?? const []) : const [];
    });
  }

  Future<bool> _addPoster({
    required String address,
    DateTime? expiresAt,
    String? reason,
  }) async {
    final r = await PublicOSChannels.addPoster(
      slug: _slug,
      address: address,
      expiresAt: expiresAt?.toUtc().toIso8601String(),
      serverAddress: _serverAddress,
    );
    if (!mounted) return false;
    if (r.success) {
      _load();
      return true;
    }
    handleWriteError(
        context, r.error ?? context.l10n.manageChannelPageFailAddPoster,
        fallbackMessage: r.error?['message']?.toString() ??
            context.l10n.manageChannelPageFailAddPoster);
    return false;
  }

  Future<void> _removePoster(String address) async {
    setState(() => _removing.add(address.toLowerCase()));
    final r = await PublicOSChannels.removePoster(
      slug: _slug,
      address: address,
      serverAddress: _serverAddress,
    );
    if (!mounted) return;
    if (r.success) {
      setState(() {
        _entries = _entries
            .where((e) => e.address.toLowerCase() != address.toLowerCase())
            .toList();
        _removing.remove(address.toLowerCase());
      });
    } else {
      setState(() => _removing.remove(address.toLowerCase()));
      handleWriteError(
          context, r.error ?? context.l10n.manageChannelPageFailRemovePoster,
          fallbackMessage: r.error?['message']?.toString() ??
              context.l10n.manageChannelPageFailRemovePoster);
    }
  }

  bool get _isApproved => widget.channel.postingPolicy == 'approved';

  /// Verdict + explainer derived from `Channel.postingPolicy` + gates.
  /// Policy semantics:
  ///  - `owner` → only the owner can post (list is ignored)
  ///  - `open`  → anyone with access can post (list is ignored)
  ///  - `approved` → owner + addresses in this list can post
  ///
  /// When the list is inert (owner/open) we warning-tint the banner and
  /// surface an "Edit channel" CTA so the user has a one-tap fix. The
  /// address entry bar is hidden in those states since adding does nothing.
  _SectionStatus _buildBanner() {
    final policy = widget.channel.postingPolicy;
    final count = _entries.length;
    final gates = _postingGates(context, widget.channel);
    switch (policy) {
      case 'approved':
        return _SectionStatus(
          label: context.l10n.manageChannelPageWhoCanPost,
          verdict: context.l10n.manageChannelPagePostersVerdict(count),
          explainer: context.l10n.manageChannelPagePostersExplainerApproved,
          gates: gates,
        );
      case 'open':
        return _SectionStatus(
          label: context.l10n.manageChannelPageWhoCanPost,
          verdict: context.l10n.manageChannelPagePostersVerdictOpen,
          explainer: context.l10n.manageChannelPagePostersExplainerOpen,
          gates: gates,
          warning: true,
          actionLabel: context.l10n.manageChannelPageEditChannel,
          onAction: widget.onEditChannel,
        );
      case 'owner':
      default:
        return _SectionStatus(
          label: context.l10n.manageChannelPageWhoCanPost,
          verdict: context.l10n.manageChannelPagePostersVerdictOwnerOnly,
          explainer: context.l10n.manageChannelPagePostersExplainerOwner,
          gates: gates,
          warning: true,
          actionLabel: context.l10n.manageChannelPageEditChannel,
          onAction: widget.onEditChannel,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBanner(),
        // Only show the address entry bar when the list is actually used.
        // On owner/open policies adds are inert — the banner explains why
        // and offers an Edit channel CTA instead.
        if (_isApproved)
          _AddressEntryBar(
            showExpiration: true,
            showReason: false,
            addHint: context.l10n.manageChannelPagePosterAddHint,
            addButtonLabel: context.l10n.manageChannelPagePosterAddButton,
            onSubmit: _addPoster,
          ),
        Expanded(
          child: _loading && _entries.isEmpty
              ? const _LoadingState()
              : _entries.isEmpty
                  ? _EmptyState(
                      icon: Icons.edit_note_rounded,
                      label: context.l10n.manageChannelPagePostersEmpty,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _entries.length,
                        itemBuilder: (_, i) {
                          final e = _entries[i];
                          final expires = e.expiresAt == null
                              ? null
                              : DateTime.tryParse(e.expiresAt!);
                          return _ModEntryRow(
                            address: e.address,
                            expiresAt: expires,
                            onRemove: () => _removePoster(e.address),
                            removing:
                                _removing.contains(e.address.toLowerCase()),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

// ============================================================================
// BANS tab — `blacklist` rows for the channel. Uses
// PublicOSChannels.{listBans, ban, unban}.
// ============================================================================

class _BansTab extends StatefulWidget {
  final Channel channel;

  const _BansTab({super.key, required this.channel});

  @override
  State<_BansTab> createState() => _BansTabState();
}

class _BansTabState extends State<_BansTab> {
  List<BanEntry> _entries = [];
  bool _loading = true;
  final Set<String> _removing = {};

  String get _slug => widget.channel.slug;
  String? get _serverAddress => widget.channel.serverAddress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await PublicOSChannels.listBans(
      slug: _slug,
      serverAddress: _serverAddress,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _entries = r.success ? (r.data ?? const []) : const [];
    });
  }

  Future<bool> _ban({
    required String address,
    DateTime? expiresAt,
    String? reason,
  }) async {
    final r = await PublicOSChannels.ban(
      slug: _slug,
      address: address,
      reason: reason,
      serverAddress: _serverAddress,
    );
    if (!mounted) return false;
    if (r.success) {
      _load();
      return true;
    }
    handleWriteError(context, r.error ?? context.l10n.manageChannelPageFailBan,
        fallbackMessage: r.error?['message']?.toString() ??
            context.l10n.manageChannelPageFailBan);
    return false;
  }

  Future<void> _unban(String address) async {
    setState(() => _removing.add(address.toLowerCase()));
    final r = await PublicOSChannels.unban(
      slug: _slug,
      address: address,
      serverAddress: _serverAddress,
    );
    if (!mounted) return;
    if (r.success) {
      setState(() {
        _entries = _entries
            .where((e) => e.address.toLowerCase() != address.toLowerCase())
            .toList();
        _removing.remove(address.toLowerCase());
      });
    } else {
      setState(() => _removing.remove(address.toLowerCase()));
      handleWriteError(
          context, r.error ?? context.l10n.manageChannelPageFailUnban,
          fallbackMessage: r.error?['message']?.toString() ??
              context.l10n.manageChannelPageFailUnban);
    }
  }

  /// Bans are the only layer that affects EVERY interaction (the server
  /// checks them first in every operation). Same
  /// verdict copy regardless of channel config — no gate chips either.
  _SectionStatus _buildBanner() {
    final count = _entries.length;
    return _SectionStatus(
      label: context.l10n.manageChannelPageWhosBlocked,
      verdict: context.l10n.manageChannelPageBansVerdict(count),
      explainer: context.l10n.manageChannelPageBansExplainer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBanner(),
        _AddressEntryBar(
          showExpiration: false,
          showReason: true,
          addHint: context.l10n.manageChannelPageBanAddHint,
          addButtonLabel: context.l10n.manageChannelPageBanAddButton,
          onSubmit: _ban,
        ),
        Expanded(
          child: _loading && _entries.isEmpty
              ? const _LoadingState()
              : _entries.isEmpty
                  ? _EmptyState(
                      icon: Icons.block_rounded,
                      label: context.l10n.manageChannelPageBansEmpty,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _entries.length,
                        itemBuilder: (_, i) {
                          final e = _entries[i];
                          return _ModEntryRow(
                            address: e.address,
                            secondaryLine: e.reason,
                            onRemove: () => _unban(e.address),
                            removing:
                                _removing.contains(e.address.toLowerCase()),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

// ============================================================================
// READ ACCESS tab — merged whitelist + pending follow requests. Backed by
// `whitelists` (manual adds + auto-inserts on approval) and `follow_requests`
// (the inbox). PublicOSChannels.{listWhitelist, addToWhitelist,
// removeFromWhitelist, listFollowers, approveFollower, ignoreFollower}.
// ============================================================================

class _ReadAccessTab extends StatefulWidget {
  final Channel channel;
  final VoidCallback onEditChannel;

  const _ReadAccessTab({
    super.key,
    required this.channel,
    required this.onEditChannel,
  });

  @override
  State<_ReadAccessTab> createState() => _ReadAccessTabState();
}

/// Single-source-of-truth tab for who can read a private channel. Server-
/// side both manual whitelist additions AND approved follow requests end
/// up as rows in the same `whitelists` table (the server's
/// `ApproveFollower` creates a Whitelist row), so surfacing them as
/// separate tabs would be misleading.
///
/// Layout: status banner → pending requests (capped, scrollable in-place)
/// → address entry bar → full whitelist with remove buttons. Pending
/// requests + entry bar are hidden on public channels (the access check
/// ignores the whitelist there entirely).
class _ReadAccessTabState extends State<_ReadAccessTab> {
  List<WhitelistEntry> _whitelist = [];
  List<FollowRequest> _requests = [];
  bool _loading = true;
  final Set<String> _removing = {};
  final Set<String> _processing = {};
  String _requestFilter = 'pending';

  /// Window for the requests inbox. Matches the left-nav badge query so the
  /// counts agree on first read; rows older than this stay queryable from
  /// the server but don't surface in the manage view by default.
  static const Duration _requestsWindow = Duration(days: 14);

  String get _slug => widget.channel.slug;
  String? get _serverAddress => widget.channel.serverAddress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Parallel fetch — both endpoints are independent. A failure on one
  /// leaves the other intact so the page stays useful when, say, requests
  /// 500s but the whitelist loads fine.
  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _fetchWhitelist(),
      _fetchRequests(),
    ]);
    if (!mounted) return;
    setState(() {
      _whitelist = results[0] as List<WhitelistEntry>;
      _requests = results[1] as List<FollowRequest>;
      _loading = false;
    });
  }

  Future<List<WhitelistEntry>> _fetchWhitelist() async {
    final r = await PublicOSChannels.listWhitelist(
      slug: _slug,
      serverAddress: _serverAddress,
    );
    return r.success ? (r.data ?? const []) : const [];
  }

  Future<List<FollowRequest>> _fetchRequests() async {
    // Public channels gate reads at the server, so a request inbox
    // wouldn't normally exist — skip the fetch to save a round trip.
    if (!widget.channel.isPrivate) return const [];
    final r = await PublicOSChannels.listFollowers(
      slug: _slug,
      serverAddress: _serverAddress,
      statuses: const ['pending', 'ignored', 'approved'],
      startDate: DateTime.now().subtract(_requestsWindow),
    );
    if (!r.success || r.data == null) return const [];
    return r.data!.followRequests;
  }

  Future<bool> _addToWhitelist({
    required String address,
    DateTime? expiresAt,
    String? reason,
  }) async {
    final r = await PublicOSChannels.addToWhitelist(
      slug: _slug,
      address: address,
      expiresAt: expiresAt?.toUtc().toIso8601String(),
      serverAddress: _serverAddress,
    );
    if (!mounted) return false;
    if (r.success) {
      _refreshWhitelist();
      return true;
    }
    handleWriteError(
        context, r.error ?? context.l10n.manageChannelPageFailAddWhitelist,
        fallbackMessage: r.error?['message']?.toString() ??
            context.l10n.manageChannelPageFailAddWhitelist);
    return false;
  }

  Future<void> _removeFromWhitelist(String address) async {
    setState(() => _removing.add(address.toLowerCase()));
    final r = await PublicOSChannels.removeFromWhitelist(
      slug: _slug,
      address: address,
      serverAddress: _serverAddress,
    );
    if (!mounted) return;
    if (r.success) {
      setState(() {
        _whitelist = _whitelist
            .where((e) => e.address.toLowerCase() != address.toLowerCase())
            .toList();
        _removing.remove(address.toLowerCase());
      });
    } else {
      setState(() => _removing.remove(address.toLowerCase()));
      handleWriteError(
          context, r.error ?? context.l10n.manageChannelPageFailRemove,
          fallbackMessage: r.error?['message']?.toString() ??
              context.l10n.manageChannelPageFailRemove);
    }
  }

  /// Approve creates a Whitelist row on the server (`channel_follows.go`'s
  /// `ApproveFollower` does both — flips the request to `approved` AND
  /// inserts into `whitelists`). Reflect that locally: drop the request
  /// AND re-fetch the whitelist so the new row appears with its server-
  /// assigned id / createdAt / expiresAt rather than a faked stub.
  /// Replace the matching request row in-place so the inbox keeps its
  /// audit trail (approved + ignored rows stay visible under their
  /// respective chips). Dropping the row would erase the owner's history
  /// in the chip-filtered all-status view.
  void _replaceRequest(FollowRequest updated) {
    _requests = [
      for (final r in _requests) r.uid == updated.uid ? updated : r,
    ];
  }

  Future<void> _approve(FollowRequest req) async {
    setState(() => _processing.add(req.uid));
    final r = await PublicOSChannels.approveFollower(
      slug: _slug,
      requestUid: req.uid,
      serverAddress: _serverAddress,
    );
    if (!mounted) return;
    if (r.success && r.data != null) {
      setState(() {
        _processing.remove(req.uid);
        _replaceRequest(r.data!);
      });
      _refreshWhitelist();
    } else {
      setState(() => _processing.remove(req.uid));
      handleWriteError(
          context, r.error ?? context.l10n.manageChannelPageFailApprove,
          fallbackMessage: r.error?['message']?.toString() ??
              context.l10n.manageChannelPageFailApprove);
    }
  }

  /// Ignore is a soft owner-side action: the request row stays in the
  /// table with `status = ignored` so the requester sees a stable history
  /// and the owner keeps an audit trail. The row stays in `_requests`
  /// and re-renders under the Ignored chip in the inbox.
  Future<void> _ignore(FollowRequest req) async {
    setState(() => _processing.add(req.uid));
    final r = await PublicOSChannels.ignoreFollower(
      slug: _slug,
      requestUid: req.uid,
      serverAddress: _serverAddress,
    );
    if (!mounted) return;
    if (r.success && r.data != null) {
      setState(() {
        _processing.remove(req.uid);
        _replaceRequest(r.data!);
      });
    } else {
      setState(() => _processing.remove(req.uid));
      handleWriteError(
          context, r.error ?? context.l10n.manageChannelPageFailIgnore,
          fallbackMessage: r.error?['message']?.toString() ??
              context.l10n.manageChannelPageFailIgnore);
    }
  }

  Future<void> _refreshWhitelist() async {
    final fresh = await _fetchWhitelist();
    if (!mounted) return;
    setState(() => _whitelist = fresh);
  }

  /// Read-access whitelist — only has teeth when the channel is private.
  /// On public
  /// channels the list sits inert; surface that with a warning tint + an
  /// "ignored right now" explainer so the user doesn't wonder why adding
  /// addresses seems to do nothing.
  _SectionStatus _buildBanner() {
    final isPrivate = widget.channel.isPrivate;
    final count = _whitelist.length;
    final gates = <({IconData icon, String text})>[];
    final readChip = _tierChip(context, widget.channel.readTier);
    if (readChip != null) gates.add(readChip);
    if (!isPrivate) {
      return _SectionStatus(
        label: context.l10n.manageChannelPageWhoCanRead,
        verdict: context.l10n.manageChannelPageReadVerdictPublic,
        explainer: context.l10n.manageChannelPageReadExplainerPublic,
        gates: gates,
        warning: true,
        actionLabel: context.l10n.manageChannelPageEditChannel,
        onAction: widget.onEditChannel,
      );
    }
    return _SectionStatus(
      label: context.l10n.manageChannelPageWhoCanRead,
      verdict: context.l10n.manageChannelPageReadVerdict(count),
      explainer: context.l10n.manageChannelPageReadExplainerPrivate,
      gates: gates,
    );
  }

  /// Capped-height requests inbox. Hidden when no requests in any status
  /// OR when the channel is public (no inbox exists in that state). Three
  /// filter chips (Pending / Ignored / Approved) drive a client-side
  /// filter on the already-fetched 14-day window — switching chips never
  /// re-hits the server. Per-row actions vary by status: pending shows
  /// Approve + Ignore; ignored shows only Approve (owner can reconsider);
  /// approved is read-only because revoke happens by removing the
  /// whitelist entry below, not by mutating the historical request row.
  Widget _buildRequestsSection(GlassTokens tokens) {
    final pendingCount = _requests.where((r) => r.isPending).length;
    final ignoredCount = _requests.where((r) => r.isIgnored).length;
    final approvedCount = _requests.where((r) => r.isApproved).length;
    final filtered =
        _requests.where((r) => r.status == _requestFilter).toList();
    final filterLabel = switch (_requestFilter) {
      'pending' => context.l10n.manageChannelPageFilterPending,
      'ignored' => context.l10n.manageChannelPageFilterIgnored,
      _ => context.l10n.manageChannelPageFilterApproved,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              context.l10n.manageChannelPageRequestsHeader,
              style: TextStyle(
                color: tokens.textDim,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              children: [
                _RequestFilterChip(
                  label: context.l10n.manageChannelPageFilterPending,
                  count: pendingCount,
                  selected: _requestFilter == 'pending',
                  onTap: () => setState(() => _requestFilter = 'pending'),
                ),
                _RequestFilterChip(
                  label: context.l10n.manageChannelPageFilterIgnored,
                  count: ignoredCount,
                  selected: _requestFilter == 'ignored',
                  onTap: () => setState(() => _requestFilter = 'ignored'),
                ),
                _RequestFilterChip(
                  label: context.l10n.manageChannelPageFilterApproved,
                  count: approvedCount,
                  selected: _requestFilter == 'approved',
                  onTap: () => setState(() => _requestFilter = 'approved'),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 290),
            child: Container(
              decoration: BoxDecoration(
                color: tokens.surfaceElevated,
                border: Border.all(color: tokens.borderSubtle, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      child: Text(
                        context.l10n
                            .manageChannelPageNoRequestsInWindow(filterLabel),
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
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: tokens.borderSubtle, height: 1),
                      itemBuilder: (_, i) {
                        final r = filtered[i];
                        return _RequestRow(
                          request: r,
                          processing: _processing.contains(r.uid),
                          onApprove: () => _approve(r),
                          onIgnore: () => _ignore(r),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final isPrivate = widget.channel.isPrivate;
    final showRequests = isPrivate && _requests.isNotEmpty;
    return Column(
      children: [
        _buildBanner(),
        if (showRequests) _buildRequestsSection(tokens),
        // Manual entry only matters on private channels. On public ones
        // adds are ignored by the access check anyway — the banner CTA
        // steers users toward toggling privacy instead.
        if (isPrivate)
          _AddressEntryBar(
            showExpiration: true,
            showReason: false,
            addHint: context.l10n.manageChannelPageReadAddHint,
            addButtonLabel: context.l10n.manageChannelPageReadAddButton,
            onSubmit: _addToWhitelist,
          ),
        Expanded(
          child: _loading && _whitelist.isEmpty
              ? const _LoadingState()
              : _whitelist.isEmpty
                  ? _EmptyState(
                      icon: Icons.visibility_outlined,
                      label: context.l10n.manageChannelPageReadEmpty,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _whitelist.length,
                        itemBuilder: (_, i) {
                          final e = _whitelist[i];
                          final expires = e.expiresAt == null
                              ? null
                              : DateTime.tryParse(e.expiresAt!);
                          return _ModEntryRow(
                            address: e.address,
                            expiresAt: expires,
                            onRemove: () => _removeFromWhitelist(e.address),
                            removing:
                                _removing.contains(e.address.toLowerCase()),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _RequestRow extends StatefulWidget {
  final FollowRequest request;
  final bool processing;
  final VoidCallback onApprove;
  final VoidCallback onIgnore;

  const _RequestRow({
    required this.request,
    required this.processing,
    required this.onApprove,
    required this.onIgnore,
  });

  @override
  State<_RequestRow> createState() => _RequestRowState();
}

class _RequestRowState extends State<_RequestRow> {
  Contact? _contact;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final c = await _lookupContact(widget.request.requesterAddress);
    if (!mounted || c == null) return;
    setState(() => _contact = c);
  }

  void _openProfile() {
    final c = _contact;
    if (c != null) {
      AppNav.toContact(context, c);
    } else {
      AppNav.toProfile(context, widget.request.requesterAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final request = widget.request;
    final address = request.requesterAddress;
    final short = address.length > 14
        ? '${address.substring(0, 8)}…${address.substring(address.length - 4)}'
        : address;
    final displayName = _contact?.displayName;
    final hasName = displayName != null && displayName.isNotEmpty;
    final requested = DateTime.tryParse(request.createdAt);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GlassContactIcon(
            contact: _contact,
            address: address,
            size: 40,
            onTap: _openProfile,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? displayName : short,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: hasName ? null : 'monospace',
                  ),
                ),
                if (hasName) ...[
                  const SizedBox(height: 2),
                  Text(
                    short,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                if (requested != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    context.l10n
                        .manageChannelPageRequestedAt(_relative(requested)),
                    style: TextStyle(color: tokens.textDim, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (widget.processing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: PhigitalLoadingWidget(size: 16, showShadows: false),
              ),
            )
          // Approved rows are read-only here. Revoke happens by removing
          // the matching whitelist entry below; mutating the historical
          // request row would be a noop (server returns INVALID_TRANSITION).
          else if (request.isApproved)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                context.l10n.manageChannelPageRequestApprovedTag,
                style: TextStyle(
                  color: tokens.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            )
          else ...[
            // Pending shows both Approve + Ignore; ignored only Approve
            // (owner can reconsider but not move back to pending). Ignore
            // is soft (row stays) so it doesn't read as destructive here.
            if (request.isPending) ...[
              _RequestAction(
                label: context.l10n.manageChannelPageActionIgnore,
                onPressed: widget.onIgnore,
              ),
              const SizedBox(width: 8),
            ],
            _RequestAction(
                label: context.l10n.manageChannelPageActionApprove,
                onPressed: widget.onApprove),
          ],
        ],
      ),
    );
  }

  String _relative(DateTime when) {
    final l10n = context.l10n;
    final d = DateTime.now().difference(when);
    if (d.inMinutes < 1) return l10n.manageChannelPageJustNow;
    if (d.inHours < 1) return l10n.manageChannelPageMinutesAgo(d.inMinutes);
    if (d.inDays < 1) return l10n.manageChannelPageHoursAgo(d.inHours);
    if (d.inDays < 30) return l10n.manageChannelPageDaysAgo(d.inDays);
    return l10n.manageChannelPageMonthsAgo((d.inDays / 30).floor());
  }
}

/// Filter chip for the requests inbox (Pending / Ignored / Approved).
/// Shows a count next to the label so the owner can see at a glance
/// which buckets have anything in them without flipping through.
class _RequestFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _RequestFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final accent = tokens.connectedAccent;
    final fg = selected ? accent : tokens.starkWhite;
    final bg =
        selected ? accent.withValues(alpha: 0.12) : tokens.surfaceElevated;
    final border = selected
        ? accent.withValues(alpha: 0.6)
        : tokens.borderMedium;
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            '$label · $count',
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _RequestAction({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final color = tokens.starkWhite;
    return Material(
      color: tokens.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.borderMedium, width: 1),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

Future<Contact?> _lookupContact(String address) async {
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
