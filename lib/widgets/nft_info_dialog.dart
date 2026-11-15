import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:publicos_core/publicos_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/chain_registry.dart';
import '../theme/glass_tokens.dart';
import 'glass_contact_icon.dart';
import 'nft_verified_art.dart';
import 'system_app_action_button.dart';

/// A dedicated dialog for an NFT avatar — distinct from the full-screen image
/// viewer. Built entirely from the metadata already cached on the contact
/// (`verifiedNftAvatarData`), so it needs **no network/API call**: art, name,
/// contract/chain/token, ownership verdict, traits, and explorer/marketplace
/// links.
///
/// Returns immediately (does nothing) if the contact has no resolved NFT
/// **avatar** data. For banners/cards, call [showNftInfoDialogFor] directly with
/// the surface's own ref + verdict.
Future<void> showNftInfoDialog(
  BuildContext context,
  Contact contact, {
  Future<bool> Function(NftAvatarRef ref)? onUseAsAvatar,
}) {
  final ref = contact.nftAvatar;
  final cache = contact.verifiedNftAvatarData;
  if (ref == null || cache == null) return Future.value();
  return showNftInfoDialogFor(
    context,
    ref: ref,
    cache: cache,
    owner: contact,
    onUseAsAvatar: onUseAsAvatar,
  );
}

/// Surface-agnostic entry point: show the NFT info dialog for any resolved
/// (ref, verdict) pair — avatar, banner, or card. The avatar path goes through
/// [showNftInfoDialog]; the banner reads `contact.nftBanner` +
/// `contact.verifiedNftBannerData`; cards read the per-record `nftVerified`
/// verdict. [owner] is the contact the NFT was verified against (the viewed
/// profile) — when ownership is verified its mini avatar renders in the
/// "owned by" badge. [onUseAsAvatar], when non-null, renders the "Use as
/// avatar" button.
Future<void> showNftInfoDialogFor(
  BuildContext context, {
  required NftAvatarRef ref,
  required VerifiedNftAvatar cache,
  Contact? owner,
  Future<bool> Function(NftAvatarRef ref)? onUseAsAvatar,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (_) => _NftInfoDialog(
      ref: ref,
      cache: cache,
      owner: owner,
      onUseAsAvatar: onUseAsAvatar,
    ),
  );
}

class _NftInfoDialog extends StatelessWidget {
  final NftAvatarRef ref;
  final VerifiedNftAvatar cache;

  /// The contact the NFT was verified against (the viewed profile). When
  /// ownership is verified, its mini avatar renders inside the "owned by" badge.
  /// Null on surfaces with no contact in hand (e.g. the create-record preview),
  /// where the badge degrades to a plain "Verified" pill.
  final Contact? owner;

  /// When non-null, renders a "Use as avatar" button that sets this NFT as the
  /// current user's avatar. The callback performs the chain write (behind its
  /// own blocking overlay) and returns whether it succeeded. Provided only when
  /// viewing someone else's profile — on your own it'd be a no-op (the NFT shown
  /// is already your avatar).
  final Future<bool> Function(NftAvatarRef ref)? onUseAsAvatar;

  const _NftInfoDialog({
    required this.ref,
    required this.cache,
    this.owner,
    this.onUseAsAvatar,
  });

  /// Chain names come from the app's one registry (`lib/data/chain_registry.dart`).
  /// A private copy of the names here would drift from it, and a chain missing
  /// from the copy would render as a bare number.
  String? _chainNameOf(int chainId) => chainById(chainId)?.name;

  String? _explorerUrl() {
    if (ref.isSolana) return 'https://solscan.io/token/${ref.mint}';
    switch (ref.chain) {
      case 1:
        return 'https://etherscan.io/token/${ref.contract}?a=${ref.tokenId}';
      case 10:
        return 'https://optimistic.etherscan.io/token/${ref.contract}';
      case 137:
        return 'https://polygonscan.com/token/${ref.contract}';
      case 8453:
        return 'https://basescan.org/token/${ref.contract}';
      case 42161:
        return 'https://arbiscan.io/token/${ref.contract}';
      case 4489:
        return 'https://publicos.dev/contracts/';
      default:
        return null;
    }
  }

