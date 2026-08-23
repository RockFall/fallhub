import 'dart:convert';

import 'package:colony_domain/colony_domain.dart' as domain;
import 'package:drift/drift.dart';

import '../colony_database.dart';

abstract final class ActivationMappers {
  static DateTime utcMs(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  static DateTime? utcMsOrNull(int? ms) =>
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  static Map<String, Object?> decodeMap(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, Object?>) return decoded;
    if (decoded is Map) {
      return {
        for (final entry in decoded.entries) entry.key.toString(): entry.value,
      };
    }
    return const {};
  }

  static List<String> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return [for (final item in decoded) item.toString()];
    }
    return const [];
  }

  static domain.ActivationProtocol toProtocol(ActivationProtocolRow row) {
    return domain.ActivationProtocol(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      name: row.name,
      description: row.description,
      protocolType: domain.ActivationProtocolType.values.byName(row.protocolType),
      originState: domain.ActivationTransitionState.fromJson(
        decodeMap(row.originStateJson),
      ),
      targetState: domain.ActivationTransitionState.fromJson(
        decodeMap(row.targetStateJson),
      ),
      activeVersion: row.activeVersion,
      isEnabled: row.isEnabled,
      seedKey: row.seedKey,
      linkedTaskId:
          row.linkedTaskId == null ? null : domain.EntityId(row.linkedTaskId!),
      maturity: domain.ActivationRouteMaturity.values.byName(row.maturity),
      createdAt: utcMs(row.createdAt),
      updatedAt: utcMs(row.updatedAt),
    );
  }

  static ActivationProtocolsCompanion fromProtocol(
    domain.ActivationProtocol protocol,
  ) {
    return ActivationProtocolsCompanion.insert(
      id: protocol.id.value,
      profileId: protocol.profileId.value,
      name: protocol.name,
      description: Value(protocol.description),
      protocolType: protocol.protocolType.name,
      originStateJson: jsonEncode(protocol.originState.toJson()),
      targetStateJson: jsonEncode(protocol.targetState.toJson()),
      activeVersion: Value(protocol.activeVersion),
      isEnabled: Value(protocol.isEnabled),
      seedKey: Value(protocol.seedKey),
      linkedTaskId: Value(protocol.linkedTaskId?.value),
      maturity: Value(protocol.maturity.name),
      createdAt: protocol.createdAt.millisecondsSinceEpoch,
      updatedAt: protocol.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.ActivationProtocolVersion toVersion(
    ActivationProtocolVersionRow row,
  ) {
    return domain.ActivationProtocolVersion(
      protocolId: domain.EntityId(row.protocolId),
      version: row.version,
      triggerRules: domain.ActivationTriggerRules.fromJson(
        decodeMap(row.triggerRulesJson),
      ),
      releaseConditions: domain.ActivationReleaseConditions.fromJson(
        decodeMap(row.releaseConditionsJson),
      ),
      applicableContexts: decodeList(row.applicableContextsJson),
      shieldProfileId: row.shieldProfileId == null
          ? null
          : domain.EntityId(row.shieldProfileId!),
      temptationBundleId: row.temptationBundleId == null
          ? null
          : domain.EntityId(row.temptationBundleId!),
      sensorySceneId: row.sensorySceneId == null
          ? null
          : domain.EntityId(row.sensorySceneId!),
      fallbackProtocolId: row.fallbackProtocolId == null
          ? null
          : domain.EntityId(row.fallbackProtocolId!),
      createdAt: utcMs(row.createdAt),
    );
  }

  static ActivationProtocolVersionsCompanion fromVersion(
    domain.ActivationProtocolVersion version,
  ) {
    return ActivationProtocolVersionsCompanion.insert(
      protocolId: version.protocolId.value,
      version: version.version,
      triggerRulesJson: jsonEncode(version.triggerRules.toJson()),
      releaseConditionsJson: jsonEncode(version.releaseConditions.toJson()),
      applicableContextsJson: Value(jsonEncode(version.applicableContexts)),
      shieldProfileId: Value(version.shieldProfileId?.value),
      temptationBundleId: Value(version.temptationBundleId?.value),
      sensorySceneId: Value(version.sensorySceneId?.value),
      fallbackProtocolId: Value(version.fallbackProtocolId?.value),
      createdAt: version.createdAt.millisecondsSinceEpoch,
    );
  }

  static domain.ActivationCommandTemplate toCommand(
    ActivationCommandTemplateRow row,
  ) {
    return domain.ActivationCommandTemplate(
      id: domain.EntityId(row.id),
      protocolId: domain.EntityId(row.protocolId),
      protocolVersion: row.protocolVersion,
      sequenceKey: row.sequenceKey,
      instruction: row.instruction,
      actionVerb: row.actionVerb,
      objectRef: row.objectRef,
      destinationRef: row.destinationRef,
      preconditions: decodeList(row.preconditionsJson),
      proofPolicy: domain.ActivationProofPolicy.fromJson(
        decodeMap(row.proofPolicyJson),
      ),
      timeoutPolicy: domain.ActivationTimeoutPolicy.fromJson(
        decodeMap(row.timeoutPolicyJson),
      ),
      fallback: domain.ActivationFallbackPolicy.fromJson(
        decodeMap(row.fallbackJson),
      ),
      skippable: row.skippable,
      estimatedSeconds: row.estimatedSeconds,
      waypointId:
          row.waypointId == null ? null : domain.EntityId(row.waypointId!),
      opensTaskId:
          row.opensTaskId == null ? null : domain.EntityId(row.opensTaskId!),
      deepLink: row.deepLink,
      isFirstMeaningfulAction: row.isFirstMeaningfulAction,
      releasesOnConfirm: row.releasesOnConfirm,
    );
  }

  static ActivationCommandTemplatesCompanion fromCommand(
    domain.ActivationCommandTemplate command,
  ) {
    return ActivationCommandTemplatesCompanion.insert(
      id: command.id.value,
      protocolId: command.protocolId.value,
      protocolVersion: command.protocolVersion,
      sequenceKey: command.sequenceKey,
      instruction: command.instruction,
      actionVerb: command.actionVerb,
      objectRef: Value(command.objectRef),
      destinationRef: Value(command.destinationRef),
      preconditionsJson: Value(jsonEncode(command.preconditions)),
      proofPolicyJson: jsonEncode(command.proofPolicy.toJson()),
      timeoutPolicyJson: jsonEncode(command.timeoutPolicy.toJson()),
      fallbackJson: jsonEncode(command.fallback.toJson()),
      skippable: Value(command.skippable),
      estimatedSeconds: Value(command.estimatedSeconds),
      waypointId: Value(command.waypointId?.value),
      opensTaskId: Value(command.opensTaskId?.value),
      deepLink: Value(command.deepLink),
      isFirstMeaningfulAction: Value(command.isFirstMeaningfulAction),
      releasesOnConfirm: Value(command.releasesOnConfirm),
    );
  }

  static domain.ActivationEpisode toEpisode(ActivationEpisodeRow row) {
    return domain.ActivationEpisode(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      protocolId:
          row.protocolId == null ? null : domain.EntityId(row.protocolId!),
      protocolVersion: row.protocolVersion,
      triggerType: domain.ActivationTriggerType.values.byName(row.triggerType),
      hypothesisType: row.hypothesisType == null
          ? null
          : domain.InertiaHypothesisType.values.byName(row.hypothesisType!),
      hypothesisConfidence: row.hypothesisConfidence,
      capacityMode: domain.ActivationCapacityMode.values.byName(row.capacityMode),
      initialState: domain.ActivationTransitionState.fromJson(
        decodeMap(row.initialStateJson),
      ),
      targetState: domain.ActivationTransitionState.fromJson(
        decodeMap(row.targetStateJson),
      ),
      status: domain.ActivationEpisodeStatus.values.byName(row.status),
      startedAt: utcMs(row.startedAt),
      firstMotionAt: utcMsOrNull(row.firstMotionAt),
      releasedAt: utcMsOrNull(row.releasedAt),
      endedAt: utcMsOrNull(row.endedAt),
      interventionLevelMax: row.interventionLevelMax,
      shieldUsed: row.shieldUsed,
      bundleUsed: row.bundleUsed,
      escapeUsed: row.escapeUsed,
      userCorrection: row.userCorrection,
      linkedTaskId:
          row.linkedTaskId == null ? null : domain.EntityId(row.linkedTaskId!),
      experimentAssignmentId: row.experimentAssignmentId == null
          ? null
          : domain.EntityId(row.experimentAssignmentId!),
      provenance: domain.ActivationProvenance.fromJson(
        decodeMap(row.provenanceJson),
      ),
    );
  }

  static ActivationEpisodesCompanion fromEpisode(
    domain.ActivationEpisode episode,
  ) {
    return ActivationEpisodesCompanion.insert(
      id: episode.id.value,
      profileId: episode.profileId.value,
      protocolId: Value(episode.protocolId?.value),
      protocolVersion: Value(episode.protocolVersion),
      triggerType: episode.triggerType.name,
      hypothesisType: Value(episode.hypothesisType?.name),
      hypothesisConfidence: Value(episode.hypothesisConfidence),
      capacityMode: episode.capacityMode.name,
      initialStateJson: jsonEncode(episode.initialState.toJson()),
      targetStateJson: jsonEncode(episode.targetState.toJson()),
      status: episode.status.name,
      startedAt: episode.startedAt.millisecondsSinceEpoch,
      firstMotionAt: Value(episode.firstMotionAt?.millisecondsSinceEpoch),
      releasedAt: Value(episode.releasedAt?.millisecondsSinceEpoch),
      endedAt: Value(episode.endedAt?.millisecondsSinceEpoch),
      interventionLevelMax: Value(episode.interventionLevelMax),
      shieldUsed: Value(episode.shieldUsed),
      bundleUsed: Value(episode.bundleUsed),
      escapeUsed: Value(episode.escapeUsed),
      userCorrection: Value(episode.userCorrection),
      linkedTaskId: Value(episode.linkedTaskId?.value),
      experimentAssignmentId: Value(episode.experimentAssignmentId?.value),
      provenanceJson: jsonEncode(episode.provenance.toJson()),
    );
  }

  static domain.ActivationCommandRun toRun(ActivationCommandRunRow row) {
    return domain.ActivationCommandRun(
      id: domain.EntityId(row.id),
      episodeId: domain.EntityId(row.episodeId),
      templateId:
          row.templateId == null ? null : domain.EntityId(row.templateId!),
      sequenceIndex: row.sequenceIndex,
      instructionRendered: row.instructionRendered,
      status: domain.ActivationCommandRunStatus.values.byName(row.status),
      presentedAt: utcMs(row.presentedAt),
      firstSignalAt: utcMsOrNull(row.firstSignalAt),
      confirmedAt: utcMsOrNull(row.confirmedAt),
      skippedAt: utcMsOrNull(row.skippedAt),
      adaptedAt: utcMsOrNull(row.adaptedAt),
      confirmationMode: row.confirmationMode == null
          ? null
          : domain.ActivationConfirmationMode.values.byName(
              row.confirmationMode!,
            ),
      proofConfidence: row.proofConfidence,
      adaptationReason: row.adaptationReason,
      isFirstMeaningfulAction: row.isFirstMeaningfulAction,
      deepLink: row.deepLink,
      opensTaskId:
          row.opensTaskId == null ? null : domain.EntityId(row.opensTaskId!),
    );
  }

  static ActivationCommandRunsCompanion fromRun(
    domain.ActivationCommandRun run,
  ) {
    return ActivationCommandRunsCompanion.insert(
      id: run.id.value,
      episodeId: run.episodeId.value,
      templateId: Value(run.templateId?.value),
      sequenceIndex: run.sequenceIndex,
      instructionRendered: run.instructionRendered,
      status: run.status.name,
      presentedAt: run.presentedAt.millisecondsSinceEpoch,
      firstSignalAt: Value(run.firstSignalAt?.millisecondsSinceEpoch),
      confirmedAt: Value(run.confirmedAt?.millisecondsSinceEpoch),
      skippedAt: Value(run.skippedAt?.millisecondsSinceEpoch),
      adaptedAt: Value(run.adaptedAt?.millisecondsSinceEpoch),
      confirmationMode: Value(run.confirmationMode?.name),
      proofConfidence: Value(run.proofConfidence),
      adaptationReason: Value(run.adaptationReason),
      isFirstMeaningfulAction: Value(run.isFirstMeaningfulAction),
      deepLink: Value(run.deepLink),
      opensTaskId: Value(run.opensTaskId?.value),
    );
  }

  static domain.ActivationProof toProof(ActivationProofRow row) {
    return domain.ActivationProof(
      id: domain.EntityId(row.id),
      episodeId: domain.EntityId(row.episodeId),
      commandRunId:
          row.commandRunId == null ? null : domain.EntityId(row.commandRunId!),
      proofType: domain.ActivationProofType.values.byName(row.proofType),
      observedAt: utcMs(row.observedAt),
      source: row.source,
      confidence: row.confidence,
      privacyClass: domain.PrivacyClass.values.byName(row.privacyClass),
      interpretation: decodeMap(row.interpretationJson),
      rawReference: row.rawReference,
      userConfirmed: row.userConfirmed,
    );
  }

  static ActivationProofsCompanion fromProof(domain.ActivationProof proof) {
    return ActivationProofsCompanion.insert(
      id: proof.id.value,
      episodeId: proof.episodeId.value,
      commandRunId: Value(proof.commandRunId?.value),
      proofType: proof.proofType.name,
      observedAt: proof.observedAt.millisecondsSinceEpoch,
      source: proof.source,
      confidence: proof.confidence,
      privacyClass: proof.privacyClass.name,
      interpretationJson: Value(jsonEncode(proof.interpretation)),
      rawReference: Value(proof.rawReference),
      userConfirmed: Value(proof.userConfirmed),
    );
  }

  static domain.ActivationWaypoint toWaypoint(ActivationWaypointRow row) {
    return domain.ActivationWaypoint(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      name: row.name,
      waypointType: domain.ActivationWaypointType.values.byName(
        row.waypointType,
      ),
      zoneId: row.zoneId == null ? null : domain.EntityId(row.zoneId!),
      equipmentId:
          row.equipmentId == null ? null : domain.EntityId(row.equipmentId!),
      token: row.token,
      settings: decodeMap(row.settingsJson),
      reliabilityScore: row.reliabilityScore,
      privacyClass: domain.PrivacyClass.values.byName(row.privacyClass),
      isEnabled: row.isEnabled,
      createdAt: utcMs(row.createdAt),
      updatedAt: utcMs(row.updatedAt),
    );
  }

  static ActivationWaypointsCompanion fromWaypoint(
    domain.ActivationWaypoint waypoint,
  ) {
    return ActivationWaypointsCompanion.insert(
      id: waypoint.id.value,
      profileId: waypoint.profileId.value,
      name: waypoint.name,
      waypointType: waypoint.waypointType.name,
      zoneId: Value(waypoint.zoneId?.value),
      equipmentId: Value(waypoint.equipmentId?.value),
      token: Value(waypoint.token),
      settingsJson: Value(jsonEncode(waypoint.settings)),
      reliabilityScore: Value(waypoint.reliabilityScore),
      privacyClass: waypoint.privacyClass.name,
      isEnabled: Value(waypoint.isEnabled),
      createdAt: waypoint.createdAt.millisecondsSinceEpoch,
      updatedAt: waypoint.updatedAt.millisecondsSinceEpoch,
    );
  }

  static domain.WaypointObservation toObservation(WaypointObservationRow row) {
    return domain.WaypointObservation(
      id: domain.EntityId(row.id),
      waypointId: domain.EntityId(row.waypointId),
      episodeId:
          row.episodeId == null ? null : domain.EntityId(row.episodeId!),
      observedAt: utcMs(row.observedAt),
      state: domain.ActivationWaypointListenState.values.byName(row.state),
      latencyMs: row.latencyMs,
      source: row.source,
    );
  }

  static WaypointObservationsCompanion fromObservation(
    domain.WaypointObservation observation,
  ) {
    return WaypointObservationsCompanion.insert(
      id: observation.id.value,
      waypointId: observation.waypointId.value,
      episodeId: Value(observation.episodeId?.value),
      observedAt: observation.observedAt.millisecondsSinceEpoch,
      state: observation.state.name,
      latencyMs: observation.latencyMs,
      source: Value(observation.source),
    );
  }

  static domain.InertiaSignal toSignal(InertiaSignalRow row) {
    return domain.InertiaSignal(
      id: domain.EntityId(row.id),
      episodeId:
          row.episodeId == null ? null : domain.EntityId(row.episodeId!),
      signalType: domain.InertiaSignalType.values.byName(row.signalType),
      observedAt: utcMs(row.observedAt),
      value: decodeMap(row.valueJson),
      source: row.source,
      confidence: row.confidence,
      expiresAt: utcMsOrNull(row.expiresAt),
      privacyClass: domain.PrivacyClass.values.byName(row.privacyClass),
    );
  }

  static InertiaSignalsCompanion fromSignal(domain.InertiaSignal signal) {
    return InertiaSignalsCompanion.insert(
      id: signal.id.value,
      episodeId: Value(signal.episodeId?.value),
      signalType: signal.signalType.name,
      observedAt: signal.observedAt.millisecondsSinceEpoch,
      valueJson: Value(jsonEncode(signal.value)),
      source: signal.source,
      confidence: signal.confidence,
      expiresAt: Value(signal.expiresAt?.millisecondsSinceEpoch),
      privacyClass: signal.privacyClass.name,
    );
  }

  static domain.FrictionShieldProfile toShieldProfile(
    FrictionShieldProfileRow row,
  ) {
    return domain.FrictionShieldProfile(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      name: row.name,
      platformMode: domain.FrictionShieldPlatformMode.values.byName(
        row.platformMode,
      ),
      protectedCategories: decodeList(row.protectedCategoriesJson),
      allowlistCategories: decodeList(row.allowlistCategoriesJson),
      escapePolicy: domain.ActivationEscapePolicy.fromJson(
        decodeMap(row.escapePolicyJson),
      ),
      isEnabled: row.isEnabled,
    );
  }

  static FrictionShieldProfilesCompanion fromShieldProfile(
    domain.FrictionShieldProfile profile,
  ) {
    return FrictionShieldProfilesCompanion.insert(
      id: profile.id.value,
      profileId: profile.profileId.value,
      name: profile.name,
      platformMode: profile.platformMode.name,
      protectedCategoriesJson: Value(jsonEncode(profile.protectedCategories)),
      allowlistCategoriesJson: Value(jsonEncode(profile.allowlistCategories)),
      escapePolicyJson: jsonEncode(profile.escapePolicy.toJson()),
      isEnabled: Value(profile.isEnabled),
    );
  }

  static domain.FrictionShieldSession toShieldSession(
    FrictionShieldSessionRow row,
  ) {
    return domain.FrictionShieldSession(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      shieldProfileId: domain.EntityId(row.shieldProfileId),
      episodeId:
          row.episodeId == null ? null : domain.EntityId(row.episodeId!),
      state: domain.FrictionShieldState.values.byName(row.state),
      startedAt: utcMs(row.startedAt),
      endedAt: utcMsOrNull(row.endedAt),
      escapeCount: row.escapeCount,
    );
  }

  static FrictionShieldSessionsCompanion fromShieldSession(
    domain.FrictionShieldSession session,
  ) {
    return FrictionShieldSessionsCompanion.insert(
      id: session.id.value,
      profileId: session.profileId.value,
      shieldProfileId: session.shieldProfileId.value,
      episodeId: Value(session.episodeId?.value),
      state: session.state.name,
      startedAt: session.startedAt.millisecondsSinceEpoch,
      endedAt: Value(session.endedAt?.millisecondsSinceEpoch),
      escapeCount: Value(session.escapeCount),
    );
  }

  static domain.TemptationBundle toBundle(TemptationBundleRow row) {
    return domain.TemptationBundle(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      name: row.name,
      pleasureLabel: row.pleasureLabel,
      requiredTransition: row.requiredTransition,
      audioHint: row.audioHint,
      isEnabled: row.isEnabled,
    );
  }

  static TemptationBundlesCompanion fromBundle(domain.TemptationBundle bundle) {
    return TemptationBundlesCompanion.insert(
      id: bundle.id.value,
      profileId: bundle.profileId.value,
      name: bundle.name,
      pleasureLabel: bundle.pleasureLabel,
      requiredTransition: bundle.requiredTransition,
      audioHint: Value(bundle.audioHint),
      isEnabled: Value(bundle.isEnabled),
    );
  }

  static domain.ActivationScene toScene(ActivationSceneRow row) {
    return domain.ActivationScene(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      name: row.name,
      kind: domain.ActivationSceneKind.values.byName(row.kind),
      payload: decodeMap(row.payloadJson),
      isEnabled: row.isEnabled,
    );
  }

  static ActivationScenesCompanion fromScene(domain.ActivationScene scene) {
    return ActivationScenesCompanion.insert(
      id: scene.id.value,
      profileId: scene.profileId.value,
      name: scene.name,
      kind: scene.kind.name,
      payloadJson: Value(jsonEncode(scene.payload)),
      isEnabled: Value(scene.isEnabled),
    );
  }

  static domain.RescueContract toRescue(RescueContractRow row) {
    return domain.RescueContract(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      contactLabel: row.contactLabel,
      messageTemplate: row.messageTemplate,
      status: domain.RescueContractStatus.values.byName(row.status),
      personId: row.personId == null ? null : domain.EntityId(row.personId!),
      requiresConfirmation: row.requiresConfirmation,
      lastConfirmedAt: utcMsOrNull(row.lastConfirmedAt),
    );
  }

  static RescueContractsCompanion fromRescue(domain.RescueContract contract) {
    return RescueContractsCompanion.insert(
      id: contract.id.value,
      profileId: contract.profileId.value,
      contactLabel: contract.contactLabel,
      messageTemplate: contract.messageTemplate,
      status: contract.status.name,
      personId: Value(contract.personId?.value),
      requiresConfirmation: Value(contract.requiresConfirmation),
      lastConfirmedAt: Value(contract.lastConfirmedAt?.millisecondsSinceEpoch),
    );
  }

  static domain.ActivationExperiment toExperiment(ActivationExperimentRow row) {
    return domain.ActivationExperiment(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      name: row.name,
      hypothesis: row.hypothesis,
      variableKey: row.variableKey,
      variants: decodeList(row.variantsJson),
      contextFilter: decodeMap(row.contextFilterJson),
      minimumSamples: row.minimumSamples,
      status: domain.ActivationExperimentStatus.values.byName(row.status),
      startedAt: utcMsOrNull(row.startedAt),
      endedAt: utcMsOrNull(row.endedAt),
      result: row.resultJson == null ? null : decodeMap(row.resultJson!),
    );
  }

  static ActivationExperimentsCompanion fromExperiment(
    domain.ActivationExperiment experiment,
  ) {
    return ActivationExperimentsCompanion.insert(
      id: experiment.id.value,
      profileId: experiment.profileId.value,
      name: experiment.name,
      hypothesis: experiment.hypothesis,
      variableKey: experiment.variableKey,
      variantsJson: jsonEncode(experiment.variants),
      contextFilterJson: Value(jsonEncode(experiment.contextFilter)),
      minimumSamples: Value(experiment.minimumSamples),
      status: experiment.status.name,
      startedAt: Value(experiment.startedAt?.millisecondsSinceEpoch),
      endedAt: Value(experiment.endedAt?.millisecondsSinceEpoch),
      resultJson: Value(
        experiment.result == null ? null : jsonEncode(experiment.result),
      ),
    );
  }

  static domain.ActivationExperimentAssignment toAssignment(
    ActivationExperimentAssignmentRow row,
  ) {
    return domain.ActivationExperimentAssignment(
      id: domain.EntityId(row.id),
      experimentId: domain.EntityId(row.experimentId),
      episodeId: domain.EntityId(row.episodeId),
      variant: row.variant,
      assignedAt: utcMs(row.assignedAt),
    );
  }

  static ActivationExperimentAssignmentsCompanion fromAssignment(
    domain.ActivationExperimentAssignment assignment,
  ) {
    return ActivationExperimentAssignmentsCompanion.insert(
      id: assignment.id.value,
      experimentId: assignment.experimentId.value,
      episodeId: assignment.episodeId.value,
      variant: assignment.variant,
      assignedAt: assignment.assignedAt.millisecondsSinceEpoch,
    );
  }

  static domain.ActivationInsight toInsight(ActivationInsightRow row) {
    return domain.ActivationInsight(
      id: domain.EntityId(row.id),
      profileId: domain.EntityId(row.profileId),
      title: row.title,
      body: row.body,
      createdAt: utcMs(row.createdAt),
      sampleSize: row.sampleSize,
      confidence: domain.ConfidenceLevel.values.byName(row.confidence),
      associativeOnly: row.associativeOnly,
    );
  }

  static ActivationInsightsCompanion fromInsight(
    domain.ActivationInsight insight,
  ) {
    return ActivationInsightsCompanion.insert(
      id: insight.id.value,
      profileId: insight.profileId.value,
      title: insight.title,
      body: insight.body,
      createdAt: insight.createdAt.millisecondsSinceEpoch,
      sampleSize: Value(insight.sampleSize),
      confidence: Value(insight.confidence.name),
      associativeOnly: Value(insight.associativeOnly),
    );
  }
}
