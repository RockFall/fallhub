# Privacy / legal prep stub — Phase 12 (Iter 103)

Rascunho **não jurídico**. Preparação para beta local-first; não substitui assessoria legal.

## Princípios do produto (já no código)

| Tema | Postura |
|------|---------|
| Conta | Não obrigatória; app útil offline |
| Dados | Locais (Drift); export JSON pelo usuário |
| Saúde | Registro pessoal; **não diagnostica** |
| Finanças | Ledger manual; **não executa** operações bancárias |
| IA | Regras locais (`rules_v1`); **sem LLM remoto** nesta fatia |
| Integrações | Opt-in ICS somente leitura; sem write-back SO |
| Sync | Outbox local stub; remote/E2EE **defer** |

## Textos de UI a manter

- Disclaimers em Health, Finance, Integrations, Sync, NarrativeDigest
- Consentimento explícito antes de import ICS
- Restore = full-replace com confirmação dupla

## Pendências formais (fora do MVP código)

1. Política de privacidade hospedada (URL)
2. Termos de uso / EULA loja
3. Textos de loja (Play) sobre dados sensíveis
4. Avaliação DPIA se sync remoto for ativado
5. Certificação clínica: **explicitamente fora** (ADR-034)

## Próximo passo produto

Quando sync remoto ou Health Connect entrarem no roadmap, abrir ADR + seção legal dedicada **antes** do código de rede.
