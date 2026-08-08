import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/health_controllers.dart';

class LogSymptomEntrySheet extends ConsumerStatefulWidget {
  const LogSymptomEntrySheet({super.key, required this.condition});

  final HealthCondition condition;

  static Future<void> show(BuildContext context, HealthCondition condition) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LogSymptomEntrySheet(condition: condition),
    );
  }

  @override
  ConsumerState<LogSymptomEntrySheet> createState() =>
      _LogSymptomEntrySheetState();
}

class _LogSymptomEntrySheetState extends ConsumerState<LogSymptomEntrySheet> {
  final _noteController = TextEditingController();
  final _regionController = TextEditingController();
  int _intensity = 3;

  @override
  void initState() {
    super.initState();
    if (widget.condition.bodyRegions.isNotEmpty) {
      _regionController.text = widget.condition.bodyRegions.first;
    }
    _intensity = widget.condition.severityUserReported ?? 3;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final logged = await ref.read(healthControllerProvider.notifier).logSymptom(
          conditionId: widget.condition.id,
          intensity: _intensity,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          bodyRegion: _regionController.text.trim().isEmpty
              ? null
              : _regionController.text.trim(),
        );
    if (!mounted || logged == null) return;
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
              AppStrings.healthLogSymptom,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.sm),
            Text(
              widget.condition.title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: ColonySpacing.lg),
            DropdownButtonFormField<int>(
              initialValue: _intensity,
              decoration: const InputDecoration(
                labelText: AppStrings.healthSymptomIntensity,
              ),
              items: [
                for (var i = 1; i <= 5; i++)
                  DropdownMenuItem(value: i, child: Text('$i')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _intensity = value);
              },
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _regionController,
              decoration: const InputDecoration(
                labelText: AppStrings.healthBodyRegionOptional,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: AppStrings.healthSymptomNoteOptional,
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
