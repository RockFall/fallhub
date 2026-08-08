import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLifecyclePolicy', () {
    test('allows active to completed', () {
      expect(
        ProjectLifecyclePolicy.canTransition(
          ProjectStatus.active,
          ProjectStatus.completed,
        ),
        isTrue,
      );
    });

    test('allows completed to archived', () {
      expect(
        ProjectLifecyclePolicy.canTransition(
          ProjectStatus.completed,
          ProjectStatus.archived,
        ),
        isTrue,
      );
    });

    test('blocks active to archived', () {
      expect(
        ProjectLifecyclePolicy.canTransition(
          ProjectStatus.active,
          ProjectStatus.archived,
        ),
        isFalse,
      );
    });

    test('blocks archived to active', () {
      expect(
        ProjectLifecyclePolicy.canTransition(
          ProjectStatus.archived,
          ProjectStatus.active,
        ),
        isFalse,
      );
    });
  });
}
