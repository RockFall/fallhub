import 'dart:math' as math;

import 'package:flutter/material.dart';

class ColonyAgendaBlock {
  const ColonyAgendaBlock({
    required this.id,
    required this.title,
    required this.timeLabel,
    required this.start,
    required this.end,
    required this.color,
    this.iconName,
    this.warning = false,
    this.onTap,
    this.visualOnly = false,
    this.allDay = false,
  });

  final String id;
  final String title;
  final String timeLabel;
  final DateTime start;
  final DateTime end;
  final Color color;
  final String? iconName;
  final bool warning;
  final VoidCallback? onTap;
  final bool visualOnly;
  final bool allDay;
}

/// Vertical padding so hour labels and the first/last cards stay inside the rail.
const kColonyAgendaRailPad = 8.0;

/// Short meetings stay tappable on a tall day scale.
const kColonyAgendaMinBlockHeight = 38.0;

const kColonyAgendaBlockGap = 3.0;

/// Visible duration on [day] at which a block is treated as all-day
/// (birthday, holiday) and kept off the proportional hour scale.
const kColonyAgendaAllDayHours = 20.0;

/// Hour-of-day in local time, clamped to `[0, 24]` for [day].
double colonyAgendaHourOf(DateTime instant, DateTime day) {
  final local = instant.toLocal();
  final dayStart = DateTime(day.year, day.month, day.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  if (local.isBefore(dayStart)) return 0;
  if (!local.isBefore(dayEnd)) return 24;
  return local.hour + local.minute / 60.0 + local.second / 3600.0;
}

bool colonyAgendaBlockIsAllDay(ColonyAgendaBlock block, DateTime day) {
  if (block.visualOnly) return false;
  if (block.allDay) return true;
  final start = colonyAgendaHourOf(block.start, day);
  final end = colonyAgendaHourOf(block.end, day);
  return (end - start) >= kColonyAgendaAllDayHours;
}

/// Hour ticks for the visible window. Always includes the first and last hour.
List<int> colonyAgendaHourTicks(double viewStartHour, double viewEndHour) {
  final start = viewStartHour.round().clamp(0, 24);
  final end = viewEndHour.round().clamp(0, 24);
  if (end <= start) return [start];
  final span = end - start;
  final step = span >= 12
      ? 4
      : span >= 6
      ? 2
      : 1;
  final ticks = <int>{start, end};
  final firstMultiple = ((start + step - 1) ~/ step) * step;
  for (var h = firstMultiple; h < end; h += step) {
    if (h > start) ticks.add(h);
  }
  final list = ticks.toList()..sort();
  return list;
}

class ColonyAgendaPlacement {
  const ColonyAgendaPlacement({
    required this.block,
    required this.top,
    required this.height,
    required this.lane,
    required this.laneCount,
    required this.startHour,
    required this.endHour,
  });

  final ColonyAgendaBlock block;
  final double top;
  final double height;
  final int lane;
  final int laneCount;
  final double startHour;
  final double endHour;
}

class ColonyAgendaRailLayout {
  const ColonyAgendaRailLayout({
    required this.viewStartHour,
    required this.viewEndHour,
    required this.canvasHeight,
    required this.hourTicks,
    required this.timed,
    required this.allDay,
  });

  final double viewStartHour;
  final double viewEndHour;
  final double canvasHeight;
  final List<int> hourTicks;
  final List<ColonyAgendaPlacement> timed;
  final List<ColonyAgendaBlock> allDay;

  double yAt(double hour) {
    final span = (viewEndHour - viewStartHour).clamp(0.001, 24.0);
    final usable = (canvasHeight - 2 * kColonyAgendaRailPad).clamp(
      1.0,
      canvasHeight,
    );
    final t = ((hour - viewStartHour) / span).clamp(0.0, 1.0);
    return kColonyAgendaRailPad + t * usable;
  }
}

/// Maps the day's timed items onto [canvasHeight] using the first and last
/// timed hours (all-day cards are returned separately and do not stretch the
/// scale to 00:00–24:00).
ColonyAgendaRailLayout layoutColonyAgendaRail({
  required List<ColonyAgendaBlock> blocks,
  required DateTime day,
  required double canvasHeight,
  DateTime? now,
}) {
  final allDay = <ColonyAgendaBlock>[];
  final timedBlocks = <ColonyAgendaBlock>[];
  for (final block in blocks) {
    if (block.visualOnly) continue;
    if (colonyAgendaBlockIsAllDay(block, day)) {
      allDay.add(block);
    } else {
      timedBlocks.add(block);
    }
  }

  if (timedBlocks.isEmpty) {
    return ColonyAgendaRailLayout(
      viewStartHour: 8,
      viewEndHour: 20,
      canvasHeight: canvasHeight,
      hourTicks: const [8, 12, 16, 20],
      timed: const [],
      allDay: allDay,
    );
  }

  var minHour = 24.0;
  var maxHour = 0.0;
  final hours = <ColonyAgendaBlock, (double, double)>{};
  for (final block in timedBlocks) {
    final start = colonyAgendaHourOf(block.start, day).clamp(0.0, 24.0);
    final end = colonyAgendaHourOf(block.end, day).clamp(0.0, 24.0);
    if (end <= start) continue;
    hours[block] = (start, end);
    if (start < minHour) minHour = start;
    if (end > maxHour) maxHour = end;
  }

  if (hours.isEmpty) {
    return ColonyAgendaRailLayout(
      viewStartHour: 8,
      viewEndHour: 20,
      canvasHeight: canvasHeight,
      hourTicks: const [8, 12, 16, 20],
      timed: const [],
      allDay: allDay,
    );
  }

  var viewStart = minHour.floorToDouble();
  var viewEnd = maxHour.ceilToDouble();
  if (viewEnd <= viewStart) {
    viewEnd = (viewStart + 1).clamp(0.0, 24.0);
  }

  final nowLocal = now?.toLocal();
  if (nowLocal != null &&
      nowLocal.year == day.year &&
      nowLocal.month == day.month &&
      nowLocal.day == day.day) {
    final nowHour = colonyAgendaHourOf(nowLocal, day);
    if (nowHour < viewStart) viewStart = nowHour.floorToDouble();
    if (nowHour > viewEnd) viewEnd = nowHour.ceilToDouble();
  }

  final layout = ColonyAgendaRailLayout(
    viewStartHour: viewStart,
    viewEndHour: viewEnd,
    canvasHeight: canvasHeight,
    hourTicks: colonyAgendaHourTicks(viewStart, viewEnd),
    timed: const [],
    allDay: allDay,
  );

  final timedItems =
      hours.entries
          .map((e) => (block: e.key, start: e.value.$1, end: e.value.$2))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  final lanes = _assignLanes(timedItems);
  final placed = <ColonyAgendaPlacement>[];
  for (final item in timedItems) {
    final assignment = lanes[item.block]!;
    final top = layout.yAt(item.start);
    final raw = layout.yAt(item.end) - top;
    final height = math
        .min(
          math.max(raw - kColonyAgendaBlockGap, kColonyAgendaMinBlockHeight),
          (canvasHeight - top).clamp(kColonyAgendaMinBlockHeight, canvasHeight),
        )
        .toDouble();
    placed.add(
      ColonyAgendaPlacement(
        block: item.block,
        top: top,
        height: height,
        lane: assignment.lane,
        laneCount: assignment.laneCount,
        startHour: item.start,
        endHour: item.end,
      ),
    );
  }

  return ColonyAgendaRailLayout(
    viewStartHour: viewStart,
    viewEndHour: viewEnd,
    canvasHeight: canvasHeight,
    hourTicks: layout.hourTicks,
    timed: placed,
    allDay: allDay,
  );
}

class _LaneAssignment {
  const _LaneAssignment({required this.lane, required this.laneCount});
  final int lane;
  final int laneCount;
}

bool _overlaps(
  ({ColonyAgendaBlock block, double start, double end}) a,
  ({ColonyAgendaBlock block, double start, double end}) b,
) {
  return a.start < b.end - 0.01 && b.start < a.end - 0.01;
}

Map<ColonyAgendaBlock, _LaneAssignment> _assignLanes(
  List<({ColonyAgendaBlock block, double start, double end})> items,
) {
  final laneEnd = <double>[];
  final laneOf = <ColonyAgendaBlock, int>{};
  for (final item in items) {
    var placed = false;
    for (var i = 0; i < laneEnd.length; i++) {
      if (laneEnd[i] <= item.start + 0.01) {
        laneOf[item.block] = i;
        laneEnd[i] = item.end;
        placed = true;
        break;
      }
    }
    if (!placed) {
      laneOf[item.block] = laneEnd.length;
      laneEnd.add(item.end);
    }
  }

  final parent = List<int>.generate(items.length, (i) => i);
  int find(int i) => parent[i] == i ? i : parent[i] = find(parent[i]);
  void union(int a, int b) {
    final ra = find(a);
    final rb = find(b);
    if (ra != rb) parent[ra] = rb;
  }

  for (var i = 0; i < items.length; i++) {
    for (var j = i + 1; j < items.length; j++) {
      if (_overlaps(items[i], items[j])) union(i, j);
    }
  }

  final clusterMaxLane = <int, int>{};
  for (var i = 0; i < items.length; i++) {
    final root = find(i);
    final lane = laneOf[items[i].block] ?? 0;
    final prev = clusterMaxLane[root] ?? 0;
    if (lane > prev) clusterMaxLane[root] = lane;
  }

  final out = <ColonyAgendaBlock, _LaneAssignment>{};
  for (var i = 0; i < items.length; i++) {
    final root = find(i);
    out[items[i].block] = _LaneAssignment(
      lane: laneOf[items[i].block] ?? 0,
      laneCount: (clusterMaxLane[root] ?? 0) + 1,
    );
  }
  return out;
}
