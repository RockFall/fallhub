import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final integrationConsentsProvider =
    StreamProvider<List<IntegrationConsent>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).integrations.watchConsents(profile.id);
});

final externalCalendarEventsProvider =
    StreamProvider<List<ExternalCalendarEvent>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref
      .watch(repositoriesProvider)
      .integrations
      .watchCalendarEvents(profile.id);
});

final calendarIcsConsentProvider = Provider<IntegrationConsent?>((ref) {
  final consents = ref.watch(integrationConsentsProvider).asData?.value;
  if (consents == null) return null;
  for (final c in consents) {
    if (c.kind == IntegrationKind.calendarIcs) return c;
  }
  return null;
});
