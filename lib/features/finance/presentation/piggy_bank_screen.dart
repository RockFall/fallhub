import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/piggy_bank_providers.dart';
import '../application/piggy_bank_query.dart';

class PiggyBankScreen extends ConsumerWidget {
  const PiggyBankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evaluation = ref.watch(piggySnapshotProvider);
    return evaluation.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _PiggyMessage(
        title: AppStrings.errorGeneric,
        body: '$error',
        action: AppStrings.piggyRetry,
        onAction: () => ref.invalidate(piggySnapshotProvider),
      ),
      data: (value) {
        if (value == null) {
          return const _PiggyMessage(
            title: AppStrings.piggyTitle,
            body: AppStrings.piggyNoProfile,
          );
        }
        return _PiggyBody(evaluation: value);
      },
    );
  }
}

class _PiggyMessage extends StatelessWidget {
  const _PiggyMessage({
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });

  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ColonySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: ColonySpacing.md),
            Text(body, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: ColonySpacing.lg),
              FilledButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PiggyBody extends ConsumerWidget {
  const _PiggyBody({required this.evaluation});

  final PiggyEvaluation evaluation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = evaluation.snapshot;
    final config = evaluation.config;
    final statusColor = _statusColor(snapshot.status);
    final history = snapshot.history.reversed.take(14).toList();

    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        Text(
          AppStrings.piggyTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: ColonySpacing.xs),
        Text(
          AppStrings.piggyOfflineHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: ColonySpacing.lg),
        Semantics(
          identifier: 'piggy.balance',
          child: Text(
            PiggyMoney.format(snapshot.balanceMinor),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: ColonySpacing.sm),
        Text(AppStrings.piggySpentToday(PiggyMoney.format(snapshot.spentTodayMinor))),
        Text(
          AppStrings.piggyAvailableToday(
            PiggyMoney.format(snapshot.availableTodayMinor),
          ),
        ),
        if (snapshot.debtDays != null)
          Text(
            AppStrings.piggyDebtDays(snapshot.debtDays!),
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
          ),
        if (snapshot.requiredPaceMinor != null)
          Text(
            AppStrings.piggyRequiredPace(
              PiggyMoney.format(snapshot.requiredPaceMinor!),
            ),
          ),
        if (snapshot.status == PiggyBankStatus.red && snapshot.burstDayCost != null)
          Padding(
            padding: const EdgeInsets.only(top: ColonySpacing.md),
            child: Material(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(ColonyRadii.md),
              child: Padding(
                padding: const EdgeInsets.all(ColonySpacing.md),
                child: Text(PiggyMoney.daysCost(snapshot.burstDayCost!)),
              ),
            ),
          ),
        const SizedBox(height: ColonySpacing.xl),
        Text(
          AppStrings.piggyHistoryTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: ColonySpacing.sm),
        if (history.isEmpty)
          const Text(AppStrings.piggyHistoryEmpty)
        else
          for (final day in history)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_formatCivil(day.date)),
              subtitle: Text(
                AppStrings.piggyHistoryLine(
                  PiggyMoney.format(day.spentMinor),
                  PiggyMoney.format(config.dailyAmountMinor),
                ),
              ),
              trailing: Text(PiggyMoney.format(day.balanceMinor)),
            ),
        const SizedBox(height: ColonySpacing.lg),
        Text(
          AppStrings.piggyTodayTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: ColonySpacing.sm),
        if (snapshot.todayExpenses.isEmpty)
          const Text(AppStrings.piggyTodayEmpty)
        else
          for (final line in snapshot.todayExpenses)
            _ExpenseTile(line: line),
        const SizedBox(height: ColonySpacing.xl),
        _ConfigSection(config: config),
      ],
    );
  }
}

class _ExpenseTile extends ConsumerWidget {
  const _ExpenseTile({required this.line});

  final PiggyExpenseLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signed = line.direction == TransactionDirection.inflow
        ? -line.displayMinor
        : line.displayMinor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(line.description),
        Row(
          children: [
            Expanded(
              child: Text(
                line.counts ? AppStrings.piggyInPiggy : AppStrings.piggyOutOfPiggy,
              ),
            ),
            Text(PiggyMoney.format(signed)),
            IconButton(
              tooltip: AppStrings.piggyCorrectAmount,
              onPressed: () => _correctAmount(context, ref),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.piggyOutOfPiggy),
          value: !line.counts,
          onChanged: (outside) {
            ref.read(piggyBankControllerProvider.notifier).updateOverride(
                  transactionId: EntityId(line.transactionId),
                  excluded: outside,
                );
          },
        ),
      ],
    );
  }

  Future<void> _correctAmount(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: (line.displayMinor / 100).toStringAsFixed(2).replaceAll('.', ','),
    );
    final saved = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.piggyCorrectAmount),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: const InputDecoration(labelText: AppStrings.piggyAmount),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.piggyCancel),
          ),
          FilledButton(
            onPressed: () {
              final minor = _parseMinor(controller.text);
              Navigator.pop(context, minor);
            },
            child: const Text(AppStrings.piggySave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (saved == null || saved <= 0) return;
    await ref.read(piggyBankControllerProvider.notifier).updateOverride(
          transactionId: EntityId(line.transactionId),
          amountOverrideMinor: saved,
        );
  }
}

