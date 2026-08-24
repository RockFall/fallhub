import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../tasks/application/task_providers.dart';
import '../../tasks/presentation/widgets/task_list_row.dart';
import '../application/plan_day_controller.dart';
import '../application/plan_day_providers.dart';
import 'widgets/plan_composer.dart';

class PlanDayScreen extends ConsumerStatefulWidget {
  const PlanDayScreen({
    super.key,
    this.initialDay,
    this.focusComposer = false,
  });

  final String? initialDay;
  final bool focusComposer;

  @override
  ConsumerState<PlanDayScreen> createState() => _PlanDayScreenState();
}

class _PlanDayScreenState extends ConsumerState<PlanDayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyIncomingDay());
  }

  @override
  void didUpdateWidget(covariant PlanDayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDay != widget.initialDay) {
      _applyIncomingDay();
    }
  }

  void _applyIncomingDay() {
    if (!mounted) return;
    final initial = widget.initialDay;
    if (initial != null && DayPlanPolicies.isValidLocalDateKey(initial)) {
      ref.read(planSelectedDayProvider.notifier).select(initial);
      return;
    }
    ref.read(planSelectedDayProvider.notifier).select(
          dayPlanLocalDateKey(ref.read(clockProvider)()),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(planDayControllerProvider, (previous, next) {
      if (next.hasError && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.errorGeneric)),
        );
      }
    });

    final day = ref.watch(planSelectedDayProvider);
    final today = dayPlanLocalDateKey(ref.watch(clockProvider)());
    final listsAsync = ref.watch(planDayTasksProvider);
    final sectionsAsync = ref.watch(planDaySectionsProvider);
    final progress = ref.watch(planDayProgressProvider);
    final grouped = ref.watch(planDayGroupByProjectProvider);
    final composerEnabled = !listsAsync.hasError;

    return Column(
      children: [
        _PlanHeader(
          localDate: day,
          isToday: day == today,
          done: progress.$1,
          total: progress.$2,
          onPrev: () => ref
              .read(planSelectedDayProvider.notifier)
              .select(dayPlanShiftDate(day, -1)),
          onNext: () => ref
              .read(planSelectedDayProvider.notifier)
              .select(dayPlanShiftDate(day, 1)),
          onToday: () =>
              ref.read(planSelectedDayProvider.notifier).select(today),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ColonySpacing.md),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              label: const Text(AppStrings.tasksGroupByProject),
              selected: grouped,
              onSelected: (_) => ref
                  .read(planDayGroupByProjectProvider.notifier)
                  .toggleGroupByProject(),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        Expanded(
          child: listsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Padding(
                padding: const EdgeInsets.all(ColonySpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(AppStrings.planDayErrorLoad),
                    const SizedBox(height: ColonySpacing.sm),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(activeTasksProvider);
                        ref.invalidate(doneTasksProvider);
                      },
                      child: const Text(AppStrings.planDayRetry),
                    ),
                  ],
                ),
              ),
            ),
            data: (lists) {
              return sectionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
                data: (sections) {
                  final isEmpty = lists.open.isEmpty && lists.done.isEmpty;
                  if (isEmpty) {
                    return const _EmptyState();
                  }
                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ColonySpacing.sm,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            for (final section in sections)
                              if (section.title.isEmpty)
                                Column(
                                  children: [
                                    for (final task in section.tasks)
                                      TaskListRow(task: task),
                                  ],
                                )
                              else
                                ColonyPanel(
                                  title: section.title,
                                  child: Column(
                                    children: [
                                      for (final task in section.tasks)
                                        TaskListRow(task: task),
                                    ],
                                  ),
                                ),
                          ]),
                        ),
                      ),
                      if (lists.open.isEmpty && lists.done.isNotEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(ColonySpacing.lg),
                            child: Text(
                              AppStrings.planDayAllDone,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      if (lists.done.isNotEmpty)
                        SliverToBoxAdapter(
                          child: ColonyPanel(
                            title: AppStrings.planDayCompletedCount(
                              lists.done.length,
                            ),
                            collapsible: true,
                            initiallyExpanded: false,
                            child: Column(
                              children: [
                                for (final task in lists.done)
                                  TaskListRow(task: task),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        PlanComposer(
          autoFocus: widget.focusComposer,
          enabled: composerEnabled,
        ),
      ],
    );
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({
    required this.localDate,
    required this.isToday,
    required this.done,
    required this.total,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final String localDate;
  final bool isToday;
  final int done;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final progress = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ColonySpacing.sm,
        ColonySpacing.md,
        ColonySpacing.sm,
        ColonySpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: AppStrings.planDayPreviousDay,
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      AppStrings.planDayDateHeading(
                        localDate,
                        isToday: isToday,
                      ),
                      style: text.titleMedium,
                    ),
                    if (!isToday)
                      TextButton(
                        onPressed: onToday,
                        child: const Text(AppStrings.planDayJumpToday),
                      ),
                  ],
                ),
              ),
              if (total > 0)
                Text(
                  AppStrings.planDayProgress(done, total),
                  style: text.labelLarge?.copyWith(
                    color: ColonyColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              IconButton(
                tooltip: AppStrings.planDayNextDay,
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(ColonyRadii.sm),
            child: LinearProgressIndicator(
              minHeight: 3,
              value: progress,
              color: ColonyMiniAppColors.planDay,
              backgroundColor: ColonyColors.void_,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wb_twilight_outlined,
            size: 32,
            color: ColonyColors.textMuted,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.planDayEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColonyColors.textMuted,
                ),
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.planDayEmptyHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColonyColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}
