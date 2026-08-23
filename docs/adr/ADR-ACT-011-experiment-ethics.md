# ADR-ACT-011: ética dos experimentos N-of-1

## Status
Aceito

## Contexto
Comparar variantes de rota pode parecer um ranking da pessoa.

## Decisão
Experimentos são locais, opt-in, com amostra mínima. Insights usam `ActivationInsight.causalityDisclaimer`. Sem bandit contextual nesta fatia. Sem publicação, sem sync do resultado.

## Consequências
O sistema pode sugerir comprimir uma rota; nunca diz que o usuário “piorou”.
