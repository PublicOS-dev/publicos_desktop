// Ported from the mobile client's
// components/renounce_citizenship_dialogs.dart; only the imports differ.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// The two dialogs in front of `PublicOSAccounts.renounceCitizenship`.
/// Returns true only when BOTH were confirmed.
///
/// Renouncing is immediate and final, so the two steps are built to stop a
/// reflex tap, not just to ask twice:
///
/// 1. **The cost list, with a wait.** The first dialog lists what happens in
///    the one transaction, and its RENOUNCE button counts down 15 s before it
///    can be tapped. It sits on the LEFT; KEEP CITIZENSHIP is on the right,
///    where a primary usually is.
/// 2. **The last step, with the buttons swapped.** KEEP CITIZENSHIP moves to
///    the left and RENOUNCE CITIZENSHIP NOW to the right. A thumb that learned
///    the first layout lands on KEEP.
Future<bool> confirmRenounceCitizenship(BuildContext context) async {
  final first = await showDialog<bool>(
    context: context,
    builder: (_) => const _RenounceCostDialog(),
  );
  if (first != true || !context.mounted) return false;
  final second = await showDialog<bool>(
    context: context,
    builder: (_) => const _RenounceLastStepDialog(),
  );
  return second == true;
}

const int _kRenounceWaitSeconds = 15;

class _RenounceCostDialog extends StatefulWidget {
  const _RenounceCostDialog();

  @override
  State<_RenounceCostDialog> createState() => _RenounceCostDialogState();
}

class _RenounceCostDialogState extends State<_RenounceCostDialog> {
  int _left = _kRenounceWaitSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left = (_left - 1).clamp(0, _kRenounceWaitSeconds));
      if (_left == 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final ready = _left == 0;
    final costs = <String>[
      l10n.renounceCostName,
      l10n.renounceCostShare,
      l10n.renounceCostSubs,
      l10n.renounceCostGraph,
      l10n.renounceCostSeat,
      l10n.renounceCostVouches,
    ];

    return AlertDialog(
      backgroundColor: tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.borderSubtle),
      ),
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
      title: Text(
        l10n.renounceDlg1Title,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.starkWhite,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.renounceDlg1Lead,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.softDanger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: tokens.softDanger.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final c in costs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: tokens.softDanger,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              c,
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 12,
                                height: 1.4,
                                color: tokens.starkWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Step 1: the dangerous button is on the LEFT and locked behind the
        // countdown; the safe one is on the right.
        TextButton(
          onPressed: ready ? () => Navigator.pop(context, true) : null,
          child: Text(
            ready
                ? l10n.renounceDlg1Confirm
                : l10n.renounceWait(_left.toString()),
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: ready
                  ? tokens.softDanger
                  : tokens.textDim.withValues(alpha: 0.55),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            l10n.renounceKeep,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RenounceLastStepDialog extends StatelessWidget {
  const _RenounceLastStepDialog();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final AppLocalizations l10n = context.l10n;
    return AlertDialog(
      backgroundColor: tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.softDanger.withValues(alpha: 0.5)),
      ),
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
      title: Text(
        l10n.renounceDlg2Title,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.starkWhite,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Text(
        l10n.renounceDlg2Body,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.textDim,
          fontSize: 13,
          height: 1.4,
        ),
      ),
      actions: [
        // Step 2: the positions are SWAPPED on purpose. The safe button now
        // sits where the dangerous one was a second ago.
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            l10n.renounceKeep,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            l10n.renounceDlg2Confirm,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.softDanger,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
