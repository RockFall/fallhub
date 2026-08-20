# Integração Banco Inter

Decisão final (ago/2026). ADR: [`docs/adr/ADR-011-financial-imports-open-finance.md`](../adr/ADR-011-financial-imports-open-finance.md).

## O que o app faz

1. **Uma vez:** você importa o extrato/fatura que o Inter já exporta (OFX, CSV ou PDF-CSV da conta; PDF da fatura se houver CSV). Até 2 anos de história.
2. **Para sempre:** o Colony lê as **notificações do Android** (com permissão explícita), extrai compras de débito e crédito no instante do push, e grava no ledger local.
3. **Leitor de notificações** não é só banco: guarda o que chegou (localmente) e corre extratores. Nesta fatia o extrator de **gastos** já funciona; os outros módulos entram depois na mesma fila.

Sem servidor, sem Pluggy, sem API PJ, sem scrape do Super App. O Colony **não paga** fatura nem faz Pix.

## Por que não o botão mágico do Pierre

O Pierre é instituição de pagamento: o Inter autoriza **eles**. Um app pessoal não pode chamar Open Finance sozinho. Agregador comercial custa mensalidade e não é instantâneo (horas). API Inter é só PJ e não tem fatura PF.

## Setup (fácil, no app)

**Histórico (Finanças → Importar):**

1. No Super App Inter: Saldo → período → exportar → e-mail (PDF/CSV/OFX). Para cartão: fatura fechada → exportar o que o app oferecer.
2. No Colony: colar ou escolher o arquivo, **escolher a conta destino**, Analisar → Aplicar. Reimportar o mesmo arquivo não duplica.

**Novos gastos (Integrações → Leitor de notificações):**

1. Leia o aviso: o Colony passa a ver **todas** as notificações do celular, só neste aparelho, para extrair gastos agora e outros sinais depois. Dá para desligar. Códigos de verificação são ignorados.
2. Ative o interruptor no Colony.
3. Toque **Abrir ajustes do Android** → ative **Colônia** na lista “acesso a notificações”.
4. Volte. Os dois passos (app + sistema) precisam estar verdes.
5. Faça uma compra de teste: o push do Inter deve virar lançamento em segundos.

iOS: só importação de arquivo nesta fatia (o SO não tem listener equivalente estável).

## Como funciona depois

```
Inter (push) → Android NotificationListener → fila local
      → extratores (finanças agora; outros depois)
      → ledger Drift (dedup por fingerprint)
```

- Compra no cartão → conta `creditCard` (Inter Cartão, criada se faltar).
- Pix/débito/TED → conta `checking` (Inter Conta).
- Mesmo gasto no extrato importado depois = ignorado (fingerprint).
- Sem notificação (não chegou push) = furo até o próximo OFX/CSV.

## Fora

Open Finance/Pluggy como caminho deste produto. Scraping. API privada do Super App. Accessibility para abrir o Inter. IMAP/Gmail nesta fatia.

## Aceite

- Importar OFX ou CSV Inter uma vez preenche o passado, com preview e sem duplicata.
- Com leitor ligado, compra no débito ou crédito vira lançamento sem abrir o Super App de novo.
- Setup com texto claro, empty/loading/erro, opt-in revogável, strings localizadas.
- Desligar o leitor não apaga o ledger.
