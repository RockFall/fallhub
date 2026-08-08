import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';
import '../../flame/habitat_game.dart';
import '../../flame/habitat_room_stats.dart';

/// Compact room role + 4 meters (V9.7) — sits under the colonist bar.
class HabitatRoomStatsStrip extends StatefulWidget {
  const HabitatRoomStatsStrip({
    super.key,
    required this.game,
  });

  final HabitatGame game;

  @override
  State<HabitatRoomStatsStrip> createState() => _HabitatRoomStatsStripState();
}

class _HabitatRoomStatsStripState extends State<HabitatRoomStatsStrip> {
  bool _expanded = false;
  bool _spaceFlash = false;
  int _lastGen = -1;
  HabitatRoomStats _display = HabitatRoomStats.empty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFromGame(animate: false);
  }

  void _syncFromGame({required bool animate}) {
    final stats = widget.game.roomStats;
    final gen = widget.game.roomStatsGeneration;
    if (gen == _lastGen && animate) return;
    _lastGen = gen;
    if (widget.game.spaceTightPulse) {
      widget.game.consumeSpaceTightPulse();
      _spaceFlash = true;
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _spaceFlash = false);
      });
    }
    setState(() => _display = stats);
  }

  @override
  Widget build(BuildContext context) {
    // Pull latest stats when parent rebuilds (edit / location / timer).
    final gen = widget.game.roomStatsGeneration;
    if (gen != _lastGen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncFromGame(animate: true);
      });
    }

    final stats = _display;
    final role = _roleLabel(stats.role);
    final impress = _impressLabel(stats.impressiveness);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(3),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xCC141416),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0x66FFFFFF)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      role,
                      key: ValueKey(role),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    impress,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Meter(
                    label: AppStrings.habitatRoomStatBeauty,
                    value: stats.beauty,
                    color: const Color(0xFF7BC67E),
                  ),
                  _Meter(
                    label: AppStrings.habitatRoomStatSpace,
                    value: stats.space,
                    color: _spaceFlash
                        ? const Color(0xFFE8A838)
                        : const Color(0xFF6EB5E0),
                    flash: _spaceFlash,
                  ),
                  _Meter(
                    label: AppStrings.habitatRoomStatClean,
                    value: stats.cleanliness,
                    color: const Color(0xFFB8C4D4),
                  ),
                  _Meter(
                    label: AppStrings.habitatRoomStatWealth,
                    value: stats.wealth,
                    color: const Color(0xFFD4B06A),
                  ),
                  _Meter(
                    label: AppStrings.habitatRoomStatComfort,
                    value: stats.comfort,
                    color: const Color(0xFFE8A0C8),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity, height: 0),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in stats.breakdown)
                        Text(
                          '${line.label} ${line.delta >= 0 ? '+' : ''}${line.delta}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                            height: 1.25,
                          ),
                        ),
                      if (stats.breakdown.isEmpty)
                        Text(
                          AppStrings.habitatInspectEmptyShort,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(HabitatRoomRole role) => switch (role) {
        HabitatRoomRole.bedroom => AppStrings.habitatRoomRoleBedroom,
        HabitatRoomRole.dining => AppStrings.habitatRoomRoleDining,
        HabitatRoomRole.office => AppStrings.habitatRoomRoleOffice,
        HabitatRoomRole.exterior => AppStrings.habitatRoomRoleExterior,
        HabitatRoomRole.generic => AppStrings.habitatRoomRoleGeneric,
      };

  String _impressLabel(HabitatImpressiveness i) => switch (i) {
        HabitatImpressiveness.mediocre => AppStrings.habitatImpressMediocre,
        HabitatImpressiveness.pleasant => AppStrings.habitatImpressPleasant,
        HabitatImpressiveness.nice => AppStrings.habitatImpressNice,
        HabitatImpressiveness.glorious => AppStrings.habitatImpressGlorious,
      };
}

class _Meter extends StatelessWidget {
  const _Meter({
    required this.label,
    required this.value,
    required this.color,
    this.flash = false,
  });

  final String label;
  final int value;
  final Color color;
  final bool flash;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        width: 52,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: flash ? color : Colors.white54,
                fontSize: 9,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: SizedBox(
                height: 4,
                child: Stack(
                  children: [
                    Container(color: const Color(0x33FFFFFF)),
                    FractionallySizedBox(
                      widthFactor: (value / 100).clamp(0.0, 1.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$value',
              style: TextStyle(
                color: flash ? color : Colors.white70,
                fontSize: 9,
                height: 1,
                fontWeight: flash ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
