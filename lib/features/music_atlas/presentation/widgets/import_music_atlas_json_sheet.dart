import 'dart:convert';

import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/music_atlas_controllers.dart';
import '../../application/music_atlas_import_parse.dart';
import '../../application/music_atlas_providers.dart';

class ImportMusicAtlasJsonSheet extends ConsumerWidget {
  const ImportMusicAtlasJsonSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ImportMusicAtlasJsonSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.md,
        ColonySpacing.lg,
        ColonySpacing.lg + bottom,
      ),
      child: const SingleChildScrollView(
        child: ImportMusicAtlasJsonPanel(popOnSuccess: true),
      ),
    );
  }
}

class ImportMusicAtlasJsonPanel extends ConsumerStatefulWidget {
  const ImportMusicAtlasJsonPanel({super.key, this.popOnSuccess = false});

  final bool popOnSuccess;

  @override
  ConsumerState<ImportMusicAtlasJsonPanel> createState() =>
      _ImportMusicAtlasJsonPanelState();
}

class _ImportMusicAtlasJsonPanelState
    extends ConsumerState<ImportMusicAtlasJsonPanel> {
  final _json = TextEditingController();
  String? _error;
  String? _fileName;
  MusicAtlasJsonDocument? _document;
  bool _parsing = false;

  @override
  void dispose() {
    _json.dispose();
    super.dispose();
  }

  Future<void> _copyPrompt(String prompt) async {
    await Clipboard.setData(ClipboardData(text: prompt));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.musicAtlasPromptCopied)),
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _error = null;
      _parsing = true;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json', 'txt'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) {
        if (mounted) setState(() => _parsing = false);
        return;
      }
      final file = result.files.first;
      if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
        await _acceptParsed(
          await compute(parseMusicAtlasJsonFile, file.path!),
          file.name,
        );
        return;
      }
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        await _acceptParsed(
          await compute(parseMusicAtlasJsonSource, utf8.decode(file.bytes!)),
          file.name,
        );
        return;
      }
      setState(() {
        _parsing = false;
        _error = AppStrings.musicAtlasImportEmpty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _parsing = false;
        _document = null;
        _error = '${AppStrings.musicAtlasInvalidJson}: $e';
      });
    }
  }

  Future<void> _acceptParsed(
    Map<dynamic, dynamic> json,
    String fileName,
  ) async {
    final document = MusicAtlasJsonDocument.fromJson(
      Map<String, dynamic>.from(json),
    );
    if (!mounted) return;
    setState(() {
      _document = document;
      _fileName = fileName;
      _json.clear();
      _parsing = false;
      _error = null;
    });
    await _previewAndConfirm();
  }

  Future<MusicAtlasJsonImportPlan?> _planOrError() async {
    try {
      final document = _document;
      final MusicAtlasJsonDocument resolved;
      if (document != null) {
        resolved = document;
      } else {
        final source = _json.text.trim();
        if (source.isEmpty) {
          setState(() => _error = AppStrings.musicAtlasImportEmpty);
          return null;
        }
        resolved = MusicAtlasJsonDocument.fromJson(
          await compute(parseMusicAtlasJsonSource, source),
        );
      }
      final plan = await ref
          .read(musicAtlasControllerProvider.notifier)
          .previewJson(resolved);
      setState(() {
        _error = null;
        _document = resolved;
      });
      return plan;
    } on MusicAtlasJsonException catch (e) {
      setState(() => _error = '${AppStrings.musicAtlasInvalidJson}: $e');
      return null;
    } on FormatException catch (e) {
      setState(() => _error = '${AppStrings.musicAtlasInvalidJson}: $e');
      return null;
    }
  }

  Future<void> _previewAndConfirm() async {
    final plan = await _planOrError();
    if (plan == null || !mounted) return;
    if (plan.createCount == 0 &&
        plan.linkCount == 0 &&
        plan.encounters.isEmpty &&
        plan.expeditions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.musicAtlasImportNothingToDo)),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.musicAtlasPreview),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.musicAtlasImportPlanSummary(
                  create: plan.createCount,
                  link: plan.linkCount,
                  skip: plan.skipCount,
                  conflict: plan.conflictCount,
                ),
              ),
              const SizedBox(height: ColonySpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final step in plan.nodes.take(20))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(step.node.title, maxLines: 2),
                        subtitle: Text(
                          '${step.action.name} · ${step.node.nodeType.name}',
                        ),
                      ),
                  ],
                ),
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
            child: const Text(AppStrings.musicAtlasApply),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _apply();
  }

  Future<void> _apply() async {
    final document = _document;
    if (document == null) {
      setState(() => _error = AppStrings.musicAtlasImportEmpty);
      return;
    }
    try {
      final result = await ref
          .read(musicAtlasControllerProvider.notifier)
          .applyJson(document);
      if (!mounted || result == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.musicAtlasImportDone} '
            '${AppStrings.musicAtlasImportPlanSummary(
              create: result.createdNodes,
              link: result.linkedNodes,
              skip: result.skippedNodes,
              conflict: result.conflictNodes,
            )}',
          ),
        ),
      );
      _json.clear();
      setState(() {
        _error = null;
        _document = null;
        _fileName = null;
      });
      if (widget.popOnSuccess && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on MusicAtlasJsonException catch (e) {
      setState(() => _error = '${AppStrings.musicAtlasInvalidJson}: $e');
    } on FormatException catch (e) {
      setState(() => _error = '${AppStrings.musicAtlasInvalidJson}: $e');
    } catch (_) {
      setState(() => _error = AppStrings.errorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prompt = ref.watch(musicAtlasPromptProvider);
    final busy =
        _parsing || ref.watch(musicAtlasControllerProvider).isLoading;

    return Semantics(
      container: true,
      identifier: 'music_atlas.import',
      label: AppStrings.musicAtlasImportJson,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.musicAtlasSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ColonyColors.textMuted),
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.musicAtlasPromptLive,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: ColonyColors.accentCyan),
          ),
          const SizedBox(height: ColonySpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.musicAtlasPromptTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              TextButton.icon(
                onPressed: busy
                    ? null
                    : () => prompt.whenData(_copyPrompt),
                icon: const Icon(Icons.copy_outlined),
                label: const Text(AppStrings.musicAtlasCopyPrompt),
              ),
            ],
          ),
          const SizedBox(height: ColonySpacing.sm),
          prompt.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(AppStrings.errorGeneric),
            data: (text) => DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: ColonyColors.borderSeparator),
                borderRadius: BorderRadius.circular(ColonyRadii.md),
                color: ColonyColors.panel.withValues(alpha: 0.4),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(ColonySpacing.sm),
                  child: SelectableText(
                    text,
                    key: const Key('music_atlas.import.prompt'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          TextField(
            key: const Key('music_atlas.import.json'),
            controller: _json,
            enabled: !busy,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: AppStrings.musicAtlasPasteJson,
              hintText: AppStrings.musicAtlasPasteHint,
              helperText: _fileName,
            ),
            onChanged: (_) {
              if (_error != null || _document != null) {
                setState(() {
                  _error = null;
                  _document = null;
                  _fileName = null;
                });
              }
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: ColonySpacing.sm),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: ColonySpacing.md),
          if (busy) const LinearProgressIndicator(),
          if (busy) const SizedBox(height: ColonySpacing.sm),
          Wrap(
            spacing: ColonySpacing.sm,
            runSpacing: ColonySpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : _pickFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text(AppStrings.musicAtlasPickFile),
              ),
              FilledButton.icon(
                onPressed: busy ? null : _previewAndConfirm,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text(AppStrings.musicAtlasPreview),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
