import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/relations_controllers.dart';

class CreateFriendshipCircleSheet extends ConsumerStatefulWidget {
  const CreateFriendshipCircleSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateFriendshipCircleSheet(),
    );
  }

  @override
  ConsumerState<CreateFriendshipCircleSheet> createState() =>
      _CreateFriendshipCircleSheetState();
}

class _CreateFriendshipCircleSheetState
    extends ConsumerState<CreateFriendshipCircleSheet> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  FriendshipCadence? _cadence;
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _nameError = AppStrings.friendshipCircleNameRequired);
      return;
    }
    final created =
        await ref.read(relationsControllerProvider.notifier).createCircle(
              name: trimmed,
              notes: _notes.text,
              defaultCadence: _cadence,
            );
    if (!mounted || created == null) return;
    Navigator.pop(context);
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
            AppStrings.friendshipCircleNew,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.lg),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: AppStrings.friendshipCircleName,
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          DropdownButtonFormField<FriendshipCadence?>(
            initialValue: _cadence,
            decoration: const InputDecoration(
              labelText: AppStrings.friendshipCircleDefaultCadence,
            ),
            items: [
              const DropdownMenuItem<FriendshipCadence?>(
                value: null,
                child: Text(AppStrings.friendshipNoCadence),
              ),
              ...FriendshipCadence.values.map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(AppStrings.friendshipCadenceLabel(c)),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _cadence = value),
          ),
          const SizedBox(height: ColonySpacing.md),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: AppStrings.friendshipCircleNotesOptional,
            ),
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
