import 'dart:math' as math;

import 'package:fallhub/features/habitat/flame/components/pawn_job_controller.dart';
import 'package:fallhub/features/habitat/flame/habitat_bubbles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bubble phrase pools are non-empty for all job kinds', () {
    final rng = math.Random(1);
    for (final job in HabitatJobKind.values) {
      expect(HabitatBubbleLines.forJobArrived(job, rng), isNotEmpty);
    }
    expect(HabitatBubbleLines.forTap(rng), isNotEmpty);
    expect(HabitatBubbleLines.forIdle(rng), isNotEmpty);
  });
}
