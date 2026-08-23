import 'dart:math' as math;

import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import 'relations_assets.dart';

Color friendshipKindColor(FriendshipKind kind) => switch (kind) {
      FriendshipKind.innerCircle => const Color(0xFFE07A3D),
      FriendshipKind.close => ColonyMiniAppColors.friendships,
      FriendshipKind.regular => ColonyColors.accentMoss,
      FriendshipKind.casual => ColonyColors.statusInfo,
      FriendshipKind.acquaintance => ColonyColors.statusUnknown,
      FriendshipKind.childhood => const Color(0xFF7B5EA7),
      FriendshipKind.familyFriend => const Color(0xFFD45B6A),
      FriendshipKind.colleagueSocial => const Color(0xFF5A7A9A),
      FriendshipKind.neighbor => const Color(0xFF3D9AA8),
      FriendshipKind.online => const Color(0xFF2BB7C4),
      FriendshipKind.seasonal => const Color(0xFFD4A017),
      FriendshipKind.dormant => ColonyColors.textMuted,
      FriendshipKind.unspecified => ColonyColors.accentSand,
    };

Color friendshipAttentionColor(FriendshipAttention attention) =>
    switch (attention) {
      FriendshipAttention.overdue => ColonyColors.statusRisk,
      FriendshipAttention.dueSoon => ColonyColors.statusAttention,
      FriendshipAttention.onTrack => ColonyColors.statusGood,
      FriendshipAttention.noCadence => ColonyColors.statusInfo,
      FriendshipAttention.neverMet => ColonyColors.statusUnknown,
    };

Color personGlyphColor(String name) {
  const palette = [
    Color(0xFF5BA86A),
    Color(0xFFC4A35A),
    Color(0xFF4A90C8),
    Color(0xFF7B5EA7),
    Color(0xFFD45B6A),
    Color(0xFF3D9AA8),
    Color(0xFFE07A3D),
  ];
  final hash = name.toLowerCase().codeUnits.fold<int>(0, (a, b) => a + b);
  return palette[hash % palette.length];
}

String personInitials(Person person) {
  final source = (person.preferredName ?? person.displayName).trim();
  final parts = source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  final first = parts.first;
  final last = parts.length > 1 ? parts.last : '';
  final letters = (first[0] + (last.isEmpty ? '' : last[0])).toUpperCase();
  return letters;
}

class PersonGlyph extends StatelessWidget {
  const PersonGlyph({
    super.key,
    required this.person,
    this.attention,
    this.size = 44,
  });

  final Person person;
  final FriendshipAttention? attention;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fill = personGlyphColor(person.displayName);
    final ring = attention == null
        ? fill.withValues(alpha: 0.4)
        : friendshipAttentionColor(attention!);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill.withValues(alpha: 0.22),
        border: Border.all(color: ring, width: 2),
      ),
      child: Text(
        personInitials(person),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: ColonyColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class CadenceRing extends StatelessWidget {
  const CadenceRing({
    super.key,
    required this.rhythm,
    this.size = 56,
  });

  final FriendshipRhythm rhythm;
  final double size;

  @override
  Widget build(BuildContext context) {
    final interval = switch (rhythm.attention) {
      FriendshipAttention.noCadence || FriendshipAttention.neverMet => null,
      _ => rhythm.daysSinceLastEncounter,
    };
    final progress = () {
      if (rhythm.cadenceDueAt == null || rhythm.lastEncounterAt == null) {
        return 0.0;
      }
      final total = rhythm.cadenceDueAt!
          .difference(rhythm.lastEncounterAt!)
          .inDays
          .clamp(1, 365);
      final used = (rhythm.daysSinceLastEncounter ?? 0).clamp(0, total);
      return (used / total).clamp(0.0, 1.0);
    }();
    final color = friendshipAttentionColor(rhythm.attention);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CadenceRingPainter(progress: progress, color: color),
        child: Center(
          child: Text(
            interval == null ? '·' : '$interval',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _CadenceRingPainter extends CustomPainter {
  _CadenceRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 3;
    final track = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _CadenceRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class FriendshipKindChip extends StatelessWidget {
  const FriendshipKindChip({super.key, required this.kind});

  final FriendshipKind kind;

  @override
  Widget build(BuildContext context) {
    final color = friendshipKindColor(kind);
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.18),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      label: Text(
        AppStrings.friendshipKindLabel(kind),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class RelationsEmptyState extends StatelessWidget {
  const RelationsEmptyState({
    super.key,
    required this.asset,
    required this.title,
    required this.hint,
  });

  final String asset;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(ColonyRadii.soft),
              child: Image.asset(
                asset,
                width: 140,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Icon(
                  Icons.people_outline,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: ColonySpacing.sm),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class RelationsHeroBanner extends StatelessWidget {
  const RelationsHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ColonyRadii.soft),
      child: Stack(
        children: [
          Image.asset(
            RelationsAssets.heroConstellation,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              height: 120,
              color: ColonyColors.void_,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    ColonyColors.void_.withValues(alpha: 0.72),
                    ColonyColors.void_.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(ColonySpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: ColonyColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: ColonySpacing.xs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RelationsMark extends StatelessWidget {
  const RelationsMark({super.key, required this.asset, this.size = 36});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => SizedBox(
          width: size,
          height: size,
          child: const Icon(Icons.hub_outlined),
        ),
      ),
    );
  }
}

class EncounterSparkline extends StatelessWidget {
  const EncounterSparkline({super.key, required this.dates, this.maxBars = 8});

  final List<DateTime> dates;
  final int maxBars;

  @override
  Widget build(BuildContext context) {
    final latest = [...dates]..sort();
    final shown = latest.length > maxBars
        ? latest.sublist(latest.length - maxBars)
        : latest;
    if (shown.isEmpty) {
      return Text(
        AppStrings.friendshipNeverMet,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Row(
      children: [
        for (var i = 0; i < shown.length; i++)
          Container(
            width: 10,
            height: 10 + (i * 2),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: ColonyMiniAppColors.friendships.withValues(
                alpha: 0.35 + (i / shown.length) * 0.65,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
