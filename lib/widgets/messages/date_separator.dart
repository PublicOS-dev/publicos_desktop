import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Glass-styled pill separator between day groups in a chat scroll view.
/// Shows "Today" / "Yesterday" / `yyyy-MM-dd` based on the difference
/// between [date] and `DateTime.now()` at construction time. Pure styling,
/// no state.
@immutable
class DateSeparator extends StatelessWidget {
  final DateTime date;

  final int _daysFromNow;

  static final DateFormat _defaultFormatter = DateFormat('yyyy-MM-dd');

  static const double _horizontalPadding = 12;
  static const double _verticalPadding = 6;
  static const double _borderRadius = 16;
  static const double _fontSize = 11;

  DateSeparator({
    super.key,
    required this.date,
  }) : _daysFromNow = _calculateDaysFromNow(date);

  static int _calculateDaysFromNow(DateTime date) {
    final now = DateTime.now();
    return now.difference(date).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _horizontalPadding,
          vertical: _verticalPadding,
        ),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(_borderRadius),
          // Borderless (both apps): the fill alone reads.
        ),
        child: Text(
          _getDisplayText(),
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: _fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  String _getDisplayText() {
    if (_daysFromNow == 0) return 'Today';
    if (_daysFromNow == 1) return 'Yesterday';
    return _defaultFormatter.format(date);
  }
}
