import 'package:flutter/material.dart';
import 'nft_avatar_fx.dart';
import '../data/nft_avatar_prefs.dart';
import 'nft_image.dart';
import 'phigital_loading_widget.dart';
import '../theme/glass_tokens.dart';

/// Corner the sparkle cluster overhangs. The painter clusters its pixels toward
/// the top-left of its box; [bottomRight] point-reflects that box (180°) so the
/// same burst overhangs the opposite corner — used by the wide NFT banner.
enum SparkleCorner { topLeft, bottomRight }

/// Square NFT artwork with the canonical "verified NFT" treatment — the same
/// corner sparkles + diagonal shimmer sweep used on [GlassContactIcon] and the
/// NFT info dialog — shown only when [verifiedOwner] and gated by the user's
/// [NftAvatarPrefs] toggles.
///
/// Lifted from the NFT info dialog's private `_NftArt` so the avatar sheet's
/// preview box and the quick-pick grids ("Previously used" / "Pick mine or
/// used") render owned NFTs exactly the same way. Fills its parent — wrap in an
/// [AspectRatio]/[SizedBox] to size it. Owns one 10s controller so the two
/// effects stay phase-locked.
class NftVerifiedArt extends StatefulWidget {
  final String? image;

  /// Drives the sparkles + shimmer. When false the art renders plain.
  final bool verifiedOwner;

  final BorderRadius borderRadius;

  /// Sparkle cluster size in px. The focused dialog uses 60; small grid tiles
  /// want ~26–30 so the burst sits proportionate to the tile.
  final double fxSize;

  /// Use the doubled, wider-spread sparkle set (for large focused art) vs the
  /// canonical 6-pixel avatar set (for small tiles).
  final bool focusedSparkles;

  /// Which corner the sparkle cluster overhangs. [SparkleCorner.topLeft] is the
  /// shipped avatar/card/grid placement; [SparkleCorner.bottomRight] (the NFT
  /// banner) point-reflects the same cluster so it overhangs the bottom-right,
  /// spilling outside the wide strip.
  final SparkleCorner sparkleCorner;

  final BoxFit fit;

  /// Shown when [image] is null or fails to load. Defaults to a deep-surface
  /// fill.
  final Widget? fallback;

  const NftVerifiedArt({
    super.key,
    required this.image,
    required this.verifiedOwner,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.fxSize = 60,
    this.focusedSparkles = true,
    this.sparkleCorner = SparkleCorner.topLeft,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  State<NftVerifiedArt> createState() => _NftVerifiedArtState();
}

class _NftVerifiedArtState extends State<NftVerifiedArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim =
        AnimationController(vsync: this, duration: const Duration(seconds: 10));
    // Prefs are in-memory statics (default ON); re-check off the paint path and
    // adopt a non-default toggle, mirroring GlassContactIcon / the dialog.
    NftAvatarPrefs.ensureLoaded().then((_) {
      if (!mounted) return;
      setState(_maybeAnimate);
    });
    _maybeAnimate();
  }

  @override
  void didUpdateWidget(covariant NftVerifiedArt old) {
    super.didUpdateWidget(old);
    if (old.verifiedOwner != widget.verifiedOwner) _maybeAnimate();
  }

  void _maybeAnimate() {
    final want = widget.verifiedOwner &&
        (NftAvatarPrefs.sparkles || NftAvatarPrefs.shimmer);
    if (want) {
      if (!_anim.isAnimating) _anim.repeat();
    } else if (_anim.isAnimating) {
      _anim.stop();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final showSparkles = widget.verifiedOwner && NftAvatarPrefs.sparkles;
    final showShimmer = widget.verifiedOwner && NftAvatarPrefs.shimmer;
    final fallback = widget.fallback ?? Container(color: tokens.surfaceDeep);
    final bottomRight = widget.sparkleCorner == SparkleCorner.bottomRight;
    // Banner (bottomRight) spills the cluster further past the strip edge so it
    // reads as an app overlay, not part of the art.
    final overhang = widget.fxSize * (bottomRight ? 0.28 : 0.18);

    return Stack(
      clipBehavior: Clip.none, // let the sparkles spill past the art corner
      children: [
        ClipRRect(
          borderRadius: widget.borderRadius,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.image != null
                    ? NftImage(
                        url: widget.image!,
                        fit: widget.fit,
                        fallback: fallback,
                      )
                    : fallback,
                if (showShimmer)
                  AnimatedBuilder(
                    animation: _anim,
                    builder: (_, __) =>
                        CustomPaint(painter: NftShimmerPainter(_anim.value)),
                  ),
              ],
            ),
          ),
        ),
        if (showSparkles)
          Positioned(
            top: bottomRight ? null : -overhang,
            bottom: bottomRight ? -overhang : null,
            left: bottomRight ? null : -overhang,
            right: bottomRight ? -overhang : null,
            width: widget.fxSize,
            height: widget.fxSize,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) {
                final sparkles = CustomPaint(
                  painter: NftSparklesPainter(_anim.value,
                      focused: widget.focusedSparkles),
                );
                // The painter clusters top-left; for the bottom-right anchor we
                // point-reflect (180°) so the same burst overhangs that corner.
                return bottomRight
                    ? Transform.scale(scaleX: -1, scaleY: -1, child: sparkles)
                    : sparkles;
              },
            ),
          ),
      ],
    );
  }
}

/// A quick-pick NFT grid tile: verified art (shimmer/sparkles when owned) + a
/// bottom-right chain badge (the chain's brand mark, see [NftChainIcon]) + a
/// selection ring. Shared shape for the avatar sheet's "Previously used" (EVM)
/// and "Pick mine or used" (Solana) grids.
///
/// Pass [image] = null with [loading] = true for an un-hydrated tile (spinner),
/// or [image] = null with [loading] = false for an unavailable image (icon).
class NftPickTile extends StatelessWidget {
  final String? image;
  final bool verified;

  /// Brand mark for the tile's chain, rendered in the bottom-right corner over
  /// a dark scrim. Null = no badge (only shown alongside a loaded [image]).
  final Widget? chainBadge;
  final bool selected;
  final bool loading;

  const NftPickTile({
    super.key,
    required this.image,
    required this.verified,
    required this.chainBadge,
    required this.selected,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final radius = BorderRadius.circular(10);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius + BorderRadius.circular(2),
        color: tokens.glassFill,
        border: Border.all(
          color: selected ? tokens.connectedAccent : tokens.borderSubtle,
          width: selected ? 2 : 1,
        ),
      ),
      // Clip.none so the verified sparkles can spill past the tile corner.
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          if (image != null)
            NftVerifiedArt(
              image: image,
              verifiedOwner: verified,
              borderRadius: radius,
              fxSize: 26,
              focusedSparkles: false,
            )
          else
            Center(
              child: loading
                  ? const PhigitalLoadingWidget(size: 16, showShadows: false)
                  : Icon(Icons.image_not_supported_outlined,
                      size: 18, color: tokens.textDim),
            ),
          if (chainBadge != null && image != null)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: chainBadge,
              ),
            ),
        ],
      ),
    );
  }
}
