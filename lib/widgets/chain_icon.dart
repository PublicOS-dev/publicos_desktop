import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:publicos_core/publicos_core.dart';

/// Brand marks for the wallet-directory protocols, as inline SVG.
///
/// flutter_svg is already a dependency, so these need no asset files or pubspec
/// wiring — the markup lives here as `const` strings (only basic primitives:
/// polygon/path/circle/rect/linearGradient, all flutter_svg-supported).
const String _ethSvg = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<polygon points="12,1.5 4.8,12.6 12,9.4" fill="#8A92B2"/>
<polygon points="12,1.5 19.2,12.6 12,9.4" fill="#62688F"/>
<polygon points="12,9.4 4.8,12.6 12,16.4" fill="#62688F"/>
<polygon points="12,9.4 19.2,12.6 12,16.4" fill="#454A75"/>
<polygon points="12,17.8 4.8,13.9 12,22.5" fill="#8A92B2"/>
<polygon points="12,17.8 19.2,13.9 12,22.5" fill="#62688F"/>
</svg>''';

const String _solSvg = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<defs><linearGradient id="g" x1="2" y1="4" x2="22" y2="20" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="#9945FF"/><stop offset="1" stop-color="#14F195"/></linearGradient></defs>
<path d="M5.5 4 H22 L18.5 7 H2 Z" fill="url(#g)"/>
<path d="M2 10.5 H18.5 L22 13.5 H5.5 Z" fill="url(#g)"/>
<path d="M5.5 17 H22 L18.5 20 H2 Z" fill="url(#g)"/>
</svg>''';

const String _btcSvg = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="12" r="11" fill="#F7931A"/>
<g fill="#fff">
<rect x="9" y="6" width="2" height="12" rx="0.4"/>
<rect x="10.4" y="4.4" width="1.5" height="2.4" rx="0.4"/>
<rect x="13.2" y="4.4" width="1.5" height="2.4" rx="0.4"/>
<rect x="10.4" y="17.2" width="1.5" height="2.4" rx="0.4"/>
<rect x="13.2" y="17.2" width="1.5" height="2.4" rx="0.4"/>
<path d="M9.8 6 H14 a3.1 3.1 0 0 1 0 6 H9.8 Z"/>
<path d="M9.8 11.6 H14.6 a3.3 3.3 0 0 1 0 6.6 H9.8 Z"/>
</g>
<g fill="#F7931A">
<rect x="11.2" y="7.6" width="2.7" height="2.8"/>
<rect x="11.2" y="13.2" width="3.1" height="3.4"/>
</g>
</svg>''';

const String _adaSvg = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="12" r="11" fill="#0033AD"/>
<g fill="#fff">
<circle cx="12" cy="12" r="1.7"/>
<circle cx="12" cy="6.4" r="1.1"/>
<circle cx="16.85" cy="9.2" r="1.1"/>
<circle cx="16.85" cy="14.8" r="1.1"/>
<circle cx="12" cy="17.6" r="1.1"/>
<circle cx="7.15" cy="14.8" r="1.1"/>
<circle cx="7.15" cy="9.2" r="1.1"/>
</g>
</svg>''';

// ── Per-EVM-chain brand marks ───────────────────────────────────────────────
// The protocol-level [_ethSvg] above stands in for "an EVM chain" generically
// (wallet directory). NFT avatars live on a *specific* chain, so the avatar
// quick-pick grids want the chain's own mark. Kept deliberately simple (disc +
// one glyph) so they read at the ~13px corner-badge size. Brand colours from
// each chain's brand kit.

// Optimism — red disc + white ring.
const String _opSvg = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="12" r="11" fill="#FF0420"/>
<circle cx="12" cy="12" r="5.4" fill="none" stroke="#fff" stroke-width="2.4"/>
</svg>''';

// Polygon — purple disc + white hexagon.
const String _polygonSvg = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="12" r="11" fill="#8247E5"/>
<polygon points="12,6 17,9 17,15 12,18 7,15 7,9" fill="none" stroke="#fff" stroke-width="2"/>
</svg>''';

