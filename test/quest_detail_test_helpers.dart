import 'package:colony_database/colony_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';

/// Avoids hanging on QuestDetailScreen stream/timer teardown.
Future<void> settleQuestDetail(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> waitForQuestDetailStreams(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> tapQuestRelationsTab(WidgetTester tester) async {
  await tester.tap(find.text(AppStrings.questDetailTabRelations));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> tearDownQuestDetail(
  WidgetTester tester,
  ColonyDatabase db,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await db.close();
}
