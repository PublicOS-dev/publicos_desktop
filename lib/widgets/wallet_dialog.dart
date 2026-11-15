import 'dart:ui';

import 'package:flutter/material.dart';

import '../screens/wallet_view.dart';
import '../theme/glass_tokens.dart';

/// Wallets as a BIG DIALOG (a footer action row under
/// Keychain; the Wallets nav row — index 4 — intercepts to the same dialog,
/// mirroring the BSP/SSP pattern). Thin shell: header + close; every behavior
/// lives in the ported [WalletView] (the client's explorer wallet tab).
Future<void> showWalletDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _WalletDialog(),
  );
}

class _WalletDialog extends StatelessWidget {
  const _WalletDialog();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final maxH = MediaQuery.of(context).size.height * 0.86;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            width: DialogWidth.xl,
            height: maxH,
            decoration: GlassTheme.glassBox(
              context,
            ).copyWith(color: tokens.surfaceDeep.withValues(alpha: 0.92)),
            child: Column(
              children: [
                _header(context, tokens),
                const Expanded(child: WalletView()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, GlassTokens tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 12, 0),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              color: tokens.connectedAccent, size: 20),
          const SizedBox(width: 10),
          Text(
            'WALLETS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: tokens.starkWhite,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Close',
            icon: Icon(Icons.close_rounded, size: 19, color: tokens.textDim),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
