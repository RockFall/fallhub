import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';

class PiggyEvaluation {
  const PiggyEvaluation({required this.config, required this.snapshot});

  final PiggyBankConfig config;
  final PiggyBankSnapshot snapshot;
}

abstract final class PiggyBankQuery {
  static Future<PiggyEvaluation> load(
    ColonyRepositories repos,
    EntityId profileId,
    DateTime now,
  ) async {
    final config = await repos.piggy.ensureConfig(
      profileId: profileId,
      now: now,
    );
    final transactions = await repos.finance.listTransactions(profileId);
    final notifications =
        await repos.integrations.listCapturedNotifications(profileId);
    final overrides = await repos.piggy.listOverrides(profileId);
    final textByTransaction = <String, String>{};
    for (final notification in notifications) {
      final transactionId = notification.ledgerTransactionId?.value;
      if (transactionId == null) continue;
      textByTransaction[transactionId] = notification.combinedText;
    }
    final overrideByTransaction = {
      for (final override in overrides) override.transactionId.value: override,
    };
    final inputs = [
      for (final transaction in transactions)
        PiggyLedgerInput(
          id: transaction.id.value,
          fingerprint: transaction.fingerprint,
          amountMinor: transaction.amountMinor,
          direction: transaction.direction,
          occurredAt: transaction.occurredAt,
          description: transaction.descriptionOriginal,
          categoryId: transaction.categoryId?.value,
          notificationText: textByTransaction[transaction.id.value],
          excluded:
              overrideByTransaction[transaction.id.value]?.excluded ?? false,
          amountOverrideMinor:
              overrideByTransaction[transaction.id.value]?.amountOverrideMinor,
        ),
    ];
    return PiggyEvaluation(
      config: config,
      snapshot: PiggyBankCalculator.evaluate(
        config: config,
        inputs: inputs,
        now: now,
      ),
    );
  }
}
