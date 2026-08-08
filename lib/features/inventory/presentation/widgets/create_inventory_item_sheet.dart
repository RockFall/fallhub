import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/inventory_controllers.dart';

class CreateInventoryItemSheet extends ConsumerStatefulWidget {
  const CreateInventoryItemSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateInventoryItemSheet(),
    );
  }

  @override
  ConsumerState<CreateInventoryItemSheet> createState() =>
      _CreateInventoryItemSheetState();
}

class _CreateInventoryItemSheetState
    extends ConsumerState<CreateInventoryItemSheet> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _priceController = TextEditingController();
  final _currencyController = TextEditingController(text: 'BRL');
  InventoryCategory _category = InventoryCategory.other;
  DateTime? _purchaseDate;
  DateTime? _warrantyEnd;
  String? _nameError;
  String? _priceError;

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
    final priceMinor = _parsePriceMinor();
    final currency = _currencyController.text.trim();
    final created = await ref.read(inventoryControllerProvider.notifier).create(
          name: _nameController.text.trim(),
          category: _category,
          locationLabel: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          purchaseDate: _purchaseDate,
          purchasePriceMinor: priceMinor,
          purchaseCurrency: priceMinor == null
              ? null
              : (currency.isEmpty ? 'BRL' : currency),
          warrantyEnd: _warrantyEnd,
        );
    if (!mounted || created == null) return;
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
              AppStrings.inventoryNewItem,
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
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: AppStrings.inventoryLocationOptional,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
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
            const SizedBox(height: ColonySpacing.md),
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
