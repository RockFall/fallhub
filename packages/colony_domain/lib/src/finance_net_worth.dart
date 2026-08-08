import 'finance_display_policy.dart';
import 'financial_account.dart';

/// Aggregated net worth for one currency (MVP: no FX conversion).
class NetWorthByCurrency {
  const NetWorthByCurrency({
    required this.currency,
    required this.totalMinor,
    required this.includedAccountCount,
  });

  final String currency;
  final int totalMinor;
  final int includedAccountCount;
}

/// Lite net-worth: sum balances of accounts with [FinancialAccount.includeInNetWorth].
/// Multi-currency totals stay separate (no conversion). Masking is all-or-nothing
/// when any included account is sensitive and values are hidden.
abstract final class FinanceNetWorthPolicy {
  static List<NetWorthByCurrency> compute({
    required List<FinancialAccount> accounts,
    required Map<String, int> balancesByAccountId,
  }) {
    final totals = <String, int>{};
    final counts = <String, int>{};

    for (final account in accounts) {
      if (account.isArchived || !account.includeInNetWorth) continue;
      final balance = balancesByAccountId[account.id.value] ??
          account.currentBalanceMinor;
      totals[account.currency] = (totals[account.currency] ?? 0) + balance;
      counts[account.currency] = (counts[account.currency] ?? 0) + 1;
    }

    final currencies = totals.keys.toList()..sort();
    return [
      for (final currency in currencies)
        NetWorthByCurrency(
          currency: currency,
          totalMinor: totals[currency]!,
          includedAccountCount: counts[currency]!,
        ),
    ];
  }

  /// True when any included account would be masked (privacy: hide whole sum).
  static bool shouldMaskTotal({
    required List<FinancialAccount> accounts,
    required bool showValues,
  }) {
    if (showValues) return false;
    for (final account in accounts) {
      if (account.isArchived || !account.includeInNetWorth) continue;
      if (FinanceDisplayPolicy.shouldMask(
        account: account,
        showValues: showValues,
      )) {
        return true;
      }
    }
    return false;
  }
}
