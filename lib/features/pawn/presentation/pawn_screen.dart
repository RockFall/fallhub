import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../activation/application/activation_providers.dart';
import '../../activation/presentation/widgets/stuck_now_sheet.dart';
import '../application/pawn_controllers.dart';
import '../application/pawn_providers.dart';
import 'widgets/check_in_sheet.dart';
import 'widgets/need_reading_sheet.dart';
import 'widgets/needs_inspect_tab.dart';

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
    _tabs = TabController(length: 4, vsync: this);
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
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: AppStrings.pawnTabSummary),
                Tab(text: AppStrings.pawnTabNeeds),
                Tab(text: AppStrings.pawnTabMind),
                Tab(text: AppStrings.pawnTabActivation),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _SummaryTab(profile: p, checkIn: checkIn),
                  NeedsInspectTab(
                    onRecordNeed: (snapshot) {
                      NeedReadingSheet.show(context, snapshot: snapshot);
                    },
                  ),
                  _MindTab(checkIn: checkIn),
                  const _ActivationTab(),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _profileRow(context),
          const SizedBox(height: ColonySpacing.sm),
          Wrap(
            spacing: ColonySpacing.sm,
            runSpacing: ColonySpacing.sm,
            children: [
              if (!compact)
                OutlinedButton(
                  onPressed: () => context.go('/colony/pawn-create'),
                  child: const Text(AppStrings.habitatEditPawn),
                ),
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
      ),
    );
  }

  Widget _profileRow(BuildContext context) {
    return ColonyPawnBanner(
      name: profile.displayName,
      restPips: ColonyPipMeter.countFor(checkIn?.energy),
      moodPips: ColonyPipMeter.countFor(checkIn?.mood),
      restLabel: AppStrings.homeRest,
      moodLabel: AppStrings.homeMood,
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

class _ActivationTab extends ConsumerWidget {
  const _ActivationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodes = ref.watch(activationEpisodesProvider);
    final protocols = ref.watch(activationProtocolsProvider);
    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        ColonyHeroBanner(
          assetPath: ActivationArtAssets.hero,
          height: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.activationPawnTab,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Text(AppStrings.activationHeroCaption),
            ],
          ),
        ),
        const SizedBox(height: ColonySpacing.sm),
        Text(AppStrings.activationDisclaimer),
        const SizedBox(height: ColonySpacing.sm),
        Text(AppStrings.activationNoMoralScore),
        const SizedBox(height: ColonySpacing.md),
        FilledButton(
          onPressed: () => StuckNowSheet.show(context),
          child: const Text(AppStrings.activationStuckNow),
        ),
        const SizedBox(height: ColonySpacing.lg),
        Text(AppStrings.activationProtocols,
            style: Theme.of(context).textTheme.titleMedium),
        protocols.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(AppStrings.errorGeneric),
          data: (items) => Column(
            children: [
              for (final protocol in items.take(6))
                Padding(
                  padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
                  child: ColonyJourneyCard(
                    assetPath:
                        ActivationVisualCatalog.artForProtocol(protocol),
                    title: protocol.name,
                    subtitle: ActivationVisualCatalog.forProtocol(protocol)
                        .journeyLabel,
                    height: 104,
                    onTap: () => context.go(
                      '/activation/protocols/${protocol.id.value}',
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: ColonySpacing.md),
        Text(AppStrings.activationEpisodes,
            style: Theme.of(context).textTheme.titleMedium),
        episodes.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (items) => Column(
            children: [
              for (final episode in items.take(5))
                ListTile(
                  title: Text(AppStrings.activationStatus(episode.status)),
                  subtitle: Text(episode.targetState.label),
                  onTap: () => context.go(
                    '/activation/episodes/${episode.id.value}?inspect=1',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
