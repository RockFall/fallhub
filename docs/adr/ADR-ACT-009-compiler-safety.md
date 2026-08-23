# ADR-ACT-009: segurança do compilador de rota

## Status
Aceito

## Contexto
IA generativa pode produzir comandos morais, inseguros ou impossíveis.

## Decisão
`ActivationCommandGrammar` rejeita fragmentos proibidos e verbos abstratos. Seeds e o assistente local só emitem instruções concretas. Comandos gerados (quando existirem) precisam passar na gramática antes de persistir. Sem LLM nesta fatia.

## Consequências
“Seja produtivo” nunca chega à tela ativa.
