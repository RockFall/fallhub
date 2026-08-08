import 'package:colony_design_system/colony_design_system.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../../app/localization/app_strings.dart';

import '../application/work_controllers.dart';

import '../application/work_providers.dart';

import 'widgets/bills_section.dart';

import 'widgets/work_priority_grid.dart';



class WorkScreen extends ConsumerStatefulWidget {

  const WorkScreen({super.key});



  @override

  ConsumerState<WorkScreen> createState() => _WorkScreenState();

}



class _WorkScreenState extends ConsumerState<WorkScreen> {

  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      ref.read(workBootstrapProvider.notifier).ensureSeeded();

    });

  }



  @override

  Widget build(BuildContext context) {

    ref.listen(workPriorityControllerProvider, (previous, next) {

      if (next.hasError && !next.isLoading && context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text(AppStrings.errorGeneric)),

        );

      }

    });



    final bootstrap = ref.watch(workBootstrapProvider);

    final priorities = ref.watch(workPrioritiesProvider);



    if (priorities.isLoading || bootstrap.isLoading) {

      return const Center(child: CircularProgressIndicator());

    }



    if (priorities.hasError || bootstrap.hasError) {

      return Center(child: Text(AppStrings.errorGeneric));

    }



    final items = priorities.requireValue;



    if (items.isEmpty) {

      return Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Text(AppStrings.workPrioritiesEmpty),

            const SizedBox(height: ColonySpacing.md),

            FilledButton(

              onPressed: () =>

                  ref.read(workBootstrapProvider.notifier).ensureSeeded(),

              child: const Text(AppStrings.reload),

            ),

          ],

        ),

      );

    }



    return ListView(

      padding: const EdgeInsets.all(ColonySpacing.lg),

      children: [

        Row(

          children: [

            Expanded(

              child: Text(

                AppStrings.workPriorities,

                style: Theme.of(context).textTheme.titleLarge,

              ),

            ),

            TextButton.icon(

              onPressed: () => context.go('/work/schedule'),

              icon: const Icon(Icons.calendar_today_outlined, size: 18),

              label: const Text(AppStrings.openSchedule),

            ),

          ],

        ),

        const SizedBox(height: ColonySpacing.md),

        ColonyPanel(

          title: AppStrings.workPriorities,

          icon: Icons.grid_on_outlined,

          helpText: AppStrings.workPrioritiesHelp,

          child: WorkPriorityGrid(

            priorities: items,

            onCycle: (priority) => ref

                .read(workPriorityControllerProvider.notifier)

                .cycle(priority),

          ),

        ),

        const SizedBox(height: ColonySpacing.lg),

        const BillsSection(),

      ],

    );

  }

}

