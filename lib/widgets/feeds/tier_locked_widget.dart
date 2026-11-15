import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/feeds/gate_locked_shell.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// The bodies for the read ladder's **identity-tier** refusals — rung 2 of
/// `readLadder.decide()`: `VERIFIED_ONLY` (citizens), `ACCOUNT_ONLY` (a
/// PublicOS account, not a bare key), `STANDING_REQUIRED` (a citizen or a
/// paid-up domain). Rendering these as the private-channel lock with a
/// "Request access" button would be a category error: the tier is a
/// property of the *reader*, and no owner approval
/// changes it (the ladder puts the tier above the list for exactly that
/// reason, so an owner is never asked to approve someone their own tier
/// setting will bounce).
///
/// So there is no request button here. Each state says what the channel
/// requires and offers a re-check, because the fix — getting vouched, signing
/// in with an account, paying the domain — happens elsewhere in the app.
///
/// ⚠ **Same edit twice** — twin of
/// `publicos_client/lib/components/feeds/tier_locked_widget.dart`.
class TierLockedWidget extends StatelessWidget {
  /// One of `VERIFIED_ONLY` · `ACCOUNT_ONLY` · `STANDING_REQUIRED`.
  final String code;
  final Channel channel;
  final Future<void> Function() onRetry;
  final Color? accentColor;

  const TierLockedWidget({
    super.key,
    required this.code,
    required this.channel,
    required this.onRetry,
    this.accentColor,
  });

  static const codes = <String>[
    'VERIFIED_ONLY',
    'ACCOUNT_ONLY',
    'STANDING_REQUIRED',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, badge, blurb) = switch (code) {
      'VERIFIED_ONLY' => (
          Icons.verified_rounded,
          l10n.tierLockedWidgetVerifiedOnlyBadge,
          l10n.tierLockedWidgetVerifiedOnlyBlurb,
        ),
      'ACCOUNT_ONLY' => (
          Icons.badge_rounded,
          l10n.tierLockedWidgetAccountOnlyBadge,
          l10n.tierLockedWidgetAccountOnlyBlurb,
        ),
      _ => (
          Icons.shield_rounded,
          l10n.tierLockedWidgetStandingBadge,
          l10n.tierLockedWidgetStandingBlurb,
        ),
    };
    return GateLockedShell(
      icon: icon,
      title: channel.name,
      description: channel.description,
      badge: badge,
      blurb: blurb,
      onRefresh: onRetry,
      action: GatePrimaryButton(
        label: l10n.tierLockedWidgetRetry,
        icon: Icons.refresh_rounded,
        onPressed: onRetry,
        accentColor: accentColor,
      ),
    );
  }
}
