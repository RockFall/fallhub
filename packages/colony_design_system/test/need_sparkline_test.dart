import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('needSparklineHitAt prefers a sample inside the tapped day', () {
    const points = [
      NeedSparklinePoint(x: 5.5 / 7, value: 0.2),
      NeedSparklinePoint(x: 5.7 / 7, value: 0.8),
      NeedSparklinePoint(x: 6.5 / 7, value: 0.4),
    ];

    final morning = needSparklineHitAt(
      x: 5.2 / 7,
      points: points,
      dayCount: 7,
    );
    expect(morning.dayIndex, 5);
    expect(morning.pointIndex, 0);

    final evening = needSparklineHitAt(
      x: 5.8 / 7,
      points: points,
      dayCount: 7,
    );
    expect(evening.dayIndex, 5);
    expect(evening.pointIndex, 1);

    final empty = needSparklineHitAt(x: 1.4 / 7, points: points, dayCount: 7);
    expect(empty.dayIndex, 1);
    expect(empty.pointIndex, isNull);
  });

  testWidgets('NeedSparkline paints several same-day points', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NeedSparkline(
            points: [
              NeedSparklinePoint(x: 0.10, value: 0.2),
              NeedSparklinePoint(x: 0.16, value: 0.8),
              NeedSparklinePoint(x: 0.72, value: 0.5),
            ],
            labels: ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'],
            selectedIndex: 1,
            highlightedDayIndex: 1,
          ),
        ),
      ),
    );

    expect(find.byType(NeedSparkline), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('S'), findsNWidgets(3));
  });
}
