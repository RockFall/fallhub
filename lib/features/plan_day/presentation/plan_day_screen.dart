import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../application/plan_day_controller.dart';
import '../application/plan_day_providers.dart';
import 'widgets/plan_composer.dart';
import 'widgets/plan_item_row.dart';

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
  var _carryOverDismissed = false;
  var _carryOverChoosing = false;

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
    final rowsAsync = ref.watch(planDayRowsProvider);
    final progress = ref.watch(planDayProgressProvider);
    final carryOver = ref.watch(planCarryOverProvider).asData?.value ?? const [];
    final showCarryOver =
        !_carryOverDismissed && carryOver.isNotEmpty && day == today;
    final composerEnabled = !rowsAsync.hasError;

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
        if (showCarryOver)
          _CarryOverBanner(
            items: carryOver,
            choosing: _carryOverChoosing,
            onAddAll: () async {
              await ref
                  .read(planDayControllerProvider.notifier)
                  .carryOverAll(carryOver);
              if (mounted) {
                setState(() {
                  _carryOverDismissed = true;
                  _carryOverChoosing = false;
                });
              }
            },
            onChoose: () => setState(() => _carryOverChoosing = true),
            onAddOne: (item) => ref
                .read(planDayControllerProvider.notifier)
                .carryOverOne(item),
            onDismiss: () => setState(() {
              _carryOverDismissed = true;
              _carryOverChoosing = false;
            }),
          ),
        Expanded(
          child: rowsAsync.when(
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
                      onPressed: () => ref.invalidate(dayPlanProvider),
                      child: const Text(AppStrings.planDayRetry),
                    ),
                  ],
                ),
              ),
            ),
            data: (rows) {
              final open = rows.where((row) => !row.isDone).toList();
              final done = rows.where((row) => row.isDone).toList();
              if (rows.isEmpty) {
                return _EmptyState(
                  hasSuggestions:
                      ref.watch(planPullableTasksProvider).isNotEmpty,
                );
              }
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ColonySpacing.sm,
                    ),
                    sliver: SliverReorderableList(
                      itemCount: open.length,
                      onReorder: (oldIndex, newIndex) {
                        var target = newIndex;
                        if (oldIndex < target) target -= 1;
                        final next = [...open];
                        final moved = next.removeAt(oldIndex);
                        next.insert(target, moved);
                        ref.read(planDayControllerProvider.notifier).reorder([
                          ...next.map((row) => row.item.id),
                          ...done.map((row) => row.item.id),
                        ]);
                      },
                      itemBuilder: (context, index) {
                        final row = open[index];
                        return ReorderableDelayedDragStartListener(
                          key: ValueKey(row.item.id.value),
                          index: index,
                          child: PlanItemRow(
                            row: row,
                            onMoveUp: index == 0
                                ? null
                                : () {
                                    final next = [...open];
                                    final item = next.removeAt(index);
                                    next.insert(index - 1, item);
                                    ref
                                        .read(
                                          planDayControllerProvider.notifier,
                                        )
                                        .reorder([
                                      ...next.map((r) => r.item.id),
                                      ...done.map((r) => r.item.id),
                                    ]);
                                  },
                            onMoveDown: index == open.length - 1
                                ? null
                                : () {
                                    final next = [...open];
                                    final item = next.removeAt(index);
                                    next.insert(index + 1, item);
                                    ref
                                        .read(
                                          planDayControllerProvider.notifier,
                                        )
                                        .reorder([
                                      ...next.map((r) => r.item.id),
                                      ...done.map((r) => r.item.id),
                                    ]);
                                  },
                          ),
                        );
                      },
                    ),
                  ),
                  if (open.isEmpty && done.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(ColonySpacing.lg),
                        child: Text(
                          AppStrings.planDayAllDone,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (done.isNotEmpty)
                    SliverToBoxAdapter(
                      child: ColonyPanel(
                        title: AppStrings.planDayCompletedCount(done.length),
                        collapsible: true,
                        initiallyExpanded: false,
                        child: Column(
                          children: [
                            for (final row in done) PlanItemRow(row: row),
                          ],
                        ),
                      ),
                    ),
                ],
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

class _CarryOverBanner extends StatelessWidget {
  const _CarryOverBanner({
    required this.items,
    required this.choosing,
    required this.onAddAll,
    required this.onChoose,
    required this.onAddOne,
    required this.onDismiss,
  });

  final List<DayPlanItem> items;
  final bool choosing;
  final VoidCallback onAddAll;
  final VoidCallback onChoose;
  final ValueChanged<DayPlanItem> onAddOne;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: ColonySpacing.md,
        vertical: ColonySpacing.sm,
      ),
      padding: const EdgeInsets.all(ColonySpacing.md),
      decoration: BoxDecoration(
        color: ColonyColors.raised,
        borderRadius: BorderRadius.circular(ColonyRadii.soft),
        border: const Border(
          left: BorderSide(width: 3, color: ColonyColors.accentSand),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 18, color: ColonyColors.accentSand),
              const SizedBox(width: ColonySpacing.sm),
              Expanded(
                child: Text(AppStrings.planDayCarryOverBanner(items.length)),
              ),
              IconButton(
                tooltip: AppStrings.planDayCarryOverDismiss,
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          Wrap(
            spacing: ColonySpacing.sm,
            children: [
              TextButton(
                onPressed: onAddAll,
                child: Text(AppStrings.planDayCarryOverAddAll(items.length)),
              ),
              TextButton(
                onPressed: onChoose,
                child: const Text(AppStrings.planDayCarryOverPick),
              ),
            ],
          ),
          if (choosing)
            for (final item in items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(item.title),
                trailing: IconButton(
                  tooltip: AppStrings.planDayCarryOverAction,
                  onPressed: () => onAddOne(item),
                  icon: const Icon(Icons.add),
                ),
              ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSuggestions});

  final bool hasSuggestions;

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
          if (!hasSuggestions) ...[
            const SizedBox(height: ColonySpacing.sm),
            Text(
              AppStrings.planDayEmptyHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColonyColors.textMuted,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
