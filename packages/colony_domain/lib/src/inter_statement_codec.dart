import 'finance_csv_codec.dart';
import 'id_generator.dart';
import 'ledger_transaction.dart';
import 'transaction_fingerprint.dart';

/// OFX (Inter SGML) + CSV nativo Inter + CSV interno Colony.
abstract final class InterStatementCodec {
  static bool looksLikeOfx(String source) {
    final head = source.trimLeft().toUpperCase();
    return head.startsWith('OFXHEADER') ||
        head.contains('<OFX>') ||
        head.contains('<STMTTRN>');
  }

  static bool looksLikeInterCsv(String source) {
    final header = _findHeaderLine(source);
    if (header == null) return false;
    final n = header.toLowerCase();
    return (n.contains('data') && n.contains('valor')) &&
        !n.contains('account_id');
  }

  /// Parses OFX, Inter CSV, or Colony CSV. [accountId] required for Inter/OFX.
  static List<FinanceCsvPreviewRow> parse(
    String source, {
    required String accountId,
  }) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      throw FormatException('Arquivo vazio');
    }
    if (looksLikeOfx(trimmed)) {
      return parseOfx(trimmed, accountId: accountId);
    }
    if (looksLikeInterCsv(trimmed)) {
      return parseInterCsv(trimmed, accountId: accountId);
    }
    return FinanceCsvCodec.parsePreview(trimmed);
  }

  static List<FinanceCsvPreviewRow> parseOfx(
    String source, {
    required String accountId,
  }) {
    final blocks = RegExp(
      r'<STMTTRN>([\s\S]*?)</STMTTRN>',
      caseSensitive: false,
    ).allMatches(source);
    if (blocks.isEmpty) {
      throw FormatException('OFX sem transações');
    }
    final rows = <FinanceCsvPreviewRow>[];
    for (final block in blocks) {
      final body = block.group(1)!;
      final amountRaw = _sgml(body, 'TRNAMT');
      final dateRaw = _sgml(body, 'DTPOSTED');
      final memo = _sgml(body, 'MEMO') ?? _sgml(body, 'NAME') ?? 'OFX';
      final fitId = _sgml(body, 'FITID');
      if (amountRaw == null || dateRaw == null) continue;
      final amount = double.tryParse(amountRaw.replaceAll(',', '.'));
      if (amount == null || amount == 0) continue;
      final occurredAt = _parseOfxDate(dateRaw);
      final outflow = amount < 0;
      final amountMinor = (amount.abs() * 100).round();
      final direction =
          outflow ? TransactionDirection.outflow : TransactionDirection.inflow;
      final description = memo.trim();
      final fingerprint = fitId != null && fitId.trim().isNotEmpty
          ? 'ofx:${fitId.trim()}'
          : computeTransactionFingerprint(
              accountId: EntityId(accountId),
              occurredAt: occurredAt,
              amountMinor: amountMinor,
              currency: 'BRL',
              direction: direction,
              descriptionOriginal: description,
            );
      rows.add(
        FinanceCsvPreviewRow(
          accountId: accountId,
          occurredAt: occurredAt,
          descriptionOriginal: description,
          amountMinor: amountMinor,
          currency: 'BRL',
          direction: direction,
          fingerprint: fingerprint,
        ),
      );
    }
    if (rows.isEmpty) {
      throw FormatException('OFX sem lançamentos válidos');
    }
    return rows;
  }

  static List<FinanceCsvPreviewRow> parseInterCsv(
    String source, {
    required String accountId,
  }) {
    final lines = source
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final headerIndex = lines.indexWhere((l) => _isInterHeader(l));
    if (headerIndex < 0) {
      throw FormatException('CSV Inter sem cabeçalho Data/Valor');
    }
    final header = _split(lines[headerIndex]);
    final dateIdx = _col(header, ['data lançamento', 'data lancamento', 'data']);
    final valueIdx = _col(header, ['valor']);
    final histIdx = _col(header, ['histórico', 'historico', 'descricao', 'descrição']);
    final descIdx = _col(header, ['descrição', 'descricao', 'histórico', 'historico']);
    if (dateIdx == null || valueIdx == null) {
      throw FormatException('CSV Inter: colunas Data e Valor são obrigatórias');
    }
    final rows = <FinanceCsvPreviewRow>[];
    for (var i = headerIndex + 1; i < lines.length; i++) {
      final cols = _split(lines[i]);
      if (cols.length <= valueIdx || cols.length <= dateIdx) continue;
      final occurredAt = _parseBrDate(cols[dateIdx]);
      final amountMinorSigned = _parseBrAmount(cols[valueIdx]);
      if (occurredAt == null || amountMinorSigned == 0) continue;
      final outflow = amountMinorSigned < 0;
      final amountMinor = amountMinorSigned.abs();
      final hist = histIdx != null && histIdx < cols.length ? cols[histIdx] : '';
      final desc = descIdx != null && descIdx < cols.length ? cols[descIdx] : '';
      final description = [
        hist.trim(),
        desc.trim(),
      ].where((s) => s.isNotEmpty).join(' — ');
      final direction =
          outflow ? TransactionDirection.outflow : TransactionDirection.inflow;
      final label = description.isEmpty ? 'Inter' : description;
      rows.add(
        FinanceCsvPreviewRow(
          accountId: accountId,
          occurredAt: occurredAt,
          descriptionOriginal: label,
          amountMinor: amountMinor,
          currency: 'BRL',
          direction: direction,
          fingerprint: computeTransactionFingerprint(
            accountId: EntityId(accountId),
            occurredAt: occurredAt,
            amountMinor: amountMinor,
            currency: 'BRL',
            direction: direction,
            descriptionOriginal: label,
          ),
        ),
      );
    }
    if (rows.isEmpty) {
      throw FormatException('CSV Inter sem lançamentos');
    }
    return rows;
  }

  static String? _findHeaderLine(String source) {
    for (final line in source.split(RegExp(r'\r?\n'))) {
      if (_isInterHeader(line)) return line;
    }
    return null;
  }

  static bool _isInterHeader(String line) {
    final n = line.toLowerCase();
    return n.contains('data') && n.contains('valor');
  }

  static List<String> _split(String line) {
    final sep = line.contains(';') ? ';' : ',';
    return line.split(sep).map((s) => s.trim().replaceAll('"', '')).toList();
  }

  static int? _col(List<String> header, List<String> names) {
    for (var i = 0; i < header.length; i++) {
      final h = header[i].toLowerCase();
      for (final name in names) {
        if (h.contains(name)) return i;
      }
    }
    return null;
  }

  static DateTime? _parseBrDate(String raw) {
    final m = RegExp(r'(\d{2})/(\d{2})/(\d{4})').firstMatch(raw.trim());
    if (m == null) return null;
    return DateTime.utc(
      int.parse(m.group(3)!),
      int.parse(m.group(2)!),
      int.parse(m.group(1)!),
    );
  }

  static int _parseBrAmount(String raw) {
    var s = raw.trim().replaceAll(r'R$', '').replaceAll(' ', '');
    final negative = s.startsWith('-') || s.startsWith('(');
    s = s.replaceAll('(', '').replaceAll(')', '').replaceAll('+', '');
    if (s.startsWith('-')) s = s.substring(1);
    if (s.contains(',')) {
      s = s.replaceAll('.', '').replaceAll(',', '');
    } else if (s.contains('.')) {
      final parts = s.split('.');
      if (parts.last.length == 2) {
        s = parts.join('');
      } else {
        s = s.replaceAll('.', '');
        s = '${s}00';
      }
    } else {
      s = '${s}00';
    }
    final n = int.tryParse(s) ?? 0;
    return negative ? -n : n;
  }

  static String? _sgml(String body, String tag) {
    final m = RegExp(
      '<$tag>([^<\\n\\r]+)',
      caseSensitive: false,
    ).firstMatch(body);
    return m?.group(1)?.trim();
  }

  static DateTime _parseOfxDate(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 8) return DateTime.utc(1970);
    return DateTime.utc(
      int.parse(digits.substring(0, 4)),
      int.parse(digits.substring(4, 6)),
      int.parse(digits.substring(6, 8)),
    );
  }
}
