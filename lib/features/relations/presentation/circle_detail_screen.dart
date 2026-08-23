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
import 'widgets/add_circle_member_sheet.dart';
import 'widgets/log_encounter_sheet.dart';

class CircleDetailScreen extends ConsumerWidget {
  const CircleDetailScreen({super.key, required this.circleId});

  final EntityId circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circles = ref.watch(friendshipCirclesProvider).value ?? const [];
    FriendshipCircle? circle;
    for (final item in circles) {
      if (item.id == circleId) {
        circle = item;
        break;
      }
    }
    if (circle == null || circle.isArchived) {
      return Center(child: Text(AppStrings.circleNotFound));
    }
    final current = circle;
    final overviews = ref.watch(friendshipOverviewsProvider).value ?? const [];
    final members =
        overviews.where((row) => row.circles.any((c) => c.id == circleId)).toList();

    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        Row(
          children: [
            RelationsMark(asset: RelationsAssets.markCircle, size: 56),
            const SizedBox(width: ColonySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    AppStrings.circleMemberCount(members.length),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (current.defaultCadence != null)
                    Text(
                      AppStrings.friendshipCadenceLabel(current.defaultCadence!),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (current.notes != null) ...[
          const SizedBox(height: ColonySpacing.md),
          Text(current.notes!),
        ],
        const SizedBox(height: ColonySpacing.lg),
        Text(
          AppStrings.circleMembersTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: ColonySpacing.sm),
        if (members.isEmpty)
          Text(
            AppStrings.circleMembersEmpty,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          for (final row in members)
            Card(
              margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
              child: ListTile(
                leading: PersonGlyph(
                  person: row.person,
                  attention: row.rhythm.attention,
                ),
                title: Text(row.person.displayName),
                subtitle: Text(
                  [
                    AppStrings.friendshipKindLabel(row.friendship.kind),
                    AppStrings.daysSinceEncounter(
                      row.rhythm.daysSinceLastEncounter,
                    ),
                  ].join(' · '),
                ),
                onTap: () => openFriendshipDetail(context, row.friendship.id),
                trailing: IconButton(
                  tooltip: AppStrings.circleUnlinkMember,
                  icon: const Icon(Icons.link_off_outlined),
                  onPressed: () => ref
                      .read(relationsControllerProvider.notifier)
                      .unlinkPersonFromCircle(
                        personId: row.person.id,
                        circleId: current.id,
                      ),
                ),
              ),
            ),
        const SizedBox(height: ColonySpacing.xl),
        Wrap(
          spacing: ColonySpacing.sm,
          runSpacing: ColonySpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: () => AddCircleMemberSheet.show(context, current),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(AppStrings.circleAddMember),
            ),
            OutlinedButton.icon(
              onPressed: () => LogEncounterSheet.show(
                context,
                preselected: members.map((m) => m.person).toList(),
              ),
              icon: const Icon(Icons.event_available_outlined),
              label: Text(AppStrings.circleLogEncounter),
            ),
            TextButton.icon(
              onPressed: () async {
                await ref
                    .read(relationsControllerProvider.notifier)
                    .archiveCircle(current);
                if (!context.mounted) return;
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  goRelations(context, '/relations/circles');
                }
              },
              icon: const Icon(Icons.archive_outlined),
              label: Text(AppStrings.circleArchive),
            ),
          ],
        ),
      ],
    );
  }
}
