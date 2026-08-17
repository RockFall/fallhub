import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../application/flashcard_controllers.dart';
import '../application/flashcard_providers.dart';

class StudySessionScreen extends ConsumerStatefulWidget {
  const StudySessionScreen({
    super.key,
    this.deckId,
    this.areaId,
    this.cardId,
    this.mode = FlashcardStudySessionMode.scheduled,
  });

  final String? deckId;
  final String? areaId;
  final String? cardId;
  final FlashcardStudySessionMode mode;

  @override
  ConsumerState<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends ConsumerState<StudySessionScreen> {
  List<StudyCard>? _queue;
  var _index = 0;
  var _revealed = false;
  DateTime? _shownAt;
  FlashcardReviewOutcome? _lastOutcome;
  FlashcardReviewLog? _lastPractice;

  bool get _isPractice => widget.mode == FlashcardStudySessionMode.practice;

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(flashcardsProvider);
    final srsAsync = ref.watch(flashcardSrsProvider);
    final decks = ref.watch(flashcardDecksProvider).asData?.value ?? const [];
    final cards = cardsAsync.asData?.value;
    final srs = srsAsync.asData?.value;

    if (cards == null || srs == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_queue == null && cards.isNotEmpty) {
      _queue = _buildQueue(cards, srs, decks);
    } else if (_queue == null &&
        ref.watch(profileProvider).asData?.value != null) {
      _queue = const [];
    } else if (_queue == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final queue = _queue!;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _reveal,
        const SingleActivator(LogicalKeyboardKey.digit1): () =>
            _rate(FlashcardRating.again),
        const SingleActivator(LogicalKeyboardKey.digit2): () =>
            _rate(FlashcardRating.hard),
        const SingleActivator(LogicalKeyboardKey.digit3): () =>
            _rate(FlashcardRating.good),
        const SingleActivator(LogicalKeyboardKey.digit4): () =>
            _rate(FlashcardRating.easy),
      },
      child: Focus(
        autofocus: true,
        child: Padding(
          padding: const EdgeInsets.all(ColonySpacing.lg),
          child: queue.isEmpty || _index >= queue.length
              ? _Done(
                  practice: _isPractice,
                  onBack: () => context.go('/flashcards'),
                )
              : _StudyBody(
                  item: queue[_index],
                  current: _index + 1,
                  total: queue.length,
                  revealed: _revealed,
                  canUndo: _lastOutcome != null || _lastPractice != null,
                  practice: _isPractice,
                  onReveal: _reveal,
                  onRate: _rate,
                  onUndo: _undo,
                  onBury: _isPractice ? null : _bury,
                  onSuspend: _suspend,
                  onClose: () => context.go('/flashcards'),
                ),
        ),
      ),
    );
  }

  List<StudyCard> _buildQueue(
    List<Flashcard> cards,
    Map<EntityId, FlashcardSrsState> srs,
    List<FlashcardDeck> decks,
  ) {
    var filtered = cards;
    if (widget.deckId != null) {
      filtered = filtered.where((c) => c.deckId.value == widget.deckId).toList();
    }
    if (widget.areaId != null) {
      final areas = ref.read(knowledgeAreasProvider).asData?.value ?? const [];
      final placements =
          ref.read(knowledgePlacementsProvider).asData?.value ?? const [];
      final ids = KnowledgeAreaPolicy.descendantIds(
        rootId: EntityId(widget.areaId!),
        areas: areas,
        placements: placements,
      );
      filtered = filtered
          .where((c) => c.areaId != null && ids.contains(c.areaId))
          .toList();
    }
    if (widget.cardId != null) {
      filtered = filtered.where((c) => c.id.value == widget.cardId).toList();
    }
    if (_isPractice) {
      if (widget.cardId == null) {
        filtered = filtered
            .where((c) => c.scheduleMode == FlashcardScheduleMode.unscheduled)
            .toList();
      }
      return StudyQueuePolicy.buildPracticeQueue(
        cards: filtered,
        srsByCard: srs,
      );
    }

    final now = ref.read(clockProvider)();
    final logs = ref.read(flashcardLogsProvider).asData?.value ?? const [];
    final newUsed = FlashcardDailyUsagePolicy.newIntroducedByDeck(
      cards: cards,
      srsByCard: srs,
      logs: logs,
      now: now,
    );
    final reviewUsed = FlashcardDailyUsagePolicy.reviewRepsByDeck(
      cards: cards,
      logs: logs,
      now: now,
    );
    final deckById = {for (final deck in decks) deck.id: deck};
    final byDeck = <EntityId, List<Flashcard>>{};
    for (final card in filtered) {
      byDeck.putIfAbsent(card.deckId, () => []).add(card);
    }
    final queue = <StudyCard>[];
    for (final entry in byDeck.entries) {
      final deck = deckById[entry.key];
      queue.addAll(
        StudyQueuePolicy.buildQueue(
          cards: entry.value,
          srsByCard: srs,
          now: now,
          newRemaining: (deck?.newLimitPerDay ?? 20) - (newUsed[entry.key] ?? 0),
          reviewRemaining:
              (deck?.reviewLimitPerDay ?? 200) - (reviewUsed[entry.key] ?? 0),
          interleaveByArea: widget.deckId == null,
        ),
      );
    }
    return queue;
  }

  void _reveal() {
    if (_revealed) return;
    setState(() {
      _revealed = true;
      _shownAt ??= DateTime.now();
    });
  }

  Future<void> _rate(FlashcardRating rating) async {
    final queue = _queue;
    if (queue == null || _index >= queue.length || !_revealed) return;
    final item = queue[_index];
    final duration = _shownAt == null
        ? null
        : DateTime.now().difference(_shownAt!).inMilliseconds;
    if (_isPractice) {
      final log = await ref.read(flashcardControllerProvider.notifier).practice(
            card: item.card,
            rating: rating,
            durationMs: duration,
          );
      if (!mounted) return;
      setState(() {
        _lastPractice = log;
        _lastOutcome = null;
        _index += 1;
        _revealed = false;
        _shownAt = null;
      });
      return;
    }
    final outcome = await ref.read(flashcardControllerProvider.notifier).review(
          card: item.card,
          rating: rating,
          durationMs: duration,
        );
    if (!mounted) return;
    if (outcome?.becameLeech == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.flashcardsLeech)),
      );
    }
    setState(() {
      _lastOutcome = outcome;
      _lastPractice = null;
      _index += 1;
      _revealed = false;
      _shownAt = null;
    });
  }

  Future<void> _undo() async {
    if (_lastPractice != null) {
      await ref
          .read(flashcardControllerProvider.notifier)
          .undoPractice(_lastPractice!);
      if (!mounted) return;
      setState(() {
        _lastPractice = null;
        _index = (_index - 1).clamp(0, _index);
        _revealed = false;
      });
      return;
    }
    final outcome = _lastOutcome;
    if (outcome == null) return;
    await ref.read(flashcardControllerProvider.notifier).undoReview(outcome);
    if (!mounted) return;
    setState(() {
      _lastOutcome = null;
      _index = (_index - 1).clamp(0, _index);
      _revealed = false;
    });
  }

  Future<void> _bury() async {
    final queue = _queue;
    if (queue == null || _index >= queue.length) return;
    await ref.read(flashcardControllerProvider.notifier).bury(queue[_index].card);
    if (!mounted) return;
    setState(() {
      _index += 1;
      _revealed = false;
    });
  }

  Future<void> _suspend() async {
    final queue = _queue;
    if (queue == null || _index >= queue.length) return;
    await ref
        .read(flashcardControllerProvider.notifier)
        .setSuspended(queue[_index].card, true);
    if (!mounted) return;
    setState(() {
      _index += 1;
      _revealed = false;
    });
  }
}

