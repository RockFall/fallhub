# ADR-MUSIC-015: Ontologia canónica multi-eixo do Atlas

## Status
Aceito

## Contexto
A primeira cartografia tratava territórios como uma árvore única (`Música > Rock > Progressive Rock > Canterbury`). Isso produz erros: género, tradição, movimento, cena, técnica e função não são a mesma coisa. Discogs separa genres de styles; AllMusic distingue genres e styles; MusicBrainz trata género como tag subjectiva e extensível.

Não havia dados reais de utilizador a preservar. Vale o estado ideal.

## Decisão

1. **Onze eixos** — `genre`, `tradition`, `scene`, `movement`, `form`, `function`, `technique`, `descriptor`, `geography`, `era`, `concept`. Um álbum vive em vários ao mesmo tempo.
2. **Vinte e seis famílias de género** — `western_art` … `southeast_asian`. Brasileiro, africano, MENA e ásia são famílias-tradição no mapa, não equivalentes ontológicos a Jazz ou Metal; o eixo `tradition` guarda essa distinção.
3. **Categorias funcionais** (Stage & Screen, jogos, library, spoken word) **não** são géneros-mãe.
4. **Polihierarquia** — `parentKeys` + `secondaryParentKeys` (Blackgaze → Metal e Shoegaze).
5. **Grafo semântico** — `derivedFrom`, `influencedBy`, `fusedWith`, `siblingOf`, `historicallyPrecedes`, `regionalVariantOf`, `revivalOf`, `sceneAssociatedWith`, `movementAssociatedWith`, `commonlyOverlaps`.
6. **Proibidos como raiz** — World Music, Progressive sozinho, moods, lo-fi, fusion como pai universal, MPB como pai de toda a música brasileira.
7. **Mapa** — só rios de género; a árvore profunda não se desenha toda: raízes + caminhos explorados + filhos do poço aberto.
8. **Fonte** — `MusicCanon` / `MusicTaxon` em `colony_domain`, gerados por `tool/generate_music_canon.py`. Long tail cresce sem partir as 26 raízes.
9. **Picker** — `MusicGenreAtlas.searchAssignable`: vazio = 26 raízes; texto = todos os eixos.

## Consequências
Chaves antigas (`br.mpb`, `rock.postpunk`) ficam como *aliases*. Dump Spotify e JSON passam a resolver contra o cânone. A spec §12 e §81 passam a ser a norma.
