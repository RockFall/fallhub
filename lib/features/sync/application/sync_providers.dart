import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final syncPendingProvider = StreamProvider<List<SyncOperation>>((ref) {
  return ref.watch(repositoriesProvider).sync.watchPending();
});

final syncDeviceProvider = FutureProvider<DeviceIdentity>((ref) async {
  return ref.watch(repositoriesProvider).sync.ensureLocalDevice();
});
