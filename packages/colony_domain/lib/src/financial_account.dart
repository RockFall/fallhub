import 'package:equatable/equatable.dart';

import 'id_generator.dart';

enum FinancialAccountType {
  checking,
  savings,
  cash,
  creditCard,
  investment,
  receivable,
  payable,
  other,
}

enum SensitiveDisplayMode {
  visible,
  hidden,
}

class FinancialAccount extends Equatable {
  const FinancialAccount({
    required this.id,
    required this.profileId,
    required this.entityId,
    required this.institution,
    required this.name,
    required this.type,
    required this.currency,
    required this.currentBalanceMinor,
    required this.balanceAsOf,
    required this.includeInNetWorth,
    required this.sensitiveDisplayMode,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final EntityId entityId;
  final String institution;
  final String name;
  final FinancialAccountType type;
  final String currency;
  final int currentBalanceMinor;
  final DateTime? balanceAsOf;
  final bool includeInNetWorth;
  final SensitiveDisplayMode sensitiveDisplayMode;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FinancialAccount.create({
    required EntityId id,
    required EntityId profileId,
    required EntityId entityId,
    required String institution,
    required String name,
    required FinancialAccountType type,
    required String currency,
    int currentBalanceMinor = 0,
    DateTime? balanceAsOf,
    bool includeInNetWorth = true,
    SensitiveDisplayMode sensitiveDisplayMode = SensitiveDisplayMode.hidden,
    bool isArchived = false,
    required DateTime createdAt,
  }) {
    return FinancialAccount(
      id: id,
      profileId: profileId,
      entityId: entityId,
      institution: institution.trim(),
      name: name.trim(),
      type: type,
      currency: currency,
      currentBalanceMinor: currentBalanceMinor,
      balanceAsOf: balanceAsOf,
      includeInNetWorth: includeInNetWorth,
      sensitiveDisplayMode: sensitiveDisplayMode,
      isArchived: isArchived,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  FinancialAccount copyWith({
    String? institution,
    String? name,
    FinancialAccountType? type,
    String? currency,
    int? currentBalanceMinor,
    DateTime? balanceAsOf,
    bool clearBalanceAsOf = false,
    bool? includeInNetWorth,
    SensitiveDisplayMode? sensitiveDisplayMode,
    bool? isArchived,
    DateTime? updatedAt,
  }) {
    return FinancialAccount(
      id: id,
      profileId: profileId,
      entityId: entityId,
      institution: institution ?? this.institution,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      currentBalanceMinor: currentBalanceMinor ?? this.currentBalanceMinor,
      balanceAsOf: clearBalanceAsOf ? null : (balanceAsOf ?? this.balanceAsOf),
      includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
      sensitiveDisplayMode: sensitiveDisplayMode ?? this.sensitiveDisplayMode,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        entityId,
        institution,
        name,
        type,
        currency,
        currentBalanceMinor,
        balanceAsOf,
        includeInNetWorth,
        sensitiveDisplayMode,
        isArchived,
        createdAt,
        updatedAt,
      ];
}
