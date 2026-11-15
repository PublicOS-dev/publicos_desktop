import 'package:flutter/material.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// The desktop shell for a widget the client shows as a bottom sheet.
///
/// **The standing rule: bottom sheets are rare on desktop —
/// a big centred dialog is the right container, and we have the space.** So a
/// port keeps the sheet's BODY verbatim (including a `DraggableScrollableSheet`
/// where the client used one — it sizes against the constraints it is given,
/// and inside these constraints that is the dialog) and swaps only the shell.
/// The only body edits a re-shell should need are dropping the drag handle and
/// squaring the sheet's top-only radius to all four corners.
///
/// Height is capped at 85 % of the window so a tall sheet scrolls inside the
/// dialog instead of running off the canvas; [width] is the one knob callers
/// tune per surface (480 suits a form, ~720 an editor with a live preview).
Future<T?> showGlassSheetDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double width = DialogWidth.m,
  // A sheet that was `isDismissible: false` (e.g. a signature request, where a
  // scrim tap must not count as an answer) maps to `barrierDismissible: false`.
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  Color? barrierColor,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    useRootNavigator: useRootNavigator,
    builder: (dialogCtx) => Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: MediaQuery.of(dialogCtx).size.height * 0.85,
        ),
        child: Builder(builder: builder),
      ),
    ),
  );
}
