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
    blocks.add(
      ColonyAgendaBlock(
        id: item.id,
        title: title,
        timeLabel: AppStrings.homeTimeRange(item.startAt, item.endAt),
        start: item.startAt,
        end: item.endAt,
        color: style.$1,
        iconName: style.$2,
        warning: conflictIds.contains(item.id),
        onTap: onOpenSchedule,
      ),
    );
  }

  blocks.sort((a, b) => a.start.compareTo(b.start));
  return _fillTrailingLivre(day, blocks, onOpenSchedule);
}

/// Midday holes stay empty (NOW marker breathes). Evening free time is a
/// visual "Livre" block, matching the home terminal reference.
List<ColonyAgendaBlock> _fillTrailingLivre(
  DateTime day,
  List<ColonyAgendaBlock> occupied,
  VoidCallback? onTap,
) {
  if (occupied.isEmpty) return occupied;
  final startDay = DateTime(day.year, day.month, day.day);
  final endDay = startDay.add(const Duration(days: 1));
  var lastEnd = startDay;
  for (final b in occupied) {
    final end = b.end.isAfter(endDay) ? endDay : b.end;
    if (end.isAfter(lastEnd)) lastEnd = end;
  }
  if (endDay.difference(lastEnd) < const Duration(minutes: 45)) {
    return occupied;
  }
  return [
    ...occupied,
    ColonyAgendaBlock(
      id: 'livre-end',
      title: AppStrings.homeLivre,
      timeLabel: AppStrings.homeTimeRange(lastEnd, endDay),
      start: lastEnd,
      end: endDay,
      color: ColonyAgendaColors.free,
      iconName: 'star',
      onTap: onTap,
      visualOnly: true,
    ),
  ];
}
