import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final googleTimelineImportProvider =
    StreamProvider<GoogleTimelineImport?>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield null;
    return;
  }
  yield* ref.watch(repositoriesProvider).googleTimeline.watchImport(profile.id);
});

final timelinePlaceLabelsProvider =
    StreamProvider<List<TimelinePlaceLabel>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield const [];
    return;
  }
  yield* ref.watch(repositoriesProvider).googleTimeline.watchLabels(profile.id);
});

final timelineInsightsProvider = Provider<TimelineInsights?>((ref) {
  final import = ref.watch(googleTimelineImportProvider).asData?.value;
  if (import == null) return null;
  final labels = {
    for (final label in ref.watch(timelinePlaceLabelsProvider).asData?.value ??
        const <TimelinePlaceLabel>[])
      label.placeId: label,
  };
  return GoogleTimelineAnalytics.analyze(import.document, labels: labels);
});

class TimelineSelectedDay extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void select(DateTime day) => state = day;
}

final timelineSelectedDayProvider =
    NotifierProvider<TimelineSelectedDay, DateTime?>(TimelineSelectedDay.new);
