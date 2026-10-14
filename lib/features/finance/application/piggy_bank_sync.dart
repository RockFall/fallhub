import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';

import '../../integrations/application/notification_capture_platform.dart';
import 'piggy_bank_query.dart';
import 'piggy_widget_sink.dart';

/// Drains the native inbox and books spends with the existing extractor,
/// then republishes the cofrinho. Used when the UI isolate is not running.
class PiggyClosedAppSync {
  PiggyClosedAppSync({
    required this.repositories,
    required this.sink,
    required this.now,
    this.platform,
  });

  final ColonyRepositories repositories;
  final PiggyWidgetSink sink;
  final DateTime Function() now;
  final NotificationCapturePlatform? platform;

  Future<PiggyEvaluation?> drainAndPublish() async {
    final pending = await platform?.drainInbox() ?? const <NotificationCapturePayload>[];
    return applyPayloads(pending);
  }

  Future<PiggyEvaluation?> applyPayloads(
    List<NotificationCapturePayload> payloads,
  ) async {
    final profile = await repositories.profiles.getActive();
    if (profile == null) return null;
    for (final payload in payloads) {
      try {
        await repositories.integrations.ingestCapturedNotification(
          profileId: profile.id,
          payload: payload,
        );
      } catch (_) {
        // Consent off or a duplicate key — the ledger stays as it is.
      }
    }
    final evaluation = await PiggyBankQuery.load(
      repositories,
      profile.id,
      now(),
    );
    await PiggyWidgetPublisher.publish(
      sink: sink,
      config: evaluation.config,
      snapshot: evaluation.snapshot,
    );
    return evaluation;
  }
}
