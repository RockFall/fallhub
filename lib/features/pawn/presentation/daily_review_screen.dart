import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../flashcards/application/flashcard_providers.dart';
import '../../flashcards/presentation/widgets/flashcard_due_hero.dart';
import '../application/pawn_controllers.dart';
import '../application/pawn_providers.dart';

class DailyReviewScreen extends ConsumerStatefulWidget {
  const DailyReviewScreen({super.key});

  @override
  ConsumerState<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends ConsumerState<DailyReviewScreen> {
  final _happened = TextEditingController();
  final _current = TextEditingController();
  final _tomorrow = TextEditingController();
  final _correction = TextEditingController();
  var _loaded = false;

  @override
  void dispose() {
    _happened.dispose();
    _current.dispose();
    _tomorrow.dispose();
    _correction.dispose();
    super.dispose();
  }

  void _populateFromReview(DailyReview? review) {
    if (review == null || _loaded) return;
    _happened.text = review.whatHappened ?? '';
    _current.text = review.currentState ?? '';
    _tomorrow.text = review.tomorrowCommitments ?? '';
    _correction.text = review.routeCorrection ?? '';
    _loaded = true;
  }

  Future<void> _save() async {
    await ref.read(dailyReviewControllerProvider.notifier).submit(
          whatHappened: _happened.text.trim(),
          currentState: _current.text.trim(),
          tomorrowCommitments: _tomorrow.text.trim(),
          routeCorrection: _correction.text.trim(),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(dailyReviewControllerProvider).isLoading;
    final existing = ref.watch(todayDailyReviewProvider);
    existing.whenData(_populateFromReview);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.dailyReview)),
      body: existing.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(ColonySpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppStrings.dailyReviewIntro),
              const SizedBox(height: ColonySpacing.lg),
              FlashcardDueHero(
                digest: ref.watch(flashcardTodayDigestProvider),
                onStudy: () => context.go('/flashcards/study'),
                onPractice: () =>
                    context.go('/flashcards/study?mode=practice&saved=1'),
                onLater: () => context.go('/flashcards/study?later=1'),
              ),
              const SizedBox(height: ColonySpacing.lg),
              _field(AppStrings.reviewWhatHappened, _happened),
              _field(AppStrings.reviewCurrentState, _current),
              _field(AppStrings.reviewTomorrow, _tomorrow),
              _field(AppStrings.reviewCorrection, _correction),
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
