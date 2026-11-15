import 'dart:async';
import 'dart:io';
import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';

/// Bottom sheet for creating or editing a profile tab (web page or feed).
///
/// `record == null` → create mode (type selector shown, "CREATE TAB").
/// `record != null` → edit mode (type locked, fields pre-filled, "SAVE CHANGES").
/// [onSave] receives the built router [Record]; the sheet pops itself after
/// the callback resolves.
Future<void> showCreateTabSheet(
  BuildContext context, {
  Record? record,
  required Function(Record) onSave,
}) {
  // DELTA (desktop): sheet -> centered glass dialog. Opens on top of the
  // manage-tabs dialog, which is why it is the narrower of the two.
  return showGlassSheetDialog<void>(
    context: context,
    width: DialogWidth.m,
    builder: (_) => _CreateTabSheet(record: record, onSave: onSave),
  );
}

enum _TabKind { web, channel }

class _CreateTabSheet extends StatefulWidget {
  final Record? record; // For editing
  final Function(Record) onSave;

  const _CreateTabSheet({
    this.record,
    required this.onSave,
  });

  @override
  State<_CreateTabSheet> createState() => _CreateTabSheetState();
}

class _CreateTabSheetState extends State<_CreateTabSheet> {
  static final _domainPattern = RegExp(
    r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
  );
  static final _localPattern = RegExp(
    r'^(http?:\/\/)?(localhost|127\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}|10\.\d{1,3}\.\d{1,3}\.\d{1,3}|172\.(1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3})(:\d+)?(\/.*)?$',
  );

  late TextEditingController _labelController;
  late TextEditingController _urlController;
  bool _isSaving = false;
  String? _errorText;
  _TabKind _selectedTabKind = _TabKind.web;

  bool? _isUrlReachable;
  bool _isCheckingReachability = false;
  Timer? _reachabilityTimer;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final metadata = widget.record?.metadata;
    _labelController = TextEditingController(
      text: metadata?['name'] as String? ?? '',
    );
    _urlController = TextEditingController(
      text: widget.record?.value ?? '',
    );

    if (widget.record?.routerSubtype == RouterSubtype.channel) {
      _selectedTabKind = _TabKind.channel;
    }

    _labelController.addListener(() => setState(() {}));
    _urlController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _reachabilityTimer?.cancel();
    _labelController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  bool get _labelValid {
    final label = _labelController.text.trim();
    return label.isNotEmpty && label.length <= 50;
  }

  bool get _urlValid {
    final url = _urlController.text.trim();
    if (url.isEmpty) return false;
    return _domainPattern.hasMatch(url) || _localPattern.hasMatch(url);
  }

