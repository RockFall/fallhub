import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../quests/application/quest_providers.dart';
import '../../application/relations_controllers.dart';

class EditCommitmentSheet extends ConsumerStatefulWidget {
  const EditCommitmentSheet({super.key, required this.commitment});

  final Commitment commitment;

  static Future<void> show(BuildContext context, Commitment commitment) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditCommitmentSheet(commitment: commitment),
    );
  }

  @override
  ConsumerState<EditCommitmentSheet> createState() =>
      _EditCommitmentSheetState();
}

class _EditCommitmentSheetState extends ConsumerState<EditCommitmentSheet> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _madeByController;
  late final TextEditingController _madeToController;
  late final TextEditingController _notesController;
  late CommitmentStatus _status;
  EntityId? _linkedQuestId;
  String? _descriptionError;
  String? _madeToError;

  @override
  void initState() {
    super.initState();
    final c = widget.commitment;
    _descriptionController = TextEditingController(text: c.description);
    _madeByController = TextEditingController(text: c.madeByLabel);
    _madeToController = TextEditingController(text: c.madeToLabel ?? '');
    _notesController = TextEditingController(text: c.notes ?? '');
    _status = c.status;
    _linkedQuestId = c.linkedQuestId;
  }

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
    final hasCounterpart = madeTo.isNotEmpty ||
        widget.commitment.madeToPersonId != null ||
        widget.commitment.madeToOrganizationId != null;
    setState(() {
      _descriptionError =
          description.isEmpty ? AppStrings.commitmentDescriptionRequired : null;
      _madeToError =
          hasCounterpart ? null : AppStrings.commitmentMadeToRequired;
    });
    return _descriptionError == null && _madeToError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final madeToRaw = _madeToController.text.trim();
    final base = widget.commitment.copyWith(
      description: _descriptionController.text.trim(),
      madeByLabel: _madeByController.text.trim().isEmpty
          ? 'eu'
          : _madeByController.text.trim(),
      madeToLabel: madeToRaw.isEmpty ? null : madeToRaw,
      clearMadeToLabel: madeToRaw.isEmpty,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      clearNotes: _notesController.text.trim().isEmpty,
      status: _status,
      linkedQuestId: _linkedQuestId,
      clearLinkedQuestId: _linkedQuestId == null,
    );
    final saved =
        await ref.read(relationsControllerProvider.notifier).saveCommitment(base);
    if (!mounted || saved == null) return;
    Navigator.pop(context);
  }

  Future<void> _setStatus(CommitmentStatus status) async {
    final updated = await ref
        .read(relationsControllerProvider.notifier)
        .setCommitmentStatus(widget.commitment, status);
    if (!mounted || updated == null) return;
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
              AppStrings.commitmentEdit,
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
            DropdownButtonFormField<CommitmentStatus>(
              // ignore: deprecated_member_use
              value: _status,
              decoration: const InputDecoration(
                labelText: AppStrings.commitmentStatus,
              ),
              items: CommitmentStatus.values
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(AppStrings.commitmentStatusLabel(s)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
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
            const SizedBox(height: ColonySpacing.sm),
            Wrap(
              spacing: ColonySpacing.sm,
              children: [
                TextButton(
                  onPressed: () => _setStatus(CommitmentStatus.kept),
                  child: Text(AppStrings.commitmentMarkKept),
                ),
                TextButton(
                  onPressed: () => _setStatus(CommitmentStatus.broken),
                  child: Text(AppStrings.commitmentMarkBroken),
                ),
                TextButton(
                  onPressed: () => _setStatus(CommitmentStatus.cancelled),
                  child: Text(AppStrings.commitmentMarkCancelled),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
