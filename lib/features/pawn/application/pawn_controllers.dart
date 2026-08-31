import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'pawn_providers.dart';

class CheckInController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    required double mood,
    required double energy,
    required double tension,
    required double focus,
    String? note,
    List<String> selectedFactors = const [],
    Map<String, double> needReadings = const {},
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repos = ref.read(repositoriesProvider);
      final profile = await repos.profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');

      await repos.needs.seedDefaults(profile.id);

      final factors = selectedFactors
          .map(
            (label) =>
                (label: label, impact: _impactFor(label), uncertain: false),
          )
          .toList();

      await repos.checkIns.save(
        profileId: profile.id,
        mood: mood.clamp(0, 1),
        energy: energy.clamp(0, 1),
        tension: tension.clamp(0, 1),
        focus: focus.clamp(0, 1),
        note: note,
        factors: factors,
      );

      if (needReadings.isNotEmpty) {
        final defs = await repos.needs.listEnabled(profile.id);
        final bySlug = {for (final def in defs) def.slug: def};
        for (final entry in needReadings.entries) {
          final def = bySlug[entry.key];
          if (def == null) continue;
          await repos.needs.recordReading(
            needId: def.id,
            normalizedValue: entry.value.clamp(0, 1),
          );
        }
      }
    });
    ref.invalidate(latestCheckInProvider);
    ref.invalidate(needSnapshotsProvider);
  }

  /// Quick mood from the inspect humor rail/slider. Copies energy, tension,
  /// focus and factors from the latest check-in so they are not wiped.
  Future<void> recordMood(double mood) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repos = ref.read(repositoriesProvider);
      final profile = await repos.profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');

      final latest = await repos.checkIns.getLatest(profile.id);
      var factors = const <({String label, int? impact, bool uncertain})>[];
      if (latest != null) {
        final existing = await repos.checkIns.getFactors(latest.id);
        factors = [
          for (final factor in existing)
            (
              label: factor.label,
              impact: factor.impact,
              uncertain: factor.uncertain,
            ),
        ];
      }

      await repos.checkIns.save(
        profileId: profile.id,
        mood: mood.clamp(0, 1),
        energy: latest?.energy ?? 0.5,
        tension: latest?.tension ?? 0.5,
        focus: latest?.focus ?? 0.5,
        factors: factors,
      );
    });
    ref.invalidate(latestCheckInProvider);
  }

  int? _impactFor(String label) {
    if (label.contains('Sono curto') || label.contains('Preocupação'))
      return -8;
    if (label.contains('Descanso') ||
        label.contains('Interação') ||
        label.contains('Avanço') ||
        label.contains('Caminhada') ||
        label.contains('Música')) {
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
      await ref
          .read(repositoriesProvider)
          .needs
          .recordReading(
            needId: needId,
            normalizedValue: normalizeScale5(scaleValue),
            note: note,
          );
    });
    ref.invalidate(needSnapshotsProvider);
  }
}

final needReadingControllerProvider =
    AsyncNotifierProvider<NeedReadingController, void>(
      NeedReadingController.new,
    );

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
    AsyncNotifierProvider<DailyReviewController, void>(
      DailyReviewController.new,
    );

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
    AsyncNotifierProvider<WeeklyReviewController, void>(
      WeeklyReviewController.new,
    );

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
    AsyncNotifierProvider<PawnBootstrapController, void>(
      PawnBootstrapController.new,
    );
