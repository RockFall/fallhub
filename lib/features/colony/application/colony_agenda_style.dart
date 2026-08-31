import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';

(Color, String) agendaStyleFor(ScheduleBlockMode mode) {
  return switch (mode) {
    ScheduleBlockMode.sleep => (ColonyAgendaColors.sleep, 'moon'),
    ScheduleBlockMode.focus => (ColonyAgendaColors.focus, 'crosshair'),
    ScheduleBlockMode.meeting => (ColonyAgendaColors.meeting, 'cap'),
    ScheduleBlockMode.recreation => (ColonyAgendaColors.meal, 'utensils'),
    ScheduleBlockMode.free => (ColonyAgendaColors.free, 'star'),
    ScheduleBlockMode.exercise => (ColonyAgendaColors.exercise, 'exercise'),
    ScheduleBlockMode.commute => (ColonyAgendaColors.commute, 'commute'),
    ScheduleBlockMode.social => (ColonyAgendaColors.social, 'handshake'),
    ScheduleBlockMode.recovery => (ColonyAgendaColors.recovery, 'bed'),
    ScheduleBlockMode.routine => (ColonyAgendaColors.routine, 'clock'),
    ScheduleBlockMode.flexible => (ColonyAgendaColors.flexible, 'star'),
    ScheduleBlockMode.unavailable => (ColonyAgendaColors.unavailable, 'close'),
  };
}

List<ColonyAgendaBlock> buildColonyAgendaBlocks({
  required DateTime day,
  required List<ScheduleTimelineItem> items,
  required Set<String> conflictIds,
  VoidCallback? onOpenSchedule,
}) {
  final blocks = <ColonyAgendaBlock>[];
  for (final item in items) {
    final mode =
        item.block?.mode ??
        switch (item.kind) {
          ScheduleTimelineItemKind.task => ScheduleBlockMode.focus,
          ScheduleTimelineItemKind.external => ScheduleBlockMode.meeting,
          ScheduleTimelineItemKind.block => ScheduleBlockMode.flexible,
        };
    final style = agendaStyleFor(mode);
    final title = item.block != null
        ? AppStrings.scheduleBlockShortLabel(mode)
        : item.label;
    final allDay = _isAllDayItem(item, day);
    blocks.add(
      ColonyAgendaBlock(
        id: item.id,
        title: title,
        timeLabel: allDay
            ? AppStrings.homeAllDay
            : AppStrings.homeTimeRange(item.startAt, item.endAt),
        start: item.startAt,
        end: item.endAt,
        color: style.$1,
        iconName: style.$2,
        warning: conflictIds.contains(item.id),
        onTap: onOpenSchedule,
        allDay: allDay,
      ),
    );
  }

  blocks.sort((a, b) => a.start.compareTo(b.start));
  return blocks;
}

bool _isAllDayItem(ScheduleTimelineItem item, DateTime day) {
  final startDay = DateTime(day.year, day.month, day.day);
  final endDay = startDay.add(const Duration(days: 1));
  final start = item.startAt.toLocal();
  final end = item.endAt.toLocal();
  final visibleStart = start.isBefore(startDay) ? startDay : start;
  final visibleEnd = end.isAfter(endDay) ? endDay : end;
  return !visibleEnd.isAfter(visibleStart)
      ? false
      : visibleEnd.difference(visibleStart) >= const Duration(hours: 20);
}
