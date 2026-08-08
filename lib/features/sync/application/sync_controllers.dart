import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'sync_providers.dart';

class SyncController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<int> processLocalNoop() async {
    state = const AsyncLoading();
    var count = 0;
    state = await AsyncValue.guard(() async {
      count = await ref.read(repositoriesProvider).sync.processLocalNoop();
    });
    ref.invalidate(syncPendingProvider);
    ref.invalidate(syncDeviceProvider);
    return state.hasError ? 0 : count;
  }
}

final syncControllerProvider =
    AsyncNotifierProvider<SyncController, void>(SyncController.new);
