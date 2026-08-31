import 'dart:async';

import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'calendar_ics_auto_sync.dart';
import 'ics_feed_client.dart';
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
    await ref
        .read(repositoriesProvider)
        .integrations
        .ensureConsent(
          profileId: profile.id,
          kind: IntegrationKind.calendarIcs,
        );
    ref.invalidate(integrationConsentsProvider);
  }

  Future<void> ensureNotificationConsent() async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return;
    await ref
        .read(repositoriesProvider)
        .integrations
        .ensureConsent(
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
      await ref
          .read(repositoriesProvider)
          .integrations
          .setConsentEnabled(
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
      await ref
          .read(repositoriesProvider)
          .integrations
          .setConsentEnabled(
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
      await ref
          .read(repositoriesProvider)
          .integrations
          .ingestCapturedNotification(profileId: profileId, payload: payload);
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
    ref.invalidate(calendarOverlayEventsProvider);
    ref.invalidate(integrationConsentsProvider);
    return state.hasError ? 0 : count;
  }

  Future<int> syncIcsFeed(String rawUrl, {bool persistUrl = true}) async {
    var count = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uri = IcsFeedPolicy.normalize(rawUrl);
      if (uri == null) {
        throw const IcsFeedFetchException('URL inválida');
      }
      await ensureCalendarConsent();
      final profile = await ref.read(profileProvider.future);
      if (profile == null) {
        throw StateError('Perfil não encontrado');
      }
      final consents = await ref
          .read(repositoriesProvider)
          .integrations
          .listConsents(profile.id);
      final enabled = consents.any(
        (c) => c.kind == IntegrationKind.calendarIcs && c.enabled,
      );
      if (!enabled) {
        await ref
            .read(repositoriesProvider)
            .integrations
            .setConsentEnabled(
              profileId: profile.id,
              kind: IntegrationKind.calendarIcs,
              enabled: true,
            );
      }
      final body = await ref.read(icsFeedClientProvider).get(uri);
      final now = ref.read(clockProvider)();
      final previews = IcsCodec.parsePreview(
        body,
        windowStart: now.toUtc().subtract(const Duration(days: 30)),
        windowEnd: now.toUtc().add(const Duration(days: 400)),
      );
      final created = await ref
          .read(repositoriesProvider)
          .integrations
          .syncCalendarPreviews(profileId: profile.id, previews: previews);
      count = created.length;
      final store = ref.read(calendarIcsFeedStoreProvider);
      if (persistUrl) {
        await store.writeUrl(uri.toString());
      }
      await store.writeLastFetchedAt(now.toUtc());
    });
    ref.invalidate(externalCalendarEventsProvider);
    ref.invalidate(calendarOverlayEventsProvider);
    ref.invalidate(integrationConsentsProvider);
    ref.invalidate(calendarIcsFeedUrlProvider);
    if (state.hasError) {
      final err = state.error;
      if (err is IcsFeedFetchException || err is FormatException) {
        throw err!;
      }
      throw IcsFeedFetchException(err.toString());
    }
    return count;
  }

  Future<int?> refreshFeedIfStale({
    Duration maxAge = const Duration(minutes: 15),
  }) async {
    final store = ref.read(calendarIcsFeedStoreProvider);
    final url = await store.readUrl();
    if (url == null || url.isEmpty) return null;
    final last = await store.readLastFetchedAt();
    final now = ref.read(clockProvider)();
    if (last != null && now.toUtc().difference(last) < maxAge) {
      return null;
    }
    try {
      return await syncIcsFeed(url, persistUrl: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> unlinkIcsFeed() async {
    await ref.read(calendarIcsFeedStoreProvider).clear();
    ref.invalidate(calendarIcsFeedUrlProvider);
    ref.invalidate(calendarOverlayEventsProvider);
  }
}

final integrationsControllerProvider =
    AsyncNotifierProvider<IntegrationsController, void>(
      IntegrationsController.new,
    );

/// Starts inbox drain + live listen while in-app opt-in is on.
final notificationIngestRuntimeProvider = Provider<void>((ref) {
  ref.listen<IntegrationConsent?>(notificationListenerConsentProvider, (
    previous,
    next,
  ) {
    if (next?.enabled == true) {
      ref
          .read(integrationsControllerProvider.notifier)
          .syncNotificationIngest();
    }
  }, fireImmediately: true);
});

/// Pulls the saved Google iCal feed when the app opens or returns to
/// the foreground (ADR-050). First process pull is eager; resumes use 15 min.
final calendarIcsAutoSyncProvider = Provider<CalendarIcsAutoSync>((ref) {
  return CalendarIcsAutoSync(
    refresh: ({Duration maxAge = const Duration(minutes: 15)}) {
      return ref
          .read(integrationsControllerProvider.notifier)
          .refreshFeedIfStale(maxAge: maxAge);
    },
  );
});

/// Wires [CalendarIcsAutoSync] to profile-ready + app lifecycle.
final calendarIcsRuntimeProvider = Provider<void>((ref) {
  final sync = ref.watch(calendarIcsAutoSyncProvider);

  Future<void> pull({required bool resumed}) async {
    try {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) return;
      if (resumed) {
        await sync.onResumed();
      } else {
        await sync.onOpened();
      }
    } catch (_) {
      // Offline / missing plugin — agenda still works with local data.
    }
  }

  ref.listen(profileProvider, (previous, next) {
    if (next.asData?.value != null) {
      unawaited(pull(resumed: false));
    }
  }, fireImmediately: true);

  final listener = AppLifecycleListener(
    onResume: () => unawaited(pull(resumed: true)),
  );
  ref.onDispose(listener.dispose);
});

/// Back-compat alias used by home/schedule; prefers the lifecycle runtime.
final calendarIcsAutoRefreshProvider = calendarIcsRuntimeProvider;
