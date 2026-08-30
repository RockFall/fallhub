# Fallhub Terminal — kit gráfico

Identidade visual original do chrome (ADR-049). Não copiar RimWorld nem Fallout.

## Pastas de runtime

`packages/colony_design_system/assets/ui/terminal/`

| Pasta | Uso |
|-------|-----|
| `icons/` | Sprites 48×48 (16×16 ×3). `*_mono.png` para tintar (tabs). |
| `chrome/` | Painel rebitado, botão cobre, inset. |
| `portraits/` | Retrato padrão do pawn. |
| `textures/` | Grain metálico tileable. |
| `catalog/` | Folha de ícones para revisão. |

Regenerar:

```bash
python3 tool/generate_fallhub_terminal_assets.py
```

Ícones já previstos para telas futuras (pesquisa, inventário, viagens, sync, etc.) estão no mesmo diretório — usar `ColonyGfx.icon('research')` em vez de Material Icons.
