import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Escape closes the surface it wraps: the focused media and the focused
/// post. Flutter's own
/// Escape only dismisses barrier-dismissible routes, and neither surface is
/// one (the focused post is not even a route inside the Feeds pane).
///
/// An autofocused [Focus] puts the keyboard inside the surface when it opens,
/// so the binding hears Escape without a click first. Surfaces stack the way
/// their routes do: the focused media is a route above the focused post, so
/// its own binding answers first and the post stays open.
///
/// Escape inside a text field only leaves the field; the next Escape closes
/// the surface, so a half-written comment is never thrown away by one key.
class EscapeToClose extends StatelessWidget {
  final VoidCallback onEscape;
  final Widget child;

  const EscapeToClose({super.key, required this.onEscape, required this.child});

  void _handle() {
    final focused = FocusManager.instance.primaryFocus;
    final ctx = focused?.context;
    final inText = ctx != null &&
        (ctx.widget is EditableText ||
            ctx.findAncestorWidgetOfExactType<EditableText>() != null);
    if (inText) {
      focused!.unfocus();
      return;
    }
    onEscape();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handle,
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
