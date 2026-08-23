import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/music_atlas_controllers.dart';

class CaptureMusicEncounterSheet extends ConsumerStatefulWidget {
  const CaptureMusicEncounterSheet({
    super.key,
    this.nodeId,
    this.nowPlaying = false,
  });

  final EntityId? nodeId;
  final bool nowPlaying;

  static Future<void> show(BuildContext context, {required EntityId nodeId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CaptureMusicEncounterSheet(nodeId: nodeId),
    );
  }

  static Future<void> showNowPlaying(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CaptureMusicEncounterSheet(nowPlaying: true),
    );
  }

  @override
  ConsumerState<CaptureMusicEncounterSheet> createState() =>
      _CaptureMusicEncounterSheetState();
}

class _CaptureMusicEncounterSheetState
    extends ConsumerState<CaptureMusicEncounterSheet> {
  final _note = TextEditingController();
  var _type = MusicEncounterType.attentiveListen;
  int? _resonance;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.md,
        ColonySpacing.lg,
        ColonySpacing.lg + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.nowPlaying
                ? AppStrings.musicAtlasNowPlaying
                : AppStrings.musicAtlasCapture,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (!widget.nowPlaying)
            DropdownButton<MusicEncounterType>(
              value: _type,
              isExpanded: true,
              items: [
                for (final type in MusicEncounterType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Text(AppStrings.musicAtlasEncounterLabel(type)),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _type = value);
              },
            ),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: AppStrings.musicAtlasNoteField,
            ),
          ),
          DropdownButton<int?>(
            value: _resonance,
            isExpanded: true,
            hint: const Text(AppStrings.musicAtlasResonance),
            items: [
              for (final value in [-2, -1, 0, 1, 2, 3])
                DropdownMenuItem(value: value, child: Text('$value')),
            ],
            onChanged: (value) => setState(() => _resonance = value),
          ),
          const SizedBox(height: ColonySpacing.md),
          FilledButton(
            onPressed: () async {
              final controller = ref.read(musicAtlasControllerProvider.notifier);
              if (widget.nowPlaying) {
                await controller.captureNowPlaying(
                  resonance: _resonance,
                  note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                );
              } else if (widget.nodeId != null) {
                await controller.recordEncounter(
                  nodeId: widget.nodeId!,
                  type: _type,
                  resonance: _resonance,
                  note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                );
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text(AppStrings.musicAtlasCapture),
          ),
        ],
      ),
    );
  }
}
