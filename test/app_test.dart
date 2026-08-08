import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/bootstrap/colony_app.dart';
import 'package:fallhub/core/providers/app_providers.dart';

void main() {
  testWidgets('shows onboarding when no profile', (tester) async {
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const ColonyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CRIAR COLÔNIA'), findsOneWidget);
  });

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
