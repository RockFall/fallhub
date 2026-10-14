import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/providers/app_providers.dart';
import 'piggy_bank_query.dart';
import 'piggy_widget_sink.dart';

final piggyWidgetSinkProvider = Provider<PiggyWidgetSink>(
  (ref) => const HomeWidgetPiggySink(),
);

class PiggySnapshotNotifier extends AsyncNotifier<PiggyEvaluation?> {
  @override
  Future<PiggyEvaluation?> build() async {
    final profile = await ref.watch(profileProvider.future);
    if (profile == null) return null;
    final repos = ref.watch(repositoriesProvider);
    var skipTransactions = true;
    var skipConfig = true;
    final transactions = repos.finance.watchTransactions(profile.id).listen((_) {
      if (skipTransactions) {
        skipTransactions = false;
        return;
      }
      ref.invalidateSelf();
    });
    final config = repos.piggy.watchConfig(profile.id).listen((_) {
      if (skipConfig) {
        skipConfig = false;
        return;
      }
      ref.invalidateSelf();
    });
    ref.onDispose(() {
      transactions.cancel();
      config.cancel();
    });
    return PiggyBankQuery.load(repos, profile.id, ref.read(clockProvider)());
  }
}

final piggySnapshotProvider =
    AsyncNotifierProvider<PiggySnapshotNotifier, PiggyEvaluation?>(
  PiggySnapshotNotifier.new,
);

class PiggyBankController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> saveConfig(PiggyBankConfig config) async {
    config.validate();
    final saved = config.copyWith(updatedAt: ref.read(clockProvider)());
    await ref.read(repositoriesProvider).piggy.saveConfig(saved);
    ref.invalidate(piggySnapshotProvider);
  }

  Future<void> updateOverride({
    required EntityId transactionId,
    bool? excluded,
    int? amountOverrideMinor,
    bool clearAmount = false,
  }) async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return;
    final repos = ref.read(repositoriesProvider);
    final existing = (await repos.piggy.listOverrides(profile.id))
        .where((row) => row.transactionId == transactionId)
        .firstOrNull;
    await repos.piggy.saveOverride(
      PiggyBankOverride(
        profileId: profile.id,
        transactionId: transactionId,
        excluded: excluded ?? existing?.excluded ?? false,
        amountOverrideMinor: clearAmount
            ? null
            : (amountOverrideMinor ?? existing?.amountOverrideMinor),
        updatedAt: ref.read(clockProvider)(),
      ),
    );
    ref.invalidate(piggySnapshotProvider);
  }
}

final piggyBankControllerProvider =
    AsyncNotifierProvider<PiggyBankController, void>(PiggyBankController.new);

final piggyDeepLinkRuntimeProvider = Provider<void>((ref) {
  if (kIsWeb) return;
  late final AppLinks links;
  try {
    links = AppLinks();
  } catch (_) {
    return;
  }

  Future<void> handle(Uri uri) async {
    if (uri.scheme != 'colony' || uri.host != 'piggy') return;
    ref.read(routerProvider).go('/resources/piggy');
  }

  try {
    links.getInitialLink().then((uri) {
      if (uri != null) handle(uri);
    }).ignore();
    final sub = links.uriLinkStream.listen(handle);
    ref.onDispose(sub.cancel);
  } catch (_) {
    // Tests and desktop hosts without the plugin stay usable.
  }
});

final piggyWidgetRuntimeProvider = Provider<void>((ref) {
  ref.listen(piggySnapshotProvider, (previous, next) {
    final evaluation = next.asData?.value;
    if (evaluation == null) return;
    unawaited(
      PiggyWidgetPublisher.publish(
        sink: ref.read(piggyWidgetSinkProvider),
        config: evaluation.config,
        snapshot: evaluation.snapshot,
      ),
    );
  });

  Timer? midnight;
  void arm() {
    midnight?.cancel();
    final delay = PiggyBankCalendar.nextMidnightUtc(DateTime.now())
        .difference(DateTime.now().toUtc());
    midnight = Timer(delay.isNegative ? const Duration(seconds: 1) : delay, () {
      ref.invalidate(piggySnapshotProvider);
      arm();
    });
  }

  arm();
  final lifecycle = AppLifecycleListener(
    onResume: () => ref.invalidate(piggySnapshotProvider),
  );
  ref.onDispose(() {
    midnight?.cancel();
    lifecycle.dispose();
  });
});
