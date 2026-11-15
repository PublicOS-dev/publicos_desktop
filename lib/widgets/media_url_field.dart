import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/quality_toggle.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/image_utils.dart';
import 'package:publicos_desktop/utils/media_picker.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/widgets/error/write_error_dispatcher.dart';

/// URL input + upload button.
///
/// Two interaction paths to set the URL:
///
/// 1. **Type / paste** — user types in the field. Save uses that text as-is.
/// 2. **Upload** — user picks an image. The widget *stages* it (computes
///    a compressed Low version + keeps the HD original), shows a preview
///    card with size + quota info + a Low/HD toggle, then uploads the
///    chosen variant on confirm. The returned URL fills the field.
///
/// X clears whatever's in the field, and if the URL came from our upload
/// it also fires a server DELETE to free quota.
///
/// Lifecycle: the widget owns its own DELETE on the X tap. It does NOT
/// delete on dispose — parents track the uploaded id via [onUploaded] /
/// [onUploadDeleted] callbacks and fire cleanup themselves when the
/// surrounding form is cancelled without saving.
class MediaUrlField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final InputDecoration? decoration;
  final FormFieldValidator<String>? validator;
  final bool enabled;

  /// Fired after a successful upload, with the server-assigned file id.
  /// Parent should remember it so it can DELETE on cancel/dispose.
  final void Function(int fileId)? onUploaded;

  /// Fired after the X clears an uploaded URL (after the widget already
  /// fires the DELETE). Parent should clear its tracked id.
  final VoidCallback? onUploadDeleted;

  /// When true, uploads are unavailable (no SSP / custom feed server
  /// configured). Upload button renders in the dashed-disabled style and
  /// the picker is blocked. URL paste path still works.
  final bool noServer;

  /// False hides the URL row (field + upload button) while idle. The
  /// staged card and errors still show. For hosts that put their own
  /// Upload control elsewhere and call [MediaUrlFieldState.pickImage].
  final bool showUrlRow;

  const MediaUrlField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.decoration,
    this.validator,
    this.enabled = true,
    this.onUploaded,
    this.onUploadDeleted,
    this.noServer = false,
    this.showUrlRow = true,
  });

  @override
  State<MediaUrlField> createState() => MediaUrlFieldState();
}

/// Public so a host can open the picker from its own control: see
/// [pickImage] and [MediaUrlField.showUrlRow].
class MediaUrlFieldState extends State<MediaUrlField> {
  static const double _fieldHeight = 52;

  // Posted-upload state
  int? _uploadedFileId;
  bool _uploading = false;
  bool _deleting = false;
  String? _errorMessage;

  // Staged-upload state — image picked + compressed, not yet sent to server
  _StagedImage? _staged;
  bool _hdMode = false;
  bool _picking = false;

  // Cached quota — lazy-loaded on first stage, refreshed after each upload.
  MediaQuota? _quota;
  bool _loadingQuota = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  /// Opens the picker, then the staged card (preview, Low/HD, quota,
  /// confirm), exactly as the widget's own upload button does.
  Future<void> pickImage() => _pickImage();

  Future<void> _refreshQuota() async {
    setState(() => _loadingQuota = true);
    try {
      final resp = await PublicOSSsp.listMedia();
      if (!mounted) return;
      if (resp.success && resp.data != null) {
        setState(() => _quota = resp.data!.quota);
      }
    } finally {
      if (mounted) setState(() => _loadingQuota = false);
    }
  }

