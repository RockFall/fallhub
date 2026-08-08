import 'financial_account.dart';

abstract final class FinanceDisplayPolicy {
  static bool shouldMask({
    required FinancialAccount account,
    required bool showValues,
  }) {
    if (showValues) return false;
    return account.sensitiveDisplayMode == SensitiveDisplayMode.hidden;
  }

  static String formatAmountMinor({
    required int amountMinor,
    required String currency,
    required bool masked,
  }) {
    if (masked) return '••••';
    final major = amountMinor.abs() / 100;
    final sign = amountMinor < 0 ? '-' : '';
    final formatted = major.toStringAsFixed(2).replaceAll('.', ',');
    return '$sign$formatted $currency';
  }

  static String formatSignedAmountMinor({
    required int signedAmountMinor,
    required String currency,
    required bool masked,
  }) {
    if (masked) return '••••';
    final sign = signedAmountMinor >= 0 ? '+' : '-';
    return '$sign${formatAmountMinor(
      amountMinor: signedAmountMinor.abs(),
      currency: currency,
      masked: false,
    )}';
  }
}
