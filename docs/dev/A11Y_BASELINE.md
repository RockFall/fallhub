# Accessibility baseline — Life Colony OS (ADR-034)

Checklist manual + asserts de Semantics em testes. Android-first; não substitui auditoria formal.

**Última atualização:** Iter 91

## Princípios

1. Ações primárias têm label semântico em português
2. Disclaimers de saúde/finanças/IA permanecem legíveis (não só cor)
3. Empty/loading/error states anunciáveis
4. Sem depender só de ícone sem texto

## Hubs cobertos (MVP Iter 91)

| Superfície | Semantics / identifier | Teste |
|------------|------------------------|-------|
| `/settings/integrations` | `integrations.screen`, `integrations.import_ics` | `integrations_screen_test` |
| NarrativeDigest sheet | `narrative_digest.sheet`, `.disclaimer` | `narrative_digest_sheet_test` |
| `/settings/sync` | `sync.screen`, `sync.process_local` | `sync_status_screen_test` |

Widget tests assert texto visível + presença de `Semantics` (identifiers para TalkBack).

## Checklist manual (smoke)

- [ ] TalkBack: Settings → Integrações — ouve título e estado do switch
- [ ] TalkBack: Resumo da semana — ouve disclaimer de regras locais
- [ ] Contraste: texto disclaimer legível no tema dark do DS
- [ ] Foco: botões Importar/Colar alcançáveis sem gesto obscuro

## Fora de escopo (defer)

- Auditoria WCAG completa
- Desktop keyboard map completo
- Dynamic type stress em todas as telas
- Clinical/legal review

## Próximos

Ver `META_REVIEW_ITER90.md` backlog Iter 92+.
