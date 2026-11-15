import 'package:flutter/material.dart';

import 'package:publicos_desktop/widgets/chain_icon.dart';
import 'package:publicos_desktop/data/chain_registry.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';

/// Move THIS TAB to another chain — the first user-facing chain control in the
/// browser. Ported from publicos_client `components/browser/chain_picker_sheet.dart`;
/// identical but for the import paths and no `HapticFeedback` (desktop).
///
/// ── WHY IT EXISTS ────────────────────────────────────────────────────────────
/// Without it only a *page* can change the chain, by calling
/// `wallet_switchEthereumChain`. That is right for a modern dApp and useless
/// for the large class of pre-2021 ones written when "the wallet is already on
/// mainnet" was a safe assumption: they never ask, so they silently read our
/// chain and find nothing. `thenftmonkeytheorem.io` is the worked example —
/// its whole source contains no `wallet_*` call at all. Nothing is broken in
/// the wallet; the user simply has no other way to say "read this site on
/// Ethereum".
///
/// ── SCOPE IS ONE TAB, AND THAT IS LOAD-BEARING ───────────────────────────────
/// A `ChainRegistry` is built per webview and starts at PublicOS every time
/// (the chain is per-webview). This sheet
/// switches that one registry, so it moves the current page and nothing else —
/// not the browser, not another tab, not the app. It is deliberately NOT
/// persisted: the honest default on every fresh page is the chain we are
/// actually on, and a remembered override is how a wallet starts lying about
/// its chain.
///
/// ── WHY IT RELOADS ───────────────────────────────────────────────────────────
/// A switch emits `chainChanged` to the page, which is all the spec asks for
/// and all a modern dApp needs. A legacy dApp does not listen — it read the
/// chain once on mount — so without a reload the user switches and sees
/// nothing change, which reads as a broken control. The reload is the reason
/// the feature works on exactly the sites that need it.
class ChainPickerSheet extends StatelessWidget {
  /// The chain the tab is on now, `0x`-prefixed hex.
  final String? currentChainId;

  const ChainPickerSheet({super.key, this.currentChainId});

  /// Returns the chosen chain as `0x`-prefixed hex, or null if dismissed or
  /// the user re-picked the chain they were already on.
  static Future<String?> show({
    required BuildContext context,
    String? currentChainId,
  }) {
    return showGlassSheetDialog<String>(
      context: context,
      width: DialogWidth.m,
      builder: (_) => ChainPickerSheet(currentChainId: currentChainId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final currentId = chainIdFromHex(currentChainId);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tokens.glassFill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: NftChainIcon(chain: currentId, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.signatureRequestSheetLabelNetwork,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: tokens.starkWhite,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.browserChainPickerNote,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 11,
                            color: tokens.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                itemCount: kChainRegistry.length,
                itemBuilder: (context, i) {
                  final chain = kChainRegistry[i];
                  final selected = chain.chainId == currentId;
                  return _ChainRow(
                    chain: chain,
                    selected: selected,
                    onTap: () {
                      Navigator.of(context)
                          .pop(selected ? null : chainIdToHex(chain.chainId));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainRow extends StatelessWidget {
  final ChainDef chain;
  final bool selected;
  final VoidCallback onTap;

  const _ChainRow({
    required this.chain,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final accent = chain.isOx ? tokens.connectedAccent : tokens.fallbackAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            // Fill-only: an unselected row had NO paint but the hairline, so
            // `glassFill` takes over the edge it carried.
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.12)
                  : tokens.glassFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                NftChainIcon(chain: chain.chainId, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chain.name,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: tokens.starkWhite,
                        ),
                      ),
                      Text(
                        '${chain.nativeSymbol} · ${chain.chainId}',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 11,
                          color: tokens.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_rounded, size: 18, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
