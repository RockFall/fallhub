import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'package:flame/game.dart';

import '../../../app/localization/app_strings.dart';
import 'components/living_pawn_component.dart';
import 'components/pawn_job_controller.dart';
import 'habitat_room_stats.dart';

enum HabitatBubbleKind { speech, thought, mote }

class HabitatBubble {
  HabitatBubble({
    required this.pawn,
    required this.text,
    required this.kind,
    this.duration = 6.2,
    String? stackGroupId,
  }) : stackGroupId = stackGroupId ?? pawn.memberId;

  /// Speaker for this line (tip leans toward them in a shared stack).
  final LivingPawnComponent pawn;
  final String text;
  final HabitatBubbleKind kind;
  final double duration;

  /// Bubbles with the same id share one Habbo column (e.g. a conversation).
  final String stackGroupId;

  double age = 0;

  /// Logical stack index: 0 = newest (bottom), higher = older / higher.
  double stackSlot = 0;

  /// Animated slot that eases toward [stackSlot] (Habbo rise).
  double displaySlot = 0;

  /// Last measured bubble height in screen pixels (for spacing).
  double layoutHeight = 28;

  double get t => (age / duration).clamp(0.0, 1.0);
  bool get done => age >= duration;

  double get opacity {
    var o = 1.0;
    if (t < 0.08) {
      o = t / 0.08;
    } else if (t > 0.62) {
      o = (1 - t) / 0.38;
    }
    o *= (1.0 - stackSlot * 0.12).clamp(0.28, 1.0);
    return o.clamp(0.0, 1.0);
  }
}

/// Local phrase pools — no LLM (spec 07 V5).
abstract final class HabitatBubbleLines {
  static String forJobArrived(HabitatJobKind job, math.Random rng) =>
      switch (job) {
        HabitatJobKind.sleep => _pick(rng, AppStrings.habitatBubbleSleep),
        HabitatJobKind.sit => _pick(rng, AppStrings.habitatBubbleSit),
        HabitatJobKind.goToTable => _pick(rng, AppStrings.habitatBubbleTable),
        HabitatJobKind.goTo => _pick(rng, AppStrings.habitatBubbleArrived),
        HabitatJobKind.clean => _pick(rng, AppStrings.habitatBubbleClean),
        HabitatJobKind.recreate => _pick(rng, AppStrings.habitatBubbleRecreate),
        HabitatJobKind.wander => _pick(rng, AppStrings.habitatBubbleIdle),
      };

  static String forTap(math.Random rng) =>
      _pick(rng, AppStrings.habitatBubbleTap);

  static String forIdle(math.Random rng, {String? avoid}) {
    final roll = rng.nextDouble();
    if (roll < 0.50) return '…';
    if (roll < 0.82) {
      return _pickAvoid(rng, AppStrings.habitatBubbleIdleSoft, avoid);
    }
    return _pickAvoid(rng, AppStrings.habitatBubbleIdleRare, avoid);
  }

  static String? forRoomStats(HabitatRoomStats stats, math.Random rng) {
    if (stats.spaceTight && rng.nextDouble() < 0.28) {
      return _pick(rng, AppStrings.habitatBubbleRoomTight);
    }
    if (stats.beautyHigh && rng.nextDouble() < 0.22) {
      return _pick(rng, AppStrings.habitatBubbleRoomNice);
    }
    return null;
  }

  static String forArt(math.Random rng) =>
      _pick(rng, AppStrings.habitatBubbleArt);

  static String forTooDark(math.Random rng) =>
      AppStrings.habitatBubbleTooDark;

  static String _pick(math.Random rng, List<String> lines) =>
      lines[rng.nextInt(lines.length)];

  static String _pickAvoid(
    math.Random rng,
    List<String> lines,
    String? avoid,
  ) {
    if (lines.isEmpty) return '…';
    if (avoid == null || lines.length == 1) return _pick(rng, lines);
    final filtered = [for (final l in lines) if (l != avoid) l];
    if (filtered.isEmpty) return _pick(rng, lines);
    return _pick(rng, filtered);
  }
}

/// Stable conversation stack id for a pair of speakers.
String socialBubbleStackId(String aId, String bId) {
  if (aId.compareTo(bId) <= 0) return 'social:$aId|$bId';
  return 'social:$bId|$aId';
}

/// Draws speech/thought bubbles (Habbo-style stack, shared per conversation).
class BubbleLayerComponent extends Component with HasGameReference<FlameGame> {
  BubbleLayerComponent({required this.bubbles});

  final List<HabitatBubble> bubbles;

  /// Max visible bubbles per stack group (oldest drop off the top).
  static const int maxStackPerGroup = 6;

  @Deprecated('Use maxStackPerGroup')
  static const int maxStackPerPawn = maxStackPerGroup;

  static const double screenFontSize = 13;
  static const double screenMaxTextWidth = 168;
  static const double padX = 10;
  static const double padY = 5;
  static const double stackGap = 4;

