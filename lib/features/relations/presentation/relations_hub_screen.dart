import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/relations_providers.dart';
import '../../colony/presentation/colony_mini_apps.dart';
import 'relations_navigation.dart';
import 'relations_visuals.dart';
import 'widgets/create_friendship_sheet.dart';
import 'widgets/create_person_sheet.dart';
import 'widgets/log_encounter_sheet.dart';

class RelationsHubScreen extends ConsumerWidget {
  const RelationsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider).value ?? const [];
    final board = ref.watch(friendshipOverviewsProvider);
    final circles = ref.watch(friendshipCirclesProvider).value ?? const [];
    final activePeople = people.where((p) => !p.isArchived).toList();
    final activeCircles = circles.where((c) => !c.isArchived).toList();
    final overviews = board.value ?? const [];
    final attention = overviews.where((r) => r.rhythm.needsAttention).toList();
    final now = DateTime.now().toUtc();
    final birthdays = activePeople.where((p) {
      final b = p.birthday;
      return b != null && b.month == now.month;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        RelationsHeroBanner(
          title: AppStrings.relationsHubTitle,
          subtitle: AppStrings.relationsHubHint,
        ),
        const SizedBox(height: ColonySpacing.lg),
        Wrap(
          spacing: ColonySpacing.sm,
          runSpacing: ColonySpacing.sm,
          children: [
            _HubStat(
              label: AppStrings.relationsStatsPeople,
              value: '${activePeople.length}',
              color: ColonyMiniAppColors.people,
            ),
            _HubStat(
              label: AppStrings.relationsStatsFriendships,
              value: '${overviews.length}',
              color: ColonyMiniAppColors.friendships,
            ),
            _HubStat(
              label: AppStrings.relationsStatsCircles,
              value: '${activeCircles.length}',
              color: const Color(0xFF7B5EA7),
            ),
            _HubStat(
              label: AppStrings.relationsStatsAttention,
              value: '${attention.length}',
              color: ColonyColors.statusRisk,
            ),
          ],
        ),
        const SizedBox(height: ColonySpacing.lg),
        Wrap(
          spacing: ColonySpacing.sm,
          runSpacing: ColonySpacing.sm,
          children: [
            _HubDoor(
              asset: ColonyMiniAppAssets.people,
              label: AppStrings.peopleTitle,
              onTap: () => goRelations(context, '/relations/people'),
            ),
            _HubDoor(
              asset: ColonyMiniAppAssets.friendships,
              label: AppStrings.friendshipsTitle,
              onTap: () => goRelations(context, '/relations/friendships'),
            ),
            _HubDoor(
              asset: ColonyMiniAppAssets.circles,
              label: AppStrings.relationsCirclesTitle,
              onTap: () => goRelations(context, '/relations/circles'),
            ),
            _HubDoor(
              asset: ColonyMiniAppAssets.encounters,
              label: AppStrings.relationsEncountersTitle,
              onTap: () => goRelations(context, '/relations/encounters'),
            ),
          ],
        ),
        const SizedBox(height: ColonySpacing.xl),
        Text(
          AppStrings.friendshipAttentionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: ColonySpacing.sm),
        if (attention.isEmpty)
          Text(
            AppStrings.friendshipAttentionEmpty,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: attention.length,
              separatorBuilder: (_, _) => const SizedBox(width: ColonySpacing.sm),
              itemBuilder: (context, index) {
                final row = attention[index];
                return _AttentionCard(row: row);
              },
            ),
          ),
        const SizedBox(height: ColonySpacing.xl),
        Text(
          AppStrings.relationsBirthdaysTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: ColonySpacing.sm),
        if (birthdays.isEmpty)
          Text(
            AppStrings.relationsBirthdaysEmpty,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          for (final person in birthdays)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: PersonGlyph(person: person),
              title: Text(person.displayName),
              subtitle: Text(
                AppStrings.birthdayOnLabel(
                  person.birthday!.day,
                  person.birthday!.month,
                ),
              ),
              onTap: () => openPersonDetail(context, person.id),
            ),
        const SizedBox(height: ColonySpacing.xl),
        Wrap(
          spacing: ColonySpacing.sm,
          runSpacing: ColonySpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: () => CreatePersonSheet.show(context),
              icon: const Icon(Icons.person_add_outlined),
              label: Text(AppStrings.personNew),
            ),
            OutlinedButton.icon(
              onPressed: () => CreateFriendshipSheet.show(context),
              icon: const Icon(Icons.favorite_outline),
              label: Text(AppStrings.friendshipNew),
            ),
            OutlinedButton.icon(
              onPressed: () => LogEncounterSheet.show(context),
              icon: const Icon(Icons.event_available_outlined),
              label: Text(AppStrings.friendshipLogEncounter),
            ),
          ],
        ),
      ],
    );
  }
}

class _HubStat extends StatelessWidget {
  const _HubStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.all(ColonySpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(ColonyRadii.soft),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _HubDoor extends StatelessWidget {
  const _HubDoor({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ColonyRadii.soft),
      child: SizedBox(
        width: 86,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                asset,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    const SizedBox(width: 56, height: 56, child: Icon(Icons.apps)),
              ),
            ),
            const SizedBox(height: ColonySpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.row});

  final FriendshipOverview row;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openFriendshipDetail(context, row.friendship.id),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(ColonySpacing.md),
        decoration: BoxDecoration(
          color: friendshipAttentionColor(row.rhythm.attention)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(ColonyRadii.soft),
        ),
        child: Row(
          children: [
            PersonGlyph(
              person: row.person,
              attention: row.rhythm.attention,
            ),
            const SizedBox(width: ColonySpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    row.person.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    AppStrings.daysSinceEncounter(
                      row.rhythm.daysSinceLastEncounter,
                    ),
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
