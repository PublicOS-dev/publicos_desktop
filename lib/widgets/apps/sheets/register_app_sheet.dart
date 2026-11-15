import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// Glass bottom sheet that registers a new app (3-step form) or edits an
/// existing one. Ported from publicos_client's
/// `components/apps/register_app_bottom_sheet.dart` — logic is verbatim
/// (registerApp → 3s settle wait → setAppPointer fan-out → local cache),
/// only the chrome is reskinned to glass tokens.
Future<void> showRegisterAppSheet(
  BuildContext context, {
  VoidCallback? onSuccess,
  AppBookmark? existingApp,
}) {
  // DELTA (desktop): bottom sheet → centred glass dialog, the shared shell.
  return showGlassSheetDialog(
    context: context,
    width: DialogWidth.xl,
    builder: (_) => _RegisterAppSheet(
      onSuccess: onSuccess,
      existingApp: existingApp,
    ),
  );
}

class _RegisterAppSheet extends StatefulWidget {
  final VoidCallback? onSuccess;
  final AppBookmark? existingApp;

  const _RegisterAppSheet({this.onSuccess, this.existingApp});

  @override
  State<_RegisterAppSheet> createState() => _RegisterAppSheetState();
}

class _RegisterAppSheetState extends State<_RegisterAppSheet> {
  final _formKey = GlobalKey<FormState>();
  final _appNameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _iconUrlCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _warningsCtrl = TextEditingController();
  final _categoryOneCtrl = TextEditingController();
  final _categoryTwoCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _appStoreLinkCtrl = TextEditingController();
  final _playStoreLinkCtrl = TextEditingController();
  final _apkDownloadCtrl = TextEditingController();
  final _ipaDownloadCtrl = TextEditingController();

