import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'features/finance/application/piggy_bank_sync.dart';
import 'features/finance/application/piggy_widget_sink.dart';

/// Background entrypoint started by the Android notification worker.
/// Reuses [FinanceNotificationExtractor] via the existing ingest pipeline.
@pragma('vm:entry-point')
Future<void> piggyBankHeadless() async {
  WidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('colony/piggy_headless');
  channel.setMethodCallHandler((call) async {
    if (call.method != 'run') return null;
    final payloads = <NotificationCapturePayload>[];
    final arguments = call.arguments;
    if (arguments is Map) {
      final raw = arguments['payloads'];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            payloads.add(
              NotificationCapturePayload.fromJson(
                Map<Object?, Object?>.from(item),
              ),
            );
          }
        }
      }
    }
    final database = await ColonyDatabase.open();
    try {
      final sink = const HomeWidgetPiggySink();
      final previous = await sink.readStatus();
      final repos = ColonyRepositories.create(database);
      final evaluation = await PiggyClosedAppSync(
        repositories: repos,
        sink: sink,
        now: DateTime.now,
      ).applyPayloads(payloads);
      if (evaluation == null) return {'ok': false};
      final payload = PiggyWidgetPayload.fromSnapshot(
        evaluation.snapshot,
        alertWhenRed: evaluation.config.alertWhenRed,
      );
      return payload.toChannelMap(
        crossedIntoRed: PiggyPublishPolicy.shouldAlert(
          alertWhenRed: evaluation.config.alertWhenRed,
          status: evaluation.snapshot.status,
          previousStatus: previous,
        ),
      );
    } finally {
      await database.close();
    }
  });
  await channel.invokeMethod<void>('ready');
}
