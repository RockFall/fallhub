import 'package:fallhub/features/habitat/flame/components/living_pawn_component.dart';
import 'package:fallhub/features/habitat/flame/habitat_bubbles.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePawn extends Fake implements LivingPawnComponent {
  _FakePawn(this.memberId);
  @override
  final String memberId;
}

void main() {
  group('Habbo bubble stack', () {
    test('new bubble sits at slot 0 and older rows rise', () {
      final pawn = _FakePawn('a');
      final bubbles = <HabitatBubble>[];

      pushStackedBubble(bubbles, pawn, 'Oi');
      expect(bubbles, hasLength(1));
      expect(bubbles.single.stackSlot, 0);

      pushStackedBubble(bubbles, pawn, 'Tudo bem?');
      expect(bubbles, hasLength(2));
      expect(bubbles.where((b) => b.text == 'Tudo bem?').single.stackSlot, 0);
      expect(bubbles.where((b) => b.text == 'Oi').single.stackSlot, 1);

      pushStackedBubble(bubbles, pawn, 'Pois é.');
      expect(bubbles.where((b) => b.text == 'Pois é.').single.stackSlot, 0);
      expect(
        bubbles.where((b) => b.text == 'Tudo bem?').single.stackSlot,
        1,
      );
      expect(bubbles.where((b) => b.text == 'Oi').single.stackSlot, 2);
    });

    test('stack caps at maxStackPerGroup', () {
      final pawn = _FakePawn('a');
      final bubbles = <HabitatBubble>[];
      final n = BubbleLayerComponent.maxStackPerGroup;
      for (var i = 0; i < n + 3; i++) {
        pushStackedBubble(bubbles, pawn, 'linha $i');
      }
      expect(bubbles.length, n);
      expect(
        bubbles.every((b) => b.stackSlot < n),
        isTrue,
      );
      expect(
        bubbles.where((b) => b.stackSlot == 0).single.text,
        'linha ${n + 2}',
      );
    });

    test('two pawns keep independent stacks by default', () {
      final a = _FakePawn('a');
      final b = _FakePawn('b');
      final bubbles = <HabitatBubble>[];
      pushStackedBubble(bubbles, a, 'A1');
      pushStackedBubble(bubbles, b, 'B1');
      pushStackedBubble(bubbles, a, 'A2');
      expect(bubbles.where((x) => identical(x.pawn, a)).length, 2);
      expect(bubbles.where((x) => identical(x.pawn, b)).length, 1);
      expect(bubbles.where((x) => x.text == 'A1').single.stackSlot, 1);
      expect(bubbles.where((x) => x.text == 'B1').single.stackSlot, 0);
    });

    test('shared social group stacks both speakers in one column', () {
      final a = _FakePawn('a');
      final b = _FakePawn('b');
      final group = socialBubbleStackId('a', 'b');
      final bubbles = <HabitatBubble>[];

      pushStackedBubble(bubbles, a, 'Oi', stackGroupId: group);
      pushStackedBubble(bubbles, b, 'E aí', stackGroupId: group);
      pushStackedBubble(bubbles, a, 'Tudo bem?', stackGroupId: group);

      expect(bubbles, hasLength(3));
      expect(bubbles.every((x) => x.stackGroupId == group), isTrue);
      expect(bubbles.where((x) => x.text == 'Tudo bem?').single.stackSlot, 0);
      expect(bubbles.where((x) => x.text == 'E aí').single.stackSlot, 1);
      expect(bubbles.where((x) => x.text == 'Oi').single.stackSlot, 2);
    });
  });
}
