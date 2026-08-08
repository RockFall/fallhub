import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/research_controllers.dart';
import '../../application/research_providers.dart';
import 'add_evidence_sheet.dart';

class ResearchEvidencePanel extends ConsumerWidget {
  const ResearchEvidencePanel({super.key, required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeAsync = ref.watch(researchNodeProvider(nodeId));
    final evidenceAsync = ref.watch(researchEvidenceProvider(nodeId));
    final nodeStatus = nodeAsync.asData?.value?.status;

    return ColonyPanel(
      title: AppStrings.researchEvidence,
      icon: Icons.fact_check_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          evidenceAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text(AppStrings.errorGeneric),
            data: (items) {
              if (items.isEmpty) {
                return Text(AppStrings.researchNoEvidence);
              }
              return Column(
                children: items
                    .map(
                      (item) {
                        final canDelete = nodeStatus == null ||
                            ResearchDemonstrationPolicy.canDeleteEvidence(
                              nodeStatus: nodeStatus,
                              evidenceCount: items.length,
                            );
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.title),
                          subtitle: Text(
                            '${AppStrings.researchEvidenceTypeLabel(item.type)}\n${item.body}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: canDelete
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => ref
                                      .read(researchControllerProvider.notifier)
                                      .deleteEvidence(
                                        nodeId: item.nodeId,
                                        evidenceId: item.id,
                                      ),
                                )
                              : null,
                        );
                      },
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: ColonySpacing.sm),
          OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text(AppStrings.researchAddEvidence),
            onPressed: () => AddEvidenceSheet.show(context, nodeId: nodeId),
          ),
        ],
      ),
    );
  }
}
