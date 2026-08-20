import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android NotificationListener bridge (ADR-011). No-op on other platforms.
class NotificationCapturePlatform {
  NotificationCapturePlatform({
    MethodChannel? methods,
    EventChannel? events,
  })  : _methods = methods ?? const MethodChannel('colony/notifications'),
        _events = events ?? const EventChannel('colony/notifications/events');

  final MethodChannel _methods;
  final EventChannel _events;

  static final NotificationCapturePlatform instance =
      NotificationCapturePlatform();

  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> isListenerEnabled() async {
    if (!isAndroid) return false;
    try {
      final value = await _methods.invokeMethod<bool>('isListenerEnabled');
      return value ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openListenerSettings() async {
    if (!isAndroid) return;
    try {
      await _methods.invokeMethod<void>('openListenerSettings');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<List<NotificationCapturePayload>> drainInbox() async {
    if (!isAndroid) return const [];
    try {
      final raw = await _methods.invokeMethod<List<dynamic>>('drainInbox');
      return _decodeList(raw);
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }

  Stream<NotificationCapturePayload> live() {
    if (!isAndroid) return const Stream.empty();
    return _events.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return NotificationCapturePayload.fromJson(
          Map<Object?, Object?>.from(event),
        );
      }
      throw FormatException('Evento de notificação inválido');
    });
  }

  static List<NotificationCapturePayload> _decodeList(List<dynamic>? raw) {
    if (raw == null) return const [];
    final out = <NotificationCapturePayload>[];
    for (final item in raw) {
      if (item is Map) {
        out.add(
          NotificationCapturePayload.fromJson(
            Map<Object?, Object?>.from(item),
          ),
        );
      }
    }
    return out;
  }
}

class FakeNotificationCapturePlatform extends NotificationCapturePlatform {
  FakeNotificationCapturePlatform({
    this.android = true,
    this.listenerEnabled = false,
    List<NotificationCapturePayload>? inbox,
    Stream<NotificationCapturePayload>? liveStream,
  })  : inbox = inbox ?? <NotificationCapturePayload>[],
        _live = liveStream ?? const Stream.empty(),
        super(
          methods: const MethodChannel('colony/notifications/fake'),
          events: const EventChannel('colony/notifications/fake/events'),
        );

  bool android;
  bool listenerEnabled;
  final List<NotificationCapturePayload> inbox;
  final Stream<NotificationCapturePayload> _live;
  int openSettingsCount = 0;

  @override
  bool get isAndroid => android;

  @override
  Future<bool> isListenerEnabled() async => android && listenerEnabled;

  @override
  Future<void> openListenerSettings() async {
    openSettingsCount++;
  }

  @override
  Future<List<NotificationCapturePayload>> drainInbox() async {
    final copy = List<NotificationCapturePayload>.from(inbox);
    inbox.clear();
    return copy;
  }

  @override
  Stream<NotificationCapturePayload> live() => _live;
}
