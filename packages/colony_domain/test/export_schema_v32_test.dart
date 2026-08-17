import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('export v32 parses hierarchical flashcard tags', () {
    final now = DateTime.utc(2026, 8, 17, 12);
    final json = {
      'exported_at': now.toIso8601String(),
      'version': 32,
      'profile': {
        'id': 'profile-1',
        'colony_name': 'Schema',
        'display_name': 'Tester',
        'timezone': 'UTC',
        'locale': 'pt_BR',
        'base_currency': 'BRL',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      'preferences': {
        'density_mode': 'management',
        'theme_mode': 'dark',
        'week_starts_on_monday': true,
        'use_24_hour_format': true,
        'sectors_enabled': <String>[],
        'onboarding_completed': true,
      },
      'tasks': <Map<String, dynamic>>[],
      'events': <Map<String, dynamic>>[],
      'flashcard_tags': [
        {
          'id': 'tag-music',
          'title': 'Música',
          'sort_order': 0,
          'created_at': now.toIso8601String(),
        },
        {
          'id': 'tag-harmony',
          'parent_id': 'tag-music',
          'title': 'Harmonia',
          'sort_order': 1,
          'created_at': now.toIso8601String(),
        },
      ],
      'flashcard_tag_links': [
        {
          'card_id': 'card-1',
          'tag_id': 'tag-harmony',
          'linked_at': now.toIso8601String(),
        },
      ],
    };

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.version, 32);
    expect(snapshot.flashcardTags, hasLength(2));
    expect(snapshot.flashcardTags.last.parentId?.value, 'tag-music');
    expect(snapshot.flashcardTagLinks, hasLength(1));
    expect(snapshot.flashcardTagLinks.single.tagId.value, 'tag-harmony');
    expect(snapshot.toJson()['flashcard_tags'], isA<List>());
  });

  test('export rejects version above 32', () {
    expect(
      () => ExportSnapshot.fromJson({
        'exported_at': '2026-08-17T12:00:00.000Z',
        'version': 33,
        'profile': {
          'id': 'profile-1',
          'colony_name': 'Schema',
          'display_name': 'Tester',
          'timezone': 'UTC',
          'locale': 'pt_BR',
          'base_currency': 'BRL',
          'created_at': '2026-08-17T12:00:00.000Z',
          'updated_at': '2026-08-17T12:00:00.000Z',
        },
        'preferences': {
          'density_mode': 'management',
          'theme_mode': 'dark',
          'week_starts_on_monday': true,
          'use_24_hour_format': true,
          'sectors_enabled': <String>[],
          'onboarding_completed': true,
        },
        'tasks': <Map<String, dynamic>>[],
        'events': <Map<String, dynamic>>[],
      }),
      throwsA(isA<ExportSnapshotException>()),
    );
  });
}
