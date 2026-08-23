import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/relations_controllers.dart';
import '../application/relations_providers.dart';
import 'widgets/create_person_sheet.dart';
import 'widgets/edit_person_sheet.dart';
import 'widgets/log_person_interaction_sheet.dart';

enum _PeopleSort { name, lastContact }

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  final _search = TextEditingController();
  _PeopleSort _sort = _PeopleSort.lastContact;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int? _daysSince(DateTime? at) {
    if (at == null) return null;
    return DateTime.now().toUtc().difference(at.toUtc()).inDays;
  }

  List<Person> _visible(List<Person> people) {
    final query = _search.text.trim().toLowerCase();
    var visible = people.where((p) => !p.isArchived).toList();
    if (query.isNotEmpty) {
      visible = visible.where((p) {
        final haystack = [
          p.displayName,
          p.preferredName ?? '',
          ...p.relationshipTypes,
          p.notes ?? '',
        ].join(' ').toLowerCase();
        return haystack.contains(query);
      }).toList();
    }
    visible.sort((a, b) {
      if (_sort == _PeopleSort.name) {
        return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      }
      final aAt = a.lastInteractionAt;
      final bAt = b.lastInteractionAt;
      if (aAt == null && bAt == null) {
        return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      }
      if (aAt == null) return 1;
      if (bAt == null) return -1;
      return bAt.compareTo(aAt);
    });
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(peopleProvider);
    final friendships = ref.watch(friendshipsProvider).value ?? const [];

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.peopleTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.peopleDisclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.md),
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: AppStrings.personSearchHint,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: ColonySpacing.sm),
          SegmentedButton<_PeopleSort>(
            segments: const [
              ButtonSegment(
                value: _PeopleSort.lastContact,
                label: Text(AppStrings.personSortLastContact),
              ),
              ButtonSegment(
                value: _PeopleSort.name,
                label: Text(AppStrings.personSortName),
              ),
            ],
            selected: {_sort},
            onSelectionChanged: (value) {
              setState(() => _sort = value.first);
            },
          ),
          const SizedBox(height: ColonySpacing.lg),
          Expanded(
            child: peopleAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
              data: (people) {
                final visible = _visible(people);
                if (visible.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.peopleEmpty),
                        const SizedBox(height: ColonySpacing.sm),
                        Text(
                          AppStrings.peopleEmptyHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final person = visible[index];
                    Friendship? friendship;
                    for (final f in friendships) {
                      if (f.personId == person.id && !f.isArchived) {
                        friendship = f;
                        break;
                      }
                    }
                    final subtitle = [
                      if (person.preferredName != null) person.preferredName!,
                      if (person.relationshipTypes.isNotEmpty)
                        person.relationshipTypes.join(', '),
                      if (friendship != null)
                        AppStrings.friendshipKindLabel(friendship.kind),
                      AppStrings.lastContactLabel(
                        _daysSince(person.lastInteractionAt),
                      ),
                    ].join(' · ');
                    return Card(
                      margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
                      child: ListTile(
                        title: Text(person.displayName),
                        subtitle: Text(subtitle),
                        onTap: () => EditPersonSheet.show(context, person),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: AppStrings.personLogInteraction,
                              icon: const Icon(Icons.chat_bubble_outline),
                              onPressed: () => LogPersonInteractionSheet.show(
                                context,
                                person,
                              ),
                            ),
                            IconButton(
                              tooltip: AppStrings.personArchive,
                              icon: const Icon(Icons.archive_outlined),
                              onPressed: () => ref
                                  .read(relationsControllerProvider.notifier)
                                  .archive(person),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          FilledButton.icon(
            onPressed: () => CreatePersonSheet.show(context),
            icon: const Icon(Icons.add),
            label: Text(AppStrings.personNew),
          ),
        ],
      ),
    );
  }
}
