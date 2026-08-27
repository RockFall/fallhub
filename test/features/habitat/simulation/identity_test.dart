import 'package:fallhub/features/habitat/simulation/identity/identity.dart';
import 'package:fallhub/features/habitat/simulation/mirror/mirror.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('InterestTaxonomy hierarchy', () {
    final jazz = InterestPath.parse('music/jazz/bebop');
    expect(jazz.isUnder(InterestPath.parse('music')), isTrue);
    expect(InterestTaxonomy.childrenOf('music').length, greaterThan(2));
  });

  test('PreferenceStore declared beats simulated', () {
    final store = PreferenceStore();
    store.put(
      'p',
      PreferenceReading(
        path: InterestPath.parse('music/jazz'),
        affinity: 0.4,
        source: MirrorSignalSource.simulated,
      ),
    );
    store.put(
      'p',
      PreferenceReading(
        path: InterestPath.parse('music/jazz'),
        affinity: 0.95,
        source: MirrorSignalSource.userDeclared,
      ),
    );
    expect(store.effectiveAffinity('p', 'music/jazz'), 0.95);
  });

  test('BehaviorProfile seed stable', () {
    final a = BehaviorProfile.fromSeed('colonist');
    final b = BehaviorProfile.fromSeed('colonist');
    expect(a.extraversion, b.extraversion);
    expect(a.socialStyle, b.socialStyle);
  });

  test('Novelty rises after time', () {
    final n = NoveltyTracker();
    n.markUsed('p', 'listenMusic', 0);
    expect(n.novelty('p', 'listenMusic', 100), lessThan(0.2));
    expect(n.novelty('p', 'listenMusic', 8 * 3600), greaterThan(0.9));
  });
}
