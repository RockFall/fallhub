import 'package:equatable/equatable.dart';

import 'id_generator.dart';

enum InventoryCategory {
  electronics,
  document,
  clothing,
  tool,
  consumable,
  media,
  other,
}

enum InventoryItemStatus {
  active,
  stored,
  lent,
  disposed,
  archived;

  bool get isHiddenFromActiveList =>
      this == disposed || this == archived;
}

/// Personal inventory item (ADR-024). Local record only; no market valuation.
class InventoryItem extends Equatable {
  const InventoryItem({
    required this.id,
    required this.profileId,
    required this.name,
    required this.category,
    required this.status,
    this.locationLabel,
    this.notes,
    this.tags = const [],
    this.purchaseDate,
    this.purchasePriceMinor,
    this.purchaseCurrency,
    this.warrantyEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final String name;
  final InventoryCategory category;
  final InventoryItemStatus status;
  final String? locationLabel;
  final String? notes;
  final List<String> tags;
  final DateTime? purchaseDate;
  final int? purchasePriceMinor;
  final String? purchaseCurrency;
  final DateTime? warrantyEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory InventoryItem.create({
    required EntityId id,
    required EntityId profileId,
    required String name,
    required InventoryCategory category,
    InventoryItemStatus status = InventoryItemStatus.active,
    String? locationLabel,
    String? notes,
    List<String> tags = const [],
    DateTime? purchaseDate,
    int? purchasePriceMinor,
    String? purchaseCurrency,
    DateTime? warrantyEnd,
    required DateTime createdAt,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Inventory item name cannot be empty');
    }
    if (purchasePriceMinor != null && purchasePriceMinor < 0) {
      throw ArgumentError('purchasePriceMinor cannot be negative');
    }
    final trimmedLocation = locationLabel?.trim();
    final trimmedNotes = notes?.trim();
    final trimmedCurrency = purchaseCurrency?.trim();
    return InventoryItem(
      id: id,
      profileId: profileId,
      name: trimmedName,
      category: category,
      status: status,
      locationLabel: (trimmedLocation == null || trimmedLocation.isEmpty)
          ? null
          : trimmedLocation,
      notes: (trimmedNotes == null || trimmedNotes.isEmpty) ? null : trimmedNotes,
      tags: tags
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      purchaseDate: purchaseDate,
      purchasePriceMinor: purchasePriceMinor,
      purchaseCurrency: (trimmedCurrency == null || trimmedCurrency.isEmpty)
          ? null
          : trimmedCurrency.toUpperCase(),
      warrantyEnd: warrantyEnd,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  InventoryItem copyWith({
    String? name,
    InventoryCategory? category,
    InventoryItemStatus? status,
    String? locationLabel,
    bool clearLocationLabel = false,
    String? notes,
    bool clearNotes = false,
    List<String>? tags,
    DateTime? purchaseDate,
    bool clearPurchaseDate = false,
    int? purchasePriceMinor,
    bool clearPurchasePrice = false,
    String? purchaseCurrency,
    bool clearPurchaseCurrency = false,
    DateTime? warrantyEnd,
    bool clearWarrantyEnd = false,
    DateTime? updatedAt,
  }) {
    final nextName = name?.trim() ?? this.name;
    if (nextName.isEmpty) {
      throw ArgumentError('Inventory item name cannot be empty');
    }
    final nextPrice =
        clearPurchasePrice ? null : (purchasePriceMinor ?? this.purchasePriceMinor);
    if (nextPrice != null && nextPrice < 0) {
      throw ArgumentError('purchasePriceMinor cannot be negative');
    }
    final nextNotes = clearNotes
        ? null
        : (notes != null
            ? (notes.trim().isEmpty ? null : notes.trim())
            : this.notes);
    final nextLocation = clearLocationLabel
        ? null
        : (locationLabel != null
            ? (locationLabel.trim().isEmpty ? null : locationLabel.trim())
            : this.locationLabel);
    final nextCurrency = clearPurchaseCurrency
        ? null
        : (purchaseCurrency != null
            ? (purchaseCurrency.trim().isEmpty
                ? null
                : purchaseCurrency.trim().toUpperCase())
            : this.purchaseCurrency);
    return InventoryItem(
      id: id,
      profileId: profileId,
      name: nextName,
      category: category ?? this.category,
      status: status ?? this.status,
      locationLabel: nextLocation,
      notes: nextNotes,
      tags: tags ?? this.tags,
      purchaseDate:
          clearPurchaseDate ? null : (purchaseDate ?? this.purchaseDate),
      purchasePriceMinor: nextPrice,
      purchaseCurrency: nextCurrency,
      warrantyEnd: clearWarrantyEnd ? null : (warrantyEnd ?? this.warrantyEnd),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        name,
        category,
        status,
        locationLabel,
        notes,
        tags,
        purchaseDate,
        purchasePriceMinor,
        purchaseCurrency,
        warrantyEnd,
        createdAt,
        updatedAt,
      ];
}
