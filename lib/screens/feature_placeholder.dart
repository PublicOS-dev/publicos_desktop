import 'package:flutter/material.dart';

import '../theme/glass_tokens.dart';

/// A feature pane that has no glass-dark implementation yet.
///
/// The shell provides the sidebar + multi-pane frame; a destination whose
/// feature pane does not exist yet renders this honest placeholder.
///
/// Pane anatomy mirrors how the real panes will read: a left-aligned header
/// (icon + title + an UPCOMING chip) over a centered "coming soon" body, on the
/// shell's `background`. An optional [footer] hangs an extra action under the
/// body (the Settings pane uses it for Log out while real Settings is pending).
class FeaturePlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;

  /// One-line description of what the pane will hold once migrated.
  final String blurb;

  /// Optional extra affordance shown below the placeholder body.
  final Widget? footer;

  const FeaturePlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.blurb,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      color: tokens.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(tokens),
          Expanded(child: _body(tokens)),
        ],
      ),
    );
  }

  Widget _header(GlassTokens tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tokens.glassFill,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Icon(icon, size: 20, color: tokens.starkWhite),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: tokens.starkWhite,
            ),
          ),
          const SizedBox(width: 12),
          _chip(tokens),
        ],
      ),
    );
  }

  Widget _chip(GlassTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tokens.fallbackAccent.withValues(alpha: 0.12),
        border: Border.all(color: tokens.fallbackAccent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'UPCOMING',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: tokens.fallbackAccent,
        ),
      ),
    );
  }

  Widget _body(GlassTokens tokens) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: tokens.glassFill,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Icon(icon, size: 30, color: tokens.textDim),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: tokens.starkWhite,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              blurb,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: tokens.textDim,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Lands in an upcoming slice of the glass-dark rebuild.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: tokens.textDim.withValues(alpha: 0.6),
              ),
            ),
            if (footer != null) ...[
              const SizedBox(height: 28),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
