import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/quests/application/quest_providers.dart';
import 'package:fallhub/features/quests/presentation/quest_board_screen.dart';

void main() {
  testWidgets('QuestBoardScreen shows empty state', (tester) async {
    final profile = ColonyProfile.create(
      id: const EntityId('profile-1'),
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
      createdAt: DateTime.utc(2026, 8, 6),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) async => profile),
          questsProvider.overrideWith((ref) async* {
            yield [];
          }),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const QuestBoardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.questBoardEmpty), findsOneWidget);
    expect(find.text(AppStrings.newQuest), findsOneWidget);
  });
}
