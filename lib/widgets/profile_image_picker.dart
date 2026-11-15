import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/media_url_field.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

/// Inline image picker — preview box on top, no-server warning below,
/// then a [MediaUrlField] for paste/upload. Designed to live both inside
/// a bottom sheet (profile avatar / banner) and inline in a form
/// (create-group wizard).
///
/// The widget does NOT render a Save/Commit button — the surrounding
/// form decides when to persist the URL. Uploaded-file cleanup on
/// cancel is still the parent's responsibility (track via [onUploaded]
/// / [onUploadDeleted] and fire [PublicOSSsp.deleteMedia] from the
/// parent's dispose if the form wasn't saved).
class ProfileImagePicker extends StatefulWidget {
  final TextEditingController controller;

  /// Square (avatar) vs wide (banner) framing for the preview box.
  final bool isAvatar;

  /// Optional fallback shown in the preview when the controller is
  /// empty — typically the current on-chain image URL, so the user sees
  /// "what's set today" before they edit.
  final String? currentImageUrl;

  final bool enabled;

  final void Function(int fileId)? onUploaded;
  final VoidCallback? onUploadDeleted;

  /// Rendered inside the preview box when there's nothing to show
  /// (controller empty AND [currentImageUrl] missing/invalid). Defaults
  /// to a generic icon + "No image yet" label if null.
  final Widget? emptyState;

  /// Message shown in the dismissable no-server banner when the user
  /// hasn't set an SSP. Should mention what they're trying to upload
  /// ("profile picture", "group image", etc.) so the warning reads in
  /// context.
  final String noServerMessage;

  /// SharedPreferences key the warning's dismissed flag persists under.
  /// Distinct keys per surface so dismissing on profile doesn't hide
  /// the warning on create-group.
  final String dismissedWarningPrefsKey;

  /// When false, the internal preview box is omitted — the host renders its
  /// own (e.g. the avatar sheet hoists a single unified preview above the
  /// mode toggle). Defaults to true so create-group / banner are unaffected.
  final bool showPreview;

  const ProfileImagePicker({
    super.key,
    required this.controller,
    required this.isAvatar,
    required this.noServerMessage,
    required this.dismissedWarningPrefsKey,
    this.currentImageUrl,
    this.enabled = true,
    this.onUploaded,
    this.onUploadDeleted,
    this.emptyState,
    this.showPreview = true,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  // null = still resolving. true = SSP / custom server available. false =
  // no server — dashed upload button + dismissable banner.
  bool? _hasServer;
  bool _noServerWarningDismissed = false;

  bool get _hasValidUrl => _isValidUrl(widget.controller.text);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onUrlChanged);
    _loadServerState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onUrlChanged);
    super.dispose();
  }

  void _onUrlChanged() {
    if (mounted) setState(() {});
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return Uri.tryParse(url)?.hasAbsolutePath ?? false;
  }

  Future<void> _loadServerState() async {
    final results = await Future.wait<dynamic>([
      PublicOSSsp.getActiveFeedServerUrl(),
      SharedPreferences.getInstance(),
    ]);
    if (!mounted) return;
    final activeUrl = results[0] as String?;
    final prefs = results[1] as SharedPreferences;
    setState(() {
      _hasServer = activeUrl != null;
      _noServerWarningDismissed =
          prefs.getBool(widget.dismissedWarningPrefsKey) ?? false;
    });
  }

  Future<void> _dismissNoServerWarning() async {
    setState(() => _noServerWarningDismissed = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(widget.dismissedWarningPrefsKey, true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final previewUrl =
        _hasValidUrl ? widget.controller.text : widget.currentImageUrl;
    final hasValidPreview = previewUrl != null && _isValidUrl(previewUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showPreview) ...[
          ProfileImagePreviewBox(
            tokens: tokens,
            isAvatar: widget.isAvatar,
            previewUrl: hasValidPreview ? previewUrl : null,
            emptyState: widget.emptyState,
          ),
          const SizedBox(height: 12),
        ],
        if (_hasServer == false && !_noServerWarningDismissed) ...[
          _NoServerWarning(
            tokens: tokens,
            message: widget.noServerMessage,
            onDismiss: _dismissNoServerWarning,
          ),
          const SizedBox(height: 12),
        ],
        MediaUrlField(
          controller: widget.controller,
          enabled: widget.enabled,
          noServer: _hasServer == false,
          onUploaded: widget.onUploaded,
          onUploadDeleted: widget.onUploadDeleted,
        ),
      ],
    );
  }
}

/// Square (avatar) / wide (banner) image preview box — ZeroCachedImage with a
/// spinner placeholder and broken-image error state, or [emptyState] when
/// [previewUrl] is null. Public so hosts can hoist a single preview above their
/// own controls (the avatar sheet renders this for its Image mode, above the
/// Image/Ethereum/Solana toggle).
class ProfileImagePreviewBox extends StatelessWidget {
  final GlassTokens tokens;
  final bool isAvatar;
  final String? previewUrl;

  /// Shown when [previewUrl] is null. Defaults to the generic icon + "No image
  /// yet" label keyed off [isAvatar].
  final Widget? emptyState;

  const ProfileImagePreviewBox({
    super.key,
    required this.tokens,
    required this.isAvatar,
    required this.previewUrl,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    final aspectRatio = isAvatar ? 1.0 : 3.0;
    final radius = isAvatar ? 16.0 : 14.0;
    final empty = emptyState ??
        _DefaultEmptyState(
          tokens: tokens,
          icon: isAvatar
              ? Icons.account_circle_rounded
              : Icons.panorama_rounded,
        );

    final box = AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: previewUrl == null
            ? empty
            : ZeroCachedImage(
                imageUrl: previewUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) => Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: tokens.connectedAccent,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => _ErrorState(tokens: tokens),
              ),
      ),
    );

    // Avatar preview is shown at 60% width, centered; banner stays full-width.
    if (!isAvatar) return box;
    return Center(
      child: FractionallySizedBox(widthFactor: 0.6, child: box),
    );
  }
}

class _DefaultEmptyState extends StatelessWidget {
  final GlassTokens tokens;
  final IconData icon;

  const _DefaultEmptyState({required this.tokens, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: tokens.textDim.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            'No image yet',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: tokens.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final GlassTokens tokens;

  const _ErrorState({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: tokens.fallbackAccent.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 8),
          Text(
            'Cannot load image',
            style: TextStyle(
              fontSize: 12,
              color: tokens.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoServerWarning extends StatelessWidget {
  final GlassTokens tokens;
  final String message;
  final VoidCallback onDismiss;

  const _NoServerWarning({
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
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onDismiss();
            },
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
