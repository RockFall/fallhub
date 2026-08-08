import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

import 'package:colony_design_system/colony_design_system.dart';

import 'quest_chain_panel.dart';
import 'quest_linked_decisions_section.dart';
import 'quest_linked_prerequisites_section.dart';
import 'quest_linked_projects_section.dart';
import 'quest_linked_research_section.dart';

class QuestDetailRelationsTab extends StatelessWidget {
  const QuestDetailRelationsTab({
    super.key,
    required this.quest,
    required this.chain,
  });

  final Quest quest;
  final List<QuestChainNode> chain;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        QuestLinkedProjectsSection(quest: quest),
        QuestLinkedResearchSection(quest: quest),
        QuestLinkedPrerequisitesSection(quest: quest),
        QuestChainPanel(chain: chain),
        QuestLinkedDecisionsSection(quest: quest),
      ],
    );
  }
}
