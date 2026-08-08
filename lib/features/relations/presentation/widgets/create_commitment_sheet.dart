import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../quests/application/quest_providers.dart';
import '../../application/relations_controllers.dart';

class CreateCommitmentSheet extends ConsumerStatefulWidget {
  const CreateCommitmentSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateCommitmentSheet(),
    );
  }

  @override
  ConsumerState<CreateCommitmentSheet> createState() =>
      _CreateCommitmentSheetState();
}

class _CreateCommitmentSheetState extends ConsumerState<CreateCommitmentSheet> {
  final _descriptionController = TextEditingController();
  final _madeByController = TextEditingController(text: 'eu');
  final _madeToController = TextEditingController();
  final _notesController = TextEditingController();
  EntityId? _linkedQuestId;
  String? _descriptionError;
  String? _madeToError;

  @override
  void dispose() {
    _descriptionController.dispose();
    _madeByController.dispose();
    _madeToController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _validate() {
    final description = _descriptionController.text.trim();
    final madeTo = _madeToController.text.trim();
    setState(() {
      _descriptionError =
          description.isEmpty ? AppStrings.commitmentDescriptionRequired : null;
      _madeToError =
          madeTo.isEmpty ? AppStrings.commitmentMadeToRequired : null;
    });
    return _descriptionError == null && _madeToError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final created =
        await ref.read(relationsControllerProvider.notifier).createCommitment(
              description: _descriptionController.text.trim(),
              madeByLabel: _madeByController.text.trim().isEmpty
                  ? 'eu'
                  : _madeByController.text.trim(),
              madeToLabel: _madeToController.text.trim(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              linkedQuestId: _linkedQuestId,
            );
    if (!mounted || created == null) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final questsAsync = ref.watch(questsProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.commitmentNew,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: AppStrings.commitmentDescription,
                errorText: _descriptionError,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _madeByController,
              decoration: const InputDecoration(
                labelText: AppStrings.commitmentMadeBy,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _madeToController,
              decoration: InputDecoration(
                labelText: AppStrings.commitmentMadeToLabel,
                errorText: _madeToError,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: AppStrings.commitmentNotesOptional,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            questsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(AppStrings.errorGeneric),
              data: (quests) {
                final linkable = quests
                    .where((q) => !q.status.isTerminal)
                    .toList();
                return DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: _linkedQuestId?.value,
                  decoration: const InputDecoration(
                    labelText: AppStrings.commitmentLinkedQuest,
                    helperText: AppStrings.commitmentLinkedQuestHint,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(AppStrings.commitmentNoQuestLink),
                    ),
                    ...linkable.map(
                      (q) => DropdownMenuItem<String?>(
                        value: q.id.value,
                        child: Text(q.title),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    _linkedQuestId = v == null ? null : EntityId(v);
                  }),
                );
              },
            ),
            const SizedBox(height: ColonySpacing.lg),
            FilledButton(
              onPressed: _save,
              child: Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }
}
