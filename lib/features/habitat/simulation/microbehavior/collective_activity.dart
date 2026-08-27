import 'habitat_rng.dart';

/// Block E — collective activity sophistication (MD 10 R48–R58).

enum ActivityRole {
  host,
  participant,
  spectator,
  leader,
  helper,
}

class ActivityRoleAssignment {
  ActivityRoleAssignment({
    required this.activityId,
    required this.roles,
  });

  final String activityId;
  final Map<String, ActivityRole> roles;

  void reassignLeader(String newLeader) {
    for (final e in roles.entries.toList()) {
      if (e.value == ActivityRole.leader) {
        roles[e.key] = ActivityRole.participant;
      }
    }
    roles[newLeader] = ActivityRole.leader;
  }
}

abstract final class ActivityRoles {
  static ActivityRoleAssignment assign({
    required String activityId,
    required List<String> pawnIds,
    String? hostId,
  }) {
    final roles = <String, ActivityRole>{};
    for (var i = 0; i < pawnIds.length; i++) {
      final id = pawnIds[i];
      if (id == hostId) {
        roles[id] = ActivityRole.host;
      } else if (i == 0 && hostId == null) {
        roles[id] = ActivityRole.leader;
      } else {
        roles[id] = ActivityRole.participant;
      }
    }
    return ActivityRoleAssignment(activityId: activityId, roles: roles);
  }
}

enum ActivityMicrobeat {
  boardgameRoll,
  boardgameReact,
  boardgamePassTurn,
  tvSceneBeat,
  tvCommercial,
  musicListenSway,
  musicTrackChange,
  jamSolo,
  jamJoin,
  mealServe,
  mealBite,
  cookingHandOff,
  pause,
  resume,
}

class ActivityBeatScheduler {
  ActivityBeatScheduler({
    required this.activityKind,
    required this.participantIds,
  });

  final String activityKind;
  final List<String> participantIds;
  double _nextAt = 0;
  int _salt = 0;
  String? currentLeader;
  bool paused = false;

  ActivityMicrobeat? tick(double now) {
    if (paused) return null;
    if (now < _nextAt) return null;
    _salt++;
    _nextAt = now + HabitatRng.range(1.2, 3.5, a: activityKind, b: _salt);
    return switch (activityKind) {
      'boardgame' => [
          ActivityMicrobeat.boardgameRoll,
          ActivityMicrobeat.boardgameReact,
          ActivityMicrobeat.boardgamePassTurn,
        ][_salt % 3],
      'tv' || 'movie' => _salt.isEven
          ? ActivityMicrobeat.tvSceneBeat
          : ActivityMicrobeat.tvCommercial,
      'listenMusic' => _salt.isEven
          ? ActivityMicrobeat.musicListenSway
          : ActivityMicrobeat.musicTrackChange,
      'jam' => _salt.isEven
          ? ActivityMicrobeat.jamSolo
          : ActivityMicrobeat.jamJoin,
      'meal' => _salt.isEven
          ? ActivityMicrobeat.mealServe
          : ActivityMicrobeat.mealBite,
      'cooking' => ActivityMicrobeat.cookingHandOff,
      _ => ActivityMicrobeat.pause,
    };
  }

  void pause() => paused = true;
  void resume(double now) {
    paused = false;
    _nextAt = now + 0.4;
  }

  void rotateJamLeader() {
    if (participantIds.isEmpty) return;
    final i = participantIds.indexOf(currentLeader ?? '');
    currentLeader =
        participantIds[(i + 1).clamp(0, participantIds.length - 1) %
            participantIds.length];
  }
}

class ActivityMigrationPlan {
  const ActivityMigrationPlan({
    required this.fromSite,
    required this.toSite,
    required this.reason,
  });

  final String fromSite;
  final String toSite;
  final String reason;
}

abstract final class ActivityMigration {
  static ActivityMigrationPlan? maybeMigrate({
    required String currentSite,
    required double crowding,
    required double comfort,
    required List<String> altSites,
  }) {
    if (altSites.isEmpty) return null;
    if (crowding < 1.8 && comfort > 0.35) return null;
    return ActivityMigrationPlan(
      fromSite: currentSite,
      toSite: altSites.first,
      reason: crowding >= 1.8 ? 'crowding' : 'comfort',
    );
  }
}

abstract final class SpectatorBehavior {
  static bool canSpectate({
    required double interest,
    required double socialTolerance,
    required bool hasSpace,
  }) =>
      interest > 0.35 && socialTolerance > 0.25 && hasSpace;

  static (int, int)? edgeSlot({
    required (int, int) activityCenter,
    required bool Function(int x, int y) isWalkable,
  }) {
    for (final c in [
      (activityCenter.$1 + 2, activityCenter.$2),
      (activityCenter.$1 - 2, activityCenter.$2),
      (activityCenter.$1, activityCenter.$2 + 2),
    ]) {
      if (isWalkable(c.$1, c.$2)) return c;
    }
    return null;
  }
}

abstract final class GroupDispersion {
  static List<(String, (int, int))> disperse({
    required List<String> pawnIds,
    required (int, int) center,
    required bool Function(int x, int y) isWalkable,
  }) {
    final deltas = [
      (2, 0),
      (-2, 0),
      (0, 2),
      (0, -2),
      (2, 2),
      (-2, 2),
    ];
    final out = <(String, (int, int))>[];
    for (var i = 0; i < pawnIds.length; i++) {
      final d = deltas[i % deltas.length];
      final cell = (center.$1 + d.$1, center.$2 + d.$2);
      out.add((
        pawnIds[i],
        isWalkable(cell.$1, cell.$2) ? cell : center,
      ));
    }
    return out;
  }
}

class TableEtiquette {
  static bool mayReach({
    required String pawnId,
    required String itemId,
    required Set<String> claimedItems,
  }) =>
      !claimedItems.contains(itemId);

  static void claim(Set<String> claimed, String itemId) => claimed.add(itemId);
  static void release(Set<String> claimed, String itemId) =>
      claimed.remove(itemId);
}

class CookingHandoff {
  CookingHandoff({
    required this.fromPawnId,
    required this.toPawnId,
    required this.taskId,
  });

  final String fromPawnId;
  final String toPawnId;
  final String taskId;
  bool completed = false;

  void complete() => completed = true;
}
