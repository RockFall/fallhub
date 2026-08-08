import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

FinanceCsvPreviewRow _row(String fingerprint, {String desc = 'x'}) {
  return FinanceCsvPreviewRow(
    accountId: 'acc-1',
    occurredAt: DateTime.utc(2026, 8, 7),
    descriptionOriginal: desc,
    amountMinor: 100,
    currency: 'BRL',
    direction: TransactionDirection.outflow,
    fingerprint: fingerprint,
  );
}

void main() {
  group('FinanceCsvImportPolicy', () {
    test('separates new rows from existing fingerprints', () {
      final plan = FinanceCsvImportPolicy.plan(
        preview: [_row('fp-new'), _row('fp-old')],
        existingFingerprints: {'fp-old'},
      );
      expect(plan.importCount, 1);
      expect(plan.duplicateCount, 1);
      expect(plan.toImport.single.fingerprint, 'fp-new');
      expect(plan.duplicates.single.fingerprint, 'fp-old');
    });

    test('dedups repeated fingerprints within the same file', () {
      final plan = FinanceCsvImportPolicy.plan(
        preview: [_row('fp-a', desc: 'one'), _row('fp-a', desc: 'two')],
        existingFingerprints: {},
      );
      expect(plan.importCount, 1);
      expect(plan.duplicateCount, 1);
      expect(plan.toImport.single.descriptionOriginal, 'one');
    });

    test('withAccountOverride remaps account and keeps fingerprint', () {
      final remapped = FinanceCsvImportPolicy.withAccountOverride(
        rows: [_row('fp-ext', desc: 'Banco')],
        accountId: 'acc-local',
      );
      expect(remapped.single.accountId, 'acc-local');
      expect(remapped.single.fingerprint, 'fp-ext');
      expect(remapped.single.descriptionOriginal, 'Banco');
    });

    test('plan hasWork reflects importable rows', () {
      final empty = FinanceCsvImportPolicy.plan(
        preview: [_row('fp-old')],
        existingFingerprints: {'fp-old'},
      );
      expect(empty.hasWork, isFalse);
      final work = FinanceCsvImportPolicy.plan(
        preview: [_row('fp-new')],
        existingFingerprints: {},
      );
      expect(work.hasWork, isTrue);
    });
  });
}
