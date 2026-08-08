import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('selectableForSchedule keeps valid ranges only', () {
    final start = DateTime.utc(2026, 8, 7, 14);
    final valid = IcsEventPreview(
      uid: 'a',
      summary: 'Standup',
      startAt: start,
      endAt: start.add(const Duration(minutes: 30)),
    );
    final invalid = IcsEventPreview(
      uid: 'b',
      summary: 'Bad',
      startAt: start,
      endAt: start,
    );
    final selected = IcsSchedulePolicy.selectableForSchedule([valid, invalid]);
    expect(selected, [valid]);
    expect(IcsSchedulePolicy.defaultMode, ScheduleBlockMode.meeting);
  });
}
