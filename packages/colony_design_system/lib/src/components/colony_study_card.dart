import 'package:flutter/material.dart';

import '../chrome/colony_surface.dart';
import '../tokens/colony_tokens.dart';

/// Typographic study face. Reveal, never a casino flip.
class ColonyStudyCard extends StatelessWidget {
  const ColonyStudyCard({
    super.key,
    required this.prompt,
    required this.revealed,
    this.answer,
    this.extra,
    this.hint,
    this.onReveal,
  });

  final String prompt;
  final bool revealed;
  final String? answer;
  final String? extra;
  final String? hint;
  final VoidCallback? onReveal;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: revealed ? null : onReveal,
      child: ColonySurface(
        child: Padding(
          padding: const EdgeInsets.all(ColonySpacing.xl),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 160),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    prompt,
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: ColonySpacing.xl),
                  if (!revealed)
                    Text(
                      hint ?? '',
                      style: text.bodyMedium?.copyWith(
                        color: ColonyColors.textMuted,
                      ),
                    )
                  else ...[
                    if (answer != null && answer!.isNotEmpty)
                      Text(
                        answer!,
                        textAlign: TextAlign.center,
                        style: text.titleLarge?.copyWith(
                          color: ColonyColors.accentCyan,
                          height: 1.4,
                          fontSize: 22,
                        ),
                      ),
                    if (extra != null && extra!.isNotEmpty) ...[
                      const SizedBox(height: ColonySpacing.md),
                      Text(
                        extra!,
                        textAlign: TextAlign.center,
                        style: text.bodySmall,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
