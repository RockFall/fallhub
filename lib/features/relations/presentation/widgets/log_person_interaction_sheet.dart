import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/relations_controllers.dart';

class LogPersonInteractionSheet extends ConsumerStatefulWidget {
  const LogPersonInteractionSheet({super.key, required this.person});

  final Person person;

  static Future<void> show(BuildContext context, Person person) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LogPersonInteractionSheet(person: person),
    );
  }

  @override
  ConsumerState<LogPersonInteractionSheet> createState() =>
      _LogPersonInteractionSheetState();
}

class _LogPersonInteractionSheetState
    extends ConsumerState<LogPersonInteractionSheet> {
  final _noteController = TextEditingController();
  InteractionKind _kind = InteractionKind.meeting;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final created =
        await ref.read(relationsControllerProvider.notifier).logInteraction(
              person: widget.person,
              kind: _kind,
              occurredAt: DateTime.now().toUtc(),
              note: _noteController.text,
            );
    if (!mounted) return;
    if (created != null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.personLogInteraction,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            widget.person.displayName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: ColonySpacing.md),
          DropdownButtonFormField<InteractionKind>(
            initialValue: _kind,
            decoration: const InputDecoration(
              labelText: AppStrings.personInteractionKind,
            ),
            items: InteractionKind.values
                .map(
                  (k) => DropdownMenuItem(
                    value: k,
                    child: Text(AppStrings.interactionKindLabel(k)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _kind = value);
            },
          ),
          const SizedBox(height: ColonySpacing.md),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: AppStrings.personInteractionNote,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: ColonySpacing.lg),
          FilledButton(
            onPressed: _save,
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}
