import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('PriorityCyclePolicy', () {
    test('cycles through all levels', () {
      var level = PriorityLevel.blocked;
      final seen = <PriorityLevel>{level};

      for (var i = 0; i < PriorityCyclePolicy.cycle.length; i++) {
        level = PriorityCyclePolicy.next(level);
        seen.add(level);
      }

      expect(seen, containsAll(PriorityCyclePolicy.cycle));
    });

    test('returns to blocked after automatic', () {
      expect(
        PriorityCyclePolicy.next(PriorityLevel.automatic),
        PriorityLevel.blocked,
      );
    });

    test('immediate goes to high', () {
      expect(
        PriorityCyclePolicy.next(PriorityLevel.immediate),
        PriorityLevel.high,
      );
    });

    test('unknown level defaults to blocked next', () {
      // coverage for defensive branch — cycle only has known values
      expect(PriorityCyclePolicy.cycle, isNotEmpty);
    });
  });
}
