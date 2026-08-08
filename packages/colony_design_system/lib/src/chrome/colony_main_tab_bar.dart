import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

class ColonyMainTab {
  const ColonyMainTab({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

/// Bottom main-tab strip (RimWorld MainTabWindow language).
class ColonyMainTabBar extends StatelessWidget {
  const ColonyMainTabBar({
    super.key,
    required this.tabs,
    required this.currentRoute,
    required this.onSelect,
    this.height = 48,
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
        child: Container(
          height: height,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: ColonyColors.borderStandard, width: 1),
            ),
          ),
          child: Row(
            children: [
              for (final tab in tabs)
                Expanded(
                  child: _MainTabButton(
                    tab: tab,
                    selected: currentRoute == tab.route,
                    onTap: () => onSelect(tab.route),
                  ),
                ),
            ],
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
        ? ColonyColors.textPrimary
        : _hover
            ? ColonyColors.textMouseover
            : ColonyColors.textMuted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? ColonyColors.raised : Colors.transparent,
            border: Border(
              top: BorderSide(
                color: selected
                    ? ColonyColors.borderSelected
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.tab.icon, size: 20, color: fg),
              const SizedBox(height: 2),
              Text(
                widget.tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: fg,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
