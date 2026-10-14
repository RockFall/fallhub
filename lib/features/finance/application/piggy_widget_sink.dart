import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/services.dart';

abstract interface class PiggyWidgetSink {
  Future<String?> readStatus();
  Future<void> write(PiggyWidgetPayload payload);
  Future<void> notifyRed(String message);
}

class MemoryPiggyWidgetSink implements PiggyWidgetSink {
  String? status;
  PiggyWidgetPayload? last;
  final List<String> alerts = [];

  @override
  Future<String?> readStatus() async => status;

  @override
  Future<void> write(PiggyWidgetPayload payload) async {
    last = payload;
    status = payload.statusName;
  }

  @override
  Future<void> notifyRed(String message) async {
    alerts.add(message);
  }
}

/// Writes the home-screen snapshot through [MethodChannel] `colony/piggy_widget`.
/// Android stores `HomeWidgetPreferences` and redraws the piggy widget.
/// The headless worker has no activity channel, so it persists the same map itself.
class ChannelPiggyWidgetSink implements PiggyWidgetSink {
  const ChannelPiggyWidgetSink();

  static const _channel = MethodChannel('colony/piggy_widget');

  @override
  Future<String?> readStatus() async {
    try {
      return await _channel.invokeMethod<String>('readStatus');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(PiggyWidgetPayload payload) async {
    try {
      await _channel.invokeMethod<void>('publish', {
        'balance': payload.balanceLabel,
        'spentToday': payload.spentTodayLabel,
        'available': payload.availableLabel,
        'debt': payload.debtLabel,
        'status': payload.statusName,
        'week': payload.weekCsv,
      });
    } catch (_) {
      // Desktop tests and the headless isolate have no activity channel.
    }
  }

  @override
  Future<void> notifyRed(String message) async {
    try {
      await _channel.invokeMethod<void>('notifyRed', {'message': message});
    } catch (_) {}
  }
}

abstract final class PiggyWidgetPublisher {
  static Future<bool> publish({
    required PiggyWidgetSink sink,
    required PiggyBankConfig config,
    required PiggyBankSnapshot snapshot,
  }) async {
    final previous = await sink.readStatus();
    final payload = PiggyWidgetPayload.fromSnapshot(
      snapshot,
      alertWhenRed: config.alertWhenRed,
    );
    final crossed = PiggyPublishPolicy.shouldAlert(
      alertWhenRed: config.alertWhenRed,
      status: snapshot.status,
      previousStatus: previous,
    );
    await sink.write(payload);
    if (crossed) await sink.notifyRed(payload.alertMessage);
    return crossed;
  }
}
