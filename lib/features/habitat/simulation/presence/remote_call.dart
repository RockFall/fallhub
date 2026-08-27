import '../mirror/mirror_signal.dart';
import '../time/habitat_episode.dart';

enum RemoteCallMode { voiceCall, videoCall, textConversation }

enum RemoteCallPhase {
  ringing,
  active,
  ending,
  ended,
  declined,
  interrupted,
}

/// Remote participant without a Flame pawn (MD 08 M20).
class RemoteParticipantState {
  const RemoteParticipantState({
    required this.pawnId,
    required this.displayName,
    this.mode = RemoteCallMode.voiceCall,
  });

  final String pawnId;
  final String displayName;
  final RemoteCallMode mode;
}

class HabitatRemoteCall {
  HabitatRemoteCall({
    required this.id,
    required this.localPawnId,
    required this.remote,
    required this.startedAt,
    this.phase = RemoteCallPhase.ringing,
    this.source = MirrorSignalSource.manual,
  });

  final String id;
  final String localPawnId;
  final RemoteParticipantState remote;
  final double startedAt;
  RemoteCallPhase phase;
  final MirrorSignalSource source;
  double? endedAt;
}

/// Simulates voice calls without spawning the remote pawn (M20).
class RemoteCallDirector {
  RemoteCallDirector({required this.episodes});

  final HabitatEpisodeLedger episodes;
  HabitatRemoteCall? active;
  final List<String> debugLog = [];

  /// Social deltas applied to local pawn while on call (per second).
  static const socialConnectionPerSec = 0.012;
  static const socialToleranceDrainPerSec = 0.008;

  HabitatRemoteCall startVoiceCall({
    required String localPawnId,
    required String remotePawnId,
    required String remoteName,
    required double nowSim,
    MirrorSignalSource source = MirrorSignalSource.manual,
  }) {
    endActive(nowSim, interrupted: active != null);
    final call = HabitatRemoteCall(
      id: 'call-$nowSim',
      localPawnId: localPawnId,
      remote: RemoteParticipantState(
        pawnId: remotePawnId,
        displayName: remoteName,
        mode: RemoteCallMode.voiceCall,
      ),
      startedAt: nowSim,
      source: source,
    );
    active = call;
    episodes.start(
      id: call.id,
      kind: 'remoteCall',
      atSimSeconds: nowSim,
      data: {
        'local': localPawnId,
        'remote': remotePawnId,
        'mode': 'voiceCall',
        'source': source.name,
      },
    );
    debugLog.add('[${nowSim.toStringAsFixed(0)}s] ringing $remoteName');
    return call;
  }

  void answer(double nowSim) {
    final c = active;
    if (c == null || c.phase != RemoteCallPhase.ringing) return;
    c.phase = RemoteCallPhase.active;
    debugLog.add('[${nowSim.toStringAsFixed(0)}s] active with ${c.remote.displayName}');
  }

  void endActive(double nowSim, {bool interrupted = false}) {
    final c = active;
    if (c == null) return;
    c.phase = interrupted
        ? RemoteCallPhase.interrupted
        : RemoteCallPhase.ended;
    c.endedAt = nowSim;
    episodes.end(c.id, nowSim);
    debugLog.add(
      '[${nowSim.toStringAsFixed(0)}s] ${c.phase.name} ${c.remote.displayName}',
    );
    active = null;
  }

  /// Auto-answer after ring, auto-end after [maxDuration].
  void tick(double nowSim, {double maxDuration = 90}) {
    final c = active;
    if (c == null) return;
    if (c.phase == RemoteCallPhase.ringing && nowSim >= c.startedAt + 2) {
      answer(nowSim);
    }
    if (c.phase == RemoteCallPhase.active &&
        nowSim >= c.startedAt + maxDuration) {
      c.phase = RemoteCallPhase.ending;
      endActive(nowSim);
    }
  }

  bool get isOnCall =>
      active != null &&
      (active!.phase == RemoteCallPhase.active ||
          active!.phase == RemoteCallPhase.ringing);
}