  @override
  void update(double dt) {
    super.update(dt);
    final k = 1 - math.exp(-14 * dt);
    for (final b in bubbles) {
      b.displaySlot += (b.stackSlot - b.displaySlot) * k;
      if (b.t > 0.35) {
        b.displaySlot += dt * 0.35;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final ordered = bubbles.toList()
      ..sort((a, b) {
        final byGroup = a.stackGroupId.compareTo(b.stackGroupId);
        if (byGroup != 0) return byGroup;
        return b.displaySlot.compareTo(a.displaySlot);
      });
    for (final b in ordered) {
      _drawBubble(canvas, b);
    }
  }

  /// Midpoint of all speakers currently in this stack group.
  Offset _groupAnchor(HabitatBubble b, double invZoom) {
    final speakers = <LivingPawnComponent>{};
    for (final o in bubbles) {
      if (o.stackGroupId == b.stackGroupId) speakers.add(o.pawn);
    }
    if (speakers.isEmpty) speakers.add(b.pawn);

    var sx = 0.0;
    var sy = 0.0;
    for (final p in speakers) {
      sx += p.position.x;
      sy += p.visualTop;
    }
    final n = speakers.length;
    return Offset(sx / n, sy / n - 4 * invZoom);
  }

  void _drawBubble(Canvas canvas, HabitatBubble b) {
    final pawn = b.pawn;
    final zoom = game.camera.viewfinder.zoom.clamp(0.2, 4.0);
    final invZoom = 1.0 / zoom;
    final anchor = _groupAnchor(b, invZoom);

    final prefix = switch (b.kind) {
      HabitatBubbleKind.thought => '… ',
      HabitatBubbleKind.mote => '* ',
      HabitatBubbleKind.speech => '',
    };
    final label = '$prefix${b.text}';

    final style = TextStyle(
      color: Color.fromRGBO(16, 19, 22, b.opacity),
      fontSize: screenFontSize,
      fontWeight: FontWeight.w600,
      height: 1.15,
    );

    final measure = (ParagraphBuilder(ParagraphStyle())
          ..pushStyle(style)
          ..addText(label))
        .build()
      ..layout(const ParagraphConstraints(width: screenMaxTextWidth));
    final textW = measure.longestLine.clamp(28.0, screenMaxTextWidth);

    final paragraph = (ParagraphBuilder(
          ParagraphStyle(textAlign: TextAlign.center),
        )
          ..pushStyle(style)
          ..addText(label))
        .build()
      ..layout(ParagraphConstraints(width: textW));

    final w = textW + padX * 2;
    final h = paragraph.height + padY * 2;
    b.layoutHeight = h;

    final rise = _riseFor(b);
    final showTip = b.displaySlot < 0.55;
    // Tip leans toward the speaker when the stack is shared between two people.
    final tipDx =
        ((pawn.position.x - anchor.dx) / invZoom).clamp(-20.0, 20.0);

    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.scale(invZoom);

    final centerY = -rise - h / 2 - (showTip ? 6.0 : 2.0);
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, centerY),
        width: w,
        height: h,
      ),
      const Radius.circular(6),
    );

    final fillColor = _fillFor(b);
    final fill = Paint()..color = fillColor.withValues(alpha: b.opacity);
    final border = Paint()
      ..color = const Color(0xFF616C7A).withValues(alpha: b.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, border);

    if (showTip) {
      final tipBase = rect.bottom;
      final tip = Path()
        ..moveTo(tipDx - 6, tipBase - 1)
        ..lineTo(tipDx, tipBase + 8)
        ..lineTo(tipDx + 6, tipBase - 1)
        ..close();
      canvas.drawPath(tip, fill);
      canvas.drawPath(tip, border);
    }

    canvas.drawParagraph(
      paragraph,
      Offset(rect.left + padX, rect.top + padY),
    );
    canvas.restore();
  }

  /// Slight cream variants so two speakers in one stack stay distinguishable.
  Color _fillFor(HabitatBubble b) {
    if (b.kind == HabitatBubbleKind.mote) {
      return const Color(0xFFFFF3C4);
    }
    if (b.kind == HabitatBubbleKind.thought) {
      final cool = b.pawn.memberId.hashCode.isEven;
      return cool ? const Color(0xFFE8EEF5) : const Color(0xFFE9E8F2);
    }
    // Speech: parchment vs warmer cream — stable per speaker in the group.
    final speakers = <String>{
      for (final o in bubbles)
        if (o.stackGroupId == b.stackGroupId) o.pawn.memberId,
    }.toList()
      ..sort();
    final idx = speakers.indexOf(b.pawn.memberId);
    if (idx <= 0) return const Color(0xFFF2F0E6); // cool parchment
    return const Color(0xFFF8EDD6); // slightly warmer cream
  }

  double _riseFor(HabitatBubble b) {
    var rise = 0.0;
    final siblings = [
      for (final o in bubbles)
        if (o.stackGroupId == b.stackGroupId &&
            o.displaySlot < b.displaySlot - 0.01)
          o,
    ]..sort((a, c) => a.displaySlot.compareTo(c.displaySlot));

    var covered = 0.0;
    for (final s in siblings) {
      final nextBoundary = covered + 1;
      if (b.displaySlot >= nextBoundary) {
        rise += s.layoutHeight + stackGap;
        covered = nextBoundary;
      } else {
        break;
      }
    }
    final frac = (b.displaySlot - covered).clamp(0.0, 1.0);
    if (frac > 0) {
      rise += frac * (b.layoutHeight + stackGap);
    }
    return rise;
  }
}

/// Push a Habbo-style stacked bubble.
///
/// When [stackGroupId] is shared (e.g. a social encounter), all speakers
/// contribute to the **same** rising column.
void pushStackedBubble(
  List<HabitatBubble> bubbles,
  LivingPawnComponent target,
  String text, {
  HabitatBubbleKind kind = HabitatBubbleKind.speech,
  String? stackGroupId,
}) {
  final group = stackGroupId ?? target.memberId;
  for (final b in bubbles) {
    if (b.stackGroupId == group) {
      b.stackSlot += 1;
    }
  }
  bubbles.removeWhere(
    (b) =>
        b.stackGroupId == group &&
        b.stackSlot >= BubbleLayerComponent.maxStackPerGroup,
  );
  bubbles.add(
    HabitatBubble(
      pawn: target,
      text: text,
      kind: kind,
      stackGroupId: group,
    )..stackSlot = 0,
  );
}
