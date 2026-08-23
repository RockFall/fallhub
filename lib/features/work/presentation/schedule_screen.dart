import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/app_locale.dart';
import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../application/work_controllers.dart';
import '../application/work_providers.dart';
import 'widgets/schedule_block_sheet.dart';
import 'widgets/schedule_conflict_panel.dart';
import 'widgets/schedule_day_timeline.dart';
import 'widgets/schedule_three_day_view.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  String? _lastHandledDateUri;

  void _handleDateDeepLink() {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final dateParam =
        router.routerDelegate.currentConfiguration.uri.queryParameters['date'];
    if (dateParam == null) return;
    final key = router.routerDelegate.currentConfiguration.uri.toString();
    if (_lastHandledDateUri == key) return;
    _lastHandledDateUri = key;

    final parsed = parseScheduleDateParam(dateParam);
    if (parsed != null) {
      ref.read(scheduleSelectedDayProvider.notifier).select(parsed);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleDateDeepLink();
    });
  }

  Future<void> _pickDay(DateTime currentDay) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDay,
      firstDate: scheduleCalendarDay(now.subtract(const Duration(days: 365))),
      lastDate: scheduleCalendarDay(now.add(const Duration(days: 365 * 3))),
    );
    if (picked != null) {
      ref.read(scheduleSelectedDayProvider.notifier).select(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scheduleControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading && context.mounted) {
        final message = next.error is ScheduleBlockTimeRangeException
            ? AppStrings.scheduleBlockInvalidTime
            : AppStrings.errorGeneric;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });

    final selectedDay = ref.watch(scheduleSelectedDayProvider);
    final viewMode = ref.watch(scheduleViewModeProvider);
    final isThreeDay = viewMode == ScheduleViewMode.threeDay;
    final blocks = ref.watch(scheduleDayProvider(selectedDay));
    final tasks = ref.watch(scheduledTasksDayProvider(selectedDay));
    final profile = ref.watch(profileProvider).asData?.value;
    final prefs = ref.watch(preferencesProvider).asData?.value;

    final locale = profile?.locale ?? 'pt_BR';
    final use24Hour = prefs?.use24HourFormat ?? true;
    final dateLabel = isThreeDay
        ? _threeDayRangeLabel(selectedDay, locale)
        : AppLocale.date('EEE, d MMM', locale).format(selectedDay);
    final timeFormat = AppLocale.time(use24Hour: use24Hour, locale: locale);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(ColonySpacing.lg),
          decoration: const BoxDecoration(
            color: ColonyColors.raised,
            border: Border(bottom: BorderSide(color: ColonyColors.borderSubtle)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/work'),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.schedule,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SegmentedButton<ScheduleViewMode>(
                      segments: [
                        ButtonSegment(
                          value: ScheduleViewMode.day,
                          label: Text(AppStrings.scheduleViewDay),
                          tooltip: AppStrings.scheduleDayView,
                        ),
                        ButtonSegment(
                          value: ScheduleViewMode.threeDay,
                          label: Text(AppStrings.scheduleViewThreeDays),
                          tooltip: AppStrings.scheduleThreeDayView,
                        ),
                      ],
                      selected: {viewMode},
                      onSelectionChanged: (selection) {
                        ref
                            .read(scheduleViewModeProvider.notifier)
                            .select(selection.first);
                      },
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: AppStrings.schedulePreviousDay,
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            ref
                                .read(scheduleSelectedDayProvider.notifier)
                                .select(selectedDay.subtract(const Duration(days: 1)));
                          },
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDay(selectedDay),
                            child: Text(
                              dateLabel,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: AppStrings.scheduleNextDay,
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            ref
                                .read(scheduleSelectedDayProvider.notifier)
                                .select(selectedDay.add(const Duration(days: 1)));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppStrings.addScheduleBlock,
                icon: const Icon(Icons.add),
                onPressed: () => ScheduleBlockSheet.showAdd(context, selectedDay),
              ),
            ],
          ),
        ),
        Expanded(
          child: isThreeDay
              ? ScheduleThreeDayView(
                  anchorDay: selectedDay,
                  use24Hour: use24Hour,
                  locale: locale,
                )
              : ListView(
                  padding: const EdgeInsets.all(ColonySpacing.lg),
                  children: [
                    ColonyPanel(
                      title: AppStrings.scheduleTimeline,
                      icon: Icons.view_timeline_outlined,
                      child: ScheduleDayTimeline(
                        day: selectedDay,
                        use24Hour: use24Hour,
                        locale: locale,
                      ),
                    ),
                    const SizedBox(height: ColonySpacing.lg),
                    ScheduleConflictPanel(
                      day: selectedDay,
                      use24Hour: use24Hour,
                      locale: locale,
                    ),
                    if (ref.watch(scheduleConflictsProvider(selectedDay)).maybeWhen(
                          data: (conflicts) => conflicts.isNotEmpty,
                          orElse: () => false,
                        ))
                      const SizedBox(height: ColonySpacing.lg),
                    ColonyPanel(
                      title: AppStrings.scheduleBlocks,
                      icon: Icons.view_timeline_outlined,
                      child: blocks.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => Text(AppStrings.errorGeneric),
                        data: (items) {
                          if (items.isEmpty) {
                            return Text(AppStrings.noScheduleBlocks);
                          }
                          return Column(
                            children: items
                                .map(
                                  (block) => _ScheduleBlockTile(
                                    block,
                                    timeFormat,
                                    selectedDay,
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: ColonySpacing.lg),
                    ColonyPanel(
                      title: AppStrings.scheduledTasks,
                      icon: Icons.task_outlined,
                      child: tasks.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => Text(AppStrings.errorGeneric),
                        data: (items) {
                          if (items.isEmpty) {
                            return Text(AppStrings.noScheduledTasks);
                          }
                          return Column(
                            children: items
                                .map((task) => _ScheduledTaskTile(task, timeFormat))
                                .toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  String _threeDayRangeLabel(DateTime anchor, String locale) {
    final days = scheduleThreeDayRange(anchor);
    if (days.length < 2) {
      return AppLocale.date('EEE, d MMM', locale).format(anchor);
    }
    final start = AppLocale.date('d MMM', locale).format(days.first);
    final end = AppLocale.date('d MMM', locale).format(days.last);
    return '$start – $end';
  }
}

class _ScheduleBlockTile extends StatelessWidget {
  const _ScheduleBlockTile(this.block, this.timeFormat, this.day);

  final ScheduleBlock block;
  final DateFormat timeFormat;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule, size: 20),
      title: Text(AppStrings.scheduleBlockModeLabel(block.mode)),
      subtitle: Text(
        '${timeFormat.format(block.startAt.toLocal())} – ${timeFormat.format(block.endAt.toLocal())}',
      ),
      dense: true,
      onTap: () => ScheduleBlockSheet.showEdit(context, block: block, day: day),
    );
  }
}

class _ScheduledTaskTile extends StatelessWidget {
  const _ScheduledTaskTile(this.task, this.timeFormat);

  final ColonyTask task;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final time = task.scheduledStart != null
        ? timeFormat.format(task.scheduledStart!.toLocal())
        : '—';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.check_circle_outline, size: 20),
      title: Text(task.title),
      subtitle: Text(time),
      dense: true,
    );
  }
}
