import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

class TimelineLetter extends StatefulWidget {
  const TimelineLetter({
    super.key,
    required this.title,
    required this.summary,
    required this.timestamp,
    this.severity = TimelineLetterSeverity.info,
    this.sourceLabel,
    this.onTap,
    this.actions = const [],
    this.highlighted = false,
  });

  final String title;
  final String summary;
  final DateTime timestamp;
  final TimelineLetterSeverity severity;
  final String? sourceLabel;
  final VoidCallback? onTap;
  final List<Widget> actions;
  final bool highlighted;

  @override
  State<TimelineLetter> createState() => _TimelineLetterState();
}

class _TimelineLetterState extends State<TimelineLetter> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final accent = switch (widget.severity) {
      TimelineLetterSeverity.info => ColonyColors.statusInfo,
      TimelineLetterSeverity.attention => ColonyColors.statusAttention,
      TimelineLetterSeverity.risk => ColonyColors.statusRisk,
      TimelineLetterSeverity.critical => ColonyColors.statusCritical,
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: widget.highlighted || _hover
                ? ColonyColors.lightHighlight
                : ColonyColors.panel,
            border: Border(
              left: BorderSide(
                color: accent,
                width: widget.highlighted ? 5 : 3,
              ),
              bottom: const BorderSide(color: ColonyColors.borderSeparator),
            ),
          ),
          padding: const EdgeInsets.all(ColonySpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _hover
                                ? ColonyColors.textMouseover
                                : ColonyColors.textPrimary,
                          ),
                    ),
                  ),
                  Text(
                    _formatTime(widget.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColonyColors.textMuted,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: ColonySpacing.xs),
              Text(
                widget.summary,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (widget.sourceLabel != null) ...[
                const SizedBox(height: ColonySpacing.sm),
                Text(
                  widget.sourceLabel!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColonyColors.textMuted,
                      ),
                ),
              ],
              if (widget.actions.isNotEmpty) ...[
                const SizedBox(height: ColonySpacing.sm),
                Wrap(spacing: ColonySpacing.sm, children: widget.actions),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

enum TimelineLetterSeverity {
  info,
  attention,
  risk,
  critical,
}
