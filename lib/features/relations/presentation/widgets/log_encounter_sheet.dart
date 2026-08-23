import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/relations_controllers.dart';
import '../../application/relations_providers.dart';

class LogEncounterSheet extends ConsumerStatefulWidget {
  const LogEncounterSheet({super.key, this.preselected = const []});

  final List<Person> preselected;

  static Future<void> show(
    BuildContext context, {
    List<Person> preselected = const [],
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LogEncounterSheet(preselected: preselected),
    );
  }

  @override
  ConsumerState<LogEncounterSheet> createState() => _LogEncounterSheetState();
}

class _LogEncounterSheetState extends ConsumerState<LogEncounterSheet> {
  late Set<EntityId> _selected;
  final _note = TextEditingController();
  InteractionKind _kind = InteractionKind.meeting;
  DateTime _occurredAt = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _selected = {for (final p in widget.preselected) p.id};
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt.toLocal(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _occurredAt = DateTime.utc(picked.year, picked.month, picked.day, 12);
    });
  }

  Future<void> _save() async {
    final people = (ref.read(peopleProvider).value ?? const [])
        .where((p) => _selected.contains(p.id))
        .toList();
    if (people.isEmpty) return;
    final created =
        await ref.read(relationsControllerProvider.notifier).logEncounter(
              people: people,
              kind: _kind,
              occurredAt: _occurredAt,
              note: _note.text,
            );
    if (!mounted || created.isEmpty) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final people = (ref.watch(peopleProvider).value ?? const [])
        .where((p) => !p.isArchived)
        .toList();
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg + bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.friendshipLogEncounter,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.md),
            DropdownButtonFormField<InteractionKind>(
              initialValue: _kind,
              decoration: const InputDecoration(
                labelText: AppStrings.personInteractionKind,
              ),
              items: const [
                InteractionKind.meeting,
                InteractionKind.gathering,
              ]
                  .map(
                    (k) => DropdownMenuItem(
                      value: k,
                      child: Text(AppStrings.interactionKindLabel(k)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _kind = value);
              },
            ),
            const SizedBox(height: ColonySpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${AppStrings.friendshipOccurredAt}: ${_occurredAt.toIso8601String().split('T').first}',
              ),
              trailing: const Icon(Icons.event),
              onTap: _pickDate,
            ),
            const SizedBox(height: ColonySpacing.sm),
            Text(
              AppStrings.friendshipSelectPeople,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Wrap(
              spacing: ColonySpacing.sm,
              children: [
                for (final person in people)
                  FilterChip(
                    label: Text(person.displayName),
                    selected: _selected.contains(person.id),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selected.add(person.id);
                        } else {
                          _selected.remove(person.id);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: AppStrings.personInteractionNote,
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
