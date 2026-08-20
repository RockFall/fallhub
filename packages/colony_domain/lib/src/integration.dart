import 'package:equatable/equatable.dart';

import 'enums.dart';
import 'id_generator.dart';

enum IntegrationKind {
  calendarIcs,
  notificationListener,
}

/// Opt-in consent for a local integration adapter (ADR-032).
class IntegrationConsent extends Equatable {
  const IntegrationConsent({
    required this.id,
    required this.profileId,
    required this.kind,
    required this.enabled,
    this.grantedAt,
    this.revokedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final IntegrationKind kind;
  final bool enabled;
  final DateTime? grantedAt;
  final DateTime? revokedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory IntegrationConsent.create({
    required EntityId id,
    required EntityId profileId,
    required IntegrationKind kind,
    required DateTime createdAt,
    bool enabled = false,
  }) {
    return IntegrationConsent(
      id: id,
      profileId: profileId,
      kind: kind,
      enabled: enabled,
      grantedAt: enabled ? createdAt : null,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  IntegrationConsent grant(DateTime at) {
    return IntegrationConsent(
      id: id,
      profileId: profileId,
      kind: kind,
      enabled: true,
      grantedAt: at,
      revokedAt: null,
      createdAt: createdAt,
      updatedAt: at,
    );
  }

  /// Disabling does not erase previously imported local history.
  IntegrationConsent revoke(DateTime at) {
    return IntegrationConsent(
      id: id,
      profileId: profileId,
      kind: kind,
      enabled: false,
      grantedAt: grantedAt,
      revokedAt: at,
      createdAt: createdAt,
      updatedAt: at,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        kind,
        enabled,
        grantedAt,
        revokedAt,
        createdAt,
        updatedAt,
      ];
}

/// Parsed ICS VEVENT preview (ADR-032). Not persisted until confirm.
class IcsEventPreview extends Equatable {
  const IcsEventPreview({
    this.uid,
    required this.summary,
    required this.startAt,
    required this.endAt,
  });

  final String? uid;
  final String summary;
  final DateTime startAt;
  final DateTime endAt;

  @override
  List<Object?> get props => [uid, summary, startAt, endAt];
}

/// Imported calendar event with provenance (ADR-032). Local only.
class ExternalCalendarEvent extends Equatable {
  const ExternalCalendarEvent({
    required this.id,
    required this.profileId,
    this.externalUid,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.sourceType,
    required this.importedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final String? externalUid;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final SourceType sourceType;
  final DateTime importedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ExternalCalendarEvent.fromPreview({
    required EntityId id,
    required EntityId profileId,
    required IcsEventPreview preview,
    required DateTime importedAt,
  }) {
    final title = preview.summary.trim().isEmpty
        ? 'Evento importado'
        : preview.summary.trim();
    if (!preview.endAt.isAfter(preview.startAt)) {
      throw ArgumentError('ExternalCalendarEvent endAt must be after startAt');
    }
    return ExternalCalendarEvent(
      id: id,
      profileId: profileId,
      externalUid: preview.uid?.trim().isEmpty == true
          ? null
          : preview.uid?.trim(),
      title: title,
      startAt: preview.startAt.toUtc(),
      endAt: preview.endAt.toUtc(),
      sourceType: SourceType.integration,
      importedAt: importedAt,
      createdAt: importedAt,
      updatedAt: importedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        externalUid,
        title,
        startAt,
        endAt,
        sourceType,
        importedAt,
        createdAt,
        updatedAt,
      ];
}
