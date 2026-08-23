import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../finance/application/finance_providers.dart';
import '../../../flashcards/application/flashcard_providers.dart';
import '../../../health/application/health_providers.dart';
import '../../../pawn/application/pawn_providers.dart';
import '../../../pawn/presentation/widgets/check_in_sheet.dart';
import '../../../quests/application/quest_providers.dart';
import '../../../storyteller/presentation/narrative_digest_sheet.dart';
import '../../../work/application/work_providers.dart';
import '../../../activation/application/activation_controllers.dart';
import '../../../activation/presentation/widgets/agora_readiness_card.dart';

class ColonyHomeDigest extends ConsumerWidget {
  const ColonyHomeDigest({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _NowCard(),
        const SizedBox(height: ColonySpacing.lg),
        const AgoraReadinessCard(),
        const SizedBox(height: ColonySpacing.lg),
        const _StudyStrip(),
        const SizedBox(height: ColonySpacing.lg),
        const _Next24hCard(),
        const SizedBox(height: ColonySpacing.lg),
        const _ColonyStateCard(),
        const SizedBox(height: ColonySpacing.lg),
        const _ActiveQuestsCard(),
        const SizedBox(height: ColonySpacing.lg),
        const _NextActionsCard(),
        const SizedBox(height: ColonySpacing.lg),
        const _HealthReminderCard(),
        const SizedBox(height: ColonySpacing.lg),
        const _InboxCard(),
        const SizedBox(height: ColonySpacing.lg),
        ColonyHomeCard(
          icon: Icons.auto_stories_outlined,
          title: AppStrings.narrativeDigestTitle,
          onTap: () => showNarrativeDigestSheet(context),
          child: Text(
            AppStrings.homeWeeklyDigestCta,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColonyColors.accentCyan,
                ),
          ),
        ),
      ],
    );
  }
}

class _NowCard extends ConsumerWidget {
  const _NowCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).asData?.value;
    final checkIn = ref.watch(latestCheckInProvider);
    return ColonyHomeCard(
      icon: Icons.person_outline,
      title: AppStrings.homeNowTitle,
      action: TextButton(
        onPressed: () => CheckInSheet.show(context),
        child: const Text(AppStrings.checkIn),
      ),
      onTap: () => context.go('/pawn'),
      child: checkIn.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => Text(AppStrings.errorGeneric),
        data: (c) {
          final name = profile?.displayName ?? AppStrings.pawn;
          if (c == null) {
            return Text('$name · ${AppStrings.noCheckInYet}');
          }
          return Text(
            '$name · ${AppStrings.mood}: ${c.moodLabel} · ${AppStrings.energy}: ${c.energyLabel}',
          );
        },
      ),
    );
  }
}

