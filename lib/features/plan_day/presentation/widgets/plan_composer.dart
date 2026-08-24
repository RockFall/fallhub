import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/plan_day_controller.dart';
import '../../application/plan_day_providers.dart';

class PlanComposer extends ConsumerStatefulWidget {
  const PlanComposer({
    super.key,
    this.autoFocus = false,
    this.enabled = true,
  });

  final bool autoFocus;
  final bool enabled;

  @override
  ConsumerState<PlanComposer> createState() => PlanComposerState();
}

class PlanComposerState extends ConsumerState<PlanComposer> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  var _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    await ref.read(planDayControllerProvider.notifier).addAdHoc(text);
    if (!mounted) return;
    _controller.clear();
    setState(() => _query = '');
    _focus.requestFocus();
  }

  Future<void> _pick(ColonyTask task) async {
    if (!widget.enabled) return;
    await ref.read(planDayControllerProvider.notifier).addFromSuggestion(task);
    if (!mounted) return;
    _controller.clear();
    setState(() => _query = '');
    _focus.requestFocus();
  }

  Future<void> _openList() async {
    if (!widget.enabled) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColonyColors.panel,
      builder: (context) => const _AddFromListSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typing = _query.trim().isNotEmpty;
    final suggestions = ref.watch(planTaskSuggestionsProvider(_query));
    final chips = typing
        ? const <ColonyTask>[]
        : ref.watch(planTaskSuggestionsProvider(''));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (typing && suggestions.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: Material(
              color: ColonyColors.raised,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final task = suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.circle,
                      size: 8,
                      color: task.status == TaskStatus.inbox
                          ? ColonyColors.statusInfo
                          : ColonyColors.accentSand,
                    ),
                    title: Text(task.title),
                    trailing: Text(
                      task.status == TaskStatus.inbox
                          ? AppStrings.planDayChipInbox
                          : AppStrings.planDayChipNext,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ColonyColors.textMuted,
                          ),
                    ),
                    onTap: () => _pick(task),
                  );
                },
              ),
            ),
          ),
        if (!typing && chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ColonySpacing.md,
              ColonySpacing.sm,
              ColonySpacing.md,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: ColonySpacing.sm,
                runSpacing: ColonySpacing.xs,
                children: [
                  for (final task in chips)
                    Semantics(
                      button: true,
                      label: AppStrings.planDaySuggestionSemantics(task.title),
                      child: ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(task.title),
                        onPressed:
                            widget.enabled ? () => _pick(task) : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: ColonyColors.panel,
            border: Border(top: BorderSide(color: ColonyColors.borderDark)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                ColonySpacing.md,
                ColonySpacing.sm,
                ColonySpacing.sm,
                ColonySpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: AppStrings.planDayAddFromList,
                    onPressed: widget.enabled ? _openList : null,
                    icon: const Icon(Icons.playlist_add_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      enabled: widget.enabled,
                      textInputAction: TextInputAction.done,
                      onChanged: (value) => setState(() => _query = value),
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: AppStrings.planDayComposerHint,
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: AppStrings.planDayComposerSubmit,
                    onPressed: widget.enabled ? _submit : null,
                    icon: const Icon(Icons.add_circle_outline),
                    color: ColonyColors.accentCyan,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddFromListSheet extends ConsumerStatefulWidget {
  const _AddFromListSheet();

  @override
  ConsumerState<_AddFromListSheet> createState() => _AddFromListSheetState();
}

class _AddFromListSheetState extends ConsumerState<_AddFromListSheet> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(planPullableTasksProvider);
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? all
        : all
            .where((task) => task.title.toLowerCase().contains(q))
            .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: 420,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ColonySpacing.lg,
                  ColonySpacing.md,
                  ColonySpacing.lg,
                  ColonySpacing.sm,
                ),
                child: TextField(
                  autofocus: true,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    labelText: AppStrings.planDayAddFromList,
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(AppStrings.planDayNoSuggestions),
                            TextButton(
                              onPressed: () {
                                final router = GoRouter.of(context);
                                Navigator.of(context).pop();
                                router.go('/inbox');
                              },
                              child: const Text(AppStrings.planDayOpenInbox),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final task = filtered[index];
                          return ListTile(
                            title: Text(task.title),
                            trailing: const Icon(Icons.add),
                            onTap: () => ref
                                .read(planDayControllerProvider.notifier)
                                .addFromSuggestion(task),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
