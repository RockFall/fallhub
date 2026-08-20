# ADR-011: Financial imports / Open Finance

## Status
Aceito (spike — pesquisa Inter revisada ago/2026; sem código de produto nesta iter)

Pesquisa: [`docs/dev/INTER_BANKING_INTEGRATION.md`](../dev/INTER_BANKING_INTEGRATION.md).

## Contexto
Spec §23.9 pede `BankingDataProvider`: arquivos na fase inicial, parceiro regulado depois. O ledger MVP (ADR-020) é manual. O pedido de produto é Inter **PF**, débito **e** crédito, histórico e fatura aberta, **automático** — exportar OFX toda vez esvazia o sentido.

Pesquisa revisada:

1. API Inter Empresas = só PJ, 90 dias, sem fatura. Fora.
2. Super App exporta conta em OFX/CSV (até 2 anos) sob demanda; **CSV de fatura foi removido**; PDF mensal por e-mail não captura compra do dia.
3. Open Finance comercial (Pluggy/Belvo como produto) custa piso de agregador e exige backend multi-tenant.
4. **Meu Pluggy (conector `200`)** é o caminho pessoal que a própria Pluggy documenta: grátis, sem prazo, refresh diário da conexão Inter, API com `CLIENT_ID`/`SECRET` de uma Development Application. Conectar o banco “Inter” direto no dashboard **pausa após o trial**. Apps pessoais já fazem isso ([openfinance-analyst](https://github.com/meloluan/openfinance-analyst), Steward).
5. Scraping Inter: fora. Cumbuca MCP: ~5 queries/dia, não serve de loop.

Local-first continua: o SQLite é a fonte operacional; a Pluggy é o tubo de sync. Sem conta Colony. O secret é **do usuário**, no Keystore — o aparelho é o “backend” de um CPF. Embutir Client ID da Colony para N clientes seria produto comercial (~R$ 2.500/mês) e está **fora**.

## Decisão

### Port (spec §23.9)

```dart
abstract interface class BankingDataProvider {
  Future<ConsentSession> beginConsent(...);
  Stream<ImportProgress> syncAccounts(...);
  Future<void> revokeConsent(...);
}
```

Sync contínuo aplica por **upsert** (`external_id`), não por preview diário. Preview só na 1ª ligação de contas. Finanças só leem.

### Fonte primária: Meu Pluggy / conector 200

- Setup único: Meu Pluggy (consentimento no Inter) + keys no dashboard + Item ID.
- Colony: `GET` contas, transações, bills. **Não** `PATCH /items` em cron (batch proibido pela Pluggy). Meu Pluggy já sincroniza o banco todo dia.
- `Atualizar agora` pode disparar update user-initiated (janela OF = hoje+6 dias).
- Recusar sync se `connector.id != 200`.
- Um par de keys por perfil/CPF. Família = N setups, não um tenant Colony.

### Fonte secundária: arquivo

OFX/CSV da conta digital só para backfill além da janela OF ou disaster recovery. Não é o loop.

### Fora

- Scraping / sessão Super App.
- Client Secret **nosso** no APK.
- API PJ como caminho PF.
- Homologar Colony como ITP.
- Executar pagamentos.

### Ordem de fatias

1. **Meu Pluggy sync** — `external_id`, status pending/posted, secure storage, GET on-open + WorkManager, gate conector 200, backfill, UI de saúde.
2. **Faturas + categorias** — `CreditCardBill`, MCC, pagamento de fatura como transferência, parcelas.
3. **Robustez** — WebView reconsentimento, raw payload, avisos de stale.
4. **Opcional** — OFX backfill; pending via notificação Android; API PJ se CNPJ.

### IN (confiabilidade)

- Upsert pela id Pluggy; revisitar ~35 dias (`PENDING`→`POSTED`).
- Apply transacional; cursor só avança no sucesso.
- Categoria sugerida nunca sobrescreve correção manual.
- Revogar consentimento não apaga ledger (ADR-032).
- Mapper em `colony_domain` (fixtures JSON); HTTP na camada de aplicação.
- Timezone `America/Sao_Paulo`. Sinal do cartão: compra Pluggy positiva → outflow.

### Repos de base

`pluggyai/meu-pluggy`, `meloluan/openfinance-analyst` (comportamento a espelhar), `pluggyai/quickstart` (WebView Flutter), `OpenBanking-Brasil/openapi`.

## Consequências

- A 1ª slice de produto **é** rede (api.pluggy.ai), opt-in. Offline continua com o último pull.
- Precisa migration: `external_id`, `status`, connection, depois `credit_card_bills`.
- Política de privacidade antes de loja pública; sideload pessoal pode seguir com disclaimer in-app (`PRIVACY_LEGAL_PREP.md`).
- ADR-020 (ledger manual) permanece; este ADR define o tubo automático.

## Critérios de aceite da 1ª slice

1. Depois do setup único, abrir o app traz compras novas de **conta e cartão** sem exportar no Inter.
2. Re-sync não duplica.
3. Conector ≠ 200 recusado com texto acionável.
4. Empty/loading/error/offline; disclaimer somente leitura.
5. Strings localizadas; proveniência `integration`.
6. Sem scrape e sem executar pagamento.

## Referências

- Spec §23.9, §37.4, §50, §52 item 11
- ADR-005, ADR-015, ADR-020, ADR-032
- `docs/dev/INTER_BANKING_INTEGRATION.md`
- `docs/dev/PRIVACY_LEGAL_PREP.md`
