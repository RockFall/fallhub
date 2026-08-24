import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/plan_day_controller.dart';
import '../../application/plan_day_providers.dart';
import 'plan_day_feedback.dart';

class PlanDayHomeCard extends ConsumerStatefulWidget {
  const PlanDayHomeCard({super.key});

  @override
  ConsumerState<PlanDayHomeCard> createState() => _PlanDayHomeCardState();
}

class _PlanDayHomeCardState extends ConsumerState<PlanDayHomeCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await ref.read(planDayControllerProvider.notifier).addAdHocToToday(text);
    if (!mounted) return;
    _controller.clear();
    showPlanDayOpenSnack(context, AppStrings.planDayAddedSnack);
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(todayPlanRowsProvider);
    return ColonyHomeCard(
      icon: Icons.wb_twilight_outlined,
      title: AppStrings.planDayTitle,
      action: TextButton(
        onPressed: () => context.go('/today'),
        child: const Text(AppStrings.planDayHomeCta),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          rows.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text(AppStrings.errorGeneric),
            data: (list) {
              if (list.isEmpty) {
                return Text(
                  AppStrings.planDayHomeEmpty,
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              final done = list.where((row) => row.isDone).length;
              PlanRow? firstOpen;
              for (final row in list) {
                if (!row.isDone) {
                  firstOpen = row;
                  break;
                }
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          value: done / list.length,
                          strokeWidth: 3,
                          color: ColonyMiniAppColors.planDay,
                          backgroundColor: ColonyColors.void_,
                        ),
                      ),
                      const SizedBox(width: ColonySpacing.sm),
                      Text(
                        AppStrings.planDayProgress(done, list.length),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  if (firstOpen != null) ...[
                    const SizedBox(height: ColonySpacing.xs),
                    Row(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: Checkbox(
                            value: false,
                            onChanged: (_) => ref
                                .read(planDayControllerProvider.notifier)
                                .toggle(firstOpen!),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.go('/today'),
                            child: Text(
                              firstOpen.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: ColonySpacing.sm),
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              isDense: true,
              hintText: AppStrings.planDayComposerHint,
            ),
          ),
        ],
      ),
    );
  }
}
