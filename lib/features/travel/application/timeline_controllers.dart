import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'timeline_providers.dart';

class TimelineController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<GoogleTimelineImport?> replaceImport({
    required String fileName,
    GoogleTimelineDocument? document,
    String? compactJsonPath,
    int visitCount = 0,
    int activityCount = 0,
    int tripCount = 0,
  }) async {
    GoogleTimelineImport? created;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref
          .read(repositoriesProvider)
          .googleTimeline
          .replaceImport(
            profileId: profile.id,
            fileName: fileName,
            document: document,
            compactJsonPath: compactJsonPath,
            visitCount: visitCount,
            activityCount: activityCount,
            tripCount: tripCount,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(googleTimelineImportProvider);
    return created;
  }

  Future<bool> saveLabel(TimelinePlaceLabel label) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      await ref
          .read(repositoriesProvider)
          .googleTimeline
          .upsertLabel(profileId: profile.id, label: label);
    });
    if (state.hasError) return false;
    ref.invalidate(timelinePlaceLabelsProvider);
    return true;
  }
}

final timelineControllerProvider =
    AsyncNotifierProvider<TimelineController, void>(TimelineController.new);
