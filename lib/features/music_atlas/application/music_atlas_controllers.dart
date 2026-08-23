import 'dart:math';

import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../flashcards/application/flashcard_providers.dart';
import '../../integrations/application/integrations_providers.dart';
import 'music_atlas_providers.dart';
import 'spotify_runtime.dart';

class MusicAtlasController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<T?> _run<T>(Future<T> Function() body) async {
    state = const AsyncLoading();
    try {
      final result = await body();
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<MusicNode?> createNode({
    required MusicNodeType type,
    required String title,
    int? year,
    String? description,
  }) {
    return _run(() async {
      final node = await ref
          .read(repositoriesProvider)
          .musicAtlas
          .createNode(
            nodeType: type,
            canonicalName: title,
            beginYear: year,
            description: description,
          );
      ref.invalidate(musicAtlasOverviewProvider);
      ref.invalidate(musicExplorationProvider);
      return node;
    });
  }

  Future<void> saveAlbumNotes({
    required EntityId nodeId,
    required String notesMarkdown,
  }) {
    return _run(() async {
      await ref
          .read(repositoriesProvider)
          .musicAtlas
          .updateAlbumDossier(nodeId: nodeId, notesMarkdown: notesMarkdown);
      ref.invalidate(musicAtlasOverviewProvider);
      ref.invalidate(musicNodeInspectProvider(nodeId.value));
      ref.invalidate(musicExplorationProvider);
    });
  }

  Future<void> assignTerritories({
    required EntityId nodeId,
    required List<String> territoryKeys,
  }) {
    return _run(() async {
      await ref
          .read(repositoriesProvider)
          .musicAtlas
          .updateAlbumDossier(nodeId: nodeId, territoryKeys: territoryKeys);
      ref.invalidate(musicAtlasOverviewProvider);
      ref.invalidate(musicNodeInspectProvider(nodeId.value));
      ref.invalidate(musicExplorationProvider);
    });
  }

  Future<MusicEncounter?> recordEncounter({
    required EntityId nodeId,
    required MusicEncounterType type,
    int? resonance,
    String? note,
  }) {
    return _run(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      final encounter = await ref
          .read(repositoriesProvider)
          .musicAtlas
          .recordEncounter(
            profileId: profile.id,
            nodeId: nodeId,
            encounterType: type,
            resonance: resonance,
            note: note,
          );
      ref.invalidate(musicAtlasOverviewProvider);
      ref.invalidate(musicNodeInspectProvider(nodeId.value));
      ref.invalidate(musicExplorationProvider);
      return encounter;
    });
  }

