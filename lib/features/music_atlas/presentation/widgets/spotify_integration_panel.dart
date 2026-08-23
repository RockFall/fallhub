import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../integrations/application/integrations_providers.dart';
import '../../application/music_atlas_controllers.dart';
import '../../application/spotify_runtime.dart';

class SpotifyIntegrationPanel extends ConsumerStatefulWidget {
  const SpotifyIntegrationPanel({super.key});

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

  @override
  Widget build(BuildContext context) {
    final consent = ref.watch(spotifyConsentProvider);
    final busy = ref.watch(musicAtlasControllerProvider).isLoading;
    final enabled = consent?.enabled ?? false;

    return ColonyPanel(
      title: AppStrings.musicAtlasSpotifyTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.musicAtlasSpotifyDisclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
          TextField(
            controller: _clientId,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: AppStrings.musicAtlasSpotifyClientId,
            ),
            onChanged: _persistClientId,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Wrap(
            spacing: ColonySpacing.sm,
            runSpacing: ColonySpacing.sm,
            children: [
              FilledButton(
                onPressed: busy
                    ? null
                    : () => ref
                        .read(musicAtlasControllerProvider.notifier)
                        .beginSpotifyAuth(),
                child: const Text(AppStrings.musicAtlasSpotifyConnect),
              ),
              OutlinedButton(
                onPressed: busy
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
        ],
      ),
    );
  }
}
