import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// The identity mark for one of the user's own wallets.
///
/// Shared with `wallet_view.dart` so the **wallet notification
/// rows use the exact same mark as the Wallet tab** — the two can't drift,
/// because there is one implementation, not a copy. `wallet_view` delegates
/// its private `_emojiTile` to [walletEmojiTile] below.
///
/// Two looks, matching the Wallet tab exactly:
///   * **org / group Safe** → the org's on-chain avatar ([GlassContactIcon]).
///   * **everything else** (personal main Safe, keychain EOA, linked wallet) →
///     a tinted square **emoji tile**: the user's picked icon, else the
///     keychain key's own emoji, else 🪙.
///
/// There is deliberately **no `Icon()` avatar** anywhere in this family — the
/// wallet *type* is conveyed by a separate small glyph beside the name
/// (shield / key / link), not by the mark itself.

/// Default wallet glyph when nothing else is set. Mirrors
/// `wallet_view.dart::_kDefaultWalletIcon`.
const String kDefaultWalletIcon = '🪙';

const String _kWalletIconKeyPrefix = 'wallet_icon_';

/// Settings key for a wallet's LOCAL icon override — device-scoped, free.
String walletIconKey(String address) =>
    '$_kWalletIconKeyPrefix${address.toLowerCase()}';

/// Read a wallet's local icon override (null if unset). Free Drift read.
Future<String?> loadWalletIcon(String address) async {
  try {
    final rec = await PublicOSSettings.getSetting(walletIconKey(address));
    return rec?.value;
  } catch (_) {
    return null;
  }
}

/// A tinted square emoji tile — the keychain-key look, reused for a Safe's
/// user-picked icon. **The canonical wallet mark.**
Widget walletEmojiTile(
  String emoji,
  double size,
  double cornerRadius,
  Color accent,
  bool isDark,
) {
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
      borderRadius: BorderRadius.circular(cornerRadius),
    ),
    child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
  );
}

/// The wallet mark, resolved from a wallet's identity.
///
/// Pass [contact] for an org/group Safe (renders its avatar); otherwise pass
/// [emoji] and/or [colorValue] and it renders the emoji tile. A keychain key
/// carries both; a personal main Safe carries neither and falls back to 🪙 on
/// the connected accent — which is precisely what the Wallet tab shows.
class WalletAvatar extends StatelessWidget {
  /// The org's contact, for a group Safe. Null for every other kind.
  final Contact? contact;

  /// The user's picked override, else the keychain key's own emoji. Null → 🪙.
  final String? emoji;

  /// The keychain key's colour (`key['color']`). Null → the connected accent.
  final int? colorValue;

  final double size;
  final VoidCallback? onTap;

  const WalletAvatar({
    super.key,
    this.contact,
    this.emoji,
    this.colorValue,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (contact != null) {
      return GlassContactIcon(contact: contact, size: size, onTap: onTap);
    }

    final accent =
        colorValue != null ? Color(colorValue!) : tokens.connectedAccent;
    // Corner radius tracks the Wallet tab's ratio (12 @ 50px).
    final tile = walletEmojiTile(
      emoji?.isNotEmpty == true ? emoji! : kDefaultWalletIcon,
      size,
      size * 0.24,
      accent,
      isDark,
    );
    return onTap == null ? tile : GestureDetector(onTap: onTap, child: tile);
  }
}
