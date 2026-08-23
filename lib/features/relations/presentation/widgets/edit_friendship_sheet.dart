import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/relations_controllers.dart';
import '../../application/relations_providers.dart';
import 'log_encounter_sheet.dart';

class EditFriendshipSheet extends ConsumerStatefulWidget {
  const EditFriendshipSheet({super.key, required this.friendship});

  final Friendship friendship;

  static Future<void> show(BuildContext context, Friendship friendship) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditFriendshipSheet(friendship: friendship),
    );
  }

  @override
  ConsumerState<EditFriendshipSheet> createState() =>
      _EditFriendshipSheetState();
}

class _EditFriendshipSheetState extends ConsumerState<EditFriendshipSheet> {
  late FriendshipKind _kind;
  late FriendshipCadence _cadence;
  late final TextEditingController _howWeMet;
  late final TextEditingController _notes;
  late Set<EntityId> _circleIds;
  var _circlesHydrated = false;

  @override
  void initState() {
    super.initState();
    _kind = widget.friendship.kind;
    _cadence = widget.friendship.cadence;
    _howWeMet = TextEditingController(text: widget.friendship.howWeMet ?? '');
    _notes = TextEditingController(text: widget.friendship.notes ?? '');
    _circleIds = {};
  }

  @override
  void dispose() {
    _howWeMet.dispose();
    _notes.dispose();
    super.dispose();
  }

  Set<EntityId> _selectedCircles(List<FriendshipCircleMembership> memberships) {
    if (_circlesHydrated) return _circleIds;
    return {
      for (final link in memberships)
        if (link.personId == widget.friendship.personId) link.circleId,
    };
  }

  Future<void> _save() async {
    final memberships =
        ref.read(friendshipMembershipsProvider).value ?? const [];
    final saved =
        await ref.read(relationsControllerProvider.notifier).saveFriendship(
              widget.friendship.copyWith(
                kind: _kind,
                cadence: _cadence,
                howWeMet: _howWeMet.text,
                clearHowWeMet: _howWeMet.text.trim().isEmpty,
                notes: _notes.text,
                clearNotes: _notes.text.trim().isEmpty,
              ),
              circleIds: _selectedCircles(memberships),
            );
    if (!mounted || saved == null) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(peopleProvider).value ?? const [];
    Person? person;
    for (final p in people) {
      if (p.id == widget.friendship.personId) {
        person = p;
        break;
      }
    }
    final circles = (ref.watch(friendshipCirclesProvider).value ??
            const [])
        .where((c) => !c.isArchived)
        .toList();
    final memberships =
        ref.watch(friendshipMembershipsProvider).value ?? const [];
    final selectedCircles = _selectedCircles(memberships);
    final interactionsAsync =
        ref.watch(personInteractionsProvider(widget.friendship.personId));
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
              AppStrings.friendshipEdit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (person != null) ...[
              const SizedBox(height: ColonySpacing.sm),
              Text(
                person.displayName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: ColonySpacing.lg),
            DropdownButtonFormField<FriendshipKind>(
              initialValue: _kind,
              decoration: const InputDecoration(
                labelText: AppStrings.friendshipKind,
              ),
              items: FriendshipKind.values
                  .map(
                    (k) => DropdownMenuItem(
                      value: k,
                      child: Text(AppStrings.friendshipKindLabel(k)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _kind = value);
              },
            ),
            const SizedBox(height: ColonySpacing.md),
            DropdownButtonFormField<FriendshipCadence>(
              initialValue: _cadence,
              decoration: const InputDecoration(
                labelText: AppStrings.friendshipCadence,
              ),
              items: FriendshipCadence.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(AppStrings.friendshipCadenceLabel(c)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _cadence = value);
              },
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _howWeMet,
              decoration: const InputDecoration(
                labelText: AppStrings.friendshipHowWeMet,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: AppStrings.friendshipNotesOptional,
              ),
            ),
            if (circles.isNotEmpty) ...[
              const SizedBox(height: ColonySpacing.md),
              Text(
                AppStrings.friendshipCirclesTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Wrap(
                spacing: ColonySpacing.sm,
                children: [
                  for (final circle in circles)
                    FilterChip(
                      label: Text(circle.name),
                      selected: selectedCircles.contains(circle.id),
                      onSelected: (selected) {
                        setState(() {
                          _circleIds = {...selectedCircles};
                          _circlesHydrated = true;
                          if (selected) {
                            _circleIds.add(circle.id);
                          } else {
                            _circleIds.remove(circle.id);
                          }
                        });
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: ColonySpacing.md),
            interactionsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(AppStrings.errorGeneric),
              data: (items) {
                final encounters =
                    items.where((i) => i.kind.isEncounter).toList();
                if (encounters.isEmpty) {
                  return Text(AppStrings.friendshipNeverMet);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.encounterCountLabel(encounters.length),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    for (final ix in encounters.take(6))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(AppStrings.interactionKindLabel(ix.kind)),
                        subtitle: Text(
                          [
                            ix.occurredAt.toIso8601String().split('T').first,
                            if (ix.note != null) ix.note!,
                          ].join(' · '),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: ColonySpacing.md),
            if (person != null)
              OutlinedButton.icon(
                onPressed: () => LogEncounterSheet.show(
                  context,
                  preselected: [person!],
                ),
                icon: const Icon(Icons.event_available_outlined),
                label: Text(AppStrings.friendshipLogEncounter),
              ),
            TextButton(
              onPressed: () async {
                await ref
                    .read(relationsControllerProvider.notifier)
                    .archiveFriendship(widget.friendship);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: Text(AppStrings.friendshipArchive),
            ),
            const SizedBox(height: ColonySpacing.md),
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
