import 'package:equatable/equatable.dart';

import 'id_generator.dart';
import 'ledger_transaction.dart';
import 'notification_extractor.dart';

/// Fuso fixo de São Paulo (UTC−3 desde 2019, sem horário de verão).
abstract final class PiggyBankCalendar {
  static const zoneOffset = Duration(hours: -3);

  /// Data civil em America/Sao_Paulo a partir de um instante.
  static DateTime civilDate(DateTime instant) {
    final wall = instant.toUtc().add(zoneOffset);
    return DateTime.utc(wall.year, wall.month, wall.day);
  }

  /// Data já gravada como calendário (meia-noite UTC), sem deslocar o fuso.
  static DateTime dateOnly(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  static int daysInclusive(DateTime startCivil, DateTime endCivil) {
    final start = _dateOnly(startCivil);
    final end = _dateOnly(endCivil);
    return end.difference(start).inDays + 1;
  }

  /// Próxima meia-noite de São Paulo, em UTC.
  static DateTime nextMidnightUtc(DateTime now) {
    final wall = now.toUtc().add(zoneOffset);
    final todayMidnightUtc = DateTime.utc(wall.year, wall.month, wall.day, 3);
    final next = todayMidnightUtc.add(const Duration(days: 1));
    if (!next.isAfter(now.toUtc())) {
      return next.add(const Duration(days: 1));
    }
    return next;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
}

enum PiggyBankStatus { green, yellow, red }

class PiggyBankConfig extends Equatable {
  const PiggyBankConfig({
    required this.profileId,
    required this.dailyAmountMinor,
    required this.startDate,
    required this.installmentCountsTotal,
    required this.alertWhenRed,
    required this.excludedCategoryIds,
    required this.updatedAt,
    this.endDate,
  });

  static const defaultDailyAmountMinor = 9000;

  final EntityId profileId;
  final int dailyAmountMinor;
  final DateTime startDate;
  final DateTime? endDate;
  final bool installmentCountsTotal;
  final bool alertWhenRed;
  final List<String> excludedCategoryIds;
  final DateTime updatedAt;

  factory PiggyBankConfig.initial({
    required EntityId profileId,
    required DateTime todayCivil,
    required DateTime updatedAt,
  }) {
    return PiggyBankConfig(
      profileId: profileId,
      dailyAmountMinor: defaultDailyAmountMinor,
      startDate: PiggyBankCalendar.civilDate(todayCivil),
      installmentCountsTotal: true,
      alertWhenRed: true,
      excludedCategoryIds: const [],
      updatedAt: updatedAt,
    );
  }

  PiggyBankConfig copyWith({
    int? dailyAmountMinor,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? installmentCountsTotal,
    bool? alertWhenRed,
    List<String>? excludedCategoryIds,
    DateTime? updatedAt,
  }) {
    return PiggyBankConfig(
      profileId: profileId,
      dailyAmountMinor: dailyAmountMinor ?? this.dailyAmountMinor,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      installmentCountsTotal:
          installmentCountsTotal ?? this.installmentCountsTotal,
      alertWhenRed: alertWhenRed ?? this.alertWhenRed,
      excludedCategoryIds: excludedCategoryIds ?? this.excludedCategoryIds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  void validate() {
    if (dailyAmountMinor <= 0) {
      throw ArgumentError.value(
        dailyAmountMinor,
        'dailyAmountMinor',
        'valor diário deve ser positivo',
      );
    }
    final start = PiggyBankCalendar.dateOnly(startDate);
    final end = endDate == null ? null : PiggyBankCalendar.dateOnly(endDate!);
    if (end != null && end.isBefore(start)) {
      throw ArgumentError.value(endDate, 'endDate', 'data fim antes do início');
    }
  }

  @override
  List<Object?> get props => [
        profileId,
        dailyAmountMinor,
        startDate,
        endDate,
        installmentCountsTotal,
        alertWhenRed,
        excludedCategoryIds,
        updatedAt,
      ];
}

class PiggyBankOverride extends Equatable {
  const PiggyBankOverride({
    required this.profileId,
    required this.transactionId,
    required this.excluded,
    required this.updatedAt,
    this.amountOverrideMinor,
  });

  final EntityId profileId;
  final EntityId transactionId;
  final bool excluded;
  final int? amountOverrideMinor;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        profileId,
        transactionId,
        excluded,
        amountOverrideMinor,
        updatedAt,
      ];
}

/// Lançamento do ledger já persistido pelo pipeline de finanças.
class PiggyLedgerInput extends Equatable {
  const PiggyLedgerInput({
    required this.id,
    required this.fingerprint,
    required this.amountMinor,
    required this.direction,
    required this.occurredAt,
    required this.description,
    this.categoryId,
    this.notificationText,
    this.excluded = false,
    this.amountOverrideMinor,
    this.installmentCount,
    this.amountIsPerInstallment,
  });

  final String id;
  final String fingerprint;
  final int amountMinor;
  final TransactionDirection direction;
  final DateTime occurredAt;
  final String description;
  final String? categoryId;

  /// Texto do push que originou o lançamento, quando houver.
  final String? notificationText;
  final bool excluded;
  final int? amountOverrideMinor;
  final int? installmentCount;
  final bool? amountIsPerInstallment;

  @override
  List<Object?> get props => [
        id,
        fingerprint,
        amountMinor,
        direction,
        occurredAt,
        description,
        categoryId,
        notificationText,
        excluded,
        amountOverrideMinor,
        installmentCount,
        amountIsPerInstallment,
      ];
}

class PiggyExpenseLine extends Equatable {
  const PiggyExpenseLine({
    required this.transactionId,
    required this.description,
    required this.displayMinor,
    required this.countedMinor,
    required this.excluded,
    required this.direction,
    required this.occurredAt,
    required this.counts,
  });

  final String transactionId;
  final String description;
  final int displayMinor;
  final int countedMinor;
  final bool excluded;
  final TransactionDirection direction;
  final DateTime occurredAt;
  final bool counts;

  @override
  List<Object?> get props => [
        transactionId,
        description,
        displayMinor,
        countedMinor,
        excluded,
        direction,
        occurredAt,
        counts,
      ];
}

class PiggyDay extends Equatable {
  const PiggyDay({
    required this.date,
    required this.creditedMinor,
    required this.spentMinor,
    required this.balanceMinor,
  });

  final DateTime date;
  final int creditedMinor;
  final int spentMinor;
  final int balanceMinor;

  @override
  List<Object?> get props => [date, creditedMinor, spentMinor, balanceMinor];
}

class PiggyBankSnapshot extends Equatable {
  const PiggyBankSnapshot({
    required this.balanceMinor,
    required this.spentTodayMinor,
    required this.availableTodayMinor,
    required this.status,
    required this.daysElapsed,
    required this.last7SpentMinor,
    required this.history,
    required this.todayExpenses,
    this.debtDays,
    this.daysRemaining,
    this.requiredPaceMinor,
    this.burstAmountMinor,
    this.burstDayCost,
  });

  final int balanceMinor;
  final int spentTodayMinor;
  final int availableTodayMinor;
  final int? debtDays;
  final int? daysRemaining;
  final int? requiredPaceMinor;
  final PiggyBankStatus status;
  final int daysElapsed;
  final List<int> last7SpentMinor;
  final List<PiggyDay> history;
  final List<PiggyExpenseLine> todayExpenses;
  final int? burstAmountMinor;
  final double? burstDayCost;

  @override
  List<Object?> get props => [
        balanceMinor,
        spentTodayMinor,
        availableTodayMinor,
        debtDays,
        daysRemaining,
        requiredPaceMinor,
        status,
        daysElapsed,
        last7SpentMinor,
        history,
        todayExpenses,
        burstAmountMinor,
        burstDayCost,
      ];
}

class _Prepared {
  const _Prepared({
    required this.input,
    required this.civil,
    required this.countedMinor,
    required this.contributionMinor,
    required this.counts,
    required this.excluded,
    required this.isPaymentNotice,
    required this.merchantKey,
  });

  final PiggyLedgerInput input;
  final DateTime civil;
  final int countedMinor;
  final int contributionMinor;
  final bool counts;
  final bool excluded;
  final bool isPaymentNotice;
  final String merchantKey;
}

abstract final class PiggyBankEligibility {
  static final _fixed = <RegExp>[
    RegExp(r'condom[ií]nio', caseSensitive: false),
    RegExp(r'\bphi\b', caseSensitive: false),
    RegExp(r'\bclaro\b', caseSensitive: false),
    RegExp(r'assinatura', caseSensitive: false),
    RegExp(r'pagamento de fatura', caseSensitive: false),
    RegExp(r'fatura do cart[aã]o', caseSensitive: false),
    RegExp(r'entre contas', caseSensitive: false),
  ];

  static bool matchesFixedExclusion(String description) {
    return _fixed.any((pattern) => pattern.hasMatch(description));
  }

  static bool isRefund(String description, TransactionDirection direction) {
    if (direction != TransactionDirection.inflow) return false;
    final lower = description.toLowerCase();
    return lower.contains('estorno') || lower.contains('reembolso');
  }

  static bool isPaymentNotice(String description) {
    final lower = description.toLowerCase();
    if (!lower.contains('pagamento')) return false;
    if (lower.contains(' para ')) return false;
    return true;
  }

  static String merchantKey(String description) {
    const stop = {
      'compra',
      'aprovada',
      'aprovado',
      'pagamento',
      'pix',
      'cartao',
      'cartão',
      'final',
      'de',
      'em',
      'no',
      'na',
      'para',
      'enviado',
      'recebido',
      'você',
      'voce',
    };
    final cleaned = description
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúãõâêôç ]'), ' ');
    final parts = cleaned.split(RegExp(r'\s+')).where((word) {
      if (word.length <= 2) return false;
      if (stop.contains(word)) return false;
      if (RegExp(r'^\d+$').hasMatch(word)) return false;
      return true;
    });
    return parts.join(' ');
  }
}

abstract final class PiggyBankCalculator {
  static PiggyBankSnapshot evaluate({
    required PiggyBankConfig config,
    required List<PiggyLedgerInput> inputs,
    required DateTime now,
  }) {
    final daily = config.dailyAmountMinor;
    final start = PiggyBankCalendar.dateOnly(config.startDate);
    final end = config.endDate == null
        ? null
        : PiggyBankCalendar.dateOnly(config.endDate!);
    final today = PiggyBankCalendar.civilDate(now);
    final asOf = end != null && today.isAfter(end) ? end : today;

    final prepared = _prepare(config, inputs);
    final deduped = _dedupe(prepared);
    final inPeriod = deduped.where((row) {
      if (row.civil.isBefore(start)) return false;
      if (row.civil.isAfter(asOf)) return false;
      return true;
    }).toList();

    final started = !asOf.isBefore(start);
    final daysElapsed = started ? PiggyBankCalendar.daysInclusive(start, asOf) : 0;
    final spentByDay = <DateTime, int>{};
    var spentTotal = 0;
    for (final row in inPeriod) {
      if (!row.counts) continue;
      spentTotal += row.contributionMinor;
      spentByDay[row.civil] = (spentByDay[row.civil] ?? 0) + row.contributionMinor;
    }
    final balance = started ? daily * daysElapsed - spentTotal : 0;
    final spentToday = started ? (spentByDay[asOf] ?? 0) : 0;

    int? daysRemaining;
    int? pace;
    if (end != null && started && asOf.isBefore(end)) {
      final tomorrow = asOf.add(const Duration(days: 1));
      daysRemaining = PiggyBankCalendar.daysInclusive(tomorrow, end);
      if (daysRemaining > 0) {
        pace = ((daily * daysRemaining + balance) / daysRemaining).round();
      }
    }

    final history = <PiggyDay>[];
    if (started) {
      var running = 0;
      for (var i = 0; i < daysElapsed; i++) {
        final date = start.add(Duration(days: i));
        final spent = spentByDay[date] ?? 0;
        running += daily - spent;
        history.add(
          PiggyDay(
            date: date,
            creditedMinor: daily,
            spentMinor: spent,
            balanceMinor: running,
          ),
        );
      }
    }

    final last7 = List<int>.generate(7, (index) {
      final date = asOf.subtract(Duration(days: 6 - index));
      if (!started || date.isBefore(start)) return 0;
      return spentByDay[date] ?? 0;
    });

    final todayExpenses = inPeriod
        .where((row) => row.civil == asOf && _isPiggyMovement(row))
        .map(
          (row) => PiggyExpenseLine(
            transactionId: row.input.id,
            description: row.input.description,
            displayMinor: row.countedMinor,
            countedMinor: row.counts ? row.contributionMinor : 0,
            excluded: row.excluded || !row.counts,
            direction: row.input.direction,
            occurredAt: row.input.occurredAt,
            counts: row.counts,
          ),
        )
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    final status = _status(balance, daily);
    int? burstAmount;
    double? burstDays;
    if (status == PiggyBankStatus.red) {
      final outflows = inPeriod.where((row) => row.counts && row.contributionMinor > 0).toList()
        ..sort((a, b) => a.input.occurredAt.compareTo(b.input.occurredAt));
      if (outflows.isNotEmpty && daily > 0) {
        burstAmount = outflows.last.contributionMinor;
        burstDays = burstAmount / daily;
      }
    }

    return PiggyBankSnapshot(
      balanceMinor: balance,
      spentTodayMinor: spentToday,
      availableTodayMinor: balance,
      debtDays: balance < 0 && daily > 0 ? _ceilDiv(-balance, daily) : null,
      daysRemaining: daysRemaining,
      requiredPaceMinor: pace,
      status: status,
      daysElapsed: daysElapsed,
      last7SpentMinor: last7,
      history: history,
      todayExpenses: todayExpenses,
      burstAmountMinor: burstAmount,
      burstDayCost: burstDays,
    );
  }

  static int countedAmount({
    required int amountMinor,
    required int installmentCount,
    required bool amountIsPerInstallment,
    required bool countTotal,
    int? amountOverrideMinor,
  }) {
    if (amountOverrideMinor != null) return amountOverrideMinor;
    if (installmentCount <= 1) return amountMinor;
    if (countTotal) {
      return amountIsPerInstallment
          ? amountMinor * installmentCount
          : amountMinor;
    }
    if (amountIsPerInstallment) return amountMinor;
    return (amountMinor / installmentCount).round();
  }

  static List<_Prepared> _prepare(
    PiggyBankConfig config,
    List<PiggyLedgerInput> inputs,
  ) {
    final excludedCategories = config.excludedCategoryIds.toSet();
    return [
      for (final input in inputs) _prepareOne(config, input, excludedCategories),
    ];
  }

  static _Prepared _prepareOne(
    PiggyBankConfig config,
    PiggyLedgerInput input,
    Set<String> excludedCategories,
  ) {
    final plan = input.notificationText == null
        ? null
        : FinanceNotificationExtractor.installmentPlan(input.notificationText!);
    final count = input.installmentCount ?? plan?.count ?? 1;
    final perInstallment =
        input.amountIsPerInstallment ?? plan?.perInstallment ?? false;
    final counted = countedAmount(
      amountMinor: input.amountMinor,
      installmentCount: count,
      amountIsPerInstallment: perInstallment,
      countTotal: config.installmentCountsTotal,
      amountOverrideMinor: input.amountOverrideMinor,
    );
    final fixed = PiggyBankEligibility.matchesFixedExclusion(input.description);
    final categoryExcluded = input.categoryId != null &&
        excludedCategories.contains(input.categoryId);
    final refund = PiggyBankEligibility.isRefund(
      input.description,
      input.direction,
    );
    final userExcluded = input.excluded;
    final structurallyOut = userExcluded || categoryExcluded || fixed;
    var counts = false;
    var contribution = 0;
    if (!structurallyOut && input.direction == TransactionDirection.outflow) {
      counts = true;
      contribution = counted;
    } else if (!structurallyOut && refund) {
      counts = true;
      contribution = -counted;
    }
    return _Prepared(
      input: input,
      civil: PiggyBankCalendar.civilDate(input.occurredAt),
      countedMinor: counted,
      contributionMinor: contribution,
      counts: counts,
      excluded: structurallyOut,
      isPaymentNotice: PiggyBankEligibility.isPaymentNotice(input.description),
      merchantKey: PiggyBankEligibility.merchantKey(input.description),
    );
  }

  static bool _isPiggyMovement(_Prepared row) {
    if (row.input.direction == TransactionDirection.outflow) return true;
    return PiggyBankEligibility.isRefund(
      row.input.description,
      row.input.direction,
    );
  }

  static List<_Prepared> _dedupe(List<_Prepared> rows) {
    final byFingerprint = <String, _Prepared>{};
    final ordered = [...rows]
      ..sort((a, b) {
        final rank = (a.isPaymentNotice ? 1 : 0) - (b.isPaymentNotice ? 1 : 0);
        if (rank != 0) return rank;
        return a.input.occurredAt.compareTo(b.input.occurredAt);
      });
    for (final row in ordered) {
      final key = row.input.fingerprint.trim().isEmpty
          ? row.input.id
          : row.input.fingerprint.trim();
      byFingerprint.putIfAbsent(key, () => row);
    }
    final unique = byFingerprint.values.toList();
    final contentKept = <_Prepared>[];
    for (final row in unique) {
      if (row.merchantKey.isEmpty) {
        contentKept.add(row);
        continue;
      }
      final key = _contentKey(row);
      final prior = contentKept.where((other) => _contentKey(other) == key);
      final collapses = prior.any(
        (other) =>
            _importedFingerprint(row.input.fingerprint) ||
            _importedFingerprint(other.input.fingerprint),
      );
      if (collapses) continue;
      contentKept.add(row);
    }
    final drop = <_Prepared>{};
    for (final payment in contentKept) {
      if (!payment.counts || !payment.isPaymentNotice) continue;
      if (payment.input.direction != TransactionDirection.outflow) continue;
      final shadowed = contentKept.any((other) {
        if (identical(other, payment) || !other.counts) return false;
        if (other.isPaymentNotice) return false;
        if (other.input.direction != TransactionDirection.outflow) return false;
        if (other.civil != payment.civil) return false;
        return other.input.amountMinor == payment.input.amountMinor;
      });
      if (shadowed) drop.add(payment);
    }
    return contentKept.where((row) => !drop.contains(row)).toList();
  }

  static String _contentKey(_Prepared row) {
    return '${row.civil.toIso8601String()}|${row.input.direction.name}|${row.input.amountMinor}|${row.merchantKey}';
  }

  static bool _importedFingerprint(String fingerprint) {
    return fingerprint.startsWith('notif:') || fingerprint.startsWith('ofx:');
  }

  static PiggyBankStatus _status(int balanceMinor, int dailyMinor) {
    if (balanceMinor < 0) return PiggyBankStatus.red;
    if (dailyMinor > 0 && balanceMinor * 5 >= dailyMinor) {
      return PiggyBankStatus.green;
    }
    return PiggyBankStatus.yellow;
  }

  static int _ceilDiv(int numerator, int denominator) {
    return (numerator + denominator - 1) ~/ denominator;
  }
}

abstract final class PiggyMoney {
  static String format(int minor) {
    final negative = minor < 0;
    final abs = minor.abs();
    final reais = _group(abs ~/ 100);
    final cents = (abs % 100).toString().padLeft(2, '0');
    final body = 'R\$ $reais,$cents';
    return negative ? '-$body' : body;
  }

  static String daysCost(double days) {
    final text = days.toStringAsFixed(1).replaceAll('.', ',');
    return 'essa compra custou $text dias';
  }

  static String _group(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write('.');
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }
}

abstract final class PiggyPublishPolicy {
  static bool shouldAlert({
    required bool alertWhenRed,
    required PiggyBankStatus status,
    required String? previousStatus,
  }) {
    return alertWhenRed &&
        status == PiggyBankStatus.red &&
        previousStatus != null &&
        previousStatus != PiggyBankStatus.red.name;
  }
}

class PiggyWidgetPayload extends Equatable {
  const PiggyWidgetPayload({
    required this.balanceLabel,
    required this.spentTodayLabel,
    required this.availableLabel,
    required this.debtLabel,
    required this.statusName,
    required this.weekCsv,
    required this.alertMessage,
    required this.alertWhenRed,
    required this.status,
  });

  final String balanceLabel;
  final String spentTodayLabel;
  final String availableLabel;
  final String debtLabel;
  final String statusName;
  final String weekCsv;
  final String alertMessage;
  final bool alertWhenRed;
  final PiggyBankStatus status;

  factory PiggyWidgetPayload.fromSnapshot(
    PiggyBankSnapshot snapshot, {
    required bool alertWhenRed,
  }) {
    final debt = snapshot.debtDays;
    final burst = snapshot.burstDayCost;
    return PiggyWidgetPayload(
      balanceLabel: PiggyMoney.format(snapshot.balanceMinor),
      spentTodayLabel: 'Hoje: ${PiggyMoney.format(snapshot.spentTodayMinor)} gastos',
      availableLabel:
          'Pode gastar hoje: ${PiggyMoney.format(snapshot.availableTodayMinor)}',
      debtLabel: debt == null ? '' : '−$debt dias',
      statusName: snapshot.status.name,
      weekCsv: snapshot.last7SpentMinor.join(','),
      alertMessage: burst == null
          ? 'O cofrinho ficou negativo.'
          : 'O cofrinho ficou negativo. ${PiggyMoney.daysCost(burst)}.',
      alertWhenRed: alertWhenRed,
      status: snapshot.status,
    );
  }

  Map<String, Object?> toChannelMap({required bool crossedIntoRed}) {
    return {
      'balance': balanceLabel,
      'spentToday': spentTodayLabel,
      'available': availableLabel,
      'debt': debtLabel,
      'status': statusName,
      'week': weekCsv,
      'alert': alertWhenRed && crossedIntoRed,
      'message': alertMessage,
    };
  }

  @override
  List<Object?> get props => [
        balanceLabel,
        spentTodayLabel,
        availableLabel,
        debtLabel,
        statusName,
        weekCsv,
        alertMessage,
        alertWhenRed,
        status,
      ];
}
