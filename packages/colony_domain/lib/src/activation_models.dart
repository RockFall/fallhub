import 'package:equatable/equatable.dart';

import 'activation_enums.dart';
import 'enums.dart';
import 'id_generator.dart';

/// Estado inicial ou operacional descrito em texto + chaves estáveis.
class ActivationTransitionState extends Equatable {
  const ActivationTransitionState({
    required this.label,
    this.keys = const [],
  });

  final String label;
  final List<String> keys;

  Map<String, Object?> toJson() => {
        'label': label,
        'keys': keys,
      };

  factory ActivationTransitionState.fromJson(Map<String, Object?> json) {
    final keysRaw = json['keys'];
    return ActivationTransitionState(
      label: (json['label'] as String?) ?? '',
      keys: keysRaw is List
          ? [for (final item in keysRaw) item.toString()]
          : const [],
    );
  }

  @override
  List<Object?> get props => [label, keys];
}

class ActivationProofPolicy extends Equatable {
  const ActivationProofPolicy({
    this.preferred = ActivationProofType.manualTap,
    this.fallback = ActivationProofType.manualTap,
    this.minimumConfidence = 0.5,
    this.allowSkip = true,
  });

  final ActivationProofType preferred;
  final ActivationProofType fallback;
  final double minimumConfidence;
  final bool allowSkip;

  Map<String, Object?> toJson() => {
        'preferred': preferred.name,
        'fallback': fallback.name,
        'minimum_confidence': minimumConfidence,
        'allow_skip': allowSkip,
      };

