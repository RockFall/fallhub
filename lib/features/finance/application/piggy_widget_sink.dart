import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

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

class HomeWidgetPiggySink implements PiggyWidgetSink {
  const HomeWidgetPiggySink();

  static const _channel = MethodChannel('colony/piggy_widget');
  static const androidProvider = 'PiggyBankWidgetProvider';

  @override
  Future<String?> readStatus() async {
    try {
      return await HomeWidget.getWidgetData<String>('piggy_status');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(PiggyWidgetPayload payload) async {
    try {
      await HomeWidget.saveWidgetData<String>('piggy_balance', payload.balanceLabel);
      await HomeWidget.saveWidgetData<String>(
        'piggy_spent_today',
        payload.spentTodayLabel,
      );
      await HomeWidget.saveWidgetData<String>(
        'piggy_available',
        payload.availableLabel,
      );
      await HomeWidget.saveWidgetData<String>('piggy_debt', payload.debtLabel);
      await HomeWidget.saveWidgetData<String>('piggy_status', payload.statusName);
      await HomeWidget.saveWidgetData<String>('piggy_week', payload.weekCsv);
      await HomeWidget.updateWidget(androidName: androidProvider);
      await _channel.invokeMethod<void>('scheduleMidnight');
    } catch (_) {
      // Desktop tests and hosts without the plugin keep the in-app cofrinho.
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
