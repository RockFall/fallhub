import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/relations_controllers.dart';
import '../../application/relations_providers.dart';

class CreateFriendshipSheet extends ConsumerStatefulWidget {
  const CreateFriendshipSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateFriendshipSheet(),
    );
  }

  @override
  ConsumerState<CreateFriendshipSheet> createState() =>
      _CreateFriendshipSheetState();
}

class _CreateFriendshipSheetState extends ConsumerState<CreateFriendshipSheet> {
  Person? _person;
  final _newPersonName = TextEditingController();
  final _howWeMet = TextEditingController();
  final _notes = TextEditingController();
  FriendshipKind _kind = FriendshipKind.unspecified;
  late FriendshipCadence _cadence = _kind.suggestedCadence;
  final _circleIds = <EntityId>{};
  String? _personError;

  @override
  void dispose() {
    _newPersonName.dispose();
    _howWeMet.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    var person = _person;
    if (person == null && _newPersonName.text.trim().isNotEmpty) {
      person = await ref.read(relationsControllerProvider.notifier).create(
            displayName: _newPersonName.text.trim(),
          );
    }
    if (person == null) {
      setState(() => _personError = AppStrings.friendshipPickPersonRequired);
      return;
    }
    final created =
        await ref.read(relationsControllerProvider.notifier).ensureFriendship(
              person: person,
              kind: _kind,
              cadence: _cadence,
              howWeMet: _howWeMet.text,
              notes: _notes.text,
              circleIds: _circleIds,
            );
    if (!mounted || created == null) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final people = (ref.watch(peopleProvider).valueOrNull ?? const [])
        .where((p) => !p.isArchived)
        .toList();
    final existing = {
      for (final f in ref.watch(friendshipsProvider).valueOrNull ?? const [])
        if (!f.isArchived) f.personId,
    };
    final available = people.where((p) => !existing.contains(p.id)).toList();
    final circles = (ref.watch(friendshipCirclesProvider).valueOrNull ??
            const [])
        .where((c) => !c.isArchived)
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
              AppStrings.friendshipNew,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            DropdownButtonFormField<Person>(
              initialValue: _person,
              decoration: InputDecoration(
                labelText: AppStrings.friendshipPickPerson,
                errorText: _personError,
              ),
              items: available
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _person = value;
                _personError = null;
              }),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _newPersonName,
              decoration: const InputDecoration(
                labelText: AppStrings.friendshipCreatePersonHint,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
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
                if (value == null) return;
                setState(() {
                  _kind = value;
                  _cadence = value.suggestedCadence;
                });
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
                      selected: _circleIds.contains(circle.id),
                      onSelected: (selected) {
                        setState(() {
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
