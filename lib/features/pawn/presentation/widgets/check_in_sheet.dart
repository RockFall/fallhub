import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/pawn_controllers.dart';
import 'package:colony_domain/colony_domain.dart';

class CheckInSheet extends ConsumerStatefulWidget {
  const CheckInSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CheckInSheet(),
    );
  }

  @override
  ConsumerState<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends ConsumerState<CheckInSheet> {
  var _mood = 3;
  var _energy = 3;
  var _tension = 3;
  var _focus = 3;
  final _noteController = TextEditingController();
  final _selectedFactors = <String>{};

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(checkInControllerProvider.notifier).submit(
          mood: _mood,
          energy: _energy,
          tension: _tension,
          focus: _focus,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          selectedFactors: _selectedFactors.toList(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(checkInControllerProvider).isLoading;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg,
        bottom + ColonySpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.checkIn, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: ColonySpacing.lg),
            _ScaleRow(label: AppStrings.mood, value: _mood, onChanged: (v) => setState(() => _mood = v)),
            _ScaleRow(label: AppStrings.energy, value: _energy, onChanged: (v) => setState(() => _energy = v)),
            _ScaleRow(label: AppStrings.tension, value: _tension, onChanged: (v) => setState(() => _tension = v)),
            _ScaleRow(label: AppStrings.focus, value: _focus, onChanged: (v) => setState(() => _focus = v)),
            const SizedBox(height: ColonySpacing.md),
            Text(AppStrings.moodFactors, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: ColonySpacing.sm),
            Wrap(
              spacing: ColonySpacing.sm,
              children: SuggestedMoodFactors.labels
                  .map(
                    (label) => FilterChip(
                      label: Text(label),
                      selected: _selectedFactors.contains(label),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedFactors.add(label);
                          } else {
                            _selectedFactors.remove(label);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(labelText: AppStrings.noteOptional),
              maxLines: 2,
            ),
            const SizedBox(height: ColonySpacing.lg),
            FilledButton(
              onPressed: loading ? null : _submit,
              child: Text(loading ? AppStrings.loading : AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleRow extends StatelessWidget {
  const _ScaleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label)),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$value',
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Text('$value'),
        ],
      ),
    );
  }
}
