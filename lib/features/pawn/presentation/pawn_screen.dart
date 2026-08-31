import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../application/pawn_controllers.dart';
import '../application/pawn_providers.dart';
import 'widgets/check_in_sheet.dart';
import 'widgets/needs_inspect_tab.dart';
import 'widgets/pawn_mind_tab.dart';
import 'widgets/pawn_mobilization_tab.dart';
import 'widgets/pawn_summary_tab.dart';

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
      error: (_, _) => Center(child: Text(AppStrings.errorGeneric)),
      data: (p) {
        if (p == null) return const SizedBox.shrink();
        return Column(
          children: [
            checkIn.when(
              data: (c) => _PawnHeader(
                profile: p,
                checkIn: c,
                onCheckIn: () => CheckInSheet.show(context),
              ),
              loading: () => _PawnHeader(
                profile: p,
                checkIn: null,
                onCheckIn: () => CheckInSheet.show(context),
              ),
              error: (_, _) => _PawnHeader(
                profile: p,
                checkIn: null,
                onCheckIn: () => CheckInSheet.show(context),
              ),
            ),
            _PawnTabStrip(
              controller: _tabs,
              labels: const [
                AppStrings.pawnTabSummary,
                AppStrings.pawnTabNeeds,
                AppStrings.pawnTabMind,
                AppStrings.pawnTabActivation,
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  PawnSummaryTab(
                    onOpenNeeds: () => _tabs.animateTo(1),
                    onOpenActivation: () => _tabs.animateTo(3),
                  ),
                  const NeedsInspectTab(),
                  const PawnMindTab(),
                  const PawnMobilizationTab(),
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
  });

  final ColonyProfile profile;
  final CheckIn? checkIn;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: ColonyPawnBanner(
        name: profile.displayName,
        restPips: ColonyPipMeter.countFor(checkIn?.energy),
        moodPips: ColonyPipMeter.countFor(checkIn?.mood),
        restLabel: AppStrings.homeRest,
        moodLabel: AppStrings.homeMood,
        trailing: ColonyButton(
          onPressed: onCheckIn,
          height: 28,
          minWidth: 84,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: const Text(AppStrings.checkIn),
        ),
      ),
    );
  }
}

class _PawnTabStrip extends StatelessWidget {
  const _PawnTabStrip({required this.controller, required this.labels});

  final TabController controller;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          child: SizedBox(
            height: 34,
            child: Row(
              children: [
                for (var i = 0; i < labels.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return ColonyFrame(
                          variant: ColonyFrameVariant.tile,
                          selected: controller.index == i,
                          grain: false,
                          width: constraints.maxWidth,
                          height: 34,
                          fill: controller.index == i
                              ? ColonyColors.actionHover
                              : ColonyColors.actionBase,
                          onTap: () => controller.animateTo(i),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Text(
                                labels[i].toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: ColonyFonts.familyTiny,
                                  fontSize: 9,
                                  letterSpacing: 0.45,
                                  height: 1.0,
                                  fontWeight: FontWeight.w700,
                                  color: controller.index == i
                                      ? ColonyColors.textGoldHi
                                      : ColonyColors.textButton,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
