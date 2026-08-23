import 'activation_enums.dart';
import 'activation_models.dart';
import 'id_generator.dart';

class ActivationSeedSpec {
  const ActivationSeedSpec({
    required this.key,
    required this.name,
    required this.description,
    required this.type,
    required this.origin,
    required this.target,
    required this.commands,
    this.fallbackKey,
    this.contexts = const [],
  });

  final String key;
  final String name;
  final String description;
  final ActivationProtocolType type;
  final ActivationTransitionState origin;
  final ActivationTransitionState target;
  final List<ActivationSeedCommand> commands;
  final String? fallbackKey;
  final List<String> contexts;
}

class ActivationSeedCommand {
  const ActivationSeedCommand({
    required this.instruction,
    required this.verb,
    this.objectRef,
    this.destinationRef,
    this.skippable = true,
    this.estimatedSeconds = 60,
    this.splits = const [],
    this.isFirstMeaningfulAction = false,
    this.releasesOnConfirm = false,
    this.preferredProof = ActivationProofType.manualTap,
    this.deepLink,
  });

  final String instruction;
  final String verb;
  final String? objectRef;
  final String? destinationRef;
  final bool skippable;
  final int estimatedSeconds;
  final List<String> splits;
  final bool isFirstMeaningfulAction;
  final bool releasesOnConfirm;
  final ActivationProofType preferredProof;
  final String? deepLink;
}

