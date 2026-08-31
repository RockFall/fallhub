import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/pawn_controllers.dart';
import '../../application/pawn_providers.dart';

class CheckInSheet extends ConsumerStatefulWidget {
  const CheckInSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: ColonyColors.scrim,
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        final height = MediaQuery.sizeOf(ctx).height * 0.9;
        return Padding(
          padding: EdgeInsets.fromLTRB(8, 0, 8, 8 + bottom),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(height: height, child: const CheckInSheet()),
          ),
        );
      },
    );
  }

  @override
  ConsumerState<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends ConsumerState<CheckInSheet> {
  static const _primarySlugs = {'sono', 'alimentacao', 'lazer'};

  var _mood = 0.5;
  var _moodTouched = false;
  final _needValues = <String, double>{
    for (final seed in DefaultNeedSeeds.core) seed.slug: 0.5,
  };
  final _touchedNeeds = <String>{};
  final _selectedFactors = <String>{};
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final latest = ref.read(latestCheckInProvider).asData?.value;
    final snapshots = ref.read(needSnapshotsProvider).asData?.value ?? const [];
    final bySlug = {
      for (final snapshot in snapshots) snapshot.definition.slug: snapshot,
    };

    double needOf(String slug, double? fallback) {
      if (_touchedNeeds.contains(slug)) {
        return _needValues[slug] ?? fallback ?? 0.5;
      }
      return bySlug[slug]?.normalizedValue ?? fallback ?? 0.5;
    }

    await ref
        .read(checkInControllerProvider.notifier)
        .submit(
          mood: _moodTouched ? _mood : (latest?.mood ?? _mood),
          energy: needOf('sono', latest?.energy),
          tension: needOf('ansiedade', latest?.tension),
          focus: needOf('foco', latest?.focus),
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          selectedFactors: _selectedFactors.toList(),
          needReadings: {
            for (final slug in _touchedNeeds)
              if (_needValues[slug] != null) slug: _needValues[slug]!,
          },
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(checkInControllerProvider).isLoading;
    final latest = ref.watch(latestCheckInProvider).asData?.value;
    final snapshots =
        ref.watch(needSnapshotsProvider).asData?.value ?? const [];
    final bySlug = {
      for (final snapshot in snapshots) snapshot.definition.slug: snapshot,
    };
    final mood = _moodTouched ? _mood : (latest?.mood ?? _mood);

    double needValue(String slug) {
      if (_touchedNeeds.contains(slug)) return _needValues[slug] ?? 0.5;
      return bySlug[slug]?.normalizedValue ?? 0.5;
    }

    return ColonyFrame(
      variant: ColonyFrameVariant.panel,
      grain: false,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.checkIn.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: ColonyFonts.familyTiny,
                    color: ColonyColors.textGoldHi,
                    fontSize: 13,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ColonyButton(
                variant: ColonyButtonVariant.subtle,
                height: 28,
                minWidth: 72,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(AppStrings.close),
              ),
            ],
          ),
          const SizedBox(height: ColonySpacing.sm),
          Expanded(
            child: ListView(
              children: [
                NeedInspectBar(
                  label: AppStrings.mood,
                  value: mood,
                  scale: NeedInspectBarScale.featured,
                  showPointer: true,
                  semanticId: 'pawn.checkin.humor',
                  onValueChanged: (v) => setState(() {
                    _moodTouched = true;
                    _mood = v;
                  }),
                  onValueCommit: (v) => setState(() {
                    _moodTouched = true;
                    _mood = v;
                  }),
                ),
                NeedInspectSlider(
                  value: mood,
                  onChanged: (v) => setState(() {
                    _moodTouched = true;
                    _mood = v;
                  }),
                  onCommit: (v) => setState(() {
                    _moodTouched = true;
                    _mood = v;
                  }),
                  labelOf: AppStrings.scaleFiveLabel,
                  semanticId: 'pawn.checkin.humorSlider',
                ),
                const NeedInspectGroupRule(),
                _SectionLabel(AppStrings.pawnTabNeeds),
                const SizedBox(height: ColonySpacing.xs),
                for (final seed in DefaultNeedSeeds.core)
                  if (_primarySlugs.contains(seed.slug))
                    _NeedEditor(
                      slug: seed.slug,
                      name: seed.name,
                      value: needValue(seed.slug),
                      scale: NeedInspectBarScale.primary,
                      onChanged: (v) => _setNeed(seed.slug, v),
                    ),
                const NeedInspectGroupRule(),
                for (final seed in DefaultNeedSeeds.core)
                  if (!_primarySlugs.contains(seed.slug))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SizedBox(
                        height: 34,
                        child: _NeedEditor(
                          slug: seed.slug,
                          name: seed.name,
                          value: needValue(seed.slug),
                          scale: NeedInspectBarScale.compact,
                          onChanged: (v) => _setNeed(seed.slug, v),
                        ),
                      ),
                    ),
                const NeedInspectGroupRule(),
                _SectionLabel(AppStrings.checkInFactors),
                const SizedBox(height: ColonySpacing.sm),
                Wrap(
                  spacing: ColonySpacing.sm,
                  runSpacing: ColonySpacing.sm,
                  children: [
                    for (final label in SuggestedMoodFactors.labels)
                      _FactorToggle(
                        label: label,
                        selected: _selectedFactors.contains(label),
                        onToggle: () {
                          setState(() {
                            if (_selectedFactors.contains(label)) {
                              _selectedFactors.remove(label);
                            } else {
                              _selectedFactors.add(label);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: ColonySpacing.md),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColonyColors.textPrimary,
                    fontFamily: ColonyFonts.familyReadable,
                  ),
                  decoration: const InputDecoration(
                    labelText: AppStrings.noteOptional,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ColonySpacing.sm),
          Semantics(
            identifier: 'pawn.checkin.save',
            button: true,
            child: ColonyButton(
              onPressed: loading ? null : _submit,
              expanded: true,
              child: Text(loading ? AppStrings.loading : AppStrings.checkIn),
            ),
          ),
        ],
      ),
    );
  }

  void _setNeed(String slug, double value) {
    setState(() {
      _needValues[slug] = value;
      _touchedNeeds.add(slug);
    });
  }
}

class _NeedEditor extends StatelessWidget {
  const _NeedEditor({
    required this.slug,
    required this.name,
    required this.value,
    required this.scale,
    required this.onChanged,
  });

  final String slug;
  final String name;
  final double value;
  final NeedInspectBarScale scale;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return NeedInspectBar(
      label: name,
      value: value,
      scale: scale,
      showPointer: scale != NeedInspectBarScale.compact,
      fillSlot: scale == NeedInspectBarScale.compact,
      semanticId: 'pawn.checkin.need.$slug',
      onValueChanged: onChanged,
      onValueCommit: onChanged,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: ColonyFonts.familyTiny,
        color: ColonyColors.textGoldHi,
        fontSize: 11,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _FactorToggle extends StatelessWidget {
  const _FactorToggle({
    required this.label,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      identifier: 'pawn.checkin.factor.$label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              style: TextStyle(
                fontFamily: ColonyFonts.familyTiny,
                fontSize: 10,
                letterSpacing: 0.5,
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
