# Integração Banco Inter — pesquisa e plano

Status: pesquisa revisada (ago/2026). Não é código de produto. Decisão em [`docs/adr/ADR-011-financial-imports-open-finance.md`](../adr/ADR-011-financial-imports-open-finance.md).

Objetivo: **capturar automaticamente** compras novas e acompanhar fatura de **débito** (conta digital) e **crédito** (fatura aberta + fechadas) do Inter PF. Escala: **pouquíssimos usuários** (uso pessoal / família). Setup com poucos cliques; depois disso, **zero export manual recorrente**.

Requisito que invalida o plano anterior: se cada atualização depender de exportar OFX/CSV no Super App, a integração não serve.

Restrições que continuam válidas:

- Local-first: app útil offline com o último sync; **sem conta Colony** (ADR-005).
- Finanças **não executam** Pix, boleto nem pagamento de fatura.
- Opt-in, granular, revogável, com proveniência.
- A Colony **não** vira ITP/receptora Open Finance (homologação BC).
- Widgets não falam com banco; SQL só em `colony_database`.

## Leia isto primeiro (o que é, na prática)

O Inter **não deixa** um app pessoal (PF) ligar direto na conta e puxar extrato/fatura. A “API do Inter” que existe na internet é de **empresa (PJ)**. Por isso ninguem “integra o Inter” no Colony do mesmo jeito que se integra um calendário.

O jeito legal de fazer isso no Brasil chama-se **Open Finance**: você, no app do Inter, autoriza uma instituição regulada a **ler** (não a gastar) sua conta e seu cartão. A Colony não é essa instituição. A **Pluggy** é. Eles oferecem um produto de consumidor chamado **Meu Pluggy**, feito para **você ler os seus próprios bancos de graça**.

Pense em três papéis:

| Quem | Faz o quê |
| --- | --- |
| **Você** | Uma vez, autoriza o Inter a compartilhar dados com o Meu Pluggy (login e biometria **no Inter**, não no Colony). |
| **Meu Pluggy / Pluggy** | Todo dia pergunta ao Inter: “o que tem de novo?” e guarda isso nos servidores **deles**. |
| **Colony** | Quando você abre o app (e de tempos em tempos em segundo plano), pergunta à Pluggy: “o que tem de novo **da minha** conexão?” e grava no celular. Offline o ledger continua lá. |

Depois do setup, **você não exporta OFX, não baixa PDF, não abre o Super App para atualizar o Colony**. A compra de ontem aparece sozinha. A compra de 5 minutos atrás pode demorar até o próximo ciclo (horas / ao abrir o app). Não é o segundo da maquininha.

### Setup (uma vez por pessoa)

São dois sites da Pluggy — fácil confundir:

1. **meu.pluggy.ai** — cadastro de pessoa. Botão conectar → escolhe **Inter** → o Inter pede login/biometria → você marca **conta digital e cartão**. Pronto: o Meu Pluggy já vê seus saldos e faturas.
2. **dashboard.pluggy.ai** — cadastro de “desenvolvedor” (ainda você). Cria uma aplicação, liga o conector chamado **MeuPluggy** (não o conector “Inter”), gera duas chaves (`CLIENT_ID` e `CLIENT_SECRET`) e, no Demo, autoriza o Meu Pluggy de novo. Isso cria um **Item ID** (um código da conexão Inter).
3. **No Colony** — cola essas três coisas uma vez (o app guarda no cofre do celular). Primeira sincronização puxa o histórico (~1 ano). Você confirma “esta é a conta, este é o cartão”.

Daí em diante: abrir o Colony atualiza. Umas vezes por ano o Inter pode pedir para **confirmar o compartilhamento de novo** (banner no Colony → 2–3 toques). Isso não é “exportar extrato todo mês”.

### Cada usuário

O Open Finance é por **CPF**.

- Uma pessoa, uma conta Inter: um Meu Pluggy, um par de chaves, um Item. Só ela cola no perfil dela.
- Casal / família: **cada CPF faz o setup**. O Colony não “pega a conta do marido” com as chaves da esposa. Não existe um login Colony na nuvem compartilhando bancos.
- As chaves no celular da pessoa A só enxergam os bancos que **A** autorizou. Se vazarem, o estrago é o CPF daquela pessoa, não uma base de clientes.

