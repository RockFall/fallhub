import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';

class FlashcardTagField extends StatefulWidget {
  const FlashcardTagField({
    super.key,
    required this.labels,
    required this.tags,
    required this.onChanged,
  });

  final List<String> labels;
  final List<FlashcardTag> tags;
  final ValueChanged<List<String>> onChanged;

  @override
  State<FlashcardTagField> createState() => _FlashcardTagFieldState();
}

class _FlashcardTagFieldState extends State<FlashcardTagField> {
  final _add = TextEditingController();

  @override
  void dispose() {
    _add.dispose();
    super.dispose();
  }

  void _commit([String? raw]) {
    final path = FlashcardTagPolicy.parsePath(raw ?? _add.text);
    if (path.isEmpty) return;
    final label = path.join(' / ');
    final needle = FlashcardTagPolicy.normalizeTitle(label);
    if (widget.labels.any((item) => FlashcardTagPolicy.normalizeTitle(item) == needle)) {
      _add.clear();
      return;
    }
    widget.onChanged([...widget.labels, label]);
    _add.clear();
    setState(() {});
  }

  List<String> get _suggestions {
    final query = _add.text.trim().toLowerCase();
    final selected = {
      for (final label in widget.labels) FlashcardTagPolicy.normalizeTitle(label),
    };
    return [
      for (final tag in widget.tags)
        FlashcardTagPolicy.pathLabel(tagId: tag.id, tags: widget.tags),
    ]
        .where((label) {
          final key = FlashcardTagPolicy.normalizeTitle(label);
          if (selected.contains(key)) return false;
          if (query.isEmpty) return true;
          return label.toLowerCase().contains(query);
        })
        .take(8)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.labels.isNotEmpty)
          Wrap(
            spacing: ColonySpacing.sm,
            runSpacing: ColonySpacing.sm,
            children: [
              for (final label in widget.labels)
                InputChip(
                  label: Text(label),
                  onDeleted: () => widget.onChanged([
                    for (final item in widget.labels)
                      if (item != label) item,
                  ]),
                ),
            ],
          ),
        if (widget.labels.isNotEmpty) const SizedBox(height: ColonySpacing.sm),
        TextField(
          controller: _add,
          decoration: InputDecoration(
            labelText: AppStrings.flashcardsTags,
            hintText: AppStrings.flashcardsTagsHint,
            suffixIcon: IconButton(
              tooltip: AppStrings.flashcardsAddTag,
              onPressed: _commit,
              icon: const Icon(Icons.add),
            ),
          ),
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: _commit,
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: ColonySpacing.sm),
          Wrap(
            spacing: ColonySpacing.sm,
            children: [
              for (final label in suggestions)
                ActionChip(
                  label: Text(label),
                  onPressed: () => _commit(label),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
