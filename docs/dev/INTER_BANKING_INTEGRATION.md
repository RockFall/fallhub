# Integração Banco Inter — pesquisa e plano

Status: pesquisa (ago/2026). Não é código de produto. Decisão arquitetural em [`docs/adr/ADR-011-financial-imports-open-finance.md`](../adr/ADR-011-financial-imports-open-finance.md).

Objetivo: importar, com **poucos cliques** e **à prova de falhas**, extrato de débito (conta digital), fatura de cartão (atual e histórica) e metadados úteis (saldo, limites, categorias, parcelas, MCC) do Banco Inter para o ledger local do Life Colony OS.

Restrições já fechadas pela spec e pelos ADRs:

- Local-first, app útil offline, sem conta obrigatória (ADR-005, spec §0.1).
- Finanças **não executam** Pix, boleto, pagamento de fatura nem qualquer operação (§0, ADR-020).
- Integração sensível: opt-in, granular, revogável, com proveniência (§0, ADR-032).
- Open Finance **não** é uma API aberta a qualquer app pessoal; a spec §23.9 exige uma camada `BankingDataProvider` e parceiro regulado na fase posterior.
- Widgets não falam com banco; SQL só em `colony_database`.

## 1. O que o Colony já tem

O ledger MVP (ADR-020 + CSV Iter 107) já cobre a espinha dorsal de um importador:

| Peça | Onde | Serve para o Inter? |
| --- | --- | --- |
| Contas `checking` e `creditCard` | `FinancialAccount` | Sim — mapear 1:1 conta digital e cartão |
| Transação imutável + `fingerprint` | `LedgerTransaction` | Deduplicar reimportações |
| Preview → apply | `FinanceCsvImportPolicy` | Mesmo fluxo para OFX/PDF/API |
| Categorias lite | `TransactionCategory` (10 valores) | Destino de MCC / regras |
| Consentimento de integração | `IntegrationConsent` (`calendarIcs` só) | Estender com `financeInterFile` / `financeOpenFinance` |
| `externalConnectionId` | deferido no ADR-020 | Precisa voltar para sync contínuo |
| CSV codec | formato **interno** Colony, não o CSV do Inter | Precisa de um parser Inter-nativo |

Lacunas de domínio (spec §23.5, ainda deferidas): `external_id`, `posted_at`, `merchant_normalized`, `installment_group_id`, `transfer_pair_id`, `import_batch_id`, `status` (`pending`/`posted`), entidade de **fatura** (`CreditCardBill`). Sem elas, cartão fica “lista de gastos” e não “fatura com vencimento, mínimo e pagamento”.

## 2. Como se faz isso hoje (quatro caminhos reais)

Não existe um único “SDK Inter para app pessoal”. Há quatro famílias, com trade-offs opostos de cliques vs. regulação vs. cobertura de cartão.

### Caminho A — Arquivos oficiais do Super App / Internet Banking (PF e MEI)

O Inter **já exporta** extrato da conta digital em PDF, CSV e OFX.

No Super App: Saldo → filtrar período → seta/exportar → “Enviar por e-mail”. Chegam os três formatos no e-mail cadastrado. No Internet Banking: Conta Digital → Extrato → Exportar → PDF/CSV/OFX no computador.