A Colony **não** vai nascer com Client ID próprio para “conectar Inter em um toque para qualquer um”. Isso transformaria o app em produto financeiro comercial e a Pluggy cobraria o plano de milhares por mês.

### Está de graça mesmo?

**Sim, para uso pessoal do próprio CPF**, enquanto a Pluggy mantiver o Meu Pluggy. Eles dizem isso com todas as letras: sem custo e sem prazo de expiração; o trial de ~15 dias do dashboard é só para **conectar conta de outras pessoas** (modo empresa).

| Caminho | Custa? |
| --- | --- |
| Meu Pluggy + conector **MeuPluggy** (código `200`) + suas chaves no Colony | Grátis (você mesmo) |
| No dashboard, escolher o banco **Inter** direto (como se o Colony fosse um app de clientes) | Trial curto, depois ~R$ 2.500/mês |
| A Colony virar “banco” Open Finance sozinha | Homologação no BC: inviável |

Armadilha: o dashboard **deixa** clicar em Inter. Funciona uns dias e **para**. O plano manda o Colony **recusar** qualquer conexão que não seja o conector MeuPluggy.

Não é 100% “para sempre, contrato assinado”. É um programa grátis de um terceiro. Se um dia a Pluggy mudar, os dados já baixados continuam no celular; o plano B é importar OFX **uma vez**, não todo dia.

### O que o Colony passa a mostrar

- Conta digital: Pix, TED, débito, entradas — lançamentos novos sozinhos.
- Cartão: compras da **fatura aberta** (o mês corrente) e das **fechadas** (histórico, vencimento, valor, mínimo).
- Categorias sugeridas (MCC / lojista); você corrige e a correção não é sobrescrita.
- O Colony **não paga** a fatura, não faz Pix, não mexe em limite.

### O que isto ainda não é

Não é um botão mágico no primeiro dia de código: precisa da fatia de implementação (sync, ids, faturas). Este documento é o **como**, não o app já ligado.

## 0. Conclusão (o que mudou)

O único caminho PF que é ao mesmo tempo **oficial, automático, de cartão+conta, e barato em escala de 1–N CPFs** é o **Meu Pluggy (conector `200`)**:

