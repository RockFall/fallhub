# ADR-033: Storyteller / IA Phase 11 — spike local-first

## Status
Aceito (Iter 84 spike — doc-only; NarrativeDigest rules_v1 Iter 87)

## Contexto
Spec §45 Phase 11: local rules first, RAG interno, structured responses, tool confirmations, narrative reviews, privacy modes. Spec enfatiza explicabilidade e confirmação de ferramentas. O app já tem crônica (domain events), daily/weekly review, quests e sync stub. **Nenhum** modelo remoto ou on-device LLM está integrado.

## Decisão (spike — sem código produto nesta iter)

### Princípios (IN)
1. **Rules first** — heurísticas determinísticas antes de qualquer LLM
2. **Privacy modes** — default: tudo local; cloud opt-in futuro com disclaimer
3. **Tool confirmations** — IA nunca muta sem confirmação explícita do usuário
4. **Structured outputs** — respostas tipadas (JSON schema / sealed classes), não prosa livre como fonte de verdade
5. **Proveniência** — sugestões carregam evidências (event ids, entidades)

### Escopo OUT (defer explícito)
- Chamadas a APIs de LLM remotas
- Treino/fine-tune on-device
- Storyteller que imita RimWorld / cópia de narrativa de jogos
- Auto-aplicar mudanças em saúde/finanças/decisões
- RAG com embeddings cloud

### 1ª slice produto sugerida (pós-ADR)
**Narrative review lite (rules-only):**
1. Domínio: `NarrativeDigest` (period, bullets[], evidenceEventIds[], generatedAt, generator: `rules_v1`)
2. Input: domain events + daily/weekly reviews da janela
3. Output: 3–7 bullets localizados (templates), sem LLM
4. UI: botão em Weekly review / Crônica “Resumo da semana (regras locais)”
5. Sem migration pesada se digest for efêmero; se persistir → export bump

### Critérios de aceite da 1ª slice
1. Gerar digest offline a partir de eventos locais
2. Mostrar evidências clicáveis / ids
3. Disclaimer: regras locais; não é conselho médico/financeiro
4. Zero rede; strings localizadas

### Ordem recomendada
1. Fechar ICS/integrations stub se P0
2. NarrativeDigest rules_v1
3. Só então avaliar on-device LLM com ADR dedicado de privacy

## Consequências
- Phase 11 tem ADR antes de dependências de modelo
- Alinha “local rules first” da spec
- Não bloqueia Phase 12 maturity ADR futuro
