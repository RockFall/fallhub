import 'habitat_appointment.dart';

enum PlannedActivityPhase {
  arrival,
  warmup,
  primary,
  freeSocial,
  winddown,
  departure,
  done,
}

/// Thin request bridging appointment → existing affordances (MD 08 M21).
class PlannedActivityRequest {
  const PlannedActivityRequest({
    required this.kind,
    required this.primaryAffordance,
    this.fallbackAffordances = const [],
    this.minParticipants = 1,
    this.warmupAffordance,
  });

  final String kind;
  final String primaryAffordance;
  final List<String> fallbackAffordances;
  final int minParticipants;
  final String? warmupAffordance;
}

class PlannedActivityRuntime {
  PlannedActivityRuntime({
    required this.appointmentId,
    required this.request,
    this.phase = PlannedActivityPhase.arrival,
    this.resolvedAffordance,
    this.primaryUnavailable = false,
  });

  final String appointmentId;
  final PlannedActivityRequest request;
  PlannedActivityPhase phase;
  String? resolvedAffordance;
  bool primaryUnavailable;
}

/// Composes appointments into generic activities — no cutscenes (M21).
class PlannedActivityComposer {
  final Map<String, PlannedActivityRuntime> byAppointment = {};

  static PlannedActivityRequest forAppointment(HabitatAppointment appt) {
    return switch (appt.activityKind) {
      'dinner' => const PlannedActivityRequest(
          kind: 'sharedMeal',
          primaryAffordance: 'goToTable',
          fallbackAffordances: ['sit', 'socialChat'],
          minParticipants: 2,
          warmupAffordance: 'goToTable',
        ),
      'gameNight' => const PlannedActivityRequest(
          kind: 'boardgame',
          primaryAffordance: 'recreate',
          fallbackAffordances: ['socialChat', 'sit'],
          minParticipants: 2,
        ),
      'hangout' => const PlannedActivityRequest(
          kind: 'hangout',
          primaryAffordance: 'socialChat',
          fallbackAffordances: ['sit', 'listenMusic'],
          minParticipants: 2,
        ),
      'movie' => const PlannedActivityRequest(
          kind: 'watchTogether',
          primaryAffordance: 'watchTv',
          fallbackAffordances: ['sit', 'socialChat'],
          minParticipants: 1,
        ),
      _ => PlannedActivityRequest(
          kind: appt.activityKind,
          primaryAffordance: 'socialChat',
          fallbackAffordances: const ['sit', 'wander'],
        ),
    };
  }

  PlannedActivityRuntime attach(
    HabitatAppointment appt, {
    required bool Function(String affordanceId) isAvailable,
  }) {
    final req = forAppointment(appt);
    var resolved = req.primaryAffordance;
    var unavailable = false;
    if (!isAvailable(req.primaryAffordance)) {
      unavailable = true;
      resolved = req.fallbackAffordances.firstWhere(
        isAvailable,
        orElse: () => 'socialChat',
      );
    }
    final rt = PlannedActivityRuntime(
      appointmentId: appt.id,
      request: req,
      resolvedAffordance: resolved,
      phase: PlannedActivityPhase.warmup,
      primaryUnavailable: unavailable,
    );
    byAppointment[appt.id] = rt;
    return rt;
  }

  void advancePhase(String appointmentId, PlannedActivityPhase phase) {
    final rt = byAppointment[appointmentId];
    if (rt == null) return;
    rt.phase = phase;
  }

  void complete(String appointmentId) {
    final rt = byAppointment[appointmentId];
    if (rt == null) return;
    rt.phase = PlannedActivityPhase.done;
  }

  /// High utility boost while appointment primary is active.
  double utilityBoost(String appointmentId) {
    final rt = byAppointment[appointmentId];
    if (rt == null) return 0;
    return switch (rt.phase) {
      PlannedActivityPhase.primary || PlannedActivityPhase.warmup => 0.45,
      PlannedActivityPhase.freeSocial => 0.25,
      PlannedActivityPhase.winddown => 0.1,
      _ => 0,
    };
  }
}
