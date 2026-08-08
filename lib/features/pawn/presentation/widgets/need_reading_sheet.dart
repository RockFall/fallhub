import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/pawn_controllers.dart';

class NeedReadingSheet extends ConsumerStatefulWidget {
  const NeedReadingSheet({super.key, required this.snapshot});

  final NeedSnapshot snapshot;

  static Future<void> show(BuildContext context, {required NeedSnapshot snapshot}) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => NeedReadingSheet(snapshot: snapshot),
    );
  }

  @override
  ConsumerState<NeedReadingSheet> createState() => _NeedReadingSheetState();
}

class _NeedReadingSheetState extends ConsumerState<NeedReadingSheet> {
  late int _value;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _value = widget.snapshot.normalizedValue == null
        ? 3
        : denormalizeScale5(widget.snapshot.normalizedValue!);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(needReadingControllerProvider.notifier).record(
          needId: widget.snapshot.definition.id,
          scaleValue: _value,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(needReadingControllerProvider).isLoading;

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${AppStrings.recordNeed}: ${widget.snapshot.definition.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.lg),
          Slider(
            value: _value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_value',
            onChanged: (v) => setState(() => _value = v.round()),
          ),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: AppStrings.noteOptional),
          ),
          const SizedBox(height: ColonySpacing.lg),
          FilledButton(
            onPressed: loading ? null : _save,
            child: Text(loading ? AppStrings.loading : AppStrings.save),
          ),
        ],
      ),
    );
  }
}
