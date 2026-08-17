import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../storyteller/application/storyteller_providers.dart';
import '../../storyteller/presentation/narrative_digest_sheet.dart';

class ChronicleScreen extends ConsumerWidget {
  const ChronicleScreen({
    super.key,
    this.evidenceEventIds = const [],
    this.highlightEventId,
  });

  /// Event ids from digest evidence deep-link (`?eventIds=`).
  final List<String> evidenceEventIds;

  /// Primary id to emphasize (`?highlight=`).
  final String? highlightEventId;

  static List<String> parseEvidenceEventIds(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  static String chronicleEvidenceLocation({
    required Iterable<EntityId> evidenceEventIds,
    EntityId? highlightEventId,
  }) {
    final ids = evidenceEventIds.map((e) => e.value).join(',');
    final highlight = (highlightEventId ?? evidenceEventIds.first).value;
    return '/chronicle?eventIds=$ids&highlight=$highlight';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(timelineProvider);
    final digestAsync = ref.watch(weeklyNarrativeDigestProvider);
    final filterActive = evidenceEventIds.isNotEmpty;
    final highlightId = highlightEventId ??
        (evidenceEventIds.isEmpty ? null : evidenceEventIds.first);

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.chronicle,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: ColonySpacing.sm),
          Wrap(
            spacing: ColonySpacing.sm,
            runSpacing: ColonySpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ActionChip(
                avatar: const Icon(Icons.auto_stories_outlined, size: 18),
                label: Text(
                  digestAsync.maybeWhen(
                    data: (d) =>
                        AppStrings.narrativeDigestChipLabel(d.bullets.length),
                    orElse: () => AppStrings.narrativeDigestAction,
                  ),
                ),
                onPressed: () => showNarrativeDigestSheet(context),
              ),
              if (filterActive) ...[
                Chip(
                  label: Text(
                    AppStrings.chronicleEvidenceFilterActive(
                      evidenceEventIds.length,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/chronicle'),
                  child: const Text(AppStrings.chronicleClearEvidenceFilter),
                ),
              ],
            ],
          ),
          const SizedBox(height: ColonySpacing.md),
          Expanded(
            child: timeline.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
              data: (events) {
                final visible = filterActive
                    ? events
                        .where((e) => evidenceEventIds.contains(e.id.value))
                        .toList()
                    : events;
                if (events.isEmpty) {
                  return Center(child: Text(AppStrings.emptyTimeline));
                }
                if (filterActive && visible.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppStrings.chronicleEvidenceNotFound),
                        const SizedBox(height: ColonySpacing.sm),
                        TextButton(
                          onPressed: () => context.go('/chronicle'),
                          child: const Text(
                            AppStrings.chronicleClearEvidenceFilter,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final event = visible[index];
                    final isHighlight = highlightId == event.id.value;
                    return TimelineLetter(
                      key: ValueKey('chronicle-event-${event.id.value}'),
                      title: _eventTitle(event),
                      summary: _eventSummary(event),
                      timestamp: event.occurredAt,
                      severity: _severity(event),
                      sourceLabel: event.sourceType.name,
                      highlighted: isHighlight,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _eventTitle(DomainEvent event) {
    return switch (event.eventType) {
      EventType.captureCreated => 'Captura registrada',
      EventType.taskCreated => 'Tarefa criada',
      EventType.taskUpdated => 'Tarefa atualizada',
      EventType.taskStatusChanged => 'Status alterado',
      EventType.taskArchived => 'Tarefa arquivada',
      EventType.profileCreated => 'Colônia criada',
      EventType.exportCompleted => 'Exportação concluída',
      EventType.exportRestored => 'Backup restaurado',
      EventType.checkInRecorded => 'Check-in registrado',
      EventType.needReadingRecorded => 'Necessidade atualizada',
      EventType.dailyReviewCompleted => 'Revisão diária concluída',
      EventType.weeklyReviewCompleted => 'Revisão semanal concluída',
      EventType.questCreated => 'Missão criada',
      EventType.questUpdated => 'Missão atualizada',
      EventType.questAccepted => 'Missão aceita',
      EventType.questStatusChanged => 'Status da missão alterado',
      EventType.projectCreated => 'Projeto criado',
      EventType.projectUpdated => 'Projeto atualizado',
      EventType.decisionCreated => 'Decisão registrada',
      EventType.decisionUpdated => 'Decisão atualizada',
      EventType.decisionDeleted => 'Decisão excluída',
      EventType.researchNodeCreated => 'Nó de pesquisa criado',
      EventType.researchStatusChanged => 'Status da pesquisa alterado',
      EventType.researchSessionLogged => 'Sessão de aprendizado registrada',
      EventType.researchEvidenceCreated => 'Evidência de pesquisa adicionada',
      EventType.financialAccountCreated => 'Conta financeira criada',
      EventType.financialAccountUpdated => 'Conta financeira atualizada',
      EventType.transactionCreated => 'Transação registrada',
      EventType.transactionUpdated => 'Transação atualizada',
      EventType.transactionDeleted => 'Transação excluída',
      EventType.categoryBudgetCreated => 'Orçamento criado',
      EventType.categoryBudgetUpdated => 'Orçamento atualizado',
      EventType.categoryBudgetDeleted => 'Orçamento excluído',
      EventType.scheduleBlockCreated => 'Bloco de agenda criado',
      EventType.scheduleBlockUpdated => 'Bloco de agenda atualizado',
      EventType.scheduleBlockDeleted => 'Bloco de agenda excluído',
      EventType.inventoryItemCreated => 'Item de inventário criado',
      EventType.inventoryItemUpdated => 'Item de inventário atualizado',
      EventType.inventoryItemStatusChanged =>
        'Status do inventário alterado',
      EventType.personCreated => 'Pessoa registrada',
      EventType.personUpdated => 'Pessoa atualizada',
      EventType.personArchived => 'Pessoa arquivada',
      EventType.personInteractionLogged => 'Interação registrada',
      EventType.tripCreated => 'Viagem criada',
      EventType.tripUpdated => 'Viagem atualizada',
      EventType.tripStatusChanged => 'Status da viagem alterado',
      EventType.organizationCreated => 'Organização registrada',
      EventType.organizationUpdated => 'Organização atualizada',
      EventType.organizationArchived => 'Organização arquivada',
      EventType.commitmentCreated => 'Compromisso registrado',
      EventType.commitmentUpdated => 'Compromisso atualizado',
      EventType.commitmentStatusChanged => 'Status do compromisso alterado',
      EventType.syncOperationEnqueued => 'Operação na outbox',
      EventType.syncOperationAcked => 'Outbox processada localmente',
      EventType.deviceIdentityEnsured => 'Dispositivo local registrado',
      EventType.contextZoneCreated => 'Zona registrada',
      EventType.contextZoneUpdated => 'Zona atualizada',
      EventType.contextZoneArchived => 'Zona arquivada',
      EventType.integrationConsentGranted => 'Integração ativada',
      EventType.integrationConsentRevoked => 'Integração desativada',
      EventType.externalCalendarEventsImported => 'Eventos ICS importados',
      EventType.healthAppointmentCreated => 'Consulta registrada',
      EventType.healthAppointmentUpdated => 'Consulta atualizada',
      EventType.knowledgeAreaCreated => 'Área de conhecimento criada',
      EventType.knowledgeAreaUpdated => 'Área de conhecimento atualizada',
      EventType.flashcardDeckCreated => 'Baralho criado',
      EventType.flashcardDeckUpdated => 'Baralho atualizado',
      EventType.flashcardCreated => 'Flashcard criado',
      EventType.flashcardUpdated => 'Flashcard atualizado',
      EventType.flashcardReviewed => 'Flashcard revisado',
      EventType.flashcardPracticed => 'Flashcard praticado',
      EventType.flashcardScheduled => 'Flashcard programado',
      EventType.flashcardUnscheduled => 'Flashcard guardado',
      EventType.flashcardCatalogSeeded => 'Mapa de conhecimento semeado',
      EventType.knowledgeAreaPlacementAdded => 'Área colocada em outra prateleira',
      EventType.knowledgeAreaPlacementRemoved => 'Colocação de área removida',
      EventType.researchKnowledgeLinked => 'Pesquisa ligada à área',
      EventType.researchKnowledgeUnlinked => 'Pesquisa desligada da área',
      _ => event.eventType.name,
    };
  }

  String _eventSummary(DomainEvent event) {
    final title = event.payload['title'];
    if (title is String) return title;
    final status = event.payload['status'];
    if (status is String) return 'Status: $status';
    return event.aggregateType.name;
  }

  TimelineLetterSeverity _severity(DomainEvent event) {
    return switch (event.eventType) {
      EventType.taskArchived => TimelineLetterSeverity.attention,
      EventType.exportCompleted => TimelineLetterSeverity.info,
      _ => TimelineLetterSeverity.info,
    };
  }
}
