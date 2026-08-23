import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../music_atlas/presentation/widgets/spotify_integration_panel.dart';
import '../application/integrations_controllers.dart';
import '../application/integrations_providers.dart';

class IntegrationsScreen extends ConsumerStatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  ConsumerState<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends ConsumerState<IntegrationsScreen>
    with WidgetsBindingObserver {
  bool _androidListenerEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(integrationsControllerProvider.notifier);
      controller.ensureCalendarConsent();
      controller.ensureNotificationConsent();
      _refreshAndroidPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAndroidPermission();
      ref.read(integrationsControllerProvider.notifier).syncNotificationIngest();
    }
  }

  Future<void> _refreshAndroidPermission() async {
    final enabled = await ref
        .read(integrationsControllerProvider.notifier)
        .isAndroidListenerEnabled();
    if (!mounted) return;
    setState(() => _androidListenerEnabled = enabled);
  }

  Future<void> _importIcs() async {
    final consent = ref.read(calendarIcsConsentProvider);
    if (consent == null || !consent.enabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.integrationsNeedConsent)),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['ics'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.integrationsIcsReadError)),
      );
      return;
    }
    final source = String.fromCharCodes(bytes);
    await _previewAndConfirm(source);
  }

  Future<void> _pasteIcs() async {
    final consent = ref.read(calendarIcsConsentProvider);
    if (consent == null || !consent.enabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.integrationsNeedConsent)),
      );
      return;
    }
    final controller = TextEditingController();
    final source = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.integrationsPasteIcs),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: AppStrings.integrationsPasteHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text(AppStrings.integrationsPreview),
          ),
        ],
      ),
    );
    if (source == null || source.trim().isEmpty) return;
    await _previewAndConfirm(source);
  }

  Future<void> _previewAndConfirm(String source) async {
    final List<IcsEventPreview> previews;
    try {
      previews =
          ref.read(integrationsControllerProvider.notifier).previewIcs(source);
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.integrationsIcsParseError}: $e')),
      );
      return;
    }

    if (!mounted) return;
    var alsoSchedule = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(AppStrings.integrationsPreviewCount(previews.length)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: previews.length.clamp(0, 20),
                    itemBuilder: (_, i) {
                      final e = previews[i];
                      return ListTile(
                        dense: true,
                        title: Text(e.summary),
                        subtitle: Text(
                          '${e.startAt.toUtc().toIso8601String()} → ${e.endAt.toUtc().toIso8601String()}',
                        ),
                      );
                    },
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppStrings.integrationsAlsoSchedule),
                  subtitle: Text(AppStrings.integrationsAlsoScheduleHint),
                  value: alsoSchedule,
                  onChanged: (v) =>
                      setLocal(() => alsoSchedule = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(AppStrings.integrationsConfirmImport),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    final count = await ref
        .read(integrationsControllerProvider.notifier)
        .confirmIcsImport(
          previews,
          alsoCreateScheduleBlocks: alsoSchedule,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count > 0
              ? AppStrings.integrationsImportDone(count)
              : AppStrings.errorGeneric,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final icsConsent = ref.watch(calendarIcsConsentProvider);
    final notifConsent = ref.watch(notificationListenerConsentProvider);
    final eventsAsync = ref.watch(externalCalendarEventsProvider);
    final capturesAsync = ref.watch(capturedNotificationsProvider);
    final busy = ref.watch(integrationsControllerProvider).isLoading;
    final platform = ref.watch(notificationCapturePlatformProvider);
    final appOn = notifConsent?.enabled == true;
    final androidOn = _androidListenerEnabled;
    final ready = appOn && androidOn;

    return Semantics(
      container: true,
      identifier: 'integrations.screen',
      label: AppStrings.integrationsTitle,
      child: ListView(
        padding: const EdgeInsets.all(ColonySpacing.lg),
        children: [
          Text(
            AppStrings.integrationsTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.integrationsDisclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.lg),
          ColonyPanel(
            title: AppStrings.integrationsNotificationsTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.integrationsNotificationsWarning,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: ColonySpacing.md),
                if (!platform.isAndroid)
                  Text(
                    AppStrings.integrationsNotificationsIos,
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else ...[
                  _SetupStep(
                    number: '1',
                    title: AppStrings.integrationsNotificationsStep1Title,
                    subtitle: AppStrings.integrationsNotificationsStep1Body,
                    done: true,
                  ),
                  _SetupStep(
                    number: '2',
                    title: AppStrings.integrationsNotificationsStep2Title,
                    subtitle: appOn
                        ? AppStrings.integrationsNotificationsAppOn
                        : AppStrings.integrationsNotificationsAppOff,
                    done: appOn,
                    trailing: Semantics(
                      label: AppStrings.integrationsNotificationsOptIn,
                      toggled: appOn,
                      child: Switch(
                        value: appOn,
                        onChanged: busy
                            ? null
                            : (v) => ref
                                .read(integrationsControllerProvider.notifier)
                                .setNotificationListenerEnabled(v),
                      ),
                    ),
                  ),
                  _SetupStep(
                    number: '3',
                    title: AppStrings.integrationsNotificationsStep3Title,
                    subtitle: androidOn
                        ? AppStrings.integrationsNotificationsAndroidOn
                        : AppStrings.integrationsNotificationsAndroidOff,
                    done: androidOn,
                    trailing: Semantics(
                      button: true,
                      identifier: 'integrations.open_listener_settings',
                      label: AppStrings.integrationsNotificationsOpenAndroid,
                      child: OutlinedButton(
                        onPressed: busy
                            ? null
                            : () async {
                                await ref
                                    .read(
                                      integrationsControllerProvider.notifier,
                                    )
                                    .openAndroidListenerSettings();
                                await _refreshAndroidPermission();
                              },
                        child: const Text(
                          AppStrings.integrationsNotificationsOpenAndroid,
                        ),
                      ),
                    ),
                  ),
                  _SetupStep(
                    number: '4',
                    title: AppStrings.integrationsNotificationsStep4Title,
                    subtitle: ready
                        ? AppStrings.integrationsNotificationsReady
                        : AppStrings.integrationsNotificationsNotReady,
                    done: ready,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          Text(
            AppStrings.integrationsNotificationsRecent,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          capturesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(ColonySpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Text(AppStrings.errorGeneric),
            data: (items) {
              if (items.isEmpty) {
                return Text(
                  AppStrings.integrationsNotificationsEmpty,
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              return Column(
                children: [
                  for (final item in items.take(12))
                    Card(
                      margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
                      child: ListTile(
                        title: Text(
                          item.title.isEmpty
                              ? (item.appLabel ?? item.packageName)
                              : item.title,
                        ),
                        subtitle: Text(
                          item.bookedAsFinance
                              ? AppStrings.integrationsNotificationsBooked
                              : (item.text.isEmpty
                                  ? item.packageName
                                  : item.text),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: item.bookedAsFinance
                            ? const Icon(Icons.payments_outlined)
                            : null,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: ColonySpacing.lg),
          const SpotifyIntegrationPanel(),
          const SizedBox(height: ColonySpacing.lg),
          ColonyPanel(
            title: AppStrings.integrationsCalendarIcs,
            child: Semantics(
              label: AppStrings.integrationsOptIn,
              toggled: icsConsent?.enabled ?? false,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.integrationsOptIn),
                subtitle: Text(
                  icsConsent?.enabled == true
                      ? AppStrings.integrationsEnabled
                      : AppStrings.integrationsDisabled,
                ),
                value: icsConsent?.enabled ?? false,
                onChanged: busy
                    ? null
                    : (v) => ref
                        .read(integrationsControllerProvider.notifier)
                        .setCalendarIcsEnabled(v),
              ),
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  identifier: 'integrations.import_ics',
                  label: AppStrings.integrationsImportIcs,
                  child: FilledButton.icon(
                    onPressed: busy ? null : _importIcs,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text(AppStrings.integrationsImportIcs),
                  ),
                ),
              ),
              const SizedBox(width: ColonySpacing.sm),
              Expanded(
                child: Semantics(
                  button: true,
                  label: AppStrings.integrationsPasteIcs,
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : _pasteIcs,
                    icon: const Icon(Icons.content_paste_outlined),
                    label: const Text(AppStrings.integrationsPasteIcs),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ColonySpacing.lg),
          Text(
            AppStrings.integrationsImportedEvents,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          eventsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
            data: (events) {
              if (events.isEmpty) {
                return Column(
                  children: [
                    Text(AppStrings.integrationsEmpty),
                    const SizedBox(height: ColonySpacing.sm),
                    Text(
                      AppStrings.integrationsEmptyHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  for (final e in events)
                    Card(
                      margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
                      child: ListTile(
                        title: Text(e.title),
                        subtitle: Text(
                          '${e.startAt.toUtc().toIso8601String()} · ${e.sourceType.name}',
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.done,
    this.trailing,
  });

  final String number;
  final String title;
  final String subtitle;
  final bool done;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ColonySpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: done
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              done ? '✓' : number,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(width: ColonySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
