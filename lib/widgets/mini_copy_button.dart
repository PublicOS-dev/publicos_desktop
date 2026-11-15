import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../l10n/l10n_ext.dart';
import '../theme/glass_tokens.dart';

/// The 11px copy glyph that trails an address — the same glyph
/// `settings_pane.dart`'s `_kvRow` puts after a copyable value, lifted into a
/// widget so the shell's two address chips (status-bar session key, rail user
/// chip account address) share one behavior: tap → clipboard + the snackbar
/// the keychain already uses (`keychainAddressCopied`).
///
/// Its own [InkWell] sits INSIDE the chip's tap target on purpose: the inner
/// gesture wins the arena, so the copy never also opens the keychain / My
/// Account behind it.
class MiniCopyButton extends StatelessWidget {
  final String value;

  const MiniCopyButton({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Tooltip(
      message: context.l10n.walletActionCopy,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            final messenger = ScaffoldMessenger.maybeOf(context);
            messenger
              ?..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(context.l10n.keychainAddressCopied)),
              );
          },
          borderRadius: BorderRadius.circular(5),
          hoverColor: tokens.glassFillHover,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Icon(Icons.copy_rounded, size: 11, color: tokens.textDim),
          ),
        ),
      ),
    );
  }
}
