import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AlbumMarkdownBody extends StatelessWidget {
  const AlbumMarkdownBody({super.key, required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sheet = MarkdownStyleSheet(
      p: theme.textTheme.bodyMedium?.copyWith(
        height: 1.45,
        color: ColonyColors.textSecondary,
      ),
      h1: theme.textTheme.headlineSmall?.copyWith(
        color: ColonyColors.textPrimary,
        height: 1.2,
      ),
      h2: theme.textTheme.titleLarge?.copyWith(
        color: ColonyColors.textOption,
        height: 1.25,
      ),
      h3: theme.textTheme.titleMedium?.copyWith(
        color: ColonyColors.accentCyan,
        letterSpacing: 0.2,
      ),
      em: theme.textTheme.bodyMedium?.copyWith(
        fontStyle: FontStyle.italic,
        color: ColonyColors.textPrimary,
      ),
      strong: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: ColonyColors.textPrimary,
      ),
      listBullet: theme.textTheme.bodyMedium?.copyWith(
        color: ColonyColors.accentSand,
      ),
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        color: ColonyColors.textMuted,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: ColonyColors.accentSand, width: 2),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: ColonySpacing.md),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: ColonyColors.borderSeparator),
        ),
      ),
      a: theme.textTheme.bodyMedium?.copyWith(
        color: ColonyColors.accentCyan,
        decoration: TextDecoration.underline,
      ),
    );

    return MarkdownBody(
      data: markdown,
      styleSheet: sheet,
      selectable: true,
      onTapLink: (text, href, title) {
        if (href == null) return;
        launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
      },
    );
  }
}
