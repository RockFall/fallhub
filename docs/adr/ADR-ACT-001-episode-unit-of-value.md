# ADR-ACT-001: ActivationEpisode como unidade de valor

## Status
Aceito

## Contexto
A spec 03 define que o valor do Motor de Ignição não é “registrar o hábito”, e sim atravessar a transição atual. Habit trackers e streaks empurram input depois da ação e criam dívida moral.

## Decisão
A unidade persistida e narrada é `ActivationEpisode`. Sucesso = `released` ou `convertedToRecovery`. Completar todos os passos não é obrigatório. Não existe score de disciplina, streak ou “dias cumpridos”.

## Consequências
Crônica e export falam de episódios, não de adesão. Insights são associativos e locais.
