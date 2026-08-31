# ADR-044: Home como launcher de mini-programas

## Status
Aceito

## Contexto
A tela Colônia (§9) era uma coluna de `ColonyPanel` com um “mapa operacional” de seis botões. O mapa da spec é um painel de setores (saúde, trabalho, finanças, casa, relações, viagens, inbox…), não um dashboard de vanity metrics. A navegação secundária vivia escondida no menu Mais.

Queremos uma superfície de primeiro nível no estilo de super-app (referência de *layout*: grelha de mini-programas), sem copiar chrome, marca ou ícones de Alipay/RimWorld (spec §0.1, ADR-012).

## Decisão
1. **Launcher:** atalhos primários (check-in, estudar, inbox, habitat) + grelha 4 colunas dos destinos reais do app. Oito programas fixos; o resto atrás de “Mais”.
2. **Ícones:** tiles coloridos originais (assets gerados + fallback Material). Paleta em `ColonyMiniAppColors`; raios `ColonyRadii.tile` / `soft` só no launcher, sem 9-slice RimWorld.
3. **Feed abaixo:** widgets operacionais da spec §9.3 (Agora, 24h, estado da colônia, missões, próximas ações, lembrete de saúde, inbox, CTA do digest de regras). Sem score único. Saúde não diagnostica; finanças não mostram valores por omissão.
4. **Camadas:** widgets visuais em `colony_design_system`; catálogo de rotas em `lib/features/colony`. Sem SQL na UI.

## Alternativas rejeitadas
- Manter só o mapa 2×3 de botões outlined.
- Copiar grelha/ícones de Alipay ou atlases RimWorld.
- Teto de programas no menu Mais como única navegação.

## Consequências
- A home móvel passou a ser o **Fallhub Terminal** (ADR-049): pawn + agenda + trabalho + grelha 3×2. O catálogo de mini-programas permanece no menu Mais / hamburger.
- Testes da home afirmam o terminal (nome do pawn, agenda, grelha), não o texto “Programas”.
