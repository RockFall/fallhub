import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/travel_controllers.dart';

class CreateTripSheet extends ConsumerStatefulWidget {
  const CreateTripSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateTripSheet(),
    );
  }

  @override
  ConsumerState<CreateTripSheet> createState() => _CreateTripSheetState();
}

class _CreateTripSheetState extends ConsumerState<CreateTripSheet> {
  final _titleController = TextEditingController();
  final _destinationsController = TextEditingController();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _startAt;
  DateTime? _endAt;
  String? _titleError;

  @override
  void dispose() {
    _titleController.dispose();
    _destinationsController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<String> _parseDestinations() {
    return _destinationsController.text
        .split(',')
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toList();
  }

  bool _validate() {
    final title = _titleController.text.trim();
    setState(() {
      _titleError = title.isEmpty ? AppStrings.tripTitleRequired : null;
    });
    return _titleError == null;
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startAt ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _startAt = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endAt ?? _startAt ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _endAt = picked);
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final created = await ref.read(travelControllerProvider.notifier).create(
          title: _titleController.text.trim(),
          destinations: _parseDestinations(),
          startAt: _startAt,
          endAt: _endAt,
          purpose: _purposeController.text.trim().isEmpty
              ? null
              : _purposeController.text.trim(),
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
              AppStrings.tripNew,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppStrings.tripTitle,
                errorText: _titleError,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _destinationsController,
              decoration: const InputDecoration(
                labelText: AppStrings.tripDestinationsOptional,
                hintText: AppStrings.tripDestinationsHint,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppStrings.tripStartOptional),
              subtitle: Text(
                _startAt == null
                    ? AppStrings.tripDateNone
                    : MaterialLocalizations.of(context)
                        .formatCompactDate(_startAt!),
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickStart,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppStrings.tripEndOptional),
              subtitle: Text(
                _endAt == null
                    ? AppStrings.tripDateNone
                    : MaterialLocalizations.of(context)
                        .formatCompactDate(_endAt!),
              ),
              trailing: const Icon(Icons.event_outlined),
              onTap: _pickEnd,
            ),
            TextField(
              controller: _purposeController,
              decoration: const InputDecoration(
                labelText: AppStrings.tripPurposeOptional,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.tripNotesOptional,
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
