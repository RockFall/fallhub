import 'dart:convert';

import 'flashcard.dart';
import 'flashcard_tag.dart';
import 'id_generator.dart';
import 'knowledge_area.dart';
import 'knowledge_area_catalog.dart';
import 'knowledge_area_placement.dart';

class FlashcardJsonException implements Exception {
  FlashcardJsonException(this.message);
  final String message;

  @override
  String toString() => message;
}

class FlashcardJsonCard {
  const FlashcardJsonCard({
    required this.front,
    required this.back,
    required this.kind,
    required this.deckTitle,
    this.areaPath = const [],
    this.alsoIn = const [],
    this.extra,
    this.tags = const [],
    this.scheduleMode = FlashcardScheduleMode.scheduled,
    this.bidirectional = false,
  });

  final String front;
  final String back;
  final FlashcardKind kind;
  final String deckTitle;
  final List<String> areaPath;
  final List<List<String>> alsoIn;
  final String? extra;
  final List<String> tags;
  final FlashcardScheduleMode scheduleMode;
  final bool bidirectional;
}

class FlashcardJsonDocument {
  const FlashcardJsonDocument({required this.cards, this.version = 1});

  final int version;
  final List<FlashcardJsonCard> cards;
}

enum FlashcardJsonCardActionKind { create, skip, overwrite }

class FlashcardJsonAreaStep {
  const FlashcardJsonAreaStep({
    required this.path,
    this.existingId,
    this.catalogKey,
    this.description,
  });

  final List<String> path;
  final EntityId? existingId;
  final String? catalogKey;
  final String? description;

  String get title => path.last;
  List<String> get parentPath =>
      path.length <= 1 ? const [] : path.sublist(0, path.length - 1);
}

class FlashcardJsonDeckStep {
  const FlashcardJsonDeckStep({
    required this.title,
    this.existingId,
    this.areaPath = const [],
  });

  final String title;
  final EntityId? existingId;
  final List<String> areaPath;
}

class FlashcardJsonPlacementStep {
  const FlashcardJsonPlacementStep({
    required this.areaPath,
    required this.parentPath,
  });

  final List<String> areaPath;
  final List<String> parentPath;
}

class FlashcardJsonCardStep {
  const FlashcardJsonCardStep({
    required this.action,
    required this.card,
    this.existingIds = const [],
  });

  final FlashcardJsonCardActionKind action;
  final FlashcardJsonCard card;
  final List<EntityId> existingIds;
}

class FlashcardJsonImportPlan {
  const FlashcardJsonImportPlan({
    required this.areas,
    required this.decks,
    required this.placements,
    required this.cards,
  });

  final List<FlashcardJsonAreaStep> areas;
  final List<FlashcardJsonDeckStep> decks;
  final List<FlashcardJsonPlacementStep> placements;
  final List<FlashcardJsonCardStep> cards;

  int get createCount => cards
      .where((c) => c.action == FlashcardJsonCardActionKind.create)
      .length;
  int get skipCount =>
      cards.where((c) => c.action == FlashcardJsonCardActionKind.skip).length;
  int get overwriteCount => cards
      .where((c) => c.action == FlashcardJsonCardActionKind.overwrite)
      .length;
  int get newAreaCount => areas.where((a) => a.existingId == null).length;
  int get newDeckCount => decks.where((d) => d.existingId == null).length;
}

class FlashcardJsonImportResult {
  const FlashcardJsonImportResult({
    required this.createdCards,
    required this.skippedCards,
    required this.overwrittenCards,
    required this.createdAreas,
    required this.createdDecks,
  });

  final int createdCards;
  final int skippedCards;
  final int overwrittenCards;
  final int createdAreas;
  final int createdDecks;
}

abstract final class FlashcardJsonCodec {
  static const defaultDeckTitle = 'Importação';

