import 'id_generator.dart';
import 'ledger_transaction.dart';
import 'transaction_fingerprint.dart';

/// Parsed CSV row ready for plan/apply (§23.9). Persistence is repo-owned.
class FinanceCsvPreviewRow {
  const FinanceCsvPreviewRow({
    required this.accountId,
    required this.occurredAt,
    required this.descriptionOriginal,
    required this.amountMinor,
    required this.currency,
    required this.direction,
    required this.fingerprint,
    this.categoryId,
  });

  final String accountId;
  final DateTime occurredAt;
  final String descriptionOriginal;
  final int amountMinor;
  final String currency;
  final TransactionDirection direction;
  final String fingerprint;
  final String? categoryId;

  FinanceCsvPreviewRow copyWith({
    String? accountId,
    DateTime? occurredAt,
    String? descriptionOriginal,
    int? amountMinor,
    String? currency,
    TransactionDirection? direction,
    String? fingerprint,
    String? categoryId,
    bool clearCategoryId = false,
  }) {
    return FinanceCsvPreviewRow(
      accountId: accountId ?? this.accountId,
      occurredAt: occurredAt ?? this.occurredAt,
      descriptionOriginal: descriptionOriginal ?? this.descriptionOriginal,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      direction: direction ?? this.direction,
      fingerprint: fingerprint ?? this.fingerprint,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
    );
  }
}

/// CSV encode/decode for ledger transactions (§23.9 CSV fase inicial).
/// Export includes [LedgerTransaction.fingerprint] for future dedup import.
abstract final class FinanceCsvCodec {
  static const headerColumns = <String>[
    'account_id',
    'occurred_at',
    'description',
    'amount_minor',
    'currency',
    'direction',
    'category_id',
    'fingerprint',
  ];

  static String encodeTransactions(List<LedgerTransaction> transactions) {
    final buffer = StringBuffer()..writeln(headerColumns.join(','));
    final sorted = [...transactions]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    for (final tx in sorted) {
      buffer.writeln(
        [
          _escape(tx.accountId.value),
          _escape(tx.occurredAt.toUtc().toIso8601String()),
          _escape(tx.descriptionOriginal),
          tx.amountMinor.toString(),
          _escape(tx.currency),
          _escape(tx.direction.name),
          _escape(tx.categoryId?.value ?? ''),
          _escape(tx.fingerprint),
        ].join(','),
      );
    }
    return buffer.toString();
  }

  /// Stub import parser: validates header, returns preview rows.
  /// Recomputes fingerprint when blank; does not write to DB.
  static List<FinanceCsvPreviewRow> parsePreview(String csv) {
    final lines = csv
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      throw FormatException('CSV vazio');
    }
    final header = _parseLine(lines.first);
    if (header.length < headerColumns.length) {
      throw FormatException('Cabeçalho CSV incompleto');
    }
    for (var i = 0; i < headerColumns.length; i++) {
      if (header[i] != headerColumns[i]) {
        throw FormatException(
          'Cabeçalho CSV inválido: esperado ${headerColumns[i]}, obtido ${header[i]}',
        );
      }
    }

    final rows = <FinanceCsvPreviewRow>[];
    for (var i = 1; i < lines.length; i++) {
      final cols = _parseLine(lines[i]);
      if (cols.length < headerColumns.length) {
        throw FormatException('Linha ${i + 1}: colunas insuficientes');
      }
      final accountId = cols[0];
      final occurredAt = DateTime.parse(cols[1]).toUtc();
      final description = cols[2];
      final amountMinor = int.parse(cols[3]);
      final currency = cols[4];
      final direction = TransactionDirection.values.byName(cols[5]);
      final categoryId = cols[6].isEmpty ? null : cols[6];
      final providedFingerprint = cols[7];
      final fingerprint = providedFingerprint.isNotEmpty
          ? providedFingerprint
          : computeTransactionFingerprint(
              accountId: EntityId(accountId),
              occurredAt: occurredAt,
              amountMinor: amountMinor,
              currency: currency,
              direction: direction,
              descriptionOriginal: description,
            );
      rows.add(
        FinanceCsvPreviewRow(
          accountId: accountId,
          occurredAt: occurredAt,
          descriptionOriginal: description,
          amountMinor: amountMinor,
          currency: currency,
          direction: direction,
          fingerprint: fingerprint,
          categoryId: categoryId,
        ),
      );
    }
    return rows;
  }

  static String _escape(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static List<String> _parseLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            buffer.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buffer.write(ch);
        }
      } else if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    result.add(buffer.toString());
    return result;
  }
}
