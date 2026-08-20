import 'package:colony_domain/colony_domain.dart';

abstract final class AppStrings {
  static const appName = 'Colônia';
  static const colony = 'Colônia';
  static const pawn = 'Perfil';
  static const work = 'Trabalho';
  static const quests = 'Missões';
  static const research = 'Pesquisa';
  static const resources = 'Recursos';
  static const relations = 'Relações';
  static const chronicle = 'Crônica';
  static const dataCenter = 'Dados';
  static const settings = 'Configurações';
  static const more = 'Mais';
  static const habitatTitle = 'Habitat';
  static const habitatSubtitle = 'Pawn vivo · local';
  static const habitatInspectHint =
      'Toque no pawn ou num objeto para inspecionar.';
  static const habitatInspectPawnSoon =
      'Colonista ocioso — passeando pelo habitat. Inspect completo em breve.';
  static const habitatInspectPropSoon =
      'Objeto do habitat. Projeção de vida real chega nas próximas fases.';
  static const habitatStatus = 'Estado';
  static const habitatJobSleep = 'Dormir';
  static const habitatJobSit = 'Sentar';
  static const habitatJobTable = 'Ir à mesa';
  static const habitatJobWander = 'Passear';
  static const habitatSkinColor = 'Pele';
  static const habitatHairColor = 'Cabelo';
  static const habitatStuffColor = 'Cor do material';
  static const habitatInspectPropTint =
      'Sprites em escala de cinza — escolha a cor do “stuff”.';
  static const habitatCreateTitle = 'Criar colonista';
  static const habitatCreateSubtitle = 'Personalizar pawn';
  static const habitatCreateName = 'Nome';
  static const habitatCreateIdentityHint =
      'O nome aparece no Habitat e no inspect. Aparência é só visual.';
  static const habitatCatIdentity = 'Identidade';
  static const habitatCatBody = 'Corpo';
  static const habitatCatHair = 'Cabelo';
  static const habitatCatClothes = 'Roupa';
  static const habitatHairStyle = 'Corte';
  static const habitatBodyType = 'Silhueta';
  static const habitatBeard = 'Barba';
  static const habitatApparelTop = 'Tronco';
  static const habitatHat = 'Chapéu';
  static const habitatLoadout = 'Loadout';
  static const habitatApparelColor = 'Cor da roupa';
  static const habitatClothesSoon =
      'Roupas e loadouts entram na próxima fatia visual.';
  static const habitatRandomAll = 'Randomizar';
  static const habitatRandomHair = 'Random cabelo';
  static const habitatRandomClothes = 'Random roupa';
  static const habitatResetLook = 'Desfazer';
  static const habitatAcceptPawn = 'Aceitar';
  static const habitatTurnLeft = 'Girar esquerda';
  static const habitatTurnRight = 'Girar direita';
  static const habitatPreviewAuto = 'Auto';
  static const habitatPreviewManual = 'Manual';
  static const habitatPreviewWalk = 'Andar';
  static const habitatCreatePreviewHint =
      'Preview ao vivo — 4 direções + bob de caminhada.';
  static const habitatEditPawn = 'Personalizar pawn';
  static const habitatEditRoom = 'Editar cômodo';
  static const habitatEditDone = 'Concluir edição';
  static const habitatEditToolSelect = 'Selecionar';
  static const habitatEditToolFloor = 'Piso';
  static const habitatEditToolPlace = 'Colocar';
  static const habitatEditToolErase = 'Remover';
  static const habitatEditToolWall = 'Parede';
  static const habitatEditToolDoor = 'Porta';
  static const habitatEditToolMove = 'Mover';
  static const habitatEditToolZone = 'Zona permitida';
  static const habitatEditToolZoneErase = 'Apagar zona';
  static const habitatEditZoneClear = 'Limpar zona';
  static const habitatEditUndo = 'Desfazer';
  static const habitatEditHint =
      'Modo edição: pinte pisos, coloque/mova móveis, paredes e porta. Desfazer é só desta sessão.';
  static const habitatFloorWood = 'Madeira';
  static const habitatFloorCarpet = 'Carpete';
  static const habitatFloorConcrete = 'Concreto';
  static const habitatLocationBedroom = 'Quarto';
  static const habitatLocationOffice = 'Escritório';
  static const habitatLocationKitchen = 'Cozinha';
  static const habitatLocationTerrace = 'Terraço';
  static const habitatLocationHint = 'Trocar de local (cosmético — sem viagem).';
  static const habitatSelectLocation = 'Local';
  static const habitatRosterHint =
      'Colonistas no habitat — toque para priorizar, editar para personalizar.';
  static const habitatRosterAdd = 'Adicionar';
  static const habitatRosterFull = 'Cheio (4)';
  static const habitatActionPrioritize = 'Priorizar este';
  static const habitatActionFollowCam = 'Seguir câmera';
  static const habitatActionUnfollowCam = 'Parar câmera';
  static const habitatMiniHint = 'Abrir Habitat';
  static const habitatCameraReset = 'Resetar câmera';
  static const habitatZoomIn = 'Zoom +';
  static const habitatZoomOut = 'Zoom −';
  static const habitatMuteOn = 'Som off';
  static const habitatMuteOff = 'Som on';
  static const habitatDayCycle = 'Ciclo';
  static const habitatPanHint =
      'Scroll = zoom · botão do meio arrasta · Seguir câmera no menu do pawn';
  static const habitatInspectEmpty =
      'Nada selecionado. Toque num pawn ou objeto — ou segure/clique direito para o menu.';
  static const habitatInspectEmptyShort = 'Nada selecionado';
  static const habitatAmbientTempPlaceholder = '—°C';
  static const habitatAmbientWeatherPlaceholder = '—';
  static const habitatInspectBio = 'Biografia';
  static const habitatInspectBioHint = 'Nota livre sobre este colonista…';
  static const habitatInspectFacing = 'Direção';
  static const habitatInspectCell = 'Célula';
  static const habitatInspectFootprint = 'Ocupação';
  static const habitatActionGoHere = 'Ir até aqui';
  static const habitatActionGoToProp = 'Ir até o objeto';
  static const habitatActionDraft = 'Selecionar';
  static const habitatActionUndraft = 'Liberar (passear)';
  static const habitatDraftStatus = 'Draft';
  static const habitatActionCustomize = 'Personalizar';
  static const habitatFloatMenuTitle = 'Ações';
  static const habitatBubbleSleep = [
    'Hora de deitar…',
    'Só um cochilo.',
    'O colchão chama.',
  ];
  static const habitatBubbleSit = [
    'Melhor sentar um pouco.',
    'Ah, a cadeira.',
    'Descanso rápido.',
  ];
  static const habitatBubbleTable = [
    'Vamos à mesa.',
    'Papelada mental.',
    'Foco na superfície plana.',
  ];
  static const habitatBubbleArrived = [
    'Cheguei.',
    'Aqui está bem.',
    'Ok.',
  ];
  /// Soft idle thoughts (common). Keep quiet / observational.
  static const habitatBubbleIdleSoft = [
    '…',
    '…',
    'E agora?',
    'Observando a colônia.',
    'Só passando.',
  ];

  /// Rare flavor — should almost never feel spammy.
  static const habitatBubbleIdleRare = [
    'Talvez um café.',
    'Hmm.',
    'Dia tranquilo.',
  ];

  /// Legacy alias used by job-arrived wander fallback.
  static const habitatBubbleIdle = [
    ...habitatBubbleIdleSoft,
    ...habitatBubbleIdleRare,
  ];
  static const habitatBubbleTap = [
    'Sim?',
    'Estou aqui.',
    'Ordens?',
    'Oi.',
  ];
  static const habitatBubbleRoomNice = [
    'Bonito aqui.',
    'Gosto deste cômodo.',
    'Boa vibe.',
  ];
  static const habitatBubbleRoomTight = [
    'Meio apertado.',
    'Falta espaço.',
    'Cabine apertada.',
  ];
  static const habitatBubbleArt = [
    'Hmm.',
    'Bonito.',
    'Interessante…',
  ];
  static const habitatBubbleClean = [
    'Limpar isso.',
    'Sujeira…',
    'Vassoura mental.',
  ];
  static const habitatBubbleRecreate = [
    'Hora de relaxar.',
    'Boa.',
    '…',
  ];
  static const habitatBubbleTooDark = 'Escuro demais.';
  static const habitatBubbleOrderDenied = 'Não.';
  static const habitatPropQuality = 'Qualidade';
  static String habitatPropQualityValue(String q) => 'Qualidade: $q';
  static const habitatBeautyOverlay = 'Beleza';
  static const habitatBeautyOverlayOn = 'Beleza (ligada)';
  static const habitatBeautyOverlayOff = 'Beleza (mapa)';
  static const habitatActionSweepClean = 'Limpar ambiente';
  static const habitatBubbleSweepDone = 'Tudo limpo.';
  static const habitatRoomRoleBedroom = 'Quarto';
  static const habitatRoomRoleDining = 'Refeitório';
  static const habitatRoomRoleOffice = 'Escritório';
  static const habitatRoomRoleExterior = 'Exterior';
  static const habitatRoomRoleGeneric = 'Cômodo';
  static const habitatRoomStatBeauty = 'Beleza';
  static const habitatRoomStatSpace = 'Espaço';
  static const habitatRoomStatClean = 'Limpeza';
  static const habitatRoomStatWealth = 'Riqueza';
  static const habitatRoomStatComfort = 'Conforto';
  static const habitatIndoorTemp = 'Interior';
  static const habitatImpressMediocre = 'Medíocre';
  static const habitatImpressPleasant = 'Agradável';
  static const habitatImpressNice = 'Bonito';
  static const habitatImpressGlorious = 'Extasiado';

