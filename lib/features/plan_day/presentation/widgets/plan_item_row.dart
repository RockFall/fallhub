import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/plan_day_controller.dart';
import '../../application/plan_day_providers.dart';
import 'plan_day_feedback.dart';

class PlanItemRow extends ConsumerWidget {
  const PlanItemRow({
    super.key,
    required this.row,
    this.onMoveUp,
    this.onMoveDown,
  });

  final PlanRow row;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final linked = row.item.isLinked;
    final scheduled = _scheduledLabel(row.linkedTask);
    return Dismissible(
      key: ValueKey('plan-dismiss-${row.item.id.value}'),
      direction: DismissDirection.horizontal,
      background: const ColoredBox(
        color: ColonyColors.statusGood,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: ColonySpacing.lg),
            child: Icon(Icons.check, color: ColonyColors.textPrimary),
          ),
        ),
      ),
      secondaryBackground: const ColoredBox(
        color: ColonyColors.statusRisk,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: ColonySpacing.lg),
            child: Icon(
              Icons.remove_circle_outline,
              color: ColonyColors.textPrimary,
            ),
          ),
        ),
      ),
      confirmDismiss: (direction) async {
        final controller = ref.read(planDayControllerProvider.notifier);
        if (direction == DismissDirection.startToEnd) {
          final rejection = await controller.toggle(row);
          if (context.mounted) {
            if (rejection ==
                DayPlanCompletionRejection.linkedTaskBlocksCompletion) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppStrings.planDayBlockedComplete),
                ),
              );
            } else {
              showPlanDayUndoSnack(
                context,
                ref,
                AppStrings.planDayCompletedSnack,
              );
            }
          }
          return false;
        }
        await controller.removeFromToday(row.item);
        if (context.mounted) {
          showPlanDayUndoSnack(context, ref, AppStrings.planDayRemovedSnack);
        }
        return false;
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 2,
              color: linked
                  ? ColonyColors.accentCyan
                  : ColonyColors.borderSubtle,
            ),
          ),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: ColonySpacing.sm,
          ),
          leading: Semantics(
            label: linked
                ? AppStrings.planDayLinkedSemantics(row.title, row.isDone)
                : AppStrings.planDayCheckboxSemantics(row.title, row.isDone),
            child: Checkbox(
              value: row.isDone,
              onChanged: (_) async {
                final rejection = await ref
                    .read(planDayControllerProvider.notifier)
                    .toggle(row);
                if (!context.mounted) return;
                if (rejection ==
                    DayPlanCompletionRejection.linkedTaskBlocksCompletion) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.planDayBlockedComplete),
                    ),
                  );
                  return;
                }
                showPlanDayUndoSnack(
                  context,
                  ref,
                  AppStrings.planDayCompletedSnack,
                );
              },
            ),
          ),
          title: GestureDetector(
            onTap: linked
                ? () {
                    final id = row.item.taskId?.value;
                    if (id != null) context.go('/tasks/$id');
                  }
                : null,
            onLongPress: linked
                ? null
                : () => _rename(context, ref),
            child: Text(
              row.title,
              style: text.bodyMedium?.copyWith(
                decoration: row.isDone ? TextDecoration.lineThrough : null,
                color: row.isDone
                    ? ColonyColors.textMuted
                    : ColonyColors.textPrimary,
              ),
            ),
          ),
          subtitle: scheduled == null
              ? null
              : Text(
                  AppStrings.planDayScheduledPill(scheduled),
                  style: text.labelSmall?.copyWith(
                    color: ColonyColors.textMuted,
                  ),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (linked)
                const Tooltip(
                  message: AppStrings.planDayLinkedBadge,
                  child: Icon(
                    Icons.link,
                    size: 16,
                    color: ColonyColors.textMuted,
                  ),
                ),
              PopupMenuButton<String>(
                tooltip: AppStrings.more,
                onSelected: (value) async {
                  final controller =
                      ref.read(planDayControllerProvider.notifier);
                  switch (value) {
                    case 'remove':
                      await controller.removeFromToday(row.item);
                      if (context.mounted) {
                        showPlanDayUndoSnack(
                          context,
                          ref,
                          AppStrings.planDayRemovedSnack,
                        );
                      }
                    case 'open':
                      final id = row.item.taskId?.value;
                      if (id != null) context.go('/tasks/$id');
                    case 'rename':
                      if (context.mounted) await _rename(context, ref);
                    case 'up':
                      onMoveUp?.call();
                    case 'down':
                      onMoveDown?.call();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text(AppStrings.planDayRemoveFromToday),
                  ),
                  if (!linked)
                    const PopupMenuItem(
                      value: 'rename',
                      child: Text(AppStrings.planDayRename),
                    ),
                  if (onMoveUp != null)
                    const PopupMenuItem(
                      value: 'up',
                      child: Text(AppStrings.planDayMoveUp),
                    ),
                  if (onMoveDown != null)
                    const PopupMenuItem(
                      value: 'down',
                      child: Text(AppStrings.planDayMoveDown),
                    ),
                  if (linked)
                    const PopupMenuItem(
                      value: 'open',
                      child: Text(AppStrings.planDayOpenTask),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: row.title);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.planDayRename),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (next == null) return;
    await ref.read(planDayControllerProvider.notifier).rename(row.item, next);
  }

  static String? _scheduledLabel(ColonyTask? task) {
    final start = task?.scheduledStart;
    if (start == null) return null;
    final local = start.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
