import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../chrome/colony_frame.dart';
import '../chrome/colony_pixel_icon.dart';
import '../tokens/colony_tokens.dart';

class ColonyAgendaBlock {
  const ColonyAgendaBlock({
    required this.id,
    required this.title,
    required this.timeLabel,
    required this.start,
    required this.end,
    required this.color,
    this.iconName,
    this.warning = false,
    this.onTap,
    this.visualOnly = false,
  });

  final String id;
  final String title;
  final String timeLabel;
  final DateTime start;
  final DateTime end;
  final Color color;
  final String? iconName;
  final bool warning;
  final VoidCallback? onTap;
  final bool visualOnly;
}

/// Compact 24h agenda: packed blocks + cyan rail + NOW hex.
class ColonyAgendaRail extends StatelessWidget {
  const ColonyAgendaRail({
    super.key,
    required this.blocks,
    required this.day,
    this.now,
    this.nowLabel = 'NOW',
    this.title = 'Agenda do dia',
    this.emptyLabel,
    this.headerIcon = 'calendar',
    this.onHeaderTap,
    this.maxHeight = 360,
  });

  final List<ColonyAgendaBlock> blocks;
  final DateTime day;
  final DateTime? now;
  final String nowLabel;
  final String title;
  final String? emptyLabel;
  final String? headerIcon;
  final VoidCallback? onHeaderTap;
  final double maxHeight;

  static const hours = [0, 4, 8, 12, 16, 20, 24];

  @override
  Widget build(BuildContext context) {
    return ColonyFrame(
      variant: ColonyFrameVariant.panel,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onHeaderTap,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: ColonyColors.textGold,
                      letterSpacing: 1.15,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (headerIcon != null)
                  ColonyPixelIcon(
                    headerIcon!,
                    size: 16,
                    mono: true,
                    color: ColonyColors.textMuted,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (blocks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                emptyLabel ?? '—',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: ColonyColors.textMuted),
              ),
            )
          else
            _AgendaBody(
              blocks: blocks,
              day: day,
              now: now,
              nowLabel: nowLabel,
              maxHeight: maxHeight,
            ),
        ],
      ),
    );
  }
}

class _Span {
  const _Span({
    required this.startHour,
    required this.endHour,
    required this.height,
    this.block,
  });

  final double startHour;
  final double endHour;
  final double height;
  final ColonyAgendaBlock? block;
}

class _AgendaBody extends StatelessWidget {
  const _AgendaBody({
    required this.blocks,
    required this.day,
    required this.now,
    required this.nowLabel,
    required this.maxHeight,
  });

  final List<ColonyAgendaBlock> blocks;
  final DateTime day;
  final DateTime? now;
  final String nowLabel;
  final double maxHeight;

  static const _railWidth = 44.0;

  List<_Span> _spans() {
    final sorted = [...blocks]..sort((a, b) => a.start.compareTo(b.start));
    final spans = <_Span>[];
    var cursor = 0.0;

    double hourOf(DateTime t) {
      final local = t.toLocal();
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      if (local.isBefore(dayStart)) return 0;
      if (!local.isBefore(dayEnd)) return 24;
      return local.hour + local.minute / 60.0;
    }

    double occH(double hours) =>
        (44.0 + (hours - 1).clamp(0, 8) * 6).clamp(42, 80).toDouble();
    double gapH(double hours) =>
        hours < 0.35 ? 6.0 : (hours * 9).clamp(20, 44).toDouble();

    for (final b in sorted) {
      final start = hourOf(b.start).clamp(0, 24).toDouble();
      final end = hourOf(b.end).clamp(0, 24).toDouble();
      if (end <= start) continue;
      if (start > cursor + 0.05) {
        spans.add(
          _Span(
            startHour: cursor,
            endHour: start,
            height: gapH(start - cursor),
          ),
        );
      }
      spans.add(
        _Span(
          startHour: start,
          endHour: end,
          height: occH(end - start),
          block: b,
        ),
      );
      cursor = end;
    }
    if (cursor < 23.9) {
      spans.add(
        _Span(startHour: cursor, endHour: 24, height: gapH(24 - cursor)),
      );
    }
    return spans;
  }

  double _yAt(List<_Span> spans, double hour) {
    var y = 0.0;
    for (final s in spans) {
      if (hour <= s.startHour) return y;
      if (hour >= s.endHour) {
        y += s.height;
        continue;
      }
      final t =
          (hour - s.startHour) /
          (s.endHour - s.startHour).clamp(0.001, 24).toDouble();
      return y + t * s.height;
    }
    return y;
  }

