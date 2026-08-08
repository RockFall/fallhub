import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'pawn_providers.dart';

class CheckInController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    required int mood,
    required int energy,
    required int tension,
    required int focus,
    String? note,
    List<String> selectedFactors = const [],
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repos = ref.read(repositoriesProvider);
      final profile = await repos.profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');

      await repos.needs.seedDefaults(profile.id);

      final factors = selectedFactors
          .map(
            (label) => (
              label: label,
              impact: _impactFor(label),
              uncertain: false,
            ),
          )
          .toList();

      await repos.checkIns.save(
        profileId: profile.id,
        mood: normalizeScale5(mood),
        energy: normalizeScale5(energy),
        tension: normalizeScale5(tension),
        focus: normalizeScale5(focus),
        note: note,
        factors: factors,
      );
    });
    ref.invalidate(latestCheckInProvider);
    ref.invalidate(needSnapshotsProvider);
  }

  int? _impactFor(String label) {
    if (label.contains('Sono curto') || label.contains('Preocupação')) return -8;
    if (label.contains('Descanso') ||
        label.contains('Interação') ||
        label.contains('Avanço')) {
      return 4;
    }
    return null;
  }
}

final checkInControllerProvider =
    AsyncNotifierProvider<CheckInController, void>(CheckInController.new);

class NeedReadingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> record({
    required EntityId needId,
    required int scaleValue,
    String? note,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).needs.recordReading(
            needId: needId,
            normalizedValue: normalizeScale5(scaleValue),
            note: note,
          );
    });
    ref.invalidate(needSnapshotsProvider);
  }
}

final needReadingControllerProvider =
    AsyncNotifierProvider<NeedReadingController, void>(NeedReadingController.new);

class DailyReviewController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    String? whatHappened,
    String? currentState,
    String? tomorrowCommitments,
    String? routeCorrection,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repos = ref.read(repositoriesProvider);
      final profile = await repos.profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');

      await repos.dailyReviews.save(
        profileId: profile.id,
        reviewDate: DateTime.now().toUtc(),
        whatHappened: whatHappened,
        currentState: currentState,
        tomorrowCommitments: tomorrowCommitments,
        routeCorrection: routeCorrection,
      );
    });
    ref.invalidate(todayDailyReviewProvider);
  }
}

final dailyReviewControllerProvider =
    AsyncNotifierProvider<DailyReviewController, void>(DailyReviewController.new);

class WeeklyReviewController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    String? facts,
    String? wins,
    String? problems,
    String? projects,
    String? learning,
    String? nextWeek,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repos = ref.read(repositoriesProvider);
      final profile = await repos.profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');

      final prefs = await repos.preferences.get();
      final weekStart = weekStartDateFor(
        DateTime.now().toUtc(),
        weekStartsOnMonday: prefs.weekStartsOnMonday,
      );

      await repos.weeklyReviews.save(
        profileId: profile.id,
        weekStartDate: weekStart,
        facts: facts,
        wins: wins,
        problems: problems,
        projects: projects,
        learning: learning,
        nextWeek: nextWeek,
      );
    });
    ref.invalidate(currentWeekWeeklyReviewProvider);
  }
}

final weeklyReviewControllerProvider =
    AsyncNotifierProvider<WeeklyReviewController, void>(WeeklyReviewController.new);

class PawnBootstrapController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> ensureSeeded() async {
    final profile = await ref.read(repositoriesProvider).profiles.getActive();
    if (profile == null) return;
    await ref.read(repositoriesProvider).needs.seedDefaults(profile.id);
    ref.invalidate(needSnapshotsProvider);
  }
}

final pawnBootstrapProvider =
    AsyncNotifierProvider<PawnBootstrapController, void>(PawnBootstrapController.new);