  static const inbox = 'Caixa de entrada';
  static const capture = 'Capturar';
  static const captureHint = 'O que precisa ser registrado?';
  static const save = 'Salvar';
  static const cancel = 'Cancelar';
  static const delete = 'Excluir';
  static const undo = 'Desfazer';
  static const exportData = 'Exportar JSON';
  static const restoreData = 'Restaurar backup';
  static const restorePreviewTitle = 'Prévia do backup';
  static const restoreConfirmTitle = 'Substituir todos os dados?';
  static const restoreConfirmBody =
      'Esta ação apaga o perfil atual e restaura o backup. Não pode ser desfeita.';
  static const restoreConfirmAction = 'Restaurar agora';
  static const restoreCancel = 'Cancelar';
  static const restoreSuccess = 'Backup restaurado com sucesso';
  static const restoreInvalidFile = 'Arquivo de backup inválido';
  static const sideloadBuildTitle = 'Build de teste';
  static const sideloadBuildLocal =
      'Build local — não veio do GitHub Actions.';
  static const sideloadBuildCommit = 'Commit';
  static const sideloadBuildRef = 'Ref';
  static const sideloadBuildTime = 'Gerado em';
  static const restoreVersionLabel = 'Versão do export';
  static const restoreExportedAt = 'Exportado em';
  static const restoreEntityCounts = 'Conteúdo';
  static const emptyInbox = 'Inbox vazia. Use captura rápida para registrar algo.';
  static const emptyTimeline = 'Nenhum evento registrado ainda.';
  static const loading = 'Carregando…';
  static const errorGeneric = 'Algo deu errado. Tente novamente.';
  static const onboardingTitle = 'Criar colônia';
  static const onboardingSubtitle =
      'Configure sua base pessoal em menos de cinco minutos.';
  static const colonyName = 'Nome da colônia';
  static const pawnName = 'Seu nome';
  static const startColony = 'Iniciar colônia';
  static const sectorsTitle = 'Setores ativos';
  static const today = 'Hoje';
  static const nextActions = 'Próximas ações';
  static const alerts = 'Alertas';
  static const commandPalette = 'Comando';
  static const commandHint = 'Navegar ou criar…';
  static const taskDetails = 'Detalhes da tarefa';
  static const markNext = 'Próxima ação';
  static const archive = 'Arquivar';
  static const status = 'Status';
  static const offlineReady = 'Local · offline';
  static const comingSoon = 'Em breve nesta fase';
  static const checkIn = 'Check-in';
  static const dailyReview = 'Revisão diária';
  static const pawnTabSummary = 'Resumo';
  static const pawnTabNeeds = 'Necessidades';
  static const pawnTabMind = 'Mente';
  static const mood = 'Humor';
  static const energy = 'Energia';
  static const tension = 'Tensão';
  static const focus = 'Foco';
  static const note = 'Nota';
  static const noteOptional = 'Nota (opcional)';
  static const noCheckInYet = 'Nenhum check-in registrado hoje.';
  static const pawnSummaryIntro =
      'Visão do que está acontecendo — sem reduzir você a números.';
  static const needsAttention = 'Necessidades em atenção';
  static const needsStable = 'Necessidades estáveis ou sem dados recentes.';
  static const lastCheckIn = 'Último check-in';
  static const recordNeed = 'Registrar';
  static const moodDeclared = 'Humor declarado';
  static const moodFactors = 'Fatores mencionados';
  static const noFactorsYet = 'Nenhum fator registrado no último check-in.';
  static const dailyReviewIntro =
      'Revisão diária em 2–5 minutos. Fatos, estado atual e amanhã.';
  static const reviewWhatHappened = 'O que aconteceu hoje?';
  static const reviewCurrentState = 'Como estou agora?';
  static const reviewTomorrow = 'Compromissos de amanhã';
  static const reviewCorrection = 'Uma correção de rota';
  static const weeklyReview = 'Revisão semanal';
  static const weeklyReviewIntro =
      'Revisão semanal em 15–30 minutos. Fatos, vitórias e próximos passos.';
  static const narrativeDigestTitle = 'Resumo da semana (regras locais)';
  static const narrativeDigestDisclaimer =
      'Heurísticas locais — não é conselho médico, financeiro nem IA generativa.';
  static const narrativeDigestAction = 'Resumo da semana (regras)';
  static String narrativeDigestChipLabel(int bulletCount) =>
      'Resumo · $bulletCount sinal${bulletCount == 1 ? '' : 'is'}';
  static const narrativeDigestSignals = 'Sinais detectados';
  static const close = 'Fechar';

  static String narrativeDigestGenerator(String id) => 'Gerador: $id';

  static String narrativeDigestSignalChip(String templateId) =>
      switch (templateId) {
        'chronicle_events' => 'Crônica',
        'quest_activity' => 'Missões',
        'task_activity' => 'Tarefas',
        'check_ins' => 'Check-ins',
        'decisions' => 'Decisões',
        'ics_imports' => 'ICS',
        'trip_activity' => 'Viagens',
        'zone_activity' => 'Zonas',
        'commitment_activity' => 'Compromissos',
        'health_appointment_activity' => 'Consultas',
        'finance_activity' => 'Finanças',
        'research_activity' => 'Pesquisa',
        'inventory_activity' => 'Inventário',
        'review_wins' => 'Vitórias',
        'review_problems' => 'Problemas',
        'review_learning' => 'Aprendizados',
        'quiet_week' => 'Semana calma',
        'period_marker' => 'Janela',
        _ => templateId,
      };

  static String narrativeDigestPeriod(DateTime start, DateTime end) {
    String fmt(DateTime d) {
      final u = d.toUtc();
      return '${u.year.toString().padLeft(4, '0')}-'
          '${u.month.toString().padLeft(2, '0')}-'
          '${u.day.toString().padLeft(2, '0')}';
    }
    return 'Período: ${fmt(start)} → ${fmt(end)}';
  }

  static String narrativeDigestEvidence(int n) =>
      '$n evidência${n == 1 ? '' : 's'} na crônica';
  static String narrativeDigestEvidenceAction(int n) =>
      'Ver $n evidência${n == 1 ? '' : 's'} na crônica';
  static String chronicleEvidenceFilterActive(int n) =>
      'Filtro: $n evidência${n == 1 ? '' : 's'}';
  static const chronicleClearEvidenceFilter = 'Ver toda a crônica';
  static const chronicleEvidenceNotFound =
      'Evidências não encontradas na timeline.';

  static String narrativeDigestBullet(NarrativeDigestBullet bullet) {
    final count = bullet.params['count'];
    return switch (bullet.templateId) {
      'chronicle_events' =>
        '${count ?? 0} evento${count == 1 ? '' : 's'} na crônica neste período.',
      'quest_activity' =>
        '${count ?? 0} movimento${count == 1 ? '' : 's'} em missões.',
      'task_activity' =>
        '${count ?? 0} atividade${count == 1 ? '' : 's'} em tarefas/capturas.',
      'check_ins' => '${count ?? 0} check-in${count == 1 ? '' : 's'} registrado${count == 1 ? '' : 's'}.',
      'decisions' =>
        '${count ?? 0} decisão${count == 1 ? '' : 'ões'} registrada${count == 1 ? '' : 's'}.',
      'ics_imports' =>
        '${count ?? 0} importação${count == 1 ? '' : 'ões'} ICS nesta janela.',
      'trip_activity' =>
        '${count ?? 0} movimento${count == 1 ? '' : 's'} em viagens.',
      'zone_activity' =>
        '${count ?? 0} atualização${count == 1 ? '' : 'ões'} em zonas.',
      'commitment_activity' =>
        '${count ?? 0} compromisso${count == 1 ? '' : 's'} registrado${count == 1 ? '' : 's'}.',
      'health_appointment_activity' =>
        '${count ?? 0} lembrete${count == 1 ? '' : 's'} de consulta.',
      'finance_activity' =>
        '${count ?? 0} movimento${count == 1 ? '' : 's'} no ledger/orçamento.',
      'research_activity' =>
        '${count ?? 0} movimento${count == 1 ? '' : 's'} em pesquisa.',
      'inventory_activity' =>
        '${count ?? 0} movimento${count == 1 ? '' : 's'} no inventário.',
      'review_wins' => 'Vitórias anotadas na revisão semanal.',
      'review_problems' => 'Problemas anotados na revisão semanal.',
      'review_learning' => 'Aprendizados registrados na revisão semanal.',
      'quiet_week' => 'Semana calma — poucos sinais na crônica.',
      'period_marker' => 'Janela de revisão coberta pelas regras locais.',
      _ => bullet.templateId,
    };
  }
  static const reviewFacts = 'Fatos da semana';
  static const reviewWins = 'Vitórias';
  static const reviewProblems = 'Problemas';
  static const reviewProjects = 'Projetos';
  static const reviewLearning = 'Aprendizado';
  static const reviewNextWeek = 'Próxima semana';

  // Work & schedule (Phase 3)
  static const workPriorities = 'Prioridades';
  static const workPrioritiesHelp =
      'Toque para alternar: — · 1 · 2 · 3 · 4 · A';
  static const workPrioritiesEmpty =
      'Nenhuma prioridade configurada. Toque em recarregar.';
  static const reload = 'Recarregar';
  static const schedule = 'Agenda';
  static const scheduleDayView = 'Visão do dia';
  static const scheduleThreeDayView = 'Visão de 3 dias';
  static const scheduleViewDay = 'Dia';
  static const scheduleViewThreeDays = '3 dias';
  static const bills = 'Bills';
  static const billsEmpty = 'Nenhuma bill cadastrada.';
  static const addBill = 'Nova bill';
  static const billTitle = 'Título da bill';
  static const billTarget = 'Meta';
  static const billRepeatMode = 'Repetição';
  static const openSchedule = 'Abrir agenda';
  static const noScheduleBlocks = 'Nenhum bloco neste dia.';
  static const noScheduledTasks = 'Nenhuma tarefa agendada neste dia.';
  static const addScheduleBlock = 'Adicionar bloco';
  static const scheduleEditBlock = 'Editar bloco';
  static const scheduleDeleteBlock = 'Excluir bloco';
  static const scheduleDeleteBlockConfirm =
      'Remover este bloco da agenda? Esta ação não pode ser desfeita.';
  static const schedulePreviousDay = 'Dia anterior';
  static const scheduleNextDay = 'Próximo dia';
  static const scheduleStartTime = 'Início';
  static const scheduleEndTime = 'Fim';
  static const scheduleBlockMode = 'Modo';
  static const scheduleBlockInvalidTime =
      'O horário de fim deve ser depois do início.';
  static const scheduledTasks = 'Tarefas agendadas';
  static const scheduleBlocks = 'Blocos';
  static const scheduleTimeline = 'Linha do tempo';
  static const scheduleConflicts = 'Conflitos';
  static const scheduleConflictsHelp =
      'Estes itens se sobrepõem no mesmo horário.';
  static String scheduleConflictPair(String a, String b) => '$a × $b';
  static String scheduleConflictOverlap(
    String start,
    String end,
    Duration duration,
  ) {
    final minutes = duration.inMinutes;
    final durationLabel = minutes >= 60
        ? '${duration.inHours} h ${minutes % 60} min'
        : '$minutes min';
    return 'Sobreposição: $start – $end ($durationLabel)';
  }

  static String workTypeLabel(WorkType type) => switch (type) {
        WorkType.urgentHealth => 'Saúde urgente',
        WorkType.personalAdmin => 'Admin pessoal',
        WorkType.university => 'Universidade',
        WorkType.mainWork => 'Trabalho principal',
        WorkType.projectA => 'Projeto A',
        WorkType.projectB => 'Projeto B',
        WorkType.finances => 'Finanças',
        WorkType.home => 'Casa',
        WorkType.relations => 'Relações',
        WorkType.music => 'Música',
        WorkType.generalLearning => 'Aprendizado',
        WorkType.exercise => 'Exercício',
        WorkType.travelPlanning => 'Viagem',
        WorkType.restRecreation => 'Descanso',
        WorkType.captureOrganization => 'Captura',
      };

  static String priorityLevelLabel(PriorityLevel level) => switch (level) {
        PriorityLevel.blocked => '—',
        PriorityLevel.immediate => '1',
        PriorityLevel.high => '2',
        PriorityLevel.normal => '3',
        PriorityLevel.low => '4',
        PriorityLevel.automatic => 'A',
      };

  static String scheduleBlockModeLabel(ScheduleBlockMode mode) => switch (mode) {
        ScheduleBlockMode.sleep => 'Dormir',
        ScheduleBlockMode.routine => 'Rotina',
        ScheduleBlockMode.focus => 'Foco',
        ScheduleBlockMode.meeting => 'Reunião',
        ScheduleBlockMode.flexible => 'Flexível',
        ScheduleBlockMode.exercise => 'Exercício',
        ScheduleBlockMode.commute => 'Deslocamento',
        ScheduleBlockMode.social => 'Social',
        ScheduleBlockMode.recreation => 'Recreação',
        ScheduleBlockMode.recovery => 'Recuperação',
        ScheduleBlockMode.free => 'Livre',
        ScheduleBlockMode.unavailable => 'Indisponível',
      };

