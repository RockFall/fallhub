import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 18, 12);

  Map<String, dynamic> base({required int version}) => {
        'exported_at': now.toIso8601String(),
        'version': version,
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
        'knowledge_areas': [
          {
            'id': 'area-1',
            'title': 'Música',
            'slug': 'musica',
            'sort_order': 0,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          },
        ],
        'flashcard_decks': [
          {
            'id': 'deck-1',
            'title': 'Teoria',
            'new_limit_per_day': 20,
            'review_limit_per_day': 200,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          },
        ],
        'flashcards': [
          {
            'id': 'card-1',
            'deck_id': 'deck-1',
            'kind': 'basic',
            'front': 'Dominante',
            'back': 'V',
            'tags': <String>[],
            'schedule_mode': 'scheduled',
            'suspended': false,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            if (version >= 32) 'priority': 1,
          },
        ],
      };

  test('export v31 flashcards default priority to 5', () {
    final snapshot = ExportSnapshot.fromJson(base(version: 31));
    expect(snapshot.version, 31);
    expect(snapshot.flashcards.single.priority, 5);
  });

  test('export v32 parses flashcard priority', () {
    final snapshot = ExportSnapshot.fromJson(base(version: 32));
    expect(snapshot.version, 32);
    expect(snapshot.flashcards.single.priority, 1);
    final encoded = snapshot.toJson()['flashcards'] as List<dynamic>;
    expect((encoded.first as Map)['priority'], 1);
  });
}
