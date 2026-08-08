import 'dart:ui';

/// Cosmetic day/night tint driven by the device local clock (V9.5+).
///
/// No agenda linkage — [phase] and [overlayColor] follow wall-clock time.
///
/// Periods (local hour, half-open `[start, end)`):
/// - Madrugada 00–05 · Amanhecer 05–07 · Dia 07–17 · Entardecer 17–18 · Noite 18–00
class HabitatPresence {
  HabitatPresence({DateTime Function()? now}) : _now = now ?? DateTime.now {
    syncFromClock();
  }

  final DateTime Function() _now;

  /// 0 = midnight, 0.5 = noon (fraction of local day).
  double phase = 0;

  /// Sounds off by default (spec V9.5).
  bool muted = true;

  /// Refresh [phase] from local wall clock.
  void syncFromClock([DateTime? at]) {
    final t = at ?? _now();
    final secs =
        t.hour * 3600 + t.minute * 60 + t.second + t.millisecond / 1000;
    phase = (secs / 86400.0) % 1.0;
  }

  /// Called each frame — keeps tint aligned with real time.
  void tick(double dt) {
    syncFromClock();
  }

  String get phaseLabel {
    final h = phase * 24;
    if (h < 5) return 'Madrugada';
    if (h < 7) return 'Amanhecer';
    if (h < 17) return 'Dia';
    if (h < 18) return 'Entardecer';
    return 'Noite';
  }

  /// Soft multiply-style overlay — continuous with the local hour.
  Color get overlayColor => overlayColorForPhase(phase);

  /// Piecewise-linear tint between period keyframes (hour → color, alpha).
  static Color overlayColorForPhase(double phase) {
    final hour = (phase % 1.0) * 24.0;
    const keys = <(double, Color, double)>[
      (0.0, Color(0xFF152038), 0.50), // madrugada start
      (2.5, Color(0xFF121C30), 0.52), // mid-madrugada
      (5.0, Color(0xFF1A2740), 0.46), // → amanhecer
      (6.0, Color(0xFFFF9A6A), 0.28), // amanhecer
      (7.0, Color(0xFFFFD0A8), 0.12), // → dia
      (12.0, Color(0xFFFFF8E8), 0.03), // meio-dia
      (16.0, Color(0xFFFFE8C8), 0.06), // fim de dia
      (17.0, Color(0xFFFFB070), 0.18), // → entardecer
      (17.5, Color(0xFFFF7A4A), 0.30), // entardecer
      (18.0, Color(0xFF2A3A58), 0.38), // → noite
      (21.0, Color(0xFF1A2740), 0.46), // noite
      (24.0, Color(0xFF152038), 0.50), // → madrugada
    ];

    for (var i = 0; i < keys.length - 1; i++) {
      final (h0, c0, a0) = keys[i];
      final (h1, c1, a1) = keys[i + 1];
      if (hour >= h0 && hour <= h1) {
        final t = h1 == h0 ? 0.0 : (hour - h0) / (h1 - h0);
        return Color.lerp(c0, c1, t)!.withValues(alpha: _lerp(a0, a1, t));
      }
    }
    final last = keys.last;
    return last.$2.withValues(alpha: last.$3);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  int _stubPlays = 0;
  int get stubPlayCount => _stubPlays;

  /// No asset pipeline — just count when unmuted.
  void playStub(String kind) {
    if (muted) return;
    _stubPlays++;
  }
}
