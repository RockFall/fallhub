import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/research_controllers.dart';

class LogLearningSessionSheet extends ConsumerStatefulWidget {
  const LogLearningSessionSheet({super.key, required this.nodeId});

  final String nodeId;

  static Future<void> show(BuildContext context, {required String nodeId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LogLearningSessionSheet(nodeId: nodeId),
    );
  }

  @override
  ConsumerState<LogLearningSessionSheet> createState() =>
      _LogLearningSessionSheetState();
}

class _LogLearningSessionSheetState
    extends ConsumerState<LogLearningSessionSheet> {
  LearningSessionMode _mode = LearningSessionMode.read;
  final _durationController = TextEditingController(text: '30');
  final _notesController = TextEditingController();
  String? _durationError;

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _validate() {
    final minutes = int.tryParse(_durationController.text.trim());
    setState(() {
      _durationError = (minutes == null || minutes <= 0)
          ? AppStrings.researchSessionDurationInvalid
          : null;
    });
    return _durationError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final minutes = int.parse(_durationController.text.trim());
    final notes = _notesController.text.trim();
    final session = await ref.read(researchControllerProvider.notifier).logSession(
          nodeId: EntityId(widget.nodeId),
          startedAt: DateTime.now().toUtc(),
          durationMinutes: minutes,
          mode: _mode,
          notes: notes.isEmpty ? null : notes,
        );

    if (!mounted || session == null) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.researchLogSession,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.md),
          DropdownButtonFormField<LearningSessionMode>(
            value: _mode,
            decoration: const InputDecoration(
              labelText: AppStrings.researchSessionMode,
            ),
            items: LearningSessionMode.values
                .map(
                  (mode) => DropdownMenuItem(
                    value: mode,
                    child: Text(AppStrings.researchSessionModeLabel(mode)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _mode = value);
            },
          ),
          const SizedBox(height: ColonySpacing.sm),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: AppStrings.researchSessionDuration,
              errorText: _durationError,
            ),
          ),
          const SizedBox(height: ColonySpacing.sm),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: AppStrings.researchSessionNotesOptional,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: ColonySpacing.lg),
          FilledButton(
            onPressed: _save,
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}
