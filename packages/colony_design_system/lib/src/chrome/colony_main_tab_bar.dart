import 'package:flutter/material.dart';

import '../chrome/colony_pixel_icon.dart';
import '../tokens/colony_tokens.dart';

class ColonyMainTab {
  const ColonyMainTab({
    required this.label,
    required this.icon,
    required this.route,
    this.iconName,
  });

  final String label;
  final IconData icon;
  final String route;
  final String? iconName;
}

/// Bottom main-tab strip (Fallhub Terminal).
class ColonyMainTabBar extends StatelessWidget {
  const ColonyMainTabBar({
    super.key,
    required this.tabs,
    required this.currentRoute,
    required this.onSelect,
    this.height = 64,
  });

  final List<ColonyMainTab> tabs;
  final String currentRoute;
  final ValueChanged<String> onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColonyColors.tab,
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: ColonyColors.borderStandard, width: 1.4),
            ),
          ),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++) ...[
                  if (i > 0)
                    Container(width: 1, color: ColonyColors.borderSeparator),
                  Expanded(
                    child: _MainTabButton(
                      tab: tabs[i],
                      selected: currentRoute == tabs[i].route,
                      onTap: () => onSelect(tabs[i].route),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainTabButton extends StatefulWidget {
  const _MainTabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final ColonyMainTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_MainTabButton> createState() => _MainTabButtonState();
}

class _MainTabButtonState extends State<_MainTabButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final fg = selected
        ? ColonyColors.textInscribed
        : _hover
            ? ColonyColors.textMouseover
            : ColonyColors.textMuted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: AnimatedContainer(
            duration: ColonyDurations.fast,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? ColonyColors.tabActive : Colors.transparent,
              borderRadius: BorderRadius.circular(ColonyRadii.sm),
              border: selected
                  ? Border.all(
                      color: ColonyColors.brass.withValues(alpha: 0.55),
                    )
                  : null,
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x55E8C86A),
                        blurRadius: 8,
                        offset: Offset(0, -1),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.tab.iconName != null)
                  ColonyPixelIcon(
                    widget.tab.iconName!,
                    size: 22,
                    mono: true,
                    color: fg,
                  )
                else
                  Icon(widget.tab.icon, size: 20, color: fg),
                const SizedBox(height: 3),
                Text(
                  widget.tab.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontSize: 9,
                    letterSpacing: 0.5,
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
