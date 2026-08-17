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
    this.eyebrow,
    this.hint,
    this.revealedFooter,
    this.onReveal,
  });

  final String prompt;
  final bool revealed;
  final String? answer;
  final String? extra;
  final String? eyebrow;
  final String? hint;
  final Widget? revealedFooter;
  final VoidCallback? onReveal;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final path = eyebrow?.trim() ?? '';
    return GestureDetector(
      onTap: revealed ? null : onReveal,
      child: ColonySurface(
        child: Padding(
          padding: const EdgeInsets.all(ColonySpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (path.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: ColonySpacing.md),
                  child: Text(
                    path,
                    textAlign: TextAlign.center,
                    style: text.labelLarge?.copyWith(
                      color: ColonyColors.textMuted,
                      letterSpacing: 0.2,
                      height: 1.3,
                    ),
                  ),
                ),
              Expanded(
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
                          if (revealedFooter != null) ...[
                            const SizedBox(height: ColonySpacing.lg),
                            revealedFooter!,
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
