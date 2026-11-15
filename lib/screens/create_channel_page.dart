import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// Minimal channel create: name, address (slug) and server — nothing else.
/// Lists cannot exist before the channel does, so every policy, gate and
/// list lives on ChannelSettingsPage, one tap away once the channel is real.
///
/// This page has no edit mode — ChannelSettingsPage is the one editing
/// surface.
///
/// Pops with the resulting [Channel] on success so the caller can refresh
/// its list immediately; pops with `null` on cancel.
class CreateChannelPage extends StatefulWidget {
  const CreateChannelPage({super.key});

  @override
  State<CreateChannelPage> createState() => _CreateChannelPageState();
}

class _CreateChannelPageState extends State<CreateChannelPage> {
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();

  bool _slugDirty = false; // becomes true once user edits slug manually
  bool _isSaving = false;

  // Server state — populated from SSP + registered feed servers on mount.
  List<({String label, String url})> _servers = [];
  String? _selectedServerUrl;
  String _serverLabel = '';
  bool _loadingServers = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onNameChanged);
    _loadServers();
  }

  void _onNameChanged() {
    if (!_slugDirty) {
      _slugCtrl.text = _slugify(_nameCtrl.text);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    super.dispose();
  }

  /// Same slugifier graph used — strips to `[a-z0-9]` + single hyphens.
  String _slugify(String input) {
    final lower = input.trim().toLowerCase();
    final stripped = lower.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    final hyphenated = stripped.replaceAll(RegExp(r'[\s-]+'), '-');
    return hyphenated.replaceAll(RegExp(r'^-|-$'), '');
  }

  /// Populate the server list: user's SSP (if registered) + every feed
  /// server the user has added. Defaults to the first (SSP-first order).
  Future<void> _loadServers() async {
    final servers = <({String label, String url})>[];
    try {
      final sspInfo = await PublicOSSsp.getSSPServerInfo();
      if (sspInfo != null) {
        final label = sspInfo.title.isNotEmpty ? sspInfo.title : sspInfo.slug;
        servers.add((label: '$label (SSP)', url: sspInfo.apiUrl));
      }
      final feedServers = await PublicOSSsp.getFeedServers();
      for (final fs in feedServers) {
        if (sspInfo != null && fs.feedServerAddress == sspInfo.apiUrl) continue;
        servers.add(
            (label: fs.name ?? fs.feedServerAddress, url: fs.feedServerAddress));
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _servers = servers;
      _loadingServers = false;
      if (servers.isNotEmpty) {
        _selectedServerUrl = servers.first.url;
        _serverLabel = servers.first.label;
      } else {
        // Empty -> build() resolves to the localized "no server" label.
        _serverLabel = '';
      }
    });
  }

  bool get _canSave =>
      !_isSaving &&
      !_loadingServers &&
      _selectedServerUrl != null &&
      _nameCtrl.text.trim().isNotEmpty &&
      _slugCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) return;
    final l10n = context.l10n;
    setState(() => _isSaving = true);

    final name = _nameCtrl.text.trim();
    final slug = _slugCtrl.text.trim();

    try {
      final response = await PublicOSChannels.createChannel(
        name: name,
        description: '',
        slug: slug,
        serverAddress: _selectedServerUrl,
      );

      if (!mounted) return;
      if (response.success && response.data != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.createChannelPageChannelCreated(name)),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, response.data);
      } else {
        final msg = response.error?['message']?.toString() ??
            l10n.createChannelPageUnknownError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.createChannelPageFailedToCreate(msg)),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedError(l10n, e))),
      );
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickServer() async {
    if (_loadingServers || _servers.isEmpty) return;
    final picked = await showGlassSheetDialog<({String label, String url})>(
      context: context,
      width: DialogWidth.m,
      builder: (_) => _ServerPickerSheet(
        servers: _servers,
        selected: _selectedServerUrl,
      ),
    );
    if (picked == null) return;
    setState(() {
      _selectedServerUrl = picked.url;
      _serverLabel = picked.label;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final serverLabel = _loadingServers
        ? l10n.createChannelPageServerLoading
        : (_serverLabel.isEmpty
            ? l10n.createChannelPageNoServerAvailable
            : _serverLabel);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: tokens.background,
        appBar: AppBar(
          backgroundColor: tokens.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: tokens.starkWhite),
          title: Text(
            l10n.createChannelPageNewTitle,
            style: TextStyle(
              color: tokens.starkWhite,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          centerTitle: false,
          actions: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
              child: _SaveButton(
                label: l10n.createChannelPageCreate,
                enabled: _canSave,
                loading: _isSaving,
                onPressed: _save,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _SectionHeader(label: l10n.createChannelPageSectionIdentity),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  color: tokens.starkWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  hintText: l10n.createChannelPageNameHint,
                  hintStyle: TextStyle(
                    color: tokens.textDim,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
            _LabeledField(
              label: l10n.createChannelPageSlugLabel,
              hint: l10n.createChannelPageSlugHint,
              controller: _slugCtrl,
              onChanged: () => setState(() => _slugDirty = true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9-]')),
              ],
            ),
            const SizedBox(height: 8),
            _ServerSection(
              label: serverLabel,
              onTap: _pickServer,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// AppBar Save button
// ============================================================================

class _SaveButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  const _SaveButton({
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
        onTap: enabled ? onPressed : null,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
        ),
      ),
    );
  }
}

// ============================================================================
// Section primitives
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Text(
        label,
        style: TextStyle(
          color: tokens.textDim,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onChanged;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: tokens.textDim,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            inputFormatters: inputFormatters,
            onChanged: (_) => onChanged?.call(),
            style: TextStyle(color: tokens.starkWhite, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: tokens.textDim, fontSize: 15),
              filled: true,
              fillColor: tokens.surfaceElevated,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: tokens.borderSubtle, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: tokens.borderSubtle, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: tokens.borderMedium, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerSection extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ServerSection({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: l10n.createChannelPageSectionServer),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Material(
            color: tokens.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: tokens.borderSubtle, width: 1),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      size: 18,
                      color: tokens.starkWhite,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              color: tokens.starkWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.createChannelPageServerSubtitle,
                            style: TextStyle(
                              color: tokens.textDim,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: tokens.textDim,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Glass bottom sheet listing the servers the user can post to. SSP-first,
/// then each registered feed server. Taps return a `(label, url)` record
/// via `Navigator.pop`.
class _ServerPickerSheet extends StatelessWidget {
  final List<({String label, String url})> servers;
  final String? selected;

  const _ServerPickerSheet({required this.servers, required this.selected});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceDeep,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Text(
                    l10n.createChannelPageChooseServer,
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
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            for (final server in servers)
              _ServerRow(
                server: server,
                selected: server.url == selected,
                onTap: () => Navigator.pop(context, server),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ServerRow extends StatelessWidget {
  final ({String label, String url}) server;
  final bool selected;
  final VoidCallback onTap;

  const _ServerRow({
    required this.server,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final host = Uri.tryParse(server.url)?.host ?? server.url;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.cloud_outlined,
              size: 20,
              color: selected ? tokens.starkWhite : tokens.textDim,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.label,
                    style: TextStyle(
                      color: tokens.starkWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    host,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? tokens.starkWhite : tokens.borderMedium,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tokens.starkWhite,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
