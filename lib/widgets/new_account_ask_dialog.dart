import 'package:flutter/material.dart';

import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Two small glass dialogs for getting an account without a sponsor at hand
/// (the public beta's claim door, publicos_claim).
///
/// [showNewAccountAskDialog] comes right after NEW ACCOUNT has made the key and
/// signed the claim, before the QR: does the newcomer have a citizen to scan it,
/// or should the claim page create the account. [showImportKeyLinkDialog]
/// confirms a `publicos://import_key/<words>/<name>` link (the claim page's QR
/// for an account whose words were made in a browser).

/// true = "help me out" (open the claim page), false = "I have a citizen friend"
/// (show the QR), null = closed.
Future<bool?> showNewAccountAskDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final tokens = GlassTokens.of(ctx);
      final l10n = ctx.l10n;
      return _GlassShell(
        title: l10n.newAccountAskTitle,
        body: l10n.newAccountAskBody,
        actions: [
          _primary(tokens, l10n.newAccountAskFriend, () => Navigator.pop(ctx, false)),
          const SizedBox(height: 10),
          _outlined(tokens, l10n.newAccountAskHelp, () => Navigator.pop(ctx, true)),
        ],
      );
    },
  );
}

/// true = import the words. [name] may be empty (an older or hand-made link).
Future<bool?> showImportKeyLinkDialog(BuildContext context, {required String name}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final tokens = GlassTokens.of(ctx);
      final l10n = ctx.l10n;
      return _GlassShell(
        title: l10n.importKeyLinkTitle,
        body: name.isEmpty ? l10n.importKeyLinkBodyNoName : l10n.importKeyLinkBody(name),
        actions: [
          _primary(tokens, l10n.importKeyLinkAccept, () => Navigator.pop(ctx, true)),
          const SizedBox(height: 10),
          _outlined(tokens, l10n.newKeyFlowCancel, () => Navigator.pop(ctx, false)),
        ],
      );
    },
  );
}

class _GlassShell extends StatelessWidget {
  final String title;
  final String body;
  final List<Widget> actions;
  const _GlassShell({required this.title, required this.body, required this.actions});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Dialog(
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: GlassTheme.glassBox(context).copyWith(color: tokens.surfaceDeep),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.25,
                color: tokens.starkWhite,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.textDim, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 22),
            ...actions,
          ],
        ),
      ),
    );
  }
}

Widget _primary(GlassTokens tokens, String label, VoidCallback onPressed) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: tokens.starkWhite,
      foregroundColor: tokens.background,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
    ),
    onPressed: onPressed,
    child: Text(label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
  );
}

Widget _outlined(GlassTokens tokens, String label, VoidCallback onPressed) {
  return OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: tokens.starkWhite,
      side: BorderSide(color: tokens.borderMedium),
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
    ),
    onPressed: onPressed,
    child: Text(label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
  );
}
