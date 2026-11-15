import 'package:flutter/material.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/theme/theme_provider.dart';

/// Desktop mirror of the client's `showPhigitalBottomSheet` (components/
/// phigital_bottom_sheet.dart) — SAME function signature, so ported sheet
/// bodies keep zero body edits, but the presentation is a centered glass
/// dialog instead of a modal bottom sheet (the standing sheets→dialogs
/// desktop delta).
///
/// Parameter mapping:
/// - `isDismissible` → `barrierDismissible`.
/// - `useDraggable` / `maxChildSize` → the dialog's max height fraction
///   (there is nothing to drag on desktop; the content sizes itself up to
///   that cap).
/// - `enableDrag`, `showHandle`, `initialChildSize`, `minChildSize` →
///   accepted and ignored (no drag affordances, no handle bar in a dialog).
/// - `wrapInChrome` → honored: true wraps the body in the phigital card
///   chrome (background + border, full radius — no handle); false hands the
///   body its own visuals, exactly like the client.
Future<T?> showPhigitalBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context, bool isDark) builder,
  bool useDraggable = false,
  double initialChildSize = 0.5,
  double minChildSize = 0.25,
  double maxChildSize = 0.9,
  bool enableDrag = true,
  bool isDismissible = true,
  bool showHandle = true,
  bool wrapInChrome = true,
  RouteSettings? routeSettings,
  // Desktop-only knob: the dialog's max width.
  // Readers (agreement, citizenship claim) pass DialogWidth.l.
  double maxWidth = DialogWidth.m,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    routeSettings: routeSettings,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final isDark = theme.brightness == Brightness.dark;
      final maxHeightFraction = useDraggable ? maxChildSize : 0.85;

      Widget child = builder(dialogContext, isDark);
      if (wrapInChrome) {
        child = Container(
          decoration: BoxDecoration(
            color: PhigitalStyle.cardBackground(isDark),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: PhigitalStyle.cardBorder(isDark),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Flexible(child: child)],
          ),
        );
      }

      return Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight:
                MediaQuery.of(dialogContext).size.height * maxHeightFraction,
          ),
          child: child,
        ),
      );
    },
  );
}
