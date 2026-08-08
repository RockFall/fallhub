import 'package:flutter/material.dart';

import '../chrome/colony_button.dart';
import '../chrome/colony_main_tab_bar.dart';
import '../chrome/colony_surface.dart';
import '../tokens/colony_tokens.dart';

class ColonyDestination {
  const ColonyDestination({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  ColonyMainTab toMainTab() =>
      ColonyMainTab(label: label, icon: icon, route: route);
}

/// App chrome: workspace + RimWorld-style main tabs on the bottom edge.
class ColonyShell extends StatelessWidget {
  const ColonyShell({
    super.key,
    required this.destinations,
    required this.currentRoute,
    required this.onNavigate,
    required this.body,
    this.compact = true,
    this.desktopTopBar,
    this.appBarTitle,
    this.appBarActions = const [],
    this.floatingActionButton,
    this.showCaptureFab = false,
    this.onCapture,
  });

  final List<ColonyDestination> destinations;
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final Widget body;
  final bool compact;
  final Widget? desktopTopBar;
  final String? appBarTitle;
  final List<Widget> appBarActions;
  final Widget? floatingActionButton;
  final bool showCaptureFab;
  final VoidCallback? onCapture;

  @override
  Widget build(BuildContext context) {
    final tabs = (compact ? compactDestinations : destinations)
        .map((d) => d.toMainTab())
        .toList();

    final capture = floatingActionButton ??
        (showCaptureFab && onCapture != null
            ? _CaptureGizmo(onPressed: onCapture!)
            : null);
    final tabBarHeight = compact ? 52.0 : 48.0;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: ColonyColors.void_,
      appBar: appBarTitle == null && desktopTopBar == null
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: ColonySurface(
                kind: ColonySurfaceKind.panel,
                padding: const EdgeInsets.symmetric(horizontal: ColonySpacing.md),
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        if (desktopTopBar != null)
                          Expanded(child: desktopTopBar!)
                        else ...[
                          Expanded(
                            child: Text(
                              appBarTitle ?? '',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          ...appBarActions,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              top: appBarTitle == null && desktopTopBar == null,
              bottom: false,
              child: body,
            ),
          ),
          if (capture != null)
            Positioned(
              right: ColonySpacing.lg,
              bottom: tabBarHeight + bottomInset + ColonySpacing.md,
              child: capture,
            ),
        ],
      ),
      bottomNavigationBar: ColonyMainTabBar(
        tabs: tabs,
        currentRoute: currentRoute,
        onSelect: onNavigate,
        height: tabBarHeight,
      ),
    );
  }

  List<ColonyDestination> get compactDestinations {
    const compactRoutes = ['/colony', '/pawn', '/work', '/quests', '/more'];
    final selected = destinations
        .where((d) => compactRoutes.contains(d.route))
        .toList();
    if (selected.length >= 5) return selected.take(5).toList();
    return destinations.take(5).toList();
  }
}

class _CaptureGizmo extends StatelessWidget {
  const _CaptureGizmo({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ColonyButton(
      onPressed: onPressed,
      minWidth: 56,
      height: 56,
      padding: EdgeInsets.zero,
      child: const Icon(Icons.add, size: 28),
    );
  }
}
