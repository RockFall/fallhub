import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

/// Documents supported export band for beta (ADR-034 / Iter 92).
void main() {
  test('export parser accepts band 1..29 and rejects 30', () {
    final now = DateTime.utc(2026, 8, 7, 12);
    Map<String, dynamic> minimal(int version) => {
          'exported_at': now.toIso8601String(),
          'version': version,
          'profile': {
            'id': 'profile-1',
            'colony_name': 'Beta',
            'display_name': 'Caio',
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
        };

    expect(ExportSnapshot.fromJson(minimal(1)).version, 1);
    expect(ExportSnapshot.fromJson(minimal(29)).version, 29);
    expect(
      () => ExportSnapshot.fromJson(minimal(30)),
      throwsA(isA<ExportSnapshotException>()),
    );
    expect(
      () => ExportSnapshot.fromJson(minimal(0)),
      throwsA(isA<ExportSnapshotException>()),
    );
  });
}