  static String billRepeatModeLabel(BillRepeatMode mode) => switch (mode) {
        BillRepeatMode.fixed => 'Fixa',
        BillRepeatMode.untilState => 'Até estado',
        BillRepeatMode.maintainStock => 'Manter estoque',
        BillRepeatMode.interval => 'Intervalo',
        BillRepeatMode.quotaWindow => 'Cota/janela',
      };

  // Quests (Phase 4)
  static const newQuest = 'Nova missão';
  static const questBoardEmpty = 'Nenhuma missão ainda.';
  static const questBoardEmptyHint =
      'Missões ajudam a enquadrar decisões com propósito, prazo e critérios.';
  static const questSectionActive = 'Ativas';
  static const questSectionPaused = 'Pausadas';
  static const questSectionDrafts = 'Rascunhos';
  static const questSectionHistory = 'Concluídas / Abandonadas';
  static const questTitle = 'Título';
  static const questPurpose = 'Propósito';
  static const questDeadline = 'Prazo';
  static const questNoDeadline = 'Sem prazo';
  static const questSaveDraft = 'Salvar rascunho';
  static const questActivate = 'Ativar';
  static const questAcceptAndActivate = 'Aceitar e ativar';
  static const questCreateAndActivate = 'Criar e ativar';
  static const questAcceptTitle = 'Aceitar missão';
  static const questAcceptSubtitle =
      'Registre as premissas em que você baseia este compromisso.';
  static const questAcceptanceAssumptions = 'Premissas do aceite';
  static const questAddAssumption = 'Adicionar premissa';
  static const questAssumptionHint = 'Ex.: tenho tempo esta semana';
  static const questAssumptionRequired = 'Informe ao menos uma premissa';
  static const questAcceptanceDeadline = 'Prazo do aceite (opcional)';
  static const questAcceptedAt = 'Aceita em';
  static const questAcceptConfirm = 'Confirmar aceite';
  static const questAcceptCancel = 'Cancelar';

  static String questAcceptanceDeadlineValue(String date) =>
      'Prazo do aceite: $date';
  static const questPause = 'Pausar';
  static const questResume = 'Retomar';
  static const questComplete = 'Concluir';
  static const questCompleteConfirm = 'Confirmar conclusão';
  static const questCompleteCriteriaPrompt =
      'Confirme que os critérios foram atendidos:';
  static const questCompleteNoCriteriaPrompt =
      'Deseja marcar esta missão como concluída?';
  static const questAbandon = 'Abandonar';
  static const questAbandonReasonOptional = 'Motivo (opcional, neutro)';
  static const questPauseReasonOptional = 'Motivo da pausa (opcional)';
  static const questSuccessCriteria = 'Critérios de sucesso';
  static const questRisks = 'Riscos';
  static const questNextAction = 'Próxima ação';
  static const questNoNextAction = 'Nenhuma tarefa vinculada.';
  static const questLinkTask = 'Vincular tarefa';
  static const questPickExistingTask = 'Escolher tarefa ativa';
  static const questQuickCreateTask = 'Ou criar rapidamente';
  static const questExitReason = 'Motivo de saída';
  static const questNotFound = 'Missão não encontrada.';
  static const questEdit = 'Editar missão';
  static const questAddCriterion = 'Adicionar critério';
  static const questAddRisk = 'Adicionar risco';
  static const questCriterionHint = 'Ex.: documentação pronta';
  static const questRiskHint = 'Ex.: prazo de visto';
  static const questRemoveLine = 'Remover linha';
  static const questTitleRequired = 'Informe um título';
  static const questPurposeRequired = 'Informe um propósito';
  static const questClearDeadline = 'Remover prazo';

  static String questStatusLabel(QuestStatus status) => switch (status) {
        QuestStatus.draft => 'Rascunho',
        QuestStatus.active => 'Ativa',
        QuestStatus.paused => 'Pausada',
        QuestStatus.completed => 'Concluída',
        QuestStatus.abandoned => 'Abandonada',
      };

  static String taskStatusLabel(TaskStatus status) => switch (status) {
        TaskStatus.inbox => 'Inbox',
        TaskStatus.next => 'Próxima',
        TaskStatus.scheduled => 'Agendada',
        TaskStatus.doing => 'Em andamento',
        TaskStatus.blocked => 'Bloqueada',
        TaskStatus.waiting => 'Aguardando',
        TaskStatus.done => 'Concluída',
        TaskStatus.cancelled => 'Cancelada',
        TaskStatus.archived => 'Arquivada',
      };

  // Projects (Iteration 5)
  static const projects = 'Projetos';
  static const newProject = 'Novo projeto';
  static const projectListEmpty = 'Nenhum projeto ainda.';
  static const projectListEmptyHint =
      'Projetos agrupam missões relacionadas sem substituí-las.';
  static const projectSectionActive = 'Ativos';
  static const projectSectionCompleted = 'Concluídos';
  static const projectSectionArchived = 'Arquivados';
  static const projectTitle = 'Título';
  static const projectTitleRequired = 'Informe um título';
  static const projectPurpose = 'Propósito';
  static const projectPurposeOptional = 'Propósito (opcional)';
  static const projectNotFound = 'Projeto não encontrado.';
  static const projectLinkedQuests = 'Missões vinculadas';
  static const projectNoLinkedQuests = 'Nenhuma missão vinculada.';
  static const projectPickerEmpty = 'Nenhum projeto ativo disponível.';
  static const projectEdit = 'Editar projeto';
  static const projectComplete = 'Concluir projeto';
  static const projectCompleteConfirm =
      'Marcar este projeto como concluído?';
  static const projectArchive = 'Arquivar projeto';
  static const projectArchiveConfirm =
      'Arquivar este projeto? Ele ficará fora da lista de ativos.';
  static const questLinkedProjects = 'Projetos vinculados';
  static const questNoLinkedProjects = 'Nenhum projeto vinculado.';
  static const questLinkProject = 'Vincular projeto';
  static const questUnlinkProject = 'Desvincular projeto';
  static const questLinkedResearch = 'Pesquisa vinculada';
  static const questNoLinkedResearch = 'Nenhum nó de pesquisa vinculado.';
  static const questLinkResearch = 'Vincular pesquisa';
  static const questUnlinkResearch = 'Desvincular pesquisa';
  static const researchNodePickerEmpty =
      'Nenhum nó de pesquisa disponível.';
  static const questPauseReason = 'Motivo da pausa';

  static String questSelectedProjectsCount(int count) =>
      count == 1 ? '1 projeto selecionado' : '$count projetos selecionados';

  static const questLinkedPrerequisites = 'Pré-requisitos';
  static const questNoLinkedPrerequisites = 'Nenhum pré-requisito vinculado.';
  static const questLinkPrerequisite = 'Vincular pré-requisito';
  static const questUnlinkPrerequisite = 'Desvincular pré-requisito';
  static const questPrerequisitePickerEmpty =
      'Nenhuma outra missão disponível.';
  static const questWaitingBadge = 'Aguardando';
  static const questActivateBlockedPrerequisites =
      'Conclua os pré-requisitos antes de ativar esta missão.';
  static const questPrerequisiteCycle =
      'Não é possível criar dependência circular entre missões.';
  static const questPrerequisiteSelfLink =
      'Uma missão não pode depender de si mesma.';
  static const questChainTitle = 'Cadeia de missões';
  static const questDetailTabContent = 'Conteúdo';
  static const questDetailTabRelations = 'Relações';

  static String questSelectedPrerequisitesCount(int count) => count == 1
      ? '1 pré-requisito selecionado'
      : '$count pré-requisitos selecionados';

  static String projectStatusLabel(ProjectStatus status) => switch (status) {
        ProjectStatus.active => 'Ativo',
        ProjectStatus.completed => 'Concluído',
        ProjectStatus.archived => 'Arquivado',
      };

