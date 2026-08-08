import 'package:colony_design_system/colony_design_system.dart';

import 'package:colony_domain/colony_domain.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../../app/localization/app_strings.dart';

import '../../storyteller/presentation/narrative_digest_sheet.dart';

import '../application/pawn_controllers.dart';

import '../application/pawn_providers.dart';



class WeeklyReviewScreen extends ConsumerStatefulWidget {

  const WeeklyReviewScreen({super.key});



  @override

  ConsumerState<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();

}



class _WeeklyReviewScreenState extends ConsumerState<WeeklyReviewScreen> {

  final _facts = TextEditingController();

  final _wins = TextEditingController();

  final _problems = TextEditingController();

  final _projects = TextEditingController();

  final _learning = TextEditingController();

  final _nextWeek = TextEditingController();

  var _loaded = false;



  @override

  void dispose() {

    _facts.dispose();

    _wins.dispose();

    _problems.dispose();

    _projects.dispose();

    _learning.dispose();

    _nextWeek.dispose();

    super.dispose();

  }



  void _populateFromReview(WeeklyReview? review) {

    if (review == null || _loaded) return;

    _facts.text = review.facts ?? '';

    _wins.text = review.wins ?? '';

    _problems.text = review.problems ?? '';

    _projects.text = review.projects ?? '';

    _learning.text = review.learning ?? '';

    _nextWeek.text = review.nextWeek ?? '';

    _loaded = true;

  }



  Future<void> _save() async {

    await ref.read(weeklyReviewControllerProvider.notifier).submit(

          facts: _facts.text.trim(),

          wins: _wins.text.trim(),

          problems: _problems.text.trim(),

          projects: _projects.text.trim(),

          learning: _learning.text.trim(),

          nextWeek: _nextWeek.text.trim(),

        );

    if (mounted) Navigator.of(context).maybePop();

  }



  @override

  Widget build(BuildContext context) {

    final loading = ref.watch(weeklyReviewControllerProvider).isLoading;

    final existing = ref.watch(currentWeekWeeklyReviewProvider);

    existing.whenData(_populateFromReview);



    return Scaffold(

      appBar: AppBar(title: const Text(AppStrings.weeklyReview)),

      body: existing.when(

        loading: () => const Center(child: CircularProgressIndicator()),

        error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),

        data: (_) => SingleChildScrollView(

          padding: const EdgeInsets.all(ColonySpacing.lg),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              Text(AppStrings.weeklyReviewIntro),

              const SizedBox(height: ColonySpacing.md),

              OutlinedButton.icon(
                onPressed: () => showNarrativeDigestSheet(context),
                icon: const Icon(Icons.auto_stories_outlined),
                label: const Text(AppStrings.narrativeDigestAction),
              ),

              const SizedBox(height: ColonySpacing.lg),

              _field(AppStrings.reviewFacts, _facts),

              _field(AppStrings.reviewWins, _wins),

              _field(AppStrings.reviewProblems, _problems),

              _field(AppStrings.reviewProjects, _projects),

              _field(AppStrings.reviewLearning, _learning),

              _field(AppStrings.reviewNextWeek, _nextWeek),

              const SizedBox(height: ColonySpacing.xl),

              FilledButton(

                onPressed: loading ? null : _save,

                child: Text(loading ? AppStrings.loading : AppStrings.save),

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _field(String label, TextEditingController controller) {

    return Padding(

      padding: const EdgeInsets.only(bottom: ColonySpacing.lg),

      child: TextField(

        controller: controller,

        decoration: InputDecoration(labelText: label),

        maxLines: 3,

      ),

    );

  }

}


