import 'package:flutter/material.dart';

import 'package:publicos_desktop/widgets/explorer_chip.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Horizontal chip bar above the messages list. Thin wrapper around
/// [ExplorerChipBar] / [ExplorerChip] with the messages-tab semantic API.
///
/// Stateless — selection state lives on the parent page so it can drive
/// both the repo query and the chip visuals from one source.
class MessagesChipBar extends StatelessWidget {
  final bool isShowingRequests;
  final bool showPersonal;
  final bool showGroups;
  final int unknownCount;

  /// Current XMTP key label. When null the Keys chip shows "No key" in
  /// the fallback accent — that's the primary call-to-action for a new
  /// user who hasn't created any keys yet.
  final String? currentKeyLabel;

  /// Toggle between allowed inbox and pending requests. Active state is
  /// driven by [isShowingRequests] — tapping the chip flips it. Only
  /// rendered when [unknownCount] > 0; when no requests are pending the
  /// chip is hidden and the list always shows the allowed inbox.
  final VoidCallback onTapRequests;
  final VoidCallback onTogglePersonal;
  final VoidCallback onToggleGroups;

  /// If null the chip still renders but is inert — used in this pass since
  /// the new-group page isn't implemented yet.
  final VoidCallback? onTapNewGroup;
  final VoidCallback onTapSettings;
  final VoidCallback onTapKeys;
  final VoidCallback onTapInboxIds;

  const MessagesChipBar({
    super.key,
    required this.isShowingRequests,
    required this.showPersonal,
    required this.showGroups,
    required this.unknownCount,
    required this.currentKeyLabel,
    required this.onTapRequests,
    required this.onTogglePersonal,
    required this.onToggleGroups,
    required this.onTapNewGroup,
    required this.onTapSettings,
    required this.onTapKeys,
    required this.onTapInboxIds,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final hasKey = currentKeyLabel != null;

    // No key loaded → show only the Keys chip (the first one). The rest of the
    // tab is one big "load your keys" call-to-action, so the other chips would
    // do nothing yet.
    return ExplorerChipBar(
      children: [
        ExplorerChip(
          label: currentKeyLabel ?? context.l10n.messagesChipBarNoKey,
          icon: Icons.vpn_key_rounded,
          active: hasKey,
          accentColor: hasKey ? null : tokens.fallbackAccent,
          onTap: onTapKeys,
        ),
        if (hasKey) ...[
          if (unknownCount > 0) ...[
            const SizedBox(width: 16),
            ExplorerChip(
              label: context.l10n.messagesChipBarRequests,
              icon: Icons.mark_email_unread_outlined,
              active: isShowingRequests,
              count: unknownCount,
              onTap: onTapRequests,
            ),
          ],
          const SizedBox(width: 16),
          ExplorerChip(
            label: context.l10n.messagesChipBar1on1,
            icon: Icons.person_outline_rounded,
            active: showPersonal,
            onTap: onTogglePersonal,
          ),
          const SizedBox(width: 8),
          ExplorerChip(
            label: context.l10n.messagesChipBarGroups,
            icon: Icons.groups_rounded,
            active: showGroups,
            onTap: onToggleGroups,
          ),
          const SizedBox(width: 16),
          ExplorerChip(
            label: context.l10n.messagesChipBarNewGroup,
            icon: Icons.group_add_rounded,
            active: false,
            onTap: onTapNewGroup,
          ),
          const SizedBox(width: 8),
          ExplorerChip(
            label: context.l10n.messagesChipBarInboxIds,
            icon: Icons.inbox_rounded,
            active: false,
            onTap: onTapInboxIds,
          ),
          const SizedBox(width: 8),
          ExplorerChip(
            label: context.l10n.messagesChipBarSettings,
            icon: Icons.tune_rounded,
            active: false,
            onTap: onTapSettings,
          ),
        ],
      ],
    );
  }
}
