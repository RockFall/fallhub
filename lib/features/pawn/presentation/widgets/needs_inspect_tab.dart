import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../application/pawn_controllers.dart';
import '../../application/pawn_providers.dart';

class NeedsInspectTab extends ConsumerStatefulWidget {
  const NeedsInspectTab({super.key, required this.onRecordNeed});

  final void Function(NeedSnapshot snapshot) onRecordNeed;

  @override
  ConsumerState<NeedsInspectTab> createState() => _NeedsInspectTabState();
}

class _NeedsInspectTabState extends ConsumerState<NeedsInspectTab> {
  static const _expandMs = Duration(milliseconds: 280);

  EntityId? _selectedNeedId;
  var _humorChart = false;
  int? _selectedDayIndex;
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
                              onRecord: widget.onRecordNeed,
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
                                      buckets: _buckets(),
                                      selectedDayIndex: _selectedDayIndex,
                                      onSelectDay: _selectDay,
                                      dayFactors: _humorChart
                                          ? _dayFactors
                                          : const [],
                                      dayNote: _selectedBucket()?.note,
                                      showRecordSlider: _selectedNeedId != null,
                                      currentValue: _selectedSnapshot(
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
    final bySlug = {
      for (final snapshot in snapshots) snapshot.definition.slug: snapshot,
    };
    return [
      for (final seed in DefaultNeedSeeds.core)
        if (bySlug[seed.slug] != null) bySlug[seed.slug]!,
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
    if (_humorChart) return AppStrings.needChartTitle(AppStrings.mood);
    final selected = _selectedSnapshot(catalog);
    return AppStrings.needChartTitle(selected?.definition.name ?? '');
  }

  List<NeedDayBucket> _buckets() {
    final now = ref.read(clockProvider)().toLocal();
    return NeedHistorySeries.lastLocalDays(nowLocal: now, samples: _samples);
  }

  NeedDayBucket? _selectedBucket() {
    final buckets = _buckets();
    final index = _selectedDayIndex;
    if (index == null || index < 0 || index >= buckets.length) return null;
    return buckets[index];
  }

  Future<void> _openNeedChart(NeedSnapshot snapshot) async {
    setState(() {
      _selectedNeedId = snapshot.definition.id;
      _humorChart = false;
      _selectedDayIndex = null;
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
      _samples = const [];
      _dayFactors = const [];
    });
  }

  Future<void> _selectDay(int index) async {
    setState(() => _selectedDayIndex = index);
    if (!_humorChart) return;
    final buckets = _buckets();
    if (index < 0 || index >= buckets.length) return;
    await _loadDayFactors(buckets[index].sourceId);
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
    final since = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final readings = await ref
        .read(repositoriesProvider)
        .needs
        .listReadings(needId, since: since);
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
    final buckets = NeedHistorySeries.lastLocalDays(
      nowLocal: now,
      samples: samples,
    );
    setState(() {
      _samples = samples;
      _selectedDayIndex = _indexWithData(buckets) ?? buckets.length - 1;
    });
  }

  Future<void> _loadHumorHistory() async {
    final token = ++_historyToken;
    final profile = await ref.read(profileProvider.future);
    if (profile == null || !mounted || token != _historyToken) return;
    final now = ref.read(clockProvider)().toLocal();
    final since = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final checkIns = await ref
        .read(repositoriesProvider)
        .checkIns
        .listSince(profile.id, since);
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
    final buckets = NeedHistorySeries.lastLocalDays(
      nowLocal: now,
      samples: samples,
    );
    final selected = _indexWithData(buckets) ?? buckets.length - 1;
    setState(() {
      _samples = samples;
      _selectedDayIndex = selected;
    });
    await _loadDayFactors(buckets[selected].sourceId);
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

  int? _indexWithData(List<NeedDayBucket> buckets) {
    for (var i = buckets.length - 1; i >= 0; i--) {
      if (buckets[i].value != null) return i;
    }
    return null;
  }

  Future<void> _recordToday(double normalized) async {
    final needId = _selectedNeedId;
    if (needId == null) return;
    await ref
        .read(needReadingControllerProvider.notifier)
        .record(needId: needId, scaleValue: denormalizeScale5(normalized));
    await _loadNeedHistory(needId);
  }
}

class _NeedRail extends StatelessWidget {
  const _NeedRail({
    required this.snapshots,
    required this.selectedId,
    required this.onSelect,
    required this.onRecord,
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
  final void Function(NeedSnapshot snapshot) onRecord;

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
            onLongPress: () => onRecord(snapshot),
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
  });

  final CheckIn? checkIn;
  final List<MoodFactor> factors;
  final VoidCallback onOpenChart;

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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ColonyColors.textSecondary,
                          ),
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
    required this.buckets,
    required this.selectedDayIndex,
    required this.onSelectDay,
    required this.dayFactors,
    required this.dayNote,
    required this.showRecordSlider,
    required this.currentValue,
    required this.onRecordToday,
    required this.onBackToHumor,
  });

  final String title;
  final List<NeedDayBucket> buckets;
  final int? selectedDayIndex;
  final ValueChanged<int> onSelectDay;
  final List<MoodFactor> dayFactors;
  final String? dayNote;
  final bool showRecordSlider;
  final double? currentValue;
  final ValueChanged<double> onRecordToday;
  final VoidCallback onBackToHumor;

  @override
  Widget build(BuildContext context) {
    final selected =
        (selectedDayIndex != null &&
            selectedDayIndex! >= 0 &&
            selectedDayIndex! < buckets.length)
        ? buckets[selectedDayIndex!]
        : null;
    final hasData = buckets.any((b) => b.value != null);

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
          const SizedBox(height: ColonySpacing.sm),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NeedSparkline(
                    values: [for (final bucket in buckets) bucket.value],
                    labels: [
                      for (final bucket in buckets)
                        AppStrings.weekdayInitial(bucket.day),
                    ],
                    selectedIndex: selectedDayIndex,
                    onSelect: onSelectDay,
                  ),
                  const SizedBox(height: ColonySpacing.sm),
                  if (!hasData)
                    Text(
                      AppStrings.needNoHistory,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColonyColors.textMuted,
                      ),
                    )
                  else if (selected != null) ...[
                    Text(
                      AppStrings.needDayHeadline(
                        selected.day,
                        selected.value == null
                            ? '—'
                            : AppStrings.scaleFiveLabel(selected.value!),
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
                  ],
                  if (showRecordSlider) ...[
                    const SizedBox(height: ColonySpacing.sm),
                    Text(
                      AppStrings.needRecordToday,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ColonyColors.textMuted,
                      ),
                    ),
                    _TodaySlider(value: currentValue, onCommit: onRecordToday),
                  ],
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

class _TodaySlider extends StatefulWidget {
  const _TodaySlider({required this.value, required this.onCommit});

  final double? value;
  final ValueChanged<double> onCommit;

  @override
  State<_TodaySlider> createState() => _TodaySliderState();
}

class _TodaySliderState extends State<_TodaySlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value ?? 0.5;
  }

  @override
  void didUpdateWidget(covariant _TodaySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != null) {
      _value = widget.value!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: ColonyColors.needsFill,
        inactiveTrackColor: ColonyColors.borderSeparator,
        thumbColor: ColonyColors.textGoldHi,
        overlayColor: ColonyColors.needsFill.withValues(alpha: 0.16),
      ),
      child: Slider(
        value: _value.clamp(0, 1),
        min: 0,
        max: 1,
        divisions: 4,
        label: AppStrings.scaleFiveLabel(_value),
        onChanged: (v) => setState(() => _value = v),
        onChangeEnd: widget.onCommit,
      ),
    );
  }
}
