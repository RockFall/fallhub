import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/health_controllers.dart';

class CreateHealthAppointmentSheet extends ConsumerStatefulWidget {
  const CreateHealthAppointmentSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateHealthAppointmentSheet(),
    );
  }

  @override
  ConsumerState<CreateHealthAppointmentSheet> createState() =>
      _CreateHealthAppointmentSheetState();
}

class _CreateHealthAppointmentSheetState
    extends ConsumerState<CreateHealthAppointmentSheet> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _clinicianController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _scheduledAt = DateTime.now().toUtc().add(const Duration(days: 1));
  String? _titleError;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _clinicianController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt.toLocal(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt.toLocal()),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ).toUtc();
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = AppStrings.healthAppointmentTitleRequired);
      return;
    }
    setState(() => _titleError = null);
    final created =
        await ref.read(healthControllerProvider.notifier).createAppointment(
              title: title,
              scheduledAt: _scheduledAt,
              locationLabel: _locationController.text.trim().isEmpty
                  ? null
                  : _locationController.text.trim(),
              clinicianLabel: _clinicianController.text.trim().isEmpty
                  ? null
                  : _clinicianController.text.trim(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );
    if (!mounted || created == null) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final local = _scheduledAt.toLocal();
    final whenLabel =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

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
              AppStrings.healthNewAppointment,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.sm),
            Text(
              AppStrings.healthAppointmentsHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: ColonySpacing.lg),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppStrings.healthAppointmentTitle,
                errorText: _titleError,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            OutlinedButton(
              onPressed: _pickDateTime,
              child: Text('${AppStrings.healthAppointmentWhen}: $whenLabel'),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: AppStrings.healthAppointmentLocationOptional,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _clinicianController,
              decoration: const InputDecoration(
                labelText: AppStrings.healthAppointmentClinicianOptional,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: AppStrings.healthNotesOptional,
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