1. O usuário consente **uma vez** no Inter, via [meu.pluggy.ai](https://meu.pluggy.ai) (Open Finance regulado).
2. O Meu Pluggy **atualiza o Inter todo dia**. A Colony **só lê** (`GET`), não dispara lote contra o banco (a Pluggy **proíbe** batch update).
3. Credenciais são as do **próprio usuário** (aplicação Development no [dashboard.pluggy.ai](https://dashboard.pluggy.ai)). Grátis, sem prazo, **desde que o conector seja MeuPluggy / `200`**. Conectar “Inter” direto no dashboard comercial **pausa em ~14 dias** e cai no plano de ~R$ 2.500/mês.
4. O telefone **é** o backend: `CLIENT_ID` / `CLIENT_SECRET` no Keystore; HTTP para `api.pluggy.ai`. Não precisamos de servidor Colony nem de webhook público.
5. Arquivo OFX/CSV vira **backfill pontual** (histórico > janela OF, ou se a Pluggy cair) — nunca o loop diário.
6. API Inter Empresas continua **irrelevante para PF** (só PJ, sem fatura).

Isso já está em produção em apps pessoais: [meloluan/openfinance-analyst](https://github.com/meloluan/openfinance-analyst) (SQLite local, upsert 35 dias, faturas, parcelas) e o fluxo [Steward / MeuPluggy](https://fi.paired.net/docs/pluggy) (~15 min de setup, cron só de `GET`).

Atraso típico: **horas até o sync diário** (janela OF regulada = hoje + 6 dias). “Compra de agora” entra no ledger no próximo pull. `Atualizar agora` (user-initiated `PATCH` item) é o escape. Notificação do Android como `pending` é fatia posterior, não a fonte da verdade.

## 1. O que o Colony já tem

| Peça | Onde | Serve? |
| --- | --- | --- |
| Contas `checking` e `creditCard` | `FinancialAccount` | Mapear 1:1 conta digital e cartão Inter |
| `fingerprint` | `LedgerTransaction` | Fallback de dedup |
| Preview → apply CSV | `FinanceCsvImportPolicy` | Reusar o plano; sync automático aplica **sem** pedir confirm toda hora (opt-in explícito na 1ª vez) |
| Categorias lite | `TransactionCategory` | Destino de MCC / merchant Pluggy |
| `IntegrationConsent` | só `calendarIcs` | Novo kind `financeMeuPluggy` |
| `externalConnectionId` | deferido ADR-020 | **Volta a ser obrigatório** (itemId Pluggy) |

Lacunas a abrir **antes** do sync contínuo (senão duplica e não dá para faturas):

- `external_id` (id Pluggy / FITID)
- `status`: `pending` \| `posted`
- `import_batch_id`, `sourceType=integration`
- `CreditCardBill` (vencimento, total, mínimo, pagamentos, IOF)
- `posted_at`, `merchant_normalized`, `installment_group_id` (spec §23.5)
- Regras: nunca sobrescrever categoria manual; pagamento de fatura na conta = transferência, não despesa duplicada

## 2. Por que os outros caminhos não resolvem “automático PF”

### Arquivo Super App — oficial, mas manual

Conta digital: PDF/CSV/OFX até **2 anos** (e-mail sob demanda). Cartão: Inter **removeu CSV da fatura** (confirmação do próprio banco no Reclame Aqui; PDF só após o corte). PDF da fatura chega por e-mail até 3 dias úteis após o fechamento, senha = 6 dígitos do CPF.

Serve como **auditoria / backfill**. Não captura compra nova sem o usuário exportar de novo.

IMAP no PDF mensal da fatura **não** substitui o extrato do dia a dia (atrasa dias; fatura aberta não vem).

### API Inter Empresas — automática, mas não é PF

OAuth + mTLS, extrato 90 dias, saldo. **Só PJ.** Sem fatura de cartão. Certificado anual. Fora do caso.

### Open Finance comercial (Pluggy/Belvo/TecnoSpeed como produto)

É o “2 cliques” multi-usuário, mas o piso (~R$ 540–2.500/mês) é para **servir CPFs de terceiros**. Inútil para pouquíssimos usuários se pagarmos isso. A armadilha: o dashboard Pluggy deixa conectar Inter direto; isso **não** é o caminho pessoal.

### Scraping / sessão do Super App

Não há `pynubank` estável para o Inter. MFA, ToS, quebra. **Fora.**

### Cumbuca MCP

Open Finance per-user, licenciado, bom para chat. Limite ~5 queries/dia no MVP — **não** serve para monitoramento contínuo do ledger.

### Notificação Android / SMS

Complemento de baixa latência (`pending`), incompleto (sem histórico, sem fatura, texto instável). Nunca fonte canônica.

## 3. Caminho alvo: Meu Pluggy + Colony local

Dois portais, dois cadastros ([aviso oficial](https://github.com/pluggyai/meu-pluggy) e README do openfinance-analyst):

| Portal | Função |
| --- | --- |
| [meu.pluggy.ai](https://meu.pluggy.ai) | Consentimento OF. Usuário escolhe Inter, autentica **no Inter**, marca conta e cartão. Pluggy não vê a senha. Refresh **diário** da conexão. |
| [dashboard.pluggy.ai](https://dashboard.pluggy.ai) | `CLIENT_ID` + `CLIENT_SECRET` de uma **Development Application**. Habilitar conector **MeuPluggy**. Demo → OAuth Meu Pluggy → nasce um **Item** (UUID) por banco. |

Trial de ~14/15 dias do dashboard = recursos **comerciais**. Conector `200` **não expira**. Detectar no sync: se `connector.id != 200`, recusar e explicar (senão o usuário acha que “Inter direto” funcionou até o dia 15).

Dados que o Inter entrega nesse canal (cobertura Pluggy OF: Accounts, Transactions, Credit Cards, Investments, **Bills** — bills obrigatórios em OF regulado; em direct, Pluggy cita bills para **Inter PF**):

| Dado | Como vem | Recorte |
| --- | --- | --- |
| Conta digital / Pix / TED / débito | `GET /accounts`, `GET /transactions` | 1º sync ~365 dias na Pluggy; analyst reporta backfill até 24 meses no produto deles |
| Fatura **aberta** | transações do cartão sem `billId` estável + limites | janela `transactions-current` (~7 dias) a cada sync OF |
| Faturas **fechadas** | `GET /bills?accountId=` + txs por bill | histórico de faturas; total, mínimo, vencimento, `financeCharges`, `payments[]` |
| MCC / lojista | `creditCardMetadata.payeeMCC`, `merchant` | categoria sugerida |
| Parcelas | metadata de installment | `installment_group_id` |
| Saldo / limite | account + limits | Pluggy às vezes troca saldo por limite; Steward corrige pela fatura em aberto |

Sinal do cartão na Pluggy: **positivo = compra**. Normalizar no adapter: gasto negativo / entrada positiva (openfinance-analyst). Sem isso, orçamento explode.

Consentimento OF: BC removeu o teto rígido de 12 meses (Res. Conjunta 7/2023); renovação simplificada na receptora. Na prática conexões **caem** (Steward cita ~90 dias em alguns bancos). UI: aviso `LOGIN_REQUIRED` / consentimento perto de vencer + WebView “reconectar” (poucos toques, raro).

### Por que não precisamos de servidor Colony

Na arquitetura comercial, o Client Secret não pode ir no APK porque ele acessa **todos os clientes**. Aqui o secret acessa **só o Item do dono do telefone**. É o mesmo modelo de senha IMAP pessoal.

O aparelho:

1. `POST /auth` → apiKey (TTL curto; renovar).
2. `GET /items/{id}` → status, `connector.id` tem que ser 200.
3. `GET /accounts?itemId=`, `GET /transactions?accountId=&from=&to=`, `GET /bills?accountId=`.
4. Upsert local. **Não** `PATCH /items` em cron (batch proibido). Só GET. O Meu Pluggy já rodou o update no banco.
5. `Atualizar agora` (manual) pode `PATCH` o item — a Pluggy permite update user-initiated, janela OF = hoje+6 dias.

Connect token / WebView: o próprio app minta o token com o secret do usuário (setup e reconsentimento). Referência UI: `pluggyai/quickstart` `frontend/flutter`.

Background: Android `WorkManager` periódico (horas) só para GET. iOS background fetch é frágil → sync **ao abrir o app** + botão. Isso já é automático no sentido de “não exportar arquivo”. Latência intra-dia: WorkManager + sync on-open.

Pouquíssimos usuários:

- 1 CPF: um Meu Pluggy, um par de keys, um Item Inter (conta+cartão no mesmo item).
- Família: **um setup por CPF** (keys no perfil Colony daquela pessoa). Não embutir Client ID da Colony — isso seria produto comercial.
- Assistente no app para os ~6 passos (hoje o setup Steward é ~15 min e fácil de errar o conector).

## 4. Loop automático (contrato à prova de falhas)

Isto substitui “preview toda vez”. O preview existe na **1ª conexão** (quais contas criar). Depois, sync é upsert silencioso com relatório.

1. **Chave estável.** `external_id = pluggyTransaction.id`. Nunca insert cego. Fingerprint só se a Pluggy não mandar id.
2. **Revisitar 35 dias.** Transação nasce `PENDING`, vira `POSTED`, descrição/MCC enriquecem. Segunda sync atualiza a mesma linha.
3. **Fatura aberta.** Itens sem `billId` imutável ficam `pending` na conta cartão; ao fechar, ligam no `CreditCardBill`.
4. **Não duplicar pagamento.** Lançamento na conta digital “PAGTO FATURA” casa com `bills[].payments[]` → par de transferência.
5. **Apply transacional.** Lote all-or-nothing; cursor `lastSuccessfulPullAt` só avança no commit.
6. **Raw JSON.** Guardar payload do pull (ADR-015) para replay se o mapper mudar.
7. **Retry.** 401 → reauth apiKey. 429 → backoff + jitter. 5xx → não avançar cursor. Timeout → idem.
8. **Saúde da conexão.** Qualquer status ≠ `UPDATED` vira banner acionável (reconectar WebView). Campo `avisos` no digest financeiro (padrão analyst).
9. **Conector 200.** Recusar sync se não for MeuPluggy.
10. **Timezone.** Agrupar competência em `America/Sao_Paulo`.
11. **Categoria.** Sugestão só se `categoryId` vazio; correção manual gera regra local `merchant → category`.
12. **Segredo.** Keystore/Keychain. **Não** ir no export JSON em claro. Revogar consentimento não apaga o ledger.
13. **Frequência.** GET a cada abertura + periódico. Sem PATCH em lote.
14. **D-0.** OF regulado inclui hoje na janela de 7 dias; ainda assim tratar D0 como possivelmente `pending`.

Testes (domínio, sem rede):

- Fixture JSON Pluggy (conta + cartão + 2 bills) → ledger + `CreditCardBill`.
- Upsert 2× → mesma contagem; `PENDING`→`POSTED` no mesmo `external_id`.
- Pagamento de fatura não soma duas vezes no orçamento.
- `connector.id != 200` → erro localizado.
- Categoria manual preservada.
- Sinal do cartão invertido corretamente.

## 5. UX (setup uma vez, depois invisível)

**Primeira vez (assistente, ~10–15 min, uma vez por CPF):**

1. Disclaimer: somente leitura; dados vão à Pluggy (ITP) e depois ao SQLite local; revogável no Inter e no Colony.
2. Abrir Meu Pluggy / instruir “conectar Inter, conta **e** cartão”.
3. Colar `CLIENT_ID`, `CLIENT_SECRET`, `ITEM_ID` **ou** WebView Demo-equivalente se conseguirmos listar items.
4. Validar conector 200 + puxar contas → preview “Inter Conta”, “Inter Crédito”.
5. Confirmar → backfill → ligar sync automático.

**Todo dia (zero cliques):** WorkManager / on-open GET. Snackbar discreto: “12 novas · 3 atualizadas · fatura aberta R$ …”.

**Raro:** banner “Inter pediu login de novo” → WebView updateItem.

**Nunca no caminho feliz:** exportar OFX, senha de PDF, certificado `.crt`.

Tela finanças: fatura aberta (total corrido), fechada (vencimento, mínimo, pago/não), lista de compras da competência, conta digital ao lado. Empty = “ainda sem sync”; erro = acionável; offline = último `pulledAt`.

## 6. Arquitetura no monorepo

```text
colony_domain/
  BankingDataProvider
  MeuPluggyConnection   # itemId, connector must be 200
  BankingStatement      # accounts, txs, bills
  CreditCardBill
  FinanceCategoryRule
  PluggyTransactionMapper  # puro; fixtures JSON

colony_database/
  external_id, status, import_batch_id
  credit_card_bills
  banking_import_cursors
  finance_category_rules
  # secrets NÃO no Drift em claro — flutter_secure_storage

lib/features/finance/
  application/  meu_pluggy_sync_controller.dart  # GET loop, upsert
  presentation/ inter_connect_sheet.dart         # setup + saúde

lib/features/integrations/
  IntegrationKind.financeMeuPluggy
```

HTTP Pluggy fica num client de aplicação (não no widget). Sem pacote `pluggy` Dart oficial — cliente fino nosso (auth + 4 GETs), testável com `http` fake.

Arquivo OFX/CSV: adapter **secundário** no mesmo `BankingDataProvider`, para backfill >12 meses ou disaster recovery. Inter fatura CSV **não** é dependência (foi descontinuado).

## 7. Repos para copiar comportamento (não dependência)

| Repo | O que reusar |
| --- | --- |
| [pluggyai/meu-pluggy](https://github.com/pluggyai/meu-pluggy) | Fluxo oficial conector 200, refresh diário |
| [meloluan/openfinance-analyst](https://github.com/meloluan/openfinance-analyst) | **Melhor base de produto:** upsert 35d, sinal do cartão, `card_bill`, parcelas, aviso de consentimento, SQLite local, recusar conector ≠ 200, backfill 24m |
| [pluggyai/quickstart](https://github.com/pluggyai/quickstart) | WebView Flutter Connect / updateItem |
| [pluggyai/my-expenses](https://github.com/pluggyai/my-expenses) | App de gastos em cima da API |
| [OpenBanking-Brasil/openapi](https://github.com/OpenBanking-Brasil/openapi) | Shape de bills/txs (golden tests) |
| Steward docs MeuPluggy | Setup passo a passo; correção saldo vs limite via `/bills` |

Não copiar: clientes PJ (`lucasrcezimbra/bancointer` etc.) para o loop PF. Úteis só se um perfil for empresa.

## 8. Plano de fatias (ordem invertida)

Cada fatia = PR vertical. Sem sync automático, não fecha o pedido.

### Fatia 1 — Sync Meu Pluggy (desbloqueia PF automático)

- Domínio: mapper Pluggy → `LedgerTransaction` + contas; `external_id`; `status`.
- Secure storage das keys; recusar connector ≠ 200.
- Sync on-open + WorkManager GET; relatório de delta.
- UI setup + saúde da conexão + “Atualizar agora” (PATCH item, opcional).
- 1º pull: backfill (12 meses mínimo).
- Disclaimer / consent `financeMeuPluggy`.
- Migration Drift + export bump para `external_id` / status.
- Strings localizadas. App continua útil offline.

### Fatia 2 — Faturas e categorias

- `CreditCardBill` + fatura aberta vs fechada na UI.
- MCC / merchant → sugestão; regras locais.
- Pagamento de fatura = transferência.
- Parcelas / comprometido (como `installments_outlook` do analyst).

### Fatia 3 — Robustez

- Banner reconsentimento WebView.
- Digest “avisos” (stale, LOGIN_REQUIRED).
- Raw payload + replay.
- Testes de migration e conflito de fingerprint vs `external_id`.

### Fatia 4 — Opcional

- OFX/CSV conta digital como backfill > janela OF.
- `pending` via NotificationListener (Android) até o GET confirmar.
- API PJ se um perfil for CNPJ.
- IMAP do PDF mensal só como checksum da fatura fechada — **não** no caminho feliz (Inter atrasou PDF após o corte).

## 9. Riscos

| Risco | Mitigação |
| --- | --- |
| Pluggy encerra o Meu Pluggy grátis | Arquivo/OFX como fallback; dados já estão no SQLite |
| Usuário conecta Inter direto (trial) | Gate `connector == 200` no 1º sync |
| Secret no sideload APK | Keystore; um vazamento = só aquele CPF, não uma base de clientes |
| Sync diário ≠ tempo real | On-open GET; “Atualizar agora”; pending de notificação depois |
| Conexão cai ~90 dias | Banner + WebView; não é loop manual de extrato |
| Histórico OF ~12 meses | Backfill OFX **uma vez** se precisar de 2 anos |
| Saldo cartão = limite | Corrigir pela fatura em aberto (Steward) |
| Servir terceiros com as keys da Colony | Proibido; cada perfil traz o próprio Meu Pluggy |
| iOS background | Sync ao abrir é suficiente para PFM pessoal |
| LGPD / Pluggy como operador | Disclaimer na 1ª conexão; política antes de Play Store (`PRIVACY_LEGAL_PREP.md`) |

Decisão default reversível: **Meu Pluggy primeiro**, arquivo como contingência. Não scrapear. Não pagar agregador comercial para 1 CPF.

## 10. Critérios de aceite (Fatia 1)

1. Após o setup único, **abrir o app** importa compras novas da conta **e** do cartão sem o usuário mexer no Super App.
2. Segunda abertura não duplica; ids Pluggy estáveis.
3. Fatura aberta aparece como total corrido; fechadas na Fatia 2, mas txs de cartão já entram na 1.
4. Conector ≠ 200 é recusado com texto acionável.
5. Offline mostra ledger local; erro de rede não corrompe.
6. Sem Client Secret da Colony, sem scrape, sem endpoint de pagamento.
7. Revogar no Inter/Pluggy para o sync, mas o histórico local permanece.

Aceite Fatia 2: tela de fatura com vencimento, mínimo, itens da competência, pagamento na conta não duplica gasto.

## 11. Referências

- Spec §23, §23.9, §37.4, §52 ADR-011.
- ADR-005, ADR-020, ADR-032.
- [Meu Pluggy (produto)](https://pluggy.ai/meu-pluggy) — API pessoal grátis, sem expiração.
- [pluggyai/meu-pluggy](https://github.com/pluggyai/meu-pluggy) — conector proxy, refresh diário.
- [meloluan/openfinance-analyst](https://github.com/meloluan/openfinance-analyst) — implementação pessoal de referência.
- [Pluggy update item](https://docs.pluggy.ai/docs/data-sync-update-an-item) — daily sync; batch proibido; janela OF 7 dias.
- [Pluggy bills](https://docs.pluggy.ai/docs/credit-card-bills) — Inter PF.
- [Steward + MeuPluggy](https://fi.paired.net/docs/pluggy).
- Res. Conjunta 7/2023 (prazo de consentimento OF).
- Ajuda Inter: fatura por e-mail; CSV de fatura descontinuado.
