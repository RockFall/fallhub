import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/health_connect_settings_launcher.dart';
import '../../application/health_controllers.dart';
import '../../application/health_providers.dart';

class SleepPanel extends ConsumerStatefulWidget {
  const SleepPanel({super.key});

  @override
  ConsumerState<SleepPanel> createState() => _SleepPanelState();
}

class _SleepPanelState extends ConsumerState<SleepPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(healthControllerProvider.notifier).ensureSleepConsents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sleepSessionsProvider);
    final detectionConsent = ref.watch(sleepDetectionConsentProvider);
    final hcConsent = ref.watch(healthConnectSleepConsentProvider);
    final detectionOn = detectionConsent?.enabled ?? false;
    final hcOn = hcConsent?.enabled ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.healthSleepTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: ColonySpacing.xs),
        Text(
          AppStrings.healthSleepHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: ColonySpacing.sm),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(AppStrings.healthSleepDetectionToggle),
          subtitle: Text(
            detectionOn
                ? AppStrings.healthSleepDetectionOn
                : AppStrings.healthSleepDetectionOff,
          ),
          value: detectionOn,
          onChanged: (v) async {
            final ok = await ref
                .read(healthControllerProvider.notifier)
                .setSleepDetectionEnabled(v);
            if (!mounted) return;
            if (!ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.healthSleepDetectionError)),
              );
            }
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(AppStrings.healthSleepHealthConnectToggle),
          subtitle: Text(
            hcOn
                ? AppStrings.healthSleepHealthConnectOn
                : AppStrings.healthSleepHealthConnectOff,
          ),
          value: hcOn,
          onChanged: (v) async {
            final ok = await ref
                .read(healthControllerProvider.notifier)
                .setHealthConnectSleepEnabled(v);
            if (!mounted) return;
            if (!ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppStrings.healthSleepHealthConnectError),
                ),
              );
            }
          },
        ),
        if (hcOn) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                final result = await ref
                    .read(healthControllerProvider.notifier)
                    .syncHealthConnectSleep();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppStrings.healthSleepSyncResult(
                        imported: result.imported,
                        rawPoints: result.rawPoints,
                        message: result.message,
                      ),
                    ),
                    duration: const Duration(seconds: 6),
                  ),
                );
                if (result.isEmpty && mounted) {
                  await _showHcSetupSheet(context);
                }
              },
              icon: const Icon(Icons.sync),
              label: Text(AppStrings.healthSleepSyncNow),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _showHcSetupSheet(context),
              icon: const Icon(Icons.help_outline),
              label: Text(AppStrings.healthSleepHcHowTo),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _runHcDiagnose(context),
              icon: const Icon(Icons.bug_report_outlined),
              label: Text(AppStrings.healthSleepDiagnose),
            ),
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.push('/resources/health/sleep'),
            icon: const Icon(Icons.calendar_view_day_outlined),
            label: Text(AppStrings.healthSleepHistoryOpen),
          ),
        ),
        const SizedBox(height: ColonySpacing.sm),
        sessionsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => Text(AppStrings.errorGeneric),
          data: (sessions) {
            if (sessions.isEmpty) {
              return Text(
                AppStrings.healthSleepEmpty,
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }
            final fmt = DateFormat('dd/MM HH:mm');
            return Column(
              children: [
                for (final s in sessions.take(7))
                  Card(
                    margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
                    child: ListTile(
                      leading: Icon(
                        s.isOpen ? Icons.bedtime : Icons.bedtime_off_outlined,
                      ),
                      title: Text(
                        s.isOpen
                            ? AppStrings.healthSleepInProgress
                            : AppStrings.healthSleepDuration(
                                s.duration ?? Duration.zero,
                              ),
                      ),
                      subtitle: Text(
                        [
                          '${fmt.format(s.startedAt.toLocal())}'
                              '${s.endedAt == null ? '' : ' → ${fmt.format(s.endedAt!.toLocal())}'}',
                          AppStrings.healthSleepSourceLabel(s.source),
                          AppStrings.healthSleepConfidenceLabel(s.confidence),
                        ].join(' · '),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _runHcDiagnose(BuildContext context) async {
    final diag = await HealthConnectSettingsLauncher.diagnoseSleep();
    if (!mounted) return;
    final message = diag == null
        ? 'Não foi possível diagnosticar (só Android).'
        : (diag['message'] as String? ?? diag.toString());
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.healthSleepDiagnose),
        content: SingleChildScrollView(
          child: Text(
            [
              message,
              '',
              'Permissão sono: ${diag?['hasSleepReadPermission']}',
              'Histórico (dados anteriores): ${diag?['hasHistoryPermission']}',
              'Janela efetiva: ${diag?['effectiveDays']} dias',
              'Sessões sono: ${diag?['sleepCount']}',
              'Registros passos: ${diag?['stepsCount']}',
              'Mais antiga: ${_fmtEpoch(diag?['oldestStart'])}',
              'Mais recente: ${_fmtEpoch(diag?['newestEnd'])}',
              'Origens: ${(diag?['origins'] as List?)?.join(', ') ?? '—'}',
            ].join('\n'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await HealthConnectSettingsLauncher.openHealthConnectSettings();
            },
            child: Text(AppStrings.healthSleepOpenHealthConnect),
          ),
        ],
      ),
    );
  }

  String _fmtEpoch(Object? ms) {
    if (ms is! int) return '—';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  Future<void> _showHcSetupSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(ColonySpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.healthSleepHcSetupTitle,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: ColonySpacing.sm),
                Text(
                  AppStrings.healthSleepHcSetupBody,
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: ColonySpacing.md),
                Text(
                  AppStrings.healthSleepHcSetupSteps,
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: ColonySpacing.lg),
                FilledButton.icon(
                  onPressed: () async {
                    await HealthConnectSettingsLauncher.openSamsungHealth();
                  },
                  icon: const Icon(Icons.favorite_outline),
                  label: Text(AppStrings.healthSleepOpenSamsungHealth),
                ),
                const SizedBox(height: ColonySpacing.sm),
                OutlinedButton.icon(
                  onPressed: () async {
                    await HealthConnectSettingsLauncher.openHealthConnectSettings();
                  },
                  icon: const Icon(Icons.health_and_safety_outlined),
                  label: Text(AppStrings.healthSleepOpenHealthConnect),
                ),
                const SizedBox(height: ColonySpacing.sm),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppStrings.cancel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
