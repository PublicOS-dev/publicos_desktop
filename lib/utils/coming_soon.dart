import 'package:flutter/material.dart';

import 'package:publicos_desktop/theme/glass_tokens.dart';

/// The desktop port's "not in this slice yet" affordance.
///
/// The migration ports publicos_client one feature slice at a time. A ported
/// widget routinely carries controls whose behavior belongs to a slice that has
/// not been built yet (a post's tip button reaches into the wallet; its edit
/// button reaches into the composer). The rule for those:
///
///   **show the control, dummy the handler, log the row.**
///
/// We do NOT delete the control -- deleting it makes the desktop UI silently
/// diverge from the proven client tree, and the divergence is invisible at
/// review time. We do NOT follow the import either -- that is how a read-only
/// Feeds slice accidentally becomes the 3,000-LOC Wallets slice.
///
/// Instead the control stays exactly where the client puts it and its handler
/// lands here. `grep snackComingSoon` lists every control still waiting on
/// its slice.
void snackComingSoon(BuildContext context, String what) {
  final tokens = GlassTokens.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 360,
        backgroundColor: tokens.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        content: Row(
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 18,
              color: tokens.fallbackAccent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$what — coming soon',
                style: TextStyle(color: tokens.starkWhite, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
}
