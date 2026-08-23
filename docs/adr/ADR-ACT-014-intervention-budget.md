# ADR-ACT-014: orçamento de intervenção

## Status
Aceito

## Contexto
Cartas e notificações de transição competem com o Storyteller e a agenda.

## Decisão
`ActivationInterventionPolicy.dailyBudget = 6`. A escada sobe só após timeout/ignorado e desce após confirmação. Auto-start exige janela + ausência de descanso planejado + confiança média.

## Consequências
O Storyteller não cria crises de mobilização. Uma carta de transição conta no budget.
