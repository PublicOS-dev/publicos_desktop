import 'dart:ui';
import '../widgets/contact_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Full-screen QR page for a verified account.
///
/// Dismissable via iOS swipe-back and the top-right X button.
/// QR encodes the universal link `https://publicos.dev/publicosAddress/<address>`
/// — same as the share/copy actions — so any camera app opens the profile
/// (app link / AASA when installed, web otherwise).
class ProfileQrPage extends StatelessWidget {
  final String address;
  final Contact contact;
  final String displayName;

  const ProfileQrPage({
    super.key,
    required this.address,
    required this.contact,
    required this.displayName,
  });

  String get _shortAddress =>
      '${address.substring(0, 6)}...${address.substring(address.length - 4)}';

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final qrData = 'https://publicos.dev/publicosAddress/$address';

    return Scaffold(
      backgroundColor: tokens.background,
      body: Stack(
        children: [
          // Banner as backdrop
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ContactBanner(
                  contact: contact,
                  fallback: _bannerFallback(tokens),
                ),
                // Gradient fade into background
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        tokens.background,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Close button
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Spacer(),
                      _CloseButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                // Avatar
                GlassContactIcon(
                  contact: contact,
                  address: address,
                  size: 88,
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: tokens.starkWhite,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  _shortAddress,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: tokens.textDim,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 40),
                // QR card
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: tokens.surfaceDeep,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: tokens.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.starkWhite.withValues(alpha: 0.08),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.transparent,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.circle,
                      color: tokens.starkWhite,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: tokens.starkWhite,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.profileQrPageScanHint,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                // Copy link
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
                  child: _CopyLinkButton(
                    address: address,
                    qrData: qrData,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerFallback(GlassTokens tokens) {
    final base = contact.iconColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base.withValues(alpha: 0.35), tokens.surfaceDeep],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Icon(Icons.close, color: tokens.starkWhite, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class _CopyLinkButton extends StatelessWidget {
  final String address;
  final String qrData;

  const _CopyLinkButton({required this.address, required this.qrData});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Clipboard.setData(ClipboardData(text: qrData));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.profileQrPageLinkCopied),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.link, color: tokens.starkWhite, size: 16),
              const SizedBox(width: 10),
              Text(
                context.l10n.profileQrPageCopyLink,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: tokens.starkWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