  static const newResearchNode = 'Novo nó';
  static const flashcardsTitle = 'Flashcards';
  static const flashcardsSubtitle =
      'Mapa de conhecimento e repetição espaçada — local, sem conta.';
  static const flashcardsStudyNow = 'Estudar (espaçado)';
  static const flashcardsStudyDeck = 'Estudar baralho';
  static const flashcardsStudyArea = 'Estudar área';
  static const flashcardsDue = 'A revisar';
  static const flashcardsNew = 'Novos';
  static const flashcardsLearning = 'Aprendendo';
  static const flashcardsEmpty =
      'Nenhum cartão ainda. Crie um baralho ou semeie o mapa.';
  static const flashcardsEmptyHint =
      'Conhecimento não precisa virar cartão. Use o mapa para áreas e revise só o que importa.';
  static const flashcardsSearchHint = 'Buscar cartões, baralhos ou áreas';
  static const flashcardsNoResults = 'Nada corresponde à busca.';
  static const flashcardsMapTitle = 'Mapa de conhecimento';
  static const flashcardsMapEmpty = 'Nenhuma área no mapa.';
  static const flashcardsSeedMap = 'Semeiar áreas';
  static const flashcardsSeedMapHint =
      'Escolha domínios. Nada é criado sem o seu ok.';
  static const flashcardsSeedApply = 'Adicionar selecionadas';
  static const flashcardsDecksTitle = 'Baralhos';
  static const flashcardsNewDeck = 'Novo baralho';
  static const flashcardsNewCard = 'Novo cartão';
  static const flashcardsNewArea = 'Nova área';
  static const flashcardsDeckTitle = 'Nome do baralho';
  static const flashcardsDeckTitleRequired = 'Informe o nome do baralho';
  static const flashcardsAreaTitle = 'Nome da área';
  static const flashcardsAreaTitleRequired = 'Informe o nome da área';
  static const flashcardsParentArea = 'Área pai (opcional)';
  static const flashcardsNoParent = 'Raiz do mapa';
  static const flashcardsLinkedResearch = 'Pesquisa vinculada (opcional)';
  static const flashcardsNoResearch = 'Sem vínculo';
  static const flashcardsNewLimit = 'Novos por dia';
  static const flashcardsReviewLimit = 'Revisões por dia';
  static const flashcardsKind = 'Tipo';
  static const flashcardsFront = 'Frente';
  static const flashcardsBack = 'Verso';
  static const flashcardsExtra = 'Nota extra (opcional)';
  static const flashcardsTags = 'Tags (vírgula)';
  static const flashcardsBidirectional = 'Também criar o inverso';
  static const flashcardsClozeHint =
      'Use {{c1::resposta}} para lacunas. Cada cN vira um cartão.';
  static const flashcardsNotFound = 'Não encontrado.';
  static const flashcardsReveal = 'Toque para revelar';
  static const flashcardsSearchQuestion = 'Pesquisar pergunta';
  static const flashcardsAgain = 'De novo';
  static const flashcardsHard = 'Difícil';
  static const flashcardsGood = 'Bom';
  static const flashcardsEasy = 'Fácil';
  static const flashcardsUndo = 'Desfazer última';
  static const flashcardsBury = 'Adiar para amanhã';
  static const flashcardsSuspend = 'Suspender';
  static const flashcardsUnsuspend = 'Reativar';
  static const flashcardsDelete = 'Deletar flashcard';
  static const flashcardsDeleteConfirm =
      'Este cartão sai do baralho e da fila de estudo. Não dá para desfazer.';
  static const flashcardsSetPriority = 'Definir prioridade';
  static const flashcardsPriorityHigh = 'Alta';
  static const flashcardsPriorityLow = 'Baixa';
  static String flashcardsPriorityValue(int value) => 'Prioridade $value';
  static const flashcardsDone = 'Tudo revisado por hoje.';
  static const flashcardsDoneHint =
      'Volte amanhã — o intervalo cresce quando a lembrança é estável.';
  static const flashcardsLeech =
      'Sanguessuga: este cartão foi suspenso após muitos lapsos.';
  static const flashcardsForecast = 'Previsão (7 dias)';
  static const flashcardsPaceTitle = 'Ritmo e término';
  static const flashcardsPaceHelp =
      'Tempo e cartões/dia vêm das revisões SRS dos últimos 14 dias. '
      'Término = primeira formação de todos os agendados (novos + aprendendo). '
      'O ciclo espaçado continua depois.';
  static const flashcardsPaceNoSample =
      'Estude alguns cartões para medir o tempo médio e o ritmo diário.';
  static const flashcardsPaceMeanTime = 'Tempo médio';
  static const flashcardsPaceCardsDay = 'Cartões/dia';
  static const flashcardsPaceReviewsDay = 'Repetições/dia';
  static const flashcardsPaceRepetitions = 'Repetições';
  static const flashcardsPaceLapses = 'Lapsos';
  static const flashcardsPaceReviewsPerCard = 'Reviews/cartão';
  static const flashcardsPaceAgainRate = 'De novo';
  static const flashcardsPaceRemaining =
      'Ainda por formar';
  static const flashcardsPaceLoad = 'Avaliações restantes';
  static const flashcardsPaceTargetPerDay = 'Cartões por dia';
  static const flashcardsPaceTargetDays = 'Terminar em (dias)';
  static const flashcardsPaceNeedSample = 'Sem ritmo ainda — use um alvo manual.';
  static const flashcardsPaceAllDone = 'Todos os cartões agendados já passaram da formação.';
  static const flashcardsRetention = 'Retenção recente';
  static const flashcardsCards = 'Cartões';
  static const flashcardsSubareas = 'Subáreas';
  static const flashcardsNoCards = 'Nenhum cartão neste baralho.';
  static const flashcardsEditCard = 'Editar cartão';
  static const flashcardsBrowse = 'Cartões';
  static const flashcardsSuspended = 'Suspenso';
  static const flashcardsLeechBadge = 'Sanguessuga';
  static const flashcardsDisclaimer =
      'Repetição espaçada é prática local. Não substitui evidência de pesquisa.';
  static const flashcardsLinkedDecks = 'Baralhos de flashcards';
  static const flashcardsNoLinkedDecks = 'Nenhum baralho vinculado a este nó.';
  static const flashcardsCreateLinkedDeck = 'Criar baralho deste nó';
  static const flashcardsArchiveDeck = 'Arquivar baralho';
  static const flashcardsUnarchiveDeck = 'Desarquivar baralho';
  static const flashcardsEditArea = 'Editar área';
  static const flashcardsEditDeck = 'Editar baralho';
  static const flashcardsNoDecks = 'Nenhum baralho nesta área.';
  static const flashcardsKeyboardHint = 'Espaço revela · 1–4 avalia';
  static const flashcardsLimitsHint =
      'Limites valem só para este baralho, no dia local.';
  static const flashcardsEmptyCta = 'Começar pelo mapa ou por um baralho';
  static const flashcardsHeroToday = 'Hoje';
  static const flashcardsDueTodayZero = 'Nada na fila agora';
  static const flashcardsLaterToday = 'Mais tarde hoje';
  static const flashcardsLimitDeferred = 'Adiados pelo limite';
  static const flashcardsCompletedToday = 'Feitos hoje';
  static const flashcardsUnscheduled = 'Guardados';
  static const flashcardsPractice = 'Praticar';
  static const flashcardsPracticeNow = 'Praticar agora';
  static const flashcardsPracticeDeck = 'Praticar (sem fila)';
  static const flashcardsPracticeArea = 'Praticar (sem fila)';
  static const flashcardsPracticeSaved = 'Praticar guardados';
  static const flashcardsPracticeDone = 'Prática encerrada.';
  static const flashcardsPracticeDoneHint =
      'Isto não alterou a fila espaçada. Programe o cartão quando quiser revisá-lo no tempo.';
  static const flashcardsPracticeSession = 'Prática pontual';
  static const flashcardsSchedule = 'Programar';
  static const flashcardsSaveOnly = 'Só guardar';
  static const flashcardsScheduled = 'Na fila';
  static const flashcardsCaptureHint =
      'Programar entra na fila de hoje. Guardar fica à mão para uma prática pontual.';
  static const flashcardsAdvanced = 'Opções avançadas';
  static const flashcardsAlsoIn = 'Também em';
  static const flashcardsAddPlacement = 'Colocar também em…';
  static const flashcardsPlacementHint =
      'O mesmo tópico pode viver em mais de uma prateleira — Tropicalismo em Música e em História do Brasil.';
  static const flashcardsAliasShortcut = 'atalho';
  static const flashcardsSubareasEmpty = 'Nenhuma subárea ainda.';
  static const flashcardsBackToHub = 'Voltar aos flashcards';
  static const flashcardsRetentionFirm = 'Firme';
  static const flashcardsRetentionWarm = 'Em construção';
  static const flashcardsRetentionFragile = 'Frágil';
  static const flashcardsRetentionUnknown = 'Sem histórico';
  static const flashcardsMoreActions = 'Mais ações';
  static const flashcardsSearchDecksHint = 'Filtrar cartões deste baralho';
  static const flashcardsLinkedShelves = 'Prateleiras de conhecimento';
  static const flashcardsNoLinkedShelves = 'Nenhuma área ligada a este nó.';
  static const flashcardsLinkShelf = 'Ligar área';
  static const flashcardsLinkedResearchEmpty = 'Nenhum nó de pesquisa nesta área.';
  static const flashcardsLinkResearch = 'Ligar pesquisa';
  static const flashcardsPlacementParent = 'Outra prateleira';
  static const flashcardsTodayDigestHelp =
      'O número é o que a sessão vai servir hoje, já com os limites do baralho.';
  static const flashcardsStudySpaced = 'Estudar (espaçado)';
  static const flashcardsPracticeNoQueue = 'Praticar (sem fila)';
  static const flashcardsSessionBucketsHint = 'nesta sessão';
  static const flashcardsTimebox = 'Limite de tempo';
  static const flashcardsTimebox5 = '5 min';
  static const flashcardsTimebox10 = '10 min';
  static const flashcardsTimebox20 = '20 min';
  static const flashcardsTimeboxDone = 'Tempo esgotado.';
  static const flashcardsTimeboxDoneHint =
      'A fila permanece. Volte quando quiser continuar.';
  static const flashcardsQuickDeck = 'Caixa rápida';
  static const flashcardsDismissDisclaimer = 'Entendi';
  static const flashcardsFilterAll = 'Tudo';
  static const flashcardsFilterDue = 'Com fila';
  static const flashcardsFilterFragile = 'Frágil';
  static const flashcardsHasBridge = 'Também em outras prateleiras';
  static const flashcardsRemovePlacement = 'Remover desta prateleira';
  static const flashcardsNewLeafHere = 'Nova folha aqui';
  static const flashcardsAreaSearch = 'Buscar prateleira';
  static const flashcardsAreaNone = 'Sem área';
  static const flashcardsWrapCloze = 'Envolver seleção em lacuna';
  static const flashcardsSeedAncestorsHint =
      'Selecionar um ramo cria os ancestrais automaticamente.';
  static const flashcardsNextDue = 'Próxima';
  static const flashcardsNextDueNow = 'agora';
  static const flashcardsStudyResearch = 'Estudar este foco';
  static const flashcardsNewCardFromResearch = 'Novo cartão deste nó';
  static const flashcardsSrsNotEvidence =
      'Revisar cartões não demonstra o nó de pesquisa.';
  static const flashcardsLearningToday = 'Aprendizado hoje';
  static const flashcardsMapExpand = 'Expandir';
  static const flashcardsMapCollapse = 'Recolher';
  static const flashcardsCaptureArea = 'Prateleira';
  static const flashcardsDueLaterAction = 'Revisar passos de hoje';
  static const flashcardsRemaining = 'Restam nesta fila';
  static const flashcardsImportJson = 'Importar JSON';
  static const flashcardsImportJsonHint =
      'Copie o prompt para uma IA, cole o JSON gerado e carregue os cartões no mapa.';
  static const flashcardsImportPromptTitle = 'Prompt para a IA';
  static const flashcardsImportCopyPrompt = 'Copiar prompt';
  static const flashcardsImportCopied = 'Prompt copiado.';
  static const flashcardsImportPaste = 'Colar JSON';
  static const flashcardsImportPasteHint = '{ "version": 1, "cards": [ ... ] }';
  static const flashcardsImportPickFile = 'Escolher ficheiro';
  static const flashcardsImportPreview = 'Pré-visualizar';
  static const flashcardsImportConfirm = 'Importar agora';
  static const flashcardsImportEmpty = 'Cole ou escolha um JSON para continuar.';
  static const flashcardsImportInvalid = 'JSON inválido';
  static const flashcardsImportDone = 'Importação concluída.';
  static const flashcardsImportPromptLive =
      'Este texto muda quando você cria ou ativa categorias e baralhos.';
  static const flashcardsImportNothingToDo =
      'Nada a criar: os cartões já existem com o mesmo verso.';

  static String flashcardsImportPlanSummary({
    required int create,
    required int skip,
    required int overwrite,
    required int areas,
    required int decks,
  }) {
    return '$create novos · $overwrite atualizados · $skip iguais · '
        '$areas áreas · $decks baralhos';
  }

  static String flashcardsImportResultSummary(FlashcardJsonImportResult result) {
    return flashcardsImportPlanSummary(
      create: result.createdCards,
      skip: result.skippedCards,
      overwrite: result.overwrittenCards,
      areas: result.createdAreas,
      decks: result.createdDecks,
    );
  }

  static String flashcardsHeroStudyCount(int count) => count == 1
      ? '1 cartão agora'
      : '$count cartões agora';

  static String flashcardsMinutes(int minutes) => '~$minutes min';

  static String flashcardsPaceFinishIn(int days, String date) {
    if (days <= 0) return 'Já formados.';
    if (days == 1) return 'Termina amanhã ($date) se mantiver o ritmo.';
    return 'Termina em $days dias ($date) se mantiver o ritmo.';
  }

  static String flashcardsPaceRecommend(int cardsPerDay, int days) {
    if (days < 1) {
      return 'Informe em quantos dias quer formar o restante.';
    }
    if (cardsPerDay <= 0) return 'Nada pendente para formar.';
    return 'Faça $cardsPerDay cartões/dia para formar todos em $days dias.';
  }

  static String flashcardsPaceRemainingCount({
    required int remaining,
    required int reviews,
  }) {
    return '$remaining cartões · $reviews avaliações';
  }

  static String flashcardsPacePercent(double rate) =>
      '${(rate * 100).round()}%';

  static String flashcardsProgress(int current, int total) => '$current/$total';

  static String flashcardsSessionBuckets({
    required int learning,
    required int review,
    required int news,
  }) {
    return '$learning aprendendo · $review revisar · $news novos nesta sessão';
  }

  static String flashcardsNextDueIn(String interval) => 'próxima: $interval';

  static String flashcardsRemainingCount(int count) =>
      count == 1 ? 'Resta 1 cartão' : 'Restam $count cartões';

  static String researchKnowledgeLinkLabel(ResearchKnowledgeLinkKind kind) =>
      switch (kind) {
        ResearchKnowledgeLinkKind.primary => 'Foco',
        ResearchKnowledgeLinkKind.related => 'Relacionada',
        ResearchKnowledgeLinkKind.practice => 'Prática',
      };

