import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/feature_controllers.dart';

void showPlanDayUndoSnack(BuildContext context, WidgetRef ref, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: AppStrings.undo,
          onPressed: () =>
              ref.read(captureControllerProvider.notifier).undoLast(),
        ),
      ),
    );
}

void showPlanDayOpenSnack(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: AppStrings.planDayOpenPlan,
          onPressed: () {
            if (context.mounted) context.go('/today');
          },
        ),
      ),
    );
}