  static FlashcardJsonDocument parse(String source) {
    final raw = jsonDecode(_extractJson(source));
    if (raw is List) {
      return FlashcardJsonDocument(
        cards: [
          for (final item in raw) _parseCard(item, fallbackDeck: defaultDeckTitle),
        ],
      );
    }
    if (raw is! Map) {
      throw FlashcardJsonException('O JSON deve ser um objeto ou uma lista.');
    }
    final map = _asStringKeyMap(raw);
    final version = map['version'] is num ? (map['version'] as num).toInt() : 1;
    final cards = <FlashcardJsonCard>[];
    final defaultDeck = _readString(map['deck']) ??
        _readString(map['deckTitle']) ??
        defaultDeckTitle;
    final defaultPath = parsePath(map['areaPath']);

    final decksRaw = map['decks'];
    if (decksRaw is List) {
      for (final item in decksRaw) {
        if (item is! Map) continue;
        final deck = _asStringKeyMap(item);
        final title = _readString(deck['title']) ??
            _readString(deck['name']) ??
            defaultDeck;
        final deckPath = parsePath(deck['areaPath']);
        final nested = deck['cards'];
        if (nested is! List) continue;
        for (final card in nested) {
          cards.add(
            _parseCard(
              card,
              fallbackDeck: title,
              fallbackPath: deckPath.isEmpty ? defaultPath : deckPath,
            ),
          );
        }
      }
    }

    final cardsRaw = map['cards'];
    if (cardsRaw is List) {
      for (final item in cardsRaw) {
        cards.add(
          _parseCard(
            item,
            fallbackDeck: defaultDeck,
            fallbackPath: defaultPath,
          ),
        );
      }
    }

    if (cards.isEmpty) {
      throw FlashcardJsonException('Nenhum cartão encontrado no JSON.');
    }
    return FlashcardJsonDocument(version: version, cards: cards);
  }

