import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/media_url_field.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/profile/ssp_media_grid.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/fullscreen_overlay.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

/// Glass-dark sheet for the profile background (`_osux_profile_background_url_`).
///
/// One selection, three ways to make it — the card editor's image picker
/// (`create_record_page._buildImagePage`) plus a direct link:
/// the **None** tile, the **Upload** tile (MediaUrlField staging → the
/// user's own SSP), a tile from their uploads, or a pasted URL. The preview is
/// pinned above and wears the same 30% scrim the profile paints over it.
///
/// [onSave] gets the chosen URL, or `''` for None — the host deletes the
/// record rather than writing an empty value. The sheet awaits it behind the
/// chain-write overlay, then pops.
Future<void> showEditProfileBackgroundSheet(
  BuildContext context, {
  String? currentUrl,
  required Future<void> Function(String url) onSave,
}) {
  // DELTA (desktop): sheet -> centered glass dialog. Wide enough for the
  // uploads grid under the pinned preview.
  return showGlassSheetDialog<void>(
    context: context,
    width: DialogWidth.xl,
    builder: (_) => EditProfileBackgroundSheet(
      currentBackgroundImageUrl: currentUrl,
      onSave: onSave,
    ),
  );
}

class EditProfileBackgroundSheet extends StatefulWidget {
  final String? currentBackgroundImageUrl;
  final Future<void> Function(String url) onSave;

  const EditProfileBackgroundSheet({
    super.key,
    this.currentBackgroundImageUrl,
    required this.onSave,
  });

  @override
  State<EditProfileBackgroundSheet> createState() =>
      _EditProfileBackgroundSheetState();
}