/// Seeds editáveis, não afirmações clínicas (§78).
abstract final class ActivationProtocolSeeds {
  static const catalog = <ActivationSeedSpec>[
    ActivationSeedSpec(
      key: 'morning_launch_standard',
      name: 'Morning Launch — Standard',
      description: 'Rota da cama até a primeira ação, uma ordem por vez.',
      type: ActivationProtocolType.wakeUp,
      origin: ActivationTransitionState(
        label: 'Na cama, acordado',
        keys: ['bed', 'awake'],
      ),
      target: ActivationTransitionState(
        label: 'Primeira ação iniciada',
        keys: ['desk', 'first_action'],
      ),
      fallbackKey: 'morning_launch_minimal',
      contexts: ['morning'],
      commands: [
        ActivationSeedCommand(
          instruction: 'Coloque os dois pés no chão.',
          verb: 'Coloque',
          objectRef: 'feet',
          destinationRef: 'floor',
          estimatedSeconds: 20,
          splits: ['Sente-se na beira da cama.', 'Coloque um pé no chão.'],
        ),
        ActivationSeedCommand(
          instruction: 'Leve o telefone ao dock do banheiro.',
          verb: 'Leve',
          objectRef: 'phone',
          destinationRef: 'bathroom_dock',
          preferredProof: ActivationProofType.waypointQr,
          splits: [
            'Pegue o telefone.',
            'Caminhe até a porta do quarto.',
            'Deixe o telefone no dock.',
          ],
        ),
        ActivationSeedCommand(
          instruction: 'Abra o chuveiro.',
          verb: 'Abra',
          objectRef: 'shower',
          estimatedSeconds: 30,
        ),
        ActivationSeedCommand(
          instruction: 'Vista a roupa preparada.',
          verb: 'Vista',
          objectRef: 'clothes',
          estimatedSeconds: 90,
        ),
        ActivationSeedCommand(
          instruction: 'Beba um copo d\'água perto da luz.',
          verb: 'Beba',
          objectRef: 'water',
          destinationRef: 'window',
        ),
        ActivationSeedCommand(
          instruction: 'Sente-se no posto de trabalho.',
          verb: 'Sente-se',
          destinationRef: 'desk',
        ),
        ActivationSeedCommand(
          instruction: 'Abra a primeira ação já escolhida.',
          verb: 'Abra',
          isFirstMeaningfulAction: true,
          releasesOnConfirm: true,
          skippable: false,
          deepLink: '/inbox',
        ),
      ],
    ),
    ActivationSeedSpec(
      key: 'morning_launch_minimal',
      name: 'Morning Launch — Minimal',
      description: 'Rota curta para dias de baixa capacidade.',
      type: ActivationProtocolType.wakeUp,
      origin: ActivationTransitionState(
        label: 'Na cama',
        keys: ['bed'],
      ),
      target: ActivationTransitionState(
        label: 'Em pé e hidratado',
        keys: ['upright', 'water'],
      ),
      contexts: ['morning', 'low_capacity'],
      commands: [
        ActivationSeedCommand(
          instruction: 'Sente-se na beira da cama.',
          verb: 'Sente-se',
          estimatedSeconds: 20,
        ),
        ActivationSeedCommand(
          instruction: 'Beba um gole d\'água.',
          verb: 'Beba',
          objectRef: 'water',
        ),
        ActivationSeedCommand(
          instruction: 'Vá até o banheiro.',
          verb: 'Vá',
          destinationRef: 'bathroom',
        ),
        ActivationSeedCommand(
          instruction: 'Faça a higiene mínima.',
          verb: 'Faça',
          objectRef: 'hygiene',
        ),
        ActivationSeedCommand(
          instruction: 'Vista a roupa mais próxima.',
          verb: 'Vista',
          objectRef: 'clothes',
        ),
        ActivationSeedCommand(
          instruction: 'Reavalie o próximo movimento.',
          verb: 'Reavalie',
          isFirstMeaningfulAction: true,
          releasesOnConfirm: true,
        ),
      ],
    ),
    ActivationSeedSpec(
      key: 'code_ignition',
      name: 'Code Ignition',
      description: 'Do telefone à primeira mudança no código.',
      type: ActivationProtocolType.workStart,
      origin: ActivationTransitionState(
        label: 'Longe do posto',
        keys: ['away_desk'],
      ),
      target: ActivationTransitionState(
        label: 'Primeira mudança visível',
        keys: ['first_action', 'code'],
      ),
      contexts: ['work'],
      commands: [
        ActivationSeedCommand(
          instruction: 'Coloque o telefone no dock.',
          verb: 'Coloque',
          objectRef: 'phone',
          destinationRef: 'desk_dock',
        ),
        ActivationSeedCommand(
          instruction: 'Abra o workspace já escolhido.',
          verb: 'Abra',
          objectRef: 'workspace',
        ),
        ActivationSeedCommand(
          instruction: 'Abra o arquivo ou issue definido.',
          verb: 'Abra',
          objectRef: 'issue',
        ),
        ActivationSeedCommand(
          instruction: 'Leia a nota de continuidade.',
          verb: 'Leia',
          objectRef: 'restart_note',
        ),
        ActivationSeedCommand(
          instruction: 'Faça a primeira mudança visível.',
          verb: 'Faça',
          isFirstMeaningfulAction: true,
          releasesOnConfirm: true,
          skippable: false,
          deepLink: '/work',
        ),
      ],
    ),
    ActivationSeedSpec(
      key: 'study_ignition',
      name: 'Study Ignition',
      description: 'Contato real com o material, sem organizar o dia.',
      type: ActivationProtocolType.studyStart,
      origin: ActivationTransitionState(
        label: 'Antes do estudo',
        keys: ['pre_study'],
      ),
      target: ActivationTransitionState(
        label: 'Cinco minutos de contato',
        keys: ['study_contact'],
      ),
      contexts: ['study'],
      commands: [
        ActivationSeedCommand(
          instruction: 'Leve água até a mesa.',
          verb: 'Leve',
          objectRef: 'water',
          destinationRef: 'desk',
        ),
        ActivationSeedCommand(
          instruction: 'Abra o material exato.',
          verb: 'Abra',
          objectRef: 'material',
          deepLink: '/flashcards/study',
        ),
        ActivationSeedCommand(
          instruction: 'Leia apenas o primeiro enunciado.',
          verb: 'Leia',
          objectRef: 'prompt',
        ),
        ActivationSeedCommand(
          instruction: 'Escreva o que a questão pede.',
          verb: 'Escreva',
          objectRef: 'question',
        ),
        ActivationSeedCommand(
          instruction: 'Trabalhe por cinco minutos.',
          verb: 'Trabalhe',
          isFirstMeaningfulAction: true,
          releasesOnConfirm: true,
          skippable: false,
          estimatedSeconds: 300,
        ),
      ],
    ),
    ActivationSeedSpec(
      key: 'piano_ignition',
      name: 'Piano Ignition',
      description: 'Do banco à primeira frase musical.',
      type: ActivationProtocolType.creativeStart,
      origin: ActivationTransitionState(
        label: 'Longe do instrumento',
        keys: ['away_piano'],
      ),
      target: ActivationTransitionState(
        label: 'Oito compassos tocados',
        keys: ['music_contact'],
      ),
      contexts: ['music'],
      commands: [
        ActivationSeedCommand(
          instruction: 'Sente-se no banco.',
          verb: 'Sente-se',
          destinationRef: 'piano_bench',
        ),
        ActivationSeedCommand(
          instruction: 'Abra o instrumento.',
          verb: 'Abra',
          objectRef: 'piano',
        ),
        ActivationSeedCommand(
          instruction: 'Toque uma escala ou voicing definido.',
          verb: 'Toque',
          objectRef: 'scale',
        ),
        ActivationSeedCommand(
          instruction: 'Toque oito compassos da peça ativa.',
          verb: 'Toque',
          objectRef: 'piece',
          isFirstMeaningfulAction: true,
          releasesOnConfirm: true,
          deepLink: '/research/music-atlas',
        ),
      ],
    ),
    ActivationSeedSpec(
      key: 'music_expedition_walk',
      name: 'Music Expedition Walk',
      description: 'Sair de casa e iniciar um encontro do Atlas.',
      type: ActivationProtocolType.exerciseStart,
      origin: ActivationTransitionState(
        label: 'Dentro de casa',
        keys: ['home'],
      ),
      target: ActivationTransitionState(
        label: 'Caminhada iniciada',
        keys: ['outside', 'walk'],
      ),
      contexts: ['music', 'walk'],
      commands: [
        ActivationSeedCommand(
          instruction: 'Calce o tênis.',
          verb: 'Calce',
          objectRef: 'shoes',
        ),
        ActivationSeedCommand(
          instruction: 'Saia da zona da casa.',
          verb: 'Saia',
          destinationRef: 'front_door',
        ),
        ActivationSeedCommand(
          instruction: 'Inicie o encontro do Atlas Musical.',
          verb: 'Inicie',
          objectRef: 'atlas_encounter',
          deepLink: '/research/music-atlas/explore',
        ),
        ActivationSeedCommand(
          instruction: 'Caminhe por dez minutos.',
          verb: 'Caminhe',
          isFirstMeaningfulAction: true,
          releasesOnConfirm: true,
          estimatedSeconds: 600,
        ),
      ],
    ),
    ActivationSeedSpec(
      key: 'shower_reset',
      name: 'Shower Reset',
      description: 'Banho como sequência física curta.',
      type: ActivationProtocolType.hygiene,
      origin: ActivationTransitionState(
        label: 'Resistência ao banho',
        keys: ['pre_shower'],
      ),
      target: ActivationTransitionState(
        label: 'Chuveiro aberto',
        keys: ['shower_on'],
      ),
      contexts: ['hygiene'],
      commands: [
        ActivationSeedCommand(
          instruction: 'Leve o telefone ao Bathroom Dock.',
          verb: 'Leve',
          objectRef: 'phone',
          destinationRef: 'bathroom_dock',
          preferredProof: ActivationProofType.waypointQr,
        ),
        ActivationSeedCommand(
          instruction: 'Escolha a playlist já combinada.',
          verb: 'Escolha',
          objectRef: 'playlist',
        ),
        ActivationSeedCommand(
          instruction: 'Abra o chuveiro.',
          verb: 'Abra',
          objectRef: 'shower',
          isFirstMeaningfulAction: true,
          releasesOnConfirm: true,
          splits: [
            'Caminhe até o box.',
            'Gire o registro.',
          ],
        ),
      ],
    ),
    ActivationSeedSpec(
      key: 'leave_home',
      name: 'Leave Home',
      description: 'Da roupa ao ponto de reunião da porta.',
      type: ActivationProtocolType.departure,
      origin: ActivationTransitionState(
        label: 'Ainda em casa',
        keys: ['home'],
      ),
      target: ActivationTransitionState(
        label: 'Fora da porta',
        keys: ['outside'],
      ),
      contexts: ['departure'],
      commands: [
        ActivationSeedCommand(
          instruction: 'Vista a roupa de saída.',
          verb: 'Vista',
          objectRef: 'clothes',
        ),
        ActivationSeedCommand(
          instruction: 'Pegue o loadout que falta.',
          verb: 'Pegue',
          objectRef: 'loadout',
          deepLink: '/resources/inventory',
        ),
        ActivationSeedCommand(
          instruction: 'Vá até o ponto de reunião da porta.',
          verb: 'Vá',
          destinationRef: 'front_door',
          preferredProof: ActivationProofType.waypointQr,
        ),
        ActivationSeedCommand(
          instruction: 'Saia pela porta.',
          verb: 'Saia',
          isFirstMeaningfulAction: true,
          releasesOnConfirm: true,
        ),
      ],
    ),
    ActivationSeedSpec(
      key: 'night_runway',
      name: 'Night Runway',
      description: 'Preparar o terreno sem perfeccionismo.',
      type: ActivationProtocolType.sleepPreparation,
      origin: ActivationTransitionState(
        label: 'Fim do dia',
        keys: ['evening'],
      ),
      target: ActivationTransitionState(
        label: 'Terreno mínimo pronto',
        keys: ['runway'],
      ),
      contexts: ['night'],
      commands: [
        ActivationSeedCommand(
          instruction: 'Deixe a roupa de amanhã à vista.',
          verb: 'Deixe',
          objectRef: 'clothes',
        ),
        ActivationSeedCommand(
          instruction: 'Encha um copo d\'água.',
          verb: 'Encha',
          objectRef: 'water',
        ),
        ActivationSeedCommand(
          instruction: 'Anote só a primeira ação de amanhã.',
          verb: 'Anote',
          objectRef: 'first_action',
          isFirstMeaningfulAction: true,
          releasesOnConfirm: true,
          deepLink: '/inbox',
        ),
      ],
    ),
    ActivationSeedSpec(
      key: 'anti_scroll',
      name: 'Anti-scroll rescue',
      description: 'Sair da tela com um gesto físico, sem culpa.',
      type: ActivationProtocolType.antiScroll,
      origin: ActivationTransitionState(
        label: 'Rolando a tela',
        keys: ['scroll'],
      ),
      target: ActivationTransitionState(
        label: 'Telefone fora da mão',
        keys: ['phone_down'],
      ),
      contexts: ['scroll'],
      commands: [
        ActivationSeedCommand(
          instruction: 'Trave o telefone.',
          verb: 'Trave',
          objectRef: 'phone',
          estimatedSeconds: 5,
        ),
        ActivationSeedCommand(
          instruction: 'Coloque o telefone virado para baixo.',
          verb: 'Coloque',
          objectRef: 'phone',
          destinationRef: 'surface',
        ),
        ActivationSeedCommand(
          instruction: 'Fique em pé e dê três passos.',
          verb: 'Fique',
          isFirstMeaningfulAction: true,
          releasesOnConfirm: true,
        ),
      ],
    ),
  ];

