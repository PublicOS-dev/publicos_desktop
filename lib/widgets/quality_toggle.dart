import 'package:flutter/material.dart';

import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Glass-styled Low / HD segmented toggle. Used by both the chat input
/// (image attachment quality) and `MediaUrlField` (avatar / banner /
/// group icon upload quality). Both sites must look identical.
///
/// HD can be locked off by passing [hdEnabled: false] — the option dims
/// and a tap calls [onHdDisabledTap] instead of [onChanged] (chat uses
/// this to nudge the user to subscribe to an SSP). When [hdEnabled] is
/// true (default), tapping HD calls `onChanged(true)`.
class QualityToggle extends StatelessWidget {
  final bool hdMode;
  final ValueChanged<bool> onChanged;
  final bool hdEnabled;
  final VoidCallback? onHdDisabledTap;

  const QualityToggle({
    super.key,
    required this.hdMode,
    required this.onChanged,
    this.hdEnabled = true,
    this.onHdDisabledTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSubtle),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option(
            tokens: tokens,
            label: context.l10n.qualityToggleLow,
            active: !hdMode,
            disabled: false,
            onTap: () => onChanged(false),
          ),
          _option(
            tokens: tokens,
            label: context.l10n.qualityToggleHd,
            active: hdMode,
            disabled: !hdEnabled,
            onTap: hdEnabled
                ? () => onChanged(true)
                : (onHdDisabledTap ?? () {}),
          ),
        ],
      ),
    );
  }

  Widget _option({
    required GlassTokens tokens,
    required String label,
    required bool active,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    final accent = tokens.connectedAccent;
    final color = disabled
        ? tokens.textDim.withValues(alpha: 0.4)
        : (active ? accent : tokens.textDim);
    final fill = active && !disabled
        ? accent.withValues(alpha: 0.18)
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: color,
          ),
        ),
      ),
    );
  }
}
