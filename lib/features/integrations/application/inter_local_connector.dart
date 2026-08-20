import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

/// Local Inter connector: file history lives in the ledger; live spends
/// arrive via notification ingest (ADR-011).
class InterLocalConnector implements BankConnector {
  InterLocalConnector(this._ref);

  final Ref _ref;

  Future<ColonyProfile> _requireProfile() async {
    final profile = await _ref.read(profileProvider.future);
    if (profile == null) {
      throw StateError('Perfil não encontrado');
    }
    return profile;
  }

  @override
  Future<List<FinancialAccount>> accounts() async {
    final profile = await _requireProfile();
    final all =
        await _ref.read(repositoriesProvider).finance.listAccounts(profile.id);
    return all
        .where((a) => a.institution.trim().toLowerCase() == 'inter')
        .toList();
  }

  @override
  Future<List<LedgerTransaction>> transactions() async {
    final interIds = {for (final a in await accounts()) a.id.value};
    final profile = await _requireProfile();
    final all = await _ref
        .read(repositoriesProvider)
        .finance
        .listTransactions(profile.id);
    return all.where((t) => interIds.contains(t.accountId.value)).toList();
  }

  @override
  Stream<FinanceSpendCandidate> liveTransactions() async* {
    final profile = await _requireProfile();
    yield* _ref
        .read(repositoriesProvider)
        .integrations
        .watchCapturedNotifications(profile.id)
        .map((rows) {
      return [
        for (final row in rows)
          if (row.bookedAsFinance)
            FinanceNotificationExtractor.tryParse(row.extractInput),
      ].whereType<FinanceSpendCandidate>();
    }).expand((candidates) => candidates);
  }
}
