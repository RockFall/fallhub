import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../chrome/colony_button.dart';
import '../chrome/colony_frame.dart';
import '../chrome/colony_pixel_icon.dart';
import '../tokens/colony_tokens.dart';
import 'colony_agenda_rail_layout.dart';

export 'colony_agenda_rail_layout.dart';

/// Compact day agenda: proportional first→last hour scale + cyan rail + NOW.
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
    this.onAction,
    this.actionIcon = 'plug',
    this.actionSemanticLabel,
    this.emptyHint,
    this.emptyActionLabel,
    this.onEmptyAction,
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
  final VoidCallback? onAction;
  final String? actionIcon;
  final String? actionSemanticLabel;
  final String? emptyHint;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final double maxHeight;

  static const hours = [0, 4, 8, 12, 16, 20, 24];

  @override
  Widget build(BuildContext context) {
    return ColonyFrame(
      variant: ColonyFrameVariant.panel,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onHeaderTap,
                  child: Text(
                    title.toUpperCase(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: ColonyColors.textGold,
                      letterSpacing: 1.15,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (onAction != null)
                Semantics(
                  button: true,
                  label: actionSemanticLabel,
                  child: InkWell(
                    onTap: onAction,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: ColonyPixelIcon(
                        actionIcon ?? 'plug',
                        size: 16,
                        mono: true,
                        color: ColonyColors.textGold,
                      ),
                    ),
                  ),
                )
              else if (headerIcon != null)
                ColonyPixelIcon(
                  headerIcon!,
                  size: 16,
                  mono: true,
                  color: ColonyColors.textMuted,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (blocks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Text(
                    emptyLabel ?? '—',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColonyColors.textMuted,
                    ),
                  ),
                  if (emptyHint != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      emptyHint!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColonyColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (onEmptyAction != null && emptyActionLabel != null) ...[
                    const SizedBox(height: 12),
                    ColonyButton(
                      onPressed: onEmptyAction,
                      child: Text(emptyActionLabel!.toUpperCase()),
                    ),
                  ],
                ],
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

  @override
  Widget build(BuildContext context) {
    final layout = layoutColonyAgendaRail(
      blocks: blocks,
      day: day,
      canvasHeight: maxHeight,
      now: now,
    );
    final nowLocal = now?.toLocal();
    final isToday =
        nowLocal != null &&
        nowLocal.year == day.year &&
        nowLocal.month == day.month &&
        nowLocal.day == day.day;
    final nowHour = isToday
        ? nowLocal.hour + nowLocal.minute / 60.0 + nowLocal.second / 3600.0
        : null;
    final nowInWindow =
        nowHour != null &&
        nowHour >= layout.viewStartHour - 0.01 &&
        nowHour <= layout.viewEndHour + 0.01;
    final nowY = nowHour == null || !nowInWindow ? null : layout.yAt(nowHour);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (layout.allDay.isNotEmpty) ...[
          _AllDayStrip(blocks: layout.allDay),
          const SizedBox(height: 8),
        ],
        if (layout.timed.isNotEmpty)
          SizedBox(
            height: layout.canvasHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: _railWidth,
                      child: CustomPaint(
                        painter: _RailPainter(
                          hours: layout.hourTicks,
                          yAt: layout.yAt,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          return Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              for (final placed in layout.timed)
                                Positioned(
                                  key: ValueKey(
                                    'agenda-block-${placed.block.id}',
                                  ),
                                  top: placed.top,
                                  left:
                                      placed.lane * (width / placed.laneCount),
                                  width: width / placed.laneCount,
                                  height: placed.height,
                                  child: _BlockCard(block: placed.block),
                                ),
                            ],
                          );
                        },
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
      ],
    );
  }
}

class _AllDayStrip extends StatelessWidget {
  const _AllDayStrip({required this.blocks});

  final List<ColonyAgendaBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final block in blocks)
          KeyedSubtree(
            key: ValueKey('agenda-allday-${block.id}'),
            child: _AllDayChip(block: block),
          ),
      ],
    );
  }
}

class _AllDayChip extends StatelessWidget {
  const _AllDayChip({required this.block});

  final ColonyAgendaBlock block;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: ColonyFrame(
        variant: ColonyFrameVariant.block,
        fill: block.color,
        grain: false,
        onTap: block.onTap,
        padding: const EdgeInsets.fromLTRB(5, 4, 8, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (block.iconName != null) ...[
              _AgendaIconMark(name: block.iconName!, size: 16, well: 22),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                block.title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: ColonyColors.textPrimary,
                  fontSize: 11,
                  letterSpacing: 0.6,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({required this.hours, required this.yAt});

  final List<int> hours;
  final double Function(double hour) yAt;

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
      final y = yAt(h.toDouble()).clamp(4.0, size.height - 4.0);
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
    final stripe = Color.lerp(block.color, const Color(0xFFE8E0D4), 0.38);
    final fill = Color.lerp(block.color, const Color(0xFF3A4048), 0.12);
    return Padding(
      padding: const EdgeInsets.only(right: 2, bottom: 3),
      child: ColonyFrame(
        variant: ColonyFrameVariant.block,
        fill: fill,
        grain: false,
        onTap: block.onTap,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Container(width: 4, color: stripe),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
                child: Row(
                  children: [
                    if (block.iconName != null) ...[
                      _AgendaIconMark(name: block.iconName!),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              block.title.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: ColonyColors.textPrimary,
                                    fontSize: 12,
                                    letterSpacing: 0.8,
                                    height: 1.0,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              block.timeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: ColonyColors.textMuted,
                                    fontSize: 9,
                                    letterSpacing: 0.2,
                                    height: 1.0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (block.warning) ...[
                      const SizedBox(width: 4),
                      const ColonyPixelIcon('warning', size: 14),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaIconMark extends StatelessWidget {
  const _AgendaIconMark({required this.name, this.size = 20, this.well = 26});

  final String name;
  final double size;
  final double well;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: well,
      height: well,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xCC080A0E),
        borderRadius: BorderRadius.circular(3),
        border: const Border(
          top: BorderSide(color: Color(0x99000000)),
          left: BorderSide(color: Color(0x99000000)),
          bottom: BorderSide(color: Color(0x55C8C4B8)),
          right: BorderSide(color: Color(0x33C8C4B8)),
        ),
      ),
      child: ColonyPixelIcon(name, size: size),
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
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: railWidth - 13,
            top: 9,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColonyColors.textGoldHi,
                boxShadow: [
                  BoxShadow(
                    color: ColonyColors.textGoldHi.withValues(alpha: 0.55),
                    blurRadius: 7,
                  ),
                ],
              ),
            ),
          ),
          Row(
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
