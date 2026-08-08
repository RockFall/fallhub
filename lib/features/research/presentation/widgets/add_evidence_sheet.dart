import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/research_controllers.dart';
import '../../application/research_providers.dart';

class AddEvidenceSheet extends ConsumerStatefulWidget {
  const AddEvidenceSheet({super.key, required this.nodeId});

  final String nodeId;

  static Future<void> show(BuildContext context, {required String nodeId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddEvidenceSheet(nodeId: nodeId),
    );
  }

  @override
  ConsumerState<AddEvidenceSheet> createState() => _AddEvidenceSheetState();
}

class _AddEvidenceSheetState extends ConsumerState<AddEvidenceSheet> {
  ResearchEvidenceType _type = ResearchEvidenceType.note;
  String? _sessionId;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _titleError;
  String? _bodyError;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  bool _validate() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    setState(() {
      _titleError = title.isEmpty ? AppStrings.researchEvidenceTitleRequired : null;
      _bodyError = body.isEmpty ? AppStrings.researchEvidenceBodyRequired : null;
    });
    return _titleError == null && _bodyError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final evidence =
        await ref.read(researchControllerProvider.notifier).addEvidence(
              nodeId: EntityId(widget.nodeId),
              type: _type,
              title: _titleController.text.trim(),
              body: _bodyController.text.trim(),
              sessionId:
                  _sessionId == null ? null : EntityId(_sessionId!),
            );

    if (!mounted || evidence == null) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final sessionsAsync = ref.watch(researchSessionsProvider(widget.nodeId));

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
            AppStrings.researchAddEvidence,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.md),
          DropdownButtonFormField<ResearchEvidenceType>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: AppStrings.researchEvidenceType,
            ),
            items: ResearchEvidenceType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(AppStrings.researchEvidenceTypeLabel(type)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _type = value);
            },
          ),
          sessionsAsync.maybeWhen(
            data: (sessions) {
              if (sessions.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: ColonySpacing.sm),
                child: DropdownButtonFormField<String?>(
                  initialValue: _sessionId,
                  decoration: const InputDecoration(
                    labelText: AppStrings.researchEvidenceSessionOptional,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(AppStrings.researchEvidenceNoSession),
                    ),
                    ...sessions.map(
                      (session) => DropdownMenuItem<String?>(
                        value: session.id.value,
                        child: Text(
                          AppStrings.researchSessionSummary(
                            session.durationMinutes,
                            session.startedAt.toLocal(),
                          ),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _sessionId = value),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: ColonySpacing.sm),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: AppStrings.researchEvidenceTitle,
              errorText: _titleError,
            ),
          ),
          const SizedBox(height: ColonySpacing.sm),
          TextField(
            controller: _bodyController,
            decoration: InputDecoration(
              labelText: AppStrings.researchEvidenceBody,
              errorText: _bodyError,
            ),
            maxLines: 4,
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
