import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../application/colony_roster.dart';
import '../../flame/habitat_game.dart';
import 'pawn_preview.dart';

/// RimWorld-style colonist bar — square bust + name under (V9 polish).
class HabitatRosterBar extends StatelessWidget {
  const HabitatRosterBar({
    super.key,
    required this.game,
    required this.roster,
    required this.onChanged,
    required this.onRemove,
  });

  final HabitatGame game;
  final List<ColonyMember> roster;
  final VoidCallback onChanged;
  final void Function(String id) onRemove;

  static const double portrait = 56;

  @override
  Widget build(BuildContext context) {
    final focusedId = game.focusedPawn?.memberId;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in roster) ...[
            _ColonistSlot(
              member: m,
              selected: m.id == focusedId,
              onTap: () {
                final p = game.pawnByMemberId(m.id);
                if (p != null) game.selectPawn(p);
                onChanged();
              },
              onLongPress: () => context.go(
                '/colony/pawn-create?memberId=${m.id}',
              ),
              onRemove: m.isPlayer ? null : () => onRemove(m.id),
            ),
            if (m != roster.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _ColonistSlot extends StatelessWidget {
  const _ColonistSlot({
    required this.member,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    this.onRemove,
  });

  final ColonyMember member;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final name = member.appearance.name;
    return Tooltip(
      message: name,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          width: HabitatRosterBar.portrait + 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: HabitatRosterBar.portrait,
                    height: HabitatRosterBar.portrait,
                    decoration: BoxDecoration(
                      color: const Color(0xCC1A1A1A),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFE8E8E8)
                            : const Color(0xFF6A6A6A),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: ClipRect(
                      child: Align(
                        alignment: const Alignment(0, -0.85),
                        heightFactor: 0.62,
                        child: Transform.scale(
                          scale: 1.55,
                          alignment: Alignment.topCenter,
                          child: PawnPreview(
                            appearance: member.appearance,
                            size: HabitatRosterBar.portrait,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      left: 1,
                      right: 1,
                      bottom: 1,
                      child: Container(
                        height: 3,
                        color: const Color(0xFF3DB8A8),
                      ),
                    ),
                  if (onRemove != null && selected)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Material(
                        color: const Color(0xEE333333),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onRemove,
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.1,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
