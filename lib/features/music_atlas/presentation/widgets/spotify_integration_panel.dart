import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../integrations/application/integrations_providers.dart';
import '../../application/music_atlas_controllers.dart';
import '../../application/music_atlas_providers.dart';
import '../../application/spotify_history_files.dart';
import '../../application/spotify_runtime.dart';

class SpotifyIntegrationPanel extends ConsumerStatefulWidget {
  const SpotifyIntegrationPanel({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const Padding(
          padding: EdgeInsets.fromLTRB(
            ColonySpacing.lg,
            ColonySpacing.md,
            ColonySpacing.lg,
            ColonySpacing.xl,
          ),
          child: SingleChildScrollView(child: SpotifyIntegrationPanel()),
        );
      },
    );
  }

  @override
  ConsumerState<SpotifyIntegrationPanel> createState() =>
      _SpotifyIntegrationPanelState();
}

class _SpotifyIntegrationPanelState
    extends ConsumerState<SpotifyIntegrationPanel> {
  final _clientId = TextEditingController();
  final _callback = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(musicAtlasControllerProvider.notifier).ensureSpotifyConsent();
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('spotify.clientId') ?? '';
      if (!mounted) return;
      if (stored.isNotEmpty) {
        _clientId.text = stored;
        ref.read(spotifyClientIdProvider.notifier).set(stored);
      }
    });
  }

  @override
  void dispose() {
    _clientId.dispose();
    _callback.dispose();
    super.dispose();
  }

  Future<void> _persistClientId(String value) async {
    ref.read(spotifyClientIdProvider.notifier).set(value.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spotify.clientId', value.trim());
  }

  Future<void> _open(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _copyRedirect() async {
    await Clipboard.setData(
      const ClipboardData(text: MusicSpotifyPolicy.defaultRedirectUri),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.musicAtlasSpotifyRedirectCopied)),
    );
  }

  Future<void> _importHistory() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip', 'json'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final files = [
      for (final file in result.files)
        if (file.bytes != null) (name: file.name, bytes: file.bytes!),
    ];
    if (files.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.musicAtlasSpotifyHistoryEmpty)),
      );
      return;
    }
    try {
      final history = SpotifyHistoryFiles.parsePicked(files);
      if (history.albums.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.musicAtlasSpotifyHistoryEmpty),
          ),
        );
        return;
      }
      final imported = await ref
          .read(musicAtlasControllerProvider.notifier)
          .importSpotifyHistory(history);
      if (!mounted || imported == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.musicAtlasSpotifyHistoryDone(
              albums: history.albums.length,
              created: imported.createdNodes,
              encounters: imported.createdEncounters,
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final consent = ref.watch(spotifyConsentProvider);
    final busy = ref.watch(musicAtlasControllerProvider).isLoading;
    final error = ref.watch(musicAtlasControllerProvider).asError?.error;
    final linked = ref.watch(spotifySessionProvider).asData?.value ?? false;
    final enabled = consent?.enabled ?? false;
    final theme = Theme.of(context);

    return ColonyPanel(
      title: AppStrings.musicAtlasSpotifyTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.musicAtlasSpotifyDisclaimer,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            linked
                ? AppStrings.musicAtlasSpotifyLinked
                : AppStrings.musicAtlasSpotifyNotLinked,
            style: theme.textTheme.titleSmall?.copyWith(
              color: linked
                  ? ColonyColors.statusGood
                  : ColonyColors.statusAttention,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: ColonySpacing.sm),
            Text(
              '$error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: ColonyColors.statusRisk,
              ),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.integrationsOptIn),
            subtitle: Text(
              enabled
                  ? AppStrings.integrationsEnabled
                  : AppStrings.integrationsDisabled,
            ),
            value: enabled,
            onChanged: busy
                ? null
                : (value) => ref
                    .read(musicAtlasControllerProvider.notifier)
                    .setSpotifyEnabled(value),
          ),
          Text(
            AppStrings.musicAtlasSpotifyHowTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          const _Step(number: '1', text: AppStrings.musicAtlasSpotifyHow1),
          const _Step(number: '2', text: AppStrings.musicAtlasSpotifyHow2),
          SelectableText(
            MusicSpotifyPolicy.defaultRedirectUri,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              color: ColonyColors.textOption,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _copyRedirect,
              icon: const Icon(Icons.copy, size: 16),
              label: const Text(AppStrings.musicAtlasSpotifyCopyRedirect),
            ),
          ),
          const _Step(number: '3', text: AppStrings.musicAtlasSpotifyHow3),
          const _Step(number: '4', text: AppStrings.musicAtlasSpotifyHow4),
          const SizedBox(height: ColonySpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _open(MusicSpotifyPolicy.developerDashboardUrl),
            icon: const Icon(Icons.open_in_new),
            label: const Text(AppStrings.musicAtlasSpotifyOpenDashboard),
          ),
          TextField(
            controller: _clientId,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: AppStrings.musicAtlasSpotifyClientId,
              hintText: 'a1b2c3… (Dashboard → Settings)',
            ),
            onChanged: (value) {
              setState(() {});
              _persistClientId(value);
            },
          ),
          const SizedBox(height: ColonySpacing.sm),
          Wrap(
            spacing: ColonySpacing.sm,
            runSpacing: ColonySpacing.sm,
            children: [
              FilledButton(
                onPressed: busy || _clientId.text.trim().isEmpty
                    ? null
                    : () => ref
                        .read(musicAtlasControllerProvider.notifier)
                        .beginSpotifyAuth(),
                child: const Text(AppStrings.musicAtlasSpotifyConnect),
              ),
              OutlinedButton(
                onPressed: busy || !linked
                    ? null
                    : () => ref
                        .read(musicAtlasControllerProvider.notifier)
                        .pullSpotifyLibrary(),
                child: const Text(AppStrings.musicAtlasSpotifyPull),
              ),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => ref
                        .read(musicAtlasControllerProvider.notifier)
                        .setSpotifyEnabled(false),
                child: const Text(AppStrings.musicAtlasSpotifyRevoke),
              ),
            ],
          ),
          TextField(
            controller: _callback,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: AppStrings.musicAtlasSpotifyPasteCode,
              hintText: 'colony://integrations/spotify/callback?code=…',
            ),
            onChanged: (_) => setState(() {}),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: busy || _callback.text.trim().isEmpty
                  ? null
                  : () => ref
                      .read(musicAtlasControllerProvider.notifier)
                      .completeSpotifyAuth(_callback.text),
              child: const Text(AppStrings.musicAtlasApply),
            ),
          ),
          const Divider(),
          Text(
            AppStrings.musicAtlasSpotifyHistoryTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: ColonySpacing.xs),
          Text(
            AppStrings.musicAtlasSpotifyHistoryLead,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.sm),
          const _Step(number: '1', text: AppStrings.musicAtlasSpotifyHistory1),
          const _Step(number: '2', text: AppStrings.musicAtlasSpotifyHistory2),
          const _Step(number: '3', text: AppStrings.musicAtlasSpotifyHistory3),
          const _Step(number: '4', text: AppStrings.musicAtlasSpotifyHistory4),
          const _Step(number: '5', text: AppStrings.musicAtlasSpotifyHistory5),
          const _Step(number: '6', text: AppStrings.musicAtlasSpotifyHistory6),
          const SizedBox(height: ColonySpacing.sm),
          Wrap(
            spacing: ColonySpacing.sm,
            runSpacing: ColonySpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () => _open(MusicSpotifyPolicy.privacyUrl),
                icon: const Icon(Icons.privacy_tip_outlined),
                label: const Text(AppStrings.musicAtlasSpotifyOpenPrivacy),
              ),
              FilledButton.tonalIcon(
                onPressed: busy ? null : _importHistory,
                icon: const Icon(Icons.unarchive_outlined),
                label: const Text(AppStrings.musicAtlasSpotifyImportHistory),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: ColonyColors.optionSelected,
            child: Text(number, style: Theme.of(context).textTheme.labelSmall),
          ),
          const SizedBox(width: ColonySpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
