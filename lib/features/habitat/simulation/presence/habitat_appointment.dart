import '../mirror/mirror_signal.dart';
import '../time/habitat_episode.dart';
import 'presence_lifecycle.dart';

enum AppointmentPresenceMode { physical, remote, mixed }

enum AppointmentPhase {
  upcoming,
  preparing,
  due,
  active,
  ending,
  completed,
  cancelled,
}

/// Simulated future commitment (MD 08 M19).
class HabitatAppointment {
  const HabitatAppointment({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.participantPawnIds,
    required this.siteId,
    required this.activityKind,
    required this.presenceMode,
    required this.source,
    this.preparationWindow = 600,
    this.requiredTags = const {},
  });

  final String id;
  final String title;
  final double startsAt;
  final double endsAt;
  final Set<String> participantPawnIds;
  final String siteId;
  final String activityKind;
  final AppointmentPresenceMode presenceMode;
  final double preparationWindow;
  final Set<String> requiredTags;
  final MirrorSignalSource source;
}

class AppointmentRuntime {
  AppointmentRuntime({
    required this.appointment,
    this.phase = AppointmentPhase.upcoming,
  });

  final HabitatAppointment appointment;
  AppointmentPhase phase;
  bool preparationFired = false;
}

/// Drives appointment phases and intents — does not execute activities (M19).
class HabitatAppointmentDirector {
  HabitatAppointmentDirector({
    required this.episodes,
    this.presence,
  });

  final HabitatEpisodeLedger episodes;
  final VisitorLifecycleDirector? presence;
  final List<AppointmentRuntime> appointments = [];
  final List<String> debugTimeline = [];

  void schedule(HabitatAppointment appt) {
    appointments.add(AppointmentRuntime(appointment: appt));
    debugTimeline.add(
      '[${appt.startsAt.toStringAsFixed(0)}s] upcoming: ${appt.title} '
      '(${appt.source.name})',
    );
  }

  /// Demo helper — dinner in [delaySeconds].
  HabitatAppointment scheduleDemoDinner({
    required Set<String> participants,
    required double nowSim,
    double delaySeconds = 120,
    double durationSeconds = 180,
    String siteId = 'home',
  }) {
    final appt = HabitatAppointment(
      id: 'appt-dinner-$nowSim',
      title: 'Jantar',
      startsAt: nowSim + delaySeconds,
      endsAt: nowSim + delaySeconds + durationSeconds,
      participantPawnIds: participants,
      siteId: siteId,
      activityKind: 'dinner',
      presenceMode: AppointmentPresenceMode.physical,
      preparationWindow: 60,
      source: MirrorSignalSource.manual,
    );
    schedule(appt);
    // Visitors among participants arrive slightly before.
    final presence = this.presence;
    if (presence != null) {
      for (final id in participants) {
        final st = presence.status[id];
        if (st == null || st.role == PresenceRole.visitor) {
          presence.scheduleVisit(
            pawnId: id,
            arriveAtSim: appt.startsAt - 20,
            leaveAtSim: appt.endsAt + 30,
          );
        }
      }
    }
    return appt;
  }

  List<AppointmentIntent> tick(double simSeconds) {
    final intents = <AppointmentIntent>[];
    for (final rt in appointments) {
      final a = rt.appointment;
      if (rt.phase == AppointmentPhase.completed ||
          rt.phase == AppointmentPhase.cancelled) {
        continue;
      }

      final prepStart = a.startsAt - a.preparationWindow;
      if (rt.phase == AppointmentPhase.upcoming && simSeconds >= prepStart) {
        rt.phase = AppointmentPhase.preparing;
        rt.preparationFired = true;
        debugTimeline.add(
          '[${simSeconds.toStringAsFixed(0)}s] preparing: ${a.title}',
        );
        intents.add(
          AppointmentIntent.prepare(
            appointmentId: a.id,
            participantIds: a.participantPawnIds,
          ),
        );
      }

      if ((rt.phase == AppointmentPhase.preparing ||
              rt.phase == AppointmentPhase.upcoming) &&
          simSeconds >= a.startsAt) {
        rt.phase = AppointmentPhase.active;
        debugTimeline.add(
          '[${simSeconds.toStringAsFixed(0)}s] active: ${a.title}',
        );
        episodes.start(
          id: 'appt-${a.id}',
          kind: 'appointment',
          atSimSeconds: simSeconds,
          data: {
            'title': a.title,
            'activityKind': a.activityKind,
            'source': a.source.name,
          },
        );
        intents.add(
          AppointmentIntent.start(
            appointmentId: a.id,
            participantIds: a.participantPawnIds,
            activityKind: a.activityKind,
          ),
        );
      }

      if (rt.phase == AppointmentPhase.active &&
          simSeconds >= a.endsAt - 20 &&
          simSeconds < a.endsAt) {
        rt.phase = AppointmentPhase.ending;
        debugTimeline.add(
          '[${simSeconds.toStringAsFixed(0)}s] ending: ${a.title}',
        );
      }

      if ((rt.phase == AppointmentPhase.active ||
              rt.phase == AppointmentPhase.ending) &&
          simSeconds >= a.endsAt) {
        rt.phase = AppointmentPhase.completed;
        episodes.end('appt-${a.id}', simSeconds);
        debugTimeline.add(
          '[${simSeconds.toStringAsFixed(0)}s] completed: ${a.title}',
        );
        intents.add(
          AppointmentIntent.complete(
            appointmentId: a.id,
            participantIds: a.participantPawnIds,
          ),
        );
      }
    }
    return intents;
  }

  List<HabitatAppointment> upcoming(double now) => [
        for (final rt in appointments)
          if (rt.phase == AppointmentPhase.upcoming ||
              rt.phase == AppointmentPhase.preparing)
            rt.appointment,
      ];
}

enum AppointmentIntentKind { prepare, start, complete }

class AppointmentIntent {
  const AppointmentIntent({
    required this.kind,
    required this.appointmentId,
    required this.participantIds,
    this.activityKind,
  });

  final AppointmentIntentKind kind;
  final String appointmentId;
  final Set<String> participantIds;
  final String? activityKind;

  factory AppointmentIntent.prepare({
    required String appointmentId,
    required Set<String> participantIds,
  }) =>
      AppointmentIntent(
        kind: AppointmentIntentKind.prepare,
        appointmentId: appointmentId,
        participantIds: participantIds,
      );

  factory AppointmentIntent.start({
    required String appointmentId,
    required Set<String> participantIds,
    required String activityKind,
  }) =>
      AppointmentIntent(
        kind: AppointmentIntentKind.start,
        appointmentId: appointmentId,
        participantIds: participantIds,
        activityKind: activityKind,
      );

  factory AppointmentIntent.complete({
    required String appointmentId,
    required Set<String> participantIds,
  }) =>
      AppointmentIntent(
        kind: AppointmentIntentKind.complete,
        appointmentId: appointmentId,
        participantIds: participantIds,
      );
}