class _ConfigSection extends ConsumerStatefulWidget {
  const _ConfigSection({required this.config});

  final PiggyBankConfig config;

  @override
  ConsumerState<_ConfigSection> createState() => _ConfigSectionState();
}

class _ConfigSectionState extends ConsumerState<_ConfigSection> {
  late final TextEditingController _daily;

  @override
  void initState() {
    super.initState();
    _daily = TextEditingController(
      text: (widget.config.dailyAmountMinor / 100).toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _daily.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.piggySettingsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: ColonySpacing.sm),
        TextField(
          controller: _daily,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: const InputDecoration(labelText: AppStrings.piggyDailyAmount),
          onSubmitted: (_) => _saveDaily(),
        ),
        const SizedBox(height: ColonySpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _saveDaily,
            child: const Text(AppStrings.piggySaveDaily),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.piggyStartDate),
          subtitle: Text(_formatCivil(config.startDate)),
          onTap: () => _pickDate(start: true),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.piggyEndDate),
          subtitle: Text(
            config.endDate == null
                ? AppStrings.piggyEndDateEmpty
                : _formatCivil(config.endDate!),
          ),
          trailing: config.endDate == null
              ? null
              : IconButton(
                  tooltip: AppStrings.piggyClearEndDate,
                  onPressed: () => ref
                      .read(piggyBankControllerProvider.notifier)
                      .saveConfig(config.copyWith(clearEndDate: true)),
                  icon: const Icon(Icons.close),
                ),
          onTap: () => _pickDate(start: false),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.piggyInstallmentTotal),
          subtitle: const Text(AppStrings.piggyInstallmentTotalHint),
          value: config.installmentCountsTotal,
          onChanged: (value) => ref
              .read(piggyBankControllerProvider.notifier)
              .saveConfig(config.copyWith(installmentCountsTotal: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.piggyAlertWhenRed),
          value: config.alertWhenRed,
          onChanged: (value) => ref
              .read(piggyBankControllerProvider.notifier)
              .saveConfig(config.copyWith(alertWhenRed: value)),
        ),
        const SizedBox(height: ColonySpacing.sm),
        Text(
          AppStrings.piggyExcludedCategories,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: ColonySpacing.xs),
        Wrap(
          spacing: ColonySpacing.xs,
          children: [
            for (final category in TransactionCategory.values)
              FilterChip(
                label: Text(AppStrings.financeCategoryLabel(category)),
                selected: config.excludedCategoryIds.contains(
                  TransactionCategoryPolicy.categoryIdFor(category).value,
                ),
                onSelected: (selected) {
                  final id = TransactionCategoryPolicy.categoryIdFor(category).value;
                  final next = [...config.excludedCategoryIds];
                  if (selected) {
                    if (!next.contains(id)) next.add(id);
                  } else {
                    next.remove(id);
                  }
                  ref.read(piggyBankControllerProvider.notifier).saveConfig(
                        config.copyWith(excludedCategoryIds: next),
                      );
                },
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveDaily() async {
    final minor = _parseMinor(_daily.text);
    if (minor == null || minor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.financeAmountInvalid)),
      );
      return;
    }
    await ref.read(piggyBankControllerProvider.notifier).saveConfig(
          widget.config.copyWith(dailyAmountMinor: minor),
        );
  }

  Future<void> _pickDate({required bool start}) async {
    final current = start
        ? widget.config.startDate
        : (widget.config.endDate ?? widget.config.startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final civil = DateTime.utc(picked.year, picked.month, picked.day);
    final notifier = ref.read(piggyBankControllerProvider.notifier);
    if (!start &&
        civil.isBefore(PiggyBankCalendar.dateOnly(widget.config.startDate))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.piggyInvalidDates)),
      );
      return;
    }
    if (start) {
      final end = widget.config.endDate;
      final next = end != null && end.isBefore(civil)
          ? widget.config.copyWith(startDate: civil, clearEndDate: true)
          : widget.config.copyWith(startDate: civil);
      await notifier.saveConfig(next);
    } else {
      await notifier.saveConfig(widget.config.copyWith(endDate: civil));
    }
  }
}

Color _statusColor(PiggyBankStatus status) {
  return switch (status) {
    PiggyBankStatus.green => const Color(0xFF2E7D32),
    PiggyBankStatus.yellow => const Color(0xFFF9A825),
    PiggyBankStatus.red => const Color(0xFFC62828),
  };
}

String _formatCivil(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

int? _parseMinor(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final normalized = trimmed.contains(',')
      ? trimmed.replaceAll('.', '').replaceAll(',', '.')
      : trimmed;
  final major = double.tryParse(normalized);
  if (major == null) return null;
  return (major * 100).round();
}
