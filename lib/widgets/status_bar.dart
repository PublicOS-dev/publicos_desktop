import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../theme/glass_tokens.dart';
import '../theme/shell_tones.dart';
import '../utils/app_update.dart';
import 'app_update_dialog.dart';
import 'mini_copy_button.dart';
import 'sidebar.dart' show ProviderStatus;

/// The shell status bar — a full-width quiet container, same tone as the
/// rail, docked as a SIBLING of the pane row (`Column[Row[...], StatusBar]`)
/// so top/bottom is a child reorder driven by `ShellPrefs.statusBarTop`.
///
/// Layout rule: identity-left (what am I signing with — keychain launcher,
/// active web3 key, XMTP state), environment-right (what am I connected to —
/// chain RPC, SSP). The center is deliberately empty: reserved for the future
/// quick-glance incoming-messages surface, so it lands without reshuffling.
/// Deferred until they have real data sources: network node count, the
/// notification bell.
///
/// The chain/SSP dots are the legitimate home of teal/orange — connected vs
/// public-fallback state, the client explorer's color logic. Pure
/// presentation: all state lives in [AppShell].
class StatusBar extends StatelessWidget {
  final String? myAddress;

  /// The XMTP chip: `[sim] <emoji> <key> · <who>`.
  /// [xmtpKeyLabel] is `PublicOS.currentXmtpKeyLabel` (null = nothing signed
  /// in); [xmtpKeyEmoji] its keychain emoji. [inboxRegisteredLabel] is the
  /// label the active inbox is bound to in the account's on-chain inbox
  /// directory (null = not registered), rendered as `displayName/label` —
  /// the browser's `domain/tab` shape. For an
  /// org key, [displayName] is the ORG's name, since the label lives in the
  /// org's directory. [inboxLookupDone] is false
  /// while the directory read is in flight (chip shows `…`). [xmtpInboxId]
  /// only feeds the tooltip.
  final String? xmtpKeyLabel;
  final String? xmtpKeyEmoji;
  final String? xmtpInboxId;
  final String? inboxRegisteredLabel;
  final bool inboxLookupDone;
  final String? displayName;

  final ProviderStatus chain;
  final ProviderStatus ssp;

  final VoidCallback onOpenKeychain;
  final VoidCallback onOpenChain;
  final VoidCallback onOpenSsp;

  /// Unread on-chain notifications. The client carries this on an app-bar
  /// bell; desktop has no app bar, and the status bar is already the home
  /// for glanceable live state.
  final int unreadCount;
  final VoidCallback onOpenNotifications;