class _StudyBody extends StatelessWidget {
  const _StudyBody({
    required this.item,
    required this.current,
    required this.total,
    required this.revealed,
    required this.canUndo,
    required this.practice,
    required this.onReveal,
    required this.onRate,
    required this.onUndo,
    required this.onBury,
    required this.onSuspend,
    required this.onClose,
  });

  final StudyCard item;
  final int current;
  final int total;
  final bool revealed;
  final bool canUndo;
  final bool practice;
  final VoidCallback onReveal;
  final ValueChanged<FlashcardRating> onRate;
  final VoidCallback onUndo;
  final VoidCallback? onBury;
  final VoidCallback onSuspend;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final previews = Sm2Scheduler.previewIntervals(
      state: item.srs,
      now: DateTime.now().toUtc(),
    );
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: AppStrings.flashcardsBackToHub,
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
            Expanded(
              child: LinearProgressIndicator(value: current / total),
            ),
            const SizedBox(width: ColonySpacing.sm),
            Text(AppStrings.flashcardsProgress(current, total)),
            PopupMenuButton<String>(
              tooltip: AppStrings.flashcardsMoreActions,
              onSelected: (value) {
                switch (value) {
                  case 'undo':
                    onUndo();
                  case 'bury':
                    onBury?.call();
                  case 'suspend':
                    onSuspend();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'undo',
                  enabled: canUndo,
                  child: const Text(AppStrings.flashcardsUndo),
                ),
                if (onBury != null)
                  const PopupMenuItem(
                    value: 'bury',
                    child: Text(AppStrings.flashcardsBury),
                  ),
                const PopupMenuItem(
                  value: 'suspend',
                  child: Text(AppStrings.flashcardsSuspend),
                ),
              ],
            ),
          ],
        ),
        if (practice)
          Padding(
            padding: const EdgeInsets.only(top: ColonySpacing.xs),
            child: Text(
              AppStrings.flashcardsPracticeSession,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: ColonyColors.accentCyan,
                  ),
            ),
          ),
        const SizedBox(height: ColonySpacing.lg),
        Expanded(
          child: GestureDetector(
            onTap: revealed ? null : onReveal,
            child: ColonySurface(
              child: Padding(
                padding: const EdgeInsets.all(ColonySpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.prompt,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: ColonySpacing.xl),
                    if (!revealed)
                      Text(
                        AppStrings.flashcardsReveal,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ColonyColors.textMuted,
                            ),
                      )
                    else ...[
                      Text(
                        item.answer,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: ColonyColors.accentCyan,
                              height: 1.4,
                            ),
                      ),
                      if (item.extra != null) ...[
                        const SizedBox(height: ColonySpacing.md),
                        Text(
                          item.extra!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: ColonySpacing.md),
        if (!revealed)
          const SizedBox(height: 72)
        else
          Row(
            children: [
              _RateButton(
                label: AppStrings.flashcardsAgain,
                interval: practice ? null : previews[FlashcardRating.again],
                color: ColonyColors.statusCritical,
                onPressed: () => onRate(FlashcardRating.again),
              ),
              _RateButton(
                label: AppStrings.flashcardsHard,
                interval: practice ? null : previews[FlashcardRating.hard],
                color: ColonyColors.statusAttention,
                onPressed: () => onRate(FlashcardRating.hard),
              ),
              _RateButton(
                label: AppStrings.flashcardsGood,
                interval: practice ? null : previews[FlashcardRating.good],
                color: ColonyColors.statusGood,
                onPressed: () => onRate(FlashcardRating.good),
              ),
              _RateButton(
                label: AppStrings.flashcardsEasy,
                interval: practice ? null : previews[FlashcardRating.easy],
                color: ColonyColors.accentCyan,
                onPressed: () => onRate(FlashcardRating.easy),
              ),
            ],
          ),
        if (!isMobile || kIsWeb) ...[
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.flashcardsKeyboardHint,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ColonyColors.textMuted,
                ),
          ),
        ],
      ],
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.interval,
  });

  final String label;
  final Duration? interval;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.18),
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: onPressed,
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (interval != null)
                Text(
                  Sm2Scheduler.formatInterval(interval!),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.onBack, required this.practice});

  final VoidCallback onBack;
  final bool practice;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: ColonyColors.statusGood),
          const SizedBox(height: ColonySpacing.md),
          Text(
            practice ? AppStrings.flashcardsPracticeDone : AppStrings.flashcardsDone,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            practice
                ? AppStrings.flashcardsPracticeDoneHint
                : AppStrings.flashcardsDoneHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: ColonySpacing.lg),
          FilledButton(
            onPressed: onBack,
            child: const Text(AppStrings.flashcardsBackToHub),
          ),
        ],
      ),
    );
  }
}
