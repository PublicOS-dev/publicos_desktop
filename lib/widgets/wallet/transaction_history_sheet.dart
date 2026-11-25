import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/send_icon.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';

/// Compact relative time — "now / 5m / 2h / 3d / 2w / 4mo / 1y". Shared by the
/// wallet card's in-line transaction preview and this sheet.
String txRelativeTime(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  if (d.inDays < 7) return '${d.inDays}d';
  if (d.inDays < 30) return '${(d.inDays / 7).floor()}w';
  if (d.inDays < 365) return '${(d.inDays / 30).floor()}mo';
  return '${(d.inDays / 365).floor()}y';
}

/// Incoming (received) accent and outgoing (sent) accent for a transfer row.
const _kIncoming = Color(0xFF34d399); // green
const _kOutgoing = Color(0xFFf87171); // soft red

/// Full transaction-history bottom sheet for one wallet. Presentational: it's
/// handed the first page of [transfers] (OX, newest-first, from the device's
/// stored history, `PublicOSWallets.getTransferHistory`) and asks its caller
/// for each older page as the user scrolls ([onLoadMore]).
/// It never reads the chain or the database itself.
/// A quiet wallet shows the empty state; the loader shows while the first scan
/// is still in flight.
class TransactionHistorySheet extends StatefulWidget {
  /// The wallet (Safe) address whose activity this is — decides send/receive.
  final String address;
  final List<TokenTransfer> transfers;
  final bool loading;

  /// Counterparty **wallet** address (lowercase) -> their [Contact].
  ///
  /// Resolved by the caller (`wallet_view._loadTransfers`), never here — this
  /// sheet stays presentational. A wallet absent from the map is the intended
  /// "no account" case (bare EOA, contract, or `address(0)` on a mint/burn):
  /// the row shows the short hex and **no icon**.
  final Map<String, Contact> counterparties;

  /// The page after [last] (the oldest transfer showing), oldest pages last.
  /// Null = no paging: the sheet shows [transfers] and nothing more.
  final Future<List<TokenTransfer>> Function(TokenTransfer last)? onLoadMore;

  /// Rows per page. A page shorter than this is the last one.
  final int pageSize;

  const TransactionHistorySheet({
    super.key,
    required this.address,
    required this.transfers,
    this.loading = false,
    this.counterparties = const {},
    this.onLoadMore,
    this.pageSize = 25,
  });

  @override
  State<TransactionHistorySheet> createState() =>
      _TransactionHistorySheetState();
}

class _TransactionHistorySheetState extends State<TransactionHistorySheet> {
  final ScrollController _scroll = ScrollController();
  late final List<TokenTransfer> _transfers = [...widget.transfers];
  late bool _hasMore =
      widget.onLoadMore != null && widget.transfers.length >= widget.pageSize;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || !_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 240) _loadMore();
  }

  Future<void> _loadMore() async {
    final more = widget.onLoadMore;
    if (more == null || _transfers.isEmpty) return;
    setState(() => _loadingMore = true);
    List<TokenTransfer> page = const [];
    try {
      page = await more(_transfers.last);
    } catch (_) {
      // Leave what is showing; the next scroll tries again.
    }
    if (!mounted) return;
    setState(() {
      _transfers.addAll(page);
      _hasMore = page.length >= widget.pageSize;
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final address = widget.address;
    final loading = widget.loading;
    final counterparties = widget.counterparties;
    final transfers = _transfers;
    final me = EthereumAddress.fromHex(address);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: tokens.surfaceDeep,
        // DELTA (desktop): shown in a centered glass dialog, not a bottom
        // sheet — all-corner radius, no drag handle.
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Row(
                children: [
                  SendCoinsIcon(size: 18, color: tokens.starkWhite),
                  const SizedBox(width: 10),
                  Text(
                    context.l10n.walletActivityTitle,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.starkWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Divider(color: tokens.borderSubtle, height: 1),
            ),
            if (loading && transfers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: PhigitalLoadingWidget(size: 32, showShadows: false),
              )
            else if (transfers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
                child: Text(
                  context.l10n.walletActivityEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 13,
                    height: 1.4,
                    color: tokens.textDim,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  controller: _scroll,
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  // One more row while an older page is being read.
                  itemCount: transfers.length + (_loadingMore ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      Divider(color: tokens.borderSubtle, height: 1, indent: 52),
                  itemBuilder: (_, i) {
                    if (i >= transfers.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: PhigitalLoadingWidget(
                              size: 22, showShadows: false),
                        ),
                      );
                    }
                    final t = transfers[i];
                    final other = t.isOutgoing(me) ? t.to : t.from;
                    return _TransferRow(
                      transfer: t,
                      me: me,
                      counterparty:
                          counterparties[other.eip55With0x.toLowerCase()],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  final TokenTransfer transfer;
  final EthereumAddress me;

  /// The other end, when they're a PublicOS account. Null ⇒ show the hex and
  /// **no icon** — never an address-derived identicon, which would imply an
  /// identity we haven't verified (same rule as `group_event_line::_person`).
  final Contact? counterparty;

  const _TransferRow({
    required this.transfer,
    required this.me,
    this.counterparty,
  });

  String _short(EthereumAddress a) {
    final h = a.eip55With0x;
    return '${h.substring(0, 6)}…${h.substring(h.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final out = transfer.isOutgoing(me);
    final accent = out ? _kOutgoing : _kIncoming;
    final other = out ? transfer.to : transfer.from;
    final amount =
        PublicOSWallets.formatTokenAmount(transfer.rawAmount, 18, symbol: 'OX');
    final l10n = context.l10n;

    // Null unless the other end resolved to a PublicOS account with a name.
    final rawName = counterparty == null
        ? null
        : (counterparty!.publicosDisplayName ?? counterparty!.displayName)
            .trim();
    final name = (rawName != null && rawName.isNotEmpty) ? rawName : null;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Clipboard.setData(ClipboardData(text: transfer.txHash));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.walletActivityTxCopied)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                out ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 18,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    out ? l10n.walletActivitySentTo : l10n.walletActivityReceivedFrom,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.starkWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (name != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlassContactIcon(contact: counterparty, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tokens.textDim,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      _short(other),
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: tokens.textDim,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${out ? '-' : '+'}$amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  txRelativeTime(transfer.timestamp),
                  style: TextStyle(fontSize: 11, color: tokens.textDim),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
