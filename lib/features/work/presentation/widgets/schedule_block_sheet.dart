import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../application/work_controllers.dart';

class ScheduleBlockSheet extends ConsumerStatefulWidget {
  const ScheduleBlockSheet({
    super.key,
    required this.day,
    this.block,
  });

  final DateTime day;
  final ScheduleBlock? block;

  static Future<void> showAdd(BuildContext context, DateTime day) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ScheduleBlockSheet(day: day),
    );
  }

  static Future<void> showEdit(
    BuildContext context, {
    required ScheduleBlock block,
    required DateTime day,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ScheduleBlockSheet(day: day, block: block),
    );
  }

  @override
  ConsumerState<ScheduleBlockSheet> createState() => _ScheduleBlockSheetState();
}

class _ScheduleBlockSheetState extends ConsumerState<ScheduleBlockSheet> {
  late ScheduleBlockMode _mode;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  bool get _isEdit => widget.block != null;

  @override
  void initState() {
    super.initState();
    final block = widget.block;
    if (block != null) {
      _mode = block.mode;
      final startLocal = block.startAt.toLocal();
      final endLocal = block.endAt.toLocal();
      _startTime = TimeOfDay(hour: startLocal.hour, minute: startLocal.minute);
      _endTime = TimeOfDay(hour: endLocal.hour, minute: endLocal.minute);
    } else {
      _mode = ScheduleBlockMode.focus;
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final use24Hour =
        ref.read(preferencesProvider).asData?.value.use24HourFormat ?? true;
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: use24Hour),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final controller = ref.read(scheduleControllerProvider.notifier);
    if (_isEdit) {
      await controller.updateBlock(
        block: widget.block!,
        day: widget.day,
        startHour: _startTime.hour,
        startMinute: _startTime.minute,
        endHour: _endTime.hour,
        endMinute: _endTime.minute,
        mode: _mode,
      );
    } else {
      await controller.addBlock(
        day: widget.day,
        startHour: _startTime.hour,
        startMinute: _startTime.minute,
        endHour: _endTime.hour,
        endMinute: _endTime.minute,
        mode: _mode,
      );
    }
    if (!mounted) return;
    if (ref.read(scheduleControllerProvider).hasError) return;
    Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.scheduleDeleteBlock),
        content: const Text(AppStrings.scheduleDeleteBlockConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(scheduleControllerProvider.notifier).deleteBlock(widget.block!.id);
    if (!mounted) return;
    if (ref.read(scheduleControllerProvider).hasError) return;
    Navigator.pop(context);
  }

  String _formatTime(TimeOfDay time, String locale, bool use24Hour) {
    final dateTime = DateTime(2026, 1, 1, time.hour, time.minute);
    final format = use24Hour ? DateFormat.Hm(locale) : DateFormat.jm(locale);
    return format.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final profile = ref.watch(profileProvider).asData?.value;
    final prefs = ref.watch(preferencesProvider).asData?.value;
    final locale = profile?.locale ?? 'pt_BR';
    final use24Hour = prefs?.use24HourFormat ?? true;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? AppStrings.scheduleEditBlock : AppStrings.addScheduleBlock,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            DropdownButtonFormField<ScheduleBlockMode>(
              value: _mode,
              decoration: const InputDecoration(labelText: AppStrings.scheduleBlockMode),
              items: ScheduleBlockMode.values
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(AppStrings.scheduleBlockModeLabel(m)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _mode = v);
              },
            ),
            const SizedBox(height: ColonySpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.scheduleStartTime),
              subtitle: Text(_formatTime(_startTime, locale, use24Hour)),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _pickTime(isStart: true),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.scheduleEndTime),
              subtitle: Text(_formatTime(_endTime, locale, use24Hour)),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _pickTime(isStart: false),
              ),
            ),
            const SizedBox(height: ColonySpacing.lg),
            Row(
              children: [
                if (_isEdit) ...[
                  TextButton(
                    onPressed: _confirmDelete,
                    child: const Text(AppStrings.delete),
                  ),
                  const Spacer(),
                ],
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(AppStrings.cancel),
                ),
                const SizedBox(width: ColonySpacing.md),
                FilledButton(
                  onPressed: _save,
                  child: const Text(AppStrings.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
