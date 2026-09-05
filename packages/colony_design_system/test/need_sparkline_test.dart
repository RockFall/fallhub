import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('needSparklineLinePairs spans missing days', () {
    expect(needSparklineLinePairs(const [0.2, null, null, 0.8]), [(0, 3)]);
    expect(needSparklineLinePairs(const [0.1, 0.2, null, 0.9, null, 0.4]), [
      (0, 1),
      (1, 3),
      (3, 5),
    ]);
  });

  test('needSparklineLinePairs needs two samples to draw', () {
    expect(needSparklineLinePairs(const [null, 0.5, null]), isEmpty);
    expect(needSparklineLinePairs(const [null, null]), isEmpty);
    expect(needSparklineLinePairs(const [0.4]), isEmpty);
  });

  testWidgets('NeedSparkline paints gapped history without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NeedSparkline(
            values: [0.2, null, null, 0.8, 0.5],
            labels: ['S', 'T', 'Q', 'Q', 'S'],
            selectedIndex: 3,
          ),
        ),
      ),
    );

    expect(find.byType(NeedSparkline), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('S'), findsNWidgets(2));
  });
}
