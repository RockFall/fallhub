import 'package:app_links/app_links.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routing/app_router.dart';
import 'music_atlas_controllers.dart';

/// Completes PKCE when Spotify returns to colony://integrations/spotify/callback.
final spotifyDeepLinkRuntimeProvider = Provider<void>((ref) {
  if (kIsWeb) return;
  late final AppLinks links;
  try {
    links = AppLinks();
  } catch (_) {
    return;
  }

  Future<void> handle(Uri uri) async {
    if (!MusicSpotifyPolicy.isCallbackUri(uri)) return;
    try {
      await ref
          .read(musicAtlasControllerProvider.notifier)
          .completeSpotifyAuth(uri.toString());
      ref.read(routerProvider).go('/settings/integrations');
    } catch (_) {
      // The integrations panel reads controller error state.
    }
  }

  try {
    links.getInitialLink().then((uri) {
      if (uri != null) handle(uri);
    }).ignore();
    final sub = links.uriLinkStream.listen(handle);
    ref.onDispose(sub.cancel);
  } catch (_) {
    // Tests and desktop hosts without a plugin channel stay usable.
  }
});
