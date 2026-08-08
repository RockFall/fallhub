import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/feature_controllers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _colonyController = TextEditingController(text: 'Minha Colônia');
  final _nameController = TextEditingController();
  final _sectors = <String>{
    'trabalho',
    'universidade',
    'finanças',
    'saúde',
  };

  @override
  void dispose() {
    _colonyController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(onboardingControllerProvider.notifier).complete(
          colonyName: _colonyController.text,
          displayName: _nameController.text,
          sectors: _sectors.toList(),
        );
    if (mounted) context.go('/colony');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ColonySpacing.xl),
            child: ColonyPanel(
              title: AppStrings.onboardingTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(AppStrings.onboardingSubtitle),
                  const SizedBox(height: ColonySpacing.lg),
                  TextField(
                    controller: _colonyController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.colonyName,
                    ),
                  ),
                  const SizedBox(height: ColonySpacing.md),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.pawnName,
                    ),
                  ),
                  const SizedBox(height: ColonySpacing.lg),
                  Text(AppStrings.sectorsTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: ColonySpacing.sm),
                  Wrap(
                    spacing: ColonySpacing.sm,
                    children: [
                      'saúde',
                      'finanças',
                      'trabalho',
                      'universidade',
                      'projetos',
                      'aprendizado',
                      'música',
                      'relações',
                      'casa',
                      'viagens',
                    ]
                        .map(
                          (sector) => FilterChip(
                            label: Text(sector),
                            selected: _sectors.contains(sector),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _sectors.add(sector);
                                } else {
                                  _sectors.remove(sector);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: ColonySpacing.xl),
                  FilledButton(
                    onPressed: state.isLoading ? null : _submit,
                    child: Text(
                      state.isLoading
                          ? AppStrings.loading
                          : AppStrings.startColony,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}