import 'package:flutter/material.dart';

import 'package:publicos_desktop/screens/notifications_screen.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// The on-chain activity feed as a **content-sized dialog**: not a dedicated
/// page, a dialog that grows taller with the list.
///
/// The client pushes `NotificationsScreen` as a full route from the app-bar
/// bell. Desktop has no app bar and no route stack to push onto from the
/// shell, and a full-height page for what is usually three rows reads as
/// empty. So the same widget is mounted in `asDialogBody` mode and this frame
/// supplies the chrome.
///
/// **How the growth works** — three cooperating pieces, none of which can be
/// dropped:
///   1. this `ConstrainedBox` sets only a MAX height, never a fixed one;
///   2. `NotificationsScreen`'s dialog mode uses `Column(mainAxisSize: min)`
///      with a `shrinkWrap`ed list, so it reports its natural height;
///   3. the `Flexible` inside that column lets the list scroll once the
///      natural height reaches the cap.
/// Take away (2) and the dialog is always full height; take away (3) and a
/// long list overflows instead of scrolling.
Future<void> showNotificationsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const _NotificationsDialog(),
  );
}

class _NotificationsDialog extends StatelessWidget {
  const _NotificationsDialog();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: ConstrainedBox(
        // A legitimate MediaQuery.size read: this is a dialog measured against
        // the WINDOW, which is exactly what the window size means. (Contrast
        // ported phone code, where it stands in for a widget's own width.)
        constraints: BoxConstraints(
          maxWidth: DialogWidth.l,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: tokens.glassShadow,
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: const NotificationsScreen(asDialogBody: true),
        ),
      ),
    );
  }
}
