# ADR-049: Linguagem visual Fallhub Terminal

## Status
Aceito

## Contexto
A home (ADR-044) e o chrome (tokens amostrados de atlases de gestão de colônia) não correspondem à direção de produto fechada pelo designer: um **terminal civil pixelado**, industrial, com painéis rebitados, latão, cobre e ciano funcional.

A spec §0.1 e o ADR-012 continuam a valer: não copiar assets, tipografia, cromo ou layout de terceiros. A referência de UI em `docs/produto/assets/reference/ui_references/fallhub_ref_main_page.png` é original do produto.

## Decisão
1. **Identidade:** “Fallhub Terminal” — painel de estação remota em pixel art, paleta grafite/latão/ciano, rebites nos cantos, botões de cobre em relevo. Não é HUD militar neon nem dashboard corporativo.
2. **Tipografia de chrome:** Pixelify Sans (OFL). Arimo/Carlito permanecem como família legível para texto longo se necessário.
3. **Home móvel:** data + pawn (pips de descanso/humor) + agenda compacta do dia + trabalho de hoje + grelha 3×2 (Perfil, Missões, Saúde, Finanças, Habitat, Crônica). Programas restantes ficam no menu Mais / hamburger. Sem barra de título genérica em `/colony`.
4. **Kit:** sprites, 9-slices, textura e retrato padrão em `packages/colony_design_system/assets/ui/terminal/`, gerados por `tool/generate_fallhub_terminal_assets.py`. Ícones futuros já vivem nessa pasta. Escala com `FilterQuality.none`.
5. **Componentes:** `ColonyFrame`, `ColonyPixelIcon`, `ColonyPipMeter`, `ColonyAgendaRail`, `ColonyWorkRow`, `ColonyNavTile`, `ColonyDateHeader`, `ColonyPawnBanner` — o mesmo cromo serve o restante do app via `ColonySurface` / `ColonyButton` / tabs.
6. **Dados:** a agenda preenche lacunas visuais como “Livre” (não persiste). Saúde não diagnostica; finanças não mostram valores.

## Consequências
- ADR-044: a grelha 4 colunas estilo launcher deixa de ser a home primária; o catálogo de mini-programas permanece atrás de Mais.
- Golden/widget tests da home passam a afirmar o terminal, não “Programas”.
- Regenerar o kit: `python3 tool/generate_fallhub_terminal_assets.py`.
