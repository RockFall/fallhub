import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final homeMaintenanceTasksProvider =
    StreamProvider<List<HomeMaintenanceTask>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref
      .watch(repositoriesProvider)
      .homeMaintenance
      .watchAll(profile.id);
});
