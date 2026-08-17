import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../application/research_controllers.dart';
import '../application/research_providers.dart';
import 'widgets/research_prerequisite_picker_sheet.dart';
import 'widgets/research_sessions_panel.dart';
import 'widgets/research_evidence_panel.dart';
import 'widgets/research_linked_quests_panel.dart';
import '../../flashcards/presentation/widgets/research_flashcard_decks_panel.dart';
import '../../flashcards/presentation/widgets/research_knowledge_shelves_panel.dart';

class ResearchNodeDetailScreen extends ConsumerWidget {
  const ResearchNodeDetailScreen({super.key, required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(researchControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading && context.mounted) {
        final error = next.error;
        final message = error is ResearchPrerequisiteException
            ? AppStrings.researchBlockedPrerequisites
            : error is ActiveResearchException
                ? AppStrings.researchWipBlocked
                : error is ResearchEvidenceDeleteException
                    ? AppStrings.researchDeleteEvidenceBlocked
                : error is ResearchDemonstrationException
                    ? AppStrings.researchDemonstrateBlocked
                    : AppStrings.errorGeneric;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });

    final nodeAsync = ref.watch(researchNodeProvider(nodeId));
    final prerequisites = ref.watch(researchPrerequisitesProvider(nodeId));
    final waiting = ref.watch(researchWaitingOnPrerequisitesProvider(nodeId));
    final activity = ref.watch(researchNodeActivityProvider(nodeId));
    final evidenceAsync = ref.watch(researchEvidenceProvider(nodeId));
    final now = ref.watch(clockProvider)();

    return nodeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
      data: (node) {
        if (node == null) {
          return Center(child: Text(AppStrings.researchNotFound));
        }

        final evidence = evidenceAsync.asData?.value ?? const <ResearchEvidence>[];
        final rubric = node.type == ResearchNodeType.skill
            ? SkillRubricPolicy.assess(
                evidenceCount: activity.evidenceCount,
                sessionCount: activity.sessionCount,
                lastEvidenceAt: SkillRubricPolicy.latestEvidenceAt(
                  evidence.map((e) => e.createdAt),
                ),
                now: now,
              )
            : null;

        return ListView(
          padding: const EdgeInsets.all(ColonySpacing.lg),
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/research'),
                ),
                Expanded(
                  child: Text(
                    node.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Chip(label: Text(AppStrings.researchStatusLabel(node.status))),
              ],
            ),
            if (waiting) ...[
              const SizedBox(height: ColonySpacing.sm),
              Chip(
                avatar: const Icon(Icons.hourglass_empty, size: 16),
                label: Text(AppStrings.researchWaitingBadge),
              ),
            ],
            const SizedBox(height: ColonySpacing.sm),
            Wrap(
              spacing: ColonySpacing.sm,
              runSpacing: ColonySpacing.sm,
              children: [
                if (node.status == ResearchNodeStatus.available)
                  FilledButton(
                    onPressed: () => ref
                        .read(researchControllerProvider.notifier)
                        .setInResearch(node),
                    child: const Text(AppStrings.researchStartFocus),
                  ),
                if (node.status == ResearchNodeStatus.inResearch)
                  FilledButton(
                    onPressed: () => _demonstrate(context, ref, node),
                    child: const Text(AppStrings.researchDemonstrate),
                  ),
                if (node.status == ResearchNodeStatus.demonstrated)
                  OutlinedButton(
                    onPressed: () =>
                        ref.read(researchControllerProvider.notifier).archive(node),
                    child: const Text(AppStrings.researchArchive),
                  ),
              ],
            ),
            const SizedBox(height: ColonySpacing.lg),
            ColonyPanel(
              title: AppStrings.researchNodeActivitySummary,
              icon: Icons.timeline_outlined,
              child: Text(
                AppStrings.researchNodeActivitySummaryValue(
                  sessionCount: activity.sessionCount,
                  totalDurationMinutes: activity.totalDurationMinutes,
                  evidenceCount: activity.evidenceCount,
                ),
              ),
            ),
            if (rubric != null) ...[
              const SizedBox(height: ColonySpacing.md),
              ColonyPanel(
                title: AppStrings.researchSkillRubricTitle,
                icon: Icons.school_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.researchSkillRubricLevel(
                        rubric.suggestedLevel,
                      ),
                    ),
                    const SizedBox(height: ColonySpacing.xs),
                    Text(
                      AppStrings.researchSkillRubricHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (rubric.isStale) ...[
                      const SizedBox(height: ColonySpacing.sm),
                      Text(
                        AppStrings.researchSkillRubricStale,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColonyColors.statusAttention,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: ColonySpacing.md),
            ColonyPanel(
              title: AppStrings.researchType,
              icon: Icons.category_outlined,
              child: Text(AppStrings.researchTypeLabel(node.type)),
            ),
            if (node.description != null && node.description!.isNotEmpty) ...[
              const SizedBox(height: ColonySpacing.md),
              ColonyPanel(
                title: AppStrings.researchDescription,
                icon: Icons.notes_outlined,
                child: Text(node.description!),
              ),
            ],
            if (node.demonstratedNote != null &&
                node.demonstratedNote!.isNotEmpty) ...[
              const SizedBox(height: ColonySpacing.md),
              ColonyPanel(
                title: AppStrings.researchDemonstratedNote,
                icon: Icons.check_circle_outline,
                child: Text(node.demonstratedNote!),
              ),
            ],
            const SizedBox(height: ColonySpacing.md),
            ResearchLinkedQuestsPanel(node: node),
            const SizedBox(height: ColonySpacing.md),
            ResearchFlashcardDecksPanel(nodeId: nodeId),
            const SizedBox(height: ColonySpacing.md),
            ResearchKnowledgeShelvesPanel(nodeId: nodeId),
            const SizedBox(height: ColonySpacing.md),
            ResearchSessionsPanel(nodeId: nodeId),
            const SizedBox(height: ColonySpacing.md),
            ResearchEvidencePanel(nodeId: nodeId),
            const SizedBox(height: ColonySpacing.md),
            ColonyPanel(
              title: AppStrings.researchLinkedPrerequisites,
              icon: Icons.account_tree_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  prerequisites.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => Text(AppStrings.errorGeneric),
                    data: (items) {
                      if (items.isEmpty) {
                        return Text(AppStrings.researchNoLinkedPrerequisites);
                      }
                      return Column(
                        children: items
                            .map(
                              (prereq) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(prereq.title),
                                subtitle: Text(
                                  AppStrings.researchStatusLabel(prereq.status),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.link_off),
                                  onPressed: () => ref
                                      .read(researchControllerProvider.notifier)
                                      .unlinkPrerequisite(
                                        nodeId: node.id,
                                        prerequisiteNodeId: prereq.id,
                                      ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: ColonySpacing.sm),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_link, size: 18),
                    label: const Text(AppStrings.researchLinkPrerequisite),
                    onPressed: () => _pickPrerequisites(context, ref, node, prerequisites),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _demonstrate(
    BuildContext context,
    WidgetRef ref,
    ResearchNode node,
  ) async {
    final controller = TextEditingController();
    final note = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.researchDemonstrate),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: AppStrings.researchDemonstratedNoteOptional,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
    if (note == null) return;
    await ref.read(researchControllerProvider.notifier).setDemonstrated(
          node,
          note: note.isEmpty ? null : note,
        );
  }

  Future<void> _pickPrerequisites(
    BuildContext context,
    WidgetRef ref,
    ResearchNode node,
    AsyncValue<List<ResearchNode>> prerequisites,
  ) async {
    final current = prerequisites.asData?.value ?? const <ResearchNode>[];
    final selected = await ResearchPrerequisitePickerSheet.show(
      context,
      nodeId: node.id.value,
      selectedPrerequisiteIds: current.map((p) => p.id).toList(),
    );
    if (selected == null) return;

    final controller = ref.read(researchControllerProvider.notifier);
    final currentIds = current.map((p) => p.id.value).toSet();
    final nextIds = selected.map((id) => id.value).toSet();

    for (final prereq in current) {
      if (!nextIds.contains(prereq.id.value)) {
        await controller.unlinkPrerequisite(
          nodeId: node.id,
          prerequisiteNodeId: prereq.id,
        );
      }
    }
    for (final id in selected) {
      if (!currentIds.contains(id.value)) {
        try {
          await controller.linkPrerequisite(
            nodeId: node.id,
            prerequisiteNodeId: id,
          );
        } on ResearchPrerequisiteException catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message)),
            );
          }
        }
      }
    }
  }
}
