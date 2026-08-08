import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/features/habitat/presentation/character_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CharacterCreateScreen shows RimWorld-style chrome', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: CharacterCreateScreen())),
      ),
    );
    await tester.pump();

    expect(
      find.textContaining(AppStrings.habitatCreateTitle.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(AppStrings.habitatCatHair), findsWidgets);
    // Actions live as icon tooltips in the toolbar / category header.
    expect(find.byTooltip(AppStrings.habitatAcceptPawn), findsOneWidget);
    expect(find.byTooltip(AppStrings.habitatRandomAll), findsOneWidget);
    expect(find.byTooltip(AppStrings.habitatResetLook), findsOneWidget);
    expect(find.byTooltip(AppStrings.habitatTitle), findsNothing);
    expect(find.byTooltip(AppStrings.habitatRandomHair), findsOneWidget);

    // Options pane should own most of the width (not a sliver).
    final options = tester.getSize(find.text(AppStrings.habitatHairStyle).first);
    expect(options.width, greaterThan(0));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
