import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'health_providers.dart';

class HealthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<HealthCondition?> create({
    required String title,
    required HealthConditionType type,
    int? severityUserReported,
    String? notes,
    String? bodyRegion,
  }) async {
    state = const AsyncLoading();
    HealthCondition? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).health.create(
            profileId: profile.id,
            title: title,
            type: type,
            severityUserReported: severityUserReported,
            bodyRegions: bodyRegion == null || bodyRegion.trim().isEmpty
                ? const []
                : [bodyRegion.trim()],
            notes: notes,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(healthConditionsProvider);
    return created;
  }

  Future<HealthCondition?> saveCondition(HealthCondition condition) async {
    state = const AsyncLoading();
    HealthCondition? updated;
    state = await AsyncValue.guard(() async {
      updated = await ref.read(repositoriesProvider).health.save(condition);
    });
    if (state.hasError) return null;
    ref.invalidate(healthConditionsProvider);
    return updated;
  }

  Future<HealthCondition?> archive(HealthCondition condition) async {
    state = const AsyncLoading();
    HealthCondition? archived;
    state = await AsyncValue.guard(() async {
      archived = await ref.read(repositoriesProvider).health.archive(condition);
    });
    if (state.hasError) return null;
    ref.invalidate(healthConditionsProvider);
    return archived;
  }

  Future<HealthAppointment?> createAppointment({
    required String title,
    required DateTime scheduledAt,
    String? locationLabel,
    String? clinicianLabel,
    String? notes,
  }) async {
    state = const AsyncLoading();
    HealthAppointment? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).health.createAppointment(
            profileId: profile.id,
            title: title,
            scheduledAt: scheduledAt,
            locationLabel: locationLabel,
            clinicianLabel: clinicianLabel,
            notes: notes,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(healthAppointmentsProvider);
    return created;
  }

  Future<HealthAppointment?> saveAppointment(
    HealthAppointment appointment,
  ) async {
    state = const AsyncLoading();
    HealthAppointment? updated;
    state = await AsyncValue.guard(() async {
      updated = await ref
          .read(repositoriesProvider)
          .health
          .saveAppointment(appointment);
    });
    if (state.hasError) return null;
    ref.invalidate(healthAppointmentsProvider);
    return updated;
  }

  Future<HealthAppointment?> markAppointmentDone(
    HealthAppointment appointment,
  ) async {
    state = const AsyncLoading();
    HealthAppointment? updated;
    state = await AsyncValue.guard(() async {
      updated = await ref.read(repositoriesProvider).health.saveAppointment(
            appointment.copyWith(status: HealthAppointmentStatus.done),
          );
    });
    if (state.hasError) return null;
    ref.invalidate(healthAppointmentsProvider);
    return updated;
  }

  Future<HealthAppointment?> markAppointmentCancelled(
    HealthAppointment appointment,
  ) async {
    state = const AsyncLoading();
    HealthAppointment? updated;
    state = await AsyncValue.guard(() async {
      updated = await ref.read(repositoriesProvider).health.saveAppointment(
            appointment.copyWith(status: HealthAppointmentStatus.cancelled),
          );
    });
    if (state.hasError) return null;
    ref.invalidate(healthAppointmentsProvider);
    return updated;
  }

  Future<SymptomEntry?> logSymptom({
    required EntityId conditionId,
    required int intensity,
    String? note,
    String? bodyRegion,
  }) async {
    state = const AsyncLoading();
    SymptomEntry? entry;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      entry = await ref.read(repositoriesProvider).health.logSymptomEntry(
            profileId: profile.id,
            conditionId: conditionId,
            intensity: intensity,
            note: note,
            bodyRegion: bodyRegion,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(symptomEntriesForConditionProvider(conditionId.value));
    return entry;
  }
}

final healthControllerProvider =
    AsyncNotifierProvider<HealthController, void>(HealthController.new);