Limite oficial de consulta: **até 2 anos** entre data inicial e final ([ajuda Inter](https://ajuda.inter.co/conta-digital-pessoa-fisica-e-mei/como-acessar-o-extrato-da-conta-digital-pf-ou-mei)).

CSV típico da comunidade (Conta Azul / ERPs):

- Separador `;`, encoding Latin-1 (fallback UTF-8).
- Metadados nas primeiras linhas, depois cabeçalho.
- Colunas frequentes: `Data Lançamento; Histórico; Descrição; Valor` (valor BR `1.520,00`).

OFX é o formato mais estável: `FITID` (id estável), `TRNAMT` com sinal, `DTPOSTED`, `MEMO`/`NAME`. É o que Conta Azul, Fintera e Omie pedem para conciliação.

Cartão de crédito no Super App: Cartões → Fatura (aberta em azul, fechada em vermelho) → detalhe da atual, passadas e futuras. Compartilhar boleto / salvar PDF. PDF da fatura Inter vem **protegido por senha = 6 primeiros dígitos do CPF do titular** ([blog Inter](https://blog.inter.co/fatura-inter/)). Não há OFX oficial de fatura tão documentado quanto o da conta digital; o caminho estruturado de cartão, no mundo PF, é Open Finance (abaixo) ou parse do PDF/CSV se o app oferecer.

**Cliques:** ~5–8 (exportar no Inter + abrir no Colony). **Confiabilidade:** alta (formato do próprio banco). **Local-first:** sim. **Cartão histórico:** PDF/e-mail, parse mais frágil que OFX.

### Caminho B — API Banking Inter Empresas (só PJ)

Portal: [developers.inter.co](https://developers.inter.co/). Auth: OAuth2 client credentials **+ mTLS** (`.crt` + `.key` gerados no Internet Banking, validade ~12 meses). Token ~60 min. Escopos granulares (`extrato.read`, etc.).

Endpoints úteis (leitura):

| Recurso | Path | Janela | Rate limit típico |
| --- | --- | --- | --- |
| Extrato simples | `GET /banking/v2/extrato` | máx. **90 dias** por chamada | ~10 req/min |
| Extrato PDF | `GET /banking/v2/extrato/exportar` | 90 dias | idem |
| Extrato enriquecido | `GET /banking/v2/extrato/completo` | 90 dias, paginado, filtros tipo | idem |
| Saldo | `GET /banking/v2/saldo` | snapshot | — |

Histórico além de 90 dias = várias janelas encadeadas (ex.: 8 chamadas para 2 anos), com checkpoint.

**Não serve para o caso PF.** Conta Azul, Hubpay e a própria comunicação Inter Empresas: API **somente PJ**; PF e MEI **não** geram certificado de integração. A API Banking **não expõe fatura de cartão** — é caixa/extrato/pagamentos/Pix de conta corrente empresarial.

SDKs oficiais: Java e C#. Não há SDK Dart/Flutter oficial.

**Cliques:** muitos (criar app, baixar zip de cert, colar Client ID/Secret, renovar todo ano). **Cartão:** não. **Encaixa no Colony:** só como adapter opcional *bring-your-own-cert* para quem tiver CNPJ.

### Caminho C — Open Finance Brasil (o caminho “poucos cliques” de verdade para PF)

O Inter é instituição participante. O usuário consente no app/internet banking do Inter; a app receptora lê dados com token de consentimento. **A Colony não pode falar direto com o Inter Open Finance**: só ITP/receptora regulada pelo BC, ou um **agregador** já credenciado.

APIs relevantes (Open Finance Brasil, credit-cards v2 / accounts v2):

| Dado | Endpoint (conceitual) | Recorte |
| --- | --- | --- |
| Conta corrente / poupança | `accounts` + `transactions` | histórico ~**12 meses** |
| Transações recentes conta | `transactions-current` | ~7 dias |
| Lista de cartões | `credit-cards-accounts/accounts` | produto, bandeira |
| Limites | `.../limits` | crédito, saque |
| Transações cartão históricas | `.../transactions` | ~**12 meses**, pós-clearing |
| Fatura **aberta** (atual) | `.../transactions-current` | ~7 dias; `billId` pode faltar |
| Faturas **fechadas** | `.../bills` | só fatura já encerrada |
| Itens de uma fatura | `.../bills/{billId}/transactions` | conciliadas **e** faturadas |
| MCC / CNPJ do lojista | campos `payeeMCC`, identificação | categorização |
| Parcelas | `payeeMCC` + installment metadata | `installment_group_id` |
| Investimentos | phase 4 OF (cobertura variável) | Pluggy marca Inter 🟢 |

IDs de transação de cartão só ficam imutáveis **depois que a fatura fecha** (regra OF). Reimportar fatura aberta exige tratar `pending` → `posted` sem duplicar.

Fluxo UX de agregador (Pluggy, Belvo, TecnoSpeed PlugBank, etc.):

1. App pede um **connect token** a um **backend** (Client ID/Secret nunca no apk).
2. WebView abre o widget; usuário escolhe Inter, autentica **no Inter**, marca conta e/ou cartão, confirma.
3. Webhook/`item.updated` → backend baixa contas, transações, bills.
4. App aplica no ledger local.

Isso é “poucos cliques” (2–4 no widget + biometria do Inter). Cobertura Pluggy (ago/2026): Inter PF e PJ com Accounts, Transactions, **Credit Cards**, Investments. Bills de cartão são **obrigatórios** em conectores Open Finance regulados; em conectores “direct”, Pluggy cita bills especificamente para **Inter PF** e Itaú Cartões.

Custo real para um app pessoal (relatos públicos 2026, não contrato):

| Agregador | Piso citado | Flutter? | Bills Inter? |
| --- | --- | --- | --- |
| Pluggy | ~R$ 2.500/mês | WebView oficial no [pluggyai/quickstart](https://github.com/pluggyai/quickstart) (`frontend/flutter`) | Sim (OF + Inter PF direct) |
| Belvo | ~R$ 6.000/mês (Launch ~US$ 1.000) | SDKs, não Flutter first-party | Sim (objeto bill OF) |
| TecnoSpeed PlugBank | ~R$ 1.500 adesão + ~R$ 540/mês | API JSON | Extrato + fatura (2026) |
| Meu Pluggy (consumidor) | grátis para a pessoa | não é SDK de produto | a pessoa conecta no site deles |

**Bloqueio local-first:** agregador **exige backend** para mintar token e puxar transações (connect token não lê bills/transactions completos — 403). Segredo no app = comprometido no sideload. Sem backend Colony, este caminho não entra em produção.

Atalho desonesto: scraping da sessão do Super App. Equivalente a `pynubank` não existe de forma estável para o Inter; quebra com MFA, ToS e atualização de app. **Fora de escopo.**

### Caminho D — Híbrido (recomendado)

Arquivos oficiais como fonte **sempre disponível e offline**. Open Finance via parceiro como fonte **opcional** quando (e se) houver backend + contrato. API PJ como fonte **opcional** se o perfil tiver certificado. Os três desaguam no mesmo `BankingDataProvider` e no mesmo preview/apply.

## 3. O que dá para extrair, por fonte

| Dado | Arquivo PF | API PJ | Open Finance (agregador) |
| --- | --- | --- | --- |
| Extrato débito atual | CSV/OFX | extrato 90d | transactions-current |
| Extrato débito histórico | CSV/OFX até 2 anos | N×90 dias | ~12 meses |
| Saldo | no PDF/cabeçalho OFX | `saldo` | account balance |
| Fatura cartão **aberta** | tela/PDF atual | não | transactions-current (+ limites) |
| Faturas cartão **fechadas** | PDFs mensais (senha CPF) | não | `bills` + transactions por `billId` |
| Pagamento da fatura | lançamento na conta + PDF | não | `bills[].payments[]` |
| Mínimo / vencimento / IOF | PDF fatura | não | `minimumPaymentAmount`, `financeCharges` |
| Limite do cartão | não estruturado | não | `limits` |
| MCC / CNPJ lojista | às vezes no histórico CSV | extrato completo (parcial) | sim |
| Categoria pronta | Inter tem categoria no app, **não** sai limpa no OFX | não | merchant.category (Pluggy Pro) ou MCC nosso |
| Parcelas | texto “Parcela 3/12” | idem | campos OF de installment |
| Investimentos Inter | fora deste plano | não nesta API | OF investimentos (cobertura variável) |
| Pix / TED contraparte | descrição | extrato completo | transaction parties |

Categorização: a spec §23.6 manda **regras determinísticas primeiro**, sugestão depois, **nunca** sobrescrever correção manual. Mapa proposto:

1. MCC Open Finance / `payeeMCC` → `TransactionCategory`.
2. Palavras do `Histórico` Inter (`IFOOD`, `UBER`, `PIX`, `PAGTO FATURA`, `CASHBACK`).
3. Lojista normalizado (CNPJ) com tabela local aprendida.
4. Usuário corrige → regra local (`merchant X → category Y`).

Pagamento de fatura na conta corrente deve virar **transferência** (`transfer_pair_id`), não despesa + despesa. Sem isso o orçamento duplica o cartão.

## 4. Repositórios que realmente ajudam (e os que não)

Nenhum repositório é um “drop-in” Flutter para o Colony. Usar como **referência de protocolo**, não como dependência de runtime.

### Usar como base de implementação

| Repo | Por quê | Como usar aqui |
| --- | --- | --- |
| [OpenBanking-Brasil/openapi](https://github.com/OpenBanking-Brasil/openapi) | Contratos oficiais (`credit-cards/2.2.0.yml`, accounts) | Modelar `CreditCardBill` e IDs estáveis; golden tests com fixtures YAML |
| [pluggyai/quickstart](https://github.com/pluggyai/quickstart) | Flutter + WebView do Connect; exemplos de token no backend | Copiar **só** o padrão WebView quando houver parceiro; não commitar secrets |
| [pluggyai/my-expenses](https://github.com/pluggyai/my-expenses) | App de gastos pessoais completo em cima da Pluggy | Ver mapeamento account/bill/transaction → ledger |
| [lucasrcezimbra/bancointer](https://github.com/lucasrcezimbra/bancointer) | Cliente Python limpo: mTLS, token, `get_statements`, fake client de teste | Espelhar o fluxo OAuth+mTLS num `InterPjApiClient` Dart; reusar a ideia do `ClientFake` |
| [abstra-app/template-bank-reconciliation](https://github.com/abstra-app/template-bank-reconciliation) | `get_expenses_from_inter_api.py` mínimo (token + `GET /banking/v2/extrato`) | Snippet canônico de headers `x-conta-corrente` + cert tuple |
| [Maxed-OSS/ofx-normalizer](https://github.com/Maxed-OSS/ofx-normalizer) | OFX/QFX + CSV → schema único (sinal, data, direção) | Portar a ideia para Dart (`OfxStatement` + `InterCsvStatement`); não puxar Go |
| [kedder/ofxstatement](https://github.com/kedder/ofxstatement) | Ecossistema de plugins banco→OFX | Padrão de plugin por instituição; o nosso “plugin” é Inter |

### Referência secundária (PJ / cobrança, pouco extrato)

- [renatojdev/bancointer-python](https://github.com/renatojdev/bancointer-python) — PyPI `bancointer-python`; banking + cobrança; extrato enriquecido ainda “a implementar” em várias tags.
- [helbertfurbino/api-inter-v2](https://github.com/helbertfurbino/api-inter-v2) (fork da divulgueregional) — PHP com extrato/saldo/PDF.
- [LuizDMM/inter_api_python_connector](https://github.com/LuizDMM/inter_api_python_connector) — wrapper MIT pequeno, pouco movimento.

### Não usar como base do app

- Scrapers / “unofficial Inter API” de sessão mobile — frágeis, MFA, risco jurídico.
- [mcp-dir/inter-mcp](https://github.com/mcp-dir/inter-mcp) — MCP de leitura via Open Finance para agentes; útil para explorar o **shape** dos dados (`openfinance_list_credit_card_bills`), não para embutir no Flutter.
- Conversors PDF→OFX na nuvem (MeuOFX etc.) — vazam fatura com CPF; o parse tem que ser **on-device**.

Não há pacote `ofx` maduro e óbvio no pub.dev comparável ao normalizer. O parser OFX do Colony deve ser **nosso**, pequeno, com fixtures reais (anonimizadas) de um OFX Inter.

## 5. Recomendação

Para “fácil + confiável” **neste** produto (sideload, local-first, um usuário, sem backend):

1. **Fatia 1 (fazer):** importador Inter por arquivo, com assistente de poucos toques e share-sheet. OFX primeiro (débito), CSV Inter nativo depois, PDF de fatura depois. É a única combinação que é oficial, PF, offline e barata.
2. **Fatia 2:** modelo de fatura + regras de categoria + detecção de pagamento de fatura como transferência + cursor de importação (à prova de reimport).
3. **Fatia 3 (opcional, PJ):** adapter `InterPjBankingProvider` com certs no dispositivo (Android Keystore / iOS Keychain), janelas de 90 dias, só leitura `extrato`+`saldo`.
4. **Fatia 4 (opcional, quando houver parceiro):** `OpenFinanceAggregatorProvider` (Pluggy como primeiro, TecnoSpeed se o piso for o critério). UI = WebView de consentimento. Dados caem no mesmo apply idempotente.

Não implementar scraping. Não colocar Client Secret de agregador no APK. Não fingir sync contínuo sem consentimento visível e revogável.

## 6. UX “poucos cliques” (Fatia 1)

Tela nova a partir de Finanças e de `/settings/integrations`: **Importar do Inter**.

Conta digital (meta: ≤ 6 toques depois da 1ª vez):

1. Escolher conta Colony destino (ou criar “Inter Conta” automaticamente).
2. Botão **Como exportar** (bottom sheet com os 4 passos oficiais do Super App) + **Abrir arquivos** / receber via share.
3. Detectar OFX vs CSV vs PDF pelo conteúdo, não pela extensão.
4. Preview (já existe o padrão CSV): N novos, M duplicados, período, saldo OFX se houver.
5. Confirmar → apply transacional.

Cartão:

1. Escolher conta `creditCard` destino.
2. Mesmo picker; se PDF, pedir senha **uma vez**, guardar hash/verificador local, nunca o CPF completo em texto.
3. Se o PDF for “boleto + resumo” e não o detalhe, avisar e sugerir Open Finance ou CSV se disponível.
4. Preview agrupa por competência da fatura (vencimento).

Android: `intent-filter` para `*.ofx`, `*.qfx`, `text/csv`, `application/pdf` com origem “share from Gmail/Inter”. iOS: share extension equivalente quando a plataforma estiver no radar.

Empty/loading/error/offline: arquivo ilegível, senha PDF errada, período vazio, encoding, duplicata total (“nada a aplicar” — já existe).

## 7. Arquitetura no monorepo

Seguir camadas da spec. Nada de HTTP em widget.

```text
colony_domain/
  BankingDataProvider          # port §23.9
  BankingStatement             # contas + txs + bills normalizados
  BankingImportCursor          # fromDate, toDate, page, lastFitId
  CreditCardBill               # dueDate, total, minimum, payments
  FinanceCategoryRule          # padrão → TransactionCategory
  OfxCodec / InterCsvCodec     # parsers puros

colony_database/
  implementa persistência + raw_payload opcional
  ledger_transactions.external_id
  ledger_transactions.import_batch_id
  credit_card_bills
  banking_import_cursors
  finance_category_rules

lib/features/finance/
  application/  InterImportController (preview/apply, retry)
  presentation/ inter_import_sheet.dart

lib/features/integrations/
  IntegrationKind.financeInterFile | financeInterPj | financeOpenFinance
```

Mapeamento para o ledger atual:

- `FITID` OFX / `transactionId` OF / id da API PJ → `external_id` (preferido na dedup).
- Sem id → `fingerprint` atual (conta+data+valor+descrição).
- `sourceType = integration` (ou `file`).
- Categoria só preenchida se vazia; correção manual é sagrada (§23.6).

Parser OFX: SGML 1.0.2 que o Inter emite (não assumir XML OFX 2). Testes com fixture recortada e anonimizada.

Parser CSV Inter: pular linhas até achar cabeçalho conhecido; `;`; decimal BR; datas `dd/MM/yyyy`.

## 8. Confiabilidade (à prova de falhas)

Contrato de importação, independente da fonte:

1. **Idempotência.** Dedup por `external_id` se existir, senão fingerprint. Reimportar o mesmo mês é no-op nas linhas já vistas (o CSV apply já faz isso).
2. **Preview obrigatório.** Nenhuma fonte escreve direto. Mesmo a API PJ e o webhook OF passam por plan/apply (o webhook pode pré-carregar um plan pendente).
3. **Transação de DB.** Apply all-or-nothing por lote; em falha, cursor não avança.
4. **Cursor.** Persistir `from`, `to`, `page`, `lastExternalId`, `status`. Retomar janela 90d/12m sem buraco nem overlap destrutivo.
5. **Raw payload.** Guardar OFX/CSV/JSON cru no attachment store (ADR-015) para replay se o parser evoluir. Não reenviar à nuvem.
6. **Pending vs posted.** Fatura aberta / D0 da conta: `status=pending`. No próximo sync, promover pelo mesmo `external_id` sem criar segunda linha.
7. **Retry.** 401 → renovar token (PJ/OF). 429 → backoff exponencial + jitter. 5xx → retry limitado. Timeout → não marcar cursor como done.
8. **Certificado PJ.** Avisar 30 dias antes de expirar (12 meses). Falha de mTLS = erro acionável, não crash.
9. **Consentimento OF.** Mostrar escopo, validade (tipicamente 12 meses, refresh periódico), revogar no app **e** instruir revogar no Inter. Revogar **não** apaga histórico local (ADR-032).
10. **Não duplicar fatura.** Pagamento na conta corrente + itens do cartão: o pagamento casa com `CreditCardBill.payments` e vira transferência. Cashback = inflow `income` ou categoria dedicada, nunca soma no gasto do lojista.
11. **Janela incompleta.** OFX do dia corrente é instável (dica Fintera/Conta Azul: importar até D-1). Default: `to = yesterday`.
12. **Encoding e locale.** Latin-1 + UTF-8 BOM; teste com `ç` e `R$`.
13. **Segredos.** Cert PJ e senha de PDF só em storage cifrado do SO. Agregador só no servidor, se existir.
14. **Auditoria.** `import_batch`: fonte, horário, contagem, hash do arquivo, erros por linha.

Testes mínimos (DoD):

- Fixture OFX Inter → N txs, fingerprints estáveis.
- CSV Inter com metadados no topo → mesmo resultado que OFX no overlap.
- Reimport → 0 novos.
- PDF senha errada → erro localizado, sem crash.
- (Futuro) JSON Pluggy bill + transactions → `CreditCardBill` + txs com `billId`.
- Categoria manual não é sobrescrita na 2ª sync.
- `flutter analyze` + testes de `colony_domain` / `colony_database` / widget do sheet.

## 9. Plano de fatias (ordem)

Não estimar calendário; cada fatia é um PR vertical.

### Fatia 1 — Inter file adapter (desbloqueia PF hoje)

- Domínio: `OfxCodec`, `InterCsvCodec`, `BankingStatement`, estender preview além do CSV interno.
- UI: sheet “Importar do Inter” + intent-filter Android.
- Consent `financeInterFile`.
- Contas: débito via OFX/CSV. Cartão: se CSV/OFX existir no export do usuário; senão adiar PDF.
- Strings em `lib/app/localization/`.
- Export schema: só bump se persistir entidades novas (`external_id` / batch). Preferir colunas novas com migration Drift + teste de migration.

### Fatia 2 — Fatura como entidade + categorias

- `CreditCardBill` + ligação tx↔fatura.
- Regras MCC/histórico Inter → categoria sugestão.
- Detecção `PAGTO FATURA` / Pix para o próprio cartão → transfer pair (pode ficar “soft pair” em notes se o par ainda for defer).
- Parser PDF on-device (senha CPF) com testes em fixture sintético, **nunca** commitar PDF real.

### Fatia 3 — API PJ opcional

- `InterPjApiClient` (Dart `HttpClient` + `SecurityContext` com `.crt`/`.key`).
- Upload dos certs uma vez; só `extrato.read` + `saldo.read`.
- Sync manual (“Atualizar 90 dias”) + cursor para histórico.
- Sandbox `cdpj-sandbox.partners.uatinter.co` nos testes.

### Fatia 4 — Open Finance via parceiro

- Só depois de ADR de backend mínimo (conflita com “sem conta”) **ou** modo power-user “trago meu Client ID Pluggy + um relay que eu hospedo”.
- WebView Flutter do quickstart Pluggy.
- Mapear bills + transactions-current (fatura aberta) + 12 meses.
- Consentimento visível / revogação.
- Custo e LGPD: política de privacidade **antes** do código de rede (`docs/dev/PRIVACY_LEGAL_PREP.md`).

## 10. Riscos e decisões abertas

| Risco | Mitigação |
| --- | --- |
| CSV Inter muda cabeçalho | Detecção por aliases; OFX como fonte canônica de débito |
| PDF fatura muda layout / senha | Parser versionado; fallback “não consegui ler, use OF” |
| Open Finance só 12 meses vs Inter 2 anos em arquivo | Arquivo para backfill; OF para contínuo |
| Fatura aberta muda todo dia | `pending` + mesmo id |
| Agregador caro demais para 1 usuário | Não bloquear o produto; Fatia 1 basta para uso pessoal |
| mTLS no Flutter | Funciona em Android/iOS via `SecurityContext`; **não** em web |
| Sideload APK + cert no device | Keystore, não gravar `.key` em texto no backup JSON (ou cifrar) |
| Ser receptora OF direto | Fora: capital, certificação FAPI, homologação BC |

Decisão default reversível (spec §53): **arquivo primeiro**, agregador depois. API PJ só se o perfil for empresa Inter.

## 11. Critérios de aceite (quando a Fatia 1 existir)

1. Usuário PF importa OFX da conta Inter e vê lançamentos no ledger, com disclaimer de que o app não paga nada.
2. Reimportar o mesmo arquivo não duplica.
3. CSV “nativo Inter” (`;`, cabeçalho BR) também importa, ou explica o mismatch.
4. Empty/loading/error/offline no sheet.
5. Strings localizadas; proveniência `file`/`integration`.
6. Sem Client Secret, sem scrape, sem endpoint de pagamento.

Aceite da Fatia 2: uma fatura fechada (PDF ou JSON de fixture OF) vira conta cartão + txs da competência + total/vencimento visíveis.

Aceite da Fatia 4: 4 toques no widget Pluggy/TecnoSpeed → contas débito e crédito preenchidas, bills históricos listados, revogar consentimento não apaga o ledger.

## 12. Referências

- Spec §23 (ledger), §23.9 (Open Finance), §37.4–37.5 (arquivos/share sheet), §52 ADR-011.
- ADR-005 local-first, ADR-020 ledger, ADR-032 integrações.
- [developers.inter.co](https://developers.inter.co/) — API Empresas.
- [Open Finance Brasil — credit cards](https://openfinancebrasil.atlassian.net/wiki/spaces/OF/pages/193691666).
- [Pluggy coverage Inter](https://docs.pluggy.ai/docs/open-finance-institutions-coverage), [bills](https://docs.pluggy.ai/docs/credit-card-bills).
- Ajuda Inter: exportar extrato PF; blog fatura + senha PDF.
- Relato de custo agregadores: [TabNews, 2026](https://www.tabnews.com.br/GuilhermeVieira/estou-desenvolvendo-um-app-de-financas-pessoais-e-nao-consigo-pagar-o-open-finance-pluggy-r2-5k-mes-belvo-r6k-mes-tecnospeed-r1-5k-de-entrada-r540).
