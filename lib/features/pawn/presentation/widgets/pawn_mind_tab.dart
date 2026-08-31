import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../application/pawn_providers.dart';
import 'check_in_sheet.dart';
import 'pawn_tab_chrome.dart';

class PawnMindTab extends ConsumerStatefulWidget {
  const PawnMindTab({super.key});

  @override
  ConsumerState<PawnMindTab> createState() => _PawnMindTabState();
}

class _PawnMindTabState extends ConsumerState<PawnMindTab> {
  List<MoodFactor> _factors = const [];
  EntityId? _loadedFor;

  @override
  Widget build(BuildContext context) {
    final checkInAsync = ref.watch(latestCheckInProvider);
    final checkIn = checkInAsync.asData?.value;
    final now = ref.watch(clockProvider)().toLocal();

    ref.listen<AsyncValue<CheckIn?>>(latestCheckInProvider, (prev, next) {
      final latest = next.asData?.value;
      if (latest?.id == _loadedFor) return;
      _loadFactors(latest);
    });
    if (checkIn?.id != _loadedFor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadFactors(checkIn);
      });
    }

    final plus = [
      for (final factor in _factors)
        if ((factor.impact ?? 0) > 0) factor,
    ];
    final minus = [
      for (final factor in _factors)
        if ((factor.impact ?? 0) < 0) factor,
    ];
    final named = [
      for (final factor in _factors)
        if (factor.impact == null || factor.impact == 0) factor,
    ];
    final today = checkIn != null && _isLocalDay(checkIn.observedAt, now);

    return PawnPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MoodStamp(
                  label: checkIn?.moodLabel,
                  today: today,
                  hasCheckIn: checkIn != null,
                ),
              ),
              const SizedBox(width: 10),
              ColonyButton(
                height: 28,
                minWidth: 84,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                onPressed: () => CheckInSheet.show(context),
                child: const Text(AppStrings.checkIn),
              ),
            ],
          ),
          const NeedInspectGroupRule(),
          Expanded(
            child: ListView(
              children: [
                if (checkIn == null)
                  const PawnMutedText(AppStrings.noCheckInYet)
                else ...[
                  if (plus.isNotEmpty)
                    _FactorBlock(title: AppStrings.pawnMindLift, factors: plus),
                  if (minus.isNotEmpty)
                    _FactorBlock(
                      title: AppStrings.pawnMindDrag,
                      factors: minus,
                    ),
                  if (named.isNotEmpty)
                    _FactorBlock(
                      title: AppStrings.pawnMindNamed,
                      factors: named,
                    ),
                  if (_factors.isEmpty)
                    const PawnMutedText(AppStrings.noFactorsYet),
                  if (checkIn.note != null && checkIn.note!.isNotEmpty) ...[
                    const SizedBox(height: ColonySpacing.sm),
                    const PawnSectionLabel(AppStrings.note),
                    const SizedBox(height: 6),
                    Text(
                      checkIn.note!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColonyColors.textSecondary,
                        fontFamily: ColonyFonts.familyReadable,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
                const NeedInspectGroupRule(),
                const PawnSectionLabel(AppStrings.pawnMindPrompts),
                const SizedBox(height: 4),
                const PawnMutedText(AppStrings.pawnMindPromptHint),
                const SizedBox(height: 6),
                for (final prompt in CheckInPrompts.daily)
                  PawnLogRow(
                    title: prompt,
                    onTap: () => CheckInSheet.show(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadFactors(CheckIn? checkIn) async {
    _loadedFor = checkIn?.id;
    if (checkIn == null) {
      if (mounted) setState(() => _factors = const []);
      return;
    }
    final factors = await ref
        .read(repositoriesProvider)
        .checkIns
        .getFactors(checkIn.id);
    if (!mounted || _loadedFor != checkIn.id) return;
    setState(() => _factors = factors);
  }

  static bool _isLocalDay(DateTime utc, DateTime nowLocal) {
    final local = utc.toLocal();
    return local.year == nowLocal.year &&
        local.month == nowLocal.month &&
        local.day == nowLocal.day;
  }
}

class _MoodStamp extends StatelessWidget {
  const _MoodStamp({
    required this.label,
    required this.today,
    required this.hasCheckIn,
  });

  final String? label;
  final bool today;
  final bool hasCheckIn;

  @override
  Widget build(BuildContext context) {
    return ColonyFrame(
      variant: ColonyFrameVariant.inset,
      grain: false,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.moodDeclared.toUpperCase(),
            style: const TextStyle(
              fontFamily: ColonyFonts.familyTiny,
              color: ColonyColors.textMuted,
              fontSize: 9,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            (hasCheckIn ? (label ?? '—') : '—').toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: ColonyFonts.familyTiny,
              color: ColonyColors.textGoldHi,
              fontSize: 22,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          if (hasCheckIn && !today) ...[
            const SizedBox(height: 4),
            const PawnMutedText(AppStrings.pawnSitrepMoodNotToday, tiny: true),
          ],
        ],
      ),
    );
  }
}

class _FactorBlock extends StatelessWidget {
  const _FactorBlock({required this.title, required this.factors});

  final String title;
  final List<MoodFactor> factors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PawnSectionLabel(title),
          const SizedBox(height: 4),
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
        ],
      ),
    );
  }
}
