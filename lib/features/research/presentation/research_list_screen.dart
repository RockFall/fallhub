import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../application/research_controllers.dart';
import '../application/research_providers.dart';
import 'widgets/create_research_node_sheet.dart';
import 'widgets/research_graph_view.dart';
import 'widgets/research_hierarchy_list.dart';

class ResearchListScreen extends ConsumerStatefulWidget {
  const ResearchListScreen({super.key});

  @override
  ConsumerState<ResearchListScreen> createState() => _ResearchListScreenState();
}

class _ResearchListScreenState extends ConsumerState<ResearchListScreen> {
  String? _lastHandledCreateUri;
  GoRouter? _trackedRouter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (router != null && !identical(_trackedRouter, router)) {
      _trackedRouter?.routerDelegate.removeListener(_onRouterChanged);
      _trackedRouter = router;
      _trackedRouter!.routerDelegate.addListener(_onRouterChanged);
    }
    _syncCreateDeepLinkState();
    _handleCreateDeepLink();
  }

  @override
  void dispose() {
    _trackedRouter?.routerDelegate.removeListener(_onRouterChanged);
    super.dispose();
  }

  void _onRouterChanged() {
    if (!mounted) return;
    _syncCreateDeepLinkState();
    _handleCreateDeepLink();
  }

  void _syncCreateDeepLinkState() {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final uri = router.routerDelegate.currentConfiguration.uri;
    if (uri.queryParameters['create'] != '1') {
      _lastHandledCreateUri = null;
    }
  }

  void _handleCreateDeepLink() {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final uri = router.routerDelegate.currentConfiguration.uri;
    if (uri.queryParameters['create'] != '1') return;
    final key = uri.toString();
    if (_lastHandledCreateUri == key) return;
    _lastHandledCreateUri = key;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await CreateResearchNodeSheet.show(context);
      if (!mounted) return;
      _lastHandledCreateUri = null;
      final currentRouter = GoRouter.maybeOf(context);
      if (currentRouter == null) return;
      final currentUri = currentRouter.routerDelegate.currentConfiguration.uri;
      if (currentUri.queryParameters['create'] == '1') {
        context.go('/research');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(researchControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.errorGeneric)),
        );
      }
    });

    final nodesAsync = ref.watch(researchNodesProvider);
    final hierarchy = ref.watch(filteredResearchHierarchyProvider);
    final searchQuery = ref.watch(researchSearchQueryProvider);
    final focus = ref.watch(activeResearchFocusProvider);
    final viewMode = ref.watch(researchViewModeProvider);
    final progress = ref.watch(researchTreeProgressProvider);
    final isGraph = viewMode == ResearchViewMode.graph;

    return nodesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
      data: (nodes) {
        if (nodes.isEmpty) {
          return _EmptyList(onCreate: () => CreateResearchNodeSheet.show(context));
        }

        return Padding(
          padding: const EdgeInsets.all(ColonySpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.research,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => CreateResearchNodeSheet.show(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(AppStrings.newResearchNode),
                  ),
                ],
              ),
              const SizedBox(height: ColonySpacing.md),
              SearchBar(
                hintText: AppStrings.researchSearchHint,
                onChanged: (value) {
                  ref.read(researchSearchQueryProvider.notifier).set(value);
                },
                leading: const Icon(Icons.search),
              ),
              if (progress.activeTotal > 0) ...[
                const SizedBox(height: ColonySpacing.md),
                ColonyPanel(
                  title: AppStrings.researchProgressSummary,
                  icon: Icons.insights_outlined,
                  child: Text(
                    AppStrings.researchProgressSummaryValue(
                      progress.demonstratedCount,
                      progress.activeTotal,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: ColonySpacing.md),
              SegmentedButton<ResearchViewMode>(
                segments: [
                  ButtonSegment(
                    value: ResearchViewMode.list,
                    label: Text(AppStrings.researchViewList),
                    icon: const Icon(Icons.list),
                  ),
                  ButtonSegment(
                    value: ResearchViewMode.graph,
                    label: Text(AppStrings.researchViewGraph),
                    icon: const Icon(Icons.account_tree_outlined),
                  ),
                ],
                selected: {viewMode},
                onSelectionChanged: (selection) {
                  ref
                      .read(researchViewModeProvider.notifier)
                      .select(selection.first);
                },
              ),
              if (focus != null) ...[
                const SizedBox(height: ColonySpacing.md),
                ColonyPanel(
                  title: AppStrings.researchActiveFocus,
                  icon: Icons.science_outlined,
                  child: Text(focus.title),
                ),
              ],
              const SizedBox(height: ColonySpacing.lg),
              if (isGraph)
                const Expanded(child: ResearchGraphView())
              else ...[
                Text(
                  AppStrings.researchHierarchyTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: ColonySpacing.sm),
                Expanded(
                  child: searchQuery.trim().isNotEmpty && hierarchy.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.researchSearchNoResults,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : SingleChildScrollView(
                          child: ResearchHierarchyList(hierarchy: hierarchy),
                        ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ColonySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.researchListEmpty,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ColonySpacing.sm),
            Text(
              AppStrings.researchListEmptyHint,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ColonySpacing.lg),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.newResearchNode),
            ),
          ],
        ),
      ),
    );
  }
}
