import 'package:flutter/material.dart';
import '../../contact_banner.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';

/// Glass bottom sheet with app metadata + launch buttons + bookmark toggle.
///
/// Ported from publicos_client's `components/apps/app_profile_bottom_sheet.dart`.
/// Logic matches 1:1; the visual layer is reskinned to glass tokens and
/// the "open in browser" / store / apk / ipa launch actions are snackbar
/// stubs (no in-app browser, no url_launcher dep yet).
///
/// The owner row navigates to a snackbar stub too — ProfilePage isn't ported.
Future<void> showAppProfileSheet(
  BuildContext context, {
  required AppBookmark app,
  required Contact? ownerContact,
  VoidCallback? onEdit,
  VoidCallback? onRemoveBookmark,
  VoidCallback? onAddBookmark,
}) {
  // DELTA (desktop): bottom sheet → centred glass dialog, the shared shell.
  return showGlassSheetDialog(
    context: context,
    width: DialogWidth.xl,
    builder: (_) => _AppProfileSheet(
      app: app,
      ownerContact: ownerContact,
      onEdit: onEdit,
      onRemoveBookmark: onRemoveBookmark,
      onAddBookmark: onAddBookmark,
    ),
  );
}

class _AppProfileSheet extends StatelessWidget {
  final AppBookmark app;
  final Contact? ownerContact;
  final VoidCallback? onEdit;
  final VoidCallback? onRemoveBookmark;
  final VoidCallback? onAddBookmark;

  const _AppProfileSheet({
    required this.app,
    required this.ownerContact,
    required this.onEdit,
    required this.onRemoveBookmark,
    required this.onAddBookmark,
  });

  bool get _isOwnedByCurrentUser {
    final currentHex = PublicOS.myPublicosAddress;
    if (currentHex == null) return false;
    return currentHex.toLowerCase() ==
        app.ownerAccountAddress.eip55With0x.toLowerCase();
  }

  bool get _hasCategories =>
      (app.getPointer('category_one') != null &&
          app.getPointer('category_one')!.value.isNotEmpty) ||
      (app.getPointer('category_two') != null &&
          app.getPointer('category_two')!.value.isNotEmpty);

  bool get _hasWarnings =>
      app.getPointer('warnings') != null &&
      app.getPointer('warnings')!.value.isNotEmpty;

  bool get _hasAppStoreLink =>
      app.getPointer('appstore_link') != null &&
      app.getPointer('appstore_link')!.value.isNotEmpty;

  bool get _hasPlayStoreLink =>
      app.getPointer('playstore_link') != null &&
      app.getPointer('playstore_link')!.value.isNotEmpty;

  bool get _hasApkDownload =>
      app.getPointer('apk_download') != null &&
      app.getPointer('apk_download')!.value.isNotEmpty;

  bool get _hasIpaDownload =>
      app.getPointer('ipa_download') != null &&
      app.getPointer('ipa_download')!.value.isNotEmpty;

  bool get _hasWebApp => app.url != null && app.url!.isNotEmpty;
  bool get _hasIOS => _hasAppStoreLink || _hasIpaDownload;
  bool get _hasAndroid => _hasPlayStoreLink || _hasApkDownload;
  bool get _hasAnyPlatform => _hasWebApp || _hasIOS || _hasAndroid;

