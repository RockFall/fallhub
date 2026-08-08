import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NeedBar shows unknown label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
        home: const Scaffold(
          body: NeedBar(
            data: NeedBarData(label: 'Sono', statusText: 'Desconhecido'),
          ),
        ),
      ),
    );

    expect(find.text('Desconhecido'), findsOneWidget);
  });
}
