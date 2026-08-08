import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/finance_controllers.dart';
import '../../application/finance_providers.dart';

class ImportFinanceCsvSheet extends ConsumerStatefulWidget {
  const ImportFinanceCsvSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ImportFinanceCsvSheet(),
    );
  }

  @override
  ConsumerState<ImportFinanceCsvSheet> createState() =>
      _ImportFinanceCsvSheetState();
}

class _ImportFinanceCsvSheetState extends ConsumerState<ImportFinanceCsvSheet> {
  final _csvController = TextEditingController();
  String? _error;
  FinanceCsvImportPlan? _plan;
  String? _accountOverrideId;
  bool _busy = false;

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  EntityId? get _accountOverride =>
      _accountOverrideId == null ? null : EntityId(_accountOverrideId!);

  Future<void> _preview() async {
    final text = _csvController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _error = AppStrings.financeImportCsvEmpty;
        _plan = null;
      });
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
      _plan = null;
    });
    final plan = await ref
        .read(financeControllerProvider.notifier)
        .planTransactionsCsv(text, accountOverride: _accountOverride);
    if (!mounted) return;
    setState(() => _busy = false);
    if (plan == null) {
      setState(() => _error = AppStrings.financeImportCsvInvalid);
      return;
    }
    setState(() => _plan = plan);
  }

  Future<void> _apply() async {
    final plan = _plan;
    if (plan == null) return;
    if (!plan.hasWork) {
      setState(() => _error = AppStrings.financeImportCsvNothingToApply);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    final applied = await ref
        .read(financeControllerProvider.notifier)
        .applyTransactionsCsv(plan);
    if (!mounted) return;
    setState(() => _busy = false);
    if (applied == null) {
      setState(() => _error = AppStrings.financeImportCsvInvalid);
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.financeImportCsvResult(
            applied.importCount,
            applied.duplicateCount,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final accountsAsync = ref.watch(financialAccountsProvider);
    final plan = _plan;

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
              AppStrings.financeImportCsv,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.sm),
            Text(
              AppStrings.financeImportCsvHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: ColonySpacing.lg),
            TextField(
              controller: _csvController,
              maxLines: 8,
              onChanged: (_) {
                if (_plan != null || _error != null) {
                  setState(() {
                    _plan = null;
                    _error = null;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: AppStrings.financeImportCsvPaste,
                errorText: _error,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            accountsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (accounts) {
                final active = accounts.where((a) => !a.isArchived).toList();
                if (active.isEmpty) return const SizedBox.shrink();
                return DropdownButtonFormField<String?>(
                  value: _accountOverrideId,
                  decoration: const InputDecoration(
                    labelText: AppStrings.financeImportCsvAccountOverride,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(AppStrings.financeImportCsvAccountFromCsv),
                    ),
                    for (final a in active)
                      DropdownMenuItem<String?>(
                        value: a.id.value,
                        child: Text('${a.name} · ${a.institution}'),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) {
                          setState(() {
                            _accountOverrideId = value;
                            _plan = null;
                          });
                        },
                );
              },
            ),
            if (plan != null) ...[
              const SizedBox(height: ColonySpacing.md),
              Text(
                AppStrings.financeImportCsvPlanSummary(
                  plan.importCount,
                  plan.duplicateCount,
                ),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (plan.toImport.isNotEmpty) ...[
                const SizedBox(height: ColonySpacing.sm),
                for (final row in plan.toImport.take(5))
                  Padding(
                    padding: const EdgeInsets.only(bottom: ColonySpacing.xs),
                    child: Text(
                      '• ${row.descriptionOriginal}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ],
            const SizedBox(height: ColonySpacing.lg),
            if (_busy)
              const Center(child: CircularProgressIndicator())
            else ...[
              OutlinedButton(
                onPressed: _preview,
                child: Text(AppStrings.financeImportCsvPreviewAction),
              ),
              const SizedBox(height: ColonySpacing.sm),
              FilledButton(
                onPressed: plan == null ? null : _apply,
                child: Text(AppStrings.financeImportCsvApplyAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
