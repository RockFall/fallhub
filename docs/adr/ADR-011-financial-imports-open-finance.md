# ADR-011: Financial imports / Open Finance

## Status
Aceito (spike doc — pesquisa Inter ago/2026; sem código de produto nesta iter)

Pesquisa detalhada: [`docs/dev/INTER_BANKING_INTEGRATION.md`](../dev/INTER_BANKING_INTEGRATION.md).

## Contexto
Spec §23.9 e §37.4 pedem camada de provedor bancário, fase inicial por arquivo (OFX/CSV/PDF) e fase posterior via parceiro regulado. Spec §52 lista este ADR como obrigatório; ADR-020 implementou o ledger **manual** e deixou `externalConnectionId` / Open Finance deferidos. ADR-032 deferiu banking APIs explicitamente.

O pedido concreto é Banco Inter: extrato de débito, fatura de cartão atual e histórica, categorias, poucos cliques, à prova de falhas.

Pesquisa (ago/2026) mostrou quatro fatos que travam uma integração “direta”:

1. **API Inter Empresas** (OAuth + mTLS, [developers.inter.co](https://developers.inter.co/)) é **somente PJ**, janela de extrato **90 dias**, e **não** entrega fatura de cartão.
2. **PF/MEI** já exportam conta digital em **PDF, CSV e OFX** (até 2 anos) pelo Super App / Internet Banking. Fatura de cartão sai sobretudo em **PDF senha = 6 dígitos do CPF**.
3. **Open Finance Brasil** é o único caminho estruturado PF para cartão (bills fechadas + `transactions-current` da fatura aberta + ~12 meses + MCC). A Colony **não** pode ser receptora direta; precisa de agregador (Pluggy / Belvo / TecnoSpeed) **e de um backend** para Client Secret. Piso público ~R$ 540–2.500/mês — incompatível com app local-first sem conta, a menos que exista contrato/parceiro.
4. Não há equivalente estável a `pynubank` para o Inter. Scraping está **fora**.

## Decisão

### Port único (spec §23.9)

```dart
abstract interface class BankingDataProvider {
  Future<ConsentSession> beginConsent(...);
  Stream<ImportProgress> syncAccounts(...);
  Future<void> revokeConsent(...);
}
```

Toda fonte (arquivo Inter, API PJ, agregador OF) normaliza para o mesmo `BankingStatement` e passa pelo preview/apply já usado no CSV (Iter 107). Finanças **somente leem/importam**.

### Ordem de fatias

1. **Inter file adapter (IN)** — OFX canônico para débito; CSV nativo Inter (`;`, decimal BR); share-sheet; consent `IntegrationKind` novo; dedup por `FITID`/`external_id` senão `fingerprint`.
2. **Fatura como entidade + categorias (IN em seguida)** — `CreditCardBill`; regras MCC/histórico; pagamento de fatura não duplica gasto; PDF on-device.
3. **API PJ (opcional)** — certs no Keystore, só `extrato.read`/`saldo.read`, cursor 90 dias. Fora se o perfil for só PF.
4. **Open Finance agregador (defer)** — Pluggy como primeiro candidato (Flutter WebView no `pluggyai/quickstart`, cobertura Inter PF bills). Só após backend mínimo **ou** modo power-user com relay hospedado pelo usuário + política de privacidade. TecnoSpeed se o critério for piso de preço.

### IN

- Idempotência, preview, transação de DB, cursor, raw payload, pending→posted, retry 429/5xx, D-1 como `to` default.
- Categoria sugerida nunca sobrescreve correção manual (spec §23.6).
- Revogar consentimento não apaga ledger local (ADR-032).
- Parsers em `colony_domain` (puros); HTTP/mTLS em camada de aplicação/dados, não em widget.

### OUT

- Screen scraping / sessão não oficial do Super App.
- Client Secret de agregador no APK.
- Executar Pix, boleto, pagamento de fatura.
- Homologar a Colony como ITP/receptora OF.
- Sync contínuo em background sem UI de consentimento/validade.

### Repos de base (referência, não dependência)

Ver tabela na pesquisa. Em resumo: `OpenBanking-Brasil/openapi`, `pluggyai/quickstart` + `my-expenses`, `lucasrcezimbra/bancointer`, `abstra-app/template-bank-reconciliation`, `Maxed-OSS/ofx-normalizer`. Parser OFX Dart é **nosso**, com fixtures anonimizadas.

## Consequências

- Fatia 1 desbloqueia o caso de uso pessoal (PF) sem violar local-first nem pagar agregador.
- Cartão histórico estruturado de verdade fica na Fatia 2 (PDF) ou 4 (OF). A Fatia 1 pode já importar CSV/OFX de cartão **se** o usuário conseguir exportar.
- `external_id`, `import_batch_id` e `CreditCardBill` exigirão migration Drift + bump de export quando forem persistidos — não nesta iter.
- ADR-020 permanece válido para o MVP manual; este ADR abre o caminho de import.

## Critérios de aceite da 1ª slice produto

1. Importar OFX Inter da conta digital com preview/confirm e zero duplicata na reimportação.
2. Assistente “Como exportar no Super App” + picker/share-sheet.
3. Empty/loading/error + disclaimer (app não executa).
4. Strings localizadas; proveniência `file`/`integration`.
5. Sem rede bancária obrigatória; app continua útil offline.

## Referências

- Spec §23.9, §37.4, §50, §52 item 11
- ADR-005, ADR-015, ADR-020, ADR-032
- `docs/dev/INTER_BANKING_INTEGRATION.md`
- `docs/dev/PRIVACY_LEGAL_PREP.md` (obrigatório antes da Fatia 4)