  String? _marketplaceUrl() {
    if (ref.isSolana) return 'https://magiceden.io/item-details/${ref.mint}';
    const slug = {
      1: 'ethereum',
      10: 'optimism',
      137: 'matic',
      8453: 'base',
      42161: 'arbitrum',
    };
    final s = slug[ref.chain];
    if (s == null) return null;
    return 'https://opensea.io/assets/$s/${ref.contract}/${ref.tokenId}';
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _short(String s) =>
      s.length <= 12 ? s : '${s.substring(0, 6)}…${s.substring(s.length - 4)}';

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final name = (cache.metadata['name'] as String?)?.trim();
    final collection =
        (cache.metadata['collection'] as String?)?.trim(); // often absent
    final image = cache.imageUrl;
    final attrs = cache.attributes;

    return Dialog(
      backgroundColor: tokens.surfaceElevated,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: DialogWidth.m,
          maxHeight: MediaQuery.of(context).size.height - 96,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Art — full-width square, always renders complete. Carries the
            // live verified-owner sparkle + shimmer treatment, same rule as
            // the "Verified" badge.
            _NftArt(
              image: image,
              verifiedOwner: cache.verifiedOwnership,
            ),
            // Sticky title block — name + verified badge + collection. Sits
            // right under the art and never scrolls, so the NFT is always
            // framed by its name.
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name?.isNotEmpty == true
                              ? name!
                              : (ref.isSolana
                                  ? _short(ref.mint ?? '')
                                  : '#${_short(ref.tokenId)}'),
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            color: tokens.starkWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (cache.verifiedOwnership)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                tokens.connectedAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: owner == null
                              // No contact in hand (preview) — plain pill.
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_rounded,
                                        size: 14,
                                        color: tokens.connectedAccent),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        fontFamily: 'SpaceGrotesk',
                                        color: tokens.connectedAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                )
                              // [mini avatar] displayName owns this NFT — the
                              // avatar is the same 28px as the profile
                              // "founded by" row.
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // GlassContactIcon(contact: owner!, size: 28),
                                    Icon(Icons.verified_rounded,
                                      size: 16,
                                      color: tokens.connectedAccent,
                                    ),
                                    const SizedBox(width: 6),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 110),
                                      child: Text(
                                        owner!.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'SpaceGrotesk',
                                          color: tokens.connectedAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'owns this NFT',
                                      style: TextStyle(
                                        fontFamily: 'SpaceGrotesk',
                                        color: tokens.connectedAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                    ],
                  ),
                  if (collection?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      collection!,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: tokens.textDim,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Scrollable details — chain/contract rows, traits, and the
            // Explorer/Marketplace links. Eats whatever vertical space the
            // dialog has left after art + sticky title + pinned button.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ref.isSolana) ...[
                      _row(tokens, 'Chain', 'Solana'),
                      _copyRow(context, tokens, 'Mint',
                          ref.mint ?? ''),
                    ] else ...[
                      _row(
                          tokens,
                          'Chain',
                          _chainNameOf(ref.chain) ??
                              'Chain ${ref.chain}'),
                      _copyRow(context, tokens,
                          'Contract', ref.contract),
                      _row(tokens, 'Token ID',
                          _short(ref.tokenId)),
                      _row(tokens, 'Standard',
                          ref.standard.toUpperCase()),
                    ],
                    if (attrs.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'TRAITS',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          color: tokens.textDim,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: attrs
                            .whereType<Map>()
                            .map((a) => _trait(tokens, a))
                            .whereType<Widget>()
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        if (_explorerUrl() != null)
                          Expanded(
                            child: _linkButton(
                              tokens,
                              'Explorer',
                              Icons.open_in_new,
                              () => _open(_explorerUrl()!),
                            ),
                          ),
                        if (_explorerUrl() != null &&
                            _marketplaceUrl() != null)
                          const SizedBox(width: 10),
                        if (_marketplaceUrl() != null)
                          Expanded(
                            child: _linkButton(
                              tokens,
                              'Marketplace',
                              Icons.storefront_outlined,
                              () => _open(_marketplaceUrl()!),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Pinned bottom action — visible without scrolling so the
            // primary CTA is always reachable.
            if (onUseAsAvatar != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: SystemAppActionButton(
                  label: 'USE AS AVATAR',
                  icon: Icons.account_circle_rounded,
                  onTap: () => _confirmUseAsAvatar(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Confirm, then set this NFT as the current user's avatar via [onUseAsAvatar]
  /// (which owns the blocking "Saving to chain..." overlay + refresh). Closes
  /// this dialog on success.
  Future<void> _confirmUseAsAvatar(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final t = GlassTokens.of(dialogContext);
        return AlertDialog(
          constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
          backgroundColor: t.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: t.borderSubtle),
          ),
          title: Text(
            'Set as profile picture?',
            style: TextStyle(
              color: t.starkWhite,
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          content: Text(
            "This sets this NFT as your avatar. You'll only appear verified if you own it.",
            style: TextStyle(
              color: t.textDim,
              fontFamily: 'SpaceGrotesk',
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancel',
                  style: TextStyle(color: t.textDim)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('Set as avatar',
                  style: TextStyle(color: t.connectedAccent)),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    final ok = await onUseAsAvatar!(ref);
    if (ok && context.mounted) Navigator.of(context).pop();
  }

  Widget _row(GlassTokens tokens, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 12)),
          Text(value,
              style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _copyRow(
      BuildContext context, GlassTokens tokens, String label, String value) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${label} copied'),
              duration: const Duration(seconds: 1)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 12)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_short(value),
                    style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: tokens.starkWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 5),
                Icon(Icons.copy_rounded, size: 12, color: tokens.textDim),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget? _trait(GlassTokens tokens, Map a) {
    final type = (a['trait_type'] ?? a['traitType'])?.toString();
    final value = a['value']?.toString();
    if (value == null || value.isEmpty) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.surfaceDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (type != null && type.isNotEmpty)
            Text(type.toUpperCase(),
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
          Text(value,
              style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _linkButton(
      GlassTokens tokens, String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.starkWhite,
        side: BorderSide(color: tokens.borderSubtle),
        padding: const EdgeInsets.symmetric(vertical: 11),
        textStyle: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// The square NFT art with the same live "verified NFT" treatment as
/// [GlassContactIcon] — sparkles + shimmer — shown only when the launching
/// profile is the verified owner (same rule as the "Verified" badge), and gated
/// by the user's [NftAvatarPrefs] toggles. Delegates to the shared
/// [NftVerifiedArt] (focused, top-rounded) so the avatar sheet's grids and this
/// dialog render owned NFTs identically.
class _NftArt extends StatelessWidget {
  final String? image;
  final bool verifiedOwner;
  const _NftArt({required this.image, required this.verifiedOwner});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: NftVerifiedArt(
        image: image,
        verifiedOwner: verifiedOwner,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        fxSize: 60,
        focusedSparkles: true,
      ),
    );
  }
}
