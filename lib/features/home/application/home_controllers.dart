import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'home_providers.dart';

class HomeController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<HomeMaintenanceTask?> create({
    required String title,
    required String systemOrItem,
    int? cadenceDays,
    DateTime? nextDueAt,
    String? vendorLabel,
    int? estimatedCostMinor,
    String? currency,
    String? notes,
  }) async {
    state = const AsyncLoading();
    HomeMaintenanceTask? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).homeMaintenance.create(
            profileId: profile.id,
            title: title,
            systemOrItem: systemOrItem,
            cadenceDays: cadenceDays,
            nextDueAt: nextDueAt,
            vendorLabel: vendorLabel,
            estimatedCostMinor: estimatedCostMinor,
            currency: currency,
            notes: notes,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(homeMaintenanceTasksProvider);
    return created;
  }

  Future<HomeMaintenanceTask?> save(HomeMaintenanceTask task) async {
    state = const AsyncLoading();
    HomeMaintenanceTask? updated;
    state = await AsyncValue.guard(() async {
      updated = await ref.read(repositoriesProvider).homeMaintenance.save(task);
    });
    if (state.hasError) return null;
    ref.invalidate(homeMaintenanceTasksProvider);
    return updated;
  }

  Future<HomeMaintenanceTask?> markDone(HomeMaintenanceTask task) async {
    state = const AsyncLoading();
    HomeMaintenanceTask? updated;
    state = await AsyncValue.guard(() async {
      updated =
          await ref.read(repositoriesProvider).homeMaintenance.markDone(task);
    });
    if (state.hasError) return null;
    ref.invalidate(homeMaintenanceTasksProvider);
    return updated;
  }

  Future<HomeMaintenanceTask?> archive(HomeMaintenanceTask task) async {
    state = const AsyncLoading();
    HomeMaintenanceTask? archived;
    state = await AsyncValue.guard(() async {
      archived =
          await ref.read(repositoriesProvider).homeMaintenance.archive(task);
    });
    if (state.hasError) return null;
    ref.invalidate(homeMaintenanceTasksProvider);
    return archived;
  }
}

final homeControllerProvider =
    AsyncNotifierProvider<HomeController, void>(HomeController.new);
