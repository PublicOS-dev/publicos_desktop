import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// The discovery ASK, a dialog.
///
/// Fired by `PostsList` once per channel per mount, only when a key is
/// loaded, the reader-wide default is OFF, the channel has signalled sign-in
/// and the user has not answered. Copy from the signalled `mode`.
///
/// Returns `'accepted'` | `'denied'` | null (dismissed → the decision stays
/// null and the channel is asked again on its next open).
///
/// ⚠ Same edit twice — twin in the other client.
Future<String?> showChannelSigninAskDialog(
  BuildContext context, {
  required String mode,
}) {
  final tokens = GlassTokens.of(context);
  final l10n = context.l10n;
  final body = mode == 'required'
      ? l10n.channelSigninBodyRequired
      : l10n.channelSigninBodyOptional;
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.borderSubtle),
      ),
      title: Row(
        children: [
          Icon(Icons.vpn_key_rounded, size: 20, color: tokens.textDim),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.channelSigninTitle,
              style: TextStyle(color: tokens.starkWhite, fontSize: 17),
            ),
          ),
        ],
      ),
      // DESKTOP DELTA: AlertDialog sizes to the body's intrinsic width, and
      // on a wide window that lets the copy run out across the window. Width
      // comes from `constraints` (DialogWidth.s); the content fills it.
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
      content: SizedBox(
        width: double.maxFinite,
        child: Text(
          body,
          style: TextStyle(color: tokens.textDim, fontSize: 13, height: 1.4),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, PublicOSChannelSignin.denied),
          child: Text(l10n.channelSigninDeny,
              style: TextStyle(color: tokens.textDim)),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, PublicOSChannelSignin.accepted),
          child: Text(
            l10n.channelSigninAllow,
            style: TextStyle(
              color: tokens.fallbackAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

/// What the key menu returned. `decision` is `'accepted'` / `'denied'` /
/// null (Forget) — wrapped so "closed without choosing" (a null result from
/// `showDialog`) is distinguishable from "Forget".
class ChannelSigninChoice {
  final String? decision;
  const ChannelSigninChoice(this.decision);
}

/// The key MENU: current state on top, then Allow · Deny ·
/// Forget. Forget is offered only when there is an answer to forget.
///
/// ⚠ Same edit twice — twin in the other client.
Future<ChannelSigninChoice?> showChannelSigninMenu(
  BuildContext context, {
  required ChannelSigninPref pref,
  required bool effective,
}) {
  final tokens = GlassTokens.of(context);
  final l10n = context.l10n;
  final body = pref.mode == 'required'
      ? l10n.channelSigninBodyRequired
      : l10n.channelSigninBodyOptional;
  final state =
      effective ? l10n.channelSigninStateOn : l10n.channelSigninStateOff;

  Widget row({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return ListTile(
      dense: true,
      enabled: enabled,
      leading: Icon(icon,
          size: 20,
          color: selected
              ? tokens.fallbackAccent
              : (enabled ? tokens.starkWhite : tokens.textDim)),
      title: Text(label,
          style: TextStyle(
            color: enabled ? tokens.starkWhite : tokens.textDim,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          )),
      trailing: selected
          ? Icon(Icons.check_rounded, size: 18, color: tokens.fallbackAccent)
          : null,
      onTap: onTap,
    );
  }

  return showDialog<ChannelSigninChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.borderSubtle),
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      title: Row(
        children: [
          Icon(
            effective ? Icons.vpn_key_rounded : Icons.vpn_key_off_rounded,
            size: 20,
            color: effective ? tokens.starkWhite : tokens.textDim,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.channelSigninMenuTitle,
              style: TextStyle(color: tokens.starkWhite, fontSize: 17),
            ),
          ),
        ],
      ),
      // DESKTOP DELTA: width cap, DialogWidth.m (a picker); the content
      // fills it.
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
              child: Text(
                '$state\n\n$body',
                style:
                    TextStyle(color: tokens.textDim, fontSize: 13, height: 1.4),
              ),
            ),
            Divider(height: 1, color: tokens.borderSubtle),
            row(
              icon: Icons.vpn_key_rounded,
              label: l10n.channelSigninAllow,
              selected: pref.decision == PublicOSChannelSignin.accepted,
              onTap: () => Navigator.pop(
                  ctx, const ChannelSigninChoice(PublicOSChannelSignin.accepted)),
            ),
            row(
              icon: Icons.vpn_key_off_rounded,
              label: l10n.channelSigninDeny,
              selected: pref.decision == PublicOSChannelSignin.denied,
              onTap: () => Navigator.pop(
                  ctx, const ChannelSigninChoice(PublicOSChannelSignin.denied)),
            ),
            row(
              icon: Icons.restart_alt_rounded,
              label: l10n.channelSigninForget,
              selected: false,
              onTap: pref.decision == null
                  ? null
                  : () => Navigator.pop(ctx, const ChannelSigninChoice(null)),
            ),
          ],
        ),
      ),
    ),
  );
}
