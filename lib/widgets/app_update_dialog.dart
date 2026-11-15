import 'package:flutter/material.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/app_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// The offer of [AppUpdate]: what the new build is, then download, check and
/// hand over. Opened from the status bar chip.
Future<void> showAppUpdateDialog(BuildContext context, UpdateOffer offer) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AppUpdateDialog(offer: offer),
  );
}

enum _Phase { offer, downloading, installing, failed }

class _AppUpdateDialog extends StatefulWidget {
  final UpdateOffer offer;
  const _AppUpdateDialog({required this.offer});

  @override
  State<_AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<_AppUpdateDialog> {
  late final bool _inPlace = AppUpdate.canUpdateInPlace();
  _Phase _phase = _Phase.offer;
  int _percent = 0;

  Future<void> _update() async {
    setState(() => _phase = _Phase.downloading);
    try {
      final source = await AppUpdate.download(
        widget.offer,
        onProgress: (fraction) {
          final percent = (fraction * 100).floor().clamp(0, 100);
          if (percent != _percent && mounted) {
            setState(() => _percent = percent);
          }
        },
      );
      if (!mounted) return;
      setState(() => _phase = _Phase.installing);
      // One beat so the last line is read before the window goes.
      await Future<void>.delayed(const Duration(milliseconds: 900));
      await AppUpdate.applyAndRestart(widget.offer, source);
    } catch (e) {
      debugPrint('[UPDATE] failed: $e');
      if (mounted) setState(() => _phase = _Phase.failed);
    }
  }

  Future<void> _openPage() async {
    await launchUrl(Uri.parse(AppUpdate.downloadPage),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final offer = widget.offer;
    final sizeMb = (offer.zipSize / (1024 * 1024)).round();
    final body = TextStyle(color: tokens.starkWhite, height: 1.4);
    final dim = TextStyle(color: tokens.textDim, fontSize: 12.5, height: 1.4);
    final busy = _phase == _Phase.downloading || _phase == _Phase.installing;

    final String message;
    switch (_phase) {
      case _Phase.offer:
        message = _inPlace
            ? l10n.desktopUpdateBody(offer.version, sizeMb)
            : l10n.desktopUpdateNotHere;
      case _Phase.downloading:
        message = l10n.desktopUpdateDownloading(_percent);
      case _Phase.installing:
        message = l10n.desktopUpdateInstalling;
      case _Phase.failed:
        message = l10n.desktopUpdateFailed;
    }

    final showPage = _phase == _Phase.failed || !_inPlace;

    return AlertDialog(
      backgroundColor: tokens.surfaceDeep,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      constraints: const BoxConstraints(
          minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
      title: Text(
        l10n.desktopUpdateTitle,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.starkWhite,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: body),
          if (_phase == _Phase.downloading) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _percent / 100,
                minHeight: 4,
                color: tokens.connectedAccent,
                backgroundColor: tokens.glassFill,
              ),
            ),
          ],
          if (_phase == _Phase.offer && _inPlace) ...[
            const SizedBox(height: 10),
            Text(l10n.desktopUpdateChecked, style: dim),
          ],
        ],
      ),
      actions: busy
          ? const []
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.desktopUpdateLater,
                    style: TextStyle(color: tokens.textDim)),
              ),
              if (showPage)
                TextButton(
                  onPressed: _openPage,
                  child: Text(l10n.desktopUpdateOpenPage,
                      style: TextStyle(color: tokens.connectedAccent)),
                )
              else
                TextButton(
                  onPressed: _update,
                  child: Text(l10n.desktopUpdateNow,
                      style: TextStyle(
                          color: tokens.connectedAccent,
                          fontWeight: FontWeight.w700)),
                ),
            ],
    );
  }
}
