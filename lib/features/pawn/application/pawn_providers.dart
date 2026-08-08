import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final needSnapshotsProvider = StreamProvider<List<NeedSnapshot>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).needs.watchSnapshots(profile.id);
});

final latestCheckInProvider = StreamProvider<CheckIn?>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield null;
    return;
  }
  yield* ref.watch(repositoriesProvider).checkIns.watchLatest(profile.id);
});

final todayDailyReviewProvider = FutureProvider<DailyReview?>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return null;
  return ref
      .watch(repositoriesProvider)
      .dailyReviews
      .getForDate(profile.id, DateTime.now().toUtc());
});

final currentWeekWeeklyReviewProvider = FutureProvider<WeeklyReview?>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return null;
  final prefs = await ref.watch(preferencesProvider.future);
  final weekStart = weekStartDateFor(
    DateTime.now().toUtc(),
    weekStartsOnMonday: prefs.weekStartsOnMonday,
  );
  return ref
      .watch(repositoriesProvider)
      .weeklyReviews
      .getForWeek(profile.id, weekStart);
});
