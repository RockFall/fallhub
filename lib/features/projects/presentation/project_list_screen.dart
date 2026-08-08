import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../application/project_controllers.dart';
import '../application/project_providers.dart';
import 'widgets/create_project_sheet.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
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
      await CreateProjectSheet.show(context);
      if (!mounted) return;
      _lastHandledCreateUri = null;
      final currentRouter = GoRouter.maybeOf(context);
      if (currentRouter == null) return;
      final currentUri = currentRouter.routerDelegate.currentConfiguration.uri;
      if (currentUri.queryParameters['create'] == '1') {
        context.go('/projects');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(projectControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.errorGeneric)),
        );
      }
    });

    final list = ref.watch(projectListProvider);
    final projectsAsync = ref.watch(projectsProvider);

    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
      data: (_) {
        if (list.isEmpty) {
          return _EmptyList(onCreate: () => CreateProjectSheet.show(context));
        }

        return ListView(
          padding: const EdgeInsets.all(ColonySpacing.lg),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.projects,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => CreateProjectSheet.show(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(AppStrings.newProject),
                ),
              ],
            ),
            const SizedBox(height: ColonySpacing.lg),
            if (list.active.isNotEmpty)
              _ProjectSection(
                title: AppStrings.projectSectionActive,
                projects: list.active,
              ),
            if (list.completed.isNotEmpty)
              _ProjectSection(
                title: AppStrings.projectSectionCompleted,
                projects: list.completed,
              ),
            if (list.archived.isNotEmpty)
              _ProjectSection(
                title: AppStrings.projectSectionArchived,
                projects: list.archived,
              ),
          ],
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
            Icon(
              Icons.folder_outlined,
              size: 48,
              color: ColonyColors.borderStandard,
            ),
            const SizedBox(height: ColonySpacing.lg),
            Text(
              AppStrings.projectListEmpty,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ColonySpacing.sm),
            Text(
              AppStrings.projectListEmptyHint,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ColonySpacing.lg),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.newProject),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectSection extends StatelessWidget {
  const _ProjectSection({required this.title, required this.projects});

  final String title;
  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ColonySpacing.lg),
      child: ColonyPanel(
        title: title,
        icon: Icons.folder_outlined,
        child: Column(
          children: projects.map((project) => _ProjectCard(project: project)).toList(),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(project.title),
      subtitle: project.purpose == null ? null : Text(project.purpose!, maxLines: 2),
      trailing: Chip(
        label: Text(
          AppStrings.projectStatusLabel(project.status),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onTap: () => context.go('/projects/${project.id.value}'),
    );
  }
}
