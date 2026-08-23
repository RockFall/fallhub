# ADR-ACT-004: retenção de sinais brutos

## Status
Aceito

## Contexto
Passos, uso de apps e localização são classe sensível. Guardar indefinidamente cria vigilância.

## Decisão
`InertiaSignal.expiresAt` é obrigatório para sinais de alta sensibilidade. `expireSignals` apaga expirados. Export de episódios não inclui sinais brutos nem `rawReference` de provas. Localização, quando existir, é zona — não coordenada.

## Consequências
Eventos derivados (episódio iniciado/liberado) têm retenção longa; o bruto some.
