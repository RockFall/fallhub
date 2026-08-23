import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/relations_providers.dart';
import 'relations_assets.dart';
import 'relations_navigation.dart';
import 'relations_shortcut_bar.dart';
import 'relations_visuals.dart';
import 'widgets/log_encounter_sheet.dart';

class EncountersChronicleScreen extends ConsumerWidget {
  const EncountersChronicleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactionsAsync = ref.watch(allPersonInteractionsProvider);
    final people = {
      for (final p in ref.watch(peopleProvider).value ?? const []) p.id: p,
    };

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.relationsEncountersTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.relationsEncountersHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.md),
          const RelationsShortcutBar(current: RelationsDoor.encounters),
          const SizedBox(height: ColonySpacing.lg),
          Expanded(
            child: interactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text(AppStrings.errorGeneric)),
              data: (items) {
                final encounters = items
                    .where((ix) => ix.kind.isEncounter)
                    .toList()
                  ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
                if (encounters.isEmpty) {
                  return RelationsEmptyState(
                    asset: RelationsAssets.emptyEncounters,
                    title: AppStrings.relationsEncountersEmpty,
                    hint: AppStrings.relationsEncountersEmptyHint,
                  );
                }
                final groups = <DateTime, List<PersonInteraction>>{};
                for (final ix in encounters) {
                  final local = ix.occurredAt.toLocal();
                  final day = DateTime(local.year, local.month, local.day);
                  groups.putIfAbsent(day, () => []).add(ix);
                }
                final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
                return ListView(
                  children: [
                    for (final day in days) ...[
                      Text(
                        AppStrings.encounterDayLabel(day),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: ColonySpacing.sm),
                      for (final ix in groups[day]!)
                        Card(
                          margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
                          child: ListTile(
                            leading: people[ix.personId] == null
                                ? RelationsMark(
                                    asset: RelationsAssets.markEncounter,
                                  )
                                : PersonGlyph(person: people[ix.personId]!),
                            title: Text(
                              people[ix.personId]?.displayName ??
                                  AppStrings.personNotFound,
                            ),
                            subtitle: Text(
                              [
                                AppStrings.interactionKindLabel(ix.kind),
                                if (ix.note != null) ix.note!,
                              ].join(' · '),
                            ),
                            trailing: RelationsMark(
                              asset: RelationsAssets.markEncounter,
                              size: 28,
                            ),
                            onTap: people[ix.personId] == null
                                ? null
                                : () => openPersonDetail(
                                      context,
                                      ix.personId,
                                    ),
                          ),
                        ),
                      const SizedBox(height: ColonySpacing.md),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          FilledButton.icon(
            onPressed: () => LogEncounterSheet.show(context),
            icon: const Icon(Icons.event_available_outlined),
            label: Text(AppStrings.friendshipLogEncounterMulti),
          ),
        ],
      ),
    );
  }
}
