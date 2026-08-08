import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/features/work/presentation/widgets/work_priority_grid.dart';

void main() {
  testWidgets('WorkPriorityGrid renders work types and cycles on tap', (tester) async {
    const profileId = EntityId('profile-1');
    final priorities = [
      WorkPriority(
        profileId: profileId,
        workType: WorkType.mainWork,
        level: PriorityLevel.normal,
        updatedAt: DateTime.utc(2026, 8, 6),
      ),
      WorkPriority(
        profileId: profileId,
        workType: WorkType.finances,
        level: PriorityLevel.high,
        updatedAt: DateTime.utc(2026, 8, 6),
      ),
    ];

    WorkPriority? cycled;
    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
        home: Scaffold(
          body: WorkPriorityGrid(
            priorities: priorities,
            onCycle: (p) => cycled = p,
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.workTypeLabel(WorkType.mainWork)), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('3'));
    await tester.pump();

    expect(cycled?.workType, WorkType.mainWork);
  });
}