  static List<String> parsePath(Object? raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return [
        for (final item in raw)
          if (item != null && item.toString().trim().isNotEmpty)
            item.toString().trim(),
      ];
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return const [];
    return [
      for (final part in text.split(RegExp(r'\s*(?:>|/|·|,)\s*')))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }

  static String normalizeText(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String cardIdentity(String front, FlashcardKind kind) =>
      '${kind.name}\u0001${normalizeText(front)}';

  static FlashcardJsonCard _parseCard(
    Object? raw, {
    required String fallbackDeck,
    List<String> fallbackPath = const [],
  }) {
    if (raw is! Map) {
      throw FlashcardJsonException('Cada cartão deve ser um objeto JSON.');
    }
    final map = _asStringKeyMap(raw);
    final front = _readString(map['front']) ?? _readString(map['frente']) ?? '';
    final back = _readString(map['back']) ??
        _readString(map['verso']) ??
        _readString(map['answer']) ??
        '';
    if (front.trim().isEmpty) {
      throw FlashcardJsonException('Cartão sem frente (front).');
    }
    final kind = parseKind(map['kind'] ?? map['tipo']);
    if (kind != FlashcardKind.freeRecall &&
        kind != FlashcardKind.cloze &&
        back.trim().isEmpty) {
      throw FlashcardJsonException('Cartão "$front" sem verso (back).');
    }
    if (kind == FlashcardKind.cloze &&
        ClozeRenderer.indicesIn(front).isEmpty) {
      throw FlashcardJsonException(
        'Cartão cloze precisa de {{c1::texto}} na frente.',
      );
    }
    final deck = _readString(map['deck']) ??
        _readString(map['deckTitle']) ??
        fallbackDeck;
    final path = parsePath(map['areaPath']);
    final also = <List<String>>[];
    final alsoRaw = map['alsoIn'] ?? map['also_in'];
    if (alsoRaw is List) {
      for (final item in alsoRaw) {
        final extraPath = parsePath(item);
        if (extraPath.isNotEmpty) also.add(extraPath);
      }
    }
    final tagsRaw = map['tags'];
    final tags = <String>[
      if (tagsRaw is List)
        for (final tag in tagsRaw)
          if (tag != null && tag.toString().trim().isNotEmpty)
            tag.toString().trim(),
      if (tagsRaw is String && tagsRaw.trim().isNotEmpty)
        for (final tag in tagsRaw.split(','))
          if (tag.trim().isNotEmpty) tag.trim(),
    ];
    return FlashcardJsonCard(
      front: front.trim(),
      back: back.trim(),
      kind: kind,
      deckTitle: deck.trim().isEmpty ? fallbackDeck : deck.trim(),
      areaPath: path.isEmpty ? fallbackPath : path,
      alsoIn: also,
      extra: _readString(map['extra']),
      tags: tags,
      scheduleMode: parseSchedule(map['schedule'] ?? map['scheduleMode']),
      bidirectional: map['bidirectional'] == true ||
          map['inverso'] == true ||
          kind == FlashcardKind.reverse,
    );
  }

  static FlashcardKind parseKind(Object? raw) {
    final value = raw?.toString().trim().toLowerCase() ?? '';
    return switch (value) {
      '' || 'basic' || 'basico' || 'básico' => FlashcardKind.basic,
      'reverse' || 'inverso' => FlashcardKind.reverse,
      'cloze' || 'lacuna' => FlashcardKind.cloze,
      'freerecall' ||
      'free_recall' ||
      'recordacao' ||
      'recordação' ||
      'recordação livre' =>
        FlashcardKind.freeRecall,
      'exercise' || 'exercicio' || 'exercício' => FlashcardKind.exercise,
      'repertoire' || 'repertorio' || 'repertório' => FlashcardKind.repertoire,
      _ => throw FlashcardJsonException('Tipo de cartão desconhecido: $raw'),
    };
  }

  static FlashcardScheduleMode parseSchedule(Object? raw) {
    final value = raw?.toString().trim().toLowerCase() ?? '';
    return switch (value) {
      '' || 'scheduled' || 'programado' || 'srs' =>
        FlashcardScheduleMode.scheduled,
      'unscheduled' || 'guardado' || 'saved' =>
        FlashcardScheduleMode.unscheduled,
      _ => throw FlashcardJsonException('Agenda desconhecida: $raw'),
    };
  }

  static String _extractJson(String source) {
    var text = source.trim();
    if (text.isEmpty) {
      throw FlashcardJsonException('JSON vazio.');
    }
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', caseSensitive: false);
    final fenced = fence.firstMatch(text);
    if (fenced != null) {
      text = fenced.group(1)!.trim();
    }
    final obj = text.indexOf('{');
    final arr = text.indexOf('[');
    if (obj < 0 && arr < 0) {
      throw FlashcardJsonException('Não encontrei um objeto ou lista JSON.');
    }
    final start = obj < 0
        ? arr
        : arr < 0
            ? obj
            : (obj < arr ? obj : arr);
    return text.substring(start);
  }

  static Map<String, dynamic> _asStringKeyMap(Map raw) {
    return {
      for (final entry in raw.entries) entry.key.toString(): entry.value,
    };
  }

  static String? _readString(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text.trim().isEmpty ? null : text;
  }
}

abstract final class FlashcardJsonImportPolicy {
  static FlashcardJsonImportPlan plan({
    required FlashcardJsonDocument document,
    required List<KnowledgeArea> areas,
    required List<FlashcardDeck> decks,
    required List<Flashcard> cards,
    List<KnowledgeAreaPlacement> placements = const [],
  }) {
    final areaSteps = <String, FlashcardJsonAreaStep>{};
    final deckSteps = <String, FlashcardJsonDeckStep>{};
    final placementSteps = <FlashcardJsonPlacementStep>[];
    final cardSteps = <FlashcardJsonCardStep>[];
    final latestBackByKey = <String, String>{};
    final createIndexByKey = <String, int>{};

    void collectPath(List<String> path) {
      if (path.isEmpty) return;
      KnowledgeCatalogEntry? catalogNode;
      EntityId? parentId;
      final walked = <String>[];
      for (final title in path) {
        walked.add(title);
        final key = pathKey(walked);
        catalogNode = KnowledgeAreaCatalog.childNamed(catalogNode, title);
        if (areaSteps.containsKey(key)) {
          parentId = areaSteps[key]!.existingId;
          continue;
        }
        final parentKey = walked.length == 1
            ? null
            : pathKey(walked.sublist(0, walked.length - 1));
        final parentStep = parentKey == null ? null : areaSteps[parentKey];
        final existing = parentStep != null && parentStep.existingId == null
            ? null
            : KnowledgeAreaPolicy.childNamed(
                parentId: parentId,
                title: title,
                areas: areas,
                placements: placements,
              );
        areaSteps[key] = FlashcardJsonAreaStep(
          path: List<String>.from(walked),
          existingId: existing?.id,
          catalogKey: existing?.catalogKey ?? catalogNode?.key,
          description: catalogNode?.description,
        );
        parentId = existing?.id;
      }
    }

    for (final card in document.cards) {
      collectPath(card.areaPath);
      for (final extra in card.alsoIn) {
        collectPath(extra);
        if (card.areaPath.isNotEmpty && extra.isNotEmpty) {
          placementSteps.add(
            FlashcardJsonPlacementStep(
              areaPath: card.areaPath,
              parentPath: extra,
            ),
          );
        }
      }
      final deckKey = FlashcardJsonCodec.normalizeText(card.deckTitle);
      deckSteps.putIfAbsent(
        deckKey,
        () => FlashcardJsonDeckStep(
          title: card.deckTitle,
          existingId: _deckByTitle(decks, card.deckTitle)?.id,
          areaPath: card.areaPath,
        ),
      );
      final deck = _deckByTitle(decks, card.deckTitle);
      final identity = FlashcardJsonCodec.cardIdentity(card.front, card.kind);
      final batchKey = '$deckKey\u0001$identity';
      final matches = deck == null
          ? const <Flashcard>[]
          : [
              for (final existing in cards)
                if (existing.deckId == deck.id &&
                    existing.reverseOfId == null &&
                    FlashcardJsonCodec.cardIdentity(
                          existing.front,
                          existing.kind,
                        ) ==
                        identity)
                  existing,
            ];
      final incomingBack = FlashcardJsonCodec.normalizeText(card.back);
      if (matches.isNotEmpty) {
        final sameAnswer = matches.every(
          (existing) =>
              FlashcardJsonCodec.normalizeText(existing.back) == incomingBack,
        );
        cardSteps.add(
          FlashcardJsonCardStep(
            action: sameAnswer
                ? FlashcardJsonCardActionKind.skip
                : FlashcardJsonCardActionKind.overwrite,
            card: card,
            existingIds: [for (final match in matches) match.id],
          ),
        );
        latestBackByKey[batchKey] = incomingBack;
        continue;
      }
      final previousIndex = createIndexByKey[batchKey];
      if (previousIndex != null) {
        if (latestBackByKey[batchKey] != incomingBack) {
          cardSteps[previousIndex] = FlashcardJsonCardStep(
            action: FlashcardJsonCardActionKind.create,
            card: card,
          );
          latestBackByKey[batchKey] = incomingBack;
        }
        cardSteps.add(
          FlashcardJsonCardStep(
            action: FlashcardJsonCardActionKind.skip,
            card: card,
          ),
        );
        continue;
      }
      createIndexByKey[batchKey] = cardSteps.length;
      latestBackByKey[batchKey] = incomingBack;
      cardSteps.add(
        FlashcardJsonCardStep(
          action: FlashcardJsonCardActionKind.create,
          card: card,
        ),
      );
    }

    final orderedAreas = areaSteps.values.toList()
      ..sort((a, b) => a.path.length.compareTo(b.path.length));
    return FlashcardJsonImportPlan(
      areas: orderedAreas,
      decks: deckSteps.values.toList(),
      placements: placementSteps,
      cards: cardSteps,
    );
  }

  static FlashcardDeck? _deckByTitle(List<FlashcardDeck> decks, String title) {
    final needle = FlashcardJsonCodec.normalizeText(title);
    for (final deck in decks) {
      if (deck.isArchived) continue;
      if (FlashcardJsonCodec.normalizeText(deck.title) == needle) return deck;
    }
    return null;
  }

  static String pathKey(List<String> path) => [
        for (final part in path) FlashcardJsonCodec.normalizeText(part),
      ].join('\u0001');
}

abstract final class FlashcardJsonPromptBuilder {
  static String build({
    required List<KnowledgeArea> areas,
    List<KnowledgeAreaPlacement> placements = const [],
    List<FlashcardDeck> decks = const [],
    List<FlashcardTag> tags = const [],
  }) {
    final buffer = StringBuffer()
      ..writeln(
        'Você formata flashcards para o app Life Colony OS (local-first).',
      )
      ..writeln(
        'Responda APENAS com JSON válido (sem markdown, sem comentário).',
      )
      ..writeln(
        'O app importa o JSON, cria prateleiras/baralhos que faltarem,',
      )
      ..writeln(
        'ignora cartões idênticos e substitui o verso se a pergunta já existir',
      )
      ..writeln('no mesmo baralho com resposta diferente. O SRS não é resetado no overwrite.')
      ..writeln()
      ..writeln('SCHEMA')
      ..writeln('{')
      ..writeln('  "version": 1,')
      ..writeln('  "cards": [')
      ..writeln('    {')
      ..writeln('      "front": "pergunta ou prompt (obrigatório)",')
      ..writeln('      "back": "resposta (obrigatório, salvo cloze/recordação livre)",')
      ..writeln(
        '      "kind": "basic|reverse|cloze|freeRecall|exercise|repertoire",',
      )
      ..writeln('      "deck": "nome do baralho (reutiliza se já existir)",')
      ..writeln(
        '      "areaPath": ["Raiz", "Filho", "Folha"],',
      )
      ..writeln(
        '      "alsoIn": [["Outra raiz", "Outra folha"]],',
      )
      ..writeln('      "extra": "nota opcional no verso",')
      ..writeln(
        '      "tags": ["Jazz", "Música / Harmonia"],',
      )
      ..writeln('      "schedule": "scheduled|unscheduled",')
      ..writeln('      "bidirectional": false')
      ..writeln('    }')
      ..writeln('  ]')
      ..writeln('}')
      ..writeln()
      ..writeln('CAMPOS')
      ..writeln(
        '- front: texto da frente. Cloze usa {{c1::lacuna}} (pode haver c2, c3…).',
      )
      ..writeln('- back: verso. Em cloze pode repetir o texto completo.')
      ..writeln(
        '- kind: basic (padrão), reverse (par invertido), cloze, freeRecall, exercise, repertoire.',
      )
      ..writeln(
        '- deck: agrupa os cartões. Se o nome já existir (ignora maiúsculas), reutiliza.',
      )
      ..writeln(
        '- areaPath: categorias da raiz até a folha. Cada segmento inexistente é CRIADO.',
      )
      ..writeln(
        '- alsoIn: caminhos extra (o mesmo tópico em outra prateleira, ex. Tropicalismo).',
      )
      ..writeln(
        '- tags: etiquetas flexíveis, independentes do mapa. Um cartão pode ter várias.',
      )
      ..writeln(
        '  Cada item pode ser um nome ("Jazz") ou um caminho de subtags ("Música / Harmonia").',
      )
      ..writeln(
        '  Segmentos inexistentes são CRIADOS. Estudar a tag pai inclui as subtags.',
      )
      ..writeln(
        '- schedule: scheduled = entra na fila SM-2; unscheduled = só prática pontual.',
      )
      ..writeln(
        '- bidirectional: true cria o cartão invertido (frente↔verso) com SRS separado.',
      )
      ..writeln()
      ..writeln('LIBERDADE DE CRIAR CATEGORIAS')
      ..writeln(
        'Pode inventar ramos novos quando o assunto não couber nos existentes.',
      )
      ..writeln(
        'Prefira reutilizar um título já listado abaixo (mesma grafia) para não duplicar a prateleira.',
      )
      ..writeln(
        'Se o caminho coincidir com o catálogo canónico do app, a prateleira oficial é ativada.',
      )
      ..writeln();

    if (areas.isEmpty) {
      buffer.writeln(
        'MAPA ATUAL: ainda não há categorias. Crie a árvore inteira via areaPath.',
      );
    } else {
      buffer.writeln('CATEGORIAS JÁ EXISTENTES (use estes nomes em areaPath):');
      final forest = KnowledgeAreaPolicy.buildForest(areas);
      void walk(KnowledgeAreaNode node, String indent) {
        final extras = KnowledgeAreaPolicy.extraParentsOf(
          areaId: node.area.id,
          areas: areas,
          placements: placements,
        );
        final alias = extras.isEmpty
            ? ''
            : '  (também em: ${[
                for (final parent in extras)
                  KnowledgeAreaPolicy.pathLabel(areaId: parent.id, areas: areas),
              ].join('; ')})';
        buffer.writeln('$indent- ${node.area.title}$alias');
        for (final child in node.children) {
          walk(child, '$indent  ');
        }
      }

      for (final root in forest) {
        walk(root, '');
      }
    }

