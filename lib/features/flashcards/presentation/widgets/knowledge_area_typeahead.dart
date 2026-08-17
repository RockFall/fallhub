import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';

class KnowledgeAreaTypeahead extends StatefulWidget {
  const KnowledgeAreaTypeahead({
    super.key,
    required this.areas,
    required this.onSelected,
    this.placements = const [],
    this.selectedId,
    this.allowNone = true,
    this.enabled = true,
    this.label = AppStrings.flashcardsCaptureArea,
  });

  final List<KnowledgeArea> areas;
  final List<KnowledgeAreaPlacement> placements;
  final EntityId? selectedId;
  final ValueChanged<EntityId?> onSelected;
  final bool allowNone;
  final bool enabled;
  final String label;

  @override
  State<KnowledgeAreaTypeahead> createState() => _KnowledgeAreaTypeaheadState();
}

class _KnowledgeAreaTypeaheadState extends State<KnowledgeAreaTypeahead> {
  late final TextEditingController _controller;
  var _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _labelFor(widget.selectedId));
  }

  @override
  void didUpdateWidget(covariant KnowledgeAreaTypeahead oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId && _query.isEmpty) {
      _controller.text = _labelFor(widget.selectedId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _labelFor(EntityId? id) {
    if (id == null) return '';
    return KnowledgeAreaPolicy.pathLabel(areaId: id, areas: widget.areas);
  }

  @override
  Widget build(BuildContext context) {
    final hits = widget.areas
        .where(
          (area) => KnowledgeAreaPolicy.matchesQuery(
            area: area,
            query: _query,
            areas: widget.areas,
            placements: widget.placements,
          ),
        )
        .take(8)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: AppStrings.flashcardsAreaSearch,
            suffixIcon: widget.selectedId == null
                ? const Icon(Icons.search)
                : IconButton(
                    tooltip: AppStrings.flashcardsAreaNone,
                    onPressed: widget.allowNone
                        ? () {
                            _controller.clear();
                            setState(() => _query = '');
                            widget.onSelected(null);
                          }
                        : null,
                    icon: const Icon(Icons.clear),
                  ),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        if (_query.trim().isNotEmpty) ...[
          const SizedBox(height: ColonySpacing.xs),
          if (widget.allowNone)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.flashcardsAreaNone),
              onTap: () {
                _controller.clear();
                setState(() => _query = '');
                widget.onSelected(null);
              },
            ),
          for (final area in hits)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(area.title),
              subtitle: Text(
                KnowledgeAreaPolicy.pathLabel(
                  areaId: area.id,
                  areas: widget.areas,
                ),
              ),
              onTap: () {
                widget.onSelected(area.id);
                _controller.text = _labelFor(area.id);
                setState(() => _query = '');
              },
            ),
          if (hits.isEmpty)
            Text(
              AppStrings.flashcardsNoResults,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColonyColors.textMuted,
                  ),
            ),
        ],
      ],
    );
  }
}
