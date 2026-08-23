# ADR-ACT-002: protocolo versionado vs Tasks

## Status
Aceito

## Contexto
Tasks já existem como ações do dia. Duplicar rotinas em uma segunda lista criaria dois sistemas de trabalho.

## Decisão
`ActivationProtocol` é um programa versionado de transição, não uma Task. Comandos podem apontar `opensTaskId` / `deepLink` para a primeira ação significativa. Alterar um protocolo cria versão nova; episódios antigos conservam a versão usada. Tasks não ganharam colunas nesta fatia — o vínculo vive no protocolo/episódio.

## Consequências
O motor de prioridades continua escolhendo o trabalho; o Motor de Ignição só conduz a entrada.
