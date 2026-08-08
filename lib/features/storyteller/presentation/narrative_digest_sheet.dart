import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../chronicle/presentation/chronicle_screen.dart';
import '../application/storyteller_providers.dart';

Future<void> showNarrativeDigestSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const NarrativeDigestSheet(),
  );
}

class NarrativeDigestSheet extends ConsumerWidget {
  const NarrativeDigestSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digestAsync = ref.watch(weeklyNarrativeDigestProvider);

    return Semantics(
      container: true,
      identifier: 'narrative_digest.sheet',
      label: AppStrings.narrativeDigestTitle,
      child: Padding(
        padding: const EdgeInsets.all(ColonySpacing.lg),
        child: digestAsync.when(
          loading: () => const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Text(AppStrings.errorGeneric),
          data: (digest) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.narrativeDigestTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: ColonySpacing.sm),
              Semantics(
                identifier: 'narrative_digest.disclaimer',
                label: AppStrings.narrativeDigestDisclaimer,
                child: Text(
                  AppStrings.narrativeDigestDisclaimer,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: ColonySpacing.md),
              Text(
                AppStrings.narrativeDigestGenerator(digest.generator),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: ColonySpacing.xs),
              Text(
                AppStrings.narrativeDigestPeriod(
                  digest.periodStart,
                  digest.periodEnd,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: ColonySpacing.md),
              Text(
                AppStrings.narrativeDigestSignals,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: ColonySpacing.sm),
              Wrap(
                spacing: ColonySpacing.sm,
                runSpacing: ColonySpacing.xs,
                children: [
                  for (final b in digest.bullets)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        AppStrings.narrativeDigestSignalChip(b.templateId),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: ColonySpacing.md),
              ...digest.bullets.map(
                (b) {
                  final hasEvidence = b.evidenceEventIds.isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
                    child: Semantics(
                      button: hasEvidence,
                      label: hasEvidence
                          ? AppStrings.narrativeDigestEvidenceAction(
                              b.evidenceEventIds.length,
                            )
                          : AppStrings.narrativeDigestBullet(b),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.auto_stories_outlined),
                        title: Text(AppStrings.narrativeDigestBullet(b)),
                        subtitle: hasEvidence
                            ? Text(
                                AppStrings.narrativeDigestEvidence(
                                  b.evidenceEventIds.length,
                                ),
                              )
                            : null,
                        trailing: hasEvidence
                            ? const Icon(Icons.open_in_new, size: 18)
                            : null,
                        onTap: hasEvidence
                            ? () {
                                final location =
                                    ChronicleScreen.chronicleEvidenceLocation(
                                  evidenceEventIds: b.evidenceEventIds,
                                );
                                Navigator.of(context).pop();
                                context.go(location);
                              }
                            : null,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: ColonySpacing.md),
              Semantics(
                button: true,
                label: AppStrings.close,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(AppStrings.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
