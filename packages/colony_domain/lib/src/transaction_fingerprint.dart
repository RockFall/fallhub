import 'id_generator.dart';
import 'ledger_transaction.dart';

/// Stable hash for deduplication (manual import future).
String computeTransactionFingerprint({
  required EntityId accountId,
  required DateTime occurredAt,
  required int amountMinor,
  required String currency,
  required TransactionDirection direction,
  required String descriptionOriginal,
}) {
  final normalized = [
    accountId.value,
    occurredAt.toUtc().toIso8601String(),
    amountMinor.toString(),
    currency.toUpperCase(),
    direction.name,
    descriptionOriginal.trim().toLowerCase(),
  ].join('|');
  return _fnv1a64Hex(normalized);
}

String _fnv1a64Hex(String input) {
  const offset = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  var hash = offset;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
