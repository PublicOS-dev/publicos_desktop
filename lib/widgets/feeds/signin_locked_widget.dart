import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/feeds/gate_locked_shell.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// The body for `SIGNIN_REQUIRED`: the channel requires sign-in to read and
/// the user either said no (`decision == 'denied'`) or has not answered yet
/// (the ask was dismissed). One screen, two copies; Allow flips the
/// decision and the host reloads under the new posture.
///
/// Pull-to-refresh re-runs the host's plain reload — it must NEVER consent.
///
/// ⚠ **Same edit twice** — twin in the other client.
class SigninLockedWidget extends StatelessWidget {
  final Channel channel;

  /// `'denied'`, or null when the user has not answered.
  final String? decision;

  /// Called with `'accepted'` or `'denied'`; the host writes it and reloads.
  final Future<void> Function(String decision) onDecide;

  /// The host's plain reload (pull-to-refresh). Never a consent.
  final Future<void> Function() onRefresh;
  final Color? accentColor;

  const SigninLockedWidget({
    super.key,
    required this.channel,
    required this.decision,
    required this.onDecide,
    required this.onRefresh,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = GlassTokens.of(context);
    final denied = decision == PublicOSChannelSignin.denied;
    return GateLockedShell(
      icon: Icons.vpn_key_off_rounded,
      title: channel.name,
      description: channel.description,
      badge: l10n.signinLockedBadge,
      blurb: denied ? l10n.signinLockedBlurbDenied : l10n.signinLockedBlurbAsk,
      onRefresh: onRefresh,
      action: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!denied) ...[
            TextButton(
              onPressed: () => onDecide(PublicOSChannelSignin.denied),
              child: Text(l10n.channelSigninDeny,
                  style: TextStyle(color: tokens.textDim)),
            ),
            const SizedBox(width: 8),
          ],
          GatePrimaryButton(
            label: l10n.channelSigninAllow,
            icon: Icons.vpn_key_rounded,
            onPressed: () => onDecide(PublicOSChannelSignin.accepted),
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }
}