  static String flashcardKindLabel(FlashcardKind kind) => switch (kind) {
        FlashcardKind.basic => 'Básico',
        FlashcardKind.reverse => 'Inverso',
        FlashcardKind.cloze => 'Lacuna',
        FlashcardKind.freeRecall => 'Recordação livre',
        FlashcardKind.exercise => 'Exercício',
        FlashcardKind.repertoire => 'Repertório',
      };

  static const researchListEmpty = 'Nenhum nó de pesquisa ainda.';
  static const researchListEmptyHint =
      'Organize conhecimentos e habilidades com pré-requisitos.';
  static const researchTitle = 'Título';
  static const researchTitleRequired = 'Informe um título';
  static const researchDescription = 'Descrição';
  static const researchDescriptionOptional = 'Descrição (opcional)';
  static const researchType = 'Tipo';
  static const researchNotFound = 'Nó de pesquisa não encontrado.';
  static const researchHierarchyTitle = 'Lista hierárquica';
  static const researchSearchHint = 'Buscar por título ou descrição';
  static const researchSearchNoResults = 'Nenhum nó corresponde à busca.';
  static const researchViewList = 'Lista';
  static const researchViewGraph = 'Grafo';
  static const researchGraphEmpty = 'Nenhum nó para exibir no grafo.';
  static const researchShowDependencies = 'Dependências';
  static const researchGraphFocusHint =
      'Pinça para zoom; arraste para mover. Nó em foco destacado.';
  static const researchProgressSummary = 'Progresso';
  static const researchNodeActivitySummary = 'Atividade';
  static const researchSkillRubricTitle = 'Rubrica sugerida (local)';
  static const researchSkillRubricHint =
      'Nível heurístico 0–6 a partir de evidências e sessões. Não altera o status do nó.';
  static const researchSkillRubricStale =
      'Confiança possivelmente defasada — última evidência antiga.';
  static String researchSkillRubricLevel(int level) => 'Nível sugerido: $level/6';
  static const researchActiveFocus = 'Foco atual';
  static const researchStartFocus = 'Iniciar foco';
  static const researchDemonstrate = 'Demonstrar';
  static const researchArchive = 'Arquivar';
  static const researchDemonstratedNote = 'Nota de demonstração';
  static const researchDemonstratedNoteOptional = 'Nota (opcional)';
  static const researchLinkedQuests = 'Missões vinculadas';
  static const researchNoLinkedQuests = 'Nenhuma missão vinculada.';
  static const researchLinkQuest = 'Vincular missão';
  static const researchUnlinkQuest = 'Desvincular missão';
  static const researchQuestPickerEmpty = 'Nenhuma missão disponível.';
  static const researchLinkedPrerequisites = 'Pré-requisitos';
  static const researchNoLinkedPrerequisites = 'Nenhum pré-requisito vinculado.';
  static const researchLinkPrerequisite = 'Vincular pré-requisito';
  static const researchPrerequisitePickerEmpty =
      'Nenhum outro nó disponível para vincular.';
  static const researchWaitingBadge = 'Aguardando';
  static const researchBlockedPrerequisites =
      'Pré-requisitos incompletos para iniciar foco';
  static const researchWipBlocked = 'Já existe uma pesquisa em foco';
  static const researchPrerequisiteCycle =
      'Dependência circular entre nós de pesquisa';

  static const researchLogSession = 'Registrar sessão';
  static const researchSessions = 'Sessões de aprendizado';
  static const researchNoSessions = 'Nenhuma sessão registrada.';
  static const researchSessionMode = 'Modo';
  static const researchSessionDuration = 'Duração (minutos)';
  static const researchSessionDurationInvalid = 'Informe duração válida em minutos';
  static const researchSessionNotesOptional = 'Notas (opcional)';
  static const researchAddEvidence = 'Adicionar evidência';
  static const researchEvidence = 'Evidências';
  static const researchNoEvidence = 'Nenhuma evidência registrada.';
  static const researchEvidenceType = 'Tipo';
  static const researchEvidenceTitle = 'Título';
  static const researchEvidenceBody = 'Conteúdo';
  static const researchEvidenceTitleRequired = 'Informe um título';
  static const researchEvidenceBodyRequired = 'Informe o conteúdo';
  static const researchDemonstrateBlocked =
      'Adicione ao menos uma evidência antes de demonstrar';
  static const researchDeleteEvidenceBlocked =
      'Não é possível remover a última evidência de um nó demonstrado';
  static const researchEvidenceSessionOptional = 'Sessão (opcional)';
  static const researchEvidenceNoSession = 'Nenhuma sessão';

  static String researchSessionModeLabel(LearningSessionMode mode) =>
      switch (mode) {
        LearningSessionMode.read => 'Leitura',
        LearningSessionMode.watch => 'Assistir',
        LearningSessionMode.practice => 'Prática',
        LearningSessionMode.review => 'Revisão',
      };

  static String researchEvidenceTypeLabel(ResearchEvidenceType type) =>
      switch (type) {
        ResearchEvidenceType.note => 'Nota',
        ResearchEvidenceType.practiceLog => 'Log de prática',
        ResearchEvidenceType.summary => 'Resumo',
      };

  static String researchSessionSummary(int minutes, DateTime startedAt) {
    final date =
        '${startedAt.day.toString().padLeft(2, '0')}/${startedAt.month.toString().padLeft(2, '0')}';
    return '$minutes min · $date';
  }

  static String researchProgressSummaryValue(int demonstrated, int activeTotal) =>
      '$demonstrated/$activeTotal demonstrados';

  static String researchNodeActivitySummaryValue({
    required int sessionCount,
    required int totalDurationMinutes,
    required int evidenceCount,
  }) {
    final sessions = sessionCount == 1 ? '1 sessão' : '$sessionCount sessões';
    final evidence = evidenceCount == 1 ? '1 evidência' : '$evidenceCount evidências';
    return '$sessions · $totalDurationMinutes min · $evidence';
  }

  static String researchStatusLabel(ResearchNodeStatus status) => switch (status) {
        ResearchNodeStatus.available => 'Disponível',
        ResearchNodeStatus.inResearch => 'Em foco',
        ResearchNodeStatus.demonstrated => 'Demonstrado',
        ResearchNodeStatus.archived => 'Arquivado',
      };

  static String researchTypeLabel(ResearchNodeType type) => switch (type) {
        ResearchNodeType.skill => 'Habilidade',
        ResearchNodeType.knowledge => 'Conhecimento',
        ResearchNodeType.capability => 'Capacidade',
        ResearchNodeType.practice => 'Prática',
      };

  static String researchSelectedPrerequisitesCount(int count) => count == 1
      ? '1 pré-requisito selecionado'
      : '$count pré-requisitos selecionados';

  // Decisions (Iteration 6)
  static const newDecision = 'Nova decisão';
  static const editDecision = 'Editar decisão';
  static const decisionTitle = 'Título';
  static const decisionTitleRequired = 'Informe um título';
  static const decisionContext = 'Contexto';
  static const decisionContextRequired = 'Informe o contexto';
  static const decisionChoice = 'Decisão tomada';
  static const decisionChoiceRequired = 'Informe a decisão tomada';
  static const decisionAlternatives = 'Alternativas consideradas';
  static const decisionAddAlternative = 'Adicionar alternativa';
  static const decisionAlternativeHint = 'Ex.: continuar no emprego atual';
  static const decisionCriteria = 'Critérios';
  static const decisionAddCriterion = 'Adicionar critério';
  static const decisionCriterionHint = 'Ex.: impacto financeiro';
  static const decisionRisks = 'Riscos';
  static const decisionAddRisk = 'Adicionar risco';
  static const decisionRiskHint = 'Ex.: prazo apertado';
  static const decisionReversibility = 'Reversibilidade';
  static const questLinkedDecisions = 'Decisões vinculadas';
  static const questNoLinkedDecisions = 'Nenhuma decisão vinculada.';
  static const decisionCreateLinked = 'Registrar decisão';
  static const decisionLinkExisting = 'Vincular decisão existente';
  static const decisionUnlinkQuest = 'Desvincular decisão';
  static const decisionPickerEmpty = 'Nenhuma decisão registrada ainda.';
  static const colonyActiveQuests = 'Missões ativas';
  static const decisions = 'Decisões';
  static const decisionListEmpty = 'Nenhuma decisão registrada.';
  static const decisionListEmptyHint =
      'Registre decisões importantes para revisitar depois.';
  static const decisionAssumptions = 'Premissas';
  static const decisionAddAssumption = 'Adicionar premissa';
  static const decisionAssumptionHint = 'Ex.: mercado permanece estável';
  static const decisionExpectedOutcomes = 'Resultados esperados';
  static const decisionAddExpectedOutcome = 'Adicionar resultado';
  static const decisionExpectedOutcomeHint = 'Ex.: mais tempo livre';
  static const decisionReviewAt = 'Revisar em';
  static const decisionReviewAtClear = 'Limpar data de revisão';
  static const decisionOutcomeReview = 'Revisão do resultado';
  static const decisionOutcomeReviewHint = 'O que aconteceu depois da decisão?';
  static const decisionDelete = 'Excluir decisão';
  static const decisionDeleteConfirm =
      'Excluir esta decisão? Vínculos com missões serão removidos.';

  static String decisionReversibilityLabel(DecisionReversibility value) =>
      switch (value) {
        DecisionReversibility.easy => 'Fácil de reverter',
        DecisionReversibility.moderate => 'Reversão moderada',
        DecisionReversibility.hard => 'Difícil de reverter',
      };

  static String decisionSelectedCount(int count) =>
      count == 1 ? '1 decisão selecionada' : '$count decisões selecionadas';

  // Finance (Iteration 19)
  // Relations (Iteration 47)
  static const peopleTitle = 'Pessoas';
  static const peopleDisclaimer =
      'Registro pessoal local. Minimize dados de terceiros; não é CRM.';
  static const peopleEmpty = 'Nenhuma pessoa registrada.';
  static const peopleEmptyHint =
      'Adicione pessoas importantes da sua colônia pessoal.';
  static const personNew = 'Nova pessoa';
  static const personEdit = 'Editar pessoa';
  static const personDisplayName = 'Nome';
  static const personNameRequired = 'Informe o nome';
  static const personPreferredNameOptional = 'Apelido (opcional)';
  static const personRelationshipTypesOptional =
      'Tipos de relação (opcional)';
  static const personRelationshipTypesHint = 'amiga, família, colega';
  static const personNotesOptional = 'Notas (opcional)';
  static const personArchive = 'Arquivar';
  static const personLogInteraction = 'Registrar interação';
  static const personInteractionKind = 'Tipo';
  static const personInteractionNote = 'Nota (opcional)';
  static const personInteractionsEmpty = 'Nenhuma interação registrada.';

  static String interactionKindLabel(InteractionKind kind) => switch (kind) {
        InteractionKind.meeting => 'Encontro',
        InteractionKind.call => 'Ligação',
        InteractionKind.message => 'Mensagem',
        InteractionKind.gathering => 'Reunião',
        InteractionKind.help => 'Ajuda',
        InteractionKind.conflict => 'Conflito',
        InteractionKind.decision => 'Decisão',
        InteractionKind.promise => 'Promessa',
        InteractionKind.gift => 'Presente',
        InteractionKind.introduction => 'Introdução',
        InteractionKind.other => 'Outro',
      };