  void _onUrlChanged() {
    _reachabilityTimer?.cancel();
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _isUrlReachable = null;
        _isCheckingReachability = false;
      });
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      setState(() {
        _isUrlReachable = null;
        _isCheckingReachability = false;
      });
      return;
    }

    setState(() => _isCheckingReachability = true);
    _reachabilityTimer = Timer(
      const Duration(milliseconds: 800),
      () => _checkReachability(url),
    );
  }

  Future<void> _checkReachability(String url) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.headUrl(Uri.parse(url));
      final response =
          await request.close().timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _isUrlReachable = response.statusCode < 400;
          _isCheckingReachability = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isUrlReachable = false;
          _isCheckingReachability = false;
        });
      }
    } finally {
      client?.close();
    }
  }

  /// Tab keys are bare URL segments with no `tab.`/`rss.` prefix — the route's
  /// :type tier carries that, and the kind lives in routerSubtype.
  /// Output always satisfies the contract charset (^[a-z0-9_][a-z0-9._-]{0,30}$).
  String _generateNewKey(String label) {
    final safeLabel =
        label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return safeLabel.length > 20 ? safeLabel.substring(0, 20) : safeLabel;
  }

  Future<void> _handleSave() async {
    if (!_labelValid || !_urlValid || _isSaving) return;

    final l10n = context.l10n;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final routerSubtype = _selectedTabKind == _TabKind.channel
          ? RouterSubtype.channel
          : RouterSubtype.tab;
      final recordToSave = Record.asRouter(
        key: widget.record?.key ?? _generateNewKey(_labelController.text),
        value: _urlController.text.trim(),
        routerSubtype: routerSubtype,
        expiration: widget.record?.expiration ??
            DateTime.now().add(const Duration(days: 36500)),
        name: _labelController.text.trim(),
      );

      dynamic result = widget.onSave(recordToSave);
      if (result is Future) {
        await result;
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = localizedError(
              l10n,
              e,
              fallback: l10n.createTabSheetSaveFailed,
            ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
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
              // Title + close — matches Manage tabs.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                child: Row(
                  children: [
                    Text(
                      _isEditing
                          ? context.l10n.createTabSheetTitleEdit
                          : context.l10n.createTabSheetTitleNew,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
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
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isEditing) ...[
                        _buildKindRow(
                          tokens: tokens,
                          icon: Icons.language_rounded,
                          title: context.l10n.createTabSheetKindWeb,
                          kind: _TabKind.web,
                        ),
                        const SizedBox(height: 6),
                        _buildKindRow(
                          tokens: tokens,
                          icon: Icons.rss_feed_rounded,
                          title: context.l10n.createTabSheetKindChannel,
                          kind: _TabKind.channel,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _fieldLabel(tokens, context.l10n.createTabSheetFieldLabel),
                      const SizedBox(height: 6),
                      _buildTextField(
                        tokens: tokens,
                        controller: _labelController,
                        hint: context.l10n.createTabSheetLabelHint,
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel(
                        tokens,
                        _selectedTabKind == _TabKind.channel
                            ? context.l10n.createTabSheetFieldChannelUrl
                            : context.l10n.createTabSheetFieldWebUrl,
                      ),
                      const SizedBox(height: 6),
                      _buildTextField(
                        tokens: tokens,
                        controller: _urlController,
                        hint: _selectedTabKind == _TabKind.channel
                            ? 'https://example.com/feed.json'
                            : 'https://example.com/my-page',
                        keyboardType: TextInputType.url,
                        suffixIcon: _buildReachabilityIndicator(tokens),
                      ),
                      if (_selectedTabKind == _TabKind.channel) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: tokens.glassFill,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: tokens.borderSubtle, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: tokens.textDim,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.l10n.createTabSheetFeedFormatsInfo,
                                  style: TextStyle(
                                    fontFamily: 'SpaceGrotesk',
                                    fontSize: 12,
                                    color: tokens.textDim,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        _buildErrorPill(context),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: tokens.borderSubtle, height: 1),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: _buildSaveButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final String label;
    final VoidCallback? onTap;
    if (_isSaving) {
      label = context.l10n.createTabSheetSaving;
      onTap = null;
    } else if (!_labelValid) {
      label = context.l10n.createTabSheetEnterLabel;
      onTap = null;
    } else if (!_urlValid) {
      label = _selectedTabKind == _TabKind.channel
          ? context.l10n.createTabSheetEnterValidFeedUrl
          : context.l10n.createTabSheetEnterValidUrl;
      onTap = null;
    } else {
      label = _isEditing
          ? context.l10n.createTabSheetSaveChanges
          : context.l10n.createTabSheetCreateTab;
      onTap = _handleSave;
    }
    return SystemAppActionButton(
      label: label,
      icon: _isEditing ? Icons.check_rounded : Icons.add_rounded,
      onTap: onTap,
    );
  }

  Widget _fieldLabel(GlassTokens tokens, String label) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: tokens.textDim,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildTextField({
    required GlassTokens tokens,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: tokens.borderSubtle, width: 1),
    );
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 14,
        color: tokens.starkWhite,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 14,
          color: tokens.textDim,
        ),
        filled: true,
        fillColor: tokens.surfaceElevated,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderMedium, width: 1.5),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  /// Inline glass error pill — never a snackbar from inside a modal.
  Widget _buildErrorPill(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: error.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorText!,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                color: error,
              ),
            ),
          ),
          InkResponse(
            radius: 14,
            onTap: () => setState(() => _errorText = null),
            child: Icon(Icons.close_rounded, size: 14, color: error),
          ),
        ],
      ),
    );
  }

  Widget? _buildReachabilityIndicator(GlassTokens tokens) {
    if (_isCheckingReachability) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: PhigitalLoadingWidget(size: 8, showShadows: false),
        ),
      );
    }
    if (_isUrlReachable == true) {
      return Icon(
        Icons.check_circle_rounded,
        size: 18,
        color: tokens.connectedAccent,
      );
    }
    if (_isUrlReachable == false) {
      return Icon(
        Icons.warning_rounded,
        size: 18,
        color: tokens.fallbackAccent,
      );
    }
    return null;
  }

  Widget _buildKindRow({
    required GlassTokens tokens,
    required IconData icon,
    required String title,
    required _TabKind kind,
  }) {
    final isSelected = _selectedTabKind == kind;
    return Material(
      color: isSelected ? tokens.surfaceElevated : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? tokens.borderMedium : tokens.borderSubtle,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedTabKind = kind);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.glassFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.borderSubtle, width: 1),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? tokens.starkWhite : tokens.textDim,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: tokens.starkWhite,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, size: 18, color: tokens.starkWhite),
            ],
          ),
        ),
      ),
    );
  }
}