    final visibleDecks = [
      for (final deck in decks)
        if (!deck.isArchived) deck.title,
    ]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    buffer.writeln();
    if (visibleDecks.isEmpty) {
      buffer.writeln(
        'BARALHOS ATUAIS: nenhum. Invente um nome claro em "deck".',
      );
    } else {
      buffer
        ..writeln('BARALHOS JÁ EXISTENTES:')
        ..writeln(visibleDecks.map((title) => '- $title').join('\n'));
    }

    buffer.writeln();
    if (tags.isEmpty) {
      buffer.writeln(
        'TAGS ATUAIS: nenhuma. Invente nomes ou caminhos (ex. "Música / Harmonia").',
      );
    } else {
      buffer.writeln('TAGS JÁ EXISTENTES (reutilize a mesma grafia):');
      final forest = FlashcardTagPolicy.buildForest(tags);
      void walkTag(FlashcardTagNode node, String indent) {
        buffer.writeln('$indent- ${node.tag.title}');
        for (final child in node.children) {
          walkTag(child, '$indent  ');
        }
      }

      for (final root in forest) {
        walkTag(root, '');
      }
    }

    buffer
      ..writeln()
      ..writeln(
        'PRATELEIRAS CANÓNICAS (opcional; estes títulos ativam o catálogo):',
      );
    for (final path in KnowledgeAreaCatalog.labeledTitlePaths()) {
      buffer.writeln('- $path');
    }
    buffer
      ..writeln()
      ..writeln('REGRAS FINAIS')
      ..writeln('- Não invente campos extra.')
      ..writeln('- Não copie layout de outros apps de flashcard.')
      ..writeln('- Uma ideia por cartão; frente curta o bastante para estudar no telemóvel.')
      ..writeln('- JSON único, UTF-8.');
    return buffer.toString();
  }
}
