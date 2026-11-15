import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import '../theme/glass_tokens.dart';
import 'trust_tree_screen.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// The Social Graph pane (shell index 11) — thin host for the ported client
/// [TrustTreeScreen]. Opens centered on the signed-in user; node taps fly
/// through the graph, `AppNav.toContact` from the detail card lands in the
/// Contacts pane as usual.
class GraphPane extends StatelessWidget {
  const GraphPane({super.key});

  @override
  Widget build(BuildContext context) {
    final hex = PublicOS.myPublicosAddress;
    if (hex == null) {
      // No session address (shouldn't happen post-login) — quiet fallback.
      final tokens = GlassTokens.of(context);
      return Center(
        child: Text(
          context.l10n.desktopNoAccountLoaded,
          style: TextStyle(color: tokens.textDim, fontSize: 13),
        ),
      );
    }
    return TrustTreeScreen(initialAddress: EthereumAddress.fromHex(hex));
  }
}