  static ActivationSeedSpec? byKey(String key) {
    for (final spec in catalog) {
      if (spec.key == key) return spec;
    }
    return null;
  }

  static ActivationProtocolBundle materialize({
    required ActivationSeedSpec spec,
    required EntityId profileId,
    required EntityId protocolId,
    required DateTime now,
    required EntityId Function() newId,
    EntityId? fallbackProtocolId,
  }) {
    final protocol = ActivationProtocol(
      id: protocolId,
      profileId: profileId,
      name: spec.name,
      description: spec.description,
      protocolType: spec.type,
      originState: spec.origin,
      targetState: spec.target,
      seedKey: spec.key,
      createdAt: now,
      updatedAt: now,
    );
    final version = ActivationProtocolVersion(
      protocolId: protocolId,
      version: 1,
      triggerRules: const ActivationTriggerRules(),
      releaseConditions: const ActivationReleaseConditions(),
      applicableContexts: spec.contexts,
      fallbackProtocolId: fallbackProtocolId,
      createdAt: now,
    );
    final commands = <ActivationCommandTemplate>[
      for (var i = 0; i < spec.commands.length; i++)
        _command(spec.commands[i], protocolId, i, newId),
    ];
    return ActivationProtocolBundle(
      protocol: protocol,
      version: version,
      commands: commands,
    );
  }

  static ActivationCommandTemplate _command(
    ActivationSeedCommand seed,
    EntityId protocolId,
    int index,
    EntityId Function() newId,
  ) {
    return ActivationCommandTemplate(
      id: newId(),
      protocolId: protocolId,
      protocolVersion: 1,
      sequenceKey: (index + 1).toString().padLeft(2, '0'),
      instruction: seed.instruction,
      actionVerb: seed.verb,
      objectRef: seed.objectRef,
      destinationRef: seed.destinationRef,
      proofPolicy: ActivationProofPolicy(preferred: seed.preferredProof),
      fallback: ActivationFallbackPolicy(splitInstructions: seed.splits),
      skippable: seed.skippable,
      estimatedSeconds: seed.estimatedSeconds,
      isFirstMeaningfulAction: seed.isFirstMeaningfulAction,
      releasesOnConfirm: seed.releasesOnConfirm,
      deepLink: seed.deepLink,
    );
  }
}
