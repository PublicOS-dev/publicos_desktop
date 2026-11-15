import 'package:flutter/material.dart';

import 'package:publicos_desktop/widgets/pixel_rain_loading_widget.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// The one body every read-gate refusal renders into.
///
/// The server refuses a channel read with one of six codes
/// (`readLadder.decide()`, blacklist → tier → lists → paywall) and each code
/// gets its own screen — but they are the *same* screen with different words
/// and a different button: an icon tile, the channel's name and description,
/// a small uppercase badge, a blurb, an optional error line, an action area.
/// One shared shell, so the private, paywall and tier bodies cannot drift
/// from each other.
///
/// Pull-to-refresh wraps the whole thing — swiping down re-runs [onRefresh]
/// so a user can re-check approval / payment without leaving the screen.
///
/// ⚠ **Same edit twice** — twin of
/// `publicos_client/lib/components/feeds/gate_locked_shell.dart`.
class GateLockedShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String badge;
  final String blurb;
  final String? errorText;

  /// Anything under the blurb: a price line, a stepper, a chip.
  final Widget? detail;

  /// The button(s). Null hides the action area entirely.
  final Widget? action;
  final Future<void> Function() onRefresh;

  /// While true, renders the ambient corner rain instead of the body — the
  /// initial status fetch is in flight.
  final bool resolving;

  const GateLockedShell({
    super.key,
    required this.icon,
    required this.title,
    required this.badge,
    required this.blurb,
    required this.onRefresh,
    this.description,
    this.errorText,
    this.detail,
    this.action,
    this.resolving = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: tokens.starkWhite,
      backgroundColor: tokens.surfaceElevated,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: resolving ? _resolvingBody() : _body(context, tokens),
          ),
        ],
      ),
    );
  }

  Widget _resolvingBody() {
    // Unobtrusive corner loader — ambient activity, not a blocking spinner.
    return const Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.only(right: 24, bottom: 24),
        child: PixelRainLoadingWidget(size: 48, showShadows: false),
      ),
    );
  }

  Widget _body(BuildContext context, GlassTokens tokens) {
    final desc = description;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GateIconTile(icon: icon),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.starkWhite,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            if (desc != null && desc.isNotEmpty)
              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tokens.textDim,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 18),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: tokens.borderSubtle, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: tokens.textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              blurb,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.textDim,
                fontSize: 12,
                height: 1.55,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 16),
              detail!,
            ],
            if (errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                errorText!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tokens.fallbackAccent,
                  fontSize: 11,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 26),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// The 88px icon tile at the top of every gate body.
class GateIconTile extends StatelessWidget {
  final IconData icon;
  const GateIconTile({super.key, this.icon = Icons.lock_rounded});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.borderMedium, width: 1),
        boxShadow: [
          BoxShadow(
            color: tokens.glassShadow,
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Icon(icon, size: 38, color: tokens.starkWhite),
    );
  }
}

/// The gate bodies' one button style. `destructive` paints it in the error
/// colour (Cancel request); `accentColor` tints it to the feed's colour.
class GatePrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool destructive;
  final Color? accentColor;

  const GatePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final fg = destructive
        ? Theme.of(context).colorScheme.error
        : (accentColor ?? tokens.starkWhite);
    final borderColor = destructive
        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.5)
        : (accentColor?.withValues(alpha: 0.5) ?? tokens.borderMedium);
    return Material(
      color: tokens.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The acting-state placeholder for an action area: same height as the
/// button it replaces, so the layout does not jump.
class GateActingIndicator extends StatelessWidget {
  const GateActingIndicator({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 44,
        child: Center(
          child: PixelRainLoadingWidget(size: 32, showShadows: false),
        ),
      );
}
