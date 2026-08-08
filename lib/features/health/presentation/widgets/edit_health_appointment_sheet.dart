import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/health_controllers.dart';

class EditHealthAppointmentSheet extends ConsumerStatefulWidget {
  const EditHealthAppointmentSheet({super.key, required this.appointment});

  final HealthAppointment appointment;

  static Future<void> show(
    BuildContext context,
    HealthAppointment appointment,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditHealthAppointmentSheet(appointment: appointment),
    );
  }

  @override
  ConsumerState<EditHealthAppointmentSheet> createState() =>
      _EditHealthAppointmentSheetState();
}

class _EditHealthAppointmentSheetState
    extends ConsumerState<EditHealthAppointmentSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _clinicianController;
  late final TextEditingController _notesController;
  late DateTime _scheduledAt;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    final a = widget.appointment;
    _titleController = TextEditingController(text: a.title);
    _locationController = TextEditingController(text: a.locationLabel ?? '');
    _clinicianController = TextEditingController(text: a.clinicianLabel ?? '');
    _notesController = TextEditingController(text: a.notes ?? '');
    _scheduledAt = a.scheduledAt;
  }

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

    final location = _locationController.text.trim();
    final clinician = _clinicianController.text.trim();
    final notes = _notesController.text.trim();

    final updated =
        await ref.read(healthControllerProvider.notifier).saveAppointment(
              widget.appointment.copyWith(
                title: title,
                scheduledAt: _scheduledAt,
                locationLabel: location.isEmpty ? null : location,
                clearLocationLabel: location.isEmpty,
                clinicianLabel: clinician.isEmpty ? null : clinician,
                clearClinicianLabel: clinician.isEmpty,
                notes: notes.isEmpty ? null : notes,
                clearNotes: notes.isEmpty,
              ),
            );
    if (!mounted || updated == null) return;
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
              AppStrings.healthEditAppointment,
              style: Theme.of(context).textTheme.titleLarge,
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
