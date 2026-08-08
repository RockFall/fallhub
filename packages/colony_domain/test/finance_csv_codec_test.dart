import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('FinanceCsvCodec', () {
    final now = DateTime.utc(2026, 8, 7, 12);
    final tx = LedgerTransaction.create(
      id: EntityId('tx-1'),
      profileId: EntityId('profile-1'),
      accountId: EntityId('acc-1'),
      occurredAt: now,
      descriptionOriginal: 'Café, pão',
      amountMinor: 1500,
      currency: 'BRL',
      direction: TransactionDirection.outflow,
      categoryId: TransactionCategoryPolicy.categoryIdFor(
        TransactionCategory.food,
      ),
      createdAt: now,
    );

    test('encode includes fingerprint and escapes commas', () {
      final csv = FinanceCsvCodec.encodeTransactions([tx]);
      expect(csv, startsWith(FinanceCsvCodec.headerColumns.join(',')));
      expect(csv, contains(tx.fingerprint));
      expect(csv, contains('"Café, pão"'));
      expect(csv, contains('acc-1'));
      expect(csv, contains('1500'));
    });

    test('parsePreview round-trips fingerprint', () {
      final csv = FinanceCsvCodec.encodeTransactions([tx]);
      final rows = FinanceCsvCodec.parsePreview(csv);
      expect(rows, hasLength(1));
      expect(rows.single.fingerprint, tx.fingerprint);
      expect(rows.single.descriptionOriginal, 'Café, pão');
      expect(rows.single.amountMinor, 1500);
      expect(rows.single.categoryId, 'cat_food');
    });

    test('parsePreview recomputes blank fingerprint', () {
      final csv = [
        FinanceCsvCodec.headerColumns.join(','),
        'acc-1,2026-08-07T12:00:00.000Z,Mercado,2000,BRL,outflow,cat_food,',
      ].join('\n');
      final rows = FinanceCsvCodec.parsePreview(csv);
      expect(rows, hasLength(1));
      expect(rows.single.fingerprint, isNotEmpty);
      expect(
        rows.single.fingerprint,
        computeTransactionFingerprint(
          accountId: EntityId('acc-1'),
          occurredAt: DateTime.utc(2026, 8, 7, 12),
          amountMinor: 2000,
          currency: 'BRL',
          direction: TransactionDirection.outflow,
          descriptionOriginal: 'Mercado',
        ),
      );
    });

    test('parsePreview rejects bad header', () {
      expect(
        () => FinanceCsvCodec.parsePreview('a,b,c\n1,2,3'),
        throwsFormatException,
      );
    });
  });
}
