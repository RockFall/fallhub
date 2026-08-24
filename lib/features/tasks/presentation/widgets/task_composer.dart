import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/task_controller.dart';

class TaskComposer extends ConsumerStatefulWidget {
  const TaskComposer({
    super.key,
    this.enabled = true,
    this.hint = AppStrings.tasksComposerHint,
    this.onSubmit,
  });

  final bool enabled;
  final String hint;
  final Future<void> Function(String title)? onSubmit;

  @override
  ConsumerState<TaskComposer> createState() => TaskComposerState();
}

class TaskComposerState extends ConsumerState<TaskComposer> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    if (widget.onSubmit != null) {
      await widget.onSubmit!(text);
    } else {
      await ref.read(taskBacklogControllerProvider.notifier).createNamed(text);
    }
    if (!mounted) return;
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColonyColors.panel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ColonySpacing.md,
          ColonySpacing.sm,
          ColonySpacing.md,
          ColonySpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                enabled: widget.enabled,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  isDense: true,
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            IconButton(
              tooltip: AppStrings.tasksComposerSubmit,
              onPressed: widget.enabled ? _submit : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
