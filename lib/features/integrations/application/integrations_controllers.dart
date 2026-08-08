import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'integrations_providers.dart';

class IntegrationsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> ensureCalendarConsent() async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return;
    await ref.read(repositoriesProvider).integrations.ensureConsent(
          profileId: profile.id,
          kind: IntegrationKind.calendarIcs,
        );
    ref.invalidate(integrationConsentsProvider);
  }

  Future<void> setCalendarIcsEnabled(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) {
        throw StateError('Perfil não encontrado');
      }
      await ref.read(repositoriesProvider).integrations.setConsentEnabled(
            profileId: profile.id,
            kind: IntegrationKind.calendarIcs,
            enabled: enabled,
          );
    });
    ref.invalidate(integrationConsentsProvider);
  }

  List<IcsEventPreview> previewIcs(String source) {
    return IcsCodec.parsePreview(source);
  }

  Future<int> confirmIcsImport(
    List<IcsEventPreview> previews, {
    bool alsoCreateScheduleBlocks = false,
  }) async {
    var count = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) {
        throw StateError('Perfil não encontrado');
      }
      final repos = ref.read(repositoriesProvider);
      final created = await repos.integrations.importCalendarPreviews(
        profileId: profile.id,
        previews: previews,
      );
      count = created.length;
      if (alsoCreateScheduleBlocks) {
        final selectable = IcsSchedulePolicy.selectableForSchedule(previews);
        for (final preview in selectable) {
          await repos.schedule.create(
            profileId: profile.id,
            startAt: preview.startAt,
            endAt: preview.endAt,
            mode: IcsSchedulePolicy.defaultMode,
            sourceType: SourceType.integration,
          );
        }
      }
    });
    ref.invalidate(externalCalendarEventsProvider);
    ref.invalidate(integrationConsentsProvider);
    return state.hasError ? 0 : count;
  }
}

final integrationsControllerProvider =
    AsyncNotifierProvider<IntegrationsController, void>(
  IntegrationsController.new,
);
