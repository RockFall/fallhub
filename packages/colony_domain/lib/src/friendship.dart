import 'package:equatable/equatable.dart';

import 'id_generator.dart';
import 'person.dart';
import 'person_interaction.dart';

/// User-assigned friendship classification. Never inferred from frequency.
enum FriendshipKind {
  innerCircle,
  close,
  regular,
  casual,
  acquaintance,
  childhood,
  familyFriend,
  colleagueSocial,
  neighbor,
  online,
  seasonal,
  dormant,
  unspecified,
}

/// Expected interval between encounters. `whenever` means no reminder.
enum FriendshipCadence {
  weekly,
  fortnightly,
  monthly,
  quarterly,
  semiannual,
  yearly,
  whenever,
}

/// Attention derived from cadence vs last encounter — not a quality score.
enum FriendshipAttention {
  overdue,
  dueSoon,
  onTrack,
  noCadence,
  neverMet,
}

extension FriendshipKindDefaults on FriendshipKind {
  FriendshipCadence get suggestedCadence => switch (this) {
        FriendshipKind.innerCircle => FriendshipCadence.weekly,
        FriendshipKind.close => FriendshipCadence.fortnightly,
        FriendshipKind.regular => FriendshipCadence.monthly,
        FriendshipKind.familyFriend => FriendshipCadence.monthly,
        FriendshipKind.neighbor => FriendshipCadence.monthly,
        FriendshipKind.casual => FriendshipCadence.quarterly,
        FriendshipKind.colleagueSocial => FriendshipCadence.quarterly,
        FriendshipKind.online => FriendshipCadence.quarterly,
        FriendshipKind.acquaintance => FriendshipCadence.semiannual,
        FriendshipKind.childhood => FriendshipCadence.yearly,
        FriendshipKind.seasonal => FriendshipCadence.yearly,
        FriendshipKind.dormant => FriendshipCadence.whenever,
        FriendshipKind.unspecified => FriendshipCadence.whenever,
      };
}

extension FriendshipCadenceDays on FriendshipCadence {
  int? get intervalDays => switch (this) {
        FriendshipCadence.weekly => 7,
        FriendshipCadence.fortnightly => 14,
        FriendshipCadence.monthly => 30,
        FriendshipCadence.quarterly => 90,
        FriendshipCadence.semiannual => 182,
        FriendshipCadence.yearly => 365,
        FriendshipCadence.whenever => null,
      };
}

extension InteractionEncounter on InteractionKind {
  /// In-person-ish gatherings used by friendship rhythm (ADR-045).
  bool get isEncounter =>
      this == InteractionKind.meeting || this == InteractionKind.gathering;
}

