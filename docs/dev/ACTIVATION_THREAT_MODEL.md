# Motor de Ignição — privacidade e threat model

Complementa ADR-ACT-004, ADR-ACT-010, ADR-ACT-012 e a spec 03 §74.

## Classes de dado

| Classe | Exemplos | Destino |
|---|---|---|
| standard | protocolo, comando, status do episódio | export e sync futuros |
| sensitive | uso de apps, rotina inferida | local; expiração |
| highly_sensitive | saúde, contato de resgate, zona residencial | local; redaction |
| secret | tokens de waypoint, HA, FamilyControls | nunca exportar |

## Ameaças e mitigações

- Rotina domiciliar: guardar “waypoint banheiro atingido”, não RSSI contínuo.
- Horários de ausência: export omite coordenadas e tokens.
- Uso de apps: shield MVP é `policyOnly`; sem Usage Access obrigatório.
- Contato social: o núcleo nunca transmite; contrato fica local.
- Automação residencial: só dry-run até consentimento + allowlist.
- Lockout: escape sem justificativa; allowlist emergência/auth/mapas/médico.
- Outra pessoa no aparelho: eventos auditáveis; sem justificativa moral.

## Analytics

Não há score de disciplina, streak ou funil de “falha”. Métricas norte: latência até primeiro movimento, taxa de escape, correção de falso positivo.