  // Inventory (Iteration 42)
  static const inventoryTitle = 'Inventário';
  static const inventoryHint =
      'Registro pessoal local. Sem avaliação de mercado nem localização GPS.';
  static const inventoryEmpty = 'Nenhum item no inventário.';
  static const inventoryEmptyHint =
      'Adicione equipamentos, documentos e outros bens pessoais.';
  static const inventoryNewItem = 'Novo item';
  static const inventoryEditItem = 'Editar item';
  static const inventoryName = 'Nome';
  static const inventoryNameRequired = 'Informe o nome';
  static const inventoryCategory = 'Categoria';
  static const inventoryStatus = 'Status';
  static const inventoryLocationOptional = 'Local (opcional)';
  static const inventoryNotesOptional = 'Notas (opcional)';
  static const inventoryPurchaseDateOptional = 'Data de compra (opcional)';
  static const inventoryPurchasePriceOptional = 'Preço de compra (opcional)';
  static const inventoryCurrency = 'Moeda';
  static const inventoryWarrantyEndOptional = 'Fim da garantia (opcional)';
  static const inventoryDateNone = 'Não informado';
  static const inventoryPriceInvalid = 'Preço inválido';
  static const inventoryArchive = 'Arquivar';
  static const inventoryLinkedQuests = 'Missões vinculadas';
  static const inventoryNoLinkedQuests = 'Nenhuma missão vinculada.';
  static const inventoryLinkQuest = 'Vincular missão';
  static const inventoryUnlinkQuest = 'Desvincular missão';
  static const inventoryQuestPickerEmpty = 'Nenhuma missão disponível.';

  static String inventoryPriceLabel(int minor, String currency) {
    final major = (minor / 100).toStringAsFixed(2);
    return '$currency $major';
  }

  static const travelTitle = 'Viagens';
  static const travelDisclaimer =
      'Planejamento pessoal local. Não reserva voos, hotéis nem recomenda destinos.';
  static const travelEmpty = 'Nenhuma viagem registrada.';
  static const travelEmptyHint =
      'Registre viagens e expedições da sua colônia pessoal.';
  static const tripNew = 'Nova viagem';
  static const tripEdit = 'Editar viagem';
  static const tripTitle = 'Título';
  static const tripTitleRequired = 'Informe o título';
  static const tripDestinationsOptional = 'Destinos (opcional)';
  static const tripDestinationsHint = 'São Paulo, Campinas';
  static const tripStartOptional = 'Início (opcional)';
  static const tripEndOptional = 'Fim (opcional)';
  static const tripPurposeOptional = 'Propósito (opcional)';
  static const tripNotesOptional = 'Notas (opcional)';
  static const tripDateNone = 'Não informado';
  static const tripStatus = 'Status';
  static const tripComplete = 'Concluir';
  static const tripPackingList = 'Lista de bagagem';
  static const tripNoPackingItems = 'Nenhum item na lista de bagagem.';
  static const tripPackingEmptyHint =
      'Use o ícone de vínculo para adicionar itens do inventário.';
  static const tripLinkInventoryItem = 'Vincular item';
  static const tripUnlinkInventoryItem = 'Desvincular item';
  static const tripInventoryPickerEmpty = 'Nenhum item de inventário disponível.';

  static const timelineHubTitle = 'Linha do tempo';
  static const timelineImport = 'Importar Timeline';
  static const timelineReimport = 'Substituir JSON';
  static const timelineImportedBadge = 'Importado do Google Maps';
  static const timelineHowToTitle = 'Como exportar no telemóvel';
  static const timelineHowToLead =
      'A Timeline vive no aparelho. Não há API: exporte o JSON no Maps e traga o ficheiro para a colónia. Um novo import apaga o anterior e grava este.';
  static const timelineAndroidTitle = 'Android';
  static const timelineAndroidSteps =
      '1. Abra Ajustes → Localização.\n'
      '2. Serviços de localização → Timeline.\n'
      '3. Exportar dados da Timeline.\n'
      '4. Guarde o ficheiro (Timeline.json ou Linha do tempo.json).\n'
      '5. Volte aqui e escolha o JSON.';
  static const timelineIosTitle = 'iPhone / iPad';
  static const timelineIosSteps =
      '1. Abra o Google Maps.\n'
      '2. Toque na foto de perfil.\n'
      '3. Ajustes → Conteúdo pessoal.\n'
      '4. Exportar dados da Timeline.\n'
      '5. Partilhe/guarde o JSON e abra-o neste ecrã.';
  static const timelineHelpLink = 'Ajuda oficial do Google Maps';
  static const timelinePickJson = 'Escolher ficheiro JSON';
  static const timelinePasteJson = 'Colar JSON';
  static const timelinePasteHint = 'Cole o conteúdo de Timeline.json';
  static const timelineReadError = 'Não foi possível ler o ficheiro.';
  static const timelineParseError = 'JSON inválido ou não é a Timeline on-device.';
  static const timelinePreviewTitle = 'Pré-visualização';
  static const timelineOverwriteTitle = 'Substituir Timeline importada?';
  static const timelineOverwriteBody =
      'Já existe um import. O JSON antigo será apagado e este passa a ser a fonte. Os nomes e categorias que você atribuiu aos lugares são mantidos.';
  static const timelineOverwriteConfirm = 'Apagar o antigo e importar';
  static const timelineImportConfirm = 'Importar para a colónia';
  static const timelineImportSuccess = 'Timeline importada.';
  static const timelineEmptyHub =
      'Importe a Timeline do Google Maps para reconstruir dia, viagens, estatísticas, lugares, cidades e o mundo.';
  static const timelineEmptyHint =
      'Categorias do Maps (gastronomia, hotéis…) não vêm no JSON. Inferimos por horário e você pode rotular cada lugar.';
  static const timelineTabDay = 'Dia';
  static const timelineTabTrips = 'Viagens';
  static const timelineTabStats = 'Estatísticas';
  static const timelineTabPlaces = 'Lugares';
  static const timelineTabCities = 'Cidades';
  static const timelineTabWorld = 'Mundo';
  static const timelineTabRhythm = 'Ritmo';
  static const timelineTabSignals = 'Sinais';
  static const timelineNoDayData = 'Nenhum segmento neste dia.';
  static const timelinePickDay = 'Dias com dados';
  static const timelineMemoryTrips = 'Viagens da Timeline';
  static const timelineManualTrips = 'Viagens manuais';
  static const timelineNoMemoryTrips =
      'O JSON não trouxe blocos timelineMemory.trip. Distâncias e destinos aparecem quando o Maps os agrupou.';
  static const timelineTransportTitle = 'Deslocamentos';
  static const timelineVisitHoursTitle = 'Horas em lugares';
  static const timelineHomeWorkTitle = 'Casa e trabalho';
  static const timelineQualityTitle = 'Qualidade do rasto';
  static const timelineParkingTitle = 'Estacionamentos';
  static const timelineNotesTitle = 'Notas da Timeline';
  static const timelinePersonaTitle = 'Persona vs. real';
  static const timelineFrequentTitle = 'Lugares frequentes';
  static const timelineLabelPlace = 'Rotular lugar';
  static const timelineCustomName = 'Nome (opcional)';
  static const timelineCategory = 'Categoria';
  static const timelineSaveLabel = 'Guardar rótulo';
  static const timelineWalk = 'A pé';
  static const timelineDrive = 'Carro';
  static const timelineTransit = 'Transportes';
  static const timelineFly = 'Avião';
  static const timelineCycling = 'Bicicleta';
  static const timelineOtherMode = 'Outro';
  static const timelineUnknownPlace = 'Lugar sem nome';
  static const timelineInferred = 'Categoria inferida';
  static const timelineProvenanceHint =
      'Fonte: importação local. Sem diagnóstico médico. Sem nomes oficiais do Maps.';
  static const timelineHelpUrl =
      'https://support.google.com/maps/answer/14164705';
  static const timelineHeatmapHint =
      'Minutos parados por hora da semana (segunda → domingo).';
  static const timelineNightsAway = 'Noites fora';
  static const timelineRadius = 'Raio desde casa';
  static const timelineCommuteDays = 'Dias casa+trabalho';
  static const timelineGaps = 'Buracos > 2 h';
  static const timelineImplausible = 'Trechos implausíveis';
  static const timelineNoPlaces = 'Nenhuma visita geolocalizada.';
  static const timelineNoCities =
      'Sem cidades no gazeteer para estas coordenadas.';
  static const timelineNoCountries = 'Nenhum país identificado.';
  static const timelineNoParking = 'Nenhum estacionamento no JSON.';
  static const timelineNoNotes = 'Nenhuma nota timelineMemory.';
  static const timelineAffinityDeclared = 'Afinidade (Maps)';
  static const timelineAffinityActual = 'Quilómetros reais';
  static const timelinePlacesInCategory = 'lugares';
  static const timelineVisits = 'visitas';
  static const timelineHoursShort = 'h';
  static const timelineKmShort = 'km';
  static const timelineDestinations = 'destinos';
  static const timelineHierarchyNested = 'Aninhado';
  static const timelineTimeless = 'Sem tempo';
  static const timelineSensorTitle = 'Sensores brutos';
  static const timelineRawPositions = 'posições GPS';
  static const timelineSensorHits = 'leituras de atividade';
  static const timelineRange = 'Período no ficheiro';
  static const timelineFileMeta = 'Ficheiro';

  static String timelineCategoryLabel(TimelinePlaceCategory category) =>
      switch (category) {
        TimelinePlaceCategory.home => 'Casa',
        TimelinePlaceCategory.work => 'Trabalho',
        TimelinePlaceCategory.gastronomy => 'Gastronomia',
        TimelinePlaceCategory.shopping => 'Compras',
        TimelinePlaceCategory.hotels => 'Hotéis',
        TimelinePlaceCategory.culture => 'Cultura',
        TimelinePlaceCategory.attractions => 'Atrações',
        TimelinePlaceCategory.airports => 'Aeroportos',
        TimelinePlaceCategory.transit => 'Trânsito',
        TimelinePlaceCategory.other => 'Outros',
      };

  static String timelineModeLabel(String id) => switch (id) {
        'walking' => timelineWalk,
        'driving' => timelineDrive,
        'transit' => timelineTransit,
        'flying' => timelineFly,
        'cycling' => timelineCycling,
        'other' => timelineOtherMode,
        'unknown' => 'Desconhecido',
        _ => id,
      };

  static String timelineDurationHours(Duration d) {
    final hours = d.inMinutes / 60.0;
    if (hours >= 10) return '${hours.round()} h';
    if (hours >= 1) return '${hours.toStringAsFixed(1)} h';
    return '${d.inMinutes} min';
  }

  static String timelineKm(double km) {
    if (km >= 100) return '${km.round()} km';
    if (km >= 10) return '${km.toStringAsFixed(1)} km';
    return '${km.toStringAsFixed(2)} km';
  }

  static String timelinePreviewCounts({
    required int visits,
    required int activities,
    required int trips,
    required int places,
  }) {
    return '$visits visitas · $activities deslocamentos · $trips viagens · $places placeIds';
  }

  static String timelineOverwriteSummary(String fileName, DateTime at) {
    final d = at.toLocal();
    final stamp =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return 'Import atual: $fileName ($stamp)';
  }

  static String timelineWeekdayShort(int mondayIndex) => const [
        'Seg',
        'Ter',
        'Qua',
        'Qui',
        'Sex',
        'Sáb',
        'Dom',
      ][mondayIndex.clamp(0, 6)];

  static String tripStatusLabel(TripStatus status) => switch (status) {
        TripStatus.planned => 'Planejada',
        TripStatus.active => 'Ativa',
        TripStatus.completed => 'Concluída',
        TripStatus.cancelled => 'Cancelada',
      };