// Base — blue disc + white rounded square.
const String _baseSvg = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="12" r="11" fill="#0052FF"/>
<rect x="8.5" y="8.5" width="7" height="7" rx="1.4" fill="#fff"/>
</svg>''';

// Arbitrum — navy disc + light-blue "A".
const String _arbitrumSvg = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="12" r="11" fill="#2D374B"/>
<path d="M12 6 L16.6 17 H13.9 L12 12 L10.1 17 H7.4 Z" fill="#28A0F0"/>
</svg>''';

// PublicOS (chain 4489) — the logo at its resting point (as in publicos.dev's
// index mark): the small circle directly ABOVE the big rounded square, both
// centred. White on the badge's dark backdrop.
const String _publicosSvg = '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<rect x="5.5" y="9.5" width="13" height="12" rx="5" fill="#fff"/>
<circle cx="12" cy="5" r="2.6" fill="#fff"/>
</svg>''';

// Gnosis — the real CC0 atomiclabs/cryptocurrency-icons mark (teal disc + owl),
// same as the GNO token in crypto_icon.dart.
const String _gnosisSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><g fill="none" fill-rule="evenodd"><circle cx="16" cy="16" r="16" fill="#00A6C4"/><path fill="#FFF" fill-rule="nonzero" d="M24.777 10.5l.2.331a10.816 10.816 0 011.523 5.537C26.482 22.236 21.785 27 16 27h-.018c-5.785 0-10.5-4.801-10.482-10.669 0-1.968.544-3.881 1.541-5.537l.182-.312.961.975a3.78 3.78 0 00-.453.9 4.09 4.09 0 002.43 5.225 4.024 4.024 0 003.608-.46L16 19.403l2.557-2.594c.236.166.508.295.798.405 2.05.736 4.298-.35 5.023-2.41.435-1.214.236-2.483-.399-3.495l.798-.809zM9.363 12.652l3.01 3.035c-.363.295-.816.46-1.306.46-1.178 0-2.14-.975-2.14-2.17 0-.497.164-.957.436-1.325zm10.5 2.851l2.974-3.016c.236.35.362.772.362 1.214 0 1.195-.96 2.17-2.14 2.17-.453 0-.852-.129-1.196-.368zm-3.827 2.281l-8.668-8.83.344-.367C9.852 6.287 12.772 5 15.91 5h.018c3.174 0 6.22 1.38 8.342 3.77l.327.369-8.56 8.645zm-7.254-8.83l7.254 7.377L23.2 9.102c-1.922-1.95-4.533-3.072-7.253-3.072h-.019c-2.702 0-5.222 1.03-7.145 2.925z"/></g></svg>';

// BNB Chain — the real CC0 atomiclabs/cryptocurrency-icons mark (`bnb.svg`),
// verbatim.
const String _bnbSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><g fill="none"><circle cx="16" cy="16" r="16" fill="#F3BA2F"/><path fill="#FFF" d="M12.116 14.404L16 10.52l3.886 3.886 2.26-2.26L16 6l-6.144 6.144 2.26 2.26zM6 16l2.26-2.26L10.52 16l-2.26 2.26L6 16zm6.116 1.596L16 21.48l3.886-3.886 2.26 2.259L16 26l-6.144-6.144-.003-.003 2.263-2.257zM21.48 16l2.26-2.26L26 16l-2.26 2.26L21.48 16zm-3.188-.002h.002V16L16 18.294l-2.291-2.29-.004-.004.004-.003.401-.402.195-.195L16 13.706l2.293 2.293z"/></g></svg>';

// Avalanche — the real CC0 atomiclabs mark (`avax.svg`), verbatim except the
// intrinsic width/height attributes, dropped so the viewBox alone drives the
// scale (same treatment as the Gnosis mark below).
const String _avaxSvg =
    '<svg viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg"><g fill="none" fill-rule="evenodd"><circle fill="#E84142" fill-rule="nonzero" cx="16" cy="16" r="16"/><path d="M11.518 22.75H8.49c-.636 0-.95 0-1.142-.123A.77.77 0 017 22.025c-.012-.226.145-.503.46-1.055l7.472-13.193c.318-.56.48-.84.682-.944a.77.77 0 01.698 0c.203.104.364.384.682.944l1.536 2.686.008.014c.343.6.517.906.593 1.226a2.26 2.26 0 010 1.066c-.076.323-.249.63-.597 1.24l-3.926 6.95-.01.017c-.346.606-.52.913-.764 1.145a2.284 2.284 0 01-.93.54c-.319.089-.675.089-1.387.089zm7.643 0h4.336c.64 0 .962 0 1.154-.126a.768.768 0 00.348-.607c.011-.219-.142-.484-.443-1.005l-.032-.054-2.172-3.722-.025-.042c-.305-.517-.46-.778-.657-.879a.762.762 0 00-.693 0c-.2.104-.36.377-.678.925l-2.165 3.722-.007.013c-.317.548-.476.821-.464 1.046a.777.777 0 00.348.606c.188.123.51.123 1.15.123z" fill="#FFF"/></g></svg>';

const Map<String, String> _svgByProtocol = {
  PublicOSWallets.protoEvm: _ethSvg,
  PublicOSWallets.protoSolana: _solSvg,
  PublicOSWallets.protoBitcoin: _btcSvg,
  PublicOSWallets.protoCardano: _adaSvg,
};

/// Chain id → brand mark. Covers the NFT-avatar chains in
/// `PublicOSContacts.nftChainNames` **and every chain in
/// `lib/data/chain_registry.dart`** — the two sets are kept equal on purpose,
/// so any chain the dApp browser or the Send sheet can reach has a real mark
/// rather than the generic Ethereum diamond. Add a chain there, add its mark
/// here.
const Map<int, String> _svgByChainId = {
  4489: _publicosSvg,
  1: _ethSvg,
  10: _opSvg,
  137: _polygonSvg,
  8453: _baseSvg,
  42161: _arbitrumSvg,
  100: _gnosisSvg,
  56: _bnbSvg,
  43114: _avaxSvg,
};

const Map<String, String> _nameByProtocol = {
  PublicOSWallets.protoEvm: 'Ethereum',
  PublicOSWallets.protoSolana: 'Solana',
  PublicOSWallets.protoBitcoin: 'Bitcoin',
  PublicOSWallets.protoCardano: 'Cardano',
};

/// Friendly display name for a CAIP protocol id (e.g. `eip155` → `Ethereum`).
/// Falls back to the raw protocol string for anything unmapped.
String chainDisplayName(String protocol) => _nameByProtocol[protocol] ?? protocol;

/// Whether [chainId] has a real brand mark (as opposed to falling back to the
/// generic Ethereum diamond). Exists so a test can pin the invariant that every
/// chain in `lib/data/chain_registry.dart` has one; without it a chain can be
/// reachable in the dApp browser while wearing Ethereum's logo.
bool hasChainMark(int chainId) => _svgByChainId.containsKey(chainId);

/// Brand mark for a wallet-directory protocol. Falls back to a neutral wallet
/// glyph for unmapped protocols.
class ChainIcon extends StatelessWidget {
  final String protocol;
  final double size;
  const ChainIcon({super.key, required this.protocol, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final svg = _svgByProtocol[protocol];
    if (svg == null) {
      return Icon(Icons.account_balance_wallet_outlined, size: size);
    }
    return SvgPicture.string(svg, width: size, height: size);
  }
}

/// Brand mark for a *specific* NFT chain — Solana, or one of the EVM chains in
/// `PublicOSContacts.nftChainNames` (keyed by CAIP-2 chain id). Used by the
/// avatar quick-pick grid tiles in place of the old chain-name text chip.
/// Falls back to the generic Ethereum diamond for an unmapped EVM chain.
class NftChainIcon extends StatelessWidget {
  final int? chain;
  final bool solana;
  final double size;
  const NftChainIcon({
    super.key,
    this.chain,
    this.solana = false,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    final svg = solana ? _solSvg : (_svgByChainId[chain] ?? _ethSvg);
    return SvgPicture.string(svg, width: size, height: size);
  }
}
