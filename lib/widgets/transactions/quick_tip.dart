import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/feeds/reaction_quick_bar.dart';
import 'package:publicos_desktop/widgets/transactions/send_sheet.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// Reader setting: "my tip", one amount used
/// twice: preselected in the tip sheet (the ★ chip) and sent by a long press
/// on a post's tip button when quick tip is on. 0.01–0.5 OX, default 0.1.
/// Quick tip is off by default. Same static-cache shape as [ReactionPrefs].
class TipPrefs {
  TipPrefs._();

  static const String kAmountKey = 'tip_my_amount';
  static const String kQuickKey = 'tip_quick_enabled';
  static const double minAmount = 0.01;
  static const double maxAmount = 0.5;
  static const double defaultAmount = 0.1;

  /// The tip sheet's fixed chips; the ★ chip (my tip) comes after them.
  static const List<double> sheetChips = [0.01, 0.1, 1];

  static double? _amount;
  static bool? _quick;

  static double get amountSync => _amount ?? defaultAmount;
  static bool get quickSync => _quick ?? false;

  static Future<void> warm() async {
    await amount();
    await quickEnabled();
  }

  static Future<double> amount() async {
    if (_amount != null) return _amount!;
    try {
      final r = await PublicOSSettings.getSetting(kAmountKey);
      final v = double.tryParse(r?.value ?? '');
      _amount = v == null ? defaultAmount : v.clamp(minAmount, maxAmount);
    } catch (_) {
      _amount = defaultAmount;
    }
    return _amount!;
  }

  static Future<void> setAmount(double v) async {
    _amount = v.clamp(minAmount, maxAmount);
    try {
      await PublicOSSettings.setSetting(
        kAmountKey,
        Record.asSettings(key: kAmountKey, value: format(_amount!), isSystem: true),
      );
    } catch (_) {}
  }

  static Future<bool> quickEnabled() async {
    if (_quick != null) return _quick!;
    try {
      final r = await PublicOSSettings.getSetting(kQuickKey);
      _quick = r?.value == 'true';
    } catch (_) {
      _quick = false;
    }
    return _quick!;
  }

  static Future<void> setQuickEnabled(bool on) async {
    _quick = on;
    try {
      await PublicOSSettings.setSetting(
        kQuickKey,
        Record.asSettings(key: kQuickKey, value: on.toString(), isSystem: true),
      );
    } catch (_) {}
  }

  /// "0.1", "0.25", "1": two decimals at most, no trailing zeros.
  static String format(double v) {
    var s = v.toStringAsFixed(2);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// The animation level: 1 under 0.1, 2 under 0.3, 3 from 0.3.
  static int level(double v) => v < 0.1 ? 1 : (v < 0.3 ? 2 : 3);
}

/// Sends [amount] OX from MY main Safe to [recipient]'s main Safe. Never a
/// group wallet, never a keychain, never an account address (a recipient
/// with no main Safe throws). Returns the tx hash.
Future<String?> sendQuickTip({
  required EthereumAddress recipient,
  required double amount,
}) async {
  final meHex = PublicOS.myPublicosAddress;
  if (meHex == null) throw StateError('no account');
  final me = EthereumAddress.fromHex(meHex);
  final mySafe = await PublicOSSafe.getMainSafeAddress(me);
  final theirSafe = await PublicOSSafe.getMainSafeAddress(recipient);
  if (mySafe == null || theirSafe == null) {
    throw StateError('main Safe not found');
  }
  // 18 decimals, from the two-decimal string: no float drift.
  final parts = TipPrefs.format(amount).split('.');
  final frac = (parts.length > 1 ? parts[1] : '').padRight(18, '0');
  final raw = BigInt.parse('${parts[0]}$frac');
  return PublicOSSafe.sendTokenFromSafe(
    accountAddress: me,
    safeAddress: EthereumAddress.fromHex(mySafe),
    to: EthereumAddress.fromHex(theirSafe),
    amount: raw,
  );
}

/// Called by the tip sheet after a tip went out, in place of its snackbar:
/// the button plays the same burst a quick tip does.
typedef TipSentCallback = void Function(String amount, String symbol);

/// The post action-row tip button. Tap opens the tip sheet. With quick tip
/// on, a long press arms a 1 s ring (the undo window: tap again to cancel),
/// then sends my tip to the author (else the channel owner) and plays the
/// burst: a fountain of my double-tap emoji, 4 / 8 / 12 of them by level,
/// with pixel confetti. Quick tip off, or no author/owner to send to → the sheet. A tip
/// sent from the sheet plays the same burst ([onOpenSheet] hands the sheet
/// the callback).
class TipActionButton extends StatefulWidget {
  final List<SendCandidate> candidates;
  final Color color;
  final void Function(TipSentCallback onTipSent) onOpenSheet;

