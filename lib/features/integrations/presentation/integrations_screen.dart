import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/integrations_controllers.dart';
import '../application/integrations_providers.dart';

class IntegrationsScreen extends ConsumerStatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  ConsumerState<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends ConsumerState<IntegrationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(integrationsControllerProvider.notifier).ensureCalendarConsent();
    });
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
    final consent = ref.watch(calendarIcsConsentProvider);
    final eventsAsync = ref.watch(externalCalendarEventsProvider);
    final busy = ref.watch(integrationsControllerProvider).isLoading;

    return Semantics(
      container: true,
      identifier: 'integrations.screen',
      label: AppStrings.integrationsTitle,
      child: Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
            title: AppStrings.integrationsCalendarIcs,
            child: Semantics(
              label: AppStrings.integrationsOptIn,
              toggled: consent?.enabled ?? false,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.integrationsOptIn),
                subtitle: Text(
                  consent?.enabled == true
                      ? AppStrings.integrationsEnabled
                      : AppStrings.integrationsDisabled,
                ),
                value: consent?.enabled ?? false,
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
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  Center(child: Text(AppStrings.errorGeneric)),
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.integrationsEmpty),
                        const SizedBox(height: ColonySpacing.sm),
                        Text(
                          AppStrings.integrationsEmptyHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final e = events[index];
                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: ColonySpacing.sm),
                      child: ListTile(
                        title: Text(e.title),
                        subtitle: Text(
                          '${e.startAt.toUtc().toIso8601String()} · ${e.sourceType.name}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}
