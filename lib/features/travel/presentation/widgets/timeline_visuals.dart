import 'dart:math' as math;

import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';

abstract final class TimelineVisuals {
  static IconData categoryIcon(TimelinePlaceCategory category) =>
      switch (category) {
        TimelinePlaceCategory.home => Icons.home_outlined,
        TimelinePlaceCategory.work => Icons.work_outline,
        TimelinePlaceCategory.gastronomy => Icons.restaurant_outlined,
        TimelinePlaceCategory.shopping => Icons.shopping_bag_outlined,
        TimelinePlaceCategory.hotels => Icons.hotel_outlined,
        TimelinePlaceCategory.culture => Icons.museum_outlined,
        TimelinePlaceCategory.attractions => Icons.landscape_outlined,
        TimelinePlaceCategory.airports => Icons.flight_outlined,
        TimelinePlaceCategory.transit => Icons.directions_transit_outlined,
        TimelinePlaceCategory.other => Icons.place_outlined,
      };

  static Color categoryColor(TimelinePlaceCategory category) =>
      switch (category) {
        TimelinePlaceCategory.home => ColonyColors.statusGood,
        TimelinePlaceCategory.work => ColonyColors.scheduleWork,
        TimelinePlaceCategory.gastronomy => ColonyColors.accentOrange,
        TimelinePlaceCategory.shopping => const Color(0xFFE08BB8),
        TimelinePlaceCategory.hotels => ColonyColors.accentViolet,
        TimelinePlaceCategory.culture => ColonyColors.accentCyan,
        TimelinePlaceCategory.attractions => ColonyColors.accentMoss,
        TimelinePlaceCategory.airports => ColonyColors.statusInfo,
        TimelinePlaceCategory.transit => ColonyColors.statusUnknown,
        TimelinePlaceCategory.other => ColonyColors.textMuted,
      };

  static Color modeColor(String id) => switch (id) {
        'walking' => ColonyColors.accentMoss,
        'driving' => ColonyColors.accentOrange,
        'transit' => ColonyColors.statusInfo,
        'flying' => ColonyColors.accentCyan,
        'cycling' => ColonyColors.statusGood,
        _ => ColonyColors.textMuted,
      };

  static IconData modeIcon(String id) => switch (id) {
        'walking' => Icons.directions_walk,
        'driving' => Icons.directions_car_outlined,
        'transit' => Icons.directions_bus_outlined,
        'flying' => Icons.flight_outlined,
        'cycling' => Icons.directions_bike_outlined,
        _ => Icons.alt_route,
      };

  static String flagEmoji(String countryCode) {
    final code = countryCode.toUpperCase();
    if (code.length != 2) return '🌍';
    return String.fromCharCodes([
      for (final unit in code.codeUnits) 0x1F1E6 - 65 + unit,
    ]);
  }

  static String clockRange(DateTime start, DateTime end) {
    String hhmm(DateTime t) {
      final l = t.toLocal();
      return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    }

    return '${hhmm(start)}–${hhmm(end)}';
  }

  static String dayLabel(DateTime day) {
    final l = day.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}';
  }

  static ConfidenceDisplay confidenceOf(double? p) {
    if (p == null) return ConfidenceDisplay.insufficient;
    if (p >= 0.8) return ConfidenceDisplay.high;
    if (p >= 0.5) return ConfidenceDisplay.medium;
    if (p >= 0.2) return ConfidenceDisplay.low;
    return ConfidenceDisplay.insufficient;
  }
}

class TimelineSparkline extends StatelessWidget {
  const TimelineSparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 36,
  });

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(values: values, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final max = values.reduce(math.max);
    if (max <= 0) {
      final axis = Paint()
        ..color = ColonyColors.borderDark
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(0, size.height - 1),
        Offset(size.width, size.height - 1),
        axis,
      );
      return;
    }
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.02)],
      ).createShader(Offset.zero & size);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final fillPath = Path()..moveTo(0, size.height);
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * (i / (values.length - 1));
      final y = size.height - (values[i] / max) * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      fillPath.lineTo(x, y);
    }
    fillPath
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class TimelineHeatmap extends StatelessWidget {
  const TimelineHeatmap({super.key, required this.minutes});

  final List<int> minutes;

  @override
  Widget build(BuildContext context) {
    final max = minutes.isEmpty ? 1 : minutes.reduce(math.max).clamp(1, 1 << 30);
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 28),
            for (var h = 0; h < 24; h++)
              if (h % 3 == 0)
                Expanded(
                  flex: 3,
                  child: Text(
                    '$h',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ColonyColors.textMuted,
                          fontSize: 9,
                        ),
                  ),
                )
              else
                const Expanded(child: SizedBox.shrink()),
          ],
        ),
        const SizedBox(height: 4),
        for (var d = 0; d < 7; d++)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    AppStrings.timelineWeekdayShort(d),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ColonyColors.textMuted,
                          fontSize: 10,
                        ),
                  ),
                ),
                for (var h = 0; h < 24; h++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.6),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              ColonyColors.panel,
                              ColonyColors.accentCyan,
                              (minutes[d * 24 + h] / max).clamp(0.0, 1.0),
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class TimelineStatTile extends StatelessWidget {
  const TimelineStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.spark,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final List<double>? spark;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? ColonyColors.accentCyan;
    return ColonySurface(
      child: Padding(
        padding: const EdgeInsets.all(ColonySpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: accent),
                  const SizedBox(width: ColonySpacing.sm),
                ],
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ColonyColors.textMuted,
                          letterSpacing: 0.6,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ColonySpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ColonyColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (spark != null) ...[
              const SizedBox(height: ColonySpacing.sm),
              TimelineSparkline(values: spark!, color: accent),
            ],
          ],
        ),
      ),
    );
  }
}

class TimelineCategoryCard extends StatelessWidget {
  const TimelineCategoryCard({
    super.key,
    required this.category,
    required this.count,
    required this.hours,
    this.onTap,
  });

  final TimelinePlaceCategory category;
  final int count;
  final Duration hours;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = TimelineVisuals.categoryColor(category);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: ColonyColors.panel,
            border: Border.all(color: ColonyColors.borderDark),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.22),
                ColonyColors.panel,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(ColonySpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(TimelineVisuals.categoryIcon(category), color: color),
                const SizedBox(height: ColonySpacing.sm),
                Text(
                  AppStrings.timelineCategoryLabel(category),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: ColonySpacing.xs),
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: ColonyColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  '${AppStrings.timelineDurationHours(hours)} · $count ${AppStrings.timelinePlacesInCategory}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColonyColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