  String _formatAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  void _launchApp(BuildContext context) {
    // Same refusal as the tile tap: an app with no url has nothing to open, and
    // navigating anyway lands on a crash rather than an empty state.
    if (!_hasWebApp) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.appsViewAppMisconfigured(app.displayName),
            style: const TextStyle(fontFamily: 'SpaceGrotesk'),
          ),
          duration: const Duration(milliseconds: 2600),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.pop(context);
    AppNav.toApp(context, app.ownerAccountAddress.eip55With0x,
        appName: app.appName, app: app);
  }

  void _openOwnerProfile(BuildContext context) {
    Navigator.pop(context);
    AppNav.toProfile(context, app.ownerAccountAddress.eip55With0x);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    const double bannerHeight = 120;
    const double avatarSize = 72;
    const double avatarOverlap = 36;

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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Banner + overlapping avatar
                  SizedBox(
                    height: bannerHeight + avatarOverlap,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Banner image
                        SizedBox(
                          height: bannerHeight,
                          width: double.infinity,
                          child: ContactBanner(
                            contact: ownerContact,
                            fallback: Container(
                              color: tokens.connectedAccent.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                        ),
                        // Top-gradient scrim for readability
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 56,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.black.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // DELTA (desktop): handle bar dropped — dialog.
                        // Edit button — owner only, top-right
                        if (_isOwnedByCurrentUser && onEdit != null)
                          Positioned(
                            top: 10,
                            right: 12,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                                onEdit!();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: tokens.surfaceDeep
                                      .withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: tokens.fallbackAccent
                                        .withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_rounded,
                                      size: 14,
                                      color: tokens.fallbackAccent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      context.l10n.appProfileSheetEdit,
                                      style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: tokens.starkWhite,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // App icon — overlaps banner bottom
                        Positioned(
                          left: 20,
                          bottom: 0,
                          child: Container(
                            width: avatarSize,
                            height: avatarSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: tokens.surfaceDeep,
                              border: Border.all(
                                color: tokens.surfaceDeep,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: tokens.glassShadow,
                                  offset: const Offset(0, 4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child:
                                  app.icon != null && app.icon!.isNotEmpty
                                      ? ZeroCachedImage(
                                          imageUrl: app.icon!,
                                          fit: BoxFit.cover,
                                          fadeInDuration: Duration.zero,
                                          fadeOutDuration: Duration.zero,
                                          errorWidget: (_, __, ___) => Icon(
                                            Icons.apps_rounded,
                                            size: 36,
                                            color: tokens.textDim,
                                          ),
                                        )
                                      : Container(
                                          color: tokens.glassFill,
                                          child: Icon(
                                            Icons.apps_rounded,
                                            size: 36,
                                            color: tokens.textDim,
                                          ),
                                        ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Name + bookmark
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            app.displayName,
                            style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                              color: tokens.starkWhite,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (!_isOwnedByCurrentUser)
                          _BookmarkButton(
                            tokens: tokens,
                            isBookmarked: onRemoveBookmark != null,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                              if (onRemoveBookmark != null) {
                                onRemoveBookmark!();
                              } else {
                                onAddBookmark?.call();
                              }
                            },
                          ),
                      ],
                    ),
                  ),

                  // Owner row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: GestureDetector(
                      onTap: () => _openOwnerProfile(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (ownerContact != null) ...[
                            GlassContactIcon(
                              contact: ownerContact,
                              address: app
                                  .ownerAccountAddress.eip55With0x,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                          ] else ...[
                            Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: tokens.textDim,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            context.l10n.appProfileSheetByPrefix,
                            style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                              fontSize: 13,
                              color: tokens.textDim,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              ownerContact?.displayName ??
                                  _formatAddress(
                                    app.ownerAccountAddress.eip55With0x,
                                  ),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: tokens.connectedAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: tokens.connectedAccent,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Platform badges
                  if (_hasAnyPlatform) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _buildPlatformBadges(tokens),
                      ),
                    ),
                  ],

                  // Categories
                  if (_hasCategories) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _buildCategoryChips(tokens),
                      ),
                    ),
                  ],

                  // Description
                  if (app.description != null &&
                      app.description!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.appProfileSheetAbout,
                            style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                              color: tokens.starkWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            app.description!,
                            style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                              color: tokens.textDim,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Warnings
                  if (_hasWarnings) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: tokens.fallbackAccent
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tokens.fallbackAccent
                                .withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: tokens.fallbackAccent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                app.getPointer('warnings')!.value,
                                style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                                  color: tokens.starkWhite,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Launch buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Text(
                      context.l10n.appProfileSheetOpenAppHeader,
                      style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                        color: tokens.starkWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_hasWebApp) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _GlassPrimaryButton(
                        tokens: tokens,
                        icon: Icons.public_rounded,
                        label: context.l10n.appProfileSheetOpenWebApp,
                        onTap: () {
                          Navigator.pop(context);
                          _launchApp(context);
                        },
                      ),
                    ),
                  ],

                  if (_hasAppStoreLink || _hasPlayStoreLink) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Row(
                        children: [
                          if (_hasAppStoreLink)
                            Expanded(
                              child: _GlassSecondaryButton(
                                tokens: tokens,
                                icon: Icons.apple_rounded,
                                label: 'App Store',
                                onTap: () =>
                                    _launchApp(context),
                              ),
                            ),
                          if (_hasAppStoreLink && _hasPlayStoreLink)
                            const SizedBox(width: 12),
                          if (_hasPlayStoreLink)
                            Expanded(
                              child: _GlassSecondaryButton(
                                tokens: tokens,
                                icon: Icons.android_rounded,
                                label: 'Play Store',
                                onTap: () =>
                                    _launchApp(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  if (_hasApkDownload || _hasIpaDownload) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Row(
                        children: [
                          if (_hasApkDownload)
                            Expanded(
                              child: _GlassSecondaryButton(
                                tokens: tokens,
                                icon: Icons.android_rounded,
                                label: context.l10n.appProfileSheetDownloadApk,
                                onTap: () =>
                                    _launchApp(context),
                              ),
                            ),
                          if (_hasApkDownload && _hasIpaDownload)
                            const SizedBox(width: 12),
                          if (_hasIpaDownload)
                            Expanded(
                              child: _GlassSecondaryButton(
                                tokens: tokens,
                                icon: Icons.apple_rounded,
                                label: context.l10n.appProfileSheetDownloadIpa,
                                onTap: () =>
                                    _launchApp(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPlatformBadges(GlassTokens tokens) {
    final badges = <Widget>[];
    if (_hasWebApp) {
      badges.add(_PlatformBadge(
        tokens: tokens,
        icon: Icons.language_rounded,
        label: 'Web',
        color: tokens.connectedAccent,
      ));
    }
    if (_hasIOS) {
      badges.add(_PlatformBadge(
        tokens: tokens,
        icon: Icons.apple_rounded,
        label: 'iOS',
        color: tokens.textDim,
      ));
    }
    if (_hasAndroid) {
      badges.add(_PlatformBadge(
        tokens: tokens,
        icon: Icons.android_rounded,
        label: 'Android',
        color: tokens.connectedAccent,
      ));
    }
    return badges;
  }

  List<Widget> _buildCategoryChips(GlassTokens tokens) {
    final chips = <Widget>[];
    for (final key in const ['category_one', 'category_two']) {
      final p = app.getPointer(key);
      if (p == null || p.value.isEmpty) continue;
      chips.add(
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: tokens.glassFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: Text(
            p.value,
            style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
    }
    return chips;
  }
}

// ---------------------------------------------------------------------------
// Leaf widgets
// ---------------------------------------------------------------------------

class _BookmarkButton extends StatelessWidget {
  final GlassTokens tokens;
  final bool isBookmarked;
  final VoidCallback onTap;

  const _BookmarkButton({
    required this.tokens,
    required this.isBookmarked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isBookmarked
                ? tokens.connectedAccent.withValues(alpha: 0.5)
                : tokens.borderSubtle,
            width: 1,
          ),
        ),
        child: Icon(
          isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
          size: 18,
          color: isBookmarked ? tokens.connectedAccent : tokens.textDim,
        ),
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  final GlassTokens tokens;
  final IconData icon;
  final String label;
  final Color color;

  const _PlatformBadge({
    required this.tokens,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPrimaryButton extends StatelessWidget {
  final GlassTokens tokens;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassPrimaryButton({
    required this.tokens,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: tokens.connectedAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tokens.connectedAccent.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: tokens.connectedAccent, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                color: tokens.connectedAccent,
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

class _GlassSecondaryButton extends StatelessWidget {
  final GlassTokens tokens;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassSecondaryButton({
    required this.tokens,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: tokens.starkWhite, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 13,
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
