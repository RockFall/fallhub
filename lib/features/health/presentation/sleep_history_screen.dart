import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/app_strings.dart';
import '../application/health_providers.dart';

/// Daily sleep totals and time ranges (ADR-035).
class SleepHistoryScreen extends ConsumerWidget {
  const SleepHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sleepSessionsProvider);
    final dayFmt = DateFormat('EEE, d MMM yyyy');
    final timeFmt = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.healthSleepHistoryTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/resources/health');
            }
          },
        ),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
        data: (sessions) {
          final days = groupSleepSessionsByWakeDay(sessions);
          if (days.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(ColonySpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.healthSleepHistoryEmpty,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: ColonySpacing.sm),
                  Text(
                    AppStrings.healthSleepHistoryEmptyHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(ColonySpacing.lg),
            itemCount: days.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: ColonySpacing.md),
                  child: Text(
                    AppStrings.healthSleepHistoryHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
              final day = days[index - 1];
              return Card(
                margin: const EdgeInsets.only(bottom: ColonySpacing.md),
                child: Padding(
                  padding: const EdgeInsets.all(ColonySpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dayFmt.format(day.day),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            AppStrings.healthSleepDuration(day.total),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: ColonySpacing.xs),
                      Text(
                        AppStrings.healthSleepHistorySessionCount(
                          day.sessionCount,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: ColonySpacing.sm),
                      for (final s in day.sessions) ...[
                        const Divider(height: ColonySpacing.md),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Icon(
                            s.isOpen
                                ? Icons.bedtime
                                : Icons.bedtime_off_outlined,
                            color: ColonyColors.textMuted,
                          ),
                          title: Text(
                            s.isOpen
                                ? AppStrings.healthSleepInProgress
                                : AppStrings.healthSleepDuration(
                                    s.duration ?? Duration.zero,
                                  ),
                          ),
                          subtitle: Text(
                            [
                              '${timeFmt.format(s.startedAt.toLocal())}'
                                  '${s.endedAt == null ? '' : ' → ${timeFmt.format(s.endedAt!.toLocal())}'}',
                              AppStrings.healthSleepSourceLabel(s.source),
                            ].join(' · '),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