  Future<void> _pickImage() async {
    if (_picking || _uploading || widget.noServer) return;
    final l10n = context.l10n;
    setState(() {
      _picking = true;
      _errorMessage = null;
    });
    try {
      final picks = await pickMedia(
        context: context,
        limit: 1,
        kind: MediaPickerKind.imageOnly,
      );
      if (!mounted) return;
      if (picks.isEmpty) return;
      final pick = picks.first;

      final compressed = await ImageUtils.compressForInline(
        pick.bytes,
        pick.mimeType,
        pick.filename,
      );
      if (!mounted) return;

      setState(() {
        _staged = _StagedImage(
          originalBytes: pick.bytes,
          compressedBytes: compressed.bytes,
          filename: pick.filename,
          // Compress may shift the MIME (heic → jpeg etc); reflect that on
          // the LOW path, keep the original MIME for HD.
          originalMimeType: pick.mimeType,
          compressedMimeType: compressed.mimeType,
        );
        // Default to Low — most callers (avatar / banner / group icon)
        // do not need HD. The toggle is right there if they do.
        _hdMode = false;
      });
      // Load quota in background — non-blocking, the staged card will
      // show a placeholder until it arrives.
      if (_quota == null) _refreshQuota();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage =
          localizedError(l10n, e, fallback: l10n.mediaUrlFieldCouldNotLoadImage));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _cancelStaged() {
    HapticFeedback.lightImpact();
    setState(() {
      _staged = null;
      _hdMode = false;
    });
  }

  Future<void> _confirmStagedUpload() async {
    final staged = _staged;
    if (staged == null || _uploading) return;
    final l10n = context.l10n;

    final bytes = _hdMode ? staged.originalBytes : staged.compressedBytes;
    final filename = staged.filename;
    final mime = _hdMode ? staged.originalMimeType : staged.compressedMimeType;

    setState(() {
      _uploading = true;
      _errorMessage = null;
    });
    try {
      final resp = await PublicOSSsp.uploadMedia(
        bytes,
        filename,
        mimeType: mime,
      );
      if (!mounted) return;
      if (!resp.success || resp.data == null) {
        final msg = resp.error?['message'] as String? ??
            resp.error?['code'] as String? ??
            l10n.mediaUrlFieldUploadFailed;
        setState(() => _errorMessage = msg);
        return;
      }
      final media = resp.data!;
      setState(() {
        _uploadedFileId = media.id;
        widget.controller.text = media.url;
        _staged = null;
        _hdMode = false;
      });
      widget.onUploaded?.call(media.id);
      // Refresh quota so the next upload (or just the next time the
      // user looks) shows the freshly-eaten bytes.
      _refreshQuota();
    } catch (e) {
      if (!mounted) return;
      // Route SSP gate failures to the snackbar dispatcher so the user
      // gets an actionable Treasury affordance; keep the inline error
      // for non-gate failures (network, server 5xx, etc.).
      if (e is SSPGateException) {
        handleWriteError(context, e);
        setState(() => _errorMessage = e.message.isNotEmpty
            ? e.message
            : l10n.mediaUrlFieldUploadBlockedSspGate);
      } else {
        setState(() => _errorMessage =
            localizedError(l10n, e, fallback: l10n.mediaUrlFieldUploadFailed));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _onClearTap() async {
    HapticFeedback.lightImpact();
    final id = _uploadedFileId;
    if (id == null) {
      widget.controller.clear();
      return;
    }
    setState(() => _deleting = true);
    try {
      await PublicOSSsp.deleteMedia(id);
    } finally {
      if (mounted) {
        setState(() {
          _uploadedFileId = null;
          _deleting = false;
          widget.controller.clear();
        });
        widget.onUploadDeleted?.call();
        _refreshQuota();
      }
    }
  }

  InputDecoration _glassDecoration(GlassTokens tokens) {
    return InputDecoration(
      isDense: true,
      labelText: widget.labelText ?? context.l10n.mediaUrlFieldImageUrlLabel,
      hintText: widget.hintText ?? 'https://example.com/image.jpg',
      labelStyle: TextStyle(fontSize: 12, color: tokens.textDim),
      hintStyle: TextStyle(
        fontSize: 13,
        color: tokens.textDim.withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: tokens.glassFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: tokens.borderSubtle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_staged != null)
          _StagedCard(
            tokens: tokens,
            staged: _staged!,
            hdMode: _hdMode,
            uploading: _uploading,
            quota: _quota,
            loadingQuota: _loadingQuota,
            onToggle: (hd) => setState(() => _hdMode = hd),
            onCancel: _uploading ? null : _cancelStaged,
            onUpload: _uploading || !widget.enabled
                ? null
                : _confirmStagedUpload,
          )
        else if (widget.showUrlRow)
          _UrlRow(
            tokens: tokens,
            controller: widget.controller,
            decoration: widget.decoration ?? _glassDecoration(tokens),
            validator: widget.validator,
            enabled: widget.enabled,
            uploadedFileId: _uploadedFileId,
            uploading: _uploading,
            deleting: _deleting,
            picking: _picking,
            noServer: widget.noServer,
            fieldHeight: _fieldHeight,
            onClearTap: _onClearTap,
            onUploadTap: _pickImage,
          ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          _InlineError(
            tokens: tokens,
            message: _errorMessage!,
            onDismiss: () => setState(() => _errorMessage = null),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// URL row (idle + uploaded states)
// ---------------------------------------------------------------------------

class _UrlRow extends StatelessWidget {
  final GlassTokens tokens;
  final TextEditingController controller;
  final InputDecoration decoration;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final int? uploadedFileId;
  final bool uploading;
  final bool deleting;
  final bool picking;
  final bool noServer;
  final double fieldHeight;
  final Future<void> Function() onClearTap;
  final Future<void> Function() onUploadTap;

  const _UrlRow({
    required this.tokens,
    required this.controller,
    required this.decoration,
    required this.validator,
    required this.enabled,
    required this.uploadedFileId,
    required this.uploading,
    required this.deleting,
    required this.picking,
    required this.noServer,
    required this.fieldHeight,
    required this.onClearTap,
    required this.onUploadTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;
    final fieldReadOnly = uploadedFileId != null || uploading;
    final uploadEnabled = enabled &&
        !hasText &&
        !uploading &&
        !deleting &&
        !picking &&
        !noServer;

    final dec = decoration.copyWith(
      suffixIcon: hasText
          ? (deleting
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: tokens.textDim,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: tokens.textDim),
                  tooltip: context.l10n.mediaUrlFieldClearTooltip,
                  splashRadius: 20,
                  onPressed: enabled ? onClearTap : null,
                ))
          : null,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 36,
        minHeight: 36,
      ),
    );

    return SizedBox(
      height: fieldHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              enabled: enabled,
              readOnly: fieldReadOnly,
              keyboardType: TextInputType.url,
              decoration: dec,
              validator: validator,
              style: TextStyle(
                fontSize: 13,
                color: fieldReadOnly ? tokens.textDim : tokens.starkWhite,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _UploadButton(
            tokens: tokens,
            enabled: uploadEnabled,
            uploading: picking,
            dashed: noServer,
            size: fieldHeight,
            onTap: onUploadTap,
          ),
        ],
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final GlassTokens tokens;
  final bool enabled;
  final bool uploading;
  final bool dashed;
  final double size;
  final Future<void> Function() onTap;

  const _UploadButton({
    required this.tokens,
    required this.enabled,
    required this.uploading,
    required this.dashed,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tokens.connectedAccent;
    final color = enabled ? accent : tokens.textDim.withValues(alpha: 0.55);

    final glyph = Center(
      child: uploading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: color,
              ),
            )
          : Icon(Icons.file_upload_outlined, color: color, size: 20),
    );

    if (dashed) {
      // Permanently-unavailable affordance (no SSP / custom server). Dashed
      // border is the system-wide signal.
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: DashedRRectPainter(
            color: tokens.borderSubtle,
            radius: 10,
          ),
          child: glyph,
        ),
      );
    }

    final borderColor =
        enabled ? accent.withValues(alpha: 0.4) : tokens.borderSubtle;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.12),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: glyph,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Staged card
// ---------------------------------------------------------------------------

class _StagedCard extends StatelessWidget {
  final GlassTokens tokens;
  final _StagedImage staged;
  final bool hdMode;
  final bool uploading;
  final MediaQuota? quota;
  final bool loadingQuota;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onCancel;
  final VoidCallback? onUpload;

  const _StagedCard({
    required this.tokens,
    required this.staged,
    required this.hdMode,
    required this.uploading,
    required this.quota,
    required this.loadingQuota,
    required this.onToggle,
    required this.onCancel,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final lowBytes = staged.compressedBytes.length;
    final hdBytes = staged.originalBytes.length;
    final selectedBytes = hdMode ? hdBytes : lowBytes;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  staged.compressedBytes,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staged.filename,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.starkWhite,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _SizeRow(
                      tokens: tokens,
                      lowBytes: lowBytes,
                      hdBytes: hdBytes,
                      hdMode: hdMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              QualityToggle(
                hdMode: hdMode,
                onChanged: uploading ? (_) {} : onToggle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _QuotaLine(
            tokens: tokens,
            quota: quota,
            loadingQuota: loadingQuota,
            uploadBytes: selectedBytes,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StagedActionButton(
                  tokens: tokens,
                  label: context.l10n.actionCancel,
                  icon: Icons.close_rounded,
                  primary: false,
                  onTap: onCancel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _StagedActionButton(
                  tokens: tokens,
                  label: uploading
                      ? context.l10n.mediaUrlFieldUploading
                      : context.l10n.mediaUrlFieldUpload,
                  icon: Icons.cloud_upload_outlined,
                  primary: true,
                  loading: uploading,
                  onTap: onUpload,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  final GlassTokens tokens;
  final int lowBytes;
  final int hdBytes;
  final bool hdMode;

  const _SizeRow({
    required this.tokens,
    required this.lowBytes,
    required this.hdBytes,
    required this.hdMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _sizeChip(context.l10n.mediaUrlFieldLow, _format(lowBytes),
            active: !hdMode),
        const SizedBox(width: 8),
        _sizeChip(context.l10n.mediaUrlFieldHd, _format(hdBytes),
            active: hdMode),
      ],
    );
  }

  Widget _sizeChip(String label, String size, {required bool active}) {
    final color = active ? tokens.connectedAccent : tokens.textDim;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $size',
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 1.2,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _QuotaLine extends StatelessWidget {
  final GlassTokens tokens;
  final MediaQuota? quota;
  final bool loadingQuota;
  final int uploadBytes;

  const _QuotaLine({
    required this.tokens,
    required this.quota,
    required this.loadingQuota,
    required this.uploadBytes,
  });

  @override
  Widget build(BuildContext context) {
    if (quota == null) {
      return Text(
        loadingQuota
            ? context.l10n.mediaUrlFieldCheckingQuota
            : context.l10n.mediaUrlFieldQuotaUnavailable,
        style: TextStyle(fontSize: 11, color: tokens.textDim),
      );
    }
    final q = quota!;
    final usedMb = q.usedMb.toDouble();
    final totalMb = q.totalMb.toDouble();
    final addMb = uploadBytes / 1024 / 1024;
    final afterMb = (usedMb + addMb).clamp(0, totalMb).toDouble();
    final progress = totalMb > 0 ? (afterMb / totalMb).clamp(0.0, 1.0) : 0.0;
    final overflows = (usedMb + addMb) > totalMb;
    final barColor =
        overflows ? tokens.fallbackAccent : tokens.connectedAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.mediaUrlFieldQuotaUsage(
                  usedMb.toStringAsFixed(1),
                  totalMb.toStringAsFixed(0),
                ),
                style: TextStyle(fontSize: 11, color: tokens.textDim),
              ),
            ),
            Text(
              overflows
                  ? context.l10n.mediaUrlFieldQuotaOver(
                      ((usedMb + addMb) - totalMb).toStringAsFixed(1))
                  : context.l10n.mediaUrlFieldQuotaAfter(
                      (usedMb + addMb).toStringAsFixed(1)),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: overflows ? tokens.fallbackAccent : tokens.starkWhite,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: tokens.borderSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

class _StagedActionButton extends StatelessWidget {
  final GlassTokens tokens;
  final String label;
  final IconData icon;
  final bool primary;
  final bool loading;
  final VoidCallback? onTap;

  const _StagedActionButton({
    required this.tokens,
    required this.label,
    required this.icon,
    required this.primary,
    this.loading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final accent = tokens.connectedAccent;
    final base = primary
        ? (disabled ? tokens.textDim.withValues(alpha: 0.4) : accent)
        : tokens.textDim;
    final fillColor =
        primary && !disabled ? accent.withValues(alpha: 0.12) : tokens.glassFill;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: primary && !disabled
                ? accent.withValues(alpha: 0.5)
                : tokens.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: base,
                ),
              )
            else
              Icon(icon, size: 14, color: base),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: base,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inline error pill
// ---------------------------------------------------------------------------

class _InlineError extends StatelessWidget {
  final GlassTokens tokens;
  final String message;
  final VoidCallback onDismiss;

  const _InlineError({
    required this.tokens,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tokens.fallbackAccent;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: accent),
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
          GestureDetector(
            onTap: onDismiss,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: tokens.textDim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _format(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)}MB';
}

// ---------------------------------------------------------------------------
// Local staged-upload result type — owns both the picker output and the
// compressor output side-by-side, since the LOW/HD toggle picks between them.
// ---------------------------------------------------------------------------

class _StagedImage {
  final Uint8List originalBytes;
  final Uint8List compressedBytes;
  final String filename;
  final String originalMimeType;
  final String compressedMimeType;

  const _StagedImage({
    required this.originalBytes,
    required this.compressedBytes,
    required this.filename,
    required this.originalMimeType,
    required this.compressedMimeType,
  });
}