/// Overlay on [Person]: how the colony classifies and paces this friendship.
class Friendship extends Equatable {
  const Friendship({
    required this.id,
    required this.profileId,
    required this.personId,
    required this.kind,
    required this.cadence,
    this.howWeMet,
    this.startedAt,
    this.notes,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final EntityId personId;
  final FriendshipKind kind;
  final FriendshipCadence cadence;
  final String? howWeMet;
  final DateTime? startedAt;
  final String? notes;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isArchived => archivedAt != null;

  factory Friendship.create({
    required EntityId id,
    required EntityId profileId,
    required EntityId personId,
    FriendshipKind kind = FriendshipKind.unspecified,
    FriendshipCadence? cadence,
    String? howWeMet,
    DateTime? startedAt,
    String? notes,
    required DateTime createdAt,
  }) {
    final met = howWeMet?.trim();
    final trimmedNotes = notes?.trim();
    return Friendship(
      id: id,
      profileId: profileId,
      personId: personId,
      kind: kind,
      cadence: cadence ?? kind.suggestedCadence,
      howWeMet: (met == null || met.isEmpty) ? null : met,
      startedAt: startedAt?.toUtc(),
      notes: (trimmedNotes == null || trimmedNotes.isEmpty)
          ? null
          : trimmedNotes,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  Friendship copyWith({
    FriendshipKind? kind,
    FriendshipCadence? cadence,
    String? howWeMet,
    bool clearHowWeMet = false,
    DateTime? startedAt,
    bool clearStartedAt = false,
    String? notes,
    bool clearNotes = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    DateTime? updatedAt,
  }) {
    final nextMet = clearHowWeMet
        ? null
        : (howWeMet != null
            ? (howWeMet.trim().isEmpty ? null : howWeMet.trim())
            : this.howWeMet);
    final nextNotes = clearNotes
        ? null
        : (notes != null
            ? (notes.trim().isEmpty ? null : notes.trim())
            : this.notes);
    return Friendship(
      id: id,
      profileId: profileId,
      personId: personId,
      kind: kind ?? this.kind,
      cadence: cadence ?? this.cadence,
      howWeMet: nextMet,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      notes: nextNotes,
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        personId,
        kind,
        cadence,
        howWeMet,
        startedAt,
        notes,
        archivedAt,
        createdAt,
        updatedAt,
      ];
}

/// Named social circle (college, RPG table, neighbors…). Not an Organization.
class FriendshipCircle extends Equatable {
  const FriendshipCircle({
    required this.id,
    required this.profileId,
    required this.name,
    this.notes,
    this.defaultCadence,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final String name;
  final String? notes;
  final FriendshipCadence? defaultCadence;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isArchived => archivedAt != null;

  factory FriendshipCircle.create({
    required EntityId id,
    required EntityId profileId,
    required String name,
    String? notes,
    FriendshipCadence? defaultCadence,
    required DateTime createdAt,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('FriendshipCircle name cannot be empty');
    }
    final trimmedNotes = notes?.trim();
    return FriendshipCircle(
      id: id,
      profileId: profileId,
      name: trimmed,
      notes: (trimmedNotes == null || trimmedNotes.isEmpty)
          ? null
          : trimmedNotes,
      defaultCadence: defaultCadence,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  FriendshipCircle copyWith({
    String? name,
    String? notes,
    bool clearNotes = false,
    FriendshipCadence? defaultCadence,
    bool clearDefaultCadence = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    DateTime? updatedAt,
  }) {
    final nextName = name?.trim() ?? this.name;
    if (nextName.isEmpty) {
      throw ArgumentError('FriendshipCircle name cannot be empty');
    }
    final nextNotes = clearNotes
        ? null
        : (notes != null
            ? (notes.trim().isEmpty ? null : notes.trim())
            : this.notes);
    return FriendshipCircle(
      id: id,
      profileId: profileId,
      name: nextName,
      notes: nextNotes,
      defaultCadence:
          clearDefaultCadence ? null : (defaultCadence ?? this.defaultCadence),
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        name,
        notes,
        defaultCadence,
        archivedAt,
        createdAt,
        updatedAt,
      ];
}

class FriendshipCircleMembership extends Equatable {
  const FriendshipCircleMembership({
    required this.personId,
    required this.circleId,
    required this.linkedAt,
  });

  final EntityId personId;
  final EntityId circleId;
  final DateTime linkedAt;

  @override
  List<Object?> get props => [personId, circleId, linkedAt];
}

/// Derived encounter rhythm. Recalculated; never stored as a score.
class FriendshipRhythm extends Equatable {
  const FriendshipRhythm({
    this.lastEncounterAt,
    this.daysSinceLastEncounter,
    required this.encounterCount,
    this.typicalIntervalDays,
    this.cadenceDueAt,
    required this.attention,
  });

  final DateTime? lastEncounterAt;
  final int? daysSinceLastEncounter;
  final int encounterCount;
  final int? typicalIntervalDays;
  final DateTime? cadenceDueAt;
  final FriendshipAttention attention;

  bool get needsAttention =>
      attention == FriendshipAttention.overdue ||
      attention == FriendshipAttention.dueSoon;

  factory FriendshipRhythm.from({
    required Iterable<PersonInteraction> interactions,
    required FriendshipCadence cadence,
    required DateTime now,
  }) {
    final encounters = interactions
        .where((i) => i.kind.isEncounter)
        .toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    if (encounters.isEmpty) {
      return const FriendshipRhythm(
        encounterCount: 0,
        attention: FriendshipAttention.neverMet,
      );
    }

    final last = encounters.last.occurredAt.toUtc();
    final nowUtc = now.toUtc();
    final daysSince = nowUtc.difference(last).inDays;
    int? typical;
    if (encounters.length >= 2) {
      final gaps = <int>[];
      for (var i = 1; i < encounters.length; i++) {
        gaps.add(
          encounters[i]
              .occurredAt
              .toUtc()
              .difference(encounters[i - 1].occurredAt.toUtc())
              .inDays,
        );
      }
      gaps.sort();
      typical = gaps[gaps.length ~/ 2];
    }

    final interval = cadence.intervalDays;
    if (interval == null) {
      return FriendshipRhythm(
        lastEncounterAt: last,
        daysSinceLastEncounter: daysSince,
        encounterCount: encounters.length,
        typicalIntervalDays: typical,
        attention: FriendshipAttention.noCadence,
      );
    }

    final dueAt = last.add(Duration(days: interval));
    final FriendshipAttention attention;
    if (daysSince >= interval) {
      attention = FriendshipAttention.overdue;
    } else if (daysSince >= (interval * 0.8).floor()) {
      attention = FriendshipAttention.dueSoon;
    } else {
      attention = FriendshipAttention.onTrack;
    }

    return FriendshipRhythm(
      lastEncounterAt: last,
      daysSinceLastEncounter: daysSince,
      encounterCount: encounters.length,
      typicalIntervalDays: typical,
      cadenceDueAt: dueAt,
      attention: attention,
    );
  }

  @override
  List<Object?> get props => [
        lastEncounterAt,
        daysSinceLastEncounter,
        encounterCount,
        typicalIntervalDays,
        cadenceDueAt,
        attention,
      ];
}

/// Board row: person + overlay + circles + derived rhythm.
class FriendshipOverview extends Equatable {
  const FriendshipOverview({
    required this.person,
    required this.friendship,
    required this.circles,
    required this.rhythm,
  });

  final Person person;
  final Friendship friendship;
  final List<FriendshipCircle> circles;
  final FriendshipRhythm rhythm;

  static int compareAttention(FriendshipOverview a, FriendshipOverview b) {
    const order = {
      FriendshipAttention.overdue: 0,
      FriendshipAttention.dueSoon: 1,
      FriendshipAttention.neverMet: 2,
      FriendshipAttention.onTrack: 3,
      FriendshipAttention.noCadence: 4,
    };
    final byAttention =
        (order[a.rhythm.attention] ?? 9).compareTo(order[b.rhythm.attention] ?? 9);
    if (byAttention != 0) return byAttention;
    final aDays = a.rhythm.daysSinceLastEncounter ?? -1;
    final bDays = b.rhythm.daysSinceLastEncounter ?? -1;
    if (aDays != bDays) return bDays.compareTo(aDays);
    return a.person.displayName.toLowerCase().compareTo(
          b.person.displayName.toLowerCase(),
        );
  }

  static List<FriendshipOverview> assemble({
    required List<Person> people,
    required List<Friendship> friendships,
    required List<FriendshipCircle> circles,
    required List<FriendshipCircleMembership> memberships,
    required List<PersonInteraction> interactions,
    required DateTime now,
  }) {
    final personById = {for (final p in people) p.id: p};
    final circleById = {for (final c in circles) c.id: c};
    final circlesByPerson = <EntityId, List<FriendshipCircle>>{};
    for (final link in memberships) {
      final circle = circleById[link.circleId];
      if (circle == null || circle.isArchived) continue;
      circlesByPerson.putIfAbsent(link.personId, () => []).add(circle);
    }
    final interactionsByPerson = <EntityId, List<PersonInteraction>>{};
    for (final ix in interactions) {
      interactionsByPerson.putIfAbsent(ix.personId, () => []).add(ix);
    }

    final rows = <FriendshipOverview>[];
    for (final friendship in friendships) {
      if (friendship.isArchived) continue;
      final person = personById[friendship.personId];
      if (person == null || person.isArchived) continue;
      rows.add(
        FriendshipOverview(
          person: person,
          friendship: friendship,
          circles: List.unmodifiable(circlesByPerson[person.id] ?? const []),
          rhythm: FriendshipRhythm.from(
            interactions: interactionsByPerson[person.id] ?? const [],
            cadence: friendship.cadence,
            now: now,
          ),
        ),
      );
    }
    rows.sort(compareAttention);
    return List.unmodifiable(rows);
  }

  @override
  List<Object?> get props => [person, friendship, circles, rhythm];
}
