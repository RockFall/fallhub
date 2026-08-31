import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../activation/application/activation_providers.dart';
import '../../../health/application/health_providers.dart';
import '../../../quests/application/quest_providers.dart';
import '../../application/pawn_providers.dart';
import 'pawn_tab_chrome.dart';

class PawnSummaryTab extends ConsumerWidget {
  const PawnSummaryTab({
    super.key,
    required this.onOpenNeeds,
    required this.onOpenActivation,
  });

  final VoidCallback onOpenNeeds;
  final VoidCallback onOpenActivation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needs = ref.watch(needSnapshotsProvider);
    final checkIn = ref.watch(latestCheckInProvider).asData?.value;
    final daily = ref.watch(todayDailyReviewProvider).asData?.value;
    final weekly = ref.watch(currentWeekWeeklyReviewProvider).asData?.value;
    final openRoute = ref.watch(openActivationEpisodeProvider).asData?.value;
    final now = ref.watch(clockProvider)().toLocal();

    return PawnPane(
      child: needs.when(
        loading: () => const Center(child: PawnMutedText(AppStrings.loading)),
        error: (_, _) => const Center(child: Text(AppStrings.errorGeneric)),
        data: (snapshots) {
          final attention = _attentionQueue(snapshots);
          final hasReadings = snapshots.any((s) => s.normalizedValue != null);
          final sitrep = AppStrings.pawnSitrepLine(
            hasCheckIn: checkIn != null,
            checkInIsToday:
                checkIn != null && _isLocalDay(checkIn.observedAt, now),
            moodLabel: checkIn?.moodLabel,
            hasNeedReadings: hasReadings,
            attentionCount: attention.length,
            openRoute: openRoute != null,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PawnSectionLabel(AppStrings.pawnSituation),
              const SizedBox(height: 6),
              Text(
                sitrep,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColonyColors.textPrimary,
                  fontFamily: ColonyFonts.familyReadable,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 4),
              const PawnMutedText(AppStrings.pawnSummaryIntro),
              const SizedBox(height: ColonySpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: PawnStatusPlate(
                      label: AppStrings.dailyReview,
                      status: daily == null
                          ? AppStrings.pawnReviewPending
                          : AppStrings.pawnReviewLogged,
                      pending: daily == null,
                      onTap: () => context.go('/pawn/review'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PawnStatusPlate(
                      label: AppStrings.weeklyReview,
                      status: weekly == null
                          ? AppStrings.pawnReviewPending
                          : AppStrings.pawnReviewLogged,
                      pending: weekly == null,
                      onTap: () => context.go('/pawn/review/weekly'),
                    ),
                  ),
                ],
              ),
              const NeedInspectGroupRule(),
              const PawnSectionLabel(AppStrings.needsAttention),
              const SizedBox(height: 6),
              Expanded(
                flex: 3,
                child: attention.isEmpty
                    ? const PawnMutedText(AppStrings.needsStable)
                    : ListView(
                        children: [
                          for (final snapshot in attention)
                            SizedBox(
                              height: 36,
                              child: NeedInspectBar(
                                label: snapshot.definition.name,
                                value: snapshot.normalizedValue,
                                scale: NeedInspectBarScale.compact,
                                showChevron: true,
                                fillSlot: true,
                                semanticId:
                                    'pawn.summary.need.${snapshot.definition.slug}',
                                onTap: onOpenNeeds,
                              ),
                            ),
                        ],
                      ),
              ),
              const NeedInspectGroupRule(),
              const PawnSectionLabel(AppStrings.pawnNext),
              const SizedBox(height: 4),
              Expanded(
                flex: 2,
                child: _NextQueue(
                  openRoute: openRoute,
                  onOpenActivation: onOpenActivation,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static List<NeedSnapshot> _attentionQueue(List<NeedSnapshot> snapshots) {
    final low = <NeedSnapshot>[];
    final stale = <NeedSnapshot>[];
    for (final snapshot in snapshots) {
      final value = snapshot.normalizedValue;
      if (value != null && value < snapshot.definition.preferredMin) {
        low.add(snapshot);
      } else if (snapshot.freshness == DataFreshness.stale) {
        stale.add(snapshot);
      }
    }
    return [...low, ...stale].take(3).toList();
  }

  static bool _isLocalDay(DateTime utc, DateTime nowLocal) {
    final local = utc.toLocal();
    return local.year == nowLocal.year &&
        local.month == nowLocal.month &&
        local.day == nowLocal.day;
  }
}

class _NextQueue extends ConsumerWidget {
  const _NextQueue({required this.openRoute, required this.onOpenActivation});

  final ActivationEpisode? openRoute;
  final VoidCallback onOpenActivation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (openRoute != null) {
      return PawnLogRow(
        title: AppStrings.activationInRoute,
        detail: openRoute!.targetState.label,
        onTap: onOpenActivation,
      );
    }

    final now = ref.watch(clockProvider)();
    final appointments =
        ref.watch(healthAppointmentsProvider).asData?.value ?? const [];
    final upcoming = [
      for (final item in appointments)
        if (item.status == HealthAppointmentStatus.scheduled &&
            !item.scheduledAt.isBefore(now))
          item,
    ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    if (upcoming.isNotEmpty) {
      final next = upcoming.first;
      return PawnLogRow(
        title: AppStrings.homeNextAppointment,
        detail: next.title,
        onTap: () => context.go('/resources/health'),
      );
    }

    final inbox = ref.watch(inboxTasksProvider).asData?.value ?? const [];
    if (inbox.isNotEmpty) {
      return PawnLogRow(
        title: AppStrings.inbox,
        detail: inbox.first.title,
        onTap: () => context.go('/inbox'),
      );
    }

    final quests = ref.watch(questsProvider).asData?.value ?? const [];
    final active = [
      for (final quest in quests)
        if (quest.status == QuestStatus.active) quest,
    ];
    if (active.isNotEmpty) {
      return PawnLogRow(
        title: AppStrings.quests,
        detail: active.first.title,
        onTap: () => context.go('/quests/${active.first.id.value}'),
      );
    }

    return const PawnMutedText(AppStrings.pawnNextEmpty);
  }
}
