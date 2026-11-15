import 'package:flutter/material.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// **DESKTOP DELTA — the in-content-area page host.**
///
/// The client's feeds flow pages (`ComposePostPage`, `CreateChannelPage`,
/// `ManageChannelPage`, `ManageServerPage`) are pushed as full-screen routes
/// and communicate through `Navigator.pop(context, result)` — and some push
/// further pages themselves (ManageServer opens ManageChannel per channel).
/// Desktop renders them **inside the feeds reading column** instead.
///
/// Rendering a route-shaped page without a route breaks three things at once:
/// `pop` has nowhere to go, pop RESULTS have no listener, and internal pushes
/// would land on the shell's root navigator (covering the whole window). A
/// nested [Navigator] fixes all three with zero edits to the ported pages:
/// the page lives on a real route, so `Navigator.of(context)` resolves to
/// THIS navigator, `pop(result)` works, `automaticallyImplyLeading` derives a
/// back arrow, and internal pushes stack in place.
///
/// Mechanics: the nested navigator's root route is an invisible underlay that
/// immediately pushes [page] on top and awaits it. When the page pops (back
/// arrow, or `pop(result)`), the await completes → [onClose] fires with the
/// result and the host is removed by its owner. The underlay never pops, so
/// the nested navigator is never emptied.
///
/// Note: `showDialog` defaults to `useRootNavigator: true`, so dialogs opened
/// by hosted pages still overlay the whole window — which is exactly the
/// desktop dialog convention.
/// Host a route-shaped client page in a BIG DIALOG (the SSP-MANAGE pattern,
/// generalized for Messages: create-group, manage-inbox-IDs).
/// Returns the page's pop result — `CreateGroupPage` pops the new group's
/// topic, so the caller's client-verbatim follow-up flow keeps working.
Future<T?> showFlowPageDialog<T>(
  BuildContext context, {
  required Widget page,
  double maxWidth = DialogWidth.xl,
  double maxHeight = 720,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogCtx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: InlineFlowHost(
            page: page,
            onClose: (result) => Navigator.of(dialogCtx).pop(result as T?),
          ),
        ),
      ),
    ),
  );
}

class InlineFlowHost extends StatefulWidget {
  /// The client page to host, verbatim.
  final Widget page;

  /// Fired exactly once, with the page's pop result (null when dismissed).
  final void Function(Object? result) onClose;

  const InlineFlowHost({super.key, required this.page, required this.onClose});

  @override
  State<InlineFlowHost> createState() => _InlineFlowHostState();
}

class _InlineFlowHostState extends State<InlineFlowHost> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  bool _closed = false;

  void _finish(Object? result) {
    if (_closed) return;
    _closed = true;
    widget.onClose(result);
  }

  @override
  Widget build(BuildContext context) {
    // Own ScaffoldMessenger: without it the hosted page's Scaffold registers
    // with the MaterialApp root messenger — the same one the shell's Scaffold
    // uses — and one showSnackBar renders in BOTH (dialog + app). Scoping it
    // here keeps snacks inside the host, zero edits to the ported pages.
    return ScaffoldMessenger(
      child: Navigator(
        key: _navKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => _FlowUnderlay(
            page: widget.page,
            onDone: _finish,
          ),
        ),
      ),
    );
  }
}

/// The nested navigator's permanent root route. Pushes the real page on the
/// first frame and reports its pop result up. Renders nothing itself — by the
/// time it could be seen, the page is already on top; after the page pops the
/// whole host is removed within the same frame.
class _FlowUnderlay extends StatefulWidget {
  final Widget page;
  final void Function(Object? result) onDone;

  const _FlowUnderlay({required this.page, required this.onDone});

  @override
  State<_FlowUnderlay> createState() => _FlowUnderlayState();
}

class _FlowUnderlayState extends State<_FlowUnderlay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final result = await Navigator.of(context).push<Object?>(
        MaterialPageRoute(builder: (_) => widget.page),
      );
      widget.onDone(result);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
