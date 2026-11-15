import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// Snackbar-level error dispatcher for signed-write failures.
///
/// Routes SSP gate failures to the right Treasury affordance per code:
///
///  - `SSP_NOT_SUBSCRIBED` → SUBSCRIBE → Treasury
///  - `SSP_WRONG`          → SWITCH    → Treasury
///  - `SSP_EXPIRED`        → RENEW     → Treasury
///  - `SSP_GATE_FAILED`    → RETRY     → no route (transient)
///
/// Accepts either a thrown [SSPGateException] (multipart upload path) or a
/// [FeedServerApiResponse] error map preserved by the channel/post wrappers
/// (which pass `errorData['error']` through verbatim from the server). All
/// other errors fall through to the [fallbackMessage] (or `Error: $error`).
///
/// **Desktop delta — the route only.** The client pushes `TreasuryPage`; desktop
/// has no nav stack and its Treasury pane is still a placeholder. So the
/// action button switches the shell to the Treasury destination via
/// [AppNav.toTreasury] instead of pushing a
/// route. The *message* — which is the load-bearing half, since it names exactly
/// why the write was refused — is verbatim. When the Treasury pane lands, the
/// action button starts working with no edit here.
void handleWriteError(
  BuildContext context,
  Object error, {
  String? fallbackMessage,
}) {
  final l10n = context.l10n;
  final gateEx = _coerceGate(error);
  if (gateEx != null) {
    final (msg, action, route) = _resolveSspGate(l10n, gateEx);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        action: action == null
            ? null
            : SnackBarAction(
                label: action,
                onPressed: () {
                  if (route) AppNav.toTreasury(context);
                },
              ),
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(localizedError(l10n, error, fallback: fallbackMessage)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Try to extract a gate exception from a thrown object, an error map (as
/// preserved on `FeedServerApiResponse.error`), or a raw `code` string.
/// Verbatim from the client.
SSPGateException? _coerceGate(Object error) {
  if (error is SSPGateException) return error;
  if (error is Map<String, dynamic>) {
    // The FeedServerApiResponse.error map already has `code` / `message` /
    // `ssp_slug` / `details` fields verbatim from the server. We don't have
    // the original HTTP status, but the code uniquely tells us which one.
    final code = error['code'];
    if (code is String) {
      final inferred = code == 'SSP_GATE_FAILED' ? 500 : 403;
      return SSPGateException.tryFromErrorMap(inferred, error);
    }
  }
  return null;
}

/// Verbatim from the client.
(String, String?, bool) _resolveSspGate(
    AppLocalizations l10n, SSPGateException e) {
  switch (e.code) {
    case 'SSP_NOT_SUBSCRIBED':
      return (
        l10n.sspNotSubscribed(e.sspSlug ?? l10n.sspThisServer),
        l10n.sspActionSubscribe,
        true,
      );
    case 'SSP_WRONG':
      return (
        l10n.sspWrong(e.otherSlug ?? l10n.sspAnotherServer),
        l10n.sspActionSwitch,
        true,
      );
    case 'SSP_EXPIRED':
      return (
        l10n.sspExpired(e.sspSlug ?? l10n.sspThisServer),
        l10n.sspActionRenew,
        true,
      );
    default:
      // SSP_GATE_FAILED — transient, no Treasury action helps.
      return (l10n.sspGateFailed, null, false);
  }
}
