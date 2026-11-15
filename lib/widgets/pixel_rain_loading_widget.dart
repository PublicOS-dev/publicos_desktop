import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/glass_tokens.dart';

/// Pixel-rain loading widget on a 16x16 logical grid — white drops fall onto
/// a wavy waterline and splash on impact. Plug-compatible with
/// [PhigitalLoadingWidget]'s constructor; only [size] and [color] are wired.
/// Extra params are accepted and ignored so call sites can swap without edits.
///
/// Copied from publicos_client (`components/pixel_rain_loading_widget.dart`).
/// The only edit vs the client is the theme import.
class PixelRainLoadingWidget extends StatefulWidget {
  final bool? rotate;
  final double size;
  final bool showShadows;
  final bool pulse;
  final bool group;
  final Color? color;

  const PixelRainLoadingWidget({
    super.key,
    this.rotate = true,
    this.size = 40,
    this.showShadows = true,
    this.pulse = false,
    this.group = false,
    this.color,
  });

  @override
  State<PixelRainLoadingWidget> createState() => _PixelRainLoadingWidgetState();
}

class _Drop {
  int col;
  int row;
  final int len;
  final int speed;
  int hold = 0;
  _Drop(this.col, this.row, this.len, this.speed);
}

class _Splash {
  final int col;
  final int row;
  int ttl;
  _Splash(this.col, this.row, this.ttl);
}

class _PixelRainLoadingWidgetState extends State<PixelRainLoadingWidget>
    with SingleTickerProviderStateMixin {
  static const int _grid = 16;
  static const int _baseline = 12;
  static const int _waveAmp = 2;
  static const double _stutterChance = 0.12;
  static const int _tickStepMicros = 110 * 1000;
  static const double _spawnRatePerSec = 10.0;

  late final Ticker _ticker;
  final List<_Drop> _drops = [];
  final List<_Splash> _splashes = [];
  final math.Random _rng = math.Random();
  double _wavePhase = 0;
  int _tickAccMicros = 0;
  double _spawnAcc = 0;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onFrame)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onFrame(Duration elapsed) {
    final dtMicros = (elapsed - _lastElapsed).inMicroseconds;
    _lastElapsed = elapsed;
    if (dtMicros <= 0) return;

    _tickAccMicros += dtMicros;
    while (_tickAccMicros >= _tickStepMicros) {
      _tick();
      _tickAccMicros -= _tickStepMicros;
    }

    _spawnAcc += (dtMicros / 1e6) * _spawnRatePerSec;
    while (_spawnAcc >= 1) {
      _spawnDrop();
      _spawnAcc -= 1;
    }

    if (mounted) setState(() {});
  }

  int _waveDelta(int col) {
    final v = math.sin((col / _grid) * math.pi * 2 + _wavePhase) * 0.5 + 0.5;
    return (v * _waveAmp).round();
  }

  int _surfaceTop(int col) => _baseline - _waveDelta(col);

  void _spawnDrop() {
    final col = _rng.nextInt(_grid);
    final r = _rng.nextDouble();
    final int len;
    final int speed;
    if (r < 0.60) {
      len = 1;
      speed = 1;
    } else if (r < 0.85) {
      len = 2;
      speed = 1;
    } else {
      len = 1;
      speed = 2;
    }
    _drops.add(_Drop(col, -1 - _rng.nextInt(3), len, speed));
  }

  void _spawnSplash(int col, int row) {
    if (col > 0) _splashes.add(_Splash(col - 1, row - 1, 2));
    if (col < _grid - 1) _splashes.add(_Splash(col + 1, row - 1, 2));
  }

  void _tick() {
    _wavePhase += 0.25;
    for (var i = _drops.length - 1; i >= 0; i--) {
      final d = _drops[i];
      if (d.hold > 0) {
        d.hold -= 1;
        continue;
      }
      if (_rng.nextDouble() < _stutterChance) {
        d.hold = 1;
        continue;
      }
      d.row += d.speed;
      final top = _surfaceTop(d.col);
      if (d.row >= top) {
        _spawnSplash(d.col, top);
        _drops.removeAt(i);
      } else if (d.row >= _grid) {
        _drops.removeAt(i);
      }
    }
    for (var i = _splashes.length - 1; i >= 0; i--) {
      _splashes[i].ttl -= 1;
      if (_splashes[i].ttl <= 0) _splashes.removeAt(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final color = widget.color ?? tokens.starkWhite;
    final radius = widget.size * (14 / 44);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          borderRadius: BorderRadius.circular(radius),
          // border: Border.all(
          //   color: tokens.starkWhite.withValues(alpha: 0.2),
          //   width: 1,
          // ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: CustomPaint(
            painter: _PixelRainPainter(
              drops: _drops,
              splashes: _splashes,
              surfaceTop: _surfaceTop,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _PixelRainPainter extends CustomPainter {
  static const int _grid = 16;
  final List<_Drop> drops;
  final List<_Splash> splashes;
  final int Function(int col) surfaceTop;
  final Color color;

  _PixelRainPainter({
    required this.drops,
    required this.splashes,
    required this.surfaceTop,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _grid;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;

    void px(int col, int row) {
      if (row < 0 || row >= _grid) return;
      canvas.drawRect(
        Rect.fromLTWH(col * cell, row * cell, cell, cell),
        paint,
      );
    }

    for (var col = 0; col < _grid; col++) {
      final top = surfaceTop(col);
      for (var row = top; row < _grid; row++) {
        px(col, row);
      }
    }
    for (final d in drops) {
      px(d.col, d.row);
      if (d.len == 2) px(d.col, d.row - 1);
    }
    for (final s in splashes) {
      px(s.col, s.row);
    }
  }

  @override
  bool shouldRepaint(_PixelRainPainter old) => true;
}
