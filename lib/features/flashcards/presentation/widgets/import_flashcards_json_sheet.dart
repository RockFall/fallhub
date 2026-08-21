import 'dart:convert';

import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/flashcard_controllers.dart';
import '../../application/flashcard_import_parse.dart';
import '../../application/flashcard_providers.dart';

class ImportFlashcardsJsonSheet extends ConsumerWidget {
  const ImportFlashcardsJsonSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ImportFlashcardsJsonSheet(),
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
        child: ImportFlashcardsJsonPanel(popOnSuccess: true),
      ),
    );
  }
}

class ImportFlashcardsJsonPanel extends ConsumerStatefulWidget {
  const ImportFlashcardsJsonPanel({super.key, this.popOnSuccess = false});

  final bool popOnSuccess;

  @override
  ConsumerState<ImportFlashcardsJsonPanel> createState() =>
      _ImportFlashcardsJsonPanelState();
}

class _ImportFlashcardsJsonPanelState
    extends ConsumerState<ImportFlashcardsJsonPanel> {
  final _json = TextEditingController();
  String? _error;
  String? _fileName;
  FlashcardJsonDocument? _document;
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
      const SnackBar(content: Text(AppStrings.flashcardsImportCopied)),
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
          await compute(parseFlashcardJsonFile, file.path!),
          file.name,
        );
        return;
      }
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        await _acceptParsed(
          await compute(parseFlashcardJsonSource, utf8.decode(file.bytes!)),
          file.name,
        );
        return;
      }
      setState(() {
        _parsing = false;
        _error = AppStrings.flashcardsImportEmpty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _parsing = false;
        _document = null;
        _error = '${AppStrings.flashcardsImportInvalid}: $e';
      });
    }
  }

  Future<void> _acceptParsed(
    Map<dynamic, dynamic> json,
    String fileName,
  ) async {
    final document = FlashcardJsonDocument.fromJson(
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

  FlashcardJsonImportPlan? _planOrError() {
    try {
      final document = _document;
      final FlashcardJsonImportPlan plan;
      if (document != null) {
        plan = ref
            .read(flashcardControllerProvider.notifier)
            .previewDocument(document);
      } else {
        final source = _json.text.trim();
        if (source.isEmpty) {
          setState(() => _error = AppStrings.flashcardsImportEmpty);
          return null;
        }
        plan = ref
            .read(flashcardControllerProvider.notifier)
            .previewJson(source);
      }
      setState(() => _error = null);
      return plan;
    } on FlashcardJsonException catch (e) {
      setState(() => _error = '${AppStrings.flashcardsImportInvalid}: $e');
      return null;
    } on FormatException catch (e) {
      setState(() => _error = '${AppStrings.flashcardsImportInvalid}: $e');
      return null;
    }
  }

  Future<void> _previewAndConfirm() async {
    final plan = _planOrError();
    if (plan == null || !mounted) return;
    if (plan.createCount == 0 &&
        plan.overwriteCount == 0 &&
        plan.newAreaCount == 0 &&
        plan.newDeckCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.flashcardsImportNothingToDo)),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.flashcardsImportPreview),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.flashcardsImportPlanSummary(
                  create: plan.createCount,
                  skip: plan.skipCount,
                  overwrite: plan.overwriteCount,
                  areas: plan.newAreaCount,
                  decks: plan.newDeckCount,
                ),
              ),
              const SizedBox(height: ColonySpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final step in plan.cards.take(20))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(step.card.front, maxLines: 2),
                        subtitle: Text(
                          '${_actionLabel(step.action)} · ${step.card.deckTitle}',
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
            child: const Text(AppStrings.flashcardsImportConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _apply();
  }

  Future<void> _apply() async {
    final document = _document;
    final source = _json.text.trim();
    if (document == null && source.isEmpty) {
      setState(() => _error = AppStrings.flashcardsImportEmpty);
      return;
    }
    try {
      final result = document != null
          ? await ref
                .read(flashcardControllerProvider.notifier)
                .importDocument(document)
          : await ref
                .read(flashcardControllerProvider.notifier)
                .importJson(source);
      if (!mounted || result == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.flashcardsImportDone} '
            '${AppStrings.flashcardsImportResultSummary(result)}',
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
    } on FlashcardJsonException catch (e) {
      setState(() => _error = '${AppStrings.flashcardsImportInvalid}: $e');
    } on FormatException catch (e) {
      setState(() => _error = '${AppStrings.flashcardsImportInvalid}: $e');
    } catch (_) {
      setState(() => _error = AppStrings.errorGeneric);
    }
  }

  static String _actionLabel(FlashcardJsonCardActionKind action) {
    return switch (action) {
      FlashcardJsonCardActionKind.create => 'novo',
      FlashcardJsonCardActionKind.skip => 'igual',
      FlashcardJsonCardActionKind.overwrite => 'atualizar verso',
    };
  }

  @override
  Widget build(BuildContext context) {
    final prompt = ref.watch(flashcardJsonPromptProvider);
    final busy = _parsing || ref.watch(flashcardControllerProvider).isLoading;
    final areasAsync = ref.watch(knowledgeAreasProvider);
    final decksAsync = ref.watch(flashcardDecksProvider);

    return Semantics(
      container: true,
      identifier: 'flashcards.import',
      label: AppStrings.flashcardsImportJson,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.flashcardsImportJsonHint,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ColonyColors.textMuted),
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.flashcardsImportPromptLive,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: ColonyColors.accentCyan),
          ),
          const SizedBox(height: ColonySpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.flashcardsImportPromptTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              TextButton.icon(
                onPressed: busy ? null : () => _copyPrompt(prompt),
                icon: const Icon(Icons.copy_outlined),
                label: const Text(AppStrings.flashcardsImportCopyPrompt),
              ),
            ],
          ),
          const SizedBox(height: ColonySpacing.sm),
          areasAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(AppStrings.errorGeneric),
            data: (_) => decksAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(AppStrings.errorGeneric),
              data: (_) => DecoratedBox(
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
                      prompt,
                      key: const Key('flashcards.import.prompt'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          TextField(
            key: const Key('flashcards.import.json'),
            controller: _json,
            enabled: !busy,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: AppStrings.flashcardsImportPaste,
              hintText: AppStrings.flashcardsImportPasteHint,
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
                label: const Text(AppStrings.flashcardsImportPickFile),
              ),
              FilledButton.icon(
                onPressed: busy ? null : _previewAndConfirm,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text(AppStrings.flashcardsImportPreview),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
