import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/music_atlas_controllers.dart';
import '../../application/music_atlas_providers.dart';

class MusicFlashcardCandidatesSheet extends ConsumerStatefulWidget {
  const MusicFlashcardCandidatesSheet({super.key, required this.encounterId});

  final EntityId encounterId;

  static Future<void> show(
    BuildContext context, {
    required EntityId encounterId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MusicFlashcardCandidatesSheet(encounterId: encounterId),
    );
  }

  @override
  ConsumerState<MusicFlashcardCandidatesSheet> createState() =>
      _MusicFlashcardCandidatesSheetState();
}

class _MusicFlashcardCandidatesSheetState
    extends ConsumerState<MusicFlashcardCandidatesSheet> {
  final _accepted = <String>{};

  String _key(MusicFlashcardCandidate candidate) =>
      '${candidate.origin}:${candidate.originId.value}:${candidate.front}';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      musicFlashcardCandidatesProvider(widget.encounterId.value),
    );
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.md,
        ColonySpacing.lg,
        ColonySpacing.lg + bottom,
      ),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text('$error'),
        data: (candidates) {
          if (candidates.isEmpty) {
            return const Text(AppStrings.musicAtlasNoCandidates);
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.musicAtlasSuggestCards,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: ColonySpacing.sm),
              Text(
                AppStrings.musicAtlasFlashcardsHelp,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: ColonySpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final candidate = candidates[index];
                    final key = _key(candidate);
                    return CheckboxListTile(
                      value: _accepted.contains(key),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _accepted.add(key);
                          } else {
                            _accepted.remove(key);
                          }
                        });
                      },
                      title: Text(candidate.front),
                      subtitle: Text(candidate.back),
                    );
                  },
                ),
              ),
              FilledButton(
                onPressed: () async {
                  final chosen = [
                    for (final candidate in candidates)
                      if (_accepted.contains(_key(candidate))) candidate,
                  ];
                  await ref
                      .read(musicAtlasControllerProvider.notifier)
                      .acceptCandidates(chosen);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text(AppStrings.musicAtlasAcceptCards),
              ),
            ],
          );
        },
      ),
    );
  }
}
