import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/glass_tokens.dart';
import 'phigital_loading_widget.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// Import key mode — mnemonic phrase or private key hex.
enum ImportKeyMode { mnemonic, privateKey }

/// Desktop dialog for importing an ETH key. The publicos_client equivalent
/// (`components/import_key_sheet.dart` → `ImportKeySheet`) is a bottom sheet;
/// this is the same flow (toggle · input · IMPORT) re-shelled as a glass dialog
/// per the desktop's dialog convention — no drag handle, a top-right close X,
/// no keyboard inset (desktop has a hardware keyboard).
///
/// The import logic itself is the caller's (`onImportMnemonic`/`onImportPrivateKey`
/// → Core `PublicOSKeychain.importTemporaryBlockchainKeyFrom…`); this widget only
/// drives the form + loading/error state and pops on success.
Future<void> showImportKeyDialog(
  BuildContext context, {
  required Future<bool> Function(String mnemonic) onImportMnemonic,
  required Future<bool> Function(String privateKey) onImportPrivateKey,
  String? title,
  String? subtitle,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ImportKeyDialog(
      onImportMnemonic: onImportMnemonic,
      onImportPrivateKey: onImportPrivateKey,
      title: title,
      subtitle: subtitle,
    ),
  );
}

class _ImportKeyDialog extends StatefulWidget {
  final Future<bool> Function(String mnemonic) onImportMnemonic;
  final Future<bool> Function(String privateKey) onImportPrivateKey;
  final String? title;
  final String? subtitle;

  const _ImportKeyDialog({
    required this.onImportMnemonic,
    required this.onImportPrivateKey,
    this.title,
    this.subtitle,
  });

  @override
  State<_ImportKeyDialog> createState() => _ImportKeyDialogState();
}

class _ImportKeyDialogState extends State<_ImportKeyDialog> {
  final TextEditingController _inputController = TextEditingController();
  ImportKeyMode _mode = ImportKeyMode.mnemonic;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  void _switchMode(ImportKeyMode mode) {
    if (_mode != mode) {
      setState(() {
        _mode = mode;
        _errorMessage = null;
      });
    }
  }

  String get _hintText => _mode == ImportKeyMode.mnemonic
      ? context.l10n.importHintMnemonic
      : '0x1a2b3c4d5e6f...';

  String get _inputLabel => _mode == ImportKeyMode.mnemonic
      ? context.l10n.importLabelMnemonic
      : context.l10n.importLabelPrivateKey;

  Future<void> _handleImport() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = _mode == ImportKeyMode.mnemonic
          ? context.l10n.importEnterMnemonic
          : context.l10n.importEnterPrivateKey);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = _mode == ImportKeyMode.mnemonic
          ? await widget.onImportMnemonic(input)
          : await widget.onImportPrivateKey(input);
      if (success && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = localizedError(context.l10n, e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: GlassTheme.glassBox(context).copyWith(
              color: tokens.surfaceDeep.withValues(alpha: 0.92),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: DialogWidth.m),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + close X (the dialog's dismiss affordance, in place
                  // of the sheet's swipe-down).
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (widget.title ?? context.l10n.keychainImportTitle).toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: tokens.starkWhite,
                          ),
                        ),
                      ),
                      InkResponse(
                        onTap: _isLoading ? null : () => Navigator.pop(context),
                        radius: 18,
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: tokens.textDim,
                        ),
                      ),
                    ],
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.textDim,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Mode toggle
                  Row(
                    children: [
                      Expanded(
                        child: _ModeToggle(
                          label: context.l10n.importModePhrase,
                          isSelected: _mode == ImportKeyMode.mnemonic,
                          onTap: () => _switchMode(ImportKeyMode.mnemonic),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ModeToggle(
                          label: context.l10n.importModePrivateKey,
                          isSelected: _mode == ImportKeyMode.privateKey,
                          onTap: () => _switchMode(ImportKeyMode.privateKey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Input label
                  Text(
                    _inputLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.textDim,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Text input
                  TextField(
                    controller: _inputController,
                    enabled: !_isLoading,
                    maxLines: 4,
                    onChanged: (_) => _clearError(),
                    style: TextStyle(
                      fontFamily:
                          _mode == ImportKeyMode.privateKey ? 'monospace' : null,
                      color: tokens.starkWhite,
                    ),
                    decoration: InputDecoration(
                      hintText: _hintText,
                      hintStyle: TextStyle(
                        fontFamily: _mode == ImportKeyMode.privateKey
                            ? 'monospace'
                            : null,
                        color: tokens.textDim,
                      ),
                      filled: true,
                      fillColor: tokens.glassFillHover,
                      // Borderless at rest — `fillColor` is the edge. ⚠ The
                      // ERROR tint stays (and `focusedBorder` below): a state
                      // with no other carrier keeps its border.
                      enabledBorder: OutlineInputBorder(
                        borderSide: _errorMessage != null
                            ? BorderSide(color: errorColor.withValues(alpha: 0.5))
                            : BorderSide.none,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              _errorMessage != null ? errorColor : tokens.starkWhite,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 14,
                          color: errorColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(fontSize: 12, color: errorColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.starkWhite,
                        foregroundColor: tokens.background,
                        disabledBackgroundColor:
                            tokens.starkWhite.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleImport,
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PhigitalLoadingWidget(
                                  size: 14,
                                  showShadows: false,
                                  color: tokens.background,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  context.l10n.importImporting,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              context.l10n.keychainImport,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        decoration: BoxDecoration(
          // Fill-only: unselected was transparent + a hairline, so the fill
          // has to take the edge over.
          color: isSelected
              ? tokens.starkWhite.withValues(alpha: 0.14)
              : tokens.glassFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: isSelected ? tokens.starkWhite : tokens.textDim,
            ),
          ),
        ),
      ),
    );
  }
}
