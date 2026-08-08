import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../application/pawn_controllers.dart';
import '../application/pawn_providers.dart';
import 'widgets/check_in_sheet.dart';
import 'widgets/need_reading_sheet.dart';

class PawnScreen extends ConsumerStatefulWidget {
  const PawnScreen({super.key});

  @override
  ConsumerState<PawnScreen> createState() => _PawnScreenState();
}

class _PawnScreenState extends ConsumerState<PawnScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pawnBootstrapProvider.notifier).ensureSeeded();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final checkIn = ref.watch(latestCheckInProvider);

    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
      data: (p) {
        if (p == null) return const SizedBox.shrink();
        return Column(
          children: [
            checkIn.when(
              data: (c) => _PawnHeader(
                profile: p,
                checkIn: c,
                onCheckIn: () => CheckInSheet.show(context),
                onDailyReview: () => context.go('/pawn/review'),
                onWeeklyReview: () => context.go('/pawn/review/weekly'),
              ),
              loading: () => _PawnHeader(
                profile: p,
                checkIn: null,
                onCheckIn: () => CheckInSheet.show(context),
                onDailyReview: () => context.go('/pawn/review'),
                onWeeklyReview: () => context.go('/pawn/review/weekly'),
              ),
              error: (_, __) => _PawnHeader(
                profile: p,
                checkIn: null,
                onCheckIn: () => CheckInSheet.show(context),
                onDailyReview: () => context.go('/pawn/review'),
                onWeeklyReview: () => context.go('/pawn/review/weekly'),
              ),
            ),
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: AppStrings.pawnTabSummary),
                Tab(text: AppStrings.pawnTabNeeds),
                Tab(text: AppStrings.pawnTabMind),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _SummaryTab(profile: p, checkIn: checkIn),
                  _NeedsTab(onRecord: (snapshot) {
                    NeedReadingSheet.show(context, snapshot: snapshot);
                  }),
                  _MindTab(checkIn: checkIn),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PawnHeader extends StatelessWidget {
  const _PawnHeader({
    required this.profile,
    required this.checkIn,
    required this.onCheckIn,
    required this.onDailyReview,
    required this.onWeeklyReview,
  });

  final ColonyProfile profile;
  final CheckIn? checkIn;
  final VoidCallback onCheckIn;
  final VoidCallback onDailyReview;
  final VoidCallback onWeeklyReview;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Container(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      decoration: const BoxDecoration(
        color: ColonyColors.raised,
        border: Border(bottom: BorderSide(color: ColonyColors.borderSubtle)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _profileRow(context),
                const SizedBox(height: ColonySpacing.sm),
                Wrap(
                  spacing: ColonySpacing.sm,
                  runSpacing: ColonySpacing.sm,
                  children: [
                    OutlinedButton(
                      onPressed: onWeeklyReview,
                      child: const Text(AppStrings.weeklyReview),
                    ),
                    OutlinedButton(
                      onPressed: onDailyReview,
                      child: const Text(AppStrings.dailyReview),
                    ),
                    FilledButton(
                      onPressed: onCheckIn,
                      child: const Text(AppStrings.checkIn),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: _profileRow(context)),
                OutlinedButton(
                  onPressed: () => context.go('/colony/pawn-create'),
                  child: const Text(AppStrings.habitatEditPawn),
                ),
                const SizedBox(width: ColonySpacing.sm),
                OutlinedButton(
                  onPressed: onWeeklyReview,
                  child: const Text(AppStrings.weeklyReview),
                ),
                const SizedBox(width: ColonySpacing.sm),
                OutlinedButton(
                  onPressed: onDailyReview,
                  child: const Text(AppStrings.dailyReview),
                ),
                const SizedBox(width: ColonySpacing.sm),
                FilledButton(
                  onPressed: onCheckIn,
                  child: const Text(AppStrings.checkIn),
                ),
              ],
            ),
    );
  }

  Widget _profileRow(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: ColonyColors.panel,
          child: Text(
            profile.displayName.isNotEmpty
                ? profile.displayName[0].toUpperCase()
                : '?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(width: ColonySpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.displayName,
                  style: Theme.of(context).textTheme.titleLarge),
              Text(
                checkIn == null
                    ? AppStrings.noCheckInYet
                    : '${AppStrings.mood}: ${checkIn!.moodLabel} · ${AppStrings.energy}: ${checkIn!.energyLabel}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab({required this.profile, required this.checkIn});

  final ColonyProfile profile;
  final AsyncValue<CheckIn?> checkIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needs = ref.watch(needSnapshotsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.pawnSummaryIntro,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: ColonySpacing.lg),
          needs.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text(AppStrings.errorGeneric),
            data: (snapshots) {
              final relevant = snapshots
                  .where(
                    (s) =>
                        s.freshness == DataFreshness.stale ||
                        s.freshness == DataFreshness.unknown ||
                        (s.normalizedValue != null &&
                            s.normalizedValue! < s.definition.preferredMin),
                  )
                  .take(4)
                  .toList();
              if (relevant.isEmpty && snapshots.isNotEmpty) {
                return ColonyPanel(
                  title: AppStrings.pawnTabNeeds,
                  child: Text(AppStrings.needsStable),
                );
              }
              return ColonyPanel(
                title: AppStrings.needsAttention,
                child: Column(
                  children: relevant
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: ColonySpacing.md),
                          child: NeedBar(
                            data: NeedBarData(
                              label: s.definition.name,
                              normalizedValue: s.normalizedValue,
                              targetMin: s.definition.preferredMin,
                              targetMax: s.definition.preferredMax,
                              statusText: s.statusText,
                              sourceSummary: s.sourceSummary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
          const SizedBox(height: ColonySpacing.lg),
          checkIn.when(
            data: (c) => ColonyPanel(
              title: AppStrings.lastCheckIn,
              child: c == null
                  ? Text(AppStrings.noCheckInYet)
                  : Text(
                      '${AppStrings.mood}: ${c.moodLabel}\n'
                      '${AppStrings.energy}: ${c.energyLabel}\n'
                      '${AppStrings.focus}: ${c.focus >= 0.65 ? 'Bom' : 'Baixo'}',
                    ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _NeedsTab extends ConsumerWidget {
  const _NeedsTab({required this.onRecord});

  final void Function(NeedSnapshot snapshot) onRecord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needs = ref.watch(needSnapshotsProvider);

    return needs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
      data: (snapshots) => ListView.separated(
        padding: const EdgeInsets.all(ColonySpacing.lg),
        itemCount: snapshots.length,
        separatorBuilder: (_, __) => const SizedBox(height: ColonySpacing.md),
        itemBuilder: (context, index) {
          final s = snapshots[index];
          return ColonyPanel(
            title: s.definition.name,
            actions: [
              IconButton(
                tooltip: AppStrings.recordNeed,
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => onRecord(s),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NeedBar(
                  data: NeedBarData(
                    label: s.definition.name,
                    normalizedValue: s.normalizedValue,
                    targetMin: s.definition.preferredMin,
                    targetMax: s.definition.preferredMax,
                    warningThreshold: s.definition.preferredMin,
                    statusText: s.statusText,
                    sourceSummary: '${s.sourceSummary} · ${s.freshness.name}',
                  ),
                ),
                const SizedBox(height: ColonySpacing.sm),
                Row(
                  children: [
                    DataProvenanceBadge(
                      kind: ProvenanceDisplay.manual,
                      compact: false,
                    ),
                    const SizedBox(width: ColonySpacing.sm),
                    ConfidenceChip(
                      level: switch (s.confidence) {
                        ConfidenceLevel.high => ConfidenceDisplay.high,
                        ConfidenceLevel.medium => ConfidenceDisplay.medium,
                        ConfidenceLevel.low => ConfidenceDisplay.low,
                        ConfidenceLevel.insufficient =>
                          ConfidenceDisplay.insufficient,
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MindTab extends ConsumerStatefulWidget {
  const _MindTab({required this.checkIn});

  final AsyncValue<CheckIn?> checkIn;

  @override
  ConsumerState<_MindTab> createState() => _MindTabState();
}

class _MindTabState extends ConsumerState<_MindTab> {
  List<MoodFactor> _factors = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFactors();
  }

  @override
  void didUpdateWidget(covariant _MindTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.checkIn.asData?.value?.id;
    final newId = widget.checkIn.asData?.value?.id;
    if (oldId != newId) {
      _loadFactors();
    }
  }

  Future<void> _loadFactors() async {
    final checkIn = widget.checkIn.asData?.value;
    if (checkIn == null) {
      setState(() {
        _factors = [];
        _loading = false;
      });
      return;
    }
    final factors =
        await ref.read(repositoriesProvider).checkIns.getFactors(checkIn.id);
    if (mounted) {
      setState(() {
        _factors = factors;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkIn = widget.checkIn.asData?.value;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (checkIn == null)
            Text(AppStrings.noCheckInYet)
          else ...[
            ColonyPanel(
              title: AppStrings.moodDeclared,
              child: Text(
                '${checkIn.moodLabel}\n'
                '${AppStrings.energy}: ${checkIn.energyLabel}',
              ),
            ),
            const SizedBox(height: ColonySpacing.lg),
            ColonyPanel(
              title: AppStrings.moodFactors,
              child: _factors.isEmpty
                  ? Text(AppStrings.noFactorsYet)
                  : ModifierList(
                      entries: _factors
                          .map(
                            (f) => ModifierEntry(
                              label: f.label,
                              impact: f.impact,
                              uncertain: f.uncertain,
                              note: f.kind == MoodFactorKind.userConfirmed
                                  ? 'confirmado'
                                  : null,
                            ),
                          )
                          .toList(),
                    ),
            ),
            if (checkIn.note != null && checkIn.note!.isNotEmpty) ...[
              const SizedBox(height: ColonySpacing.lg),
              ColonyPanel(
                title: AppStrings.note,
                child: Text(checkIn.note!),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
