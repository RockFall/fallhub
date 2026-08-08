import 'finance_csv_codec.dart';

/// Result of planning a CSV import with fingerprint deduplication (§23.9).
class FinanceCsvImportPlan {
  const FinanceCsvImportPlan({
    required this.toImport,
    required this.duplicates,
  });

  final List<FinanceCsvPreviewRow> toImport;
  final List<FinanceCsvPreviewRow> duplicates;

  int get importCount => toImport.length;
  int get duplicateCount => duplicates.length;

  bool get isEmpty => importCount == 0 && duplicateCount == 0;
  bool get hasWork => importCount > 0;
}

/// Pure policy: splits preview rows into new vs already-known fingerprints.
abstract final class FinanceCsvImportPolicy {
  /// Remaps every row to [accountId] while keeping CSV fingerprints for dedup.
  static List<FinanceCsvPreviewRow> withAccountOverride({
    required List<FinanceCsvPreviewRow> rows,
    required String accountId,
  }) {
    final trimmed = accountId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('accountId cannot be empty');
    }
    return [
      for (final row in rows) row.copyWith(accountId: trimmed),
    ];
  }

  static FinanceCsvImportPlan plan({
    required List<FinanceCsvPreviewRow> preview,
    required Set<String> existingFingerprints,
  }) {
    final toImport = <FinanceCsvPreviewRow>[];
    final duplicates = <FinanceCsvPreviewRow>[];
    final seenInFile = <String>{};

    for (final row in preview) {
      if (existingFingerprints.contains(row.fingerprint) ||
          seenInFile.contains(row.fingerprint)) {
        duplicates.add(row);
      } else {
        toImport.add(row);
        seenInFile.add(row.fingerprint);
      }
    }

    return FinanceCsvImportPlan(toImport: toImport, duplicates: duplicates);
  }
}
