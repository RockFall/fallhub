# ADR-ACT-012: consentimento de resgate social

## Status
Aceito

## Contexto
Contatar terceiros sob inércia é invasivo e pode vazar estado.

## Decisão
`RescueContract` guarda rótulo + template. `requiresConfirmation` é sempre verdadeiro no MVP. O app não envia mensagem. Contato não recebe detalhes do episódio.

## Consequências
Resgate social é contrato visível, nunca side-effect silencioso.
