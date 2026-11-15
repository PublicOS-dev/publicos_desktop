import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/wallet/wallet_avatar.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/utils/notification_kinds.dart';
import 'package:publicos_desktop/utils/own_wallets.dart';

/// Detail view for one wallet-transfer notification.
///
/// Barrier at 0.45; `showPhigitalBottomSheet` is deliberately bypassed so the
/// sheet does not get a second layer of chrome.
///
/// Reads top-to-bottom as the money moved: **who sent → what → who received →
/// the receipt**. Both parties get a full-size mark; the user's own side uses
/// the same [WalletAvatar] the Wallet tab shows, the other side its contact
/// avatar — or, when the other end is not a PublicOS account (a bare EOA, or
/// `address(0)` on a mint), **no avatar at all** and just the address.
Future<void> showTransferDetailSheet(
  BuildContext context, {
  required ActivityEvent event,
  required OwnWallet? ownWallet,
  required Contact? counterparty,
}) {
  return showGlassSheetDialog<void>(
    context: context,
    width: DialogWidth.l,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (sheetCtx) => _TransferDetailSheet(
      event: event,
      ownWallet: ownWallet,
      counterparty: counterparty,
    ),
  );
}

class _TransferDetailSheet extends StatelessWidget {
  final ActivityEvent event;
  final OwnWallet? ownWallet;
  final Contact? counterparty;

  const _TransferDetailSheet({
    required this.event,
    required this.ownWallet,
    required this.counterparty,
  });

  bool get _isIn => event.eventType == ActivityEventType.transferIn;
  bool get _isSelf => event.eventType == ActivityEventType.transferSelf;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final amount = transferAmountText(event);
    final when = DateTime.fromMillisecondsSinceEpoch(event.timestamp);

    // `actor` is always `from`, `target` always `to` — direction lives in the
    // slug, so the sheet reads the same way regardless of which side is ours.
    final fromAddr = event.actor;
    final toAddr = event.target ?? event.actor;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  _party(context, tokens, fromAddr, isFrom: true),
                  _amountBlock(context, tokens, amount),
                  _party(context, tokens, toAddr, isFrom: false),
                  const SizedBox(height: 24),
                  Divider(height: 1, color: tokens.borderSubtle),
                  const SizedBox(height: 16),
                  _details(context, tokens, when),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One end of the transfer. Which mark to draw depends on whose side it is:
  ///   * **ours** → the [WalletAvatar] the Wallet tab shows for that wallet.
  ///   * **theirs, a PublicOS account** → their contact avatar.
  ///   * **theirs, not an account** → nothing. Just the address.
  Widget _party(
    BuildContext context,
    GlassTokens tokens,
    String addr, {
    required bool isFrom,
  }) {
    final ours = ownWallet != null &&
        addr.toLowerCase() == ownWallet!.address.toLowerCase();
    // A self-move: BOTH ends are ours, but `ownWallet` only names one of them.
    // The other side is still one of the user's wallets — we just don't have
    // its label here, so it degrades to the address rather than lying.
    final label = ours
        ? ownWallet!.name
        : (counterparty?.publicosDisplayName ??
            counterparty?.displayName ??
            shortAddr(addr));

    Widget mark;
    if (ours) {
      mark = WalletAvatar(
        contact: ownWallet!.contact,
        emoji: ownWallet!.emoji,
        colorValue: ownWallet!.colorValue,
        size: 44,
      );
    } else if (counterparty != null) {
      mark = GlassContactIcon(contact: counterparty, size: 44);
    } else {
      // Not a PublicOS account — a bare EOA, a contract, or address(0) on a
      // mint. No avatar, by design.
      mark = _blankMark(tokens);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          mark,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFrom ? 'FROM' : 'TO',
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The mark for an address with no PublicOS identity behind it. A muted
  /// outline, deliberately NOT an identicon — an identicon would imply an
  /// identity we could not verify.
  Widget _blankMark(GlassTokens tokens) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Icon(Icons.tag_rounded, size: 18, color: tokens.textDim),
      );

  Widget _amountBlock(
      BuildContext context, GlassTokens tokens, String amount) {
    // Green in, plain out. A self-move is neither — no money left the user.
    final color = _isSelf
        ? tokens.textDim
        : (_isIn ? tokens.connectedAccent : tokens.starkWhite);
    final verb = _isSelf ? 'moved' : (_isIn ? 'sent' : 'sent');
    final sign = _isSelf ? '' : (_isIn ? '+' : '−');

    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 10, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            verb,
            style: TextStyle(color: tokens.textDim, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            '$sign$amount',
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _details(BuildContext context, GlassTokens tokens, DateTime when) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow(tokens, 'Time', _formatTime(when)),
        _detailRow(tokens, 'Block', '#${event.blockNumber}'),
        _detailRow(
          tokens,
          'Transaction',
          shortAddr(event.txHash),
          onTap: () {
            Clipboard.setData(ClipboardData(text: event.txHash));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transaction hash copied')),
            );
          },
        ),
        // TODO: link out to the block explorer once the chain has one wired.
        // The row shape above is already the right slot for it.
      ],
    );
  }

  Widget _detailRow(GlassTokens tokens, String label, String value,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: tokens.textDim, fontSize: 13)),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.copy_rounded, size: 13, color: tokens.textDim),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} '
        '${two(l.hour)}:${two(l.minute)}';
  }
}
