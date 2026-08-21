import 'dart:convert';

import 'package:colony_design_system/colony_design_system.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/timeline_controllers.dart';
import '../../application/timeline_import_parse.dart';
import '../../application/timeline_providers.dart';

class ImportTimelineSheet extends ConsumerStatefulWidget {
  const ImportTimelineSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ImportTimelineSheet(),
    );
  }

  @override
  ConsumerState<ImportTimelineSheet> createState() =>
      _ImportTimelineSheetState();
}

class _ImportTimelineSheetState extends ConsumerState<ImportTimelineSheet> {
  String? _error;
  String? _fileName;
  String? _compactPath;
  int _visits = 0;
  int _activities = 0;
  int _trips = 0;
  int _places = 0;
  bool _busy = false;
  bool get _hasPreview => _compactPath != null;

  Future<void> _openHelp() async {
    final uri = Uri.parse(AppStrings.timelineHelpUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _errorMessage(Object e) {
    return '${AppStrings.timelineParseError} ($e)';
  }

  Future<void> _pickFile() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json', 'txt'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final file = result.files.first;
      if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
        await _parsePath(file.path!, file.name);
        return;
      }
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        await _parseSource(utf8.decode(file.bytes!), file.name);
        return;
      }
      setState(() {
        _busy = false;
        _error = AppStrings.timelineReadError;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _errorMessage(e);
      });
    }
  }

  Future<void> _paste() async {
    final controller = TextEditingController();
    final source = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.timelinePasteJson),
        content: TextField(
          controller: controller,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: AppStrings.timelinePasteHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text(AppStrings.timelinePasteJson),
          ),
        ],
      ),
    );
    controller.dispose();
    if (source == null || source.trim().isEmpty) return;
    setState(() {
      _error = null;
      _busy = true;
    });
    await _parseSource(source, 'colado.json');
  }

  Future<void> _parsePath(String path, String fileName) async {
    try {
      final result = await compute(parseGoogleTimelineFile, path);
      _acceptPreview(result, fileName);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _compactPath = null;
        _error = _errorMessage(e);
      });
    }
  }

  Future<void> _parseSource(String source, String fileName) async {
    try {
      final result = await compute(parseGoogleTimelineSource, source);
      _acceptPreview(result, fileName);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _compactPath = null;
        _error = _errorMessage(e);
      });
    }
  }

  void _acceptPreview(Map<String, dynamic> result, String fileName) {
    if (!mounted) return;
    setState(() {
      _compactPath = result['compactPath'] as String?;
      _visits = result['visits'] as int? ?? 0;
      _activities = result['activities'] as int? ?? 0;
      _trips = result['trips'] as int? ?? 0;
      _places = result['places'] as int? ?? 0;
      _fileName = fileName;
      _busy = false;
      _error = null;
    });
  }

  Future<void> _confirm() async {
    final path = _compactPath;
    final name = _fileName;
    if (path == null || name == null) return;
    final existing = ref.read(googleTimelineImportProvider).asData?.value;
    if (existing != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(AppStrings.timelineOverwriteTitle),
          content: Text(
            '${AppStrings.timelineOverwriteBody}\n\n'
            '${AppStrings.timelineOverwriteSummary(existing.fileName, existing.importedAt)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(AppStrings.timelineOverwriteConfirm),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    final imported = await ref
        .read(timelineControllerProvider.notifier)
        .replaceImport(
          fileName: name,
          compactJsonPath: path,
          visitCount: _visits,
          activityCount: _activities,
          tripCount: _trips,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (imported == null) {
      setState(() => _error = AppStrings.errorGeneric);
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.timelineImportSuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final preview = _hasPreview;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scroll) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            ColonySpacing.lg,
            ColonySpacing.md,
            ColonySpacing.lg,
            ColonySpacing.lg + bottom,
          ),
          child: ListView(
            controller: scroll,
            children: [
              Text(
                AppStrings.timelineImport,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: ColonySpacing.sm),
              Text(
                AppStrings.timelineHowToLead,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: ColonyColors.textMuted),
              ),
              const SizedBox(height: ColonySpacing.lg),
              ColonyPanel(
                title: AppStrings.timelineAndroidTitle,
                icon: Icons.android,
                child: Text(AppStrings.timelineAndroidSteps),
              ),
              const SizedBox(height: ColonySpacing.md),
              ColonyPanel(
                title: AppStrings.timelineIosTitle,
                icon: Icons.phone_iphone,
                child: Text(AppStrings.timelineIosSteps),
              ),
              const SizedBox(height: ColonySpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _openHelp,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text(AppStrings.timelineHelpLink),
                ),
              ),
              const SizedBox(height: ColonySpacing.md),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text(AppStrings.timelinePickJson),
                    ),
                  ),
                  const SizedBox(width: ColonySpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _paste,
                      icon: const Icon(Icons.paste),
                      label: const Text(AppStrings.timelinePasteJson),
                    ),
                  ),
                ],
              ),
              if (_busy) ...[
                const SizedBox(height: ColonySpacing.lg),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_error != null) ...[
                const SizedBox(height: ColonySpacing.md),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColonyColors.statusRisk,
                  ),
                ),
              ],
              if (preview) ...[
                const SizedBox(height: ColonySpacing.lg),
                ColonyPanel(
                  title: AppStrings.timelinePreviewTitle,
                  icon: Icons.preview_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_fileName ?? ''),
                      const SizedBox(height: ColonySpacing.sm),
                      Text(
                        AppStrings.timelinePreviewCounts(
                          visits: _visits,
                          activities: _activities,
                          trips: _trips,
                          places: _places,
                        ),
                      ),
                      const SizedBox(height: ColonySpacing.md),
                      FilledButton(
                        onPressed: _busy ? null : _confirm,
                        child: Text(
                          ref
                                      .watch(googleTimelineImportProvider)
                                      .asData
                                      ?.value ==
                                  null
                              ? AppStrings.timelineImportConfirm
                              : AppStrings.timelineOverwriteConfirm,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
