import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../application/pawn_controllers.dart';
import '../../application/pawn_providers.dart';

class NeedsInspectTab extends ConsumerStatefulWidget {
  const NeedsInspectTab({super.key});

  @override
  ConsumerState<NeedsInspectTab> createState() => _NeedsInspectTabState();
}

class _NeedsInspectTabState extends ConsumerState<NeedsInspectTab> {
  static const _expandMs = Duration(milliseconds: 280);

  EntityId? _selectedNeedId;
  var _humorChart = false;
  var _range = NeedHistoryRange.all;
  int? _selectedDayIndex;
  int? _selectedPointIndex;
  var _historyToken = 0;
  List<NeedHistorySample> _samples = const [];
  List<MoodFactor> _latestFactors = const [];
  List<MoodFactor> _dayFactors = const [];
  EntityId? _factorsForCheckIn;

  bool get _chartMode => _selectedNeedId != null || _humorChart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final checkIn = ref.read(latestCheckInProvider).asData?.value;
      _factorsForCheckIn = checkIn?.id;
      _loadLatestFactors(checkIn);
    });
  }

  @override
  Widget build(BuildContext context) {
    final needs = ref.watch(needSnapshotsProvider);
    final checkIn = ref.watch(latestCheckInProvider);

    ref.listen<AsyncValue<CheckIn?>>(latestCheckInProvider, (prev, next) {
      final latest = next.asData?.value;
      if (latest?.id == _factorsForCheckIn) return;
      _factorsForCheckIn = latest?.id;
      _loadLatestFactors(latest);
    });

    final latest = checkIn.asData?.value;

    return needs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(AppStrings.errorGeneric)),
      data: (snapshots) {
        final catalog = _catalog(snapshots);
        return Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
          child: LayoutBuilder(
            builder: (context, outer) {
              return SizedBox(
                width: outer.maxWidth,
                height: outer.maxHeight,
                child: ColonyFrame(
                  variant: ColonyFrameVariant.panel,
                  grain: false,
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final leftFraction = _chartMode ? 0.38 : 0.54;
                      final leftWidth = constraints.maxWidth * leftFraction;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedContainer(
                            duration: _expandMs,
                            curve: Curves.easeInOutCubic,
                            width: leftWidth,
                            child: _NeedRail(
                              snapshots: catalog,
                              selectedId: _selectedNeedId,
                              onSelect: _openNeedChart,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: ColoredBox(
                              color: ColonyColors.borderSeparator,
                              child: SizedBox(width: 1),
                            ),
                          ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: ColonyDurations.normal,
                              child: _chartMode
                                  ? _ChartPane(
                                      key: ValueKey(
                                        _selectedNeedId?.value ?? 'humor-chart',
                                      ),
                                      title: _chartTitle(catalog),
                                      range: _range,
                                      window: _window(),
                                      selectedDayIndex: _selectedDayIndex,
                                      selectedPointIndex: _selectedPointIndex,
                                      onSelectPoint: _selectPoint,
                                      onSelectDay: _selectEmptyDay,
                                      onSelectRange: _selectRange,
                                      dayFactors: _humorChart
                                          ? _dayFactors
                                          : const [],
                                      dayNote: _selectedPoint()?.note,
                                      currentValue: _humorChart
                                          ? latest?.mood
                                          : _selectedSnapshot(
                                              catalog,
                                            )?.normalizedValue,
                                      onRecordToday: _recordToday,
                                      onBackToHumor: _backToHumor,
                                    )
                                  : _HumorPane(
                                      key: const ValueKey('humor-pane'),
                                      checkIn: latest,
                                      factors: _latestFactors,
                                      onOpenChart: _openHumorChart,
                                      onRecordMood: _recordHumorToday,
                                    ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<NeedSnapshot> _catalog(List<NeedSnapshot> snapshots) {
    NeedSnapshot? match(NeedSeed seed) {
      for (final snapshot in snapshots) {
        if (seed.matchesSlug(snapshot.definition.slug)) return snapshot;
      }
      return null;
    }

    return [
      for (final seed in DefaultNeedSeeds.core)
        if (match(seed) != null) match(seed)!,
    ];
  }

  NeedSnapshot? _selectedSnapshot(List<NeedSnapshot> catalog) {
    if (_selectedNeedId == null) return null;
    for (final snapshot in catalog) {
      if (snapshot.definition.id == _selectedNeedId) return snapshot;
    }
    return null;
  }

  String _chartTitle(List<NeedSnapshot> catalog) {
    if (_humorChart) {
      return AppStrings.needChartTitle(AppStrings.mood, range: _range);
    }
    final selected = _selectedSnapshot(catalog);
    return AppStrings.needChartTitle(
      selected?.definition.name ?? '',
      range: _range,
    );
  }

  NeedHistoryWindow _window() {
    final now = ref.read(clockProvider)().toLocal();
    return NeedHistorySeries.forRange(
      nowLocal: now,
      samples: _samples,
      range: _range,
    );
  }

  NeedHistoryPoint? _selectedPoint() {
    final points = _window().points;
    final index = _selectedPointIndex;
    if (index == null || index < 0 || index >= points.length) return null;
    return points[index];
  }

  Future<void> _openNeedChart(NeedSnapshot snapshot) async {
    setState(() {
      _selectedNeedId = snapshot.definition.id;
      _humorChart = false;
      _selectedDayIndex = null;
      _selectedPointIndex = null;
      _samples = const [];
      _dayFactors = const [];
    });
    await _loadNeedHistory(snapshot.definition.id);
  }

  Future<void> _openHumorChart() async {
    setState(() {
      _selectedNeedId = null;
      _humorChart = true;
      _selectedDayIndex = null;
      _selectedPointIndex = null;
      _samples = const [];
      _dayFactors = const [];
    });
    await _loadHumorHistory();
  }

  void _backToHumor() {
    setState(() {
      _selectedNeedId = null;
      _humorChart = false;
      _selectedDayIndex = null;
      _selectedPointIndex = null;
      _samples = const [];
      _dayFactors = const [];
    });
  }

  void _selectRange(NeedHistoryRange range) {
    if (range == _range) return;
    final now = ref.read(clockProvider)().toLocal();
    final window = NeedHistorySeries.forRange(
      nowLocal: now,
      samples: _samples,
      range: range,
    );
    setState(() {
      _range = range;
      if (window.points.isEmpty) {
        _selectedPointIndex = null;
        _selectedDayIndex = window.days.isEmpty ? null : window.days.length - 1;
        _dayFactors = const [];
      } else {
        _selectedPointIndex = window.points.length - 1;
        _selectedDayIndex = window.days.indexOf(window.points.last.day);
      }
    });
    if (_humorChart && window.points.isNotEmpty) {
      _loadDayFactors(window.points.last.id);
    }
  }

  Future<void> _selectPoint(int index) async {
    final window = _window();
    if (index < 0 || index >= window.points.length) return;
    final point = window.points[index];
    setState(() {
      _selectedPointIndex = index;
      _selectedDayIndex = window.days.indexOf(point.day);
    });
    if (!_humorChart) return;
    await _loadDayFactors(point.id);
  }

  Future<void> _selectEmptyDay(int index) async {
    setState(() {
      _selectedPointIndex = null;
      _selectedDayIndex = index;
      _dayFactors = const [];
    });
  }

  Future<void> _loadLatestFactors(CheckIn? checkIn) async {
    if (checkIn == null) {
      if (mounted) setState(() => _latestFactors = const []);
      return;
    }
    final factors = await ref
        .read(repositoriesProvider)
        .checkIns
        .getFactors(checkIn.id);
    if (mounted) setState(() => _latestFactors = factors);
  }

  Future<void> _loadNeedHistory(EntityId needId) async {
    final token = ++_historyToken;
    final now = ref.read(clockProvider)().toLocal();
    final readings = await ref
        .read(repositoriesProvider)
        .needs
        .listReadings(needId);
    if (!mounted || token != _historyToken) return;
    final samples = [
      for (final reading in readings)
        NeedHistorySample(
          id: reading.id,
          observedAt: reading.observedAt,
          value: reading.normalizedValue,
          note: reading.note,
        ),
    ];
    final window = NeedHistorySeries.forRange(
      nowLocal: now,
      samples: samples,
      range: _range,
    );
    setState(() {
      _samples = samples;
      _selectedPointIndex = window.points.isEmpty
          ? null
          : window.points.length - 1;
      _selectedDayIndex = window.points.isEmpty
          ? window.days.length - 1
          : window.days.indexOf(window.points.last.day);
    });
  }

  Future<void> _loadHumorHistory() async {
    final token = ++_historyToken;
    final profile = await ref.read(profileProvider.future);
    if (profile == null || !mounted || token != _historyToken) return;
    final now = ref.read(clockProvider)().toLocal();
    final checkIns = await ref
        .read(repositoriesProvider)
        .checkIns
        .listAll(profile.id);
    if (!mounted || token != _historyToken) return;
    final samples = [
      for (final checkIn in checkIns)
        NeedHistorySample(
          id: checkIn.id,
          observedAt: checkIn.observedAt,
          value: checkIn.mood,
          note: checkIn.note,
        ),
    ];
    final window = NeedHistorySeries.forRange(
      nowLocal: now,
      samples: samples,
      range: _range,
    );
    final selected = window.points.isEmpty ? null : window.points.length - 1;
    setState(() {
      _samples = samples;
      _selectedPointIndex = selected;
      _selectedDayIndex = selected == null
          ? window.days.length - 1
          : window.days.indexOf(window.points[selected].day);
    });
    await _loadDayFactors(selected == null ? null : window.points[selected].id);
  }

  Future<void> _loadDayFactors(EntityId? checkInId) async {
    if (checkInId == null) {
      if (mounted) setState(() => _dayFactors = const []);
      return;
    }
    final factors = await ref
        .read(repositoriesProvider)
        .checkIns
        .getFactors(checkInId);
    if (mounted) setState(() => _dayFactors = factors);
  }

  Future<void> _recordToday(double normalized) async {
    if (_humorChart) {
      await _recordHumorToday(normalized);
      return;
    }
    final needId = _selectedNeedId;
    if (needId == null) return;
    await ref
        .read(needReadingControllerProvider.notifier)
        .record(needId: needId, scaleValue: denormalizeScale5(normalized));
    await _loadNeedHistory(needId);
  }

  Future<void> _recordHumorToday(double mood) async {
    await ref.read(checkInControllerProvider.notifier).recordMood(mood);
    if (_humorChart) {
      await _loadHumorHistory();
    }
  }
}

class _NeedRail extends StatelessWidget {
  const _NeedRail({
    required this.snapshots,
    required this.selectedId,
    required this.onSelect,
  });

  static const _primarySlugs = {'sono', 'alimentacao', 'lazer'};
  static const _primaryFlex = 5;
  static const _compactFlex = 3;
  static const _primaryMin = 44.0;
  static const _compactMin = 26.0;
  static const _ruleExtent = 14.0;

  final List<NeedSnapshot> snapshots;
  final EntityId? selectedId;
  final ValueChanged<NeedSnapshot> onSelect;

  @override
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) {
      return Center(child: Text(AppStrings.needsStable));
    }
    final primary = [
      for (final snapshot in snapshots)
        if (_primarySlugs.contains(snapshot.definition.slug)) snapshot,
    ];
    final compact = [
      for (final snapshot in snapshots)
        if (!_primarySlugs.contains(snapshot.definition.slug)) snapshot,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final needed =
            primary.length * _primaryMin +
            compact.length * _compactMin +
            (primary.isNotEmpty && compact.isNotEmpty ? _ruleExtent : 0);
        final useFlex =
            constraints.hasBoundedHeight && constraints.maxHeight >= needed;

        Widget bar(NeedSnapshot snapshot, NeedInspectBarScale scale) {
          return NeedInspectBar(
            label: snapshot.definition.name,
            value: snapshot.normalizedValue,
            selected: snapshot.definition.id == selectedId,
            scale: scale,
            showChevron: true,
            showPointer: snapshot.definition.id == selectedId,
            fillSlot: true,
            semanticId: 'pawn.need.${snapshot.definition.slug}',
            onTap: () => onSelect(snapshot),
          );
        }

        final children = <Widget>[
          for (final snapshot in primary)
            useFlex
                ? Expanded(
                    flex: _primaryFlex,
                    child: bar(snapshot, NeedInspectBarScale.primary),
                  )
                : SizedBox(
                    height: _primaryMin,
                    child: bar(snapshot, NeedInspectBarScale.primary),
                  ),
          if (primary.isNotEmpty && compact.isNotEmpty)
            const NeedInspectGroupRule(),
          for (final snapshot in compact)
            useFlex
                ? Expanded(
                    flex: _compactFlex,
                    child: bar(snapshot, NeedInspectBarScale.compact),
                  )
                : SizedBox(
                    height: _compactMin,
                    child: bar(snapshot, NeedInspectBarScale.compact),
                  ),
        ];

        if (useFlex) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Column(children: children),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(right: 4),
          children: children,
        );
      },
    );
  }
}

class _HumorPane extends StatelessWidget {
  const _HumorPane({
    super.key,
    required this.checkIn,
    required this.factors,
    required this.onOpenChart,
    required this.onRecordMood,
  });

  final CheckIn? checkIn;
  final List<MoodFactor> factors;
  final VoidCallback onOpenChart;
  final ValueChanged<double> onRecordMood;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeedInspectBar(
            label: AppStrings.mood,
            value: checkIn?.mood,
            scale: NeedInspectBarScale.featured,
            showPointer: true,
            semanticId: 'pawn.need.humor',
            onTap: onOpenChart,
            onValueCommit: onRecordMood,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: checkIn == null
                ? Text(
                    AppStrings.noCheckInYet,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColonyColors.textMuted,
                      fontFamily: ColonyFonts.familyTiny,
                      fontSize: 10,
                      letterSpacing: 0.4,
                    ),
                  )
                : ListView(
                    children: [
                      ModifierList(
                        compact: true,
                        entries: [
                          for (final factor in factors)
                            ModifierEntry(
                              label: factor.label,
                              impact: factor.impact,
                              uncertain: factor.uncertain,
                            ),
                        ],
                      ),
                      if (checkIn?.note != null &&
                          checkIn!.note!.isNotEmpty) ...[
                        const SizedBox(height: ColonySpacing.md),
                        Text(
                          checkIn!.note!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: ColonyColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChartPane extends StatelessWidget {
  const _ChartPane({
    super.key,
    required this.title,
    required this.range,
    required this.window,
    required this.selectedDayIndex,
    required this.selectedPointIndex,
    required this.onSelectPoint,
    required this.onSelectDay,
    required this.onSelectRange,
    required this.dayFactors,
    required this.dayNote,
    required this.currentValue,
    required this.onRecordToday,
    required this.onBackToHumor,
  });

  final String title;
  final NeedHistoryRange range;
  final NeedHistoryWindow window;
  final int? selectedDayIndex;
  final int? selectedPointIndex;
  final ValueChanged<int> onSelectPoint;
  final ValueChanged<int> onSelectDay;
  final ValueChanged<NeedHistoryRange> onSelectRange;
  final List<MoodFactor> dayFactors;
  final String? dayNote;
  final double? currentValue;
  final ValueChanged<double> onRecordToday;
  final VoidCallback onBackToHumor;

  @override
  Widget build(BuildContext context) {
    final points = window.points;
    final selectedPoint =
        (selectedPointIndex != null &&
            selectedPointIndex! >= 0 &&
            selectedPointIndex! < points.length)
        ? points[selectedPointIndex!]
        : null;
    final selectedDay =
        (selectedDayIndex != null &&
            selectedDayIndex! >= 0 &&
            selectedDayIndex! < window.days.length)
        ? window.days[selectedDayIndex!]
        : null;
    final hasData = points.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: ColonyFonts.familyTiny,
              color: ColonyColors.textGoldHi,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: ColonySpacing.xs),
          _NeedHistoryRangeToggle(range: range, onSelect: onSelectRange),
          const SizedBox(height: ColonySpacing.sm),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NeedSparkline(
                    points: [
                      for (final point in points)
                        NeedSparklinePoint(x: point.x, value: point.value),
                    ],
                    labels: AppStrings.needHistoryAxisLabels(window.days),
                    selectedIndex: selectedPointIndex,
                    highlightedDayIndex: selectedDayIndex,
                    onSelectPoint: onSelectPoint,
                    onSelectDay: onSelectDay,
                  ),
                  const SizedBox(height: ColonySpacing.sm),
                  if (!hasData)
                    Text(
                      AppStrings.needNoHistoryFor(range),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColonyColors.textMuted,
                      ),
                    )
                  else if (selectedPoint != null) ...[
                    Text(
                      AppStrings.needSampleHeadline(
                        selectedPoint.observedAt,
                        AppStrings.scaleFiveLabel(selectedPoint.value),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (dayFactors.isNotEmpty) ...[
                      const SizedBox(height: ColonySpacing.sm),
                      ModifierList(
                        compact: true,
                        entries: [
                          for (final factor in dayFactors)
                            ModifierEntry(
                              label: factor.label,
                              impact: factor.impact,
                              uncertain: factor.uncertain,
                            ),
                        ],
                      ),
                    ],
                    if (dayNote != null && dayNote!.isNotEmpty) ...[
                      const SizedBox(height: ColonySpacing.sm),
                      Text(
                        dayNote!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ] else if (selectedDay != null) ...[
                    Text(
                      AppStrings.needDayHeadline(selectedDay, '—'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: ColonySpacing.sm),
                  Text(
                    AppStrings.needRecordToday,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ColonyColors.textMuted,
                    ),
                  ),
                  NeedInspectSlider(
                    value: currentValue,
                    onCommit: onRecordToday,
                    labelOf: AppStrings.scaleFiveLabel,
                    semanticId: 'pawn.needs.recordToday',
                  ),
                ],
              ),
            ),
          ),
          Semantics(
            identifier: 'pawn.needs.humorBack',
            button: true,
            child: ColonyButton(
              onPressed: onBackToHumor,
              expanded: true,
              child: const Text(AppStrings.mood),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedHistoryRangeToggle extends StatelessWidget {
  const _NeedHistoryRangeToggle({required this.range, required this.onSelect});

  final NeedHistoryRange range;
  final ValueChanged<NeedHistoryRange> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in NeedHistoryRange.values) ...[
          if (option != NeedHistoryRange.values.first) const SizedBox(width: 4),
          Expanded(
            child: _NeedHistoryRangeChip(
              range: option,
              selected: option == range,
              onTap: () => onSelect(option),
            ),
          ),
        ],
      ],
    );
  }
}

class _NeedHistoryRangeChip extends StatelessWidget {
  const _NeedHistoryRangeChip({
    required this.range,
    required this.selected,
    required this.onTap,
  });

  final NeedHistoryRange range;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = AppStrings.needHistoryRangeLabel(range);
    return Semantics(
      button: true,
      selected: selected,
      identifier: 'pawn.needs.range.${range.name}',
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ColonyRadii.sm),
          child: Container(
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? ColonyColors.optionSelected
                  : ColonyColors.optionUnselected,
              border: Border.all(
                color: selected
                    ? ColonyColors.borderSelected
                    : ColonyColors.borderStandard,
              ),
              borderRadius: BorderRadius.circular(ColonyRadii.sm),
            ),
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: ColonyFonts.familyTiny,
                fontSize: 9,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w700,
                color: selected
                    ? ColonyColors.textGoldHi
                    : ColonyColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
