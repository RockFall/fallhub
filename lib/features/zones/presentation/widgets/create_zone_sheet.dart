import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/zones_controllers.dart';

class CreateZoneSheet extends ConsumerStatefulWidget {
  const CreateZoneSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateZoneSheet(),
    );
  }

  @override
  ConsumerState<CreateZoneSheet> createState() => _CreateZoneSheetState();
}

class _CreateZoneSheetState extends ConsumerState<CreateZoneSheet> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _capabilitiesController = TextEditingController();
  final _unavailableController = TextEditingController();
  final _notesController = TextEditingController();
  ZoneConnectivity _connectivity = ZoneConnectivity.unknown;
  String? _nameError;

  List<String> _splitCsv(String raw) => raw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

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
    final created = await ref.read(zonesControllerProvider.notifier).create(
          name: name,
          locationLabel: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          capabilities: caps,
          unavailableWorkTypes: unavailable,
          connectivity: _connectivity,
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
              AppStrings.zoneNew,
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
