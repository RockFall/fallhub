import 'package:colony_design_system/colony_design_system.dart';

import 'package:colony_domain/colony_domain.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';



import '../../../../app/localization/app_strings.dart';



class QuestChainPanel extends StatelessWidget {

  const QuestChainPanel({

    super.key,

    required this.chain,

  });



  final List<QuestChainNode> chain;



  @override

  Widget build(BuildContext context) {

    if (chain.length < 2) return const SizedBox.shrink();



    return Padding(

      padding: const EdgeInsets.only(top: ColonySpacing.md),

      child: ColonyPanel(

        title: AppStrings.questChainTitle,

        icon: Icons.account_tree_outlined,

        child: Column(

          children: chain.map((node) {

            final quest = node.quest;

            return ListTile(

              contentPadding: EdgeInsets.zero,

              leading: node.isCurrent

                  ? Icon(

                      Icons.flag,

                      color: Theme.of(context).colorScheme.primary,

                    )

                  : const Icon(Icons.circle_outlined, size: 12),

              title: Text(

                quest.title,

                style: node.isCurrent

                    ? Theme.of(context).textTheme.titleMedium?.copyWith(

                          fontWeight: FontWeight.w600,

                        )

                    : null,

              ),

              subtitle: quest.purpose.isNotEmpty ? Text(quest.purpose, maxLines: 1) : null,

              trailing: Chip(

                label: Text(

                  AppStrings.questStatusLabel(quest.status),

                  style: Theme.of(context).textTheme.labelSmall,

                ),

                visualDensity: VisualDensity.compact,

              ),

              onTap: node.isCurrent

                  ? null

                  : () => context.go('/quests/${quest.id.value}'),

            );

          }).toList(),

        ),

      ),

    );

  }

}