  const StatusBar({
    super.key,
    required this.myAddress,
    required this.xmtpKeyLabel,
    required this.xmtpKeyEmoji,
    required this.xmtpInboxId,
    required this.inboxRegisteredLabel,
    required this.inboxLookupDone,
    required this.displayName,
    required this.chain,
    required this.ssp,
    required this.onOpenKeychain,
    required this.onOpenChain,
    required this.onOpenSsp,
    required this.unreadCount,
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final tones = ShellTones.of(context);

    final addr = myAddress;
    final shortAddr = (addr != null && addr.length >= 10)
        ? '${addr.substring(0, 6)}…${addr.substring(addr.length - 4)}'
        : null;

    return Container(
      height: ShellMetrics.statusBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: tones.chrome,
        // Borderless — tone carries the edge.
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // ── Identity (left) ──────────────────────────────────────────────
          _BarItem(
            tooltip: context.l10n.desktopStatusBarKeychainTooltip,
            onTap: onOpenKeychain,
            children: [
              Icon(Icons.vpn_key_rounded, size: 13, color: tokens.textDim),
              if (shortAddr != null) ...[
                const SizedBox(width: 6),
                Text(
                  shortAddr,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: tokens.textDim,
                  ),
                ),
                const SizedBox(width: 2),
                MiniCopyButton(value: addr!),
              ],
            ],
          ),
          _xmtpChip(context, tokens),

          // ── Center: reserved for quick-glance incoming messages ──────────
          const Spacer(),

          // ── Update offer: only while a verified newer build exists ───────
          ValueListenableBuilder<UpdateOffer?>(
            valueListenable: AppUpdate.offer,
            builder: (context, offer, _) {
              if (offer == null) return const SizedBox.shrink();
              return _BarItem(
                tooltip: context.l10n.desktopUpdateTitle,
                onTap: () => showAppUpdateDialog(context, offer),
                children: [
                  Icon(Icons.system_update_alt_rounded,
                      size: 13, color: tokens.connectedAccent),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.desktopUpdateChip,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.connectedAccent,
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Notifications bell ───────────────────────────────────────────
          _BarItem(
            tooltip: unreadCount > 0
                ? context.l10n.desktopStatusBarUnreadChain(unreadCount)
                : context.l10n.desktopStatusBarChainNotifications,
            onTap: onOpenNotifications,
            children: [
              Icon(
                unreadCount > 0
                    ? Icons.notifications_rounded
                    : Icons.notifications_none_rounded,
                size: 14,
                color: unreadCount > 0
                    ? tokens.connectedAccent
                    : tokens.textDim,
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: tokens.connectedAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'SpaceGrotesk',
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // ── Environment (right) ──────────────────────────────────────────
          _providerItem(
            tokens,
            status: chain,
            prefix: 'BSP',
            connectedSources: const {'bsp', 'custom'},
            fallbackName: context.l10n.desktopStatusBarPublicNode,
            tooltipPrefix: context.l10n.messageWidgetTxChain,
            onTap: onOpenChain,
          ),
          _providerItem(
            tokens,
            status: ssp,
            prefix: 'SSP',
            connectedSources: const {'ssp', 'custom', 'override'},
            fallbackName: context.l10n.desktopStatusBarPublicServer,
            tooltipPrefix: context.l10n.desktopStatusBarFeedServer,
            onTap: onOpenSsp,
          ),
        ],
      ),
    );
  }

  Widget _providerItem(
    GlassTokens tokens, {
    required ProviderStatus status,
    required String prefix,
    required Set<String> connectedSources,
    required String fallbackName,
    required String tooltipPrefix,
    required VoidCallback onTap,
  }) {
    // Client color logic (explorer _chainIconColor / _sspIconColor): dim
    // while checking or unreachable, teal on a provider/custom endpoint,
    // amber on the public fallback.
    final Color dot;
    if (status.reachable != true) {
      dot = tokens.textDim;
    } else if (connectedSources.contains(status.source)) {
      dot = tokens.connectedAccent;
    } else {
      dot = tokens.fallbackAccent;
    }
    final name = status.name ?? fallbackName;
    final host = status.endpoint;

    return _BarItem(
      tooltip: host == null ? '$tooltipPrefix — $name' : '$tooltipPrefix — $name ($host)',
      onTap: onTap,
      children: [
        _Dot(color: dot),
        const SizedBox(width: 6),
        Text(
          '$prefix · $name',
          style: TextStyle(fontSize: 11.5, color: tokens.textDim),
        ),
      ],
    );
  }
}

/// One clickable status-bar chip — hover fill, tight padding.
extension on StatusBar {
  /// `[sim] 🔑 main · jmsl.main` / `[sim] 🔑 main · unregistered` /
  /// `[sim] no key`. The sim glyph is the keychain's own "sign this key in
  /// for messaging" icon, teal while a key is loaded (it replaces the old
  /// dot); the `·` is the bar's separator idiom (`BSP · name`).
  Widget _xmtpChip(BuildContext context, GlassTokens tokens) {
    final l10n = context.l10n;
    final key = xmtpKeyLabel;
    final loaded = key != null && key.isNotEmpty;
    final dim = TextStyle(fontSize: 11.5, color: tokens.textDim);

    String? who;
    if (loaded) {
      final reg = inboxRegisteredLabel;
      if (reg != null) {
        final name = displayName;
        who = (name == null || name.isEmpty) ? reg : '$name/$reg';
      } else {
        who = inboxLookupDone ? l10n.statusBarInboxUnregistered : '…';
      }
    }

    final tooltip = !loaded
        ? l10n.statusBarNoKey
        : [
            if (xmtpInboxId != null) xmtpInboxId!,
            if (inboxRegisteredLabel != null && who != null)
              l10n.statusBarInboxRegisteredAs(who)
            else if (inboxLookupDone)
              l10n.statusBarInboxUnregistered,
          ].join('\n');

    return _BarItem(
      tooltip: tooltip,
      onTap: onOpenKeychain,
      children: [
        Icon(
          Icons.sim_card_outlined,
          size: 13,
          color: loaded ? tokens.connectedAccent : tokens.textDim,
        ),
        const SizedBox(width: 6),
        if (!loaded)
          Text(l10n.statusBarNoKey, style: dim)
        else ...[
          Text(xmtpKeyEmoji ?? '🔑', style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(key, style: dim),
          Text('  ·  ', style: dim),
          Text(
            who!,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: tokens.textDim,
            ),
          ),
        ],
      ],
    );
  }
}

class _BarItem extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  final List<Widget> children;

  const _BarItem({
    required this.tooltip,
    required this.onTap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          hoverColor: tokens.glassFillHover,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
