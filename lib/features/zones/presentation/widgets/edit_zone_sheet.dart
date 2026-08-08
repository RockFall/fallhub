import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/zones_controllers.dart';
import 'zone_linked_trips_section.dart';

class EditZoneSheet extends ConsumerStatefulWidget {
  const EditZoneSheet({super.key, required this.zone});

  final ContextZone zone;

  static Future<void> show(BuildContext context, ContextZone zone) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditZoneSheet(zone: zone),
    );
  }

  @override
  ConsumerState<EditZoneSheet> createState() => _EditZoneSheetState();
}

class _EditZoneSheetState extends ConsumerState<EditZoneSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _capabilitiesController;
  late final TextEditingController _unavailableController;
  late final TextEditingController _notesController;
  late ZoneConnectivity _connectivity;
  String? _nameError;

  List<String> _splitCsv(String raw) => raw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  @override
  void initState() {
    super.initState();
    final z = widget.zone;
    _nameController = TextEditingController(text: z.name);
    _locationController = TextEditingController(text: z.locationLabel ?? '');
    _capabilitiesController =
        TextEditingController(text: z.capabilities.join(', '));
    _unavailableController =
        TextEditingController(text: z.unavailableWorkTypes.join(', '));
    _notesController = TextEditingController(text: z.notes ?? '');
    _connectivity = z.connectivity;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _capabilitiesController.dispose();
    _unavailableController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = AppStrings.zoneNameRequired);
      return;
    }
    final caps = _splitCsv(_capabilitiesController.text);
    final unavailable = _splitCsv(_unavailableController.text);
    final location = _locationController.text.trim();
    final notes = _notesController.text.trim();
    final updated = widget.zone.copyWith(
      name: name,
      locationLabel: location.isEmpty ? null : location,
      clearLocationLabel: location.isEmpty,
      capabilities: caps,
      unavailableWorkTypes: unavailable,
      connectivity: _connectivity,
      notes: notes.isEmpty ? null : notes,
      clearNotes: notes.isEmpty,
    );
    final saved =
        await ref.read(zonesControllerProvider.notifier).save(updated);
    if (!mounted || saved == null) return;
    Navigator.pop(context);
  }

  Future<void> _archive() async {
    final archived =
        await ref.read(zonesControllerProvider.notifier).archive(widget.zone);
    if (!mounted || archived == null) return;
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
              AppStrings.zoneEdit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppStrings.zoneName,
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: AppStrings.zoneLocationOptional,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _capabilitiesController,
              decoration: const InputDecoration(
                labelText: AppStrings.zoneCapabilitiesOptional,
                helperText: AppStrings.zoneCapabilitiesHint,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _unavailableController,
              decoration: const InputDecoration(
                labelText: AppStrings.zoneUnavailableWorkTypesOptional,
                helperText: AppStrings.zoneUnavailableWorkTypesHint,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            DropdownButtonFormField<ZoneConnectivity>(
              // ignore: deprecated_member_use
              value: _connectivity,
              decoration: const InputDecoration(
                labelText: AppStrings.zoneConnectivity,
              ),
              items: ZoneConnectivity.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(AppStrings.zoneConnectivityLabel(c)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _connectivity = v);
              },
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: AppStrings.zoneNotesOptional,
              ),
            ),
            ZoneLinkedTripsSection(zone: widget.zone),
            const SizedBox(height: ColonySpacing.lg),
            FilledButton(
              onPressed: _save,
              child: Text(AppStrings.save),
            ),
            TextButton(
              onPressed: _archive,
              child: Text(AppStrings.zoneArchive),
            ),
          ],
        ),
      ),
    );
  }
}
