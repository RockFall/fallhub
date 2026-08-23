import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/relations_controllers.dart';
import '../application/relations_providers.dart';
import 'relations_navigation.dart';
import 'relations_visuals.dart';
import 'widgets/edit_friendship_sheet.dart';
import 'widgets/edit_person_sheet.dart';
import 'widgets/log_encounter_sheet.dart';
import 'widgets/log_person_interaction_sheet.dart';

class PersonDetailScreen extends ConsumerWidget {
  const PersonDetailScreen({super.key, required this.personId});

  final EntityId personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider).value ?? const [];
    Person? person;
    for (final p in people) {
      if (p.id == personId) {
        person = p;
        break;
      }
    }
    if (person == null) {
      return Center(child: Text(AppStrings.personNotFound));
    }

    final overviews = ref.watch(friendshipOverviewsProvider).value ?? const [];
    FriendshipOverview? overview;
    for (final row in overviews) {
      if (row.person.id == personId) {
        overview = row;
        break;
      }
    }
    final orgs = ref.watch(personMembershipsProvider(personId.value));
    final commitments = (ref.watch(commitmentsProvider).value ?? const [])
        .where((c) => c.madeToPersonId == personId && !c.status.isHiddenFromActiveList)
        .toList();
    final interactionsAsync = ref.watch(personInteractionsProvider(personId));
    final current = person;

    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        Row(
          children: [
            PersonGlyph(
              person: current,
              attention: overview?.rhythm.attention,
              size: 64,
            ),
            const SizedBox(width: ColonySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current.displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (current.preferredName != null)
                    Text(
                      current.preferredName!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  Text(
                    AppStrings.lastContactLabel(
                      current.lastInteractionAt == null
                          ? null
                          : DateTime.now()
                              .toUtc()
                              .difference(current.lastInteractionAt!.toUtc())
                              .inDays,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (current.relationshipTypes.isNotEmpty) ...[
          const SizedBox(height: ColonySpacing.md),
          Wrap(
            spacing: ColonySpacing.sm,
            children: [
              for (final type in current.relationshipTypes) Chip(label: Text(type)),
            ],
          ),
        ],
        if (current.birthday != null) ...[
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.birthdayOnLabel(
              current.birthday!.day,
              current.birthday!.month,
            ),
          ),
        ],
        if (current.notes != null) ...[
          const SizedBox(height: ColonySpacing.md),
          Text(current.notes!),
        ],
        const SizedBox(height: ColonySpacing.lg),
        if (overview != null)
          Card(
            child: ListTile(
              leading: CadenceRing(rhythm: overview.rhythm),
              title: Text(AppStrings.friendshipRhythmTitle),
              subtitle: Text(
                [
                  AppStrings.friendshipKindLabel(overview.friendship.kind),
                  AppStrings.daysSinceEncounter(
                    overview.rhythm.daysSinceLastEncounter,
                  ),
                  AppStrings.friendshipAttentionLabel(overview.rhythm.attention),
                ].join(' · '),
              ),
              onTap: () =>
                  openFriendshipDetail(context, overview!.friendship.id),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: () async {
              await ref
                  .read(relationsControllerProvider.notifier)
                  .ensureFriendship(person: current);
              if (!context.mounted) return;
              final created = ref.read(friendshipForPersonProvider(personId));
              if (created != null) {
                await EditFriendshipSheet.show(context, created);
              }
            },
            icon: const Icon(Icons.favorite_outline),
            label: Text(AppStrings.personAddToFriendships),
          ),
        if (overview != null && overview.circles.isNotEmpty) ...[
          const SizedBox(height: ColonySpacing.md),
          Text(
            AppStrings.friendshipCirclesTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Wrap(
            spacing: ColonySpacing.sm,
            children: [
              for (final circle in overview.circles)
                ActionChip(
                  label: Text(circle.name),
                  onPressed: () => openCircleDetail(context, circle.id),
                ),
            ],
          ),
        ],
        const SizedBox(height: ColonySpacing.lg),
        Text(
          AppStrings.relationsOpenOrganizations,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        orgs.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, st) => Text(AppStrings.errorGeneric),
          data: (items) {
            final visible = items.where((o) => !o.isArchived).toList();
            if (visible.isEmpty) {
              return Text(
                AppStrings.organizationNoMembers,
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
            return Column(
              children: [
                for (final org in visible)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(org.name),
                    subtitle: Text(AppStrings.organizationKindLabel(org.kind)),
                    onTap: () => goRelations(context, '/relations/organizations'),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: ColonySpacing.md),
        Text(
          AppStrings.relationsOpenCommitments,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (commitments.isEmpty)
          Text(
            AppStrings.relationsNoCommitments,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          for (final c in commitments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(c.description),
              onTap: () => goRelations(context, '/relations/commitments'),
            ),
        const SizedBox(height: ColonySpacing.lg),
        Text(
          AppStrings.personInteractionsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        interactionsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, st) => Text(AppStrings.errorGeneric),
          data: (items) {
            if (items.isEmpty) {
              return Text(AppStrings.personInteractionsEmpty);
            }
            return Column(
              children: [
                for (final ix in items.take(12))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      ix.kind.isEncounter
                          ? Icons.event_available_outlined
                          : Icons.chat_bubble_outline,
                    ),
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
        const SizedBox(height: ColonySpacing.xl),
        Wrap(
          spacing: ColonySpacing.sm,
          runSpacing: ColonySpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: () => LogEncounterSheet.show(
                context,
                preselected: [current],
              ),
              icon: const Icon(Icons.event_available_outlined),
              label: Text(AppStrings.friendshipLogEncounter),
            ),
            OutlinedButton.icon(
              onPressed: () => LogPersonInteractionSheet.show(context, current),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(AppStrings.personLogInteraction),
            ),
            OutlinedButton.icon(
              onPressed: () => EditPersonSheet.show(context, current),
              icon: const Icon(Icons.edit_outlined),
              label: Text(AppStrings.personEdit),
            ),
          ],
        ),
      ],
    );
  }
}
