import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../integrations/application/integrations_providers.dart';

final healthConditionsProvider =
    StreamProvider<List<HealthCondition>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).health.watchAll(profile.id);
});

final symptomEntriesForConditionProvider =
    StreamProvider.family<List<SymptomEntry>, String>((ref, conditionId) {
  return ref
      .watch(repositoriesProvider)
      .health
      .watchSymptomEntriesForCondition(EntityId(conditionId));
});

final healthAppointmentsProvider =
    StreamProvider<List<HealthAppointment>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).health.watchAppointments(profile.id);
});

final sleepSessionsProvider =
    StreamProvider<List<SleepSession>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).health.watchSleepSessions(profile.id);
});

final sleepDetectionConsentProvider = Provider<IntegrationConsent?>((ref) {
  final consents = ref.watch(integrationConsentsProvider).asData?.value;
  if (consents == null) return null;
  for (final c in consents) {
    if (c.kind == IntegrationKind.sleepDetection) return c;
  }
  return null;
});

final healthConnectSleepConsentProvider = Provider<IntegrationConsent?>((ref) {
  final consents = ref.watch(integrationConsentsProvider).asData?.value;
  if (consents == null) return null;
  for (final c in consents) {
    if (c.kind == IntegrationKind.healthConnectSleep) return c;
  }
  return null;
});
