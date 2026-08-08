import 'package:equatable/equatable.dart';

import 'id_generator.dart';

/// Domestic maintenance task (ADR-029 / §25.3). Local record only.
class HomeMaintenanceTask extends Equatable {
  const HomeMaintenanceTask({
    required this.id,
    required this.profileId,
    required this.title,
    required this.systemOrItem,
    this.cadenceDays,
    this.nextDueAt,
    this.lastDoneAt,
    this.vendorLabel,
    this.estimatedCostMinor,
    this.currency,
    this.notes,
    this.linkedInventoryItemId,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final String title;
  final String systemOrItem;
  final int? cadenceDays;
  final DateTime? nextDueAt;
  final DateTime? lastDoneAt;
  final String? vendorLabel;
  final int? estimatedCostMinor;
  final String? currency;
  final String? notes;
  final EntityId? linkedInventoryItemId;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isArchived => archivedAt != null;

  factory HomeMaintenanceTask.create({
    required EntityId id,
    required EntityId profileId,
    required String title,
    required String systemOrItem,
    int? cadenceDays,
    DateTime? nextDueAt,
    String? vendorLabel,
    int? estimatedCostMinor,
    String? currency,
    String? notes,
    EntityId? linkedInventoryItemId,
    required DateTime createdAt,
  }) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('HomeMaintenanceTask title cannot be empty');
    }
    final trimmedSystem = systemOrItem.trim();
    if (trimmedSystem.isEmpty) {
      throw ArgumentError('HomeMaintenanceTask systemOrItem cannot be empty');
    }
    if (cadenceDays != null && cadenceDays <= 0) {
      throw ArgumentError('cadenceDays must be positive');
    }
    if (estimatedCostMinor != null && estimatedCostMinor < 0) {
      throw ArgumentError('estimatedCostMinor cannot be negative');
    }
    final trimmedVendor = vendorLabel?.trim();
    final trimmedNotes = notes?.trim();
    final trimmedCurrency = currency?.trim();
    return HomeMaintenanceTask(
      id: id,
      profileId: profileId,
      title: trimmedTitle,
      systemOrItem: trimmedSystem,
      cadenceDays: cadenceDays,
      nextDueAt: nextDueAt,
      vendorLabel: (trimmedVendor == null || trimmedVendor.isEmpty)
          ? null
          : trimmedVendor,
      estimatedCostMinor: estimatedCostMinor,
      currency: (trimmedCurrency == null || trimmedCurrency.isEmpty)
          ? null
          : trimmedCurrency.toUpperCase(),
      notes: (trimmedNotes == null || trimmedNotes.isEmpty) ? null : trimmedNotes,
      linkedInventoryItemId: linkedInventoryItemId,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  /// Marks the task done; advances [nextDueAt] when [cadenceDays] is set.
  HomeMaintenanceTask markDone(DateTime doneAt) {
    final utc = doneAt.toUtc();
    return copyWith(
      lastDoneAt: utc,
      nextDueAt: cadenceDays == null
          ? nextDueAt
          : utc.add(Duration(days: cadenceDays!)),
      updatedAt: utc,
    );
  }

  HomeMaintenanceTask copyWith({
    String? title,
    String? systemOrItem,
    int? cadenceDays,
    bool clearCadenceDays = false,
    DateTime? nextDueAt,
    bool clearNextDueAt = false,
    DateTime? lastDoneAt,
    bool clearLastDoneAt = false,
    String? vendorLabel,
    bool clearVendorLabel = false,
    int? estimatedCostMinor,
    bool clearEstimatedCost = false,
    String? currency,
    bool clearCurrency = false,
    String? notes,
    bool clearNotes = false,
    EntityId? linkedInventoryItemId,
    bool clearLinkedInventoryItemId = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    DateTime? updatedAt,
  }) {
    final nextTitle = title?.trim() ?? this.title;
    if (nextTitle.isEmpty) {
      throw ArgumentError('HomeMaintenanceTask title cannot be empty');
    }
    final nextSystem = systemOrItem?.trim() ?? this.systemOrItem;
    if (nextSystem.isEmpty) {
      throw ArgumentError('HomeMaintenanceTask systemOrItem cannot be empty');
    }
    final nextCadence =
        clearCadenceDays ? null : (cadenceDays ?? this.cadenceDays);
    if (nextCadence != null && nextCadence <= 0) {
      throw ArgumentError('cadenceDays must be positive');
    }
    final nextCost = clearEstimatedCost
        ? null
        : (estimatedCostMinor ?? this.estimatedCostMinor);
    if (nextCost != null && nextCost < 0) {
      throw ArgumentError('estimatedCostMinor cannot be negative');
    }
    final nextVendor = clearVendorLabel
        ? null
        : (vendorLabel != null
            ? (vendorLabel.trim().isEmpty ? null : vendorLabel.trim())
            : this.vendorLabel);
    final nextCurrency = clearCurrency
        ? null
        : (currency != null
            ? (currency.trim().isEmpty ? null : currency.trim().toUpperCase())
            : this.currency);
    final nextNotes = clearNotes
        ? null
        : (notes != null
            ? (notes.trim().isEmpty ? null : notes.trim())
            : this.notes);
    return HomeMaintenanceTask(
      id: id,
      profileId: profileId,
      title: nextTitle,
      systemOrItem: nextSystem,
      cadenceDays: nextCadence,
      nextDueAt: clearNextDueAt ? null : (nextDueAt ?? this.nextDueAt),
      lastDoneAt: clearLastDoneAt ? null : (lastDoneAt ?? this.lastDoneAt),
      vendorLabel: nextVendor,
      estimatedCostMinor: nextCost,
      currency: nextCurrency,
      notes: nextNotes,
      linkedInventoryItemId: clearLinkedInventoryItemId
          ? null
          : (linkedInventoryItemId ?? this.linkedInventoryItemId),
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        title,
        systemOrItem,
        cadenceDays,
        nextDueAt,
        lastDoneAt,
        vendorLabel,
        estimatedCostMinor,
        currency,
        notes,
        linkedInventoryItemId,
        archivedAt,
        createdAt,
        updatedAt,
      ];
}
