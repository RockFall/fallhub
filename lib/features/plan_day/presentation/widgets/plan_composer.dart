import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../tasks/application/task_controller.dart';
import '../../../tasks/presentation/widgets/task_composer.dart';

class PlanComposer extends ConsumerWidget {
  const PlanComposer({
    super.key,
    this.autoFocus = false,
    this.enabled = true,
  });

  final bool autoFocus;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TaskComposer(
      enabled: enabled,
      autoFocus: autoFocus,
      hint: AppStrings.planDayComposerHint,
      onSubmit: (title) async {
        await ref.read(taskBacklogControllerProvider.notifier).createNamed(title);
      },
    );
  }
}
