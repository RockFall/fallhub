import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/flashcards/presentation/widgets/flashcard_editor_sheet.dart';

Future<void> _flush(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  testWidgets('capture sheet shows front, back and three intents first', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 8, 17, 12);
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        for (var i = 1; i <= 40; i++) 'id-$i',
      ]),
      clock: () => now,
    );
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(
      AppPreferences.defaults().copyWith(onboardingCompleted: true),
    );
    final deck = await repos.flashcards.createDeck(
      profileId: profile.id,
      title: 'Caixa rápida',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: FlashcardEditorSheet(deckId: deck.id),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.flashcardsNewCard), findsOneWidget);
    expect(find.text(AppStrings.flashcardsFront), findsOneWidget);
    expect(find.text(AppStrings.flashcardsBack), findsOneWidget);
    expect(find.text(AppStrings.flashcardsSchedule), findsOneWidget);
    expect(find.text(AppStrings.flashcardsSaveOnly), findsOneWidget);
    expect(find.text(AppStrings.flashcardsPracticeNow), findsOneWidget);
    expect(find.text(AppStrings.flashcardsAdvanced), findsOneWidget);

    await _flush(tester);
  });
}
