import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('TaskTransitionPolicy allows inbox to next', () {
    expect(
      TaskTransitionPolicy.canTransition(TaskStatus.inbox, TaskStatus.next),
      isTrue,
    );
  });

  test('TaskTransitionPolicy blocks invalid transition', () {
    expect(
      TaskTransitionPolicy.canTransition(TaskStatus.done, TaskStatus.inbox),
      isFalse,
    );
  });
}
