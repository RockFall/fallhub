import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/timeline_providers.dart';
import 'widgets/import_timeline_sheet.dart';
import 'widgets/timeline_hub_tabs.dart';

class TravelScreen extends ConsumerWidget {
  const TravelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final import = ref.watch(googleTimelineImportProvider).asData?.value;

    return DefaultTabController(
      length: 8,
      initialIndex: import == null ? 1 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ColonySpacing.lg,
              ColonySpacing.lg,
              ColonySpacing.lg,
              ColonySpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.timelineHubTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: import == null
                          ? AppStrings.timelineImport
                          : AppStrings.timelineReimport,
                      onPressed: () => ImportTimelineSheet.show(context),
                      icon: const Icon(Icons.upload_file),
                    ),
                  ],
                ),
                const SizedBox(height: ColonySpacing.xs),
                Text(
                  AppStrings.travelDisclaimer,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (import != null) ...[
                  const SizedBox(height: ColonySpacing.sm),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: DataProvenanceBadge(kind: ProvenanceDisplay.imported),
                  ),
                ],
              ],
            ),
          ),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: AppStrings.timelineTabDay),
              Tab(text: AppStrings.timelineTabTrips),
              Tab(text: AppStrings.timelineTabStats),
              Tab(text: AppStrings.timelineTabPlaces),
              Tab(text: AppStrings.timelineTabCities),
              Tab(text: AppStrings.timelineTabWorld),
              Tab(text: AppStrings.timelineTabRhythm),
              Tab(text: AppStrings.timelineTabSignals),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                TimelineDayTab(),
                TimelineTripsTab(),
                TimelineStatsTab(),
                TimelinePlacesTab(),
                TimelineCitiesTab(),
                TimelineWorldTab(),
                TimelineRhythmTab(),
                TimelineSignalsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