  const TipActionButton({
    super.key,
    required this.candidates,
    required this.color,
    required this.onOpenSheet,
  });

  @override
  State<TipActionButton> createState() => _TipActionButtonState();
}

class _TipActionButtonState extends State<TipActionButton>
    with SingleTickerProviderStateMixin {
  static const _undoWindow = Duration(milliseconds: 1000);
  late final AnimationController _ring =
      AnimationController(vsync: this, duration: _undoWindow);
  final GlobalKey _iconKey = GlobalKey();
  bool _armed = false;
  double _armedAmount = 0;
  EthereumAddress? _armedTo;

  @override
  void initState() {
    super.initState();
    TipPrefs.warm();
    _ring.addStatusListener((s) {
      if (s == AnimationStatus.completed && _armed) _fire();
    });
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  EthereumAddress? _quickRecipient() {
    for (final role in const [SendRole.author, SendRole.channelOwner]) {
      for (final c in widget.candidates) {
        if (c.role == role) return c.address;
      }
    }
    return null;
  }

  void _onTap() {
    if (_armed) {
      _cancel();
      return;
    }
    widget.onOpenSheet(_onSheetTipSent);
  }

  /// The sheet sent a tip: same burst and haptic as a quick tip.
  void _onSheetTipSent(String amount, String symbol) {
    if (!mounted) return;
    final v = double.tryParse(amount) ?? 0;
    final level = TipPrefs.level(v);
    _haptic(level);
    _burst(v, level, label: '+$amount $symbol');
  }

  void _haptic(int level) {
    switch (level) {
      case 1:
        HapticFeedback.lightImpact();
      case 2:
        HapticFeedback.mediumImpact();
      default:
        HapticFeedback.heavyImpact();
    }
  }

  void _onLongPress() {
    if (_armed) return;
    final to = _quickRecipient();
    if (!TipPrefs.quickSync || to == null) {
      widget.onOpenSheet(_onSheetTipSent);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _armed = true;
      _armedTo = to;
      _armedAmount = TipPrefs.amountSync;
    });
    _ring.forward(from: 0);
  }

  void _cancel() {
    _ring.stop();
    _ring.value = 0;
    setState(() => _armed = false);
    HapticFeedback.lightImpact();
  }

  Future<void> _fire() async {
    final to = _armedTo!;
    final amount = _armedAmount;
    final level = TipPrefs.level(amount);
    setState(() => _armed = false);
    _ring.value = 0;
    _haptic(level);
    _burst(amount, level);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = context.l10n.quickTipFailed;
    try {
      final tx = await sendQuickTip(recipient: to, amount: amount);
      if (tx == null || tx.isEmpty) throw StateError('no tx');
    } catch (e) {
      Log.w('QuickTip', 'send failed: $e');
      messenger?.showSnackBar(SnackBar(
        content: Text(failed),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _burst(double amount, int level, {String? label}) {
    final box = _iconKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (box == null || overlay == null) return;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TipBurst(
        origin: center,
        emoji: ReactionPrefs.doubleTapEmojiSync,
        label: label ?? '+${TipPrefs.format(amount)} OX',
        level: level,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  static const _levelColors = [
    Color(0xFF39D0C0), // L1 teal
    Color(0xFFF5C451), // L2 gold
    Color(0xFFFF5FA8), // L3 magenta
  ];

  @override
  Widget build(BuildContext context) {
    final ringColor = _levelColors[TipPrefs.level(_armedAmount) - 1];
    return InkResponse(
      onTap: _onTap,
      onLongPress: _onLongPress,
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: SizedBox(
          key: _iconKey,
          width: 21,
          height: 21,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (_armed)
                Positioned(
                  left: -5,
                  top: -5,
                  right: -5,
                  bottom: -5,
                  child: AnimatedBuilder(
                    animation: _ring,
                    builder: (_, __) => CustomPaint(
                      painter: _RingPainter(_ring.value, ringColor),
                    ),
                  ),
                ),
              Icon(
                Icons.volunteer_activism_rounded,
                size: 21,
                color: _armed ? ringColor : widget.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double t;
  final Color color;
  _RingPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.18);
    canvas.drawOval(rect.deflate(1), track);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect.deflate(1), -math.pi / 2, 2 * math.pi * t, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t || old.color != color;
}

/// The "sent" burst, drawn in the root overlay so it escapes the card's clip.
/// A fountain: the
/// emojis leave as a stream inside a narrow cone (±13° off vertical), climb
/// 100 / 120 / 140 px by level, slow at the top and fall back under gravity,
/// fading only on the way down. Pixel confetti sprays out with them at every
/// level (5 / 11 / 20): 4 px squares snapped to a grid, flickering between two
/// shades, blinking out instead of fading.
class _TipBurst extends StatefulWidget {
  final Offset origin;
  final String emoji;
  final String label;
  final int level;
  final VoidCallback onDone;

  const _TipBurst({
    required this.origin,
    required this.emoji,
    required this.label,
    required this.level,
    required this.onDone,
  });

  @override
  State<_TipBurst> createState() => _TipBurstState();
}

const double _kGravity = 900; // px/s²

class _Particle {
  final double vx; // launch velocity, px/s
  final double vy;
  final double delay; // seconds into the run
  final double scale;
  final double spin; // radians per second
  _Particle(this.vx, this.vy, this.delay, this.scale, this.spin);
}

class _Pixel {
  final double vx; // launch velocity, px/s
  final double vy;
  final double delay; // seconds into the run
  final double life; // seconds
  final double phase; // sway + flicker phase, radians
  final int w; // size in grid cells
  final int h;
  final List<Color> shades; // the two colours it flickers between
  _Pixel(this.vx, this.vy, this.delay, this.life, this.phase, this.w, this.h,
      this.shades);
}

class _TipBurstState extends State<_TipBurst>
    with SingleTickerProviderStateMixin {
  static const _coneHalf = 13 * math.pi / 180;
  static const _emojiCount = [4, 8, 12];
  static const _pixelCount = [5, 11, 20];
  static const _height = [100.0, 120.0, 140.0]; // px, the fountain's top
  static const _stream = [0.30, 0.48, 0.65]; // seconds the launches are spread over
  static const _labelSecs = 1.5;
  static const _palette = [
    [Color(0xFF39D0C0), Color(0xFF1F8F84)],
    [Color(0xFFF5C451), Color(0xFFB8862A)],
    [Color(0xFFFF5FA8), Color(0xFFB83A75)],
    [Color(0xFFFFFFFF), Color(0xFFAEB8C2)],
  ];

  // The last pixel can launch at the end of the stream and live 1.9 s.
  late final double _secs = _stream[widget.level - 1] + 1.95;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_secs * 1000).round()),
  );
  late final List<_Particle> _parts;
  late final List<_Pixel> _pixels;

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    final lv = widget.level - 1;
    final h = _height[lv];
    final n = _emojiCount[lv];
    // The cone is split into n equal slices and each emoji takes one, at a
    // random spot inside it, so they always fan out (a fully random pick
    // could send them all the same way, seen on device 11-20). Slices are
    // shuffled so the launch order doesn't sweep left to right.
    final slice = 2 * _coneHalf / n;
    final order = List.generate(n, (i) => i)..shuffle(r);
    _parts = List.generate(n, (i) {
      final a = -_coneHalf + slice * (order[i] + 0.15 + 0.7 * r.nextDouble());
      // Speed that tops out at 72–100 % of the fountain's height.
      final v = math.sqrt(2 * _kGravity * h * (0.72 + 0.28 * r.nextDouble()));
      return _Particle(
        math.sin(a) * v,
        -math.cos(a) * v,
        i / n * _stream[lv] + r.nextDouble() * 0.03,
        0.9 + r.nextDouble() * 0.6,
        (r.nextDouble() * 2 - 1) * 2.2,
      );
    });
    // Confetti leaves from the button with the emojis, in a cone almost
    // twice as wide and with more varied speed.
    final top = math.sqrt(2 * _kGravity * h);
    _pixels = List.generate(_pixelCount[lv], (_) {
      final a = (r.nextDouble() * 2 - 1) * _coneHalf * 1.9;
      final v = top * (0.55 + 0.6 * r.nextDouble());
      return _Pixel(
        math.sin(a) * v,
        -math.cos(a) * v,
        r.nextDouble() * _stream[lv],
        1.1 + r.nextDouble() * 0.8,
        r.nextDouble() * 2 * math.pi,
        r.nextDouble() < 0.25 ? 2 : 1,
        r.nextDouble() < 0.15 ? 2 : 1,
        _palette[r.nextInt(_palette.length)],
      );
    });
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _height[widget.level - 1];
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final s = _c.value * _secs; // seconds into the run
          final children = <Widget>[
            Positioned.fill(
              child: CustomPaint(
                painter: _PixelPainter(_pixels, widget.origin, s),
              ),
            ),
          ];
          for (final p in _parts) {
            final tau = s - p.delay;
            if (tau <= 0) continue;
            final dx = p.vx * tau;
            final dy = p.vy * tau + 0.5 * _kGravity * tau * tau;
            // Full on the way up; fades over the lower part of the fall and
            // is gone just above the button.
            var opacity = 1.0;
            if (p.vy + _kGravity * tau > 0) {
              opacity = ((-6 - dy) / (h * 0.45)).clamp(0.0, 1.0);
              if (opacity <= 0) continue;
            }
            final grow = (tau / 0.14).clamp(0.0, 1.0);
            children.add(Positioned(
              left: widget.origin.dx + dx - 12,
              top: widget.origin.dy + dy - 12,
              child: Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: p.spin * tau,
                  child: Transform.scale(
                    scale: (0.3 + 0.7 * grow) * p.scale,
                    child: Text(widget.emoji,
                        style: const TextStyle(fontSize: 18, decoration: TextDecoration.none)),
                  ),
                ),
              ),
            ));
          }
          // The amount rises from the button.
          final t = (s / _labelSecs).clamp(0.0, 1.0);
          if (t < 1) {
            final lt = Curves.easeOut.transform(t);
            children.add(Positioned(
              left: widget.origin.dx - 60,
              width: 120,
              top: widget.origin.dy - 18 - 46 * lt,
              child: Opacity(
                opacity: (t < 0.2 ? t / 0.2 : (t > 0.7 ? (1 - t) / 0.3 : 1.0))
                    .clamp(0.0, 1.0),
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
                ),
              ),
            ));
          }
          return Stack(children: children);
        },
      ),
    );
  }
}

