import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/finance_controllers.dart';

class EditFinancialAccountSheet extends ConsumerStatefulWidget {
  const EditFinancialAccountSheet({super.key, required this.account});

  final FinancialAccount account;

  static Future<void> show(BuildContext context, FinancialAccount account) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditFinancialAccountSheet(account: account),
    );
  }

  @override
  ConsumerState<EditFinancialAccountSheet> createState() =>
      _EditFinancialAccountSheetState();
}

class _EditFinancialAccountSheetState
    extends ConsumerState<EditFinancialAccountSheet> {
  late final TextEditingController _institutionController;
  late final TextEditingController _nameController;
  late FinancialAccountType _type;
  late SensitiveDisplayMode _sensitiveMode;
  late bool _includeInNetWorth;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _institutionController =
        TextEditingController(text: widget.account.institution);
    _nameController = TextEditingController(text: widget.account.name);
    _type = widget.account.type;
    _sensitiveMode = widget.account.sensitiveDisplayMode;
    _includeInNetWorth = widget.account.includeInNetWorth;
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _nameController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? AppStrings.financeAccountNameRequired : null;
    });
    return _nameError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final updated = widget.account.copyWith(
      name: _nameController.text.trim(),
      institution: _institutionController.text.trim().isEmpty
          ? AppStrings.financeInstitutionUnknown
          : _institutionController.text.trim(),
      type: _type,
      sensitiveDisplayMode: _sensitiveMode,
      includeInNetWorth: _includeInNetWorth,
      updatedAt: DateTime.now().toUtc(),
    );

    final saved =
        await ref.read(financeControllerProvider.notifier).updateAccount(updated);
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
              AppStrings.financeEditAccount,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppStrings.financeAccountName,
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _institutionController,
              decoration: const InputDecoration(
                labelText: AppStrings.financeInstitution,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            DropdownButtonFormField<FinancialAccountType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: AppStrings.financeAccountType,
              ),
              items: FinancialAccountType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(AppStrings.financeAccountTypeLabel(type)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: ColonySpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppStrings.financeIncludeInNetWorth),
              value: _includeInNetWorth,
              onChanged: (value) => setState(() => _includeInNetWorth = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppStrings.financeMaskValuesByDefault),
              value: _sensitiveMode == SensitiveDisplayMode.hidden,
              onChanged: (value) => setState(() {
                _sensitiveMode = value
                    ? SensitiveDisplayMode.hidden
                    : SensitiveDisplayMode.visible;
              }),
            ),
            const SizedBox(height: ColonySpacing.lg),
            FilledButton(
              onPressed: _save,
              child: Text(AppStrings.save),
            ),
            if (!widget.account.isArchived) ...[
              const SizedBox(height: ColonySpacing.sm),
              OutlinedButton(
                onPressed: () async {
                  final archived = await ref
                      .read(financeControllerProvider.notifier)
                      .archiveAccount(widget.account);
                  if (!mounted || archived == null) return;
                  Navigator.pop(context);
                },
                child: Text(AppStrings.financeArchiveAccount),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
