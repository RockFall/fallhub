# ADR-034: Maturidade Phase 12 — spike

## Status
Aceito (Iter 89 spike — doc-only; slices produto →91+)

## Contexto
Spec §45 Phase 12 lista: desktop polish, performance, accessibility audit, security review, clinical review for health alerts, legal/privacy preparation, localization, beta migration guarantees. Fases 0–11 têm MVP utilizável offline (ICS stub + NarrativeDigest rules). Phase 12 não introduz domínio de negócio novo — endurece qualidade, garantia e preparação de beta.

## Decisão (spike — sem código produto nesta iter)

### Princípios (IN)
1. **Android-first permanece** — desktop polish é incremental, não fork
2. **Local-first** — maturity não exige cloud; sync remote continua defer
3. **Saúde não diagnostica; finanças não executam** — reviews clínicos/legais são processo, não features que fingem certificação
4. **Garantias de migration/export** — documentar + testar; não reescrever histórico
5. **A11y e strings** — gaps DoD (§50) antes de polish cosmético

### Escopo OUT (defer explícito)
- Certificação clínica formal / parecer médico
- Auditoria legal externa / LGPD formal
- Desktop packaging (MSIX/DMG) como prioridade
- Performance profiling contínuo em CI (só smoke local)
- Rewrite de navegação / redesign visual

### 1ª slice produto sugerida (pós-ADR)
**Accessibility + DoD gaps lite:**
1. Semantics / labels em hubs críticos (Settings integrations, Sync, NarrativeDigest sheet, Zones)
2. Checklist doc `docs/dev/A11Y_BASELINE.md` (manual) + 1–2 asserts semânticos em widget tests
3. Sem migration

### Alternativa P1
**Export/migration beta guarantee note:**
1. Documento `docs/dev/BETA_MIGRATION_GUARANTEES.md` — versões suportadas, política wipe-on-restore, testes golden
2. Opcional: smoke test que migra fixture v1→atual

### Critérios de aceite da 1ª slice
1. Checklist a11y baseline versionado
2. Pelo menos uma tela Phase 10/11 com Semantics/label verificável em teste
3. Strings localizadas; zero regressão no `test_all`

### Ordem recomendada
1. Pit 90 recalcula
2. A11y baseline + Semantics lite **ou** beta migration doc
3. Localization completeness pass
4. Performance smoke só se gate degradar

## Consequências
- Phase 12 tem ADR antes de “polish infinito”
- Critério de terminação do motor: Phase 12 MVP = ADR + 1 slice a11y/DoD utilizável
- Clinical/legal reviews permanecem fora do loop de código
