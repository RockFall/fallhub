import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../pawn/application/pawn_providers.dart';

/// Ephemeral weekly NarrativeDigest from local rules (ADR-033).
final weeklyNarrativeDigestProvider =
    FutureProvider<NarrativeDigest>((ref) async {
  final prefs = await ref.watch(preferencesProvider.future);
  final clock = ref.watch(clockProvider);
  final now = clock();
  final weekStart = weekStartDateFor(
    now,
    weekStartsOnMonday: prefs.weekStartsOnMonday,
  );
  final weekEnd = weekStart.add(const Duration(days: 7));

  final events =
      await ref.watch(repositoriesProvider).events.listTimeline(limit: 5000);
  final weeklyReview = await ref.watch(currentWeekWeeklyReviewProvider.future);

  return NarrativeDigestRules.generate(
    periodStart: weekStart,
    periodEnd: weekEnd,
    events: events,
    weeklyReview: weeklyReview,
    generatedAt: now,
  );
});
