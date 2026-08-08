import 'package:fallhub/features/habitat/application/colony_roster.dart';
import 'package:fallhub/features/habitat/flame/habitat_game.dart';
import 'package:fallhub/features/habitat/flame/habitat_tint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seedDefaults yields player + extras under max', () {
    final seed = ColonyRosterStore.seedDefaults();
    expect(seed.length, greaterThanOrEqualTo(2));
    expect(seed.length, lessThanOrEqualTo(ColonyRosterStore.maxMembers));
    expect(seed.where((m) => m.isPlayer).length, 1);
  });

  test('HabitatGame spawns multi-pawn roster with independent cells', () async {
    final roster = ColonyRosterStore.seedDefaults();
    final game = HabitatGame(roster: roster);
    await game.onLoad();
    expect(game.pawns.length, roster.length);
    expect(game.focusedPawn, isNotNull);
    final cells = {
      for (final p in game.pawns) (p.cellX, p.cellY),
    };
    expect(cells.length, game.pawns.length);
    for (final p in game.pawns) {
      expect(game.map.isWalkable(p.cellX, p.cellY), isTrue);
    }

    final other = game.pawns.last;
    game.prioritizePawn(other);
    expect(game.focusedPawn?.memberId, other.memberId);
    expect(other.selected, isTrue);

    game.syncRoster([
      roster.first,
      ColonyMember(
        id: 'solo_friend',
        appearance: PawnAppearance(name: 'Nova', bodyType: 'female'),
      ),
    ]);
    expect(game.pawns.length, 2);
    expect(game.pawnByMemberId('solo_friend'), isNotNull);
    game.dispose();
  });
}
