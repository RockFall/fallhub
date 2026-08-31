import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/navigation/colony_more_menu.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/command_palette.dart';
import '../../../flashcards/application/flashcard_providers.dart';
import '../../../integrations/application/integrations_controllers.dart';
import '../../../pawn/application/pawn_providers.dart';
import '../../../pawn/presentation/widgets/check_in_sheet.dart';
import '../../../plan_day/application/plan_day_providers.dart';
import '../../../work/application/work_providers.dart';
import '../../application/colony_agenda_style.dart';

class ColonyTerminalHome extends ConsumerWidget {
  const ColonyTerminalHome({super.key, required this.profile});

  final ColonyProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)().toLocal();
    final checkIn = ref.watch(latestCheckInProvider).asData?.value;
    final inbox = ref.watch(inboxTasksProvider).asData?.value ?? const [];
    final todayLists = ref.watch(todayPlanTasksProvider);
    final day = DateTime(now.year, now.month, now.day);
    final timeline = ref.watch(scheduleTimelineItemsProvider(day));
    final conflicts = ref.watch(scheduleConflictsProvider(day));
    final digest = ref.watch(flashcardTodayDigestProvider);
    ref.watch(calendarIcsAutoRefreshProvider);

    final rest = ColonyPipMeter.countFor(checkIn?.energy);
    final mood = ColonyPipMeter.countFor(checkIn?.mood);

    final conflictIds = {
      for (final c
          in conflicts.asData?.value ?? const <ScheduleConflict>[]) ...[
        c.itemA.id,
        c.itemB.id,
      ],
    };
    final agendaBlocks = timeline.maybeWhen(
      data: (items) => buildColonyAgendaBlocks(
        day: day,
        items: items,
        conflictIds: conflictIds,
        onOpenSchedule: () => context.go('/work/schedule'),
      ),
      orElse: () => const <ColonyAgendaBlock>[],
    );

    final workRows = _workRows(
      context: context,
      checkIn: checkIn,
      now: now,
      inbox: inbox,
      openTasks: todayLists.asData?.value.open ?? const [],
      flashcardsDue: digest.cappedForSession,
    );

    return Semantics(
      container: true,
      identifier: 'colony.home.terminal',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final media = MediaQuery.of(context);
          final scaled = media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.15,
            ),
          );
          final agendaMax = (media.size.height - 500).clamp(220.0, 340.0);
          return MediaQuery(
            data: scaled,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                ColonySpacing.page,
                ColonySpacing.sm,
                ColonySpacing.page,
                ColonySpacing.lg,
              ),
              children: [
                ColonyDateHeader(
                  label: AppStrings.homeWeekdayDate(now),
                  menuSemanticLabel: AppStrings.homeMenu,
                  leadingSemanticLabel: AppStrings.commandPalette,
                  onLeading: () => CommandPalette.show(context),
                  onMenu: () => showColonyMoreMenu(context),
                ),
                const SizedBox(height: ColonySpacing.section),
                ColonyPawnBanner(
                  name: profile.displayName,
                  restPips: rest,
                  moodPips: mood,
                  restLabel: AppStrings.homeRest,
                  moodLabel: AppStrings.homeMood,
                  onTap: () => context.go('/pawn'),
                ),
                const SizedBox(height: ColonySpacing.section),
                Semantics(
                  container: true,
                  identifier: 'colony.home.agenda',
                  child: ColonyAgendaRail(
                    title: AppStrings.homeAgendaTitle,
                    emptyLabel: AppStrings.homeAgendaEmpty,
                    emptyHint: AppStrings.homeAgendaEmptyHint,
                    emptyActionLabel: AppStrings.homeLinkGoogleCalendar,
                    onEmptyAction: () =>
                        context.go('/settings/integrations?focus=calendar'),
                    nowLabel: AppStrings.homeNow,
                    day: day,
                    now: now,
                    blocks: agendaBlocks,
                    maxHeight: agendaMax,
                    onHeaderTap: () => context.go('/work/schedule'),
                    onAction: () =>
                        context.go('/settings/integrations?focus=calendar'),
                    actionSemanticLabel: AppStrings.homeLinkGoogleCalendar,
                  ),
                ),
                const SizedBox(height: ColonySpacing.section),
                Semantics(
                  container: true,
                  identifier: 'colony.home.work',
                  child: ColonyFrame(
                    variant: ColonyFrameVariant.panel,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppStrings.homeTodayWorkTitle.toUpperCase(),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: ColonyColors.textGold,
                                      letterSpacing: 1.1,
                                    ),
                              ),
                            ),
                            InkWell(
                              onTap: () => context.go('/today'),
                              child: const ColonyPixelIcon(
                                'grid',
                                size: 16,
                                mono: true,
                                color: ColonyColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (workRows.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              AppStrings.homeWorkEmpty,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: ColonyColors.textMuted),
                            ),
                          )
                        else
                          for (var i = 0; i < workRows.length; i++)
                            workRows[i].build(
                              showDivider: i != workRows.length - 1,
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: ColonySpacing.section),
                Semantics(
                  container: true,
                  identifier: 'colony.home.nav',
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: ColonySpacing.sm,
                    crossAxisSpacing: ColonySpacing.sm,
                    childAspectRatio: 1.18,
                    children: [
                      ColonyNavTile(
                        label: AppStrings.pawn,
                        iconName: 'person',
                        onPressed: () => context.go('/pawn'),
                      ),
                      ColonyNavTile(
                        label: AppStrings.quests,
                        iconName: 'flag',
                        onPressed: () => context.go('/quests'),
                      ),
                      ColonyNavTile(
                        label: AppStrings.healthTitle,
                        iconName: 'heart',
                        onPressed: () => context.go('/resources/health'),
                      ),
                      ColonyNavTile(
                        label: AppStrings.financeLedgerTitle,
                        iconName: 'coin',
                        onPressed: () => context.go('/resources/finance'),
                      ),
                      ColonyNavTile(
                        label: AppStrings.habitatTitle,
                        iconName: 'house',
                        onPressed: () => context.go('/colony/habitat'),
                      ),
                      ColonyNavTile(
                        label: AppStrings.chronicle,
                        iconName: 'book',
                        onPressed: () => context.go('/chronicle'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WorkSpec {
  const _WorkSpec({
    required this.title,
    required this.action,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String action;
  final String icon;
  final VoidCallback onPressed;

  Widget build({required bool showDivider}) {
    return ColonyWorkRow(
      title: title,
      actionLabel: action,
      iconName: icon,
      onPressed: onPressed,
      showDivider: showDivider,
    );
  }
}

List<_WorkSpec> _workRows({
  required BuildContext context,
  required CheckIn? checkIn,
  required DateTime now,
  required List<ColonyTask> inbox,
  required List<ColonyTask> openTasks,
  required int flashcardsDue,
}) {
  final rows = <_WorkSpec>[];

  if (openTasks.isNotEmpty) {
    final task = openTasks.first;
    rows.add(
      _WorkSpec(
        title: task.title,
        action: AppStrings.homeActionOpen,
        icon: 'scroll',
        onPressed: () => context.go('/tasks/${task.id.value}'),
      ),
    );
  }

  final checkedToday =
      checkIn != null &&
      checkIn.observedAt.toLocal().year == now.year &&
      checkIn.observedAt.toLocal().month == now.month &&
      checkIn.observedAt.toLocal().day == now.day;
  if (!checkedToday) {
    rows.add(
      _WorkSpec(
        title: AppStrings.homeSleepCheckIn,
        action: AppStrings.homeActionRegister,
        icon: 'moon_sleep',
        onPressed: () => CheckInSheet.show(context),
      ),
    );
  }

  if (inbox.isNotEmpty) {
    rows.add(
      _WorkSpec(
        title: AppStrings.homeInboxCount(inbox.length),
        action: AppStrings.homeActionReply,
        icon: 'envelope',
        onPressed: () => context.go('/inbox'),
      ),
    );
  }

  if (rows.length < 3 && flashcardsDue > 0) {
    rows.add(
      _WorkSpec(
        title: AppStrings.flashcardsTitle,
        action: AppStrings.homeQuickStudy,
        icon: 'cards',
        onPressed: () => context.go('/flashcards/study'),
      ),
    );
  }

  return rows.take(3).toList();
}
