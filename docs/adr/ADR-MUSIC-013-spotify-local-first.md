# ADR-MUSIC-013: Spotify local-first (sem playback)

## Status
Aceito

## Contexto
O Atlas Musical precisa de um canal para *contactos* (álbuns gravados, o que está a tocar, playlists). A spec §75 e MUSIC-013 proíbem SDK de playback, letras protegidas e tokens no export. O Colony continua útil offline; Spotify é opt-in.

## Decisão

1. **Portas no domínio** — `SpotifyCatalogPort` e `SpotifyTokenStore`. HTTP e PKCE SHA-256 ficam na app (`HttpSpotifyCatalog`). Testes usam `FakeSpotifyCatalog` + `MemorySpotifyTokenStore`.
2. **Tokens** — `PrefsSpotifyTokenStore` (SharedPreferences do dispositivo). Nunca Drift, nunca `ExportSnapshot`. Revogar o opt-in limpa tokens e o estado de sync.
3. **Consentimento** — `IntegrationKind.spotify`, mesmo ritual do ICS. Client ID é público (Development Mode); o utilizador cola o URI/código de retorno (`colony://integrations/spotify/callback`).
4. **Semântica** — biblioteca gravada = `Encounter(contact)` + estado `rumor`. Nunca `cartographed`. Constelação parte em: atento+gravado / gravado sem encontro / só local.
5. **Schema** — Drift v40 (`music_*` + `music_spotify_sync_state` sem tokens). Export v35 inclui nós/encontros/claims/expedições/runs e **não** inclui tokens nem sync secrets.
6. **Fora** — Apple Music, playback SDK, Web Playback, lyrics, LLM no dispositivo.

## Consequências
O calendário Google (docs ADR-043) passa a prever o *próximo* bump livre (Drift v41 / export v36), não o v40/v35 já usado pelo Atlas.