  static const homeMaintenanceTitle = 'Casa';
  static const homeMaintenanceDisclaimer =
      'Registro pessoal local. Não agenda serviços externos nem recomenda fornecedores.';
  static const homeMaintenanceEmpty = 'Nenhuma manutenção registrada.';
  static const homeMaintenanceEmptyHint =
      'Adicione tarefas de manutenção da casa e dos sistemas.';
  static const homeMaintenanceNew = 'Nova manutenção';
  static const homeMaintenanceEdit = 'Editar manutenção';
  static const homeMaintenanceTitleField = 'Título';
  static const homeMaintenanceTitleRequired = 'Informe o título';
  static const homeMaintenanceSystem = 'Item ou sistema';
  static const homeMaintenanceSystemRequired = 'Informe o item ou sistema';
  static const homeMaintenanceCadenceOptional =
      'Periodicidade em dias (opcional)';
  static const homeMaintenanceCadenceInvalid =
      'Periodicidade deve ser um número positivo';
  static const homeMaintenanceVendorOptional = 'Fornecedor (opcional)';
  static const homeMaintenanceNotesOptional = 'Notas (opcional)';
  static const homeMaintenanceLinkedInventory = 'Item de inventário (opcional)';
  static const homeMaintenanceNoInventoryLink = 'Nenhum vínculo';
  static const homeMaintenanceLinkedInventoryHint =
      'Vincule um item do inventário quando fizer sentido.';
  static const homeMaintenanceLinkedInventoryEmpty =
      'Nenhum item de inventário ativo para vincular.';
  static const homeMaintenanceMarkDone = 'Marcar feito';
  static const homeMaintenanceArchive = 'Arquivar';

  static String homeMaintenanceCadenceLabel(int days) =>
      days == 1 ? 'A cada 1 dia' : 'A cada $days dias';

  static String homeMaintenanceNextDue(DateTime due) {
    final local = due.toLocal();
    final d =
        '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    return 'Próxima: $d';
  }

  static const zonesTitle = 'Zonas';
  static const zonesDisclaimer =
      'Registro pessoal local. Sem GPS nem geofencing; não bloqueia o dispositivo.';
  static const zonesEmpty = 'Nenhuma zona registrada.';
  static const zonesEmptyHint =
      'Defina contextos como casa, escritório ou avião com capacidades possíveis.';
  static const zoneNew = 'Nova zona';
  static const zoneEdit = 'Editar zona';
  static const zoneName = 'Nome';
  static const zoneNameRequired = 'Informe o nome';
  static const zoneLocationOptional = 'Local (rótulo, opcional)';
  static const zoneCapabilitiesOptional =
      'Capacidades (separadas por vírgula)';
  static const zoneCapabilitiesHint = 'leitura, notas, chamadas';
  static const zoneUnavailableWorkTypesOptional =
      'Trabalho indisponível (vírgula, opcional)';
  static const zoneUnavailableWorkTypesHint =
      'ex.: restRecreation, travelPlanning';

  static String zoneUnavailableWorkTypesLabel(List<String> types) =>
      'Indisponível: ${types.join(', ')}';

  static const zoneConnectivity = 'Conectividade';
  static const zoneNotesOptional = 'Notas (opcional)';
  static const zoneArchive = 'Arquivar';
  static const zoneLinkedTrips = 'Viagens vinculadas';
  static const zoneNoLinkedTrips = 'Nenhuma viagem vinculada.';
  static const zoneLinkTrip = 'Vincular viagem';
  static const zoneUnlinkTrip = 'Desvincular viagem';
  static const zoneTripPickerEmpty = 'Nenhuma viagem disponível.';

  static String zoneConnectivityLabel(ZoneConnectivity c) => switch (c) {
        ZoneConnectivity.online => 'Online',
        ZoneConnectivity.offline => 'Offline',
        ZoneConnectivity.limited => 'Limitada',
        ZoneConnectivity.unknown => 'Desconhecida',
      };

  static const syncTitle = 'Sincronização';
  static const syncDisclaimer =
      'Sync opcional e offline-first. Outbox local; sem rede nesta fatia.';
  static const syncEmpty = 'Nenhuma operação pendente.';
  static const syncEmptyHint =
      'Mutações piloto (tarefa, missão, inventário, compromisso, viagem, zona) entram na outbox local.';
  static const syncDevice = 'Dispositivo local';
  static const syncPendingCount = 'Pendentes na outbox';
  static const syncProcessLocal = 'Processar local (sem rede)';
  static const syncProcessLocalEmpty =
      'Nada para processar — outbox já está vazia.';
  static const syncProcessLocalError =
      'Não foi possível processar a outbox local.';

  static String syncPendingLabel(int count) =>
      count == 1 ? '1 operação pendente' : '$count operações pendentes';

  static String syncProcessLocalDone(int count) => count == 1
      ? '1 operação processada localmente (sem rede).'
      : '$count operações processadas localmente (sem rede).';

  static String syncEntityTypeLabel(String entityType) => switch (entityType) {
        'task' => 'Tarefa',
        'quest' => 'Missão',
        'inventory_item' => 'Inventário',
        'commitment' => 'Compromisso',
        'trip' => 'Viagem',
        'context_zone' => 'Zona',
        _ => entityType,
      };

  static const integrationsTitle = 'Integrações';
  static const integrationsDisclaimer =
      'Opt-in local. Importação ICS somente leitura; sem conta nem write-back no calendário do SO.';
  static const integrationsCalendarIcs = 'Calendário ICS';
  static const integrationsOptIn = 'Permitir importação ICS';
  static const integrationsEnabled = 'Ativa — pode importar arquivos .ics';
  static const integrationsDisabled = 'Desligada — histórico local permanece';
  static const integrationsImportIcs = 'Importar .ics';
  static const integrationsPasteIcs = 'Colar ICS';
  static const integrationsPasteHint = 'BEGIN:VCALENDAR…';
  static const integrationsPreview = 'Pré-visualizar';

  static const integrationsConfirmImport = 'Confirmar importação';
  static const integrationsAlsoSchedule = 'Criar blocos na agenda';
  static const integrationsAlsoScheduleHint =
      'Adiciona cada evento como bloco local (modo reunião). Sem write-back no calendário do SO.';
  static const integrationsNeedConsent =
      'Ative o opt-in de calendário ICS antes de importar.';
  static const integrationsIcsReadError = 'Não foi possível ler o arquivo.';
  static const integrationsIcsParseError = 'ICS inválido';
  static const integrationsImportedEvents = 'Eventos importados';
  static const integrationsEmpty = 'Nenhum evento importado.';
  static const integrationsEmptyHint =
      'Importe um arquivo .ics offline após conceder opt-in.';

  static String integrationsPreviewCount(int n) =>
      'Pré-visualização ($n evento${n == 1 ? '' : 's'})';
  static String integrationsImportDone(int n) =>
      '$n evento${n == 1 ? '' : 's'} importado${n == 1 ? '' : 's'}.';

  static const commitmentsTitle = 'Compromissos';
  static const commitmentsDisclaimer =
      'Registro pessoal local. Lembra promessas; sem scoring social.';
  static const commitmentsEmpty = 'Nenhum compromisso aberto.';
  static const commitmentsEmptyHint =
      'Registre promessas feitas a pessoas ou grupos da colônia.';
  static const commitmentNew = 'Novo compromisso';
  static const commitmentEdit = 'Editar compromisso';
  static const commitmentDescription = 'Descrição';
  static const commitmentDescriptionRequired = 'Informe a descrição';
  static const commitmentMadeBy = 'Feito por';
  static const commitmentMadeToLabel = 'Para (nome ou rótulo)';
  static const commitmentMadeToRequired =
      'Informe para quem é o compromisso';
  static const commitmentNotesOptional = 'Notas (opcional)';
  static const commitmentLinkedQuest = 'Missão vinculada (opcional)';
  static String commitmentLinkedQuestTitle(String title) => 'Missão: $title';
  static const commitmentNoQuestLink = 'Sem vínculo com missão';
  static const commitmentLinkedQuestHint =
      'Escolha “Sem vínculo com missão” para limpar.';
  static const commitmentStatus = 'Status';
  static const commitmentMarkKept = 'Cumprido';
  static const commitmentMarkBroken = 'Quebrado';
  static const commitmentMarkCancelled = 'Cancelar';
  static const commitmentPersonLinked = 'Pessoa vinculada';
  static const commitmentOrgLinked = 'Organização vinculada';

  static String commitmentStatusLabel(CommitmentStatus status) =>
      switch (status) {
        CommitmentStatus.open => 'Aberto',
        CommitmentStatus.kept => 'Cumprido',
        CommitmentStatus.broken => 'Quebrado',
        CommitmentStatus.cancelled => 'Cancelado',
      };

  static String commitmentDue(DateTime due) {
    final local = due.toLocal();
    final d =
        '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    return 'Prazo: $d';
  }

  static const organizationsTitle = 'Organizações';
  static const organizationsDisclaimer =
      'Registro pessoal local. Minimize dados de terceiros; não é CRM.';
  static const organizationsEmpty = 'Nenhuma organização registrada.';
  static const organizationsEmptyHint =
      'Adicione empresas, clínicas, famílias e outros grupos da colônia.';
  static const organizationNew = 'Nova organização';
  static const organizationEdit = 'Editar organização';
  static const organizationName = 'Nome';
  static const organizationNameRequired = 'Informe o nome';
  static const organizationKind = 'Tipo';
  static const organizationNotesOptional = 'Notas (opcional)';
  static const organizationArchive = 'Arquivar';
  static const personMemberships = 'Organizações';
  static const personNoMemberships = 'Nenhuma organização vinculada.';
  static const personLinkOrganization = 'Vincular organização';
  static const personUnlinkOrganization = 'Desvincular organização';
  static const organizationMembers = 'Membros';
  static const organizationNoMembers = 'Nenhuma pessoa vinculada.';
  static const organizationLinkPerson = 'Vincular pessoa';
  static const organizationUnlinkPerson = 'Desvincular pessoa';
  static const membershipPickerEmpty = 'Nada disponível para vincular.';

  static String organizationKindLabel(OrganizationKind kind) => switch (kind) {
        OrganizationKind.company => 'Empresa',
        OrganizationKind.university => 'Universidade',
        OrganizationKind.family => 'Família',
        OrganizationKind.friends => 'Amigos',
        OrganizationKind.association => 'Associação',
        OrganizationKind.community => 'Comunidade',
        OrganizationKind.vendor => 'Fornecedor',
        OrganizationKind.clinic => 'Clínica',
        OrganizationKind.financial => 'Financeira',
        OrganizationKind.other => 'Outro',
      };

  static String inventoryCategoryLabel(InventoryCategory category) =>
      switch (category) {
        InventoryCategory.electronics => 'Eletrônicos',
        InventoryCategory.document => 'Documento',
        InventoryCategory.clothing => 'Roupas',
        InventoryCategory.tool => 'Ferramenta',
        InventoryCategory.consumable => 'Consumível',
        InventoryCategory.media => 'Mídia',
        InventoryCategory.other => 'Outro',
      };

  static String inventoryStatusLabel(InventoryItemStatus status) =>
      switch (status) {
        InventoryItemStatus.active => 'Ativo',
        InventoryItemStatus.stored => 'Armazenado',
        InventoryItemStatus.lent => 'Emprestado',
        InventoryItemStatus.disposed => 'Descartado',
        InventoryItemStatus.archived => 'Arquivado',
      };

