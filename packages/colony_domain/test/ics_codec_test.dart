import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('IcsCodec', () {
    test('parses VEVENT summary and UTC times', () {
      const ics = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:evt-1@colony
SUMMARY:Reunião
DTSTART:20260807T140000Z
DTEND:20260807T150000Z
END:VEVENT
END:VCALENDAR
''';
      final events = IcsCodec.parsePreview(ics);
      expect(events, hasLength(1));
      expect(events.first.uid, 'evt-1@colony');
      expect(events.first.summary, 'Reunião');
      expect(events.first.startAt, DateTime.utc(2026, 8, 7, 14));
      expect(events.first.endAt, DateTime.utc(2026, 8, 7, 15));
    });

    test('unfolds folded SUMMARY lines', () {
      const ics = '''
BEGIN:VEVENT
UID:fold
SUMMARY:Linha muito lon
 ga de título
DTSTART:20260808T090000Z
DTEND:20260808T100000Z
END:VEVENT
''';
      final events = IcsCodec.parsePreview(ics);
      expect(events.first.summary, 'Linha muito longa de título');
    });

    test('defaults end to +1h when DTEND missing', () {
      const ics = '''
BEGIN:VEVENT
SUMMARY:Só início
DTSTART:20260809T120000Z
END:VEVENT
''';
      final events = IcsCodec.parsePreview(ics);
      expect(events.first.endAt, DateTime.utc(2026, 8, 9, 13));
    });

    test('floating DTSTART uses local timezone', () {
      const ics = '''
BEGIN:VEVENT
SUMMARY:Local
DTSTART:20260831T140000
DTEND:20260831T150000
END:VEVENT
''';
      final events = IcsCodec.parsePreview(ics);
      expect(events.first.startAt, DateTime(2026, 8, 31, 14).toUtc());
      expect(events.first.endAt, DateTime(2026, 8, 31, 15).toUtc());
    });

    test('expands RRULE weekly occurrences', () {
      const ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:rec@google
SUMMARY:Aula
DTSTART:20260831T140000Z
DTEND:20260831T150000Z
RRULE:FREQ=WEEKLY;BYDAY=MO;COUNT=2
END:VEVENT
END:VCALENDAR
''';
      final events = IcsCodec.parsePreview(
        ics,
        windowStart: DateTime.utc(2026, 8, 31),
        windowEnd: DateTime.utc(2026, 9, 15),
      );
      expect(events, hasLength(2));
      expect(events.first.summary, 'Aula');
      expect(events[1].startAt, DateTime.utc(2026, 9, 7, 14));
    });

    test('throws on empty or no VEVENT', () {
      expect(() => IcsCodec.parsePreview(''), throwsFormatException);
      expect(
        () => IcsCodec.parsePreview('BEGIN:VCALENDAR\nEND:VCALENDAR'),
        throwsFormatException,
      );
    });
  });

  group('IntegrationConsent', () {
    test('grant and revoke toggle enabled without losing history intent', () {
      final now = DateTime.utc(2026, 8, 7, 12);
      final consent = IntegrationConsent.create(
        id: EntityId('c1'),
        profileId: EntityId('p1'),
        kind: IntegrationKind.calendarIcs,
        createdAt: now,
      );
      expect(consent.enabled, isFalse);
      final granted = consent.grant(now.add(const Duration(minutes: 1)));
      expect(granted.enabled, isTrue);
      expect(granted.grantedAt, isNotNull);
      final revoked = granted.revoke(now.add(const Duration(hours: 1)));
      expect(revoked.enabled, isFalse);
      expect(revoked.revokedAt, isNotNull);
      expect(revoked.grantedAt, granted.grantedAt);
    });
  });

  group('ExternalCalendarEvent', () {
    test('fromPreview sets integration provenance', () {
      final now = DateTime.utc(2026, 8, 7, 12);
      final event = ExternalCalendarEvent.fromPreview(
        id: EntityId('e1'),
        profileId: EntityId('p1'),
        preview: IcsEventPreview(
          uid: 'u1',
          summary: 'Call',
          startAt: DateTime.utc(2026, 8, 7, 14),
          endAt: DateTime.utc(2026, 8, 7, 15),
        ),
        importedAt: now,
      );
      expect(event.sourceType, SourceType.integration);
      expect(event.title, 'Call');
      expect(event.externalUid, 'u1');
    });
  });
}
