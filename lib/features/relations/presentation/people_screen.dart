import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/relations_controllers.dart';
import '../application/relations_providers.dart';
import 'widgets/create_person_sheet.dart';
import 'widgets/edit_person_sheet.dart';
import 'widgets/log_person_interaction_sheet.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(peopleProvider);

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
          const SizedBox(height: ColonySpacing.lg),
          Expanded(
            child: peopleAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
              data: (people) {
                final visible =
                    people.where((p) => !p.isArchived).toList();
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
                    final subtitle = [
                      if (person.preferredName != null) person.preferredName!,
                      if (person.relationshipTypes.isNotEmpty)
                        person.relationshipTypes.join(', '),
                    ].join(' · ');
                    return Card(
                      margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
                      child: ListTile(
                        title: Text(person.displayName),
                        subtitle: subtitle.isEmpty ? null : Text(subtitle),
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
