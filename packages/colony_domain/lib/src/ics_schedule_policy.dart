import 'integration.dart';
import 'work_enums.dart';

/// Maps ICS previews to local schedule blocks (ADR-032 polish).
/// Opt-in only; never writes to the OS calendar.
abstract final class IcsSchedulePolicy {
  /// Default mode for imported events — meeting is the closest local analog.
  static const ScheduleBlockMode defaultMode = ScheduleBlockMode.meeting;

  /// Returns previews that have a valid half-open time range for ScheduleBlock.
  static List<IcsEventPreview> selectableForSchedule(
    List<IcsEventPreview> previews,
  ) {
    return previews
        .where((p) => p.endAt.isAfter(p.startAt))
        .toList(growable: false);
  }
}
