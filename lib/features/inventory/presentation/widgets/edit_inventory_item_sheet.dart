import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/inventory_controllers.dart';
import 'inventory_linked_quests_section.dart';

class EditInventoryItemSheet extends ConsumerStatefulWidget {
  const EditInventoryItemSheet({super.key, required this.item});

  final InventoryItem item;

  static Future<void> show(BuildContext context, InventoryItem item) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditInventoryItemSheet(item: item),
    );
  }

  @override
  ConsumerState<EditInventoryItemSheet> createState() =>
      _EditInventoryItemSheetState();
}

class _EditInventoryItemSheetState
    extends ConsumerState<EditInventoryItemSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;
  late final TextEditingController _priceController;
  late final TextEditingController _currencyController;
  late InventoryCategory _category;
  late InventoryItemStatus _status;
  DateTime? _purchaseDate;
  DateTime? _warrantyEnd;
  String? _nameError;
  String? _priceError;

  static const _editableStatuses = <InventoryItemStatus>[
    InventoryItemStatus.active,
    InventoryItemStatus.stored,
    InventoryItemStatus.lent,
    InventoryItemStatus.disposed,
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item.name);
    _locationController =
        TextEditingController(text: item.locationLabel ?? '');
    _notesController = TextEditingController(text: item.notes ?? '');
    _priceController = TextEditingController(
      text: item.purchasePriceMinor == null
          ? ''
          : (item.purchasePriceMinor! / 100).toStringAsFixed(2),
    );
    _currencyController =
        TextEditingController(text: item.purchaseCurrency ?? 'BRL');
    _category = item.category;
    _status = item.status == InventoryItemStatus.archived
        ? InventoryItemStatus.active
        : item.status;
    _purchaseDate = item.purchaseDate;
    _warrantyEnd = item.warrantyEnd;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  int? _parsePriceMinor() {
    final raw = _priceController.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final major = double.tryParse(raw);
    if (major == null || major < 0) {
      return -1;
    }
    return (major * 100).round();
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final priceMinor = _parsePriceMinor();
    setState(() {
      _nameError = name.isEmpty ? AppStrings.inventoryNameRequired : null;
      _priceError = priceMinor == -1 ? AppStrings.inventoryPriceInvalid : null;
    });
    return _nameError == null && _priceError == null;
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _pickWarrantyEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _warrantyEnd ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
    );
    if (picked != null) setState(() => _warrantyEnd = picked);
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final location = _locationController.text.trim();
    final notes = _notesController.text.trim();
    final priceMinor = _parsePriceMinor();
    final currency = _currencyController.text.trim();
    final updated = widget.item.copyWith(
      name: _nameController.text.trim(),
      category: _category,
      status: _status,
      locationLabel: location,
      clearLocationLabel: location.isEmpty,
      notes: notes,
      clearNotes: notes.isEmpty,
      purchaseDate: _purchaseDate,
      clearPurchaseDate: _purchaseDate == null,
      purchasePriceMinor: priceMinor,
      clearPurchasePrice: priceMinor == null,
      purchaseCurrency: priceMinor == null
          ? null
          : (currency.isEmpty ? 'BRL' : currency),
      clearPurchaseCurrency: priceMinor == null,
      warrantyEnd: _warrantyEnd,
      clearWarrantyEnd: _warrantyEnd == null,
      updatedAt: DateTime.now().toUtc(),
    );
    final saved =
        await ref.read(inventoryControllerProvider.notifier).saveItem(updated);
    if (!mounted || saved == null) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.inventoryEditItem,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppStrings.inventoryName,
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            DropdownButtonFormField<InventoryCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: AppStrings.inventoryCategory,
              ),
              items: InventoryCategory.values
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(
                        AppStrings.inventoryCategoryLabel(category),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: ColonySpacing.md),
            DropdownButtonFormField<InventoryItemStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: AppStrings.inventoryStatus,
              ),
              items: _editableStatuses
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(
                        AppStrings.inventoryStatusLabel(status),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: AppStrings.inventoryLocationOptional,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppStrings.inventoryPurchaseDateOptional),
              subtitle: Text(
                _purchaseDate == null
                    ? AppStrings.inventoryDateNone
                    : MaterialLocalizations.of(context)
                        .formatCompactDate(_purchaseDate!),
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickPurchaseDate,
            ),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: AppStrings.inventoryPurchasePriceOptional,
                      errorText: _priceError,
                    ),
                  ),
                ),
                const SizedBox(width: ColonySpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _currencyController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: AppStrings.inventoryCurrency,
                    ),
                  ),
                ),
              ],
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppStrings.inventoryWarrantyEndOptional),
              subtitle: Text(
                _warrantyEnd == null
                    ? AppStrings.inventoryDateNone
                    : MaterialLocalizations.of(context)
                        .formatCompactDate(_warrantyEnd!),
              ),
              trailing: const Icon(Icons.event_available_outlined),
              onTap: _pickWarrantyEnd,
            ),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.inventoryNotesOptional,
              ),
            ),
            InventoryLinkedQuestsSection(item: widget.item),
            const SizedBox(height: ColonySpacing.lg),
            FilledButton(
              onPressed: _save,
              child: Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }
}
