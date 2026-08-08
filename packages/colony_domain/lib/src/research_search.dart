import 'research_hierarchy.dart';
import 'research_node.dart';

/// Filters [hierarchy] by case-insensitive match on node title and description.
/// Returns an empty list when [query] is non-empty and nothing matches.
List<ResearchHierarchyNode> filterResearchHierarchy({
  required List<ResearchHierarchyNode> hierarchy,
  required String query,
}) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return hierarchy;

  final lower = trimmed.toLowerCase();
  bool matches(ResearchNode node) {
    if (node.title.toLowerCase().contains(lower)) return true;
    final description = node.description;
    if (description != null && description.toLowerCase().contains(lower)) {
      return true;
    }
    return false;
  }

  return hierarchy.where((item) => matches(item.node)).toList();
}
