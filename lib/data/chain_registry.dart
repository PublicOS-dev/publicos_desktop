/// **The app's single chain registry** — every surface that names, dials or
/// draws a chain reads this file.
///
/// Consumers: the Send sheet's chain/token picker ([kSendChains]), the dApp
/// browser via [kBridgeChainRpcMap] (injected into the bridge's
/// `ChainRegistry`), the connect + signature sheets via [chainNameForHex], the
/// NFT info dialog, and `chain_icon.dart`'s brand marks (keyed by the same
/// ids). Keeping these facts in one place stops the surfaces disagreeing.
///
/// Bundled, verified seed:
/// every non-OX token address + decimals is traced to Circle docs / the chain's
/// own block explorer. **Re-verify against the cited explorer before changing.**
///
/// Two halves of the design:
///  - This file is the static seed. User-added custom chains (persisted in
///    settings) are a later, back-half addition — keep that runtime layer out
///    of here; this stays pure const data.
///  - OX/4489 is the default everywhere and its token address is resolved at
///    runtime from `PublicOSBsp.publicOSTokenAddress` (the chain mints it), so
///    [TokenDef.address] is null for OX only — the sheet substitutes the live
///    address and uses the global `PublicOS.web3Client` for OX sends.
///
/// Multi-chain sends are keychain-only: a Safe can't transact on a chain where
/// it isn't deployed, so Safe/group wallets pin to OX/4489 (see send_sheet.dart).
library;

/// A token offered in the picker for a given chain.
class TokenDef {
  /// Display ticker, e.g. "USDC", "OX".
  final String symbol;

  /// ERC-20 `decimals()`. Load-bearing: human↔raw is `value * 10^decimals`.
  /// USDC/USDT = 6, WBTC/cbBTC = 8, most others = 18.
  final int decimals;

  /// Hex contract address. Null for the OX token (resolved at runtime from
  /// `PublicOSBsp.publicOSTokenAddress`) and for a chain's NATIVE gas token.
  final String? address;

  /// True for the chain's native gas token (ETH / POL / xDAI). Sent as a plain
  /// value transfer (no ERC-20 calldata); balance read via `getBalance`.
  final bool isNative;

  const TokenDef({
    required this.symbol,
    required this.decimals,
    this.address,
    this.isNative = false,
  });

  /// The OX token (runtime-resolved address). Distinct from a native token,
  /// which also has a null address but is `isNative`.
  bool get isOx => address == null && !isNative;
}

/// A chain offered in the picker, with its RPC and token list.
class ChainDef {
  final int chainId;

  /// Display name, e.g. "Ethereum", "OX".
  final String name;

  /// Open / native-org RPC endpoint. Used to build a transient client for
  /// non-OX sends; for OX the sheet uses the global `PublicOS.web3Client`.
  final String rpcUrl;

  /// Native gas token ticker (ETH, POL, xDAI, OX). Shown in the picker; we do
  /// not estimate gas (deferred) — this just tells the user what funds the tx.
  final String nativeSymbol;

  /// Block explorer base URL (no trailing slash), for "view on explorer" links.
  final String? explorerUrl;

  /// User-added (settings) vs bundled seed. Always false in the static seed.
  final bool isCustom;

  /// Whether the Send sheet offers this chain in its chain picker.
  ///
  /// **Every chain here is offered to the dApp browser** (this list is the
  /// bridge's chain map — see [kBridgeChainRpcMap]), but *sending* is a money
  /// surface: a chain only joins the Send picker once its token addresses and
  /// decimals have been traced to that chain's own explorer, per this file's
  /// provenance rule. BSC and Avalanche arrived from the browser side with
  /// native-only token lists, so they browse but do not send yet. Flip this to
  /// `true` once their stablecoins are verified and added.
  final bool sendEnabled;

  final List<TokenDef> tokens;

  const ChainDef({
    required this.chainId,
    required this.name,
    required this.rpcUrl,
    required this.nativeSymbol,
    required this.tokens,
    this.explorerUrl,
    this.isCustom = false,
    this.sendEnabled = true,
  });

  bool get isOx => chainId == kOxChainId;

  /// The default token for this chain (the first listed).
  TokenDef get defaultToken => tokens.first;
}

/// PublicOS chain id. OX is the default chain everywhere.
const int kOxChainId = 4489;

/// The OX chain — the default. Its token address resolves at runtime, and OX
/// sends go through the global client, so [ChainDef.rpcUrl] here is informational.
const ChainDef kOxChain = ChainDef(
  chainId: kOxChainId,
  name: 'PublicOS', // the chain is "PublicOS"; its token is "OX"
  rpcUrl: 'https://rpc.publicos.dev',
  nativeSymbol: 'OX',
  explorerUrl: 'https://explorer.publicos.dev',
  tokens: [
    TokenDef(symbol: 'OX', decimals: 18), // ERC-20; address resolved at runtime
  ],
);

