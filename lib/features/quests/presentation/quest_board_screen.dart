import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/app_strings.dart';
import '../application/quest_controllers.dart';
import '../application/quest_providers.dart';
import 'widgets/create_quest_sheet.dart';

String _questControllerErrorMessage(Object error) {
  if (error is QuestPrerequisiteException) {
    if (error.message.contains('circular')) {
      return AppStrings.questPrerequisiteCycle;
    }
    if (error.message.contains('si mesma')) {
      return AppStrings.questPrerequisiteSelfLink;
    }
    return AppStrings.questActivateBlockedPrerequisites;
  }
  return AppStrings.errorGeneric;
}

class QuestBoardScreen extends ConsumerStatefulWidget {
  const QuestBoardScreen({super.key});

  @override
  ConsumerState<QuestBoardScreen> createState() => _QuestBoardScreenState();
}

class _QuestBoardScreenState extends ConsumerState<QuestBoardScreen> {
  String? _lastHandledCreateUri;
  GoRouter? _trackedRouter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (router != null && !identical(_trackedRouter, router)) {
      _trackedRouter?.routerDelegate.removeListener(_onRouterChanged);
      _trackedRouter = router;
      _trackedRouter!.routerDelegate.addListener(_onRouterChanged);
    }
    _syncCreateDeepLinkState();
    _handleCreateDeepLink();
  }

  @override
  void dispose() {
    _trackedRouter?.routerDelegate.removeListener(_onRouterChanged);
    super.dispose();
  }

  void _onRouterChanged() {
    if (!mounted) return;
    _syncCreateDeepLinkState();
    _handleCreateDeepLink();
  }

  void _syncCreateDeepLinkState() {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final uri = router.routerDelegate.currentConfiguration.uri;
    if (uri.queryParameters['create'] != '1') {
      _lastHandledCreateUri = null;
    }
  }

  void _handleCreateDeepLink() {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final uri = router.routerDelegate.currentConfiguration.uri;
    if (uri.queryParameters['create'] != '1') return;
    final key = uri.toString();
    if (_lastHandledCreateUri == key) return;
    _lastHandledCreateUri = key;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await CreateQuestSheet.show(context);
      if (!mounted) return;
      _lastHandledCreateUri = null;
      final currentRouter = GoRouter.maybeOf(context);
      if (currentRouter == null) return;
      final currentUri = currentRouter.routerDelegate.currentConfiguration.uri;
      if (currentUri.queryParameters['create'] == '1') {
        context.go('/quests');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(questControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_questControllerErrorMessage(next.error!))),
        );
      }
    });

    final board = ref.watch(questBoardProvider);
    final questsAsync = ref.watch(questsProvider);

    return questsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
      data: (_) {
        if (board.isEmpty) {
          return _EmptyBoard(onCreate: () => CreateQuestSheet.show(context));
        }

        return ListView(
          padding: const EdgeInsets.all(ColonySpacing.lg),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.quests,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => CreateQuestSheet.show(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(AppStrings.newQuest),
                ),
              ],
            ),
            const SizedBox(height: ColonySpacing.lg),
            if (board.active.isNotEmpty)
              _QuestSection(
                title: AppStrings.questSectionActive,
                quests: board.active,
              ),
            if (board.paused.isNotEmpty)
              _QuestSection(
                title: AppStrings.questSectionPaused,
                quests: board.paused,
              ),
            if (board.drafts.isNotEmpty)
              _QuestSection(
                title: AppStrings.questSectionDrafts,
                quests: board.drafts,
              ),
            if (board.history.isNotEmpty)
              _QuestSection(
                title: AppStrings.questSectionHistory,
                quests: board.history,
              ),
          ],
        );
      },
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ColonySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 48,
              color: ColonyColors.borderStandard,
            ),
            const SizedBox(height: ColonySpacing.lg),
            Text(
              AppStrings.questBoardEmpty,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ColonySpacing.sm),
            Text(
              AppStrings.questBoardEmptyHint,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ColonySpacing.lg),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.newQuest),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestSection extends StatelessWidget {
  const _QuestSection({required this.title, required this.quests});

  final String title;
  final List<Quest> quests;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ColonySpacing.lg),
      child: ColonyPanel(
        title: title,
        icon: Icons.flag_outlined,
        child: Column(
          children: quests
              .map((quest) => _QuestCard(quest: quest))
              .toList(),
        ),
      ),
    );
  }
}

class _QuestCard extends ConsumerWidget {
  const _QuestCard({required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final waiting = ref.watch(questWaitingOnPrerequisitesProvider(quest.id.value));

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(quest.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quest.purpose.isNotEmpty) Text(quest.purpose, maxLines: 2),
          if (quest.deadline != null)
            Text(
              '${AppStrings.questDeadline}: ${dateFormat.format(scheduleCalendarDay(quest.deadline!))}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (waiting)
            Padding(
              padding: const EdgeInsets.only(right: ColonySpacing.xs),
              child: Chip(
                label: Text(
                  AppStrings.questWaitingBadge,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          _StatusChip(status: quest.status),
        ],
      ),
      onTap: () => context.go('/quests/${quest.id.value}'),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final QuestStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        AppStrings.questStatusLabel(status),
        style: Theme.of(context).textTheme.labelSmall,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
