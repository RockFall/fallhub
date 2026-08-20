import 'captured_notification.dart';
import 'financial_account.dart';
import 'ledger_transaction.dart';

abstract interface class NotificationExtractor {
  String get id;
  NotificationExtractorKind? inspect(NotificationExtractInput input);
}

/// Runs extractors in order; first non-ignored/unknown finance win is enough.
abstract final class NotificationExtractionPipeline {
  static const extractors = <NotificationExtractor>[
    OtpNotificationFilter(),
    FinanceNotificationExtractor(),
  ];

  static NotificationExtractorKind classify(NotificationExtractInput input) {
    for (final extractor in extractors) {
      final kind = extractor.inspect(input);
      if (kind == NotificationExtractorKind.ignored) {
        return NotificationExtractorKind.ignored;
      }
      if (kind == NotificationExtractorKind.finance) {
        return NotificationExtractorKind.finance;
      }
    }
    return NotificationExtractorKind.unknown;
  }
}

/// Drops short numeric codes (2FA) so they never become ledger rows.
class OtpNotificationFilter implements NotificationExtractor {
  const OtpNotificationFilter();

  @override
  String get id => 'otp';

  @override
  NotificationExtractorKind? inspect(NotificationExtractInput input) {
    final combined = input.combined.trim();
    if (RegExp(r'^\d{4,8}$').hasMatch(combined)) {
      return NotificationExtractorKind.ignored;
    }
    final lower = combined.toLowerCase();
    if (lower.contains('código de verificação') ||
        lower.contains('codigo de verificacao') ||
        lower.contains('verification code') ||
        (lower.contains('otp') && RegExp(r'\b\d{4,8}\b').hasMatch(combined))) {
      return NotificationExtractorKind.ignored;
    }
    return null;
  }
}

/// Débito (Pix/TED/conta) e crédito (cartão) a partir do texto do push.
class FinanceNotificationExtractor implements NotificationExtractor {
  const FinanceNotificationExtractor();

  @override
  String get id => 'finance';

  static final _amount = RegExp(
    r'R\$\s*(\d{1,3}(?:\.\d{3})*,\d{2}|\d+,\d{2}|\d+)',
    caseSensitive: false,
  );

  @override
  NotificationExtractorKind? inspect(NotificationExtractInput input) {
    return tryParse(input) == null ? null : NotificationExtractorKind.finance;
  }

  static FinanceSpendCandidate? tryParse(NotificationExtractInput input) {
    final text = input.combined;
    final lower = text.toLowerCase();
    if (!_looksFinancial(lower, input.packageName)) return null;
    final amountMinor = _parseAmountMinor(text);
    if (amountMinor == null || amountMinor <= 0) return null;

    final inflow = _isInflow(lower);
    final credit = _isCreditCard(lower, input.packageName);
    final merchant = _merchant(text, lower);
    return FinanceSpendCandidate(
      amountMinor: amountMinor,
      currency: 'BRL',
      direction:
          inflow ? TransactionDirection.inflow : TransactionDirection.outflow,
      accountType: credit
          ? FinancialAccountType.creditCard
          : FinancialAccountType.checking,
      description: merchant,
      occurredAt: input.postedAt.toUtc(),
      confidence: credit || lower.contains('pix') ? 0.9 : 0.7,
    );
  }

  static bool _looksFinancial(String lower, String packageName) {
    const hints = [
      'compra',
      'pix',
      'ted',
      'transfer',
      'pagamento',
      'pagou',
      'recebeu',
      'cartão',
      'cartao',
      'débito',
      'debito',
      'crédito',
      'credito',
      'fatura',
      'cashback',
      'aprovada',
      'aprovado',
    ];
    if (hints.any(lower.contains)) return true;
    final pkg = packageName.toLowerCase();
    return pkg.contains('banco') ||
        pkg.contains('inter') ||
        pkg.contains('nubank') ||
        pkg.contains('itau') ||
        pkg.contains('bradesco') ||
        pkg.contains('picpay');
  }

  static bool _isInflow(String lower) {
    if (lower.contains('cashback') ||
        lower.contains('estorno') ||
        lower.contains('reembolso') ||
        lower.contains('recebeu') ||
        lower.contains('recebido') ||
        lower.contains('você recebeu') ||
        lower.contains('voce recebeu') ||
        lower.contains('pix recebido')) {
      return true;
    }
    return false;
  }

  static bool _isCreditCard(String lower, String packageName) {
    if (lower.contains('cartão') ||
        lower.contains('cartao') ||
        lower.contains('crédito') ||
        lower.contains('credito') ||
        lower.contains('fatura') ||
        lower.contains('final ')) {
      return true;
    }
    return false;
  }

  static String _merchant(String text, String lower) {
    final em = RegExp(
      r'(?:em|no|na|para)\s+([A-ZÁÉÍÓÚÂÊÔÃÕ0-9][A-Za-zÁ-ú0-9&* .\-]{2,40})',
    ).firstMatch(text);
    if (em != null) {
      return em.group(1)!.trim();
    }
    final title = text.split('\n').first.trim();
    if (title.isNotEmpty && title.length < 80) return title;
    return 'Movimentação';
  }

  static int? _parseAmountMinor(String text) {
    final match = _amount.firstMatch(text);
    if (match == null) return null;
    var raw = match.group(1)!;
    if (raw.contains(',')) {
      raw = raw.replaceAll('.', '').replaceAll(',', '');
    } else {
      raw = '${raw}00';
    }
    return int.tryParse(raw);
  }
}
