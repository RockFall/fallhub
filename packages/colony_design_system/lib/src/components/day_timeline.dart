import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

/// A single entry positioned on a vertical 24-hour day timeline.
class DayTimelineEntry {
  const DayTimelineEntry({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.label,
    this.color = ColonyColors.accentCyan,
    this.hasConflict = false,
    this.onTap,
  });

  final String id;
  final DateTime startAt;
  final DateTime endAt;
  final String label;
  final Color color;
  final bool hasConflict;
  final VoidCallback? onTap;
}

/// Vertical 24-hour timeline for a single calendar day (mobile-first).
class DayTimeline extends StatelessWidget {
  const DayTimeline({
    super.key,
    required this.day,
    required this.entries,
    this.hourHeight = 48,
    this.minEntryHeight = 20,
    this.timeLabelBuilder,
  });

  final DateTime day;
  final List<DayTimelineEntry> entries;
  final double hourHeight;
  final double minEntryHeight;
  final String Function(int hour)? timeLabelBuilder;

  static const _totalHours = 24;

  double get _timelineHeight => hourHeight * _totalHours;

  @override
  Widget build(BuildContext context) {
    final labelForHour = timeLabelBuilder ?? _defaultHourLabel;

    return SizedBox(
      height: _timelineHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Stack(
              children: [
                for (var hour = 0; hour < _totalHours; hour++)
                  Positioned(
                    top: hour * hourHeight - 8,
                    left: 0,
                    right: 0,
                    child: Text(
                      labelForHour(hour),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ColonyColors.textMuted,
                          ),
                      textAlign: TextAlign.right,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: ColonySpacing.sm),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var hour = 0; hour <= _totalHours; hour++)
                  Positioned(
                    top: hour * hourHeight,
                    left: 0,
                    right: 0,
                    child: const Divider(
                      height: 1,
                      thickness: 1,
                      color: ColonyColors.borderSubtle,
                    ),
                  ),
                for (final entry in entries) _TimelineEntryTile(
                  entry: entry,
                  day: day,
                  hourHeight: hourHeight,
                  minEntryHeight: minEntryHeight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _defaultHourLabel(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }
}

class _TimelineEntryTile extends StatelessWidget {
  const _TimelineEntryTile({
    required this.entry,
    required this.day,
    required this.hourHeight,
    required this.minEntryHeight,
  });

  final DayTimelineEntry entry;
  final DateTime day;
  final double hourHeight;
  final double minEntryHeight;

  double _minutesFromDayStart(DateTime instant) {
    final local = instant.toLocal();
    return (local.hour * 60 + local.minute).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final startMinutes = _minutesFromDayStart(entry.startAt);
    final endMinutes = _minutesFromDayStart(entry.endAt);
    final durationMinutes = (endMinutes - startMinutes).clamp(1, 24 * 60);

    final top = (startMinutes / 60) * hourHeight;
    final height = ((durationMinutes / 60) * hourHeight).clamp(
      minEntryHeight,
      DayTimeline._totalHours * hourHeight - top,
    );

    final body = GestureDetector(
      onTap: entry.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: entry.color.withValues(alpha: 0.35),
          border: Border.all(
            color: entry.hasConflict
                ? ColonyColors.statusCritical
                : entry.color,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: ColonySpacing.sm,
          vertical: ColonySpacing.xs,
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          entry.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: ColonyColors.textPrimary,
              ),
        ),
      ),
    );

    return Positioned(
      top: top,
      left: entry.hasConflict ? 6 : 0,
      right: 0,
      height: height,
      child: entry.hasConflict
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: ColonyColors.statusCritical,
                ),
                const SizedBox(width: ColonySpacing.xs),
                Expanded(child: body),
              ],
            )
          : body,
    );
  }
}