  bool _isLoading = false;
  int _currentStep = 0;
  bool get _isEditMode => widget.existingApp != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateFromExisting();
    }
  }

  void _populateFromExisting() {
    final app = widget.existingApp!;
    _appNameCtrl.text = app.appName;
    _displayNameCtrl.text = app.displayName;
    _iconUrlCtrl.text = app.icon ?? '';
    _descriptionCtrl.text = app.description ?? '';
    _warningsCtrl.text = app.getPointer('warnings')?.value ?? '';
    _categoryOneCtrl.text = app.getPointer('category_one')?.value ?? '';
    _categoryTwoCtrl.text = app.getPointer('category_two')?.value ?? '';
    _urlCtrl.text = app.url ?? '';
    _appStoreLinkCtrl.text = app.getPointer('appstore_link')?.value ?? '';
    _playStoreLinkCtrl.text = app.getPointer('playstore_link')?.value ?? '';
    _apkDownloadCtrl.text = app.getPointer('apk_download')?.value ?? '';
    _ipaDownloadCtrl.text = app.getPointer('ipa_download')?.value ?? '';
  }

  @override
  void dispose() {
    _appNameCtrl.dispose();
    _displayNameCtrl.dispose();
    _iconUrlCtrl.dispose();
    _descriptionCtrl.dispose();
    _warningsCtrl.dispose();
    _categoryOneCtrl.dispose();
    _categoryTwoCtrl.dispose();
    _urlCtrl.dispose();
    _appStoreLinkCtrl.dispose();
    _playStoreLinkCtrl.dispose();
    _apkDownloadCtrl.dispose();
    _ipaDownloadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return DraggableScrollableSheet(
      // DELTA (desktop): fill the dialog.
      initialChildSize: 1.0,
      minChildSize: 1.0,
      maxChildSize: 1.0,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            // DELTA (desktop): all four corners — it is a dialog now.
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(tokens: tokens, isEdit: _isEditMode),
                Container(height: 1, color: tokens.borderSubtle),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StepIndicator(
                            tokens: tokens,
                            currentStep: _currentStep,
                          ),
                          const SizedBox(height: 24),
                          if (_currentStep == 0) _buildBasicStep(tokens),
                          if (_currentStep == 1) _buildMetadataStep(tokens),
                          if (_currentStep == 2) _buildLinksStep(tokens),
                        ],
                      ),
                    ),
                  ),
                ),
                _ActionBar(
                  tokens: tokens,
                  currentStep: _currentStep,
                  isEdit: _isEditMode,
                  isLoading: _isLoading,
                  onBack: _isLoading
                      ? null
                      : () => setState(() => _currentStep--),
                  onNext: _isLoading ? null : _handleNext,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Step builders
  // ---------------------------------------------------------------------------

  Widget _buildBasicStep(GlassTokens tokens) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(tokens: tokens, text: l10n.registerAppSheetBasicInfo),
        const SizedBox(height: 16),
        _GlassTextField(
          tokens: tokens,
          controller: _appNameCtrl,
          label: l10n.registerAppSheetAppNameLabel,
          hint: l10n.registerAppSheetAppNameHint,
          helper: _isEditMode
              ? l10n.registerAppSheetAppNameHelperLocked
              : l10n.registerAppSheetAppNameHelper,
          enabled: !_isEditMode,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9\-_]')),
          ],
          validator: (v) {
            if (v == null || v.isEmpty) {
              return l10n.registerAppSheetAppNameRequired;
            }
            if (v.length < 3) {
              return l10n.registerAppSheetAppNameTooShort;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _GlassTextField(
          tokens: tokens,
          controller: _displayNameCtrl,
          label: l10n.registerAppSheetDisplayNameLabel,
          hint: l10n.registerAppSheetDisplayNameHint,
          helper: l10n.registerAppSheetDisplayNameHelper,
          validator: (v) {
            if (v == null || v.isEmpty) {
              return l10n.registerAppSheetDisplayNameRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _GlassTextField(
          tokens: tokens,
          controller: _iconUrlCtrl,
          label: l10n.registerAppSheetIconUrlLabel,
          hint: 'https://example.com/icon.png',
          helper: l10n.registerAppSheetIconUrlHelper,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildMetadataStep(GlassTokens tokens) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(tokens: tokens, text: l10n.registerAppSheetAppDetails),
        const SizedBox(height: 16),
        _GlassTextField(
          tokens: tokens,
          controller: _descriptionCtrl,
          label: l10n.registerAppSheetDescriptionLabel,
          hint: l10n.registerAppSheetDescriptionHint,
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        _GlassTextField(
          tokens: tokens,
          controller: _warningsCtrl,
          label: l10n.registerAppSheetWarningsLabel,
          hint: l10n.registerAppSheetWarningsHint,
          helper: l10n.registerAppSheetWarningsHelper,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _GlassTextField(
                tokens: tokens,
                controller: _categoryOneCtrl,
                label: l10n.registerAppSheetCategoryOneLabel,
                hint: l10n.registerAppSheetCategoryOneHint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassTextField(
                tokens: tokens,
                controller: _categoryTwoCtrl,
                label: l10n.registerAppSheetCategoryTwoLabel,
                hint: l10n.registerAppSheetCategoryTwoHint,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinksStep(GlassTokens tokens) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(tokens: tokens, text: l10n.registerAppSheetAppLinks),
        const SizedBox(height: 8),
        Text(
          l10n.registerAppSheetLinksSubtitle,
          style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        _GlassTextField(
          tokens: tokens,
          controller: _urlCtrl,
          label: l10n.registerAppSheetWebUrlLabel,
          hint: 'https://myapp.com',
          helper: l10n.registerAppSheetWebUrlHelper,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        _GlassTextField(
          tokens: tokens,
          controller: _appStoreLinkCtrl,
          label: l10n.registerAppSheetAppStoreLabel,
          hint: 'https://apps.apple.com/...',
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        _GlassTextField(
          tokens: tokens,
          controller: _playStoreLinkCtrl,
          label: l10n.registerAppSheetPlayStoreLabel,
          hint: 'https://play.google.com/...',
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        _GlassTextField(
          tokens: tokens,
          controller: _apkDownloadCtrl,
          label: l10n.registerAppSheetApkUrlLabel,
          hint: l10n.registerAppSheetApkUrlHint,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        _GlassTextField(
          tokens: tokens,
          controller: _ipaDownloadCtrl,
          label: l10n.registerAppSheetIpaUrlLabel,
          hint: l10n.registerAppSheetIpaUrlHint,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step navigation + submit — verbatim port of publicos_client logic
  // ---------------------------------------------------------------------------

  void _handleNext() {
    if (_currentStep == 0) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() => _currentStep = 1);
      }
    } else if (_currentStep == 1) {
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      _registerApp();
    }
  }

  Future<void> _registerApp() async {
    final l10n = context.l10n;
    setState(() => _isLoading = true);

    try {
      if (!_isEditMode) {
        // Step 1: Register the app (only in create mode)
        final success = await PublicOSAppRegistry.registerApp(
          _appNameCtrl.text.trim(),
          _displayNameCtrl.text.trim(),
        );
        if (!success) throw Exception('Failed to register app');

        // Step 2: 3-second settle wait so the register tx is mined before
        // we start writing pointers. Matches publicos_client:621 — without
        // this, setAppPointer can fan out onto a state where the app
        // doesn't exist yet and every pointer write silently fails.
        await Future.delayed(const Duration(seconds: 3));
      } else {
        // Edit mode: update display name first if it changed.
        if (_displayNameCtrl.text.trim() !=
            widget.existingApp!.displayName) {
          await PublicOSAppRegistry.updateAppDisplayName(
            _appNameCtrl.text.trim(),
            _displayNameCtrl.text.trim(),
          );
          await Future.delayed(const Duration(seconds: 3));
        }
      }

      // Step 3: Collect non-empty pointers.
      final pointers = <Map<String, String>>[];
      void add(String key, TextEditingController c) {
        if (c.text.trim().isNotEmpty) {
          pointers.add({'type': key, 'value': c.text.trim()});
        }
      }

      add('icon', _iconUrlCtrl);
      add('description', _descriptionCtrl);
      add('warnings', _warningsCtrl);
      add('category_one', _categoryOneCtrl);
      add('category_two', _categoryTwoCtrl);
      add('url', _urlCtrl);
      add('appstore_link', _appStoreLinkCtrl);
      add('playstore_link', _playStoreLinkCtrl);
      add('apk_download', _apkDownloadCtrl);
      add('ipa_download', _ipaDownloadCtrl);

      int successCount = 0;
      for (final pointer in pointers) {
        final ok = await PublicOSAppRegistry.setAppPointer(
          _appNameCtrl.text.trim(),
          pointer['type']!,
          pointer['value']!,
        );
        if (ok) successCount++;
      }

      // Cache locally for instant display.
      try {
        final accountAddress =
            await PublicOSAccounts.getSelectedAccountAddress();
        if (accountAddress != null) {
          final appPointers = pointers
              .map((p) => AppPointer(type: p['type']!, value: p['value']!))
              .toList();
          final appToCache = AppBookmark(
            appName: _appNameCtrl.text.trim(),
            displayName: _displayNameCtrl.text.trim(),
            ownerAccountAddress: accountAddress,
            pointers: appPointers,
          );
          await PublicOSAppRegistry.bookmarkApp(appToCache);
        }
      } catch (_) {
        // Non-fatal; chain is authoritative.
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? l10n.registerAppSheetUpdatedSnack(
                      _displayNameCtrl.text, successCount)
                  : l10n.registerAppSheetRegisteredSnack(
                      _displayNameCtrl.text, successCount),
            ),
          ),
        );
        Navigator.pop(context);
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        final errText = localizedError(l10n, PublicOS.lastError ?? e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? l10n.registerAppSheetUpdateFailed(errText)
                  : l10n.registerAppSheetRegisterFailed(errText),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Leaf widgets
// ---------------------------------------------------------------------------

// DELTA (desktop): `_DragHandle` dropped — nothing to drag in a dialog.

class _Header extends StatelessWidget {
  final GlassTokens tokens;
  final bool isEdit;
  const _Header({required this.tokens, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.connectedAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: tokens.connectedAccent.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Icon(
              isEdit
                  ? Icons.edit_rounded
                  : Icons.app_registration_rounded,
              color: tokens.connectedAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isEdit
                  ? context.l10n.registerAppSheetEditApp
                  : context.l10n.registerAppSheetRegisterApp,
              style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final GlassTokens tokens;
  final int currentStep;

  const _StepIndicator({required this.tokens, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(0, context.l10n.registerAppSheetStepBasic),
        _line(currentStep >= 1),
        _dot(1, context.l10n.registerAppSheetStepMetadata),
        _line(currentStep >= 2),
        _dot(2, context.l10n.registerAppSheetStepLinks),
      ],
    );
  }

  Widget _line(bool filled) {
    return Expanded(
      child: Container(
        height: 2,
        color: filled ? tokens.connectedAccent : tokens.borderSubtle,
      ),
    );
  }

  Widget _dot(int step, String label) {
    final isActive = currentStep >= step;
    final isCurrent = currentStep == step;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive
                ? tokens.connectedAccent.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? tokens.connectedAccent : tokens.borderMedium,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                color: isActive ? tokens.connectedAccent : tokens.textDim,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
            color: isActive ? tokens.connectedAccent : tokens.textDim,
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final GlassTokens tokens;
  final String text;

  const _SectionTitle({required this.tokens, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
        color: tokens.starkWhite,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final GlassTokens tokens;
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _GlassTextField({
    required this.tokens,
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
        color: enabled ? tokens.starkWhite : tokens.textDim,
        fontSize: 14,
      ),
      cursorColor: tokens.starkWhite,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        labelStyle: TextStyle(
                      fontFamily: 'SpaceGrotesk',
          color: tokens.textDim,
          fontSize: 13,
        ),
        hintStyle: TextStyle(
                      fontFamily: 'SpaceGrotesk',
          color: tokens.textDim.withValues(alpha: 0.6),
          fontSize: 13,
        ),
        helperStyle: TextStyle(
                      fontFamily: 'SpaceGrotesk',
          color: tokens.textDim,
          fontSize: 11,
        ),
        filled: true,
        fillColor: tokens.glassFill,
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
          borderSide:
              BorderSide(color: tokens.connectedAccent, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: tokens.borderSubtle.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.fallbackAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.fallbackAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final GlassTokens tokens;
  final int currentStep;
  final bool isEdit;
  final bool isLoading;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  const _ActionBar({
    required this.tokens,
    required this.currentStep,
    required this.isEdit,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        border: Border(
          top: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (currentStep > 0) ...[
            Expanded(
              child: _SecondaryButton(
                tokens: tokens,
                label: context.l10n.registerAppSheetBack,
                icon: Icons.arrow_back_rounded,
                onTap: onBack,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: _PrimaryButton(
              tokens: tokens,
              label: currentStep == 2
                  ? (isEdit
                      ? context.l10n.registerAppSheetUpdateApp
                      : context.l10n.registerAppSheetRegisterApp)
                  : context.l10n.registerAppSheetNext,
              icon: currentStep == 2
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
              isLoading: isLoading,
              onTap: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final GlassTokens tokens;
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.tokens,
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = enabled
        ? tokens.connectedAccent
        : tokens.connectedAccent.withValues(alpha: 0.4);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: tokens.connectedAccent.withValues(alpha: enabled ? 0.14 : 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: tokens.connectedAccent.withValues(alpha: enabled ? 0.6 : 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: fg,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                color: fg,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final GlassTokens tokens;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _SecondaryButton({
    required this.tokens,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = enabled ? tokens.starkWhite : tokens.textDim;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                color: fg,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
