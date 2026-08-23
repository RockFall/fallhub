# ADR-ACT-003: aggregação de confiança da prova

## Status
Aceito

## Contexto
Vários sinais (toque, QR, passos) podem confirmar o mesmo comando. Média simples com outliers mente.

## Decisão
`ActivationProofEngine` agrega por mediana. Bandas: alta ≥ 0.8, média ≥ 0.5, baixa ≥ 0.25. A confiança é da evidência, nunca da pessoa. Override manual sempre confirma.

## Consequências
Detecção conservadora: sem prova suficiente o comando fica `uncertain` e pede um gesto, sem acusar o usuário.
