import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/plan_day_controller.dart';
import '../../application/plan_day_providers.dart';

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
    await ref.read(planDayControllerProvider.notifier).createNamed(text);
    if (!mounted) return;
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final lists = ref.watch(todayPlanTasksProvider);
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
          lists.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text(AppStrings.errorGeneric),
            data: (day) {
              if (day.open.isEmpty && day.done.isEmpty) {
                return Text(
                  AppStrings.planDayHomeEmpty,
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              final firstOpen = day.open.isEmpty ? null : day.open.first;
              final total = day.total;
              final done = day.done.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          value: total == 0 ? 0 : done / total,
                          strokeWidth: 3,
                          color: ColonyMiniAppColors.planDay,
                          backgroundColor: ColonyColors.void_,
                        ),
                      ),
                      const SizedBox(width: ColonySpacing.sm),
                      Text(
                        AppStrings.planDayProgress(done, total),
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
                                .toggleDone(firstOpen),
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