  factory ActivationProofPolicy.fromJson(Map<String, Object?> json) {
    return ActivationProofPolicy(
      preferred: _enumOr(
        ActivationProofType.values,
        json['preferred'] as String?,
        ActivationProofType.manualTap,
      ),
      fallback: _enumOr(
        ActivationProofType.values,
        json['fallback'] as String?,
        ActivationProofType.manualTap,
      ),
      minimumConfidence: (json['minimum_confidence'] as num?)?.toDouble() ?? 0.5,
      allowSkip: json['allow_skip'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props =>
      [preferred, fallback, minimumConfidence, allowSkip];
}

class ActivationTimeoutPolicy extends Equatable {
  const ActivationTimeoutPolicy({
    this.seconds = 120,
    this.onTimeout = const ['simplify_instruction', 'offer_adapt'],
  });

  final int seconds;
  final List<String> onTimeout;

  Map<String, Object?> toJson() => {
        'seconds': seconds,
        'on_timeout': onTimeout,
      };

  factory ActivationTimeoutPolicy.fromJson(Map<String, Object?> json) {
    final raw = json['on_timeout'];
    return ActivationTimeoutPolicy(
      seconds: (json['seconds'] as num?)?.toInt() ?? 120,
      onTimeout: raw is List
          ? [for (final item in raw) item.toString()]
          : const ['simplify_instruction', 'offer_adapt'],
    );
  }

  @override
  List<Object?> get props => [seconds, onTimeout];
}

class ActivationFallbackPolicy extends Equatable {
  const ActivationFallbackPolicy({
    this.splitInstructions = const [],
    this.mergeWithNext = false,
    this.convertToRecovery = false,
  });

  final List<String> splitInstructions;
  final bool mergeWithNext;
  final bool convertToRecovery;

  Map<String, Object?> toJson() => {
        'split_instructions': splitInstructions,
        'merge_with_next': mergeWithNext,
        'convert_to_recovery': convertToRecovery,
      };

  factory ActivationFallbackPolicy.fromJson(Map<String, Object?> json) {
    final raw = json['split_instructions'];
    return ActivationFallbackPolicy(
      splitInstructions: raw is List
          ? [for (final item in raw) item.toString()]
          : const [],
      mergeWithNext: json['merge_with_next'] as bool? ?? false,
      convertToRecovery: json['convert_to_recovery'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [splitInstructions, mergeWithNext, convertToRecovery];
}

class ActivationTriggerRules extends Equatable {
  const ActivationTriggerRules({
    this.allowManual = true,
    this.scheduleWindows = const [],
    this.requireExplicitStart = true,
    this.blockWhenPlannedRest = true,
  });

  final bool allowManual;
  final List<String> scheduleWindows;
  final bool requireExplicitStart;
  final bool blockWhenPlannedRest;

  Map<String, Object?> toJson() => {
        'allow_manual': allowManual,
        'schedule_windows': scheduleWindows,
        'require_explicit_start': requireExplicitStart,
        'block_when_planned_rest': blockWhenPlannedRest,
      };

  factory ActivationTriggerRules.fromJson(Map<String, Object?> json) {
    final raw = json['schedule_windows'];
    return ActivationTriggerRules(
      allowManual: json['allow_manual'] as bool? ?? true,
      scheduleWindows: raw is List
          ? [for (final item in raw) item.toString()]
          : const [],
      requireExplicitStart: json['require_explicit_start'] as bool? ?? true,
      blockWhenPlannedRest: json['block_when_planned_rest'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        allowManual,
        scheduleWindows,
        requireExplicitStart,
        blockWhenPlannedRest,
      ];
}

class ActivationReleaseConditions extends Equatable {
  const ActivationReleaseConditions({
    this.requireFirstMeaningfulAction = true,
    this.minimumMeaningfulSeconds = 180,
    this.allowExplicitRelease = true,
    this.allowRecoveryRelease = true,
    this.targetStateKeys = const [],
  });

  final bool requireFirstMeaningfulAction;
  final int minimumMeaningfulSeconds;
  final bool allowExplicitRelease;
  final bool allowRecoveryRelease;
  final List<String> targetStateKeys;

  Map<String, Object?> toJson() => {
        'require_first_meaningful_action': requireFirstMeaningfulAction,
        'minimum_meaningful_seconds': minimumMeaningfulSeconds,
        'allow_explicit_release': allowExplicitRelease,
        'allow_recovery_release': allowRecoveryRelease,
        'target_state_keys': targetStateKeys,
      };

  factory ActivationReleaseConditions.fromJson(Map<String, Object?> json) {
    final raw = json['target_state_keys'];
    return ActivationReleaseConditions(
      requireFirstMeaningfulAction:
          json['require_first_meaningful_action'] as bool? ?? true,
      minimumMeaningfulSeconds:
          (json['minimum_meaningful_seconds'] as num?)?.toInt() ?? 180,
      allowExplicitRelease: json['allow_explicit_release'] as bool? ?? true,
      allowRecoveryRelease: json['allow_recovery_release'] as bool? ?? true,
      targetStateKeys: raw is List
          ? [for (final item in raw) item.toString()]
          : const [],
    );
  }

  @override
  List<Object?> get props => [
        requireFirstMeaningfulAction,
        minimumMeaningfulSeconds,
        allowExplicitRelease,
        allowRecoveryRelease,
        targetStateKeys,
      ];
}

class ActivationEscapePolicy extends Equatable {
  const ActivationEscapePolicy({
    this.alwaysAvailable = true,
    this.requiresJustification = false,
    this.temporaryReleaseSeconds = 120,
    this.keepEmergencyAllowlist = true,
  });

  final bool alwaysAvailable;
  final bool requiresJustification;
  final int temporaryReleaseSeconds;
  final bool keepEmergencyAllowlist;

  Map<String, Object?> toJson() => {
        'always_available': alwaysAvailable,
        'requires_justification': requiresJustification,
        'temporary_release_seconds': temporaryReleaseSeconds,
        'keep_emergency_allowlist': keepEmergencyAllowlist,
      };

  factory ActivationEscapePolicy.fromJson(Map<String, Object?> json) {
    return ActivationEscapePolicy(
      alwaysAvailable: json['always_available'] as bool? ?? true,
      requiresJustification: json['requires_justification'] as bool? ?? false,
      temporaryReleaseSeconds:
          (json['temporary_release_seconds'] as num?)?.toInt() ?? 120,
      keepEmergencyAllowlist:
          json['keep_emergency_allowlist'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        alwaysAvailable,
        requiresJustification,
        temporaryReleaseSeconds,
        keepEmergencyAllowlist,
      ];
}

class ActivationProvenance extends Equatable {
  const ActivationProvenance({
    this.kind = ProvenanceKind.manual,
    this.source = 'user',
    this.confidence = ConfidenceLevel.high,
    this.notes = const [],
  });

  final ProvenanceKind kind;
  final String source;
  final ConfidenceLevel confidence;
  final List<String> notes;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'source': source,
        'confidence': confidence.name,
        'notes': notes,
      };

  factory ActivationProvenance.fromJson(Map<String, Object?> json) {
    final raw = json['notes'];
    return ActivationProvenance(
      kind: _enumOr(
        ProvenanceKind.values,
        json['kind'] as String?,
        ProvenanceKind.manual,
      ),
      source: (json['source'] as String?) ?? 'user',
      confidence: _enumOr(
        ConfidenceLevel.values,
        json['confidence'] as String?,
        ConfidenceLevel.high,
      ),
      notes: raw is List ? [for (final item in raw) item.toString()] : const [],
    );
  }

  @override
  List<Object?> get props => [kind, source, confidence, notes];
}

class ActivationCommandTemplate extends Equatable {
  const ActivationCommandTemplate({
    required this.id,
    required this.protocolId,
    required this.protocolVersion,
    required this.sequenceKey,
    required this.instruction,
    required this.actionVerb,
    this.objectRef,
    this.destinationRef,
    this.preconditions = const [],
    this.proofPolicy = const ActivationProofPolicy(),
    this.timeoutPolicy = const ActivationTimeoutPolicy(),
    this.fallback = const ActivationFallbackPolicy(),
    this.skippable = true,
    this.estimatedSeconds,
    this.waypointId,
    this.opensTaskId,
    this.deepLink,
    this.isFirstMeaningfulAction = false,
    this.releasesOnConfirm = false,
  });

  final EntityId id;
  final EntityId protocolId;
  final int protocolVersion;
  final String sequenceKey;
  final String instruction;
  final String actionVerb;
  final String? objectRef;
  final String? destinationRef;
  final List<String> preconditions;
  final ActivationProofPolicy proofPolicy;
  final ActivationTimeoutPolicy timeoutPolicy;
  final ActivationFallbackPolicy fallback;
  final bool skippable;
  final int? estimatedSeconds;
  final EntityId? waypointId;
  final EntityId? opensTaskId;
  final String? deepLink;
  final bool isFirstMeaningfulAction;
  final bool releasesOnConfirm;

  Map<String, Object?> toJson() => {
        'id': id.value,
        'protocol_id': protocolId.value,
        'protocol_version': protocolVersion,
        'sequence_key': sequenceKey,
        'instruction': instruction,
        'action_verb': actionVerb,
        'object_ref': objectRef,
        'destination_ref': destinationRef,
        'preconditions': preconditions,
        'proof_policy': proofPolicy.toJson(),
        'timeout_policy': timeoutPolicy.toJson(),
        'fallback': fallback.toJson(),
        'skippable': skippable,
        'estimated_seconds': estimatedSeconds,
        'waypoint_id': waypointId?.value,
        'opens_task_id': opensTaskId?.value,
        'deep_link': deepLink,
        'is_first_meaningful_action': isFirstMeaningfulAction,
        'releases_on_confirm': releasesOnConfirm,
      };

  factory ActivationCommandTemplate.fromJson(Map<String, Object?> json) {
    final pre = json['preconditions'];
    return ActivationCommandTemplate(
      id: EntityId(json['id'] as String),
      protocolId: EntityId(json['protocol_id'] as String),
      protocolVersion: (json['protocol_version'] as num).toInt(),
      sequenceKey: json['sequence_key'] as String,
      instruction: json['instruction'] as String,
      actionVerb: json['action_verb'] as String,
      objectRef: json['object_ref'] as String?,
      destinationRef: json['destination_ref'] as String?,
      preconditions:
          pre is List ? [for (final item in pre) item.toString()] : const [],
      proofPolicy: ActivationProofPolicy.fromJson(
        _asMap(json['proof_policy']),
      ),
      timeoutPolicy: ActivationTimeoutPolicy.fromJson(
        _asMap(json['timeout_policy']),
      ),
      fallback: ActivationFallbackPolicy.fromJson(_asMap(json['fallback'])),
      skippable: json['skippable'] as bool? ?? true,
      estimatedSeconds: (json['estimated_seconds'] as num?)?.toInt(),
      waypointId: json['waypoint_id'] == null
          ? null
          : EntityId(json['waypoint_id'] as String),
      opensTaskId: json['opens_task_id'] == null
          ? null
          : EntityId(json['opens_task_id'] as String),
      deepLink: json['deep_link'] as String?,
      isFirstMeaningfulAction:
          json['is_first_meaningful_action'] as bool? ?? false,
      releasesOnConfirm: json['releases_on_confirm'] as bool? ?? false,
    );
  }

  ActivationCommandTemplate copyWith({
    EntityId? id,
    int? protocolVersion,
    String? sequenceKey,
    String? instruction,
    String? actionVerb,
    String? objectRef,
    String? destinationRef,
    ActivationFallbackPolicy? fallback,
    bool? skippable,
    int? estimatedSeconds,
    EntityId? opensTaskId,
    String? deepLink,
    bool? isFirstMeaningfulAction,
    bool? releasesOnConfirm,
  }) {
    return ActivationCommandTemplate(
      id: id ?? this.id,
      protocolId: protocolId,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      sequenceKey: sequenceKey ?? this.sequenceKey,
      instruction: instruction ?? this.instruction,
      actionVerb: actionVerb ?? this.actionVerb,
      objectRef: objectRef ?? this.objectRef,
      destinationRef: destinationRef ?? this.destinationRef,
      preconditions: preconditions,
      proofPolicy: proofPolicy,
      timeoutPolicy: timeoutPolicy,
      fallback: fallback ?? this.fallback,
      skippable: skippable ?? this.skippable,
      estimatedSeconds: estimatedSeconds ?? this.estimatedSeconds,
      waypointId: waypointId,
      opensTaskId: opensTaskId ?? this.opensTaskId,
      deepLink: deepLink ?? this.deepLink,
      isFirstMeaningfulAction:
          isFirstMeaningfulAction ?? this.isFirstMeaningfulAction,
      releasesOnConfirm: releasesOnConfirm ?? this.releasesOnConfirm,
    );
  }

  @override
  List<Object?> get props => [
        id,
        protocolId,
        protocolVersion,
        sequenceKey,
        instruction,
        actionVerb,
        objectRef,
        destinationRef,
        preconditions,
        proofPolicy,
        timeoutPolicy,
        fallback,
        skippable,
        estimatedSeconds,
        waypointId,
        opensTaskId,
        deepLink,
        isFirstMeaningfulAction,
        releasesOnConfirm,
      ];
}

class ActivationProtocolVersion extends Equatable {
  const ActivationProtocolVersion({
    required this.protocolId,
    required this.version,
    required this.triggerRules,
    required this.releaseConditions,
    this.applicableContexts = const [],
    this.shieldProfileId,
    this.temptationBundleId,
    this.sensorySceneId,
    this.fallbackProtocolId,
    required this.createdAt,
  });

  final EntityId protocolId;
  final int version;
  final ActivationTriggerRules triggerRules;
  final ActivationReleaseConditions releaseConditions;
  final List<String> applicableContexts;
  final EntityId? shieldProfileId;
  final EntityId? temptationBundleId;
  final EntityId? sensorySceneId;
  final EntityId? fallbackProtocolId;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'protocol_id': protocolId.value,
        'version': version,
        'trigger_rules': triggerRules.toJson(),
        'release_conditions': releaseConditions.toJson(),
        'applicable_contexts': applicableContexts,
        'shield_profile_id': shieldProfileId?.value,
        'temptation_bundle_id': temptationBundleId?.value,
        'sensory_scene_id': sensorySceneId?.value,
        'fallback_protocol_id': fallbackProtocolId?.value,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory ActivationProtocolVersion.fromJson(Map<String, Object?> json) {
    final contexts = json['applicable_contexts'];
    return ActivationProtocolVersion(
      protocolId: EntityId(json['protocol_id'] as String),
      version: (json['version'] as num).toInt(),
      triggerRules: ActivationTriggerRules.fromJson(
        _asMap(json['trigger_rules']),
      ),
      releaseConditions: ActivationReleaseConditions.fromJson(
        _asMap(json['release_conditions']),
      ),
      applicableContexts: contexts is List
          ? [for (final item in contexts) item.toString()]
          : const [],
      shieldProfileId: json['shield_profile_id'] == null
          ? null
          : EntityId(json['shield_profile_id'] as String),
      temptationBundleId: json['temptation_bundle_id'] == null
          ? null
          : EntityId(json['temptation_bundle_id'] as String),
      sensorySceneId: json['sensory_scene_id'] == null
          ? null
          : EntityId(json['sensory_scene_id'] as String),
      fallbackProtocolId: json['fallback_protocol_id'] == null
          ? null
          : EntityId(json['fallback_protocol_id'] as String),
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    );
  }

  ActivationProtocolVersion copyWith({
    int? version,
    DateTime? createdAt,
  }) {
    return ActivationProtocolVersion(
      protocolId: protocolId,
      version: version ?? this.version,
      triggerRules: triggerRules,
      releaseConditions: releaseConditions,
      applicableContexts: applicableContexts,
      shieldProfileId: shieldProfileId,
      temptationBundleId: temptationBundleId,
      sensorySceneId: sensorySceneId,
      fallbackProtocolId: fallbackProtocolId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        protocolId,
        version,
        triggerRules,
        releaseConditions,
        applicableContexts,
        shieldProfileId,
        temptationBundleId,
        sensorySceneId,
        fallbackProtocolId,
        createdAt,
      ];
}

class ActivationProtocol extends Equatable {
  const ActivationProtocol({
    required this.id,
    required this.profileId,
    required this.name,
    this.description,
    required this.protocolType,
    required this.originState,
    required this.targetState,
    this.activeVersion = 1,
    this.isEnabled = true,
    this.seedKey,
    this.linkedTaskId,
    this.maturity = ActivationRouteMaturity.experimental,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final String name;
  final String? description;
  final ActivationProtocolType protocolType;
  final ActivationTransitionState originState;
  final ActivationTransitionState targetState;
  final int activeVersion;
  final bool isEnabled;
  final String? seedKey;
  final EntityId? linkedTaskId;
  final ActivationRouteMaturity maturity;
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivationProtocol copyWith({
    String? name,
    String? description,
    bool? isEnabled,
    int? activeVersion,
    EntityId? linkedTaskId,
    bool clearLinkedTaskId = false,
    ActivationRouteMaturity? maturity,
    DateTime? updatedAt,
  }) {
    return ActivationProtocol(
      id: id,
      profileId: profileId,
      name: name ?? this.name,
      description: description ?? this.description,
      protocolType: protocolType,
      originState: originState,
      targetState: targetState,
      activeVersion: activeVersion ?? this.activeVersion,
      isEnabled: isEnabled ?? this.isEnabled,
      seedKey: seedKey,
      linkedTaskId:
          clearLinkedTaskId ? null : (linkedTaskId ?? this.linkedTaskId),
      maturity: maturity ?? this.maturity,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id.value,
        'profile_id': profileId.value,
        'name': name,
        'description': description,
        'protocol_type': protocolType.name,
        'origin_state': originState.toJson(),
        'target_state': targetState.toJson(),
        'active_version': activeVersion,
        'is_enabled': isEnabled,
        'seed_key': seedKey,
        'linked_task_id': linkedTaskId?.value,
        'maturity': maturity.name,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory ActivationProtocol.fromJson(Map<String, Object?> json) {
    return ActivationProtocol(
      id: EntityId(json['id'] as String),
      profileId: EntityId(json['profile_id'] as String),
      name: json['name'] as String,
      description: json['description'] as String?,
      protocolType: ActivationProtocolType.values.byName(
        json['protocol_type'] as String,
      ),
      originState: ActivationTransitionState.fromJson(
        _asMap(json['origin_state']),
      ),
      targetState: ActivationTransitionState.fromJson(
        _asMap(json['target_state']),
      ),
      activeVersion: (json['active_version'] as num?)?.toInt() ?? 1,
      isEnabled: json['is_enabled'] as bool? ?? true,
      seedKey: json['seed_key'] as String?,
      linkedTaskId: json['linked_task_id'] == null
          ? null
          : EntityId(json['linked_task_id'] as String),
      maturity: _enumOr(
        ActivationRouteMaturity.values,
        json['maturity'] as String?,
        ActivationRouteMaturity.experimental,
      ),
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        name,
        description,
        protocolType,
        originState,
        targetState,
        activeVersion,
        isEnabled,
        seedKey,
        linkedTaskId,
        maturity,
        createdAt,
        updatedAt,
      ];
}

class ActivationProtocolBundle extends Equatable {
  const ActivationProtocolBundle({
    required this.protocol,
    required this.version,
    required this.commands,
  });

  final ActivationProtocol protocol;
  final ActivationProtocolVersion version;
  final List<ActivationCommandTemplate> commands;

  List<ActivationCommandTemplate> get orderedCommands {
    final copy = [...commands];
    copy.sort((a, b) => a.sequenceKey.compareTo(b.sequenceKey));
    return copy;
  }

  @override
  List<Object?> get props => [protocol, version, commands];
}

class ActivationEpisode extends Equatable {
  const ActivationEpisode({
    required this.id,
    required this.profileId,
    this.protocolId,
    this.protocolVersion,
    required this.triggerType,
    this.hypothesisType,
    this.hypothesisConfidence,
    required this.capacityMode,
    required this.initialState,
    required this.targetState,
    required this.status,
    required this.startedAt,
    this.firstMotionAt,
    this.releasedAt,
    this.endedAt,
    this.interventionLevelMax = 0,
    this.shieldUsed = false,
    this.bundleUsed = false,
    this.escapeUsed = false,
    this.userCorrection,
    this.linkedTaskId,
    this.experimentAssignmentId,
    this.provenance = const ActivationProvenance(),
  });

  final EntityId id;
  final EntityId profileId;
  final EntityId? protocolId;
  final int? protocolVersion;
  final ActivationTriggerType triggerType;
  final InertiaHypothesisType? hypothesisType;
  final double? hypothesisConfidence;
  final ActivationCapacityMode capacityMode;
  final ActivationTransitionState initialState;
  final ActivationTransitionState targetState;
  final ActivationEpisodeStatus status;
  final DateTime startedAt;
  final DateTime? firstMotionAt;
  final DateTime? releasedAt;
  final DateTime? endedAt;
  final int interventionLevelMax;
  final bool shieldUsed;
  final bool bundleUsed;
  final bool escapeUsed;
  final String? userCorrection;
  final EntityId? linkedTaskId;
  final EntityId? experimentAssignmentId;
  final ActivationProvenance provenance;

  Duration? get activationLatency => firstMotionAt == null
      ? null
      : firstMotionAt!.difference(startedAt);

  ActivationEpisode copyWith({
    ActivationEpisodeStatus? status,
    DateTime? firstMotionAt,
    DateTime? releasedAt,
    DateTime? endedAt,
    int? interventionLevelMax,
    bool? shieldUsed,
    bool? bundleUsed,
    bool? escapeUsed,
    String? userCorrection,
    ActivationCapacityMode? capacityMode,
    EntityId? experimentAssignmentId,
  }) {
    return ActivationEpisode(
      id: id,
      profileId: profileId,
      protocolId: protocolId,
      protocolVersion: protocolVersion,
      triggerType: triggerType,
      hypothesisType: hypothesisType,
      hypothesisConfidence: hypothesisConfidence,
      capacityMode: capacityMode ?? this.capacityMode,
      initialState: initialState,
      targetState: targetState,
      status: status ?? this.status,
      startedAt: startedAt,
      firstMotionAt: firstMotionAt ?? this.firstMotionAt,
      releasedAt: releasedAt ?? this.releasedAt,
      endedAt: endedAt ?? this.endedAt,
      interventionLevelMax: interventionLevelMax ?? this.interventionLevelMax,
      shieldUsed: shieldUsed ?? this.shieldUsed,
      bundleUsed: bundleUsed ?? this.bundleUsed,
      escapeUsed: escapeUsed ?? this.escapeUsed,
      userCorrection: userCorrection ?? this.userCorrection,
      linkedTaskId: linkedTaskId,
      experimentAssignmentId:
          experimentAssignmentId ?? this.experimentAssignmentId,
      provenance: provenance,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id.value,
        'profile_id': profileId.value,
        'protocol_id': protocolId?.value,
        'protocol_version': protocolVersion,
        'trigger_type': triggerType.name,
        'hypothesis_type': hypothesisType?.name,
        'hypothesis_confidence': hypothesisConfidence,
        'capacity_mode': capacityMode.name,
        'initial_state': initialState.toJson(),
        'target_state': targetState.toJson(),
        'status': status.name,
        'started_at': startedAt.toUtc().toIso8601String(),
        'first_motion_at': firstMotionAt?.toUtc().toIso8601String(),
        'released_at': releasedAt?.toUtc().toIso8601String(),
        'ended_at': endedAt?.toUtc().toIso8601String(),
        'intervention_level_max': interventionLevelMax,
        'shield_used': shieldUsed,
        'bundle_used': bundleUsed,
        'escape_used': escapeUsed,
        'user_correction': userCorrection,
        'linked_task_id': linkedTaskId?.value,
        'experiment_assignment_id': experimentAssignmentId?.value,
        'provenance': provenance.toJson(),
      };

  factory ActivationEpisode.fromJson(Map<String, Object?> json) {
    return ActivationEpisode(
      id: EntityId(json['id'] as String),
      profileId: EntityId(json['profile_id'] as String),
      protocolId: json['protocol_id'] == null
          ? null
          : EntityId(json['protocol_id'] as String),
      protocolVersion: (json['protocol_version'] as num?)?.toInt(),
      triggerType: ActivationTriggerType.values.byName(
        json['trigger_type'] as String,
      ),
      hypothesisType: json['hypothesis_type'] == null
          ? null
          : InertiaHypothesisType.values.byName(
              json['hypothesis_type'] as String,
            ),
      hypothesisConfidence:
          (json['hypothesis_confidence'] as num?)?.toDouble(),
      capacityMode: ActivationCapacityMode.values.byName(
        json['capacity_mode'] as String,
      ),
      initialState: ActivationTransitionState.fromJson(
        _asMap(json['initial_state']),
      ),
      targetState: ActivationTransitionState.fromJson(
        _asMap(json['target_state']),
      ),
      status: ActivationEpisodeStatus.values.byName(json['status'] as String),
      startedAt: DateTime.parse(json['started_at'] as String).toUtc(),
      firstMotionAt: json['first_motion_at'] == null
          ? null
          : DateTime.parse(json['first_motion_at'] as String).toUtc(),
      releasedAt: json['released_at'] == null
          ? null
          : DateTime.parse(json['released_at'] as String).toUtc(),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String).toUtc(),
      interventionLevelMax:
          (json['intervention_level_max'] as num?)?.toInt() ?? 0,
      shieldUsed: json['shield_used'] as bool? ?? false,
      bundleUsed: json['bundle_used'] as bool? ?? false,
      escapeUsed: json['escape_used'] as bool? ?? false,
      userCorrection: json['user_correction'] as String?,
      linkedTaskId: json['linked_task_id'] == null
          ? null
          : EntityId(json['linked_task_id'] as String),
      experimentAssignmentId: json['experiment_assignment_id'] == null
          ? null
          : EntityId(json['experiment_assignment_id'] as String),
      provenance: ActivationProvenance.fromJson(_asMap(json['provenance'])),
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        protocolId,
        protocolVersion,
        triggerType,
        hypothesisType,
        hypothesisConfidence,
        capacityMode,
        initialState,
        targetState,
        status,
        startedAt,
        firstMotionAt,
        releasedAt,
        endedAt,
        interventionLevelMax,
        shieldUsed,
        bundleUsed,
        escapeUsed,
        userCorrection,
        linkedTaskId,
        experimentAssignmentId,
        provenance,
      ];
}

class ActivationCommandRun extends Equatable {
  const ActivationCommandRun({
    required this.id,
    required this.episodeId,
    this.templateId,
    required this.sequenceIndex,
    required this.instructionRendered,
    required this.status,
    required this.presentedAt,
    this.firstSignalAt,
    this.confirmedAt,
    this.skippedAt,
    this.adaptedAt,
    this.confirmationMode,
    this.proofConfidence,
    this.adaptationReason,
    this.isFirstMeaningfulAction = false,
    this.deepLink,
    this.opensTaskId,
  });

  final EntityId id;
  final EntityId episodeId;
  final EntityId? templateId;
  final int sequenceIndex;
  final String instructionRendered;
  final ActivationCommandRunStatus status;
  final DateTime presentedAt;
  final DateTime? firstSignalAt;
  final DateTime? confirmedAt;
  final DateTime? skippedAt;
  final DateTime? adaptedAt;
  final ActivationConfirmationMode? confirmationMode;
  final double? proofConfidence;
  final String? adaptationReason;
  final bool isFirstMeaningfulAction;
  final String? deepLink;
  final EntityId? opensTaskId;

  ActivationCommandRun copyWith({
    ActivationCommandRunStatus? status,
    DateTime? presentedAt,
    DateTime? firstSignalAt,
    DateTime? confirmedAt,
    DateTime? skippedAt,
    DateTime? adaptedAt,
    ActivationConfirmationMode? confirmationMode,
    double? proofConfidence,
    String? adaptationReason,
    String? instructionRendered,
    int? sequenceIndex,
  }) {
    return ActivationCommandRun(
      id: id,
      episodeId: episodeId,
      templateId: templateId,
      sequenceIndex: sequenceIndex ?? this.sequenceIndex,
      instructionRendered: instructionRendered ?? this.instructionRendered,
      status: status ?? this.status,
      presentedAt: presentedAt ?? this.presentedAt,
      firstSignalAt: firstSignalAt ?? this.firstSignalAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      skippedAt: skippedAt ?? this.skippedAt,
      adaptedAt: adaptedAt ?? this.adaptedAt,
      confirmationMode: confirmationMode ?? this.confirmationMode,
      proofConfidence: proofConfidence ?? this.proofConfidence,
      adaptationReason: adaptationReason ?? this.adaptationReason,
      isFirstMeaningfulAction: isFirstMeaningfulAction,
      deepLink: deepLink,
      opensTaskId: opensTaskId,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id.value,
        'episode_id': episodeId.value,
        'template_id': templateId?.value,
        'sequence_index': sequenceIndex,
        'instruction_rendered': instructionRendered,
        'status': status.name,
        'presented_at': presentedAt.toUtc().toIso8601String(),
        'first_signal_at': firstSignalAt?.toUtc().toIso8601String(),
        'confirmed_at': confirmedAt?.toUtc().toIso8601String(),
        'skipped_at': skippedAt?.toUtc().toIso8601String(),
        'adapted_at': adaptedAt?.toUtc().toIso8601String(),
        'confirmation_mode': confirmationMode?.name,
        'proof_confidence': proofConfidence,
        'adaptation_reason': adaptationReason,
        'is_first_meaningful_action': isFirstMeaningfulAction,
        'deep_link': deepLink,
        'opens_task_id': opensTaskId?.value,
      };

  factory ActivationCommandRun.fromJson(Map<String, Object?> json) {
    return ActivationCommandRun(
      id: EntityId(json['id'] as String),
      episodeId: EntityId(json['episode_id'] as String),
      templateId: json['template_id'] == null
          ? null
          : EntityId(json['template_id'] as String),
      sequenceIndex: (json['sequence_index'] as num).toInt(),
      instructionRendered: json['instruction_rendered'] as String,
      status: ActivationCommandRunStatus.values.byName(
        json['status'] as String,
      ),
      presentedAt: DateTime.parse(json['presented_at'] as String).toUtc(),
      firstSignalAt: json['first_signal_at'] == null
          ? null
          : DateTime.parse(json['first_signal_at'] as String).toUtc(),
      confirmedAt: json['confirmed_at'] == null
          ? null
          : DateTime.parse(json['confirmed_at'] as String).toUtc(),
      skippedAt: json['skipped_at'] == null
          ? null
          : DateTime.parse(json['skipped_at'] as String).toUtc(),
      adaptedAt: json['adapted_at'] == null
          ? null
          : DateTime.parse(json['adapted_at'] as String).toUtc(),
      confirmationMode: json['confirmation_mode'] == null
          ? null
          : ActivationConfirmationMode.values.byName(
              json['confirmation_mode'] as String,
            ),
      proofConfidence: (json['proof_confidence'] as num?)?.toDouble(),
      adaptationReason: json['adaptation_reason'] as String?,
      isFirstMeaningfulAction:
          json['is_first_meaningful_action'] as bool? ?? false,
      deepLink: json['deep_link'] as String?,
      opensTaskId: json['opens_task_id'] == null
          ? null
          : EntityId(json['opens_task_id'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        episodeId,
        templateId,
        sequenceIndex,
        instructionRendered,
        status,
        presentedAt,
        firstSignalAt,
        confirmedAt,
        skippedAt,
        adaptedAt,
        confirmationMode,
        proofConfidence,
        adaptationReason,
        isFirstMeaningfulAction,
        deepLink,
        opensTaskId,
      ];
}

class ActivationProof extends Equatable {
  const ActivationProof({
    required this.id,
    required this.episodeId,
    this.commandRunId,
    required this.proofType,
    required this.observedAt,
    required this.source,
    required this.confidence,
    this.privacyClass = PrivacyClass.personal,
    this.interpretation = const {},
    this.rawReference,
    this.userConfirmed,
  });

  final EntityId id;
  final EntityId episodeId;
  final EntityId? commandRunId;
  final ActivationProofType proofType;
  final DateTime observedAt;
  final String source;
  final double confidence;
  final PrivacyClass privacyClass;
  final Map<String, Object?> interpretation;
  final String? rawReference;
  final bool? userConfirmed;

  Map<String, Object?> toJson() => {
        'id': id.value,
        'episode_id': episodeId.value,
        'command_run_id': commandRunId?.value,
        'proof_type': proofType.name,
        'observed_at': observedAt.toUtc().toIso8601String(),
        'source': source,
        'confidence': confidence,
        'privacy_class': privacyClass.name,
        'interpretation': interpretation,
        'raw_reference': rawReference,
        'user_confirmed': userConfirmed,
      };

  factory ActivationProof.fromJson(Map<String, Object?> json) {
    return ActivationProof(
      id: EntityId(json['id'] as String),
      episodeId: EntityId(json['episode_id'] as String),
      commandRunId: json['command_run_id'] == null
          ? null
          : EntityId(json['command_run_id'] as String),
      proofType: ActivationProofType.values.byName(json['proof_type'] as String),
      observedAt: DateTime.parse(json['observed_at'] as String).toUtc(),
      source: json['source'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      privacyClass: _enumOr(
        PrivacyClass.values,
        json['privacy_class'] as String?,
        PrivacyClass.personal,
      ),
      interpretation: _asMap(json['interpretation']),
      rawReference: json['raw_reference'] as String?,
      userConfirmed: json['user_confirmed'] as bool?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        episodeId,
        commandRunId,
        proofType,
        observedAt,
        source,
        confidence,
        privacyClass,
        interpretation,
        rawReference,
        userConfirmed,
      ];
}

class ActivationWaypoint extends Equatable {
  const ActivationWaypoint({
    required this.id,
    required this.profileId,
    required this.name,
    required this.waypointType,
    this.zoneId,
    this.equipmentId,
    this.token,
    this.settings = const {},
    this.reliabilityScore,
    this.privacyClass = PrivacyClass.personal,
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final String name;
  final ActivationWaypointType waypointType;
  final EntityId? zoneId;
  final EntityId? equipmentId;
  final String? token;
  final Map<String, Object?> settings;
  final double? reliabilityScore;
  final PrivacyClass privacyClass;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivationWaypoint copyWith({
    String? name,
    bool? isEnabled,
    double? reliabilityScore,
    EntityId? zoneId,
    String? token,
    DateTime? updatedAt,
  }) {
    return ActivationWaypoint(
      id: id,
      profileId: profileId,
      name: name ?? this.name,
      waypointType: waypointType,
      zoneId: zoneId ?? this.zoneId,
      equipmentId: equipmentId,
      token: token ?? this.token,
      settings: settings,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      privacyClass: privacyClass,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id.value,
        'profile_id': profileId.value,
        'name': name,
        'waypoint_type': waypointType.name,
        'zone_id': zoneId?.value,
        'equipment_id': equipmentId?.value,
        'token': token,
        'settings': settings,
        'reliability_score': reliabilityScore,
        'privacy_class': privacyClass.name,
        'is_enabled': isEnabled,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory ActivationWaypoint.fromJson(Map<String, Object?> json) {
    return ActivationWaypoint(
      id: EntityId(json['id'] as String),
      profileId: EntityId(json['profile_id'] as String),
      name: json['name'] as String,
      waypointType: ActivationWaypointType.values.byName(
        json['waypoint_type'] as String,
      ),
      zoneId:
          json['zone_id'] == null ? null : EntityId(json['zone_id'] as String),
      equipmentId: json['equipment_id'] == null
          ? null
          : EntityId(json['equipment_id'] as String),
      token: json['token'] as String?,
      settings: _asMap(json['settings']),
      reliabilityScore: (json['reliability_score'] as num?)?.toDouble(),
      privacyClass: _enumOr(
        PrivacyClass.values,
        json['privacy_class'] as String?,
        PrivacyClass.personal,
      ),
      isEnabled: json['is_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        name,
        waypointType,
        zoneId,
        equipmentId,
        token,
        settings,
        reliabilityScore,
        privacyClass,
        isEnabled,
        createdAt,
        updatedAt,
      ];
}

class WaypointObservation extends Equatable {
  const WaypointObservation({
    required this.id,
    required this.waypointId,
    this.episodeId,
    required this.observedAt,
    required this.state,
    required this.latencyMs,
    this.source = 'manual',
  });

  final EntityId id;
  final EntityId waypointId;
  final EntityId? episodeId;
  final DateTime observedAt;
  final ActivationWaypointListenState state;
  final int latencyMs;
  final String source;

  Map<String, Object?> toJson() => {
        'id': id.value,
        'waypoint_id': waypointId.value,
        'episode_id': episodeId?.value,
        'observed_at': observedAt.toUtc().toIso8601String(),
        'state': state.name,
        'latency_ms': latencyMs,
        'source': source,
      };

  factory WaypointObservation.fromJson(Map<String, Object?> json) {
    return WaypointObservation(
      id: EntityId(json['id'] as String),
      waypointId: EntityId(json['waypoint_id'] as String),
      episodeId: json['episode_id'] == null
          ? null
          : EntityId(json['episode_id'] as String),
      observedAt: DateTime.parse(json['observed_at'] as String).toUtc(),
      state: ActivationWaypointListenState.values.byName(
        json['state'] as String,
      ),
      latencyMs: (json['latency_ms'] as num).toInt(),
      source: (json['source'] as String?) ?? 'manual',
    );
  }

  @override
  List<Object?> get props =>
      [id, waypointId, episodeId, observedAt, state, latencyMs, source];
}

class InertiaSignal extends Equatable {
  const InertiaSignal({
    required this.id,
    this.episodeId,
    required this.signalType,
    required this.observedAt,
    this.value = const {},
    required this.source,
    required this.confidence,
    this.expiresAt,
    this.privacyClass = PrivacyClass.personal,
  });

  final EntityId id;
  final EntityId? episodeId;
  final InertiaSignalType signalType;
  final DateTime observedAt;
  final Map<String, Object?> value;
  final String source;
  final double confidence;
  final DateTime? expiresAt;
  final PrivacyClass privacyClass;

  bool isExpired(DateTime now) =>
      expiresAt != null && !expiresAt!.isAfter(now);

  Map<String, Object?> toJson() => {
        'id': id.value,
        'episode_id': episodeId?.value,
        'signal_type': signalType.name,
        'observed_at': observedAt.toUtc().toIso8601String(),
        'value': value,
        'source': source,
        'confidence': confidence,
        'expires_at': expiresAt?.toUtc().toIso8601String(),
        'privacy_class': privacyClass.name,
      };

  factory InertiaSignal.fromJson(Map<String, Object?> json) {
    return InertiaSignal(
      id: EntityId(json['id'] as String),
      episodeId: json['episode_id'] == null
          ? null
          : EntityId(json['episode_id'] as String),
      signalType: InertiaSignalType.values.byName(json['signal_type'] as String),
      observedAt: DateTime.parse(json['observed_at'] as String).toUtc(),
      value: _asMap(json['value']),
      source: json['source'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String).toUtc(),
      privacyClass: _enumOr(
        PrivacyClass.values,
        json['privacy_class'] as String?,
        PrivacyClass.personal,
      ),
    );
  }

  @override
  List<Object?> get props => [
        id,
        episodeId,
        signalType,
        observedAt,
        value,
        source,
        confidence,
        expiresAt,
        privacyClass,
      ];
}

class InertiaHypothesis extends Equatable {
  const InertiaHypothesis({
    required this.type,
    required this.confidence,
    required this.breakdown,
    this.counterevidence = const [],
  });

  final InertiaHypothesisType type;
  final double confidence;
  final Map<String, double> breakdown;
  final List<String> counterevidence;

  ConfidenceLevel get band => ActivationProofConfidence.band(confidence);

  Map<String, Object?> toJson() => {
        'type': type.name,
        'confidence': confidence,
        'breakdown': breakdown,
        'counterevidence': counterevidence,
      };

  @override
  List<Object?> get props => [type, confidence, breakdown, counterevidence];
}

class FrictionShieldProfile extends Equatable {
  const FrictionShieldProfile({
    required this.id,
    required this.profileId,
    required this.name,
    required this.platformMode,
    this.protectedCategories = const [],
    this.allowlistCategories = const ['emergency', 'auth', 'maps', 'medical'],
    this.escapePolicy = const ActivationEscapePolicy(),
    this.isEnabled = true,
  });

  final EntityId id;
  final EntityId profileId;
  final String name;
  final FrictionShieldPlatformMode platformMode;
  final List<String> protectedCategories;
  final List<String> allowlistCategories;
  final ActivationEscapePolicy escapePolicy;
  final bool isEnabled;

  Map<String, Object?> toJson() => {
        'id': id.value,
        'profile_id': profileId.value,
        'name': name,
        'platform_mode': platformMode.name,
        'protected_categories': protectedCategories,
        'allowlist_categories': allowlistCategories,
        'escape_policy': escapePolicy.toJson(),
        'is_enabled': isEnabled,
      };

  factory FrictionShieldProfile.fromJson(Map<String, Object?> json) {
    final protected = json['protected_categories'];
    final allow = json['allowlist_categories'];
    return FrictionShieldProfile(
      id: EntityId(json['id'] as String),
      profileId: EntityId(json['profile_id'] as String),
      name: json['name'] as String,
      platformMode: FrictionShieldPlatformMode.values.byName(
        json['platform_mode'] as String,
      ),
      protectedCategories: protected is List
          ? [for (final item in protected) item.toString()]
          : const [],
      allowlistCategories: allow is List
          ? [for (final item in allow) item.toString()]
          : const ['emergency', 'auth', 'maps', 'medical'],
      escapePolicy: ActivationEscapePolicy.fromJson(
        _asMap(json['escape_policy']),
      ),
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        name,
        platformMode,
        protectedCategories,
        allowlistCategories,
        escapePolicy,
        isEnabled,
      ];
}

class FrictionShieldSession extends Equatable {
  const FrictionShieldSession({
    required this.id,
    required this.profileId,
    required this.shieldProfileId,
    this.episodeId,
    required this.state,
    required this.startedAt,
    this.endedAt,
    this.escapeCount = 0,
  });

  final EntityId id;
  final EntityId profileId;
  final EntityId shieldProfileId;
  final EntityId? episodeId;
  final FrictionShieldState state;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int escapeCount;

  FrictionShieldSession copyWith({
    FrictionShieldState? state,
    DateTime? endedAt,
    int? escapeCount,
  }) {
    return FrictionShieldSession(
      id: id,
      profileId: profileId,
      shieldProfileId: shieldProfileId,
      episodeId: episodeId,
      state: state ?? this.state,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      escapeCount: escapeCount ?? this.escapeCount,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id.value,
        'profile_id': profileId.value,
        'shield_profile_id': shieldProfileId.value,
        'episode_id': episodeId?.value,
        'state': state.name,
        'started_at': startedAt.toUtc().toIso8601String(),
        'ended_at': endedAt?.toUtc().toIso8601String(),
        'escape_count': escapeCount,
      };

  factory FrictionShieldSession.fromJson(Map<String, Object?> json) {
    return FrictionShieldSession(
      id: EntityId(json['id'] as String),
      profileId: EntityId(json['profile_id'] as String),
      shieldProfileId: EntityId(json['shield_profile_id'] as String),
      episodeId: json['episode_id'] == null
          ? null
          : EntityId(json['episode_id'] as String),
      state: FrictionShieldState.values.byName(json['state'] as String),
      startedAt: DateTime.parse(json['started_at'] as String).toUtc(),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String).toUtc(),
      escapeCount: (json['escape_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        shieldProfileId,
        episodeId,
        state,
        startedAt,
        endedAt,
        escapeCount,
      ];
}

class TemptationBundle extends Equatable {
  const TemptationBundle({
    required this.id,
    required this.profileId,
    required this.name,
    required this.pleasureLabel,
    required this.requiredTransition,
    this.audioHint,
    this.isEnabled = true,
  });

  final EntityId id;
  final EntityId profileId;
  final String name;
  final String pleasureLabel;
  final String requiredTransition;
  final String? audioHint;
  final bool isEnabled;

  Map<String, Object?> toJson() => {
        'id': id.value,
        'profile_id': profileId.value,
        'name': name,
        'pleasure_label': pleasureLabel,
        'required_transition': requiredTransition,
        'audio_hint': audioHint,
        'is_enabled': isEnabled,
      };

  factory TemptationBundle.fromJson(Map<String, Object?> json) {
    return TemptationBundle(
      id: EntityId(json['id'] as String),
      profileId: EntityId(json['profile_id'] as String),
      name: json['name'] as String,
      pleasureLabel: json['pleasure_label'] as String,
      requiredTransition: json['required_transition'] as String,
      audioHint: json['audio_hint'] as String?,
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        name,
        pleasureLabel,
        requiredTransition,
        audioHint,
        isEnabled,
      ];
}

class ActivationScene extends Equatable {
  const ActivationScene({
    required this.id,
    required this.profileId,
    required this.name,
    required this.kind,
    this.payload = const {},
    this.isEnabled = true,
  });

  final EntityId id;
  final EntityId profileId;
  final String name;
  final ActivationSceneKind kind;
  final Map<String, Object?> payload;
  final bool isEnabled;

  Map<String, Object?> toJson() => {
        'id': id.value,
        'profile_id': profileId.value,
        'name': name,
        'kind': kind.name,
        'payload': payload,
        'is_enabled': isEnabled,
      };

  factory ActivationScene.fromJson(Map<String, Object?> json) {
    return ActivationScene(
      id: EntityId(json['id'] as String),
      profileId: EntityId(json['profile_id'] as String),
      name: json['name'] as String,
      kind: ActivationSceneKind.values.byName(json['kind'] as String),
      payload: _asMap(json['payload']),
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, profileId, name, kind, payload, isEnabled];
}

class RescueContract extends Equatable {
  const RescueContract({
    required this.id,
    required this.profileId,
    required this.contactLabel,
    required this.messageTemplate,
    required this.status,
    this.personId,
    this.requiresConfirmation = true,
    this.lastConfirmedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final String contactLabel;
  final String messageTemplate;
  final RescueContractStatus status;
  final EntityId? personId;
  final bool requiresConfirmation;
  final DateTime? lastConfirmedAt;

  Map<String, Object?> toJson() => {
        'id': id.value,
        'profile_id': profileId.value,
        'contact_label': contactLabel,
        'message_template': messageTemplate,
        'status': status.name,
        'person_id': personId?.value,
        'requires_confirmation': requiresConfirmation,
        'last_confirmed_at': lastConfirmedAt?.toUtc().toIso8601String(),
      };

  factory RescueContract.fromJson(Map<String, Object?> json) {
    return RescueContract(
      id: EntityId(json['id'] as String),
      profileId: EntityId(json['profile_id'] as String),
      contactLabel: json['contact_label'] as String,
      messageTemplate: json['message_template'] as String,
      status: RescueContractStatus.values.byName(json['status'] as String),
      personId: json['person_id'] == null
          ? null
          : EntityId(json['person_id'] as String),
      requiresConfirmation: json['requires_confirmation'] as bool? ?? true,
      lastConfirmedAt: json['last_confirmed_at'] == null
          ? null
          : DateTime.parse(json['last_confirmed_at'] as String).toUtc(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        contactLabel,
        messageTemplate,
        status,
        personId,
        requiresConfirmation,
        lastConfirmedAt,
      ];
}

class ActivationExperiment extends Equatable {
  const ActivationExperiment({
    required this.id,
    required this.profileId,
    required this.name,
    required this.hypothesis,
    required this.variableKey,
    required this.variants,
    this.contextFilter = const {},
    this.minimumSamples = 6,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.result,
  });

  final EntityId id;
  final EntityId profileId;
  final String name;
  final String hypothesis;
  final String variableKey;
  final List<String> variants;
  final Map<String, Object?> contextFilter;
  final int minimumSamples;
  final ActivationExperimentStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final Map<String, Object?>? result;

  Map<String, Object?> toJson() => {
        'id': id.value,
        'profile_id': profileId.value,
        'name': name,
        'hypothesis': hypothesis,
        'variable_key': variableKey,
        'variants': variants,
        'context_filter': contextFilter,
        'minimum_samples': minimumSamples,
        'status': status.name,
        'started_at': startedAt?.toUtc().toIso8601String(),
        'ended_at': endedAt?.toUtc().toIso8601String(),
        'result': result,
      };

  factory ActivationExperiment.fromJson(Map<String, Object?> json) {
    final variants = json['variants'];
    return ActivationExperiment(
      id: EntityId(json['id'] as String),
      profileId: EntityId(json['profile_id'] as String),
      name: json['name'] as String,
      hypothesis: json['hypothesis'] as String,
      variableKey: json['variable_key'] as String,
      variants: variants is List
          ? [for (final item in variants) item.toString()]
          : const [],
      contextFilter: _asMap(json['context_filter']),
      minimumSamples: (json['minimum_samples'] as num?)?.toInt() ?? 6,
      status: ActivationExperimentStatus.values.byName(json['status'] as String),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String).toUtc(),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String).toUtc(),
      result: json['result'] == null ? null : _asMap(json['result']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        name,
        hypothesis,
        variableKey,
        variants,
        contextFilter,
        minimumSamples,
        status,
        startedAt,
        endedAt,
        result,
      ];
}

class ActivationExperimentAssignment extends Equatable {
  const ActivationExperimentAssignment({
    required this.id,
    required this.experimentId,
    required this.episodeId,
    required this.variant,
    required this.assignedAt,
  });

  final EntityId id;
  final EntityId experimentId;
  final EntityId episodeId;
  final String variant;
  final DateTime assignedAt;

  Map<String, Object?> toJson() => {
        'id': id.value,
        'experiment_id': experimentId.value,
        'episode_id': episodeId.value,
        'variant': variant,
        'assigned_at': assignedAt.toUtc().toIso8601String(),
      };

  factory ActivationExperimentAssignment.fromJson(Map<String, Object?> json) {
    return ActivationExperimentAssignment(
      id: EntityId(json['id'] as String),
      experimentId: EntityId(json['experiment_id'] as String),
      episodeId: EntityId(json['episode_id'] as String),
      variant: json['variant'] as String,
      assignedAt: DateTime.parse(json['assigned_at'] as String).toUtc(),
    );
  }

  @override
  List<Object?> get props =>
      [id, experimentId, episodeId, variant, assignedAt];
}

class ActivationInsight extends Equatable {
  const ActivationInsight({
    required this.id,
    required this.profileId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.sampleSize = 0,
    this.confidence = ConfidenceLevel.low,
    this.associativeOnly = true,
  });

  final EntityId id;
  final EntityId profileId;
  final String title;
  final String body;
  final DateTime createdAt;
  final int sampleSize;
  final ConfidenceLevel confidence;
  final bool associativeOnly;

  static const causalityDisclaimer =
      'Este padrão está associado a menor latência em episódios comparáveis. '
      'O sistema não demonstrou causa.';

  Map<String, Object?> toJson() => {
        'id': id.value,
        'profile_id': profileId.value,
        'title': title,
        'body': body,
        'created_at': createdAt.toUtc().toIso8601String(),
        'sample_size': sampleSize,
        'confidence': confidence.name,
        'associative_only': associativeOnly,
      };

  factory ActivationInsight.fromJson(Map<String, Object?> json) {
    return ActivationInsight(
      id: EntityId(json['id'] as String),
      profileId: EntityId(json['profile_id'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      sampleSize: (json['sample_size'] as num?)?.toInt() ?? 0,
      confidence: _enumOr(
        ConfidenceLevel.values,
        json['confidence'] as String?,
        ConfidenceLevel.low,
      ),
      associativeOnly: json['associative_only'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        title,
        body,
        createdAt,
        sampleSize,
        confidence,
        associativeOnly,
      ];
}

class ActivationExportBundle extends Equatable {
  const ActivationExportBundle({
    this.protocols = const [],
    this.versions = const [],
    this.commands = const [],
    this.episodes = const [],
    this.commandRuns = const [],
    this.proofs = const [],
    this.waypoints = const [],
    this.shieldProfiles = const [],
    this.bundles = const [],
    this.scenes = const [],
    this.experiments = const [],
    this.assignments = const [],
    this.insights = const [],
  });

  final List<ActivationProtocol> protocols;
  final List<ActivationProtocolVersion> versions;
  final List<ActivationCommandTemplate> commands;
  final List<ActivationEpisode> episodes;
  final List<ActivationCommandRun> commandRuns;
  final List<ActivationProof> proofs;
  final List<ActivationWaypoint> waypoints;
  final List<FrictionShieldProfile> shieldProfiles;
  final List<TemptationBundle> bundles;
  final List<ActivationScene> scenes;
  final List<ActivationExperiment> experiments;
  final List<ActivationExperimentAssignment> assignments;
  final List<ActivationInsight> insights;

  Map<String, int> get counts => {
        'activation_protocols': protocols.length,
        'activation_protocol_versions': versions.length,
        'activation_command_templates': commands.length,
        'activation_episodes': episodes.length,
        'activation_command_runs': commandRuns.length,
        'activation_proofs': proofs.length,
        'activation_waypoints': waypoints.length,
        'friction_shield_profiles': shieldProfiles.length,
        'temptation_bundles': bundles.length,
        'activation_scenes': scenes.length,
        'activation_experiments': experiments.length,
        'activation_experiment_assignments': assignments.length,
        'activation_insights': insights.length,
      };

  @override
  List<Object?> get props => [
        protocols,
        versions,
        commands,
        episodes,
        commandRuns,
        proofs,
        waypoints,
        shieldProfiles,
        bundles,
        scenes,
        experiments,
        assignments,
        insights,
      ];
}

class ActivationProofConfidence {
  const ActivationProofConfidence._();

  static const highThreshold = 0.8;
  static const mediumThreshold = 0.5;
  static const lowThreshold = 0.25;

  static ConfidenceLevel band(double confidence) {
    if (confidence >= highThreshold) return ConfidenceLevel.high;
    if (confidence >= mediumThreshold) return ConfidenceLevel.medium;
    if (confidence >= lowThreshold) return ConfidenceLevel.low;
    return ConfidenceLevel.insufficient;
  }
}

T _enumOr<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

Map<String, Object?> _asMap(Object? raw) {
  if (raw is Map<String, Object?>) return raw;
  if (raw is Map) {
    return {
      for (final entry in raw.entries) entry.key.toString(): entry.value,
    };
  }
  return const {};
}
