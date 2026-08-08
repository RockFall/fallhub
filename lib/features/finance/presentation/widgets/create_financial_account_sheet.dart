import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../application/finance_controllers.dart';
import '../../application/finance_providers.dart';

class CreateFinancialAccountSheet extends ConsumerStatefulWidget {
  const CreateFinancialAccountSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateFinancialAccountSheet(),
    );
  }

  @override
  ConsumerState<CreateFinancialAccountSheet> createState() =>
      _CreateFinancialAccountSheetState();
}

class _CreateFinancialAccountSheetState
    extends ConsumerState<CreateFinancialAccountSheet> {
  final _institutionController = TextEditingController();
  final _nameController = TextEditingController();
  FinancialAccountType _type = FinancialAccountType.checking;
  bool _includeInNetWorth = true;
  SensitiveDisplayMode _sensitiveMode = SensitiveDisplayMode.hidden;
  String? _nameError;

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

    final repos = ref.read(repositoriesProvider);
    var entity = ref.read(defaultFinancialEntityProvider);
    if (entity == null) {
      await ref.read(financeBootstrapProvider.notifier).ensureSeeded();
      entity = ref.read(defaultFinancialEntityProvider);
    }
    if (entity == null) {
      final profile = await repos.profiles.getActive();
      if (profile == null) return;
      final entities = await repos.finance.listEntities(profile.id);
      if (entities.isEmpty) return;
      entity = entities.firstWhere(
        (e) => e.kind == FinancialEntityKind.personal,
        orElse: () => entities.first,
      );
    }

    final profile = await repos.profiles.getActive();
    if (profile == null) return;

    final account = await ref.read(financeControllerProvider.notifier).createAccount(
          entityId: entity.id,
          institution: _institutionController.text.trim().isEmpty
              ? AppStrings.financeInstitutionUnknown
              : _institutionController.text.trim(),
          name: _nameController.text.trim(),
          type: _type,
          currency: profile.baseCurrency,
          includeInNetWorth: _includeInNetWorth,
          sensitiveDisplayMode: _sensitiveMode,
        );

    if (!mounted || account == null) return;
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
              AppStrings.financeNewAccount,
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
              initialValue: _type,
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
          ],
        ),
      ),
    );
  }
}
