import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';
import '../../flame/components/living_pawn_component.dart';
import '../../flame/habitat_game.dart';
import '../../simulation/content/habitat_devices.dart';
import '../../simulation/content/habitat_inventory.dart';
import '../../simulation/debug/state_explain.dart';
import '../../simulation/embodied/embodied.dart';

/// Minimal selection readout when no pawn STATE panel is shown.
class HabitatInspectHud extends StatelessWidget {
  const HabitatInspectHud({super.key, required this.selection});

  final HabitatSelection? selection;

  String? get _line {
    return switch (selection) {
      null => null,
      HabitatPawnSelection() => null, // STATE panel owns pawn inspect
      HabitatPropSelection(:final prop) => prop.name,
      HabitatCellSelection(:final cell) =>
        '${AppStrings.habitatInspectCell} ${cell.$1},${cell.$2}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final line = _line;
    if (line == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Text(
            line,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Color(0xCC000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dockable pawn STATE inspect with provenance / explain (MD 08 M4).
class HabitatStateInspectPane extends StatefulWidget {
  const HabitatStateInspectPane({
    super.key,
    required this.game,
    required this.pawn,
  });

  final HabitatGame game;
  final LivingPawnComponent pawn;

  @override
  State<HabitatStateInspectPane> createState() =>
      _HabitatStateInspectPaneState();
}

class _HabitatStateInspectPaneState extends State<HabitatStateInspectPane> {
  _StateTab _tab = _StateTab.needs;
  String? _expandedKey;
  bool _deepExplain = false;

  PawnEmbodiedState get _state =>
      widget.game.ensureEmbodied(widget.pawn.memberId);

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final job = widget.pawn.jobs.statusLabel;

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 72, 10, 96),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280, maxHeight: 420),
          child: Material(
            color: const Color(0xE0141416),
            borderRadius: BorderRadius.circular(4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0x66FFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.pawn.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${AppStrings.habitatStateJob}: $job',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 11,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (kDebugMode)
                          IconButton(
                            tooltip: AppStrings.habitatStateExplain,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () =>
                                setState(() => _deepExplain = !_deepExplain),
                            icon: Icon(
                              _deepExplain
                                  ? Icons.info
                                  : Icons.info_outline,
                              size: 18,
                              color: Colors.white.withValues(
                                alpha: _deepExplain ? 1 : 0.55,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _TabRow(
                    current: _tab,
                    onChanged: (t) => setState(() {
                      _tab = t;
                      _expandedKey = null;
                    }),
                  ),
                  const Divider(height: 1, color: Color(0x33FFFFFF)),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: _buildTabBody(state),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBody(PawnEmbodiedState state) {
    return switch (_tab) {
      _StateTab.needs => _needsBody(state),
      _StateTab.capacities => _capacitiesBody(state),
      _StateTab.conditions => _conditionsBody(state),
      _StateTab.signals => _signalsBody(),
      _StateTab.context => _contextBody(state),
    };
  }

  Widget _needsBody(PawnEmbodiedState state) {
    final entries = state.needs.values.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final n in entries)
          _ExplainRow(
            title: StateExplain.needLine(n),
            detail: StateExplain.needExplain(n),
            meter: n.pressure,
            showDetail: _deepExplain || _expandedKey == 'need.${n.kind.name}',
            onTap: () => setState(() {
              final id = 'need.${n.kind.name}';
              _expandedKey = _expandedKey == id ? null : id;
            }),
          ),
      ],
    );
  }

  Widget _capacitiesBody(PawnEmbodiedState state) {
    final entries = state.capacities.values.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in entries)
          _ExplainRow(
            title: StateExplain.capacityLine(c),
            detail: StateExplain.capacityExplain(c),
            meter: c.level,
            showDetail: _deepExplain || _expandedKey == 'cap.${c.kind.name}',
            onTap: () => setState(() {
              final id = 'cap.${c.kind.name}';
              _expandedKey = _expandedKey == id ? null : id;
            }),
          ),
      ],
    );
  }

  Widget _conditionsBody(PawnEmbodiedState state) {
    if (state.conditions.isEmpty) {
      return Text(
        '—',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in state.conditions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              StateExplain.conditionLine(c),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'Circadian alertness: '
          '${state.circadian.alertness.toStringAsFixed(2)} · '
          '${state.circadian.source.name}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _signalsBody() {
    final indoor = widget.game.indoorTemperatureEffective?.winningSignal ??
        widget.game.indoorTemperatureSignal;
    final eff = widget.game.indoorTemperatureEffective;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (indoor != null) ...[
          Text(
            StateExplain.signalLine(indoor),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              height: 1.35,
              fontFamily: 'monospace',
            ),
          ),
          if (eff != null) ...[
            const SizedBox(height: 8),
            Text(
              eff.explanation,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
                height: 1.35,
              ),
            ),
            if (eff.hasConflict)
              Text(
                'conflict',
                style: TextStyle(
                  color: Colors.orange.shade200,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ] else
          Text(
            '—',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
          ),
      ],
    );
  }

  Widget _contextBody(PawnEmbodiedState state) {
    final p = state.presence;
    final clocks = widget.game.clockDebugLine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv('Sleep', state.sleepPhase.name),
        _kv('Sedentary', '${state.movement.sedentarySeconds.round()}s'),
        _kv('Fatigue', state.movement.physicalFatigue.toStringAsFixed(2)),
        _kv(
          'Style',
          widget.game.embodiedRuntime.profileFor(widget.pawn.memberId).socialStyle.name,
        ),
        _kv(
          'Jazz',
          (widget.game.embodiedRuntime.preferences
                      .effectiveAffinity(widget.pawn.memberId, 'music/jazz') ??
                  0)
              .toStringAsFixed(2),
        ),
        _kv(
          'Kind',
          widget.game.embodiedRuntime.identity
                  .ensure(widget.pawn.memberId)
                  .kind
                  .name,
        ),
        _kv(
          'Presence',
          widget.game.embodiedRuntime.visitors.status[widget.pawn.memberId]
                  ?.state
                  .name ??
              '—',
        ),
        _kv(
          'Media',
          widget.game.embodiedRuntime.media
                  .byId(
                    widget.game.embodiedRuntime.media
                            .activeByPawn[widget.pawn.memberId] ??
                        '',
                  )
                  ?.title ??
              '—',
        ),
        if (widget.game.embodiedRuntime.lastSocialTopic != null)
          _kv('Topic', widget.game.embodiedRuntime.lastSocialTopic!.id),
        if (widget.game.embodiedRuntime.appointments.upcoming(
          widget.game.clocks.simulation.elapsedSeconds,
        ).isNotEmpty)
          _kv(
            'Appt',
            widget.game.embodiedRuntime.appointments
                .upcoming(widget.game.clocks.simulation.elapsedSeconds)
                .first
                .title,
          ),
        _kv(
          'Site',
          widget.game.embodiedRuntime.world
                  .siteForMapLocation(widget.game.locationId)
                  ?.name ??
              '—',
        ),
        _kv(
          'Ctx',
          widget.game.embodiedRuntime.activeContext.id.replaceFirst(
            'profile.',
            '',
          ),
        ),
        _kv(
          'Loc',
          widget.game.embodiedRuntime.transit.locationState[widget.pawn.memberId]
                  ?.name ??
              '—',
        ),
        if (widget.game.embodiedRuntime.calls.isOnCall)
          _kv(
            'Call',
            widget.game.embodiedRuntime.calls.active?.remote.displayName ?? '—',
          ),
        Builder(
          builder: (_) {
            final fit = widget.game.perceivedComfortFor(widget.pawn.memberId);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv(
                  'ObjComfort',
                  (fit.objective * 100).round().toString(),
                ),
                _kv(
                  'Perceived',
                  '${(fit.perceived * 100).round()} (Δ${fit.delta >= 0 ? '+' : ''}${(fit.delta * 100).round()})',
                ),
              ],
            );
          },
        ),
        _kv(
          'Preset',
          widget.game.embodiedRuntime.scenes.activePresetId ?? '—',
        ),
        _kv(
          'Loadout',
          widget.game.embodiedRuntime.loadouts
                  .currentByPawn[widget.pawn.memberId] ??
              widget.pawn.appearance.loadoutId,
        ),
        Builder(
          builder: (_) {
            final held = widget.game.embodiedRuntime.inventory.items.values
                .where(
                  (it) =>
                      it.location.kind == HabitatItemLocationKind.heldByPawn &&
                      it.location.pawnId == widget.pawn.memberId,
                )
                .map((it) => it.label)
                .join(', ');
            if (held.isEmpty) return const SizedBox.shrink();
            return _kv('Held', held);
          },
        ),
        Builder(
          builder: (_) {
            final act = widget.game.embodiedRuntime.devices.activities.values
                .where((a) => a.pawnId == widget.pawn.memberId)
                .where(
                  (a) =>
                      a.phase == SustainedActivityPhase.active ||
                      a.phase == SustainedActivityPhase.resumable,
                )
                .firstOrNull;
            if (act == null) return const SizedBox.shrink();
            return _kv('Focus', '${act.kind} (${act.phase.name})');
          },
        ),
        Builder(
          builder: (_) {
            final run = widget.game.embodiedRuntime.routines
                .runsByPawn[widget.pawn.memberId];
            if (run == null) return const SizedBox.shrink();
            return _kv(
              'Routine',
              '${run.definitionId}@${run.currentNodeId} (${run.status.name})',
            );
          },
        ),
        _kv('Room map', p.siteId),
        _kv('Room', p.roomRole),
        _kv('Home', p.isHome ? 'yes' : 'no'),
        _kv('Facing', widget.pawn.facing.name),
        _kv('Attention', widget.pawn.micro.attention.debugLabel),
        _kv('Arrival', widget.pawn.micro.arrival.state.phase.name),
        _kv('Posture', widget.pawn.micro.posture.state.phase.name),
        _kv(
          'Locomotor',
          '${widget.pawn.micro.locomotor.speedMultiplier.toStringAsFixed(2)}x',
        ),
        Builder(
          builder: (_) {
            final idle = widget.pawn.micro.microIdle.active;
            if (idle == null) return const SizedBox.shrink();
            return _kv('MicroIdle', idle.presentation.kind.name);
          },
        ),
        Builder(
          builder: (_) {
            final slot = widget.pawn.jobs.lastSlotDebug;
            if (slot == null) return const SizedBox.shrink();
            return _kv('Slot', slot);
          },
        ),
        Builder(
          builder: (_) {
            final pref = widget.pawn.jobs.routePreference?.profile.name;
            if (pref == null) return const SizedBox.shrink();
            return _kv('Route', pref);
          },
        ),
        _kv('Cell', '${widget.pawn.cellX},${widget.pawn.cellY}'),
        if (widget.game.episodes.openOfKind('sleep').isNotEmpty ||
            widget.game.episodes.openOfKind('nap').isNotEmpty)
          _kv('Episode', 'sleep open'),
        const SizedBox(height: 8),
        Text(
          clocks,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
            height: 1.3,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
          children: [
            TextSpan(
              text: '$k  ',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
            TextSpan(text: v),
          ],
        ),
      ),
    );
  }
}

enum _StateTab { needs, capacities, conditions, signals, context }

class _TabRow extends StatelessWidget {
  const _TabRow({required this.current, required this.onChanged});

  final _StateTab current;
  final ValueChanged<_StateTab> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(_StateTab tab, String label) {
      final on = tab == current;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(tab),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: on ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: on ? 1 : 0.45),
                fontSize: 10,
                fontWeight: on ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(_StateTab.needs, AppStrings.habitatStateNeeds),
        chip(_StateTab.capacities, AppStrings.habitatStateCapacities),
        chip(_StateTab.conditions, AppStrings.habitatStateConditions),
        chip(_StateTab.signals, AppStrings.habitatStateSignals),
        chip(_StateTab.context, AppStrings.habitatStateContext),
      ],
    );
  }
}

class _ExplainRow extends StatelessWidget {
  const _ExplainRow({
    required this.title,
    required this.detail,
    required this.meter,
    required this.showDetail,
    required this.onTap,
  });

  final String title;
  final String detail;
  final double meter;
  final bool showDetail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = meter.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: m,
                minHeight: 3,
                backgroundColor: const Color(0x33FFFFFF),
                color: Color.lerp(
                  const Color(0xFF6B8CAE),
                  const Color(0xFFE8C07A),
                  m,
                ),
              ),
            ),
            if (showDetail) ...[
              const SizedBox(height: 6),
              Text(
                detail,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  height: 1.35,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
