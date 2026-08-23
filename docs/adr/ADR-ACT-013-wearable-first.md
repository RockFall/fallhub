# ADR-ACT-013: execução wearable-first

## Status
Aceito (capacidade descrita)

## Contexto
A spec quer rotas phone-free (relógio). Wear OS / watchOS exigem apps nativos.

## Decisão
O domínio já trata um comando por vez, curto o bastante para watch. Sem app de relógio nesta fatia. `ActivationPlatformCapability.watchCommands` permanece falso até existir extensão.

## Consequências
A UI mobile não promete “complete pelo relógio” enquanto a capacidade for falsa.
