# ADR-052: Cofrinho diário

## Status
Aceito

## Contexto
O ledger manual (ADR-020) e o leitor de notificações do Inter (ADR-011) já transformam pushes em `LedgerTransaction`, com dedupe por `nativeKey` (`fingerprint = notif:<nativeKey>`). Faltava um orçamento diário que acumula e aparece na tela inicial do Android, inclusive com o app fechado.

## Decisão
O cofrinho é um derivado do ledger. Não há um segundo detector de gastos.

- Config por perfil: `valorDiario` (padrão R$ 90,00), `dataInicio` (padrão o dia civil de São Paulo), `dataFim` opcional, categorias excluídas, flag de parcelado e aviso ao ficar negativo.
- Fuso America/Sao_Paulo (UTC−3, sem horário de verão).
- `saldo = valorDiario × diasDecorridosInclusiveHoje − somaDespesasElegiveis`.
- `disponivelHoje = saldo`. Saldo negativo é dívida (`diasDeDivida = ceil(-saldo / valorDiario)`).
- Com `dataFim`, `ritmoNecessario = (valorDiario × diasRestantes + saldo) / diasRestantes`, em que `diasRestantes` são os dias civis depois de hoje até a data fim, inclusive. Depois da data fim o período congela.
- Status: verde se `saldo ≥ valorDiario × 0,2`, amarelo se `0 ≤ saldo` abaixo do limiar, vermelho se `saldo < 0`.
- Entram saídas do ledger (notificação ou lançamento manual). Ficam de fora: flag do usuário, categorias marcadas e textos fixos (condomínio, PHI, Claro, assinatura, pagamento de fatura, transferência entre contas). Estorno/reembolso de algo elegível devolve o valor. Estorno de item fixo não entra.
- Dedupe: fingerprint do pipeline (`notif:<nativeKey>` ou hash). Compras importadas (`notif:` / `ofx:`) com o mesmo dia, valor e comerciante colapsam. Uma notificação de pagamento sem favorecido, no mesmo dia e valor de uma compra, não conta de novo.
- Parcelado: o extrator existente (`FinanceNotificationExtractor.installmentPlan`) distingue "3x de R$" (parcela) de "R$ em 3x" (total). Por padrão o cofrinho conta o total no dia da compra; a config pode contar só a parcela.
- Correção de valor e "fora do cofrinho" ficam numa tabela de override e não reescrevem o fingerprint do ledger.
- Widget Android 2×1 / 4×2 lê um snapshot em `HomeWidgetPreferences` (saldo, gasto de hoje, disponível, status, últimos 7 dias). Toque abre `colony://piggy`.
- Atualização: ao abrir ou voltar o app; no próximo midnight de São Paulo (alarme + timer); e, com o app fechado, o `NotificationListenerService` só acorda um `WorkManager` que sobe o entrypoint Dart `piggyBankHeadless`. Esse isolate drena o inbox e chama o ingest já existente. O Kotlin não interpreta valor de compra.
- Aviso local opcional quando o status entra no vermelho vindo de outro status.

Persistência: DB v46, tabelas `piggy_bank_configs` e `piggy_bank_overrides`. O backup SQLite (ADR-051) leva as tabelas junto. O export JSON curado não as lista.

## Consequências
- O widget depende do processo Flutter headless para classificar o push. O atraso é o tempo de subir o isolate, não um parser paralelo.
- Dois cafés manuais iguais no mesmo dia continuam distintos. Dois pushes importados do mesmo comerciante, valor e dia contam uma vez.
- Finanças continuam sem executar operações. O cofrinho não recomenda investimentos.
