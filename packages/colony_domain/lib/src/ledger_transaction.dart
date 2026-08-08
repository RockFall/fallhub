import 'package:equatable/equatable.dart';

import 'id_generator.dart';
import 'transaction_fingerprint.dart';

enum TransactionDirection {
  inflow,
  outflow,
}

class LedgerTransaction extends Equatable {
  const LedgerTransaction({
    required this.id,
    required this.profileId,
    required this.accountId,
    required this.occurredAt,
    required this.descriptionOriginal,
    required this.amountMinor,
    required this.currency,
    required this.direction,
    required this.fingerprint,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.notes,
  });

  final EntityId id;
  final EntityId profileId;
  final EntityId accountId;
  final DateTime occurredAt;
  final String descriptionOriginal;
  final int amountMinor;
  final String currency;
  final TransactionDirection direction;
  final EntityId? categoryId;
  final String? notes;
  final String fingerprint;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory LedgerTransaction.create({
    required EntityId id,
    required EntityId profileId,
    required EntityId accountId,
    required DateTime occurredAt,
    required String descriptionOriginal,
    required int amountMinor,
    required String currency,
    required TransactionDirection direction,
    EntityId? categoryId,
    String? notes,
    String? fingerprint,
    required DateTime createdAt,
  }) {
    final description = descriptionOriginal.trim();
    final provided = fingerprint?.trim();
    final resolvedFingerprint = (provided != null && provided.isNotEmpty)
        ? provided
        : computeTransactionFingerprint(
            accountId: accountId,
            occurredAt: occurredAt,
            amountMinor: amountMinor,
            currency: currency,
            direction: direction,
            descriptionOriginal: description,
          );
    return LedgerTransaction(
      id: id,
      profileId: profileId,
      accountId: accountId,
      occurredAt: occurredAt,
      descriptionOriginal: description,
      amountMinor: amountMinor,
      currency: currency,
      direction: direction,
      categoryId: categoryId,
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      fingerprint: resolvedFingerprint,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  LedgerTransaction copyWith({
    EntityId? accountId,
    DateTime? occurredAt,
    String? descriptionOriginal,
    int? amountMinor,
    String? currency,
    TransactionDirection? direction,
    EntityId? categoryId,
    bool clearCategoryId = false,
    String? notes,
    bool clearNotes = false,
    DateTime? updatedAt,
  }) {
    final nextAccountId = accountId ?? this.accountId;
    final nextDescription = descriptionOriginal ?? this.descriptionOriginal;
    final nextOccurredAt = occurredAt ?? this.occurredAt;
    final nextAmount = amountMinor ?? this.amountMinor;
    final nextCurrency = currency ?? this.currency;
    final nextDirection = direction ?? this.direction;
    final fingerprint = computeTransactionFingerprint(
      accountId: nextAccountId,
      occurredAt: nextOccurredAt,
      amountMinor: nextAmount,
      currency: nextCurrency,
      direction: nextDirection,
      descriptionOriginal: nextDescription,
    );
    return LedgerTransaction(
      id: id,
      profileId: profileId,
      accountId: nextAccountId,
      occurredAt: nextOccurredAt,
      descriptionOriginal: nextDescription,
      amountMinor: nextAmount,
      currency: nextCurrency,
      direction: nextDirection,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      notes: clearNotes ? null : (notes ?? this.notes),
      fingerprint: fingerprint,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get signedAmountMinor =>
      direction == TransactionDirection.inflow ? amountMinor : -amountMinor;

  @override
  List<Object?> get props => [
        id,
        profileId,
        accountId,
        occurredAt,
        descriptionOriginal,
        amountMinor,
        currency,
        direction,
        categoryId,
        notes,
        fingerprint,
        createdAt,
        updatedAt,
      ];
}