  Future<void> setState({
    required EntityId nodeId,
    required MusicDiscoveryState state,
    int? resonance,
    String? summary,
  }) {
    return _run(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      await ref
          .read(repositoriesProvider)
          .musicAtlas
          .setDiscoveryState(
            profileId: profile.id,
            nodeId: nodeId,
            state: state,
            resonance: resonance,
            personalSummary: summary,
          );
      ref.invalidate(musicAtlasOverviewProvider);
      ref.invalidate(musicNodeInspectProvider(nodeId.value));
      ref.invalidate(musicExplorationProvider);
    });
  }

  Future<void> startExpedition(MusicExpedition expedition) {
    return _run(() async {
      await ref
          .read(repositoriesProvider)
          .musicAtlas
          .startExpedition(expedition);
      ref.invalidate(musicAtlasOverviewProvider);
    });
  }

  Future<MusicExpedition?> draftExpedition({
    required String title,
    required String question,
    List<EntityId> nodeIds = const [],
  }) {
    return _run(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      final stops = [
        for (var i = 0; i < nodeIds.length; i++)
          MusicExpeditionStop(
            id: EntityId('pending'),
            expeditionId: const EntityId('pending'),
            nodeId: nodeIds[i],
            displayOrder: i,
            role: MusicExpeditionStopRole.destination,
          ),
      ];
      final expedition = await ref
          .read(repositoriesProvider)
          .musicAtlas
          .draftExpedition(
            profileId: profile.id,
            title: title,
            question: question,
            stops: stops,
          );
      ref.invalidate(musicAtlasOverviewProvider);
      return expedition;
    });
  }

  Future<MusicAtlasJsonImportPlan?> previewJson(MusicAtlasJsonDocument doc) {
    return _run(() {
      return ref.read(repositoriesProvider).musicAtlas.planJson(document: doc);
    });
  }

  Future<MusicAtlasJsonImportResult?> applyJson(MusicAtlasJsonDocument doc) {
    return _run(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      final result = await ref
          .read(repositoriesProvider)
          .musicAtlas
          .importJson(profileId: profile.id, document: doc);
      ref.invalidate(musicAtlasOverviewProvider);
      ref.invalidate(musicAtlasPromptProvider);
      ref.invalidate(musicExplorationProvider);
      return result;
    });
  }

  Future<void> acceptCandidates(List<MusicFlashcardCandidate> chosen) {
    return _run(() async {
      if (chosen.isEmpty) return;
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      final cards = [
        for (final candidate in chosen)
          FlashcardJsonCard(
            front: candidate.front,
            back: candidate.back,
            kind: FlashcardKind.values.firstWhere(
              (k) => k.name == candidate.suggestedKind,
              orElse: () => FlashcardKind.basic,
            ),
            deckTitle: candidate.deckTitle,
            areaPath: candidate.areaPath,
            tags: candidate.tags,
          ),
      ];
      await ref
          .read(repositoriesProvider)
          .flashcards
          .importJson(
            profileId: profile.id,
            document: FlashcardJsonDocument(cards: cards),
          );
      ref.invalidate(flashcardsProvider);
      ref.invalidate(musicFlashcardCandidatesProvider);
    });
  }

  Future<void> ensureSpotifyConsent() {
    return _run(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      await ref
          .read(repositoriesProvider)
          .integrations
          .ensureConsent(profileId: profile.id, kind: IntegrationKind.spotify);
      ref.invalidate(integrationConsentsProvider);
    });
  }

  Future<void> setSpotifyEnabled(bool enabled) {
    return _run(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      await ref
          .read(repositoriesProvider)
          .integrations
          .setConsentEnabled(
            profileId: profile.id,
            kind: IntegrationKind.spotify,
            enabled: enabled,
          );
      if (!enabled) {
        await ref.read(spotifyTokenStoreProvider).clear(profile.id);
        await ref.read(repositoriesProvider).musicAtlas.clearSpotifySync(profile.id);
      }
      ref.invalidate(integrationConsentsProvider);
    });
  }

  Future<String?> beginSpotifyAuth() {
    return _run(() async {
      var clientId = ref.read(spotifyClientIdProvider).trim();
      if (clientId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        clientId = prefs.getString('spotify.clientId') ?? '';
        if (clientId.isNotEmpty) {
          ref.read(spotifyClientIdProvider.notifier).set(clientId);
        }
      }
      if (clientId.isEmpty) {
        throw StateError(AppStrings.musicAtlasSpotifyNeedClient);
      }
      final seed = completePkce(
        MusicSpotifyPolicy.generatePkce(random: Random.secure()),
      );
      final request = MusicSpotifyPolicy.authorizationRequest(
        clientId: clientId,
        pkce: seed,
        scopes: const [
          MusicSpotifyPolicy.libraryScope,
          MusicSpotifyPolicy.recentScope,
          MusicSpotifyPolicy.playlistScope,
          MusicSpotifyPolicy.currentlyPlayingScope,
        ],
      );
      ref.read(_pkceProvider.notifier).set(seed);
      final uri = Uri.parse(request.authorizationUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return request.authorizationUrl;
    });
  }

  Future<void> completeSpotifyAuth(String rawCallback) {
    return _run(() async {
      final pkce = ref.read(_pkceProvider);
      if (pkce == null) {
        throw StateError('Inicia a ligação Spotify primeiro.');
      }
      final clientId = ref.read(spotifyClientIdProvider).trim();
      final code = MusicSpotifyPolicy.extractAuthorizationCode(
        rawCallback,
        expectedState: pkce.state,
      );
      final tokens = await ref
          .read(spotifyCatalogPortProvider)
          .exchangeCode(
            clientId: clientId,
            redirectUri: MusicSpotifyPolicy.defaultRedirectUri,
            code: code,
            verifier: pkce.verifier,
          );
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      await ref.read(spotifyTokenStoreProvider).write(profile.id, tokens);
      await ref
          .read(repositoriesProvider)
          .integrations
          .setConsentEnabled(
            profileId: profile.id,
            kind: IntegrationKind.spotify,
            enabled: true,
          );
      ref.invalidate(integrationConsentsProvider);
    });
  }

  Future<MusicAtlasJsonImportResult?> pullSpotifyLibrary() {
    return _run(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      final consent = ref.read(spotifyConsentProvider);
      if (consent == null || !consent.enabled) {
        throw StateError(AppStrings.musicAtlasSpotifyNeedConsent);
      }
      var tokens = await ref.read(spotifyTokenStoreProvider).read(profile.id);
      if (tokens == null) {
        throw StateError('Liga a conta Spotify primeiro.');
      }
      final catalog = ref.read(spotifyCatalogPortProvider);
      if (tokens.isExpiredAt(DateTime.now().toUtc())) {
        tokens = await catalog.refresh(
          clientId: ref.read(spotifyClientIdProvider),
          current: tokens,
        );
        await ref.read(spotifyTokenStoreProvider).write(profile.id, tokens);
      }
      final probe = await catalog.probe(
        tokens: tokens,
        scope: MusicSpotifyPolicy.libraryScope,
        now: DateTime.now().toUtc(),
      );
      if (!probe.available) {
        await ref
            .read(repositoriesProvider)
            .musicAtlas
            .upsertSpotifySync(
              MusicSpotifySyncState(
                profileId: profile.id,
                consentId: consent.id,
                capabilityProbeJson: MusicSpotifyPolicy.capabilityProbeJson([
                  probe,
                ]),
                lastError: 'HTTP ${probe.httpStatus}',
                updatedAt: DateTime.now().toUtc(),
              ),
            );
        throw StateError(
          'Spotify indisponível (HTTP ${probe.httpStatus}). Development Mode?',
        );
      }
      final albums = await catalog.listSavedAlbums(tokens);
      final result = await ref
          .read(repositoriesProvider)
          .musicAtlas
          .importSpotifyLibrary(
            profileId: profile.id,
            albums: albums,
            consentId: consent.id,
          );
      ref.invalidate(musicAtlasOverviewProvider);
      ref.invalidate(musicSpotifyConstellationProvider);
      ref.invalidate(musicExplorationProvider);
      return result;
    });
  }

  Future<MusicEncounter?> captureNowPlaying({int? resonance, String? note}) {
    return _run(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      final tokens = await ref.read(spotifyTokenStoreProvider).read(profile.id);
      if (tokens == null) {
        throw StateError('Liga o Spotify para capturar o que está a tocar.');
      }
      final playing = await ref
          .read(spotifyCatalogPortProvider)
          .currentlyPlaying(tokens);
      if (playing == null) {
        throw StateError('Nada a tocar no Spotify.');
      }
      final encounter = await ref
          .read(repositoriesProvider)
          .musicAtlas
          .captureNowPlaying(
            profileId: profile.id,
            playing: playing,
            resonance: resonance,
            note: note,
          );
      ref.invalidate(musicAtlasOverviewProvider);
      return encounter;
    });
  }

  Future<List<SpotifyPlaylistSummary>> listPlaylists() {
    return _run(() async {
      final tokens = await _readyTokens();
      return ref.read(spotifyCatalogPortProvider).listPlaylists(tokens);
    }).then((value) => value ?? const []);
  }

  Future<MusicExpedition?> draftFromPlaylist(SpotifyPlaylistSummary playlist) {
    return _run(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      var summary = playlist;
      if (summary.tracks.isEmpty) {
        final tokens = await _readyTokens();
        final tracks = await ref
            .read(spotifyCatalogPortProvider)
            .listPlaylistTracks(tokens, playlist.spotifyId);
        summary = SpotifyPlaylistSummary(
          spotifyId: playlist.spotifyId,
          name: playlist.name,
          trackCount: tracks.length,
          snapshotId: playlist.snapshotId,
          externalUrl: playlist.externalUrl,
          tracks: tracks,
        );
      }
      final expedition = await ref
          .read(repositoriesProvider)
          .musicAtlas
          .draftExpeditionFromPlaylist(
            profileId: profile.id,
            playlist: summary,
          );
      ref.invalidate(musicAtlasOverviewProvider);
      return expedition;
    });
  }

  Future<SpotifyTokenSet> _readyTokens() async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) throw StateError('Perfil não configurado');
    var tokens = await ref.read(spotifyTokenStoreProvider).read(profile.id);
    if (tokens == null) {
      throw StateError(AppStrings.musicAtlasSpotifyNeedConnect);
    }
    if (tokens.isExpiredAt(DateTime.now().toUtc())) {
      tokens = await ref
          .read(spotifyCatalogPortProvider)
          .refresh(
            clientId: ref.read(spotifyClientIdProvider),
            current: tokens,
          );
      await ref.read(spotifyTokenStoreProvider).write(profile.id, tokens);
    }
    return tokens;
  }
}

class _PkceNotifier extends Notifier<SpotifyPkceChallenge?> {
  @override
  SpotifyPkceChallenge? build() => null;

  void set(SpotifyPkceChallenge? value) => state = value;
}

final _pkceProvider =
    NotifierProvider<_PkceNotifier, SpotifyPkceChallenge?>(_PkceNotifier.new);

final musicAtlasControllerProvider =
    AsyncNotifierProvider<MusicAtlasController, void>(MusicAtlasController.new);
