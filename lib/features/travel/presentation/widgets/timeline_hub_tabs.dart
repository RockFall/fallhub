import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/timeline_controllers.dart';
import '../../application/timeline_providers.dart';
import '../../application/travel_controllers.dart';
import '../../application/travel_providers.dart';
import 'create_trip_sheet.dart';
import 'edit_trip_sheet.dart';
import 'import_timeline_sheet.dart';
import 'timeline_visuals.dart';

class TimelineEmptyImport extends StatelessWidget {
  const TimelineEmptyImport({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        Icon(
          Icons.map_outlined,
          size: 56,
          color: ColonyColors.accentCyan.withValues(alpha: 0.8),
        ),
        const SizedBox(height: ColonySpacing.md),
        Text(
          AppStrings.timelineEmptyHub,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: ColonySpacing.sm),
        Text(
          AppStrings.timelineEmptyHint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColonyColors.textMuted,
              ),
        ),
        const SizedBox(height: ColonySpacing.lg),
        FilledButton.icon(
          onPressed: () => ImportTimelineSheet.show(context),
          icon: const Icon(Icons.upload_file),
          label: const Text(AppStrings.timelineImport),
        ),
      ],
    );
  }
}

class TimelineDayTab extends ConsumerWidget {
  const TimelineDayTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(timelineInsightsProvider);
    if (insights == null) return const TimelineEmptyImport();
    final days = GoogleTimelineAnalytics.daysWithData(insights.document);
    final selected = ref.watch(timelineSelectedDayProvider) ??
        (days.isEmpty ? DateTime.now().toUtc() : days.last);
    final items = GoogleTimelineAnalytics.dayItems(
      insights.document,
      selected,
      labels: insights.labels,
    );

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: ColonySpacing.md),
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: ColonySpacing.sm),
            itemBuilder: (context, index) {
              final day = days[days.length - 1 - index];
              final isSelected = DateTime.utc(day.year, day.month, day.day) ==
                  DateTime.utc(selected.year, selected.month, selected.day);
              return ChoiceChip(
                label: Text(TimelineVisuals.dayLabel(day)),
                selected: isSelected,
                onSelected: (_) => ref
                    .read(timelineSelectedDayProvider.notifier)
                    .select(day),
              );
            },
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text(AppStrings.timelineNoDayData))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    ColonySpacing.lg,
                    ColonySpacing.sm,
                    ColonySpacing.lg,
                    ColonySpacing.xl,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final color = item.category != null
                        ? TimelineVisuals.categoryColor(item.category!)
                        : TimelineVisuals.modeColor(item.mode ?? 'other');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
                      child: ColonySurface(
                        kind: ColonySurfaceKind.panel,
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(width: 4, color: color),
                              Expanded(
                                child: ListTile(
                                  title: Text(item.title),
                                  subtitle: Text(
                                    [
                                      TimelineVisuals.clockRange(
                                        item.startAt,
                                        item.endAt,
                                      ),
                                      if (item.subtitle != null) item.subtitle!,
                                      if (item.kind == 'visit')
                                        AppStrings.timelineDurationHours(
                                          item.endAt.difference(item.startAt),
                                        ),
                                      if (item.hierarchyLevel > 0)
                                        AppStrings.timelineHierarchyNested,
                                    ].join(' · '),
                                  ),
                                  trailing: item.probability == null
                                      ? null
                                      : ConfidenceChip(
                                          level: TimelineVisuals.confidenceOf(
                                            item.probability,
                                          ),
                                        ),
                                  onTap: item.placeId == null
                        ? null
                        : () => LabelPlaceSheet.show(
                              context,
                              placeId: item.placeId!,
                              current: insights.labels[item.placeId!],
                            ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class TimelineTripsTab extends ConsumerWidget {
  const TimelineTripsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(timelineInsightsProvider);
    final tripsAsync = ref.watch(tripsProvider);
    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        if (insights != null) ...[
          Text(
            AppStrings.timelineMemoryTrips,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          if (insights.document.trips.isEmpty)
            Text(
              AppStrings.timelineNoMemoryTrips,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColonyColors.textMuted,
                  ),
            )
          else
            for (final trip in insights.document.trips)
              Padding(
                padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
                child: ColonySurface(
                  kind: ColonySurfaceKind.panel,
                  child: Padding(
                    padding: const EdgeInsets.all(ColonySpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.public,
                              color: ColonyColors.accentCyan,
                            ),
                            const SizedBox(width: ColonySpacing.sm),
                            Expanded(
                              child: Text(
                                [
                                  TimelineVisuals.dayLabel(trip.startAt),
                                  '→',
                                  TimelineVisuals.dayLabel(trip.endAt),
                                ].join(' '),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (trip.distanceFromOriginKms != null)
                              Text(
                                '${trip.distanceFromOriginKms} ${AppStrings.timelineKmShort}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: ColonyColors.accentCyan),
                              ),
                          ],
                        ),
                        const SizedBox(height: ColonySpacing.xs),
                        Text(
                          '${trip.destinationPlaceIds.length} ${AppStrings.timelineDestinations} · ${AppStrings.timelineDurationHours(trip.duration)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ColonyColors.textMuted,
                              ),
                        ),
                        if (trip.destinationPlaceIds.isNotEmpty) ...[
                          const SizedBox(height: ColonySpacing.sm),
                          Wrap(
                            spacing: ColonySpacing.sm,
                            runSpacing: ColonySpacing.xs,
                            children: [
                              for (final id in trip.destinationPlaceIds)
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(
                                    insights.labels[id]?.customName ??
                                        insights.places
                                            .where((p) => p.placeId == id)
                                            .firstOrNull
                                            ?.city
                                            ?.name ??
                                        id,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: ColonySpacing.lg),
        ],
        Text(
          AppStrings.timelineManualTrips,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: ColonySpacing.sm),
        tripsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text(AppStrings.errorGeneric),
          data: (trips) {
            final visible =
                trips.where((t) => !t.status.isHiddenFromActiveList).toList();
            if (visible.isEmpty) {
              return Column(
                children: [
                  const Text(AppStrings.travelEmpty),
                  const SizedBox(height: ColonySpacing.sm),
                  Text(
                    AppStrings.travelEmptyHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              );
            }
            return Column(
              children: [
                for (final trip in visible)
                  Card(
                    margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
                    child: ListTile(
                      title: Text(trip.title),
                      subtitle: Text(
                        [
                          AppStrings.tripStatusLabel(trip.status),
                          if (trip.destinations.isNotEmpty)
                            trip.destinations.join(', '),
                          if (trip.purpose != null) trip.purpose!,
                        ].join(' · '),
                      ),
                      onTap: () => EditTripSheet.show(context, trip),
                      trailing: trip.status == TripStatus.completed
                          ? null
                          : IconButton(
                              tooltip: AppStrings.tripComplete,
                              icon: const Icon(Icons.check_circle_outline),
                              onPressed: () => ref
                                  .read(travelControllerProvider.notifier)
                                  .setStatus(trip, TripStatus.completed),
                            ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: ColonySpacing.md),
        FilledButton.icon(
          onPressed: () => CreateTripSheet.show(context),
          icon: const Icon(Icons.add),
          label: const Text(AppStrings.tripNew),
        ),
      ],
    );
  }
}

class TimelineStatsTab extends ConsumerWidget {
  const TimelineStatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(timelineInsightsProvider);
    if (insights == null) return const TimelineEmptyImport();
    List<double> sparkFor(String bucket) {
      final months = insights.transportByMonth;
      if (months.isEmpty) return const [];
      final slice =
          months.length <= 6 ? months : months.sublist(months.length - 6);
      return [
        for (final m in slice) m.buckets[bucket]?.km ?? 0,
      ];
    }

    final visitSpark = () {
      final months = insights.visitHoursByMonth;
      if (months.isEmpty) return const <double>[];
      final slice =
          months.length <= 6 ? months : months.sublist(months.length - 6);
      return [for (final m in slice) m.total.inMinutes / 60.0];
    }();

    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        Text(
          AppStrings.timelineTransportTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: ColonySpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: ColonySpacing.sm,
          crossAxisSpacing: ColonySpacing.sm,
          childAspectRatio: 1.15,
          children: [
            TimelineStatTile(
              label: AppStrings.timelineWalk,
              value: AppStrings.timelineKm(insights.walkKm),
              icon: Icons.directions_walk,
              color: TimelineVisuals.modeColor('walking'),
              spark: sparkFor('walking'),
            ),
            TimelineStatTile(
              label: AppStrings.timelineDrive,
              value: AppStrings.timelineKm(insights.driveKm),
              icon: Icons.directions_car_outlined,
              color: TimelineVisuals.modeColor('driving'),
              spark: sparkFor('driving'),
            ),
            TimelineStatTile(
              label: AppStrings.timelineTransit,
              value: AppStrings.timelineKm(insights.transitKm),
              icon: Icons.directions_bus_outlined,
              color: TimelineVisuals.modeColor('transit'),
              spark: sparkFor('transit'),
            ),
            TimelineStatTile(
              label: AppStrings.timelineFly,
              value: AppStrings.timelineKm(insights.flyKm),
              icon: Icons.flight_outlined,
              color: TimelineVisuals.modeColor('flying'),
              spark: sparkFor('flying'),
            ),
            TimelineStatTile(
              label: AppStrings.timelineCycling,
              value: AppStrings.timelineKm(insights.cyclingKm),
              icon: Icons.directions_bike_outlined,
              color: TimelineVisuals.modeColor('cycling'),
              spark: sparkFor('cycling'),
            ),
            TimelineStatTile(
              label: AppStrings.timelineVisitHoursTitle,
              value: AppStrings.timelineDurationHours(
                insights.categoryHours.values.fold(
                  Duration.zero,
                  (a, b) => a + b,
                ),
              ),
              icon: Icons.schedule,
              color: ColonyColors.accentSand,
              spark: visitSpark,
            ),
          ],
        ),
        const SizedBox(height: ColonySpacing.lg),
        Text(
          AppStrings.timelineHomeWorkTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: ColonySpacing.sm),
        TimelineStatTile(
          label: AppStrings.timelineCategoryLabel(TimelinePlaceCategory.home),
          value: AppStrings.timelineDurationHours(insights.homeHours),
          icon: Icons.home_outlined,
          color: TimelineVisuals.categoryColor(TimelinePlaceCategory.home),
        ),
        const SizedBox(height: ColonySpacing.sm),
        TimelineStatTile(
          label: AppStrings.timelineCategoryLabel(TimelinePlaceCategory.work),
          value: AppStrings.timelineDurationHours(insights.workHours),
          icon: Icons.work_outline,
          color: TimelineVisuals.categoryColor(TimelinePlaceCategory.work),
        ),
        const SizedBox(height: ColonySpacing.lg),
        Wrap(
          spacing: ColonySpacing.sm,
          runSpacing: ColonySpacing.sm,
          children: [
            _chip(context, AppStrings.timelineNightsAway, '${insights.nightsAway}'),
            _chip(
              context,
              AppStrings.timelineRadius,
              AppStrings.timelineKm(insights.radiusKm),
            ),
            _chip(
              context,
              AppStrings.timelineCommuteDays,
              '${insights.commuteDays}',
            ),
            _chip(context, AppStrings.timelineGaps, '${insights.gaps}'),
            _chip(
              context,
              AppStrings.timelineImplausible,
              '${insights.implausibleLegs}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, String value) {
    return ColonySurface(
      kind: ColonySurfaceKind.panel,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ColonySpacing.md,
          vertical: ColonySpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ColonyColors.textMuted,
                  ),
            ),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class TimelinePlacesTab extends ConsumerStatefulWidget {
  const TimelinePlacesTab({super.key});

  @override
  ConsumerState<TimelinePlacesTab> createState() => _TimelinePlacesTabState();
}

class _TimelinePlacesTabState extends ConsumerState<TimelinePlacesTab> {
  TimelinePlaceCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final insights = ref.watch(timelineInsightsProvider);
    if (insights == null) return const TimelineEmptyImport();
    final counts = <TimelinePlaceCategory, int>{};
    for (final p in insights.places) {
      counts[p.category] = (counts[p.category] ?? 0) + 1;
    }
    final filtered = insights.places
        .where((p) => _filter == null || p.category == _filter)
        .toList();
    final cats = TimelinePlaceCategory.values
        .where((c) => (counts[c] ?? 0) > 0)
        .toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            ColonySpacing.lg,
            ColonySpacing.lg,
            ColonySpacing.lg,
            ColonySpacing.md,
          ),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: ColonySpacing.sm,
            crossAxisSpacing: ColonySpacing.sm,
            childAspectRatio: 1.05,
            children: [
              for (final cat in cats)
                TimelineCategoryCard(
                  category: cat,
                  count: counts[cat] ?? 0,
                  hours: insights.categoryHours[cat] ?? Duration.zero,
                  onTap: () => setState(() {
                    _filter = _filter == cat ? null : cat;
                  }),
                ),
            ],
          ),
        ),
        if (filtered.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: ColonySpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Text(AppStrings.timelineNoPlaces),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              ColonySpacing.lg,
              0,
              ColonySpacing.lg,
              ColonySpacing.xl,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final place = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
                    child: ColonySurface(
                      kind: ColonySurfaceKind.panel,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              TimelineVisuals.categoryColor(place.category)
                                  .withValues(alpha: 0.2),
                          child: Icon(
                            TimelineVisuals.categoryIcon(place.category),
                            color: TimelineVisuals.categoryColor(place.category),
                          ),
                        ),
                        title: Text(
                          place.customName ??
                              place.city?.name ??
                              place.semanticType ??
                              AppStrings.timelineUnknownPlace,
                        ),
                        subtitle: Text(
                          [
                            AppStrings.timelineCategoryLabel(place.category),
                            '${place.visitCount} ${AppStrings.timelineVisits}',
                            AppStrings.timelineDurationHours(place.total),
                            if (place.customName == null)
                              AppStrings.timelineInferred,
                          ].join(' · '),
                        ),
                        onTap: place.placeId == null
                            ? null
                            : () => LabelPlaceSheet.show(
                                  context,
                                  placeId: place.placeId!,
                                  current: insights.labels[place.placeId!],
                                ),
                      ),
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }
}

class TimelineCitiesTab extends ConsumerWidget {
  const TimelineCitiesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(timelineInsightsProvider);
    if (insights == null) return const TimelineEmptyImport();
    if (insights.cities.isEmpty) {
      return const Center(child: Text(AppStrings.timelineNoCities));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      itemCount: insights.cities.length,
      itemBuilder: (context, index) {
        final city = insights.cities[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
          child: ColonySurface(
            kind: ColonySurfaceKind.panel,
            child: Padding(
              padding: const EdgeInsets.all(ColonySpacing.md),
              child: Row(
                children: [
                  Text(
                    TimelineVisuals.flagEmoji(city.city.countryCode),
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: ColonySpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          city.city.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          CityGazetteer.countryName(city.city.countryCode),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ColonyColors.textMuted,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${city.placeCount}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '${city.visitCount} ${AppStrings.timelineVisits}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColonyColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class TimelineWorldTab extends ConsumerWidget {
  const TimelineWorldTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(timelineInsightsProvider);
    if (insights == null) return const TimelineEmptyImport();
    if (insights.countries.isEmpty) {
      return const Center(child: Text(AppStrings.timelineNoCountries));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: ColonySpacing.sm,
        crossAxisSpacing: ColonySpacing.sm,
        childAspectRatio: 1.15,
      ),
      itemCount: insights.countries.length,
      itemBuilder: (context, index) {
        final country = insights.countries[index];
        return ColonySurface(
          kind: ColonySurfaceKind.panel,
          child: Padding(
            padding: const EdgeInsets.all(ColonySpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TimelineVisuals.flagEmoji(country.countryCode),
                  style: const TextStyle(fontSize: 32),
                ),
                const Spacer(),
                Text(
                  CityGazetteer.countryName(country.countryCode),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${country.cityCount} cidades · ${country.placeCount} ${AppStrings.timelinePlacesInCategory}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColonyColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TimelineRhythmTab extends ConsumerWidget {
  const TimelineRhythmTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(timelineInsightsProvider);
    if (insights == null) return const TimelineEmptyImport();
    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        Text(
          AppStrings.timelineHeatmapHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColonyColors.textMuted,
              ),
        ),
        const SizedBox(height: ColonySpacing.md),
        ColonySurface(
          kind: ColonySurfaceKind.panel,
          child: Padding(
            padding: const EdgeInsets.all(ColonySpacing.md),
            child: TimelineHeatmap(minutes: insights.hourHeatmapMinutes),
          ),
        ),
      ],
    );
  }
}

class TimelineSignalsTab extends ConsumerWidget {
  const TimelineSignalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(timelineInsightsProvider);
    final import = ref.watch(googleTimelineImportProvider).asData?.value;
    if (insights == null || import == null) return const TimelineEmptyImport();
    final doc = insights.document;

    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        const DataProvenanceBadge(kind: ProvenanceDisplay.imported),
        const SizedBox(height: ColonySpacing.sm),
        Text(
          AppStrings.timelineProvenanceHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColonyColors.textMuted,
              ),
        ),
        const SizedBox(height: ColonySpacing.md),
        ColonyPanel(
          title: AppStrings.timelineFileMeta,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(import.fileName),
              Text(
                AppStrings.timelineOverwriteSummary(
                  import.fileName,
                  import.importedAt,
                ),
              ),
              if (insights.firstAt != null && insights.lastAt != null)
                Text(
                  '${AppStrings.timelineRange}: ${TimelineVisuals.dayLabel(insights.firstAt!)} → ${TimelineVisuals.dayLabel(insights.lastAt!)}',
                ),
              Text(
                '${doc.positions.length} ${AppStrings.timelineRawPositions} · ${doc.sensorActivities.length} ${AppStrings.timelineSensorHits}',
              ),
              const SizedBox(height: ColonySpacing.sm),
              OutlinedButton.icon(
                onPressed: () => ImportTimelineSheet.show(context),
                icon: const Icon(Icons.swap_horiz),
                label: const Text(AppStrings.timelineReimport),
              ),
            ],
          ),
        ),
        const SizedBox(height: ColonySpacing.md),
        ColonyPanel(
          title: AppStrings.timelinePersonaTitle,
          child: Column(
            children: [
              for (final a in doc.affinities)
                Padding(
                  padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 88,
                        child: Text(AppStrings.timelineModeLabel(
                          GoogleTimelineAnalytics.transportBucket(a.mode),
                        )),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: a.affinity.clamp(0, 1),
                          color: TimelineVisuals.modeColor(
                            GoogleTimelineAnalytics.transportBucket(a.mode),
                          ),
                          backgroundColor: ColonyColors.optionUnselected,
                        ),
                      ),
                      const SizedBox(width: ColonySpacing.sm),
                      Text(
                        '${(insights.actualModeShare[GoogleTimelineAnalytics.transportBucket(a.mode)] ?? 0) * 100 ~/ 1}%',
                      ),
                    ],
                  ),
                ),
              if (doc.affinities.isEmpty)
                Text(
                  '${AppStrings.timelineAffinityActual}: '
                  '${AppStrings.timelineKm(insights.totalKm)}',
                ),
            ],
          ),
        ),
        const SizedBox(height: ColonySpacing.md),
        ColonyPanel(
          title: AppStrings.timelineParkingTitle,
          child: insights.parking.isEmpty
              ? const Text(AppStrings.timelineNoParking)
              : Column(
                  children: [
                    for (final p in insights.parking.take(40))
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.local_parking),
                        title: Text(
                          '${p.location.latitude.toStringAsFixed(5)}, ${p.location.longitude.toStringAsFixed(5)}',
                        ),
                        subtitle: Text(
                          TimelineVisuals.clockRange(p.startAt, p.startAt),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: ColonySpacing.md),
        ColonyPanel(
          title: AppStrings.timelineNotesTitle,
          child: doc.notes.isEmpty
              ? const Text(AppStrings.timelineNoNotes)
              : Column(
                  children: [
                    for (final n in doc.notes)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.sticky_note_2_outlined),
                        title: Text(n.text),
                        subtitle: Text(TimelineVisuals.dayLabel(n.startAt)),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: ColonySpacing.md),
        ColonyPanel(
          title: AppStrings.timelineFrequentTitle,
          child: Column(
            children: [
              for (final p in doc.frequentPlaces)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.star_outline),
                  title: Text(p.label ?? p.placeId ?? AppStrings.timelineUnknownPlace),
                  subtitle: p.location == null
                      ? null
                      : Text(
                          '${p.location!.latitude.toStringAsFixed(4)}, ${p.location!.longitude.toStringAsFixed(4)}',
                        ),
                ),
            ],
          ),
        ),
        const SizedBox(height: ColonySpacing.md),
        ColonyPanel(
          title: AppStrings.timelineQualityTitle,
          child: Text(
            '${AppStrings.timelineGaps}: ${insights.gaps}\n'
            '${AppStrings.timelineImplausible}: ${insights.implausibleLegs}',
          ),
        ),
      ],
    );
  }
}

class LabelPlaceSheet extends ConsumerStatefulWidget {
  const LabelPlaceSheet({
    super.key,
    required this.placeId,
    this.current,
  });

  final String placeId;
  final TimelinePlaceLabel? current;

  static Future<void> show(
    BuildContext context, {
    required String placeId,
    TimelinePlaceLabel? current,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LabelPlaceSheet(placeId: placeId, current: current),
    );
  }

  @override
  ConsumerState<LabelPlaceSheet> createState() => _LabelPlaceSheetState();
}

class _LabelPlaceSheetState extends ConsumerState<LabelPlaceSheet> {
  late final TextEditingController _name;
  late TimelinePlaceCategory _category;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.current?.customName ?? '');
    _category = widget.current?.category ?? TimelinePlaceCategory.other;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.md,
        ColonySpacing.lg,
        ColonySpacing.lg + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.timelineLabelPlace,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            widget.placeId,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColonyColors.textMuted,
                ),
          ),
          const SizedBox(height: ColonySpacing.md),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: AppStrings.timelineCustomName,
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          DropdownButtonFormField<TimelinePlaceCategory>(
            value: _category,
            decoration: const InputDecoration(
              labelText: AppStrings.timelineCategory,
            ),
            items: [
              for (final c in TimelinePlaceCategory.values)
                DropdownMenuItem(
                  value: c,
                  child: Text(AppStrings.timelineCategoryLabel(c)),
                ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: ColonySpacing.lg),
          FilledButton(
            onPressed: () async {
              await ref.read(timelineControllerProvider.notifier).saveLabel(
                    TimelinePlaceLabel(
                      placeId: widget.placeId,
                      category: _category,
                      customName: _name.text.trim().isEmpty
                          ? null
                          : _name.text.trim(),
                    ),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(AppStrings.timelineSaveLabel),
          ),
        ],
      ),
    );
  }
}
