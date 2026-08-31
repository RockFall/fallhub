import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/integrations/application/calendar_ics_feed_store.dart';
import 'package:fallhub/features/integrations/application/ics_feed_client.dart';
import 'package:fallhub/features/integrations/application/integrations_controllers.dart';
import 'package:fallhub/features/integrations/application/integrations_providers.dart';
import 'package:fallhub/features/work/application/work_providers.dart';

void main() {
  test('buildScheduleTimelineItems overlays Google events by title', () {
    final items = buildScheduleTimelineItems(
      blocks: const [],
      tasks: const [],
      day: DateTime(2026, 8, 31),
      externalEvents: [
        ExternalCalendarEvent(
          id: EntityId('e1'),
          profileId: EntityId('p'),
          externalUid: 'uid-1',
          title: 'Reunião cap. 3',
          startAt: DateTime(2026, 8, 31, 14).toUtc(),
          endAt: DateTime(2026, 8, 31, 15).toUtc(),
          sourceType: SourceType.integration,
          importedAt: DateTime.utc(2026, 8, 31),
          createdAt: DateTime.utc(2026, 8, 31),
          updatedAt: DateTime.utc(2026, 8, 31),
        ),
      ],
    );
    expect(items, hasLength(1));
    expect(items.single.kind, ScheduleTimelineItemKind.external);
    expect(items.single.label, 'Reunião cap. 3');
  });

  test(
    'buildScheduleTimelineItems skips Google events duplicated as blocks',
    () {
      final start = DateTime(2026, 8, 31, 14).toUtc();
      final end = DateTime(2026, 8, 31, 15).toUtc();
      final items = buildScheduleTimelineItems(
        blocks: [
          ScheduleBlock.create(
            id: EntityId('b1'),
            profileId: EntityId('p'),
            startAt: start,
            endAt: end,
            mode: ScheduleBlockMode.meeting,
            createdAt: DateTime.utc(2026, 8, 31),
          ),
        ],
        tasks: const [],
        day: DateTime(2026, 8, 31),
        externalEvents: [
          ExternalCalendarEvent(
            id: EntityId('e1'),
            profileId: EntityId('p'),
            title: 'Reunião cap. 3',
            startAt: start,
            endAt: end,
            sourceType: SourceType.integration,
            importedAt: DateTime.utc(2026, 8, 31),
            createdAt: DateTime.utc(2026, 8, 31),
            updatedAt: DateTime.utc(2026, 8, 31),
          ),
        ],
      );
      expect(items, hasLength(1));
      expect(items.single.kind, ScheduleTimelineItemKind.block);
    },
  );

  test('syncIcsFeed persists events from a fake Google iCal', () async {
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(List.generate(40, (i) => 'gcal-$i')),
      clock: () => DateTime.utc(2026, 8, 31, 12),
    );
    await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final store = MemoryCalendarIcsFeedStore();
    const ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:meet-1
SUMMARY:Sincro Google
DTSTART:20260831T150000Z
DTEND:20260831T160000Z
END:VEVENT
END:VCALENDAR
''';

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        repositoriesProvider.overrideWithValue(repos),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 8, 31, 12)),
        calendarIcsFeedStoreProvider.overrideWithValue(store),
        icsFeedClientProvider.overrideWithValue(FakeIcsFeedClient(ics)),
      ],
    );
    addTearDown(container.dispose);

    final count = await container
        .read(integrationsControllerProvider.notifier)
        .syncIcsFeed(
          'https://calendar.google.com/calendar/ical/x/private-z/basic.ics',
        );
    expect(count, 1);
    expect(await store.readUrl(), contains('calendar.google.com'));
    final events = await repos.integrations.listCalendarEvents(
      (await repos.profiles.getActive())!.id,
    );
    expect(events.single.title, 'Sincro Google');
  });
}
