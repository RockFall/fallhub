import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_locale.dart';
import '../../../../app/localization/app_strings.dart';
import 'schedule_conflict_panel.dart';
import 'schedule_day_timeline.dart';

/// Three-day schedule layout: timeline + conflicts per day.
class ScheduleThreeDayView extends ConsumerWidget {
  const ScheduleThreeDayView({
    super.key,
    required this.anchorDay,
    required this.use24Hour,
    required this.locale,
  });

  final DateTime anchorDay;
  final bool use24Hour;
  final String locale;

  static const wideBreakpoint = 720.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = scheduleThreeDayRange(anchorDay);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > wideBreakpoint;

        if (wide) {
          return Padding(
            padding: const EdgeInsets.all(ColonySpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  if (i > 0) const SizedBox(width: ColonySpacing.md),
                  Expanded(
                    child: _ScheduleDayPanel(
                      day: days[i],
                      use24Hour: use24Hour,
                      locale: locale,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(ColonySpacing.lg),
          children: [
            for (var i = 0; i < days.length; i++) ...[
              if (i > 0) const SizedBox(height: ColonySpacing.lg),
              _ScheduleDayPanel(
                day: days[i],
                use24Hour: use24Hour,
                locale: locale,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ScheduleDayPanel extends StatelessWidget {
  const _ScheduleDayPanel({
    required this.day,
    required this.use24Hour,
    required this.locale,
  });

  final DateTime day;
  final bool use24Hour;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final dateLabel = AppLocale.date('EEE, d MMM', locale).format(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          dateLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: ColonySpacing.md),
        ColonyPanel(
          title: AppStrings.scheduleTimeline,
          icon: Icons.view_timeline_outlined,
          child: ScheduleDayTimeline(
            day: day,
            use24Hour: use24Hour,
            locale: locale,
            compact: true,
          ),
        ),
        const SizedBox(height: ColonySpacing.md),
        ScheduleConflictPanel(
          day: day,
          use24Hour: use24Hour,
          locale: locale,
        ),
      ],
    );
  }
}
