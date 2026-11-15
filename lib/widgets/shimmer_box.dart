import 'package:flutter/material.dart';

/// A rounded placeholder with a diagonal highlight that sweeps across, driven by
/// a repeating [progress] animation (0→1). The canonical loading-skeleton block:
/// a [base]-filled rounded rect with a moving [highlight] band. Compose several
/// (card fill, avatar slot, text lines) into a skeleton that mirrors the shape
/// of the real content so nothing jumps when the data lands.
///
/// Shared by the trust-tree profile-card skeleton and the onboarding identity
/// card; host a single repeating [AnimationController] and pass it as [progress]
/// to every box so they sweep in sync.
class ShimmerBox extends StatelessWidget {
  final Animation<double> progress;
  final double width;
  final double height;
  final double radius;
  final Color base;
  final Color highlight;

  const ShimmerBox({
    super.key,
    required this.progress,
    required this.height,
    required this.base,
    required this.highlight,
    this.width = double.infinity,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          final dx = -2.0 + 4.0 * progress.value; // sweep off-left → off-right
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment(dx - 1, -0.2),
                end: Alignment(dx + 1, 0.2),
                colors: [base, highlight, base],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}
