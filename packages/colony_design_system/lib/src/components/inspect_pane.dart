import 'package:flutter/material.dart';

import '../chrome/colony_surface.dart';
import '../tokens/colony_tokens.dart';

class InspectPane extends StatelessWidget {
  const InspectPane({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.icon,
    this.actions = const [],
    this.footer,
    this.tabs,
    this.selectedTabIndex = 0,
    this.onTabChanged,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final IconData? icon;
  final List<Widget> actions;
  final Widget? footer;
  final List<String>? tabs;
  final int selectedTabIndex;
  final ValueChanged<int>? onTabChanged;

  @override
  Widget build(BuildContext context) {
    return ColonySurface(
      kind: ColonySurfaceKind.window,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounded = constraints.hasBoundedHeight;
          final bodyPane = ColoredBox(
            color: ColonyColors.window,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ColonySpacing.windowMargin),
              child: body,
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(ColonySpacing.windowMargin),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ColonyColors.void_,
                          border:
                              Border.all(color: ColonyColors.borderStandard),
                        ),
                        child: Icon(
                          icon,
                          color: ColonyColors.needsFill,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: ColonySpacing.md),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: ColonyColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
              if (tabs != null && tabs!.isNotEmpty)
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: ColonyColors.borderSeparator),
                      bottom: BorderSide(color: ColonyColors.borderSeparator),
                    ),
                    color: ColonyColors.tab,
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < tabs!.length; i++)
                        _InspectTab(
                          label: tabs![i],
                          selected: i == selectedTabIndex,
                          onTap: () => onTabChanged?.call(i),
                        ),
                    ],
                  ),
                ),
              if (bounded) Expanded(child: bodyPane) else bodyPane,
              if (footer != null)
                Container(
                  padding: const EdgeInsets.all(ColonySpacing.md),
                  decoration: const BoxDecoration(
                    color: ColonyColors.panel,
                    border: Border(
                      top: BorderSide(color: ColonyColors.borderSeparator),
                    ),
                  ),
                  child: footer,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InspectTab extends StatefulWidget {
  const _InspectTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_InspectTab> createState() => _InspectTabState();
}

class _InspectTabState extends State<_InspectTab> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected
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
          padding: const EdgeInsets.symmetric(
            horizontal: ColonySpacing.lg,
            vertical: ColonySpacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.selected ? ColonyColors.raised : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: widget.selected
                    ? ColonyColors.borderSelected
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
