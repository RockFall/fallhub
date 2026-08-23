import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/relations_controllers.dart';
import '../application/relations_providers.dart';
import 'relations_assets.dart';
import 'relations_navigation.dart';
import 'relations_visuals.dart';
import 'widgets/edit_friendship_sheet.dart';
import 'widgets/log_encounter_sheet.dart';

class FriendshipDetailScreen extends ConsumerWidget {
  const FriendshipDetailScreen({super.key, required this.friendshipId});

  final EntityId friendshipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviews = ref.watch(friendshipOverviewsProvider).value ?? const [];
    FriendshipOverview? row;
    for (final item in overviews) {
      if (item.friendship.id == friendshipId) {
        row = item;
        break;
      }
    }
    if (row == null) {
      return Center(child: Text(AppStrings.friendshipNotFound));
    }
    final current = row;
    final interactionsAsync =
        ref.watch(personInteractionsProvider(current.person.id));
    final attentionColor = friendshipAttentionColor(current.rhythm.attention);

    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        Row(
          children: [
            PersonGlyph(
              person: current.person,
              attention: current.rhythm.attention,
              size: 72,
            ),
            const SizedBox(width: ColonySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current.person.displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  FriendshipKindChip(kind: current.friendship.kind),
                ],
              ),
            ),
            CadenceRing(rhythm: current.rhythm, size: 72),
          ],
        ),
        const SizedBox(height: ColonySpacing.md),
        Container(
          padding: const EdgeInsets.all(ColonySpacing.md),
          decoration: BoxDecoration(
            color: attentionColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(ColonyRadii.soft),
            border: Border.all(color: attentionColor.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.friendshipRhythmTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: ColonySpacing.xs),
              Text(AppStrings.friendshipCadenceLabel(current.friendship.cadence)),
              Text(AppStrings.daysSinceEncounter(
                current.rhythm.daysSinceLastEncounter,
              )),
              Text(AppStrings.friendshipAttentionLabel(current.rhythm.attention)),
              Text(AppStrings.encounterCountLabel(current.rhythm.encounterCount)),
              if (current.rhythm.typicalIntervalDays != null)
                Text(
                  AppStrings.typicalIntervalLabel(
                    current.rhythm.typicalIntervalDays!,
                  ),
                ),
              if (current.rhythm.cadenceDueAt != null)
                Text(AppStrings.friendshipDueOn(current.rhythm.cadenceDueAt!)),
              const SizedBox(height: ColonySpacing.sm),
              interactionsAsync.maybeWhen(
                data: (items) => EncounterSparkline(
                  dates: items
                      .where((ix) => ix.kind.isEncounter)
                      .map((ix) => ix.occurredAt)
                      .toList(),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        if (current.friendship.howWeMet != null) ...[
          const SizedBox(height: ColonySpacing.lg),
          Text(
            AppStrings.friendshipHowWeMetTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(current.friendship.howWeMet!),
        ],
        if (current.friendship.notes != null) ...[
          const SizedBox(height: ColonySpacing.md),
          Text(current.friendship.notes!),
        ],
        const SizedBox(height: ColonySpacing.lg),
        Text(
          AppStrings.friendshipCirclesTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (current.circles.isEmpty)
          Text(
            AppStrings.friendshipCircleNone,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Wrap(
            spacing: ColonySpacing.sm,
            children: [
              for (final circle in current.circles)
                ActionChip(
                  avatar: RelationsMark(asset: RelationsAssets.markCircle, size: 18),
                  label: Text(circle.name),
                  onPressed: () => openCircleDetail(context, circle.id),
                ),
            ],
          ),
        const SizedBox(height: ColonySpacing.lg),
        Text(
          AppStrings.relationsEncountersTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        interactionsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, st) => Text(AppStrings.errorGeneric),
          data: (items) {
            final encounters =
                items.where((ix) => ix.kind.isEncounter).toList();
            if (encounters.isEmpty) {
              return Text(AppStrings.relationsEncountersEmpty);
            }
            return Column(
              children: [
                for (final ix in encounters.take(16))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: RelationsMark(
                      asset: RelationsAssets.markEncounter,
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
                preselected: [current.person],
              ),
              icon: const Icon(Icons.event_available_outlined),
              label: Text(AppStrings.friendshipLogEncounter),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  EditFriendshipSheet.show(context, current.friendship),
              icon: const Icon(Icons.edit_outlined),
              label: Text(AppStrings.friendshipEdit),
            ),
            OutlinedButton.icon(
              onPressed: () => openPersonDetail(context, current.person.id),
              icon: const Icon(Icons.badge_outlined),
              label: Text(AppStrings.friendshipOpenPerson),
            ),
            TextButton.icon(
              onPressed: () async {
                await ref
                    .read(relationsControllerProvider.notifier)
                    .archiveFriendship(current.friendship);
                if (!context.mounted) return;
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  goRelations(context, '/relations/friendships');
                }
              },
              icon: const Icon(Icons.archive_outlined),
              label: Text(AppStrings.friendshipArchive),
            ),
          ],
        ),
      ],
    );
  }
}
