import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/music_atlas_controllers.dart';

class CreateMusicNodeSheet extends ConsumerStatefulWidget {
  const CreateMusicNodeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateMusicNodeSheet(),
    );
  }

  @override
  ConsumerState<CreateMusicNodeSheet> createState() =>
      _CreateMusicNodeSheetState();
}

class _CreateMusicNodeSheetState extends ConsumerState<CreateMusicNodeSheet> {
  final _title = TextEditingController();
  final _year = TextEditingController();
  var _type = MusicNodeType.releaseGroup;

  @override
  void dispose() {
    _title.dispose();
    _year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.md,
        ColonySpacing.lg,
        ColonySpacing.lg + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.musicAtlasCreateNode,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: AppStrings.musicAtlasTitleField,
            ),
          ),
          DropdownButton<MusicNodeType>(
            value: _type,
            isExpanded: true,
            items: [
              for (final type in MusicNodeType.values)
                DropdownMenuItem(
                  value: type,
                  child: Text(AppStrings.musicAtlasNodeTypeLabel(type)),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _type = value);
            },
          ),
          TextField(
            controller: _year,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: AppStrings.musicAtlasYearField,
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          FilledButton(
            onPressed: () async {
              final title = _title.text.trim();
              if (title.isEmpty) return;
              await ref
                  .read(musicAtlasControllerProvider.notifier)
                  .createNode(
                    type: _type,
                    title: title,
                    year: int.tryParse(_year.text.trim()),
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text(AppStrings.musicAtlasCreateNode),
          ),
        ],
      ),
    );
  }
}
