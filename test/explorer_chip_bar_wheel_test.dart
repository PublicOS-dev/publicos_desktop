// Pins the wheel→horizontal translation on ExplorerChipBar and, more
// importantly, its three guards.
//
// The feature itself is one line; the guards are the part worth a test. Each
// exists to stop a DOUBLE scroll, because a `Listener` does not consume a
// pointer signal and the ListView is registered for the same event — so any
// delta the ListView can already act on must be left alone. A refactor that
// "simplifies" the handler by dropping a guard produces a bar that moves twice
// as fast under a trackpad or Shift, which is easy to miss by eye and trivial
// to catch here.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:publicos_desktop/widgets/explorer_chip.dart';

/// Narrow enough that the chips must overflow, so there is somewhere to scroll.
const double _barWidth = 220;

Widget _bar({int chips = 12}) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: _barWidth,
            child: ExplorerChipBar(
              children: [
                for (var i = 0; i < chips; i++)
                  ExplorerChip(
                    label: 'chip $i',
                    icon: Icons.tune_rounded,
                    active: false,
                  ),
              ],
            ),
          ),
        ),
      ),
    );

ScrollableState _scrollable(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable));

double _offset(WidgetTester tester) => _scrollable(tester).position.pixels;

/// Sends one wheel event at the centre of the bar.
Future<void> _wheel(
  WidgetTester tester,
  Offset delta, {
  PointerDeviceKind kind = PointerDeviceKind.mouse,
}) async {
  final centre = tester.getCenter(find.byType(ExplorerChipBar));
  final pointer = TestPointer(1, kind);
  pointer.hover(centre);
  await tester.sendEventToBinding(pointer.scroll(delta));
  await tester.pump();
}

void main() {
  testWidgets('a vertical wheel scrolls the chips toward the right end',
      (tester) async {
    await tester.pumpWidget(_bar());
    await tester.pump();
    expect(_offset(tester), 0);
    expect(_scrollable(tester).position.maxScrollExtent, greaterThan(0),
        reason: 'the chips must overflow or there is nothing to test');

    await _wheel(tester, const Offset(0, 120));
    expect(_offset(tester), 120);
  });

  testWidgets('scrolling up walks it back, and it never goes past the start',
      (tester) async {
    await tester.pumpWidget(_bar());
    await tester.pump();

    await _wheel(tester, const Offset(0, 120));
    await _wheel(tester, const Offset(0, -50));
    expect(_offset(tester), 70);

    // Clamping is Flutter's (ScrollPosition.pointerScroll), not ours — assert
    // it anyway, since the whole point of delegating was to inherit it.
    await _wheel(tester, const Offset(0, -9999));
    expect(_offset(tester), 0);
  });

  testWidgets('GUARD 1: a delta carrying dx is left to the ListView',
      (tester) async {
    await tester.pumpWidget(_bar());
    await tester.pump();

    // A trackpad delivers both axes. The ListView consumes the dx itself; if
    // the handler also translated the dy the bar would move twice per event.
    await _wheel(tester, const Offset(30, 120),
        kind: PointerDeviceKind.trackpad);
    expect(_offset(tester), 30,
        reason: 'only the ListView\'s own dx handling should have applied');
  });

  testWidgets('GUARD 2: with Shift held, the axis flip already handles it',
      (tester) async {
    await tester.pumpWidget(_bar());
    await tester.pump();

    await simulateKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    addTearDown(() => simulateKeyUpEvent(LogicalKeyboardKey.shiftLeft));

    // Scrollable flips its axis for a Shift-held mouse wheel and reads this
    // very dy, so the handler must stand down. One 120 of movement, not two.
    await _wheel(tester, const Offset(0, 120));
    expect(_offset(tester), 120);
  });

  testWidgets('GUARD 3: a bar whose chips fit does not move', (tester) async {
    await tester.pumpWidget(_bar(chips: 1));
    await tester.pump();
    expect(_scrollable(tester).position.maxScrollExtent, 0);

    await _wheel(tester, const Offset(0, 120));
    expect(_offset(tester), 0);
  });
}
