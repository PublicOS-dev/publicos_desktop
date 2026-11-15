import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_cached_image/zero_cached_image.dart';
import 'nft_banner.dart';

/// What a contact's banner slot paints, decided in ONE place.
///
/// An NFT banner (`profile.banner.nft`) wins; else Core's
/// [Contact.displayBannerUrl] (the owner's banner, else the background pinned
/// top when [Contact.bannerIsBackground], else the default); else [fallback].
/// [fallback] also covers loading and errors, so each slot keeps its own look.
///
/// Every banner slot uses this except the two headers that run their own art
/// geometry: `browser.dart` `_buildBanner` (background-as-banner, the publicos
/// org's live constellation) and desktop's `profile_pane.dart`. A slot must
/// not read `displayBannerUrl` alone: it knows nothing about NFT banners, so
/// an NFT-banner account would show the default image in contact rows,
/// conversation rows, the Social Graph card and more.
class ContactBanner extends StatelessWidget {
  final Contact? contact;
  final Widget fallback;
  final BoxFit fit;

  /// The NFT banner's sparkle size ([NftBanner.fxSize]).
  final double fxSize;

  const ContactBanner({
    super.key,
    required this.contact,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.fxSize = 46,
  });

  @override
  Widget build(BuildContext context) {
    final c = contact;
    if (c == null) return fallback;
    if (c.nftBanner != null) return NftBanner(contact: c, fxSize: fxSize, fallback: fallback);
    final url = c.displayBannerUrl;
    if (url.isEmpty) return fallback;
    return ZeroCachedImage(
      imageUrl: url,
      alignment: c.bannerIsBackground ? Alignment.topCenter : Alignment.center,
      fit: fit,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