  @override
  Widget build(BuildContext context) {
    final spans = _spans();
    final totalH = spans.fold<double>(0, (s, e) => s + e.height);
    final nowLocal = now?.toLocal();
    final isToday =
        nowLocal != null &&
        nowLocal.year == day.year &&
        nowLocal.month == day.month &&
        nowLocal.day == day.day;
    final nowHour = isToday ? nowLocal.hour + nowLocal.minute / 60.0 : null;
    final nowY = nowHour == null ? null : _yAt(spans, nowHour);

    return SizedBox(
      height: math.min(totalH, maxHeight),
      child: SingleChildScrollView(
        child: SizedBox(
          height: totalH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _railWidth,
                    height: totalH,
                    child: CustomPaint(
                      painter: _RailPainter(
                        hours: ColonyAgendaRail.hours,
                        yAt: (h) => _yAt(spans, h.toDouble()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Stack(
                      children: [
                        for (final s in spans)
                          if (s.block != null)
                            Positioned(
                              top: _yAt(spans, s.startHour),
                              left: 0,
                              right: 0,
                              height: s.height,
                              child: _BlockCard(block: s.block!),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
              if (nowY != null)
                Positioned(
                  top: nowY - 14,
                  left: 0,
                  right: 0,
                  height: 28,
                  child: _NowOverlay(
                    label: nowLabel,
                    clock: nowLocal!,
                    railWidth: _railWidth,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({required this.hours, required this.yAt});

  final List<int> hours;
  final double Function(int hour) yAt;

  @override
  void paint(Canvas canvas, Size size) {
    final lineX = size.width - 8;
    canvas.drawLine(
      Offset(lineX, 4),
      Offset(lineX, size.height - 4),
      Paint()
        ..color = ColonyColors.accentCyan
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final h in hours) {
      final y = yAt(h).clamp(8, size.height - 8).toDouble();
      canvas.drawCircle(
        Offset(lineX, y),
        5.2,
        Paint()..color = const Color(0x445AD4EC),
      );
      canvas.drawCircle(
        Offset(lineX, y),
        3.1,
        Paint()..color = ColonyColors.accentCyan,
      );
      canvas.drawCircle(
        Offset(lineX - 1.1, y - 1.1),
        0.8,
        Paint()..color = const Color(0xCCE8FFFF),
      );
      tp.text = TextSpan(
        text: '${h.toString().padLeft(2, '0')}:00',
        style: const TextStyle(
          fontFamily: 'Pixelify Sans',
          fontSize: 8,
          height: 1,
          color: ColonyColors.textMuted,
        ),
      );
      tp.layout(maxWidth: lineX - 6);
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RailPainter oldDelegate) => true;
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({required this.block});

  final ColonyAgendaBlock block;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: ColonyFrame(
        variant: ColonyFrameVariant.block,
        fill: block.color,
        grain: false,
        onTap: block.onTap,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            if (block.iconName != null) ...[
              ColonyPixelIcon(block.iconName!, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    block.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: ColonyColors.textPrimary,
                      fontSize: 12,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    block.timeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ColonyColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            if (block.warning) const ColonyPixelIcon('warning', size: 14),
          ],
        ),
      ),
    );
  }
}

class _NowOverlay extends StatelessWidget {
  const _NowOverlay({
    required this.label,
    required this.clock,
    required this.railWidth,
  });

  final String label;
  final DateTime clock;
  final double railWidth;

  @override
  Widget build(BuildContext context) {
    final hh = clock.hour.toString().padLeft(2, '0');
    final mm = clock.minute.toString().padLeft(2, '0');
    return IgnorePointer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: railWidth - 10,
            child: CustomPaint(
              painter: _GoldDashPainter(),
              child: const SizedBox(height: 2, width: double.infinity),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                painter: _HexPainter(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Pixelify Sans',
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1408),
                      letterSpacing: 0.7,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '$hh:$mm',
                style: const TextStyle(
                  fontFamily: 'Pixelify Sans',
                  fontSize: 9,
                  color: ColonyColors.textGoldHi,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(width: 2),
          Expanded(
            child: CustomPaint(
              painter: _GoldDashPainter(),
              child: const SizedBox(height: 2, width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldDashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ColonyColors.textGoldHi
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.square;
    const dash = 4.0;
    const gap = 3.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, size.width), y),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path
      ..moveTo(5, 0)
      ..lineTo(w - 5, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w - 5, h)
      ..lineTo(5, h)
      ..lineTo(0, h / 2)
      ..close();
    canvas.drawPath(path, Paint()..color = ColonyColors.textGoldHi);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF5A3A10),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