/// The full registry: OX first (default), then the verified open-RPC chains.
/// Tokens = stablecoins + most widely-traded (chain governance token, WBTC/cbBTC,
/// blue-chips). "Trouble tokens" (Gnosis bridged USDC, EURe) are deferred.
const List<ChainDef> kChainRegistry = [
  kOxChain,

  ChainDef(
    chainId: 1,
    name: 'Ethereum',
    // Cloudflare's gateway is sunset ("Cannot fulfill request"); PublicNode is
    // a reliable keyless public RPC.
    rpcUrl: 'https://ethereum-rpc.publicnode.com',
    nativeSymbol: 'ETH',
    explorerUrl: 'https://etherscan.io',
    tokens: [
      TokenDef(symbol: 'ETH', decimals: 18, isNative: true),
      TokenDef(symbol: 'USDC', decimals: 6, address: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'),
      TokenDef(symbol: 'USDT', decimals: 6, address: '0xdAC17F958D2ee523a2206206994597C13D831ec7'),
      TokenDef(symbol: 'DAI', decimals: 18, address: '0x6B175474E89094C44Da98b954EedeAC495271d0F'),
      TokenDef(symbol: 'WETH', decimals: 18, address: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'),
      TokenDef(symbol: 'WBTC', decimals: 8, address: '0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599'),
      TokenDef(symbol: 'LINK', decimals: 18, address: '0x514910771AF9Ca656af840dff83E8264EcF986CA'),
      TokenDef(symbol: 'UNI', decimals: 18, address: '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984'),
    ],
  ),

  ChainDef(
    chainId: 8453,
    name: 'Base',
    rpcUrl: 'https://mainnet.base.org',
    nativeSymbol: 'ETH',
    explorerUrl: 'https://basescan.org',
    tokens: [
      TokenDef(symbol: 'ETH', decimals: 18, isNative: true),
      TokenDef(symbol: 'USDC', decimals: 6, address: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913'),
      TokenDef(symbol: 'WETH', decimals: 18, address: '0x4200000000000000000000000000000000000006'),
      TokenDef(symbol: 'cbBTC', decimals: 8, address: '0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf'),
      TokenDef(symbol: 'AERO', decimals: 18, address: '0x940181a94A35A4569E4529A3CDfB74e38FD98631'),
    ],
  ),

  ChainDef(
    chainId: 10,
    name: 'OP Mainnet',
    rpcUrl: 'https://mainnet.optimism.io',
    nativeSymbol: 'ETH',
    explorerUrl: 'https://optimistic.etherscan.io',
    tokens: [
      TokenDef(symbol: 'ETH', decimals: 18, isNative: true),
      TokenDef(symbol: 'USDC', decimals: 6, address: '0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85'),
      TokenDef(symbol: 'WETH', decimals: 18, address: '0x4200000000000000000000000000000000000006'),
      TokenDef(symbol: 'OP', decimals: 18, address: '0x4200000000000000000000000000000000000042'),
      TokenDef(symbol: 'WBTC', decimals: 8, address: '0x68f180fcCe6836688e9084f035309E29Bf0A2095'),
    ],
  ),

  ChainDef(
    chainId: 42161,
    name: 'Arbitrum One',
    rpcUrl: 'https://arb1.arbitrum.io/rpc',
    nativeSymbol: 'ETH',
    explorerUrl: 'https://arbiscan.io',
    tokens: [
      TokenDef(symbol: 'ETH', decimals: 18, isNative: true),
      TokenDef(symbol: 'USDC', decimals: 6, address: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831'),
      TokenDef(symbol: 'WETH', decimals: 18, address: '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1'),
      TokenDef(symbol: 'ARB', decimals: 18, address: '0x912CE59144191C1204E64559FE8253a0e49E6548'),
      TokenDef(symbol: 'WBTC', decimals: 8, address: '0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f'),
    ],
  ),

  ChainDef(
    chainId: 137,
    name: 'Polygon PoS',
    // polygon-rpc.com returns "tenant disabled"; PublicNode is keyless +
    // live.
    rpcUrl: 'https://polygon-bor-rpc.publicnode.com',
    nativeSymbol: 'POL',
    explorerUrl: 'https://polygonscan.com',
    tokens: [
      TokenDef(symbol: 'POL', decimals: 18, isNative: true),
      // Native Circle USDC (not the bridged USDC.e).
      TokenDef(symbol: 'USDC', decimals: 6, address: '0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359'),
      TokenDef(symbol: 'USDT', decimals: 6, address: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F'),
      TokenDef(symbol: 'WETH', decimals: 18, address: '0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619'),
      TokenDef(symbol: 'WPOL', decimals: 18, address: '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270'),
      TokenDef(symbol: 'WBTC', decimals: 8, address: '0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6'),
    ],
  ),

  ChainDef(
    chainId: 100,
    name: 'Gnosis',
    rpcUrl: 'https://rpc.gnosischain.com',
    nativeSymbol: 'xDAI',
    explorerUrl: 'https://gnosisscan.io',
    tokens: [
      TokenDef(symbol: 'xDAI', decimals: 18, isNative: true),
      // WXDAI is the wrapped ERC-20 of the USD-pegged gas token (Gnosis's "dollar").
      TokenDef(symbol: 'WXDAI', decimals: 18, address: '0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d'),
      TokenDef(symbol: 'GNO', decimals: 18, address: '0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb'),
      // Deferred ("trouble tokens"): bridged USDC + Monerium EURe — add later.
    ],
  ),

  // --- Browser-only below: native token only, so `sendEnabled: false` until
  // their stablecoin addresses are explorer-verified. ---

  ChainDef(
    chainId: 56,
    name: 'BNB Chain',
    rpcUrl: 'https://bsc-dataseed.binance.org',
    nativeSymbol: 'BNB',
    explorerUrl: 'https://bscscan.com',
    sendEnabled: false,
    tokens: [
      TokenDef(symbol: 'BNB', decimals: 18, isNative: true),
    ],
  ),

  ChainDef(
    chainId: 43114,
    name: 'Avalanche',
    rpcUrl: 'https://api.avax.network/ext/bc/C/rpc',
    nativeSymbol: 'AVAX',
    explorerUrl: 'https://snowtrace.io',
    sendEnabled: false,
    tokens: [
      TokenDef(symbol: 'AVAX', decimals: 18, isNative: true),
    ],
  ),
];

/// The chains the Send sheet offers — [kChainRegistry] minus the browser-only
/// rows. See [ChainDef.sendEnabled] for why the two differ.
final List<ChainDef> kSendChains =
    kChainRegistry.where((c) => c.sendEnabled).toList(growable: false);

/// `0x`-prefixed lowercase hex for [chainId] — the form EIP-1193 speaks.
String chainIdToHex(int chainId) => '0x${chainId.toRadixString(16)}';

/// Parses a `0x`-prefixed hex chain id; null if absent or unparseable.
int? chainIdFromHex(String? hex) {
  if (hex == null) return null;
  final body = hex.startsWith('0x') || hex.startsWith('0X')
      ? hex.substring(2)
      : hex;
  return int.tryParse(body, radix: 16);
}

/// **The dApp browser's chain map** — `chainId (hex) → RPC URL`, handed to the
/// bridge's `ChainRegistry` at construction so the browser and the wallet
/// cannot drift onto different endpoints.
///
/// The bridge ships its own `defaultChains` as a standalone fallback; the app
/// always injects this, which is why this file is the single source. Adding a
/// chain here reaches the browser, the connect sheet's network pill, the
/// signature sheet and (unless [ChainDef.sendEnabled] is false) the Send
/// picker, in one edit.
final Map<String, String> kBridgeChainRpcMap = {
  for (final c in kChainRegistry) chainIdToHex(c.chainId): c.rpcUrl,
};

/// Display name for a `0x`-prefixed hex chain id, or null when the id is
/// unknown/absent — callers supply their own "unknown network" wording.
///
/// This replaced a hardcoded `switch` that existed **twice**, byte for byte,
/// in `connect_request_sheet.dart` and `signature_request_sheet.dart`.
String? chainNameForHex(String? hex) {
  final id = chainIdFromHex(hex);
  if (id == null) return null;
  return chainById(id)?.name;
}

/// Look up a chain by id; null if not in the registry.
ChainDef? chainById(int chainId) {
  for (final c in kChainRegistry) {
    if (c.chainId == chainId) return c;
  }
  return null;
}

/// The registry's [TokenDef] for [address] on [chainId], or null if the token
/// isn't in our list (caller then resolves a custom TokenDef on-chain).
TokenDef? tokenForAddress(int chainId, String address) {
  final c = chainById(chainId);
  if (c == null) return null;
  final a = address.toLowerCase();
  for (final t in c.tokens) {
    if (t.address != null && t.address!.toLowerCase() == a) return t;
  }
  return null;
}
