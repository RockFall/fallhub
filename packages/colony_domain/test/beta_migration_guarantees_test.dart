import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

/// Documents supported export band for beta (ADR-034 / Iter 92).
void main() {
  test('export parser accepts band 1..38 and rejects 39', () {
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
    expect(ExportSnapshot.fromJson(minimal(30)).version, 30);
    expect(ExportSnapshot.fromJson(minimal(31)).version, 31);
    expect(ExportSnapshot.fromJson(minimal(32)).version, 32);
    expect(ExportSnapshot.fromJson(minimal(33)).version, 33);
    expect(ExportSnapshot.fromJson(minimal(34)).version, 34);
    expect(ExportSnapshot.fromJson(minimal(35)).version, 35);
    expect(ExportSnapshot.fromJson(minimal(36)).version, 36);
    expect(ExportSnapshot.fromJson(minimal(37)).version, 37);
    expect(ExportSnapshot.fromJson(minimal(38)).version, 38);
    expect(
      () => ExportSnapshot.fromJson(minimal(39)),
      throwsA(isA<ExportSnapshotException>()),
    );
    expect(
      () => ExportSnapshot.fromJson(minimal(0)),
      throwsA(isA<ExportSnapshotException>()),
    );
  });
}
