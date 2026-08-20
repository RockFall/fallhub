import 'dart:async';

import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'integrations_providers.dart';
import 'notification_capture_platform.dart';

class IntegrationsController extends AsyncNotifier<void> {
  StreamSubscription<NotificationCapturePayload>? _liveSub;
  Future<void>? _syncInFlight;

  NotificationCapturePlatform get _platform =>
      ref.read(notificationCapturePlatformProvider);

  @override
  Future<void> build() async {
    ref.onDispose(() {
      _liveSub?.cancel();
      _liveSub = null;
    });
  }

  Future<void> ensureCalendarConsent() async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return;
    await ref.read(repositoriesProvider).integrations.ensureConsent(
          profileId: profile.id,
          kind: IntegrationKind.calendarIcs,
        );
    ref.invalidate(integrationConsentsProvider);
  }

  Future<void> ensureNotificationConsent() async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return;
    await ref.read(repositoriesProvider).integrations.ensureConsent(
          profileId: profile.id,
          kind: IntegrationKind.notificationListener,
        );
    ref.invalidate(integrationConsentsProvider);
  }

  Future<void> setCalendarIcsEnabled(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) {
        throw StateError('Perfil não encontrado');
      }
      await ref.read(repositoriesProvider).integrations.setConsentEnabled(
            profileId: profile.id,
            kind: IntegrationKind.calendarIcs,
            enabled: enabled,
          );
    });
    ref.invalidate(integrationConsentsProvider);
  }

  Future<void> setNotificationListenerEnabled(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) {
        throw StateError('Perfil não encontrado');
      }
      await ref.read(repositoriesProvider).integrations.setConsentEnabled(
            profileId: profile.id,
            kind: IntegrationKind.notificationListener,
            enabled: enabled,
          );
    });
    ref.invalidate(integrationConsentsProvider);
    if (enabled) {
      await syncNotificationIngest();
    } else {
      await _liveSub?.cancel();
      _liveSub = null;
    }
  }

  Future<bool> isAndroidListenerEnabled() {
    return _platform.isListenerEnabled();
  }

  Future<void> openAndroidListenerSettings() {
    return _platform.openListenerSettings();
  }

  Future<void> syncNotificationIngest() {
    return _syncInFlight ??= _syncNotificationIngest().whenComplete(() {
      _syncInFlight = null;
    });
  }

  Future<void> _syncNotificationIngest() async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return;
    final consents = await ref
        .read(repositoriesProvider)
        .integrations
        .listConsents(profile.id);
    final enabled = consents.any(
      (c) => c.kind == IntegrationKind.notificationListener && c.enabled,
    );
    if (!enabled) return;
    final pending = await _platform.drainInbox();
    for (final payload in pending) {
      await _ingest(profile.id, payload);
    }
    await _liveSub?.cancel();
    _liveSub = _platform.live().listen((payload) {
      unawaited(_ingest(profile.id, payload));
    });
  }

  Future<void> _ingest(
    EntityId profileId,
    NotificationCapturePayload payload,
  ) async {
    try {
      await ref.read(repositoriesProvider).integrations.ingestCapturedNotification(
            profileId: profileId,
            payload: payload,
          );
    } catch (_) {
      // Inbox item may arrive after revoke; ignore.
    }
  }

  List<IcsEventPreview> previewIcs(String source) {
    return IcsCodec.parsePreview(source);
  }

  Future<int> confirmIcsImport(
    List<IcsEventPreview> previews, {
    bool alsoCreateScheduleBlocks = false,
  }) async {
    var count = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) {
        throw StateError('Perfil não encontrado');
      }
      final repos = ref.read(repositoriesProvider);
      final created = await repos.integrations.importCalendarPreviews(
        profileId: profile.id,
        previews: previews,
      );
      count = created.length;
      if (alsoCreateScheduleBlocks) {
        final selectable = IcsSchedulePolicy.selectableForSchedule(previews);
        for (final preview in selectable) {
          await repos.schedule.create(
            profileId: profile.id,
            startAt: preview.startAt,
            endAt: preview.endAt,
            mode: IcsSchedulePolicy.defaultMode,
            sourceType: SourceType.integration,
          );
        }
      }
    });
    ref.invalidate(externalCalendarEventsProvider);
    ref.invalidate(integrationConsentsProvider);
    return state.hasError ? 0 : count;
  }
}

final integrationsControllerProvider =
    AsyncNotifierProvider<IntegrationsController, void>(
  IntegrationsController.new,
);

/// Starts inbox drain + live listen while in-app opt-in is on.
final notificationIngestRuntimeProvider = Provider<void>((ref) {
  ref.listen<IntegrationConsent?>(
    notificationListenerConsentProvider,
    (previous, next) {
      if (next?.enabled == true) {
        ref.read(integrationsControllerProvider.notifier).syncNotificationIngest();
      }
    },
    fireImmediately: true,
  );
});
