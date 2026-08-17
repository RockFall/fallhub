import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('export v31 parses placements and research knowledge links', () {
    final now = DateTime.utc(2026, 8, 17, 12);
    final json = {
      'exported_at': now.toIso8601String(),
      'version': 31,
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
      'knowledge_area_placements': [
        {
          'area_id': 'trop',
          'parent_area_id': 'br',
          'linked_at': now.toIso8601String(),
          'catalog_key': 'humanities.history.brazil',
        },
      ],
      'research_knowledge_links': [
        {
          'research_node_id': 'node-1',
          'area_id': 'odd',
          'kind': 'practice',
          'linked_at': now.toIso8601String(),
        },
      ],
    };

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.version, 31);
    expect(snapshot.knowledgeAreaPlacements, hasLength(1));
    expect(snapshot.knowledgeAreaPlacements.single.areaId.value, 'trop');
    expect(snapshot.researchKnowledgeLinks, hasLength(1));
    expect(
      snapshot.researchKnowledgeLinks.single.kind,
      ResearchKnowledgeLinkKind.practice,
    );
  });
}
