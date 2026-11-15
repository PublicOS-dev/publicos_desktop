// Ported from the mobile client's components/clear_records_dialogs.dart;
// only the imports differ.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// The two dialogs in front of `PublicOSContacts.clearAllMyRecords`.
/// Returns true only when BOTH were confirmed. Same shape as the renounce
/// dialogs, in the warning (orange) tier instead of the destructive one:
///
/// 1. **What goes, with a wait.** The DELETE button counts down 15 s before
///    it can be tapped. It sits on the LEFT; KEEP MY PROFILE is on the right.
/// 2. **The last step, with the buttons swapped.** KEEP MY PROFILE moves to
///    the left and DELETE EVERYTHING NOW to the right, so a thumb that learned
///    the first layout lands on KEEP.
Future<bool> confirmClearAllRecords(BuildContext context) async {
  final first = await showDialog<bool>(
    context: context,
    builder: (_) => const _ClearCostDialog(),
  );
  if (first != true || !context.mounted) return false;
  final second = await showDialog<bool>(
    context: context,
    builder: (_) => const _ClearLastStepDialog(),
  );
  return second == true;
}

const int _kClearWaitSeconds = 15;

class _ClearCostDialog extends StatefulWidget {
  const _ClearCostDialog();

  @override
  State<_ClearCostDialog> createState() => _ClearCostDialogState();
}

class _ClearCostDialogState extends State<_ClearCostDialog> {
  int _left = _kClearWaitSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left = (_left - 1).clamp(0, _kClearWaitSeconds));
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
    final accent = tokens.fallbackAccent;
    final costs = <String>[
      l10n.clearRecordsCostIdentity,
      l10n.clearRecordsCostBio,
      l10n.clearRecordsCostLinks,
      l10n.clearRecordsCostCards,
      l10n.clearRecordsCostForever,
    ];

    return AlertDialog(
      backgroundColor: tokens.surfaceDeep,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
      title: Text(
        l10n.clearRecordsDlg1Title,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: accent,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.clearRecordsDlg1Lead,
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
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
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
                                color: accent,
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
            const SizedBox(height: 12),
            Text(
              l10n.clearRecordsDlg1Stays,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 12,
                height: 1.4,
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
            ready ? l10n.clearRecordsDlg1Confirm : l10n.clearRecordsWait(_left.toString()),
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: ready ? accent : tokens.textDim.withValues(alpha: 0.55),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            l10n.clearRecordsKeep,
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

class _ClearLastStepDialog extends StatelessWidget {
  const _ClearLastStepDialog();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final AppLocalizations l10n = context.l10n;
    final accent = tokens.fallbackAccent;
    return AlertDialog(
      backgroundColor: tokens.surfaceDeep,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
      title: Text(
        l10n.clearRecordsDlg2Title,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.starkWhite,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Text(
        l10n.clearRecordsDlg2Body,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.textDim,
          fontSize: 13,
          height: 1.4,
        ),
      ),
      actions: [
        // Step 2: the positions are SWAPPED on purpose.
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            l10n.clearRecordsKeep,
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
            l10n.clearRecordsDlg2Confirm,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
