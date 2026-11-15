import 'dart:async';

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// Key lifetime helpers + the select-account countdown line. A session key is
/// permanent (ttl 0) or expires after a ttl in seconds; the app offers four
/// picks.
const List<int> kKeyLifetimeChoices = [86400, 604800, 2592000, 0];

/// "24 hours" · "1 week" · "1 month" · "Permanent", or "3d 4h" for any other.
String formatKeyLifetime(AppLocalizations l10n, int seconds) {
  switch (seconds) {
    case 0:
      return l10n.keyLifetimePermanent;
    case 86400:
      return l10n.keyLifetime24h;
    case 604800:
      return l10n.keyLifetimeWeek;
    case 2592000:
      return l10n.keyLifetimeMonth;
  }
  return formatKeyRemaining(Duration(seconds: seconds));
}

/// "6d 23h" · "4h 12m" · "9m" (never below 1m).
String formatKeyRemaining(Duration d) {
  if (d.inDays >= 1) return '${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
  final m = d.inMinutes < 1 ? 1 : d.inMinutes;
  return '${m}m';
}

/// Lighter sub-line under an account on the select-account screen: how long
/// this device's session key for [accountAddress] has left, counting down.
/// Shows nothing for a permanent key, while the read is out, or if it fails.
/// Turns red ("key expired") once the key has ended: an expired key is gone
/// for good, so that account needs a new key.
///
/// The keychain uses it for the current session key: [sessionAddress],
/// [showPermanent] (a permanent key reads "permanent key") and its own
/// [color] without the banner shadow.
class KeyLifetimeLine extends StatefulWidget {
  /// The account whose stored session key on this device is shown.
  final String? accountAddress;

  /// Or a session key address directly.
  final String? sessionAddress;
  final double fontSize;
  final bool showPermanent;
  final Color? color;
  final bool shadow;

  const KeyLifetimeLine({
    super.key,
    this.accountAddress,
    this.sessionAddress,
    this.fontSize = 11,
    this.showPermanent = false,
    this.color,
    this.shadow = true,
  }) : assert(accountAddress != null || sessionAddress != null);

  @override
  State<KeyLifetimeLine> createState() => _KeyLifetimeLineState();
}

class _KeyLifetimeLineState extends State<KeyLifetimeLine> {
  SessionTenureInfo? _tenure;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = widget.sessionAddress != null
          ? await PublicOSAccounts.getSessionTenure(
              EthereumAddress.fromHex(widget.sessionAddress!))
          : await PublicOSAccounts.getStoredSessionTenure(
              EthereumAddress.fromHex(widget.accountAddress!));
      if (!mounted || t == null) return;
      if (t.isPermanent && !widget.showPermanent) return;
      setState(() => _tenure = t);
      if (!t.isExpired) {
        _tick = Timer.periodic(const Duration(seconds: 30), (_) {
          if (!mounted) return;
          setState(() {});
          if (_tenure?.isExpired ?? true) _tick?.cancel();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _tenure;
    if (t == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final expired = t.isExpired;
    final base = widget.color ?? Colors.white.withValues(alpha: 0.6);
    final shadows =
        widget.shadow ? const [Shadow(color: Colors.black54, blurRadius: 6)] : null;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            t.isPermanent
                ? Icons.all_inclusive_rounded
                : expired
                    ? Icons.timer_off_outlined
                    : Icons.timer_outlined,
            size: widget.fontSize + 1,
            color: expired ? const Color(0xFFFF8A80) : base,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              t.isPermanent
                  ? l10n.keyLifetimePermanentKey
                  : expired
                      ? l10n.keyLifetimeExpired
                      : l10n.keyLifetimeExpiresIn(formatKeyRemaining(t.remaining!)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w500,
                color: expired ? const Color(0xFFFF8A80) : base,
                shadows: shadows,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
