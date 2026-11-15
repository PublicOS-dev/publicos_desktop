import 'package:flutter/material.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_widget.dart';

/// Shared fullscreen overlay shell used by both [ImageOverlay] (image viewing)
/// and transaction loading screens. Provides a dark background with fade transition.
class FullscreenOverlay extends StatelessWidget {
  final Widget child;
  final bool dismissible;
  final double opacity;

  const FullscreenOverlay({
    super.key,
    required this.child,
    this.dismissible = true,
    this.opacity = 0.96,
  });

  /// Show a transaction loading overlay that blocks the entire screen.
  /// Returns a [TransactionOverlayController] to update the message or dismiss.
  static TransactionOverlayController showTransaction(
    BuildContext context,
    String initialMessage,
  ) {
    final messageNotifier = ValueNotifier<String>(initialMessage);
    final navigator = Navigator.of(context);

    navigator.push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => FullscreenOverlay(
        dismissible: false,
        opacity: 0.4,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PhigitalLoadingWidget(size: 32, showShadows: false),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: messageNotifier,
                builder: (context, message, _) => Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ));

    return TransactionOverlayController._(
      dismiss: () {
        if (navigator.canPop()) {
          navigator.pop();
        }
        messageNotifier.dispose();
      },
      updateMessage: (msg) => messageNotifier.value = msg,
    );
  }

  /// Blocking overlay variant for operations with unknown timing/behavior:
  /// rain widget tucked bottom-right, status legend dead-center. Used by
  /// the XMTP backup/restore flow where we don't want the user touching the
  /// UI while the local DB is being written.
  static TransactionOverlayController showBlocking(
    BuildContext context,
    String initialMessage,
  ) {
    final messageNotifier = ValueNotifier<String>(initialMessage);
    final navigator = Navigator.of(context);

    navigator.push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => FullscreenOverlay(
        dismissible: false,
        opacity: 0.7,
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ValueListenableBuilder<String>(
                  valueListenable: messageNotifier,
                  builder: (context, message, _) => Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              right: 16,
              bottom: 16,
              child: PixelRainLoadingWidget(size: 48, showShadows: false),
            ),
          ],
        ),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ));

    return TransactionOverlayController._(
      dismiss: () {
        if (navigator.canPop()) {
          navigator.pop();
        }
        messageNotifier.dispose();
      },
      updateMessage: (msg) => messageNotifier.value = msg,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: dismissible,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: opacity),
        body: child,
      ),
    );
  }
}

class TransactionOverlayController {
  final VoidCallback dismiss;
  final void Function(String) updateMessage;

  TransactionOverlayController._({
    required this.dismiss,
    required this.updateMessage,
  });
}
