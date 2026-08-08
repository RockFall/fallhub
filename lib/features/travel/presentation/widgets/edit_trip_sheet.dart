import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/travel_controllers.dart';
import 'trip_packing_list_section.dart';

class EditTripSheet extends ConsumerStatefulWidget {
  const EditTripSheet({super.key, required this.trip});

  final Trip trip;

  static Future<void> show(BuildContext context, Trip trip) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditTripSheet(trip: trip),
    );
  }

  @override
  ConsumerState<EditTripSheet> createState() => _EditTripSheetState();
}

class _EditTripSheetState extends ConsumerState<EditTripSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _destinationsController;
  late final TextEditingController _purposeController;
  late final TextEditingController _notesController;
  late TripStatus _status;
  DateTime? _startAt;
  DateTime? _endAt;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    final trip = widget.trip;
    _titleController = TextEditingController(text: trip.title);
    _destinationsController =
        TextEditingController(text: trip.destinations.join(', '));
    _purposeController = TextEditingController(text: trip.purpose ?? '');
    _notesController = TextEditingController(text: trip.notes ?? '');
    _status = trip.status;
    _startAt = trip.startAt;
    _endAt = trip.endAt;
  }

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
    final updated = widget.trip.copyWith(
      title: _titleController.text.trim(),
      destinations: _parseDestinations(),
      startAt: _startAt,
      clearStartAt: _startAt == null,
      endAt: _endAt,
      clearEndAt: _endAt == null,
      purpose: _purposeController.text.trim().isEmpty
          ? null
          : _purposeController.text.trim(),
      clearPurpose: _purposeController.text.trim().isEmpty,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      clearNotes: _notesController.text.trim().isEmpty,
      status: _status,
    );
    final saved =
        await ref.read(travelControllerProvider.notifier).saveTrip(updated);
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
              AppStrings.tripEdit,
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
            DropdownButtonFormField<TripStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: AppStrings.tripStatus,
              ),
              items: TripStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(AppStrings.tripStatusLabel(status)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
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
            TripPackingListSection(trip: widget.trip),
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
