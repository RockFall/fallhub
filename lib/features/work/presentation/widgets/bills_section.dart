import 'package:colony_design_system/colony_design_system.dart';

import 'package:colony_domain/colony_domain.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../../../app/localization/app_strings.dart';

import '../../application/work_controllers.dart';

import '../../application/work_providers.dart';



class BillsSection extends ConsumerStatefulWidget {

  const BillsSection({super.key});



  @override

  ConsumerState<BillsSection> createState() => _BillsSectionState();

}



class _BillsSectionState extends ConsumerState<BillsSection> {

  @override

  Widget build(BuildContext context) {

    ref.listen(billControllerProvider, (previous, next) {

      if (next.hasError && !next.isLoading && context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text(AppStrings.errorGeneric)),

        );

      }

    });



    final bills = ref.watch(billsProvider);



    return ColonyPanel(

      title: AppStrings.bills,

      icon: Icons.receipt_long_outlined,

      actions: [

        IconButton(

          tooltip: AppStrings.addBill,

          icon: const Icon(Icons.add, size: 20),

          onPressed: () => _showCreateBill(context, ref),

        ),

      ],

      child: bills.when(

        loading: () => const Center(child: CircularProgressIndicator()),

        error: (_, __) => Text(AppStrings.errorGeneric),

        data: (items) {

          if (items.isEmpty) {

            return Text(

              AppStrings.billsEmpty,

              style: Theme.of(context).textTheme.bodyMedium,

            );

          }

          return Column(

            children: items

                .map(

                  (bill) => ListTile(

                    contentPadding: EdgeInsets.zero,

                    title: Text(bill.title),

                    subtitle: Text(

                      '${AppStrings.billRepeatModeLabel(bill.repeatMode)} · ${AppStrings.billTarget}: ${bill.target}',

                    ),

                    dense: true,

                  ),

                )

                .toList(),

          );

        },

      ),

    );

  }



  Future<void> _showCreateBill(BuildContext context, WidgetRef ref) async {

    final titleController = TextEditingController();

    var repeatMode = BillRepeatMode.fixed;

    final targetController = TextEditingController(text: '1');



    final saved = await showDialog<bool>(

      context: context,

      builder: (context) => StatefulBuilder(

        builder: (context, setState) => AlertDialog(

          title: const Text(AppStrings.addBill),

          content: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              TextField(

                controller: titleController,

                decoration: const InputDecoration(labelText: AppStrings.billTitle),

                autofocus: true,

              ),

              const SizedBox(height: ColonySpacing.md),

              DropdownButtonFormField<BillRepeatMode>(

                value: repeatMode,

                decoration: const InputDecoration(labelText: AppStrings.billRepeatMode),

                items: BillRepeatMode.values

                    .map(

                      (m) => DropdownMenuItem(

                        value: m,

                        child: Text(AppStrings.billRepeatModeLabel(m)),

                      ),

                    )

                    .toList(),

                onChanged: (v) {

                  if (v != null) setState(() => repeatMode = v);

                },

              ),

              const SizedBox(height: ColonySpacing.md),

              TextField(

                controller: targetController,

                decoration: const InputDecoration(labelText: AppStrings.billTarget),

              ),

            ],

          ),

          actions: [

            TextButton(

              onPressed: () => Navigator.pop(context, false),

              child: const Text(AppStrings.cancel),

            ),

            FilledButton(

              onPressed: () => Navigator.pop(context, true),

              child: const Text(AppStrings.save),

            ),

          ],

        ),

      ),

    );



    if (saved == true && titleController.text.trim().isNotEmpty) {

      await ref.read(billControllerProvider.notifier).create(

            title: titleController.text.trim(),

            repeatMode: repeatMode,

            target: targetController.text.trim(),

          );

    }



    titleController.dispose();

    targetController.dispose();

  }

}

