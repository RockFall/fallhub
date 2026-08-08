import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/research_providers.dart';
import 'log_learning_session_sheet.dart';

class ResearchSessionsPanel extends ConsumerWidget {
  const ResearchSessionsPanel({super.key, required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(researchSessionsProvider(nodeId));

    return ColonyPanel(
      title: AppStrings.researchSessions,
      icon: Icons.schedule_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sessionsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text(AppStrings.errorGeneric),
            data: (sessions) {
              if (sessions.isEmpty) {
                return Text(AppStrings.researchNoSessions);
              }
              return Column(
                children: sessions
                    .map(
                      (session) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          AppStrings.researchSessionModeLabel(session.mode),
                        ),
                        subtitle: Text(
                          AppStrings.researchSessionSummary(
                            session.durationMinutes,
                            session.startedAt,
                          ),
                        ),
                        trailing: session.notes != null
                            ? const Icon(Icons.notes, size: 18)
                            : null,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: ColonySpacing.sm),
          OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text(AppStrings.researchLogSession),
            onPressed: () => LogLearningSessionSheet.show(context, nodeId: nodeId),
          ),
        ],
      ),
    );
  }
}
