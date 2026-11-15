import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../theme/glass_tokens.dart';

/// PublicOS brand mark / loading widget. Copied from publicos_client
/// (`components/phigital_loading_widget.dart`) — the canonical "phigital" logo:
/// a blocky planet with orbiting moon(s), hard offset shadows. Self-contained
/// apart from [GlassTokens] (for the default color). The only edit vs the
/// client is the theme import.
///
/// Two modes:
/// - **Loading** (pulse: false): constant orbit. The app-wide loading affordance.
/// - **Logo** (pulse: true): 8s spin + 1s pause with a subtle pulse. Brand mark.
class PhigitalLoadingWidget extends StatefulWidget {
  final bool? rotate;
  final double size;
  final bool showShadows;
  final bool pulse;
  final bool group;
  final Color? color;

  const PhigitalLoadingWidget({
    super.key,
    this.rotate = true,
    this.size = 48,
    this.showShadows = true,
    this.pulse = false,
    this.group = false,
    this.color,
  });

  @override
  State<PhigitalLoadingWidget> createState() => _PhigitalLoadingWidgetState();
}

class _PhigitalLoadingWidgetState extends State<PhigitalLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _orbitController;
  late Animation<double> _orbitAnimation;
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    if (widget.pulse) {
      _orbitController = AnimationController(
        duration: const Duration(seconds: 9),
        vsync: this,
      );
      _orbitAnimation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 8.0,
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(1.0),
          weight: 1.0,
        ),
      ]).animate(_orbitController);

      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );

      if (widget.rotate == true) {
        _orbitController.repeat();
        _pulseController!.repeat(reverse: true);
      }
    } else {
      _orbitController = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      );
      _orbitAnimation =
          Tween<double>(begin: 0.0, end: 1.0).animate(_orbitController);

      if (widget.rotate == true) {
        _orbitController.repeat();
      }
    }
  }

  @override
  void didUpdateWidget(PhigitalLoadingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.pulse != oldWidget.pulse) {
      _orbitController.dispose();
      _pulseController?.dispose();
      _setupAnimations();
      return;
    }

    if (widget.rotate != oldWidget.rotate) {
      if (widget.rotate == true) {
        _orbitController.repeat();
        _pulseController?.repeat(reverse: true);
      } else {
        _orbitController.stop();
        _pulseController?.stop();
      }
    }
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final primaryColor = widget.color ?? tokens.starkWhite;

    final size = widget.size;
    final containerSize = size * 2.9;
    final orbitOffset = size * 0.875;
    final orbitingSize = size * 0.375;
    final mainRadius = size * 0.42;
    final orbitingRadius = orbitingSize * 0.44;
    final moonCount = widget.group ? 3 : 1;

    return Center(
      child: AnimatedBuilder(
        animation: _pulseController != null
            ? Listenable.merge([_orbitController, _pulseController!])
            : _orbitController,
        builder: (context, child) {
          final pulseScale = _pulseController != null
              ? 1.0 + (_pulseController!.value * 0.03)
              : 1.0;

          final startAngle = widget.pulse ? -math.pi / 2 : 0.0;
          final currentAngle =
              (_orbitAnimation.value * 2 * math.pi) + startAngle;

          return SizedBox(
            width: containerSize,
            height: containerSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: pulseScale,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(mainRadius),
                      boxShadow: widget.showShadows
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                offset: const Offset(0, 3),
                                blurRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
                for (int i = 0; i < moonCount; i++)
                  Transform.rotate(
                    angle: currentAngle + (i * 2 * math.pi / moonCount),
                    child: Transform.translate(
                      offset: Offset(orbitOffset, 0),
                      child: Transform.rotate(
                        angle: -(currentAngle + (i * 2 * math.pi / moonCount)),
                        child: Container(
                          width: orbitingSize,
                          height: orbitingSize,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(orbitingRadius),
                            boxShadow: widget.showShadows
                                ? [
                                    BoxShadow(
                                      color: primaryColor.withValues(
                                          alpha: 0.25),
                                      offset: const Offset(0, 2),
                                      blurRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
