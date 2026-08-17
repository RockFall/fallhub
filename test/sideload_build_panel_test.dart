import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/sideload_build_info.dart';
import 'package:fallhub/features/settings/presentation/widgets/sideload_build_panel.dart';

void main() {
  test('SideloadBuildInfo is local when dart-defines are absent', () {
    expect(SideloadBuildInfo.isCiBuild, isFalse);
    expect(SideloadBuildInfo.gitSha, isEmpty);
    expect(SideloadBuildInfo.shortSha, isEmpty);
  });

  testWidgets('SideloadBuildPanel shows local copy without CI defines', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
        home: const Scaffold(body: SideloadBuildPanel()),
      ),
    );

    expect(
      find.text(AppStrings.sideloadBuildTitle.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(AppStrings.sideloadBuildLocal), findsOneWidget);
  });
}