class _StudyStrip extends ConsumerWidget {
  const _StudyStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digest = ref.watch(flashcardTodayDigestProvider);
    final capped = digest.cappedForSession;
    return ColonyHomeCard(
      icon: Icons.style_outlined,
      title: AppStrings.flashcardsTitle,
      onTap: () => context.go('/flashcards'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            capped == 0
                ? AppStrings.flashcardsDueTodayZero
                : AppStrings.flashcardsHeroStudyCount(capped),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (capped > 0) ...[
            const SizedBox(height: ColonySpacing.xs),
            Text(
              AppStrings.flashcardsMinutes(digest.estimatedMinutes),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColonyColors.accentCyan,
                  ),
            ),
            const SizedBox(height: ColonySpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: () => context.go('/flashcards/study'),
                child: const Text(AppStrings.homeQuickStudy),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Next24hCard extends ConsumerWidget {
  const _Next24hCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)().toLocal();
    final today = scheduleCalendarDay(now);
    final tomorrow = scheduleCalendarDay(now.add(const Duration(days: 1)));
    final todayItems = ref.watch(scheduleTimelineItemsProvider(today));
    final tomorrowItems = ref.watch(scheduleTimelineItemsProvider(tomorrow));

    return ColonyHomeCard(
      icon: Icons.schedule_outlined,
      title: AppStrings.homeNext24hTitle,
      action: IconButton(
        tooltip: AppStrings.schedule,
        icon: const Icon(Icons.chevron_right, size: 20),
        onPressed: () => context.go('/work/schedule'),
      ),
      child: Builder(
        builder: (context) {
          if (todayItems.isLoading || tomorrowItems.isLoading) {
            return const LinearProgressIndicator();
          }
          if (todayItems.hasError || tomorrowItems.hasError) {
            return Text(AppStrings.errorGeneric);
          }
          final horizon = now.add(const Duration(hours: 24));
          final items = <ScheduleTimelineItem>[
            ...todayItems.asData?.value ?? const [],
            ...tomorrowItems.asData?.value ?? const [],
          ]
              .where(
                (item) =>
                    item.endAt.toLocal().isAfter(now) &&
                    item.startAt.toLocal().isBefore(horizon),
              )
              .toList()
            ..sort((a, b) => a.startAt.compareTo(b.startAt));
          if (items.isEmpty) {
            return Text(AppStrings.homeNext24hEmpty);
          }
          return Column(
            children: [
              for (final item in items.take(4))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    item.kind == ScheduleTimelineItemKind.task
                        ? Icons.check_box_outlined
                        : Icons.timelapse,
                    size: 18,
                    color: ColonyColors.accentCyan,
                  ),
                  title: Text(item.label),
                  subtitle: Text(_hm(item.startAt)),
                  onTap: () => context.go('/work/schedule'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ColonyStateCard extends ConsumerWidget {
  const _ColonyStateCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkIn = ref.watch(latestCheckInProvider).asData?.value;
    final active = ref.watch(activeTasksProvider).asData?.value ?? const [];
    final accounts = ref.watch(financialAccountsProvider).asData?.value ?? const [];
    final appointments =
        ref.watch(healthAppointmentsProvider).asData?.value ?? const [];
    final digest = ref.watch(flashcardTodayDigestProvider);

    final nextCount = active
        .where(
          (t) => t.status == TaskStatus.next || t.status == TaskStatus.inbox,
        )
        .length;
    final upcoming = appointments.any(
      (a) =>
          a.status == HealthAppointmentStatus.scheduled &&
          !a.scheduledAt.isBefore(DateTime.now().toUtc()),
    );

    final chips = <(String, String, Color)>[
      (
        AppStrings.homeStateCapacity,
        checkIn == null
            ? AppStrings.homeStateUnknown
            : checkIn.energy < 0.45
                ? AppStrings.homeStateAttention
                : AppStrings.homeStateStable,
        checkIn == null
            ? ColonyColors.statusUnknown
            : checkIn.energy < 0.45
                ? ColonyColors.statusAttention
                : ColonyColors.statusGood,
      ),
      (
        AppStrings.homeStateCommitments,
        nextCount == 0
            ? AppStrings.homeStateUnderControl
            : nextCount > 5
                ? AppStrings.homeStateAttention
                : AppStrings.homeStateStable,
        nextCount > 5 ? ColonyColors.statusAttention : ColonyColors.statusGood,
      ),
      (
        AppStrings.homeStateFinance,
        accounts.isEmpty
            ? AppStrings.homeStateUnknown
            : AppStrings.homeStateLedgerLocal,
        accounts.isEmpty ? ColonyColors.statusUnknown : ColonyColors.statusInfo,
      ),
      (
        AppStrings.homeStateHealth,
        upcoming
            ? AppStrings.homeStateAttention
            : AppStrings.homeStateUnknown,
        upcoming ? ColonyColors.statusAttention : ColonyColors.statusUnknown,
      ),
      (
        AppStrings.homeStateLearning,
        digest.cappedForSession > 0
            ? AppStrings.homeStateProgress
            : AppStrings.homeStateStable,
        digest.cappedForSession > 0
            ? ColonyColors.accentCyan
            : ColonyColors.statusGood,
      ),
      (
        AppStrings.homeStateMind,
        checkIn == null
            ? AppStrings.homeStateUnknown
            : checkIn.tension > 0.65
                ? AppStrings.homeStateAttention
                : AppStrings.homeStateStable,
        checkIn == null
            ? ColonyColors.statusUnknown
            : checkIn.tension > 0.65
                ? ColonyColors.statusAttention
                : ColonyColors.statusGood,
      ),
    ];

    return ColonyHomeCard(
      icon: Icons.grid_view_outlined,
      title: AppStrings.homeStateTitle,
      child: Wrap(
        spacing: ColonySpacing.sm,
        runSpacing: ColonySpacing.sm,
        children: [
          for (final chip in chips)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ColonySpacing.md,
                vertical: ColonySpacing.sm,
              ),
              decoration: BoxDecoration(
                color: ColonyColors.raised,
                borderRadius: BorderRadius.circular(ColonyRadii.soft),
                border: Border.all(color: chip.$3.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chip.$1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ColonyColors.textMuted,
                        ),
                  ),
                  Text(
                    chip.$2,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: chip.$3,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActiveQuestsCard extends ConsumerWidget {
  const _ActiveQuestsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(questBoardProvider);
    final active = board.active.take(3).toList();
    return ColonyHomeCard(
      icon: Icons.flag_outlined,
      title: AppStrings.colonyActiveQuests,
      action: IconButton(
        tooltip: AppStrings.quests,
        icon: const Icon(Icons.chevron_right, size: 20),
        onPressed: () => context.go('/quests'),
      ),
      child: active.isEmpty
          ? Text(AppStrings.questBoardEmpty)
          : Column(
              children: [
                for (final quest in active)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(quest.title),
                    subtitle: Text(
                      quest.purpose,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => context.go('/quests/${quest.id.value}'),
                  ),
              ],
            ),
    );
  }
}

class _NextActionsCard extends ConsumerWidget {
  const _NextActionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeTasksProvider);
    return ColonyHomeCard(
      icon: Icons.playlist_add_check,
      title: AppStrings.nextActions,
      child: active.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => Text(AppStrings.errorGeneric),
        data: (tasks) {
          final next = tasks
              .where(
                (t) =>
                    t.status == TaskStatus.next || t.status == TaskStatus.inbox,
              )
              .take(3)
              .toList();
          if (next.isEmpty) return Text(AppStrings.emptyInbox);
          return Column(
            children: [
              for (final task in next)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(task.title),
                  subtitle: Text(AppStrings.taskStatusLabel(task.status)),
                  trailing: IconButton(
                    tooltip: AppStrings.activationMobilizeTask,
                    icon: const Icon(Icons.directions_walk_outlined),
                    onPressed: () async {
                      final episode = await ref
                          .read(activationControllerProvider.notifier)
                          .startForTask(taskId: task.id);
                      if (!context.mounted || episode == null) return;
                      context.go('/activation/episodes/${episode.id.value}');
                    },
                  ),
                  onTap: () => context.go('/tasks/${task.id.value}'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HealthReminderCard extends ConsumerWidget {
  const _HealthReminderCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(healthAppointmentsProvider);
    return ColonyHomeCard(
      icon: Icons.event_available_outlined,
      title: AppStrings.homeNextAppointment,
      onTap: () => context.go('/resources/health'),
      child: appointments.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => Text(AppStrings.errorGeneric),
        data: (items) {
          final now = DateTime.now().toUtc();
          final upcoming = items
              .where(
                (a) =>
                    a.status == HealthAppointmentStatus.scheduled &&
                    !a.scheduledAt.isBefore(now),
              )
              .toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
          if (upcoming.isEmpty) return Text(AppStrings.homeNoAppointment);
          final next = upcoming.first;
          return Text('${next.title} · ${_hm(next.scheduledAt)}');
        },
      ),
    );
  }
}

class _InboxCard extends ConsumerWidget {
  const _InboxCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(inboxTasksProvider);
    return ColonyHomeCard(
      icon: Icons.notifications_outlined,
      title: AppStrings.alerts,
      action: IconButton(
        tooltip: AppStrings.inbox,
        icon: const Icon(Icons.chevron_right, size: 20),
        onPressed: () => context.go('/inbox'),
      ),
      child: inbox.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => Text(AppStrings.errorGeneric),
        data: (tasks) {
          if (tasks.isEmpty) return Text(AppStrings.homeInboxEmpty);
          return Column(
            children: [
              for (final task in tasks.take(5))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.inbox_outlined, size: 18),
                  title: Text(task.title),
                  onTap: () => context.go('/inbox'),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _hm(DateTime value) {
  final local = value.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}