// Ported from the mobile client's components/vouch_dialogs.dart; only the
// imports differ.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// The two dialogs in front of `PublicOSAccounts.vouch`. Returns true only
/// when BOTH were confirmed.
///
/// Same shape as [confirmRenounceCitizenship], for the same reason: a vouch
/// cannot be taken back, so the two steps are built to stop a reflex tap.
///
/// 1. **What a vouch declares, with a wait.** The first dialog states the
///    citizen agreement's vouch clauses (v1: what a vouch means,
///    identification, consequences), and its CONTINUE button counts down
///    10 s before it can be tapped. It sits on the LEFT; CANCEL is on the
///    right, where a primary usually is.
/// 2. **The last step, with the buttons swapped.** DON'T VOUCH moves to the
///    left and VOUCH NOW to the right.
Future<bool> confirmVouch(BuildContext context, String name) async {
  final first = await showDialog<bool>(
    context: context,
    builder: (_) => _VouchMeaningDialog(name: name),
  );
  if (first != true || !context.mounted) return false;
  final second = await showDialog<bool>(
    context: context,
    builder: (_) => _VouchLastStepDialog(name: name),
  );
  return second == true;
}

const int _kVouchWaitSeconds = 10;

class _VouchMeaningDialog extends StatefulWidget {
  const _VouchMeaningDialog({required this.name});

  final String name;

  @override
  State<_VouchMeaningDialog> createState() => _VouchMeaningDialogState();
}

class _VouchMeaningDialogState extends State<_VouchMeaningDialog> {
  int _left = _kVouchWaitSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left = (_left - 1).clamp(0, _kVouchWaitSeconds));
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
    final points = <String>[
      l10n.vouchPointInPerson(widget.name),
      l10n.vouchPointOneAccount,
      l10n.vouchPointTrust,
      l10n.vouchPointFinal,
      l10n.vouchPointCharacter,
      l10n.vouchPointIdentify,
      l10n.vouchPointConsequence,
    ];

    return AlertDialog(
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
      backgroundColor: tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.borderSubtle),
      ),
      title: Text(
        l10n.vouchDlg1Title(widget.name),
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
              l10n.vouchDlg1Lead,
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
                  for (final p in points)
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
                              p,
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
        // Step 1: the committing button is on the LEFT and locked behind the
        // countdown; the safe one is on the right.
        TextButton(
          onPressed: ready ? () => Navigator.pop(context, true) : null,
          child: Text(
            ready ? l10n.vouchDlg1Confirm : l10n.vouchWait(_left.toString()),
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
            l10n.vouchCancel,
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

class _VouchLastStepDialog extends StatelessWidget {
  const _VouchLastStepDialog({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final AppLocalizations l10n = context.l10n;
    return AlertDialog(
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
      backgroundColor: tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.softDanger.withValues(alpha: 0.5)),
      ),
      title: Text(
        l10n.vouchDlg2Title,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.starkWhite,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Text(
        l10n.vouchDlg2Body(name),
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.textDim,
          fontSize: 13,
          height: 1.4,
        ),
      ),
      actions: [
        // Step 2: the positions are SWAPPED on purpose. The safe button now
        // sits where the committing one was a second ago.
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            l10n.vouchDlg2Cancel,
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
            l10n.vouchDlg2Confirm,
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
