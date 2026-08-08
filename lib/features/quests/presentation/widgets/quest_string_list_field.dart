import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';

class QuestStringListField extends StatefulWidget {
  const QuestStringListField({
    super.key,
    required this.label,
    required this.addLabel,
    required this.hint,
    this.initialValues = const [],
  });

  final String label;
  final String addLabel;
  final String hint;
  final List<String> initialValues;

  @override
  QuestStringListFieldState createState() => QuestStringListFieldState();
}

class QuestStringListFieldState extends State<QuestStringListField> {
  final _controllers = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    if (widget.initialValues.isEmpty) {
      _addLine();
    } else {
      for (final value in widget.initialValues) {
        _controllers.add(TextEditingController(text: value));
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> collectValues() {
    return _controllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _addLine() {
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeLine(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
      if (_controllers.isEmpty) {
        _addLine();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: ColonySpacing.sm),
        ...List.generate(_controllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controllers[index],
                    decoration: InputDecoration(hintText: widget.hint),
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.questRemoveLine,
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _removeLine(index),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addLine,
            icon: const Icon(Icons.add, size: 18),
            label: Text(widget.addLabel),
          ),
        ),
      ],
    );
  }
}
