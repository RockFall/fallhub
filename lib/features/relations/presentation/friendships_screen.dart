import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/relations_providers.dart';
import 'widgets/create_friendship_circle_sheet.dart';
import 'widgets/create_friendship_sheet.dart';
import 'widgets/edit_friendship_sheet.dart';
import 'widgets/log_encounter_sheet.dart';

class FriendshipsScreen extends ConsumerStatefulWidget {
  const FriendshipsScreen({super.key});

  @override
  ConsumerState<FriendshipsScreen> createState() => _FriendshipsScreenState();
}

class _FriendshipsScreenState extends ConsumerState<FriendshipsScreen> {
  EntityId? _circleFilter;
  bool _overdueOnly = false;

  List<FriendshipOverview> _filter(List<FriendshipOverview> rows) {
    return rows.where((row) {
      if (_overdueOnly && !row.rhythm.needsAttention) return false;
      if (_circleFilter != null &&
          !row.circles.any((c) => c.id == _circleFilter)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(friendshipOverviewsProvider);
    final circlesAsync = ref.watch(friendshipCirclesProvider);

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.friendshipsTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.friendshipsDisclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.md),
          Wrap(
            spacing: ColonySpacing.sm,
            runSpacing: ColonySpacing.sm,
            children: [
              FilterChip(
                label: const Text(AppStrings.friendshipAllFilter),
                selected: !_overdueOnly && _circleFilter == null,
                onSelected: (_) {
                  setState(() {
                    _overdueOnly = false;
                    _circleFilter = null;
                  });
                },
              ),
              FilterChip(
                label: const Text(AppStrings.friendshipOverdueFilter),
                selected: _overdueOnly,
                onSelected: (selected) {
                  setState(() => _overdueOnly = selected);
                },
              ),
              ...circlesAsync.maybeWhen(
                data: (circles) => circles
                    .where((c) => !c.isArchived)
                    .map(
                      (circle) => FilterChip(
                        label: Text(circle.name),
                        selected: _circleFilter == circle.id,
                        onSelected: (selected) {
                          setState(() {
                            _circleFilter = selected ? circle.id : null;
                          });
                        },
                      ),
                    ),
                orElse: () => const <Widget>[],
              ),
            ],
          ),
          const SizedBox(height: ColonySpacing.lg),
          Expanded(
            child: board.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
              data: (rows) {
                final visible = _filter(rows);
                final attention =
                    rows.where((r) => r.rhythm.needsAttention).toList();
                if (rows.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.friendshipsEmpty),
                        const SizedBox(height: ColonySpacing.sm),
                        Text(
                          AppStrings.friendshipsEmptyHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }
                return ListView(
                  children: [
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
                      for (final row in attention.take(5))
                        _FriendshipTile(row: row, highlight: true),
                    const SizedBox(height: ColonySpacing.lg),
                    for (final row in visible) _FriendshipTile(row: row),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          Wrap(
            spacing: ColonySpacing.sm,
            runSpacing: ColonySpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: () => CreateFriendshipSheet.show(context),
                icon: const Icon(Icons.add),
                label: Text(AppStrings.friendshipNew),
              ),
              OutlinedButton.icon(
                onPressed: () => CreateFriendshipCircleSheet.show(context),
                icon: const Icon(Icons.group_outlined),
                label: Text(AppStrings.friendshipCircleNew),
              ),
              OutlinedButton.icon(
                onPressed: () => LogEncounterSheet.show(context),
                icon: const Icon(Icons.event_available_outlined),
                label: Text(AppStrings.friendshipLogEncounterMulti),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendshipTile extends StatelessWidget {
  const _FriendshipTile({required this.row, this.highlight = false});

  final FriendshipOverview row;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      AppStrings.friendshipKindLabel(row.friendship.kind),
      AppStrings.friendshipCadenceLabel(row.friendship.cadence),
      if (row.circles.isNotEmpty)
        row.circles.map((c) => c.name).join(', '),
      AppStrings.daysSinceEncounter(row.rhythm.daysSinceLastEncounter),
      AppStrings.friendshipAttentionLabel(row.rhythm.attention),
      if (row.rhythm.typicalIntervalDays != null)
        AppStrings.typicalIntervalLabel(row.rhythm.typicalIntervalDays!),
    ].join(' · ');
    return Card(
      color: highlight
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : null,
      margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
      child: ListTile(
        title: Text(row.person.displayName),
        subtitle: Text(subtitle),
        onTap: () => EditFriendshipSheet.show(context, row.friendship),
        trailing: IconButton(
          tooltip: AppStrings.friendshipLogEncounter,
          icon: const Icon(Icons.event_available_outlined),
          onPressed: () => LogEncounterSheet.show(
            context,
            preselected: [row.person],
          ),
        ),
      ),
    );
  }
}
