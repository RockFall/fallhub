import 'package:equatable/equatable.dart';

import 'id_generator.dart';
import 'transaction_category.dart';

/// Monthly category spending limit (spec §23.7 lite — limite mensal).
/// One row per (profile, category, currency); spent is computed for the
/// current calendar month from ledger outflows.
class CategoryBudget extends Equatable {
  const CategoryBudget({
    required this.id,
    required this.profileId,
    required this.categoryId,
    required this.currency,
    required this.limitAmountMinor,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final EntityId categoryId;
  final String currency;
  final int limitAmountMinor;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CategoryBudget.create({
    required EntityId id,
    required EntityId profileId,
    required EntityId categoryId,
    required String currency,
    required int limitAmountMinor,
    required DateTime createdAt,
  }) {
    TransactionCategoryPolicy.validateCategoryId(categoryId);
    final cat = TransactionCategoryPolicy.fromCategoryId(categoryId);
    if (cat == null || cat == TransactionCategory.income) {
      throw ArgumentError.value(
        categoryId,
        'categoryId',
        'budget requires an outflow category',
      );
    }
    final trimmedCurrency = currency.trim().toUpperCase();
    if (trimmedCurrency.isEmpty) {
      throw ArgumentError('CategoryBudget currency cannot be empty');
    }
    if (limitAmountMinor <= 0) {
      throw ArgumentError.value(
        limitAmountMinor,
        'limitAmountMinor',
        'must be positive',
      );
    }
    return CategoryBudget(
      id: id,
      profileId: profileId,
      categoryId: categoryId,
      currency: trimmedCurrency,
      limitAmountMinor: limitAmountMinor,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  CategoryBudget copyWith({
    EntityId? categoryId,
    String? currency,
    int? limitAmountMinor,
    DateTime? updatedAt,
  }) {
    final nextCategoryId = categoryId ?? this.categoryId;
    TransactionCategoryPolicy.validateCategoryId(nextCategoryId);
    final cat = TransactionCategoryPolicy.fromCategoryId(nextCategoryId);
    if (cat == null || cat == TransactionCategory.income) {
      throw ArgumentError.value(
        nextCategoryId,
        'categoryId',
        'budget requires an outflow category',
      );
    }
    final nextCurrency = (currency ?? this.currency).trim().toUpperCase();
    if (nextCurrency.isEmpty) {
      throw ArgumentError('CategoryBudget currency cannot be empty');
    }
    final nextLimit = limitAmountMinor ?? this.limitAmountMinor;
    if (nextLimit <= 0) {
      throw ArgumentError.value(
        nextLimit,
        'limitAmountMinor',
        'must be positive',
      );
    }
    return CategoryBudget(
      id: id,
      profileId: profileId,
      categoryId: nextCategoryId,
      currency: nextCurrency,
      limitAmountMinor: nextLimit,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        categoryId,
        currency,
        limitAmountMinor,
        createdAt,
        updatedAt,
      ];
}
