import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_locale.dart';
import '../../../../app/localization/app_strings.dart';
import '../../application/work_providers.dart';
import 'schedule_block_sheet.dart';

class ScheduleDayTimeline extends ConsumerWidget {
  const ScheduleDayTimeline({
    super.key,
    required this.day,
    required this.use24Hour,
    required this.locale,
    this.compact = false,
  });

  final DateTime day;
  final bool use24Hour;
  final String locale;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(scheduleTimelineItemsProvider(day));
    final conflictsAsync = ref.watch(scheduleConflictsProvider(day));

    return itemsAsync.when(
      loading: () => SizedBox(
        height: compact ? 120 : 200,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Text(AppStrings.errorGeneric),
      data: (items) {
        final conflictIds = conflictsAsync.maybeWhen(
          data: scheduleConflictItemIds,
          orElse: () => <String>{},
        );

        if (items.isEmpty) {
          return Text(AppStrings.noScheduleBlocks);
        }

        final timeFormat = AppLocale.time(use24Hour: use24Hour, locale: locale);

        return DayTimeline(
          day: day,
          hourHeight: compact ? 24 : 48,
          minEntryHeight: compact ? 14 : 20,
          timeLabelBuilder: (hour) => timeFormat.format(
            DateTime(day.year, day.month, day.day, hour),
          ),
          entries: [
            for (final item in items)
              DayTimelineEntry(
                id: item.id,
                startAt: item.startAt,
                endAt: item.endAt,
                label: item.label,
                color: _colorForItem(item),
                hasConflict: conflictIds.contains(item.id),
                onTap: item.block != null
                    ? () => ScheduleBlockSheet.showEdit(
                          context,
                          block: item.block!,
                          day: day,
                        )
                    : null,
              ),
          ],
        );
      },
    );
  }

  Color _colorForItem(ScheduleTimelineItem item) {
    if (item.block != null) {
      return switch (item.block!.mode) {
        ScheduleBlockMode.sleep => ColonyColors.accentViolet,
        ScheduleBlockMode.focus => ColonyColors.accentCyan,
        ScheduleBlockMode.meeting => ColonyColors.accentOrange,
        ScheduleBlockMode.exercise => ColonyColors.accentMoss,
        ScheduleBlockMode.unavailable => ColonyColors.statusUnknown,
        _ => ColonyColors.accentSand,
      };
    }
    return ColonyColors.statusInfo;
  }
}
