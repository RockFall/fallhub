# ADR-011: Financial imports / Inter local

## Status
Aceito — estratégia final (ago/2026). Pesquisa em [`docs/dev/INTER_BANKING_INTEGRATION.md`](../dev/INTER_BANKING_INTEGRATION.md).

## Contexto
O Inter PF não tem API de extrato/fatura. Open Finance “um toque” (Pierre) exige ser receptora regulada ou pagar agregador; sync não é instantâneo. Exportar arquivo **toda vez** esvazia o produto.

## Decisão

**Importação de arquivo uma vez + leitor de notificações Android para o contínuo.**

```text
histórico:  OFX / CSV Inter  → preview/apply (fingerprint)
novos:     NotificationListenerService → extrator de gastos → ledger
futuro:    o mesmo inbox de notificações alimenta outros módulos
```

Porta estável:

```dart
abstract interface class BankConnector {
  Future<List<FinancialAccount>> accounts();
  Future<List<LedgerTransaction>> transactions();
  Stream<FinanceSpendCandidate> liveTransactions();
}
```

Hoje: `InterLocalConnector` (arquivo + notificações). Open Finance/Pluggy só se o produto virar comercial.

### Leitor de notificações (sistema)

- Opt-in no app **e** permissão do Android (ajustes do sistema). Texto de setup explícito.
- Captura **todas** as notificações no dispositivo (exceto contínuas/OTP/próprio app), só local.
- Pipeline de extratores; o de **finanças** já grava débito e crédito.
- Revogar não apaga histórico do ledger. Raw das notificações não vai para a nuvem.

### IN

- Dedup por fingerprint; pagamento duplicado no OFX posterior é no-op.
- Finanças não executam operações.
- Contas Inter Conta / Inter Cartão criadas sob demanda.
- iOS: só arquivo nesta fatia.

### OUT

- Pluggy/Belvo/Meu Pluggy como estratégia deste app.
- Scrape, API privada, Accessibility no Super App.
- Homologar Colony no Open Finance.

## Consequências

- 1ª slice de código: importador Inter + listener Android + extrator de gastos + UI de setup.
- `IntegrationKind.notificationListener`; tabela local de notificações capturadas.
- Atraso zero nos pushes; furos se o Inter não notificar — corrigível com novo OFX.
