import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final researchNodesProvider = StreamProvider<List<ResearchNode>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).research.watchAll(profile.id);
});

final researchNodeProvider =
    StreamProvider.family<ResearchNode?, String>((ref, nodeId) async* {
  final repos = ref.watch(repositoriesProvider);
  yield await repos.research.getById(EntityId(nodeId));
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield null;
    return;
  }
  await for (final nodes in repos.research.watchAll(profile.id)) {
    yield nodes.where((n) => n.id.value == nodeId).firstOrNull;
  }
});

final researchPrerequisitesProvider =
    StreamProvider.family<List<ResearchNode>, String>((ref, nodeId) {
  return ref.watch(repositoriesProvider).research.watchPrerequisites(EntityId(nodeId));
});

final questLinkedResearchProvider =
    StreamProvider.family<List<ResearchNode>, String>((ref, questId) {
  return ref
      .watch(repositoriesProvider)
      .research
      .watchLinkedToQuest(EntityId(questId));
});

final researchLinkedQuestsProvider =
    StreamProvider.family<List<Quest>, String>((ref, nodeId) {
  return ref
      .watch(repositoriesProvider)
      .research
      .watchLinkedQuests(EntityId(nodeId));
});

final researchPrerequisiteLinksProvider =
    FutureProvider<List<ResearchPrerequisiteLink>>((ref) async {
  ref.watch(researchNodesProvider);
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return [];
  return ref.read(repositoriesProvider).research.listPrerequisiteLinks(profile.id);
});

final researchHierarchyProvider = Provider<List<ResearchHierarchyNode>>((ref) {
  final nodesAsync = ref.watch(researchNodesProvider);
  final linksAsync = ref.watch(researchPrerequisiteLinksProvider);
  return nodesAsync.when(
    data: (nodes) => linksAsync.when(
      data: (links) => buildResearchHierarchy(nodes: nodes, links: links),
      loading: () => const [],
      error: (_, __) => const [],
    ),
    loading: () => const [],
    error: (_, __) => const [],
  );
});

final researchSearchQueryProvider =
    NotifierProvider<ResearchSearchQuery, String>(ResearchSearchQuery.new);

class ResearchSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) {
    state = query;
  }
}

final filteredResearchHierarchyProvider =
    Provider<List<ResearchHierarchyNode>>((ref) {
  final hierarchy = ref.watch(researchHierarchyProvider);
  final query = ref.watch(researchSearchQueryProvider);
  return filterResearchHierarchy(hierarchy: hierarchy, query: query);
});

final researchWaitingOnPrerequisitesProvider =
    Provider.family<bool, String>((ref, nodeId) {
  final nodeAsync = ref.watch(researchNodeProvider(nodeId));
  final prereqsAsync = ref.watch(researchPrerequisitesProvider(nodeId));
  final node = nodeAsync.asData?.value;
  final prereqs = prereqsAsync.asData?.value ?? const <ResearchNode>[];
  if (node == null) return false;
  return ResearchPrerequisitePolicy.isWaitingOnPrerequisites(
    node: node,
    prerequisites: prereqs,
  );
});

final activeResearchFocusProvider = Provider<ResearchNode?>((ref) {
  final nodesAsync = ref.watch(researchNodesProvider);
  return nodesAsync.when(
    data: (nodes) => ActiveResearchPolicy.currentFocus(nodes),
    loading: () => null,
    error: (_, __) => null,
  );
});

final researchSessionsProvider =
    StreamProvider.family<List<LearningSession>, String>((ref, nodeId) {
  return ref
      .watch(repositoriesProvider)
      .research
      .watchSessions(EntityId(nodeId));
});

final researchEvidenceProvider =
    StreamProvider.family<List<ResearchEvidence>, String>((ref, nodeId) {
  return ref
      .watch(repositoriesProvider)
      .research
      .watchEvidence(EntityId(nodeId));
});

enum ResearchViewMode {
  list,
  graph,
}

class ResearchViewModeNotifier extends Notifier<ResearchViewMode> {
  @override
  ResearchViewMode build() => ResearchViewMode.list;

  void select(ResearchViewMode mode) {
    state = mode;
  }
}

final researchViewModeProvider =
    NotifierProvider<ResearchViewModeNotifier, ResearchViewMode>(
  ResearchViewModeNotifier.new,
);

class ResearchShowDependenciesNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) {
    state = value;
  }
}

final researchShowDependenciesProvider =
    NotifierProvider<ResearchShowDependenciesNotifier, bool>(
  ResearchShowDependenciesNotifier.new,
);

final researchGraphLayoutProvider = Provider<ResearchGraphLayout>((ref) {
  final nodesAsync = ref.watch(researchNodesProvider);
  final linksAsync = ref.watch(researchPrerequisiteLinksProvider);
  return nodesAsync.when(
    data: (nodes) => linksAsync.when(
      data: (links) => buildResearchGraphLayout(nodes: nodes, links: links),
      loading: () => ResearchGraphLayout.empty,
      error: (_, __) => ResearchGraphLayout.empty,
    ),
    loading: () => ResearchGraphLayout.empty,
    error: (_, __) => ResearchGraphLayout.empty,
  );
});

final researchSearchMatchIdsProvider = Provider<Set<String>>((ref) {
  final filtered = ref.watch(filteredResearchHierarchyProvider);
  return filtered.map((item) => item.node.id.value).toSet();
});

final researchTreeProgressProvider = Provider<ResearchTreeProgress>((ref) {
  final nodesAsync = ref.watch(researchNodesProvider);
  return nodesAsync.when(
    data: computeResearchTreeProgress,
    loading: () => ResearchTreeProgress.zero,
    error: (_, __) => ResearchTreeProgress.zero,
  );
});

final researchNodeActivityProvider =
    Provider.family<ResearchNodeActivitySummary, String>((ref, nodeId) {
  final sessions = ref.watch(researchSessionsProvider(nodeId));
  final evidence = ref.watch(researchEvidenceProvider(nodeId));
  if (sessions.isLoading || evidence.isLoading) {
    return ResearchNodeActivitySummary.zero;
  }
  return computeResearchNodeActivity(
    sessions: sessions.asData?.value ?? const [],
    evidence: evidence.asData?.value ?? const [],
  );
});