/// The pixel confetti: each piece is thrown from the button, loses its
/// sideways speed to drag, falls at half gravity up to a slow terminal speed
/// and sways as it goes. Drawn unsmoothed and snapped to a 4 px grid, so it
/// steps from cell to cell.
class _PixelPainter extends CustomPainter {
  final List<_Pixel> pixels;
  final Offset origin;
  final double secs;
  _PixelPainter(this.pixels, this.origin, this.secs);

  static const _cell = 4.0;
  static const _drag = 2.6; // per second, on sideways speed
  static const _fall = _kGravity * 0.5;
  static const _terminal = 150.0; // px/s
  static const _sway = 26.0; // px/s
  static const _swayRate = 7.0; // radians per second

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    for (final p in pixels) {
      final tau = secs - p.delay;
      if (tau <= 0 || tau >= p.life) continue;
      // The last 0.35 s it blinks, on for 60 ms and off for 60 ms.
      if (p.life - tau < 0.35 && (tau / 0.06).floor().isOdd) continue;
      final x = origin.dx +
          p.vx * (1 - math.exp(-_drag * tau)) / _drag +
          _sway * (math.cos(p.phase) - math.cos(_swayRate * tau + p.phase)) / _swayRate;
      // Accelerates until it reaches terminal speed, then falls steadily.
      final tc = (_terminal - p.vy) / _fall;
      final y = origin.dy +
          (tau < tc
              ? p.vy * tau + 0.5 * _fall * tau * tau
              : p.vy * tc + 0.5 * _fall * tc * tc + _terminal * (tau - tc));
      paint.color = p.shades[(tau / 0.11 + p.phase).floor() % 2];
      canvas.drawRect(
        Rect.fromLTWH(
          (x / _cell).roundToDouble() * _cell,
          (y / _cell).roundToDouble() * _cell,
          _cell * p.w,
          _cell * p.h,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelPainter old) => old.secs != secs;
}
