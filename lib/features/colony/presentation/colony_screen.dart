import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../pawn/application/pawn_providers.dart';
import '../../quests/application/quest_providers.dart';
import '../../pawn/presentation/widgets/check_in_sheet.dart';

class ColonyScreen extends ConsumerWidget {
  const ColonyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final inbox = ref.watch(inboxTasksProvider);
    final active = ref.watch(activeTasksProvider);

    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(AppStrings.errorGeneric)),
      data: (p) {
        if (p == null) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(ColonySpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${AppStrings.today} · ${p.colonyName}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: ColonySpacing.lg),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _leftColumn(context, ref, p, inbox, active)),
                        const SizedBox(width: ColonySpacing.lg),
                        SizedBox(
                          width: 320,
                          child: _alertsPanel(context, inbox),
                        ),
                      ],
                    )
                  else ...[
                    _leftColumn(context, ref, p, inbox, active),
                    const SizedBox(height: ColonySpacing.lg),
                    _alertsPanel(context, inbox),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _leftColumn(
    BuildContext context,
    WidgetRef ref,
    dynamic p,
    AsyncValue<List<ColonyTask>> inbox,
    AsyncValue<List<ColonyTask>> active,
  ) {
    final checkIn = ref.watch(latestCheckInProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColonyPanel(
          title: AppStrings.pawn,
          icon: Icons.person_outline,
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(p.displayName),
                subtitle: checkIn.when(
                  data: (c) => Text(
                    c == null
                        ? AppStrings.noCheckInYet
                        : '${AppStrings.mood}: ${c.moodLabel} · ${AppStrings.energy}: ${c.energyLabel}',
                  ),
                  loading: () => Text('${p.colonyName} · ${AppStrings.offlineReady}'),
                  error: (_, __) => Text('${p.colonyName} · ${AppStrings.offlineReady}'),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => context.go('/pawn'),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => CheckInSheet.show(context),
                  icon: const Icon(Icons.favorite_outline, size: 18),
                  label: const Text(AppStrings.checkIn),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ColonySpacing.lg),
        _ActiveQuestsPanel(),
        const SizedBox(height: ColonySpacing.lg),
        ColonyPanel(
          title: AppStrings.nextActions,
          icon: Icons.playlist_add_check,
          child: active.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text(AppStrings.errorGeneric),
            data: (tasks) {
              final next = tasks
                  .where(
                    (t) =>
                        t.status == TaskStatus.next ||
                        t.status == TaskStatus.inbox,
                  )
                  .take(3)
                  .toList();
              if (next.isEmpty) {
                return Text(AppStrings.emptyInbox);
              }
              return Column(
                children: next
                    .map(
                      (task) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(task.title),
                        subtitle: Text(AppStrings.taskStatusLabel(task.status)),
                        onTap: () => context.go('/tasks/${task.id.value}'),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
        const SizedBox(height: ColonySpacing.lg),
        _sectorGrid(context),
      ],
    );
  }

  Widget _sectorGrid(BuildContext context) {
    const sectors = [
      (AppStrings.habitatTitle, Icons.cottage_outlined, '/colony/habitat'),
      (AppStrings.habitatCreateTitle, Icons.face_retouching_natural, '/colony/pawn-create'),
      ('Saúde', Icons.favorite_outline, '/pawn'),
      ('Trabalho', Icons.work_outline, '/work'),
      ('Finanças', Icons.account_balance_wallet_outlined, '/resources/finance'),
      ('Caixa de entrada', Icons.inbox_outlined, '/inbox'),
    ];

    return ColonyPanel(
      title: 'Mapa operacional',
      icon: Icons.map_outlined,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: ColonySpacing.sm,
        crossAxisSpacing: ColonySpacing.sm,
        childAspectRatio: 2.4,
        children: sectors
            .map(
              (s) => OutlinedButton.icon(
                onPressed: () => context.go(s.$3),
                icon: Icon(s.$2, size: 18),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(s.$1),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _alertsPanel(BuildContext context, AsyncValue<List<ColonyTask>> inbox) {
    return ColonyPanel(
      title: AppStrings.alerts,
      icon: Icons.notifications_outlined,
      child: inbox.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => Text(AppStrings.errorGeneric),
        data: (tasks) {
          if (tasks.isEmpty) {
            return Text('Nenhum item pendente na inbox.');
          }
          return Column(
            children: tasks
                .take(5)
                .map(
                  (task) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inbox_outlined, size: 18),
                    title: Text(task.title),
                    dense: true,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _ActiveQuestsPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(questBoardProvider);

    return ColonyPanel(
      title: AppStrings.colonyActiveQuests,
      icon: Icons.flag_outlined,
      actions: [
        IconButton(
          tooltip: AppStrings.quests,
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: () => context.go('/quests'),
        ),
      ],
      child: Builder(
        builder: (context) {
          final active = board.active.take(3).toList();
          if (active.isEmpty) {
            return Text(
              AppStrings.questBoardEmpty,
              style: Theme.of(context).textTheme.bodyMedium,
            );
          }
          return Column(
            children: active
                .map(
                  (quest) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(quest.title),
                    subtitle: Text(
                      quest.purpose,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Chip(
                      label: Text(AppStrings.questStatusLabel(quest.status)),
                      visualDensity: VisualDensity.compact,
                    ),
                    onTap: () => context.go('/quests/${quest.id.value}'),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
