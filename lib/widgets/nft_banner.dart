import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'nft_verified_art.dart';

/// The NFT-banner surface: the wide profile header rendered as a verified NFT,
/// the banner-form-factor sibling of the NFT avatar. Reusable — wired into the
/// profile header (`browser.dart` `_buildBanner`) for now; other `bannerUrl`
/// readers can adopt it later by swapping their `ZeroCachedImage(bannerUrl)`
/// for `NftBanner(contact: …)`.
///
/// Presentational, exactly like [GlassContactIcon]: the resolve + ownership
/// verdict are computed and persisted by `PublicOSContacts.fetchContact`
/// (the `verifiedNftBanner` column). This widget reads that verdict for the
/// image + sparkle/shimmer decision. On a cache miss (verdict not yet written —
/// a bare or pre-fetch contact) it resolves the image alone for display; the
/// ownership FX then appears on the next `fetchContact`, mirroring the avatar
/// icon's first-view fallback.
class NftBanner extends StatefulWidget {
  final Contact contact;

  /// The banner sits inside the header's rect clip, so the default is square.
  final BorderRadius borderRadius;

  /// Sparkle cluster size — banner uses a larger burst than the avatar corner.
  final double fxSize;

  /// Painted while the NFT image resolves or when it can't be resolved.
  /// Null keeps [NftVerifiedArt]'s plain fill.
  final Widget? fallback;

  const NftBanner({
    super.key,
    required this.contact,
    this.borderRadius = BorderRadius.zero,
    this.fxSize = 46,
    this.fallback,
  });

  @override
  State<NftBanner> createState() => _NftBannerState();
}

class _NftBannerState extends State<NftBanner> {
  String? _image;
  bool _owned = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant NftBanner old) {
    super.didUpdateWidget(old);
    if (old.contact.verifiedNftBanner != widget.contact.verifiedNftBanner ||
        old.contact.nftBanner?.toCaip19() !=
            widget.contact.nftBanner?.toCaip19()) {
      setState(_sync);
    }
  }

  /// Adopt the fetchContact-computed verdict synchronously. On a miss, clear FX
  /// and kick a display-only image resolve (no ownership check on the render
  /// path — that's fetchContact's job).
  void _sync() {
    final ref = widget.contact.nftBanner;
    final verdict = widget.contact.verifiedNftBannerData;
    if (ref != null && verdict != null && verdict.matches(ref)) {
      _image = verdict.imageUrl;
      _owned = verdict.verifiedOwnership;
      return;
    }
    _image = null;
    _owned = false;
    if (ref != null) _resolveImageOnly(ref);
  }

  Future<void> _resolveImageOnly(NftAvatarRef ref) async {
    try {
      final meta = ref.isSolana
          ? await PublicOSWallets.resolveSolanaNftData(ref.mint!)
          : await PublicOSContacts.resolveNftAvatarData(ref);
      final img = (meta?['image'] ?? meta?['image_url']) as String?;
      if (!mounted) return;
      setState(() => _image = (img != null && img.isNotEmpty) ? img : null);
    } catch (_) {
      // leave _image null → NftVerifiedArt shows its fallback fill
    }
  }

  @override
  Widget build(BuildContext context) {
    return NftVerifiedArt(
      image: _image,
      verifiedOwner: _owned,
      fit: BoxFit.cover,
      sparkleCorner: SparkleCorner.bottomRight,
      borderRadius: widget.borderRadius,
      fxSize: widget.fxSize,
      focusedSparkles: true,
      fallback: widget.fallback,
    );
  }
}
