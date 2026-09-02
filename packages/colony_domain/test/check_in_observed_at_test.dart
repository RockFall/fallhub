import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('same local day keeps the live clock instant', () {
    final now = DateTime.utc(2026, 8, 31, 14, 20, 8);
    final observed = checkInObservedAt(
      selectedLocalDay: now.toLocal(),
      nowUtc: now,
    );
    expect(observed, now);
  });

  test('another local day keeps the current clock time on that date', () {
    final now = DateTime.utc(2026, 8, 31, 14, 20, 8);
    final nowLocal = now.toLocal();
    final selected = DateTime(nowLocal.year, nowLocal.month, nowLocal.day - 1);
    final observed = checkInObservedAt(
      selectedLocalDay: selected,
      nowUtc: now,
    ).toLocal();

    expect(observed.year, selected.year);
    expect(observed.month, selected.month);
    expect(observed.day, selected.day);
    expect(observed.hour, nowLocal.hour);
    expect(observed.minute, nowLocal.minute);
    expect(observed.second, nowLocal.second);
  });

  test('isSameLocalCalendarDay ignores clock time', () {
    expect(
      isSameLocalCalendarDay(DateTime(2026, 8, 31, 3), DateTime(2026, 8, 31, 22)),
      isTrue,
    );
    expect(
      isSameLocalCalendarDay(DateTime(2026, 8, 30, 12), DateTime(2026, 8, 31, 12)),
      isFalse,
    );
  });
}
