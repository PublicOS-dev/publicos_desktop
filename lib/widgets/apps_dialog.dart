import 'dart:ui';

import 'package:flutter/material.dart';

import '../router_helpers.dart';
import '../screens/apps_view.dart';
import '../theme/glass_tokens.dart';
import '../utils/app_history.dart';

/// Apps as a BIG DIALOG (the rail's pinned Apps button, under the
/// last-visited history, opens it). Thin shell: header +
/// close; every behavior lives in the ported [AppsView] (the client's explorer
/// Apps tab — Bookmarked · My apps · All, search under All, register, grid
/// settings). Same shell as `wallet_dialog.dart`.
///
/// Picking an app inside closes the dialog stack and lands the Contacts pane
/// on the owner's profile at that app's tab — that is `AppNav.toApp`'s desktop
/// delta, not this shell's.
Future<void> showAppsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _AppsDialog(),
  );
}

class _AppsDialog extends StatelessWidget {
  const _AppsDialog();

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
            width: DialogWidth.w,
            height: maxH,
            decoration: GlassTheme.glassBox(
              context,
            ).copyWith(color: tokens.surfaceDeep.withValues(alpha: 0.92)),
            child: Column(
              children: [
                _header(context, tokens),
                Expanded(
                  child: AppsView(
                    // System tiles (Treasury · Social Graph · Nodes): close
                    // the dialog and open the full pane. The shell records
                    // the open in the rail history.
                    onOpenSystemApp: (id) {
                      final sys = systemAppById(id);
                      if (sys == null) return;
                      Navigator.of(context).pop();
                      AppNav.onOpenDestination?.call(sys.destination);
                    },
                  ),
                ),
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
          Icon(Icons.apps_rounded, color: tokens.connectedAccent, size: 20),
          const SizedBox(width: 10),
          Text(
            'APPS',
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