  static const healthTitle = 'Saúde';
  static const healthDisclaimer = HealthSafetyPolicy.disclaimer;
  static const healthSeekCareHint = HealthSafetyPolicy.seekCareHint;
  static const healthEmpty = 'Nenhuma condição registrada.';
  static const healthEmptyHint =
      'Registre sintomas ou condições autorrelatadas. Não é diagnóstico.';
  static const healthNewCondition = 'Nova condição';
  static const healthAppointmentsTitle = 'Consultas (lembrete local)';
  static const healthAppointmentsEmpty = 'Nenhuma consulta agendada.';
  static const healthAppointmentsHint =
      'Lembrete pessoal. Não agenda com clínicas nem diagnostica.';
  static const healthNewAppointment = 'Nova consulta';
  static const healthAppointmentTitle = 'Título';
  static const healthAppointmentTitleRequired = 'Informe o título';
  static const healthAppointmentWhen = 'Data/hora';
  static const healthAppointmentLocationOptional = 'Local (opcional)';
  static const healthAppointmentClinicianOptional = 'Profissional (opcional)';
  static const healthAppointmentMarkDone = 'Marcar concluída';
  static const healthAppointmentMarkCancelled = 'Marcar cancelada';
  static const healthEditAppointment = 'Editar consulta';
  static const healthEditCondition = 'Editar condição';
  static const healthConditionTitle = 'Título';
  static const healthConditionTitleRequired = 'Informe o título';
  static const healthConditionType = 'Tipo';
  static const healthConditionStatus = 'Status';
  static const healthSeverity = 'Intensidade (1–5)';
  static const healthSeverityNone = 'Não informada';
  static const healthBodyRegionOptional = 'Região do corpo (opcional)';
  static const healthNotesOptional = 'Notas (opcional)';
  static const healthArchive = 'Arquivar';
  static const healthLogSymptom = 'Registrar sintoma';
  static const healthSymptomTimeline = 'Sintomas recentes';
  static const healthSymptomEmpty = 'Nenhum sintoma registrado nesta condição.';
  static const healthSymptomIntensity = 'Intensidade (1–5)';
  static const healthSymptomNoteOptional = 'Nota (opcional)';

  static String healthSeverityValue(int value) => 'Intensidade $value';

  static String healthSymptomIntensityValue(int value) => 'Intensidade $value';

  static String healthConditionTypeLabel(HealthConditionType type) =>
      switch (type) {
        HealthConditionType.symptom => 'Sintoma',
        HealthConditionType.diagnosisReported => 'Diagnóstico relatado',
        HealthConditionType.injury => 'Lesão',
        HealthConditionType.recovery => 'Recuperação',
        HealthConditionType.context => 'Contexto',
      };

  static String healthConditionStatusLabel(HealthConditionStatus status) =>
      switch (status) {
        HealthConditionStatus.active => 'Ativa',
        HealthConditionStatus.monitoring => 'Em monitoramento',
        HealthConditionStatus.resolved => 'Resolvida',
        HealthConditionStatus.archived => 'Arquivada',
      };

  static const financeLedgerTitle = 'Finanças';
  static const financeDisclaimer =
      'Registro pessoal local. Não diagnostica situação financeira, não recomenda investimentos e não substitui contador ou assessor.';
  static const financeShowValues = 'Mostrar valores';
  static const financeHideValues = 'Ocultar valores';
  static const financeAccountsSection = 'Contas';
  static const financeRecentTransactions = 'Transações';
  static const financeFilterPeriod = 'Período';
  static const financeFilterAccount = 'Conta';
  static const financeFilterAllAccounts = 'Todas as contas';
  static const financeFilterEmpty = 'Nenhuma transação neste filtro.';
  static const financePeriod7d = '7 dias';
  static const financePeriod30d = '30 dias';
  static const financePeriod90d = '90 dias';
  static const financePeriodAll = 'Tudo';
  static const financeAccountsEmpty = 'Nenhuma conta registrada.';

  static String financePeriodLabel(FinancePeriod period) => switch (period) {
        FinancePeriod.days7 => financePeriod7d,
        FinancePeriod.days30 => financePeriod30d,
        FinancePeriod.days90 => financePeriod90d,
        FinancePeriod.all => financePeriodAll,
      };
  static const financeAccountsEmptyHint =
      'Adicione contas manualmente para acompanhar saldos e movimentações.';
  static const financeTransactionsEmpty = 'Nenhuma transação registrada.';
  static const financeNewAccount = 'Nova conta';
  static const financeEditAccount = 'Editar conta';
  static const financeArchiveAccount = 'Arquivar conta';
  static const financeIncludeInNetWorth = 'Incluir no patrimônio';
  static const financeMaskValuesByDefault = 'Ocultar valores por padrão';
  static const financeNetWorthSection = 'Patrimônio';
  static const financeNetWorthEmpty =
      'Nenhuma conta incluída no patrimônio.';
  static const financeNetWorthExcludedHint = 'Fora do patrimônio';
  static const financeNetWorthHint =
      'Soma das contas marcadas para patrimônio. Sem conversão de moeda.';
  static const financeBudgetsSection = 'Orçamentos do mês';
  static const financeBudgetsEmpty = 'Nenhum orçamento por categoria.';
  static const financeBudgetsHint =
      'Limite mensal por categoria. Gasto = saídas categorizadas no mês atual.';
  static const financeNewBudget = 'Novo orçamento';
  static const financeEditBudget = 'Editar orçamento';
  static const financeBudgetLimit = 'Limite mensal';
  static const financeBudgetOverLimit = 'Acima do limite';
  static const financeBudgetWithinLimit = 'Dentro do limite';
  static const financeExportCsv = 'Exportar CSV';
  static const financeExportCsvEmpty = 'Nenhuma transação para exportar.';
  static const financeExportCsvHint =
      'CSV local com fingerprint para deduplicação futura. Não envia dados a bancos.';
  static const financeImportCsv = 'Importar CSV';
  static const financeImportCsvHint =
      'Cola o CSV exportado, analise o plano e confirme. Fingerprints existentes são ignorados. Local-only.';
  static const financeImportCsvPaste = 'Conteúdo CSV';
  static const financeImportCsvPreviewAction = 'Analisar';
  static const financeImportCsvApplyAction = 'Aplicar importação';
  static const financeImportCsvAction = 'Importar';
  static const financeImportCsvEmpty = 'Cole o conteúdo CSV';
  static const financeImportCsvInvalid =
      'CSV inválido. Verifique o cabeçalho e as linhas.';
  static const financeImportCsvNothingToApply =
      'Nada novo para importar (todas as linhas são duplicadas).';
  static const financeImportCsvAccountOverride = 'Conta destino (opcional)';
  static const financeImportCsvAccountFromCsv = 'Usar account_id do CSV';

  static String financeImportCsvPlanSummary(int imported, int duplicates) =>
      'Novas: $imported · Duplicadas: $duplicates';

  static String financeImportCsvResult(int imported, int duplicates) =>
      'Importadas: $imported · Ignoradas (duplicadas): $duplicates';
  static const financeAddTransaction = 'Nova transação';
  static const financeAccountName = 'Nome da conta';
  static const financeAccountNameRequired = 'Informe o nome da conta';
  static const financeInstitution = 'Instituição';
  static const financeInstitutionUnknown = 'Manual';
  static const financeAccountType = 'Tipo';
  static const financeAccount = 'Conta';
  static const financeAccountRequired = 'Selecione uma conta';
  static const financeDescription = 'Descrição';
  static const financeDescriptionRequired = 'Informe a descrição';
  static const financeAmount = 'Valor';
  static const financeAmountInvalid = 'Informe um valor válido';
  static const financeDirectionInflow = 'Entrada';
  static const financeDirectionOutflow = 'Saída';
  static const financeCategory = 'Categoria';
  static const financeCategoryNone = 'Sem categoria';
  static const financeEditTransaction = 'Editar transação';
  static const financeDeleteTransaction = 'Excluir transação';
  static const financeDeleteTransactionConfirm =
      'Esta transação será removida permanentemente. Continuar?';

  static String financeCategoryLabel(TransactionCategory category) =>
      switch (category) {
        TransactionCategory.food => 'Alimentação',
        TransactionCategory.transport => 'Transporte',
        TransactionCategory.housing => 'Moradia',
        TransactionCategory.health => 'Saúde',
        TransactionCategory.entertainment => 'Lazer',
        TransactionCategory.shopping => 'Compras',
        TransactionCategory.utilities => 'Contas e serviços',
        TransactionCategory.education => 'Educação',
        TransactionCategory.income => 'Renda',
        TransactionCategory.other => 'Outros',
      };

  static String financeOccurredAt(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return 'Data: $day/$month/${local.year}';
  }

  static String financeTransactionSubtitle({
    required String accountName,
    required DateTime occurredAt,
    TransactionCategory? category,
  }) {
    final local = occurredAt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final datePart = '$accountName · $day/$month/${local.year}';
    if (category == null) return datePart;
    return '$datePart · ${financeCategoryLabel(category)}';
  }

  static String financeAccountTypeLabel(FinancialAccountType type) =>
      switch (type) {
        FinancialAccountType.checking => 'Corrente',
        FinancialAccountType.savings => 'Poupança',
        FinancialAccountType.cash => 'Dinheiro',
        FinancialAccountType.creditCard => 'Cartão de crédito',
        FinancialAccountType.investment => 'Investimento',
        FinancialAccountType.receivable => 'A receber',
        FinancialAccountType.payable => 'A pagar',
        FinancialAccountType.other => 'Outro',
      };

  static String financeEntityKindLabel(FinancialEntityKind kind) =>
      switch (kind) {
        FinancialEntityKind.personal => 'Pessoal',
        FinancialEntityKind.business => 'Negócio',
        FinancialEntityKind.project => 'Projeto',
        FinancialEntityKind.trip => 'Viagem',
        FinancialEntityKind.shared => 'Compartilhado',
      };

  static String restoreCountLabel(String key, int count) {
    final label = switch (key) {
      'tasks' => 'Tarefas',
      'events' => 'Eventos',
      'quests' => 'Missões',
      'projects' => 'Projetos',
      'decisions' => 'Decisões',
      'schedule_blocks' => 'Blocos de agenda',
      'bills' => 'Contas',
      'check_ins' => 'Check-ins',
      'need_definitions' => 'Necessidades',
      'daily_reviews' => 'Revisões diárias',
      'mood_factors' => 'Fatores de humor',
      'weekly_reviews' => 'Revisões semanais',
      'research_nodes' => 'Nós de pesquisa',
      'learning_sessions' => 'Sessões de aprendizado',
      'research_evidence' => 'Evidências de pesquisa',
      'financial_entities' => 'Entidades financeiras',
      'financial_accounts' => 'Contas financeiras',
      'transactions' => 'Transações',
      'health_conditions' => 'Condições de saúde',
      'symptom_entries' => 'Registros de sintomas',
      'inventory_items' => 'Itens de inventário',
      'people' => 'Pessoas',
      'knowledge_areas' => 'Áreas de conhecimento',
      'flashcard_decks' => 'Baralhos',
      'flashcards' => 'Flashcards',
      'flashcard_srs' => 'Estados SRS',
      'flashcard_review_logs' => 'Revisões de flashcards',
      'knowledge_area_placements' => 'Colocações de áreas',
      'research_knowledge_links' => 'Pontes pesquisa↔conhecimento',
      'google_timeline_import' => 'Timeline importada',
      'google_timeline_place_labels' => 'Rótulos de lugares',
      _ => key,
    };
    return '$label: $count';
  }
}