class _EditProfileBackgroundSheetState
    extends State<EditProfileBackgroundSheet> {
  /// The selection. Empty = None. Every path (tile, upload, paste) writes here.
  late final TextEditingController _urlController;

  /// MediaUrlField's own controller — its URL row is hidden, so this only
  /// ever receives a finished upload, which is then adopted into [_urlController].
  final TextEditingController _uploadUrlController = TextEditingController();
  final GlobalKey<MediaUrlFieldState> _uploadFieldKey = GlobalKey();
  final GlobalKey<SspMediaGridState> _uploadsGridKey = GlobalKey();

  bool? _hasServer;
  int? _pendingUploadId;
  bool _saving = false;
  bool _saved = false;

  String get _initial => widget.currentBackgroundImageUrl?.trim() ?? '';
  String get _selection => _urlController.text.trim();

  bool get _selectionValid {
    final s = _selection;
    if (s.isEmpty) return true; // None
    final uri = Uri.tryParse(s);
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  bool get _canSave => !_saving && _selectionValid && _selection != _initial;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _initial);
    _urlController.addListener(_onSelectionChanged);
    PublicOSSsp.getActiveFeedServerUrl().then((url) {
      if (mounted) setState(() => _hasServer = url != null);
    }).catchError((_) {
      if (mounted) setState(() => _hasServer = false);
    });
  }

  @override
  void dispose() {
    _urlController.removeListener(_onSelectionChanged);
    _urlController.dispose();
    _uploadUrlController.dispose();
    final pending = _pendingUploadId;
    if (pending != null && !_saved) {
      // Fire and forget — the sheet is gone, nothing to wait for.
      PublicOSSsp.deleteMedia(pending);
    }
    super.dispose();
  }

  void _onSelectionChanged() {
    if (mounted) setState(() {});
  }

  void _select(String? url) {
    _urlController.text = url ?? '';
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final overlay = FullscreenOverlay.showTransaction(
        context, l10n.editProfileBackgroundSheetSavingToChain);
    setState(() => _saving = true);
    try {
      await widget.onSave(_selection);
      _saved = true;
      overlay.dismiss();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // The host reports its own failures (snackbar); just unlock.
      overlay.dismiss();
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DraggableScrollableSheet(
        // DELTA (desktop): inside a centered dialog there is no screen edge to
        // drag against, so the sheet fills its dialog exactly.
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
                _Header(
                  title: l10n.editProfileBackgroundSheetTitle,
                  tokens: tokens,
                  onClose: _saving ? null : () => Navigator.of(context).pop(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                  child: _buildPreview(tokens),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: _buildBody(tokens),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: tokens.borderSubtle, height: 1),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: SystemAppActionButton(
                      label: _selection.isEmpty
                          ? l10n.editProfileBackgroundSheetRemove
                          : l10n.editProfileBackgroundSheetSave,
                      icon: _selection.isEmpty
                          ? Icons.hide_image_outlined
                          : Icons.check_rounded,
                      onTap: _canSave ? _save : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreview(GlassTokens tokens) {
    final radius = BorderRadius.circular(12);
    final url = _selection;
    final Widget inner;
    if (url.isEmpty || !_selectionValid) {
      inner = Container(
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: radius,
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wallpaper_rounded,
                  size: 30, color: tokens.textDim.withValues(alpha: 0.5)),
              const SizedBox(height: 6),
              Text(
                context.l10n.editProfileBackgroundSheetEmpty,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 11,
                  letterSpacing: 0.6,
                  color: tokens.textDim,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      inner = ClipRRect(
        borderRadius: radius,
        child: Container(
          color: tokens.glassFill,
          // Same scrim the profile paints over the live background, so the
          // preview is what the page will actually look like.
          foregroundDecoration:
              BoxDecoration(color: Colors.black.withValues(alpha: 0.3)),
          child: ZeroCachedImage(
            key: ValueKey(url),
            imageUrl: url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, __) => const Center(
                child: PhigitalLoadingWidget(size: 22, showShadows: false)),
            errorWidget: (_, __, ___) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined,
                      size: 28,
                      color: tokens.fallbackAccent.withValues(alpha: 0.7)),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.editProfileBackgroundSheetUnableToLoad,
                    style: TextStyle(fontSize: 11, color: tokens.textDim),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.72,
        child: AspectRatio(aspectRatio: 16 / 9, child: inner),
      ),
    );
  }

  Widget _buildBody(GlassTokens tokens) {
    final l10n = context.l10n;
    final canUpload = _hasServer == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasServer == false) ...[
          _NoServerNote(
              tokens: tokens,
              message: l10n.editProfileBackgroundSheetNoServer),
          const SizedBox(height: 10),
        ],
        // Upload staging is MediaUrlField's; the Upload tile opens it and its
        // URL row stays hidden (card editor pattern). Above the grid, so the
        // staging card shows next to the tile that opened it.
        MediaUrlField(
          key: _uploadFieldKey,
          controller: _uploadUrlController,
          showUrlRow: false,
          noServer: !canUpload,
          enabled: !_saving,
          onUploaded: (id) {
            _pendingUploadId = id;
            _uploadsGridKey.currentState?.reload();
            _select(_uploadUrlController.text.trim());
          },
          onUploadDeleted: () => _pendingUploadId = null,
        ),
        const SizedBox(height: 8),
        SspMediaGrid(
          key: _uploadsGridKey,
          selectedUrl: _selection.isEmpty ? null : _selection,
          enabled: !_saving,
          onSelect: (file) => _select(file.url),
          leading: [
            SspMediaGridActionTile(
              icon: Icons.block_rounded,
              label: l10n.editProfileBackgroundSheetNone,
              selected: _selection.isEmpty,
              enabled: !_saving,
              onTap: () => _select(null),
            ),
            SspMediaGridActionTile(
              icon: Icons.add_rounded,
              label: l10n.editProfileBackgroundSheetUpload,
              enabled: canUpload && !_saving,
              onTap: () => _uploadFieldKey.currentState?.pickImage(),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          l10n.editProfileBackgroundSheetUrlLabel.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: tokens.textDim,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _urlController,
          enabled: !_saving,
          keyboardType: TextInputType.url,
          autocorrect: false,
          style: TextStyle(fontSize: 13, color: tokens.starkWhite),
          decoration: InputDecoration(
            isDense: true,
            hintText: l10n.editProfileBackgroundSheetUrlHint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: tokens.textDim.withValues(alpha: 0.6),
            ),
            errorText: _selectionValid
                ? null
                : l10n.editProfileBackgroundSheetInvalidUrl,
            filled: true,
            fillColor: tokens.glassFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            suffixIcon: _selection.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 16, color: tokens.textDim),
                    onPressed: _saving ? null : () => _select(null),
                  ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: tokens.connectedAccent.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: tokens.fallbackAccent.withValues(alpha: 0.6)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: tokens.fallbackAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final GlassTokens tokens;
  final VoidCallback? onClose;

  const _Header({
    required this.title,
    required this.tokens,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tokens.connectedAccent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: tokens.glassFill,
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.wallpaper_rounded, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: tokens.starkWhite,
              ),
            ),
          ),
          IconButton(
            tooltip: context.l10n.editProfileBackgroundSheetClose,
            icon: Icon(Icons.close_rounded, color: tokens.textDim, size: 20),
            onPressed: onClose == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onClose!();
                  },
          ),
        ],
      ),
    );
  }
}

class _NoServerNote extends StatelessWidget {
  final GlassTokens tokens;
  final String message;

  const _NoServerNote({required this.tokens, required this.message});

  @override
  Widget build(BuildContext context) {
    final accent = tokens.fallbackAccent;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_rounded, size: 16, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: tokens.starkWhite,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
