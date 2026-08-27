/// Block J — camera, UI and diegetic readability (MD 10 R104–R111).
library;

class AffordanceTooltip {
  const AffordanceTooltip({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;
}

abstract final class AffordanceTooltips {
  static AffordanceTooltip? forKind(String kind) {
    final k = kind.toLowerCase();
    if (k.contains('chair') || k.contains('sofa')) {
      return const AffordanceTooltip(title: 'Sentar', detail: 'Descanso leve');
    }
    if (k.contains('bed')) {
      return const AffordanceTooltip(title: 'Dormir', detail: 'Recuperar sono');
    }
    if (k.contains('tv')) {
      return const AffordanceTooltip(title: 'Assistir', detail: 'Lazer passivo');
    }
    return AffordanceTooltip(title: kind, detail: 'Usar');
  }
}

class UnavailableReason {
  const UnavailableReason({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

abstract final class ActionAvailability {
  static UnavailableReason? whyNot({
    required bool drafted,
    required bool occupied,
    required bool blockedPath,
    required bool needCapacity,
  }) {
    if (occupied) {
      return const UnavailableReason(
        code: 'occupied',
        message: 'Alguém já está usando.',
      );
    }
    if (blockedPath) {
      return const UnavailableReason(
        code: 'path',
        message: 'Sem caminho livre.',
      );
    }
    if (needCapacity) {
      return const UnavailableReason(
        code: 'capacity',
        message: 'Energia social baixa.',
      );
    }
    return null;
  }
}

class CameraFocusRequest {
  const CameraFocusRequest({
    required this.targetCell,
    required this.duration,
    this.priority = 0,
  });

  final (int, int) targetCell;
  final double duration;
  final double priority;
}

class CameraFocusController {
  CameraFocusRequest? _active;
  double _endsAt = 0;

  void request(CameraFocusRequest r, double now) {
    if (_active != null &&
        now < _endsAt &&
        r.priority < (_active!.priority)) {
      return;
    }
    _active = r;
    _endsAt = now + r.duration;
  }

  CameraFocusRequest? tick(double now) {
    if (_active == null) return null;
    if (now >= _endsAt) {
      _active = null;
      return null;
    }
    return _active;
  }
}

enum ObserverMode { normal, observer, cinematic }

class ObserverCinematicController {
  ObserverMode mode = ObserverMode.normal;
  double cinematicT = 0;

  void enterObserver() => mode = ObserverMode.observer;
  void enterCinematic() {
    mode = ObserverMode.cinematic;
    cinematicT = 0;
  }

  void exit() => mode = ObserverMode.normal;

  void tick(double dt) {
    if (mode == ObserverMode.cinematic) cinematicT += dt;
  }

  bool get hideChrome =>
      mode == ObserverMode.observer || mode == ObserverMode.cinematic;
}

class EventFocusHint {
  const EventFocusHint({
    required this.cell,
    required this.strength,
    required this.label,
  });

  final (int, int) cell;
  final double strength;
  final String label;
}

abstract final class EventFocusHints {
  /// Soft hint — does not steal camera.
  static EventFocusHint? forEvent({
    required (int, int)? cell,
    required String label,
    required double salience,
  }) {
    if (cell == null || salience < 0.4) return null;
    return EventFocusHint(
      cell: cell,
      strength: salience.clamp(0.0, 1.0),
      label: label,
    );
  }
}

class BubblePacingState {
  BubblePacingState();

  double lastSpeechAt = -999;
  double minGap = 1.1;

  bool maySpeak(double now) => now - lastSpeechAt >= minGap;

  void markSpoken(double now) => lastSpeechAt = now;
}

enum ThoughtMoteGrammar { ellipsis, spark, yawn, heart, alert }

abstract final class MoteThoughtGrammar {
  static ThoughtMoteGrammar fromTag(String? tag) => switch (tag) {
        'yawn' || 'sleepy' || 'groggy' => ThoughtMoteGrammar.yawn,
        'spark' || 'inspired' => ThoughtMoteGrammar.spark,
        'heart' || 'social' => ThoughtMoteGrammar.heart,
        'alert' || 'danger' => ThoughtMoteGrammar.alert,
        _ => ThoughtMoteGrammar.ellipsis,
      };

  static String glyph(ThoughtMoteGrammar g) => switch (g) {
        ThoughtMoteGrammar.ellipsis => '…',
        ThoughtMoteGrammar.spark => '*',
        ThoughtMoteGrammar.yawn => '~',
        ThoughtMoteGrammar.heart => '♡',
        ThoughtMoteGrammar.alert => '!',
      };
}

enum DebugHudPreset { off, minimal, navigation, social, full }

abstract final class DebugHudPresets {
  static Set<String> panels(DebugHudPreset p) => switch (p) {
        DebugHudPreset.off => {},
        DebugHudPreset.minimal => {'clock', 'job'},
        DebugHudPreset.navigation => {'clock', 'job', 'path', 'slot', 'door'},
        DebugHudPreset.social => {'clock', 'job', 'attention', 'topic', 'turn'},
        DebugHudPreset.full => {
            'clock',
            'job',
            'path',
            'slot',
            'door',
            'attention',
            'topic',
            'turn',
            'needs',
            'objects',
          },
      };
}
