# Fatia Inter + leitor de notificações — notas de merge

Para quem for revisar ou mergear. Decisão de produto: [`INTER_BANKING_INTEGRATION.md`](INTER_BANKING_INTEGRATION.md) · ADR: [`ADR-011`](../adr/ADR-011-financial-imports-open-finance.md).

## Em uma frase

Histórico Inter entra por **OFX/CSV uma vez**. Gastos novos entram pelo **leitor de notificações Android** (sistema inteiro, não só banco). Sem Pluggy, sem Open Finance, sem scrape.

## O que foi feito

### Decisão (substitui o caminho anterior)

- **Não** usamos Meu Pluggy / agregador / API PJ / reverse engineering.
- **Sim:** importação de arquivo para o passado + `NotificationListenerService` para o contínuo.
- O leitor é uma **fila do sistema**: captura (quase) todas as notificações neste aparelho; nesta fatia só o extrator de **gastos débito/crédito** grava no ledger. Outros módulos reutilizam a mesma fila depois.

### Importação Inter (Finanças)

- Parser de OFX (SGML `STMTTRN`), CSV nativo Inter (`Data`/`Valor`, `;`) e CSV interno Colony.
- Preview → aplicar, com fingerprint. Reimportar o mesmo arquivo não duplica.
- Conta destino obrigatória para Inter/OFX. Botão **Criar contas Inter** (`Inter Conta` checking, `Inter Cartão` creditCard).
- Escolher arquivo `.ofx` / `.csv` ou colar o texto.

### Leitor de notificações (Integrações)

- Setup em 4 passos, texto explícito: aviso → interruptor no Colony → abrir ajustes do Android → os dois verdes.
- Opt-in **no app** e permissão **do sistema**. Desligar não apaga o ledger.
- Captura local (exceto contínuas, resumo de grupo, próprio app, OTP).
- Push Inter de compra no cartão → `Inter Cartão`. Pix/débito/TED → `Inter Conta`.
- Lista de capturas recentes, com indicação de “virou lançamento”.
- iOS: copy de “só arquivo nesta fatia”.

### Persistência e contrato

- Drift **schema 37**: tabela `captured_notifications` (não vai no export JSON — risco de OTP).
- Export permanece **v32**.
- `IntegrationKind.notificationListener`.
- Porta `BankConnector` / `InterLocalConnector` para trocar ingestão no futuro.

## O que foi alterado

| Área | Onde |
|------|------|
| Docs (estratégia única) | `docs/dev/INTER_BANKING_INTEGRATION.md`, `docs/adr/ADR-011-…`, addendum em ADR-020 |
| Domínio | `captured_notification`, pipeline de extratores, `InterStatementCodec`, `BankConnector` |
| Banco | `captured_notifications`, ingest + `ensureInterAccount`, migration v36→v37 |
| Android | `ColonyNotificationListenerService`, inbox JSONL, Method/EventChannel `colony/notifications` |
| UI | Integrações (setup numerado), Finanças (import OFX/CSV), strings em `app_strings.dart` |
| Testes | extrator/OFX, ingest no Drift, migration v37, widgets de Integrações e import |

Arquivos novos relevantes: Kotlin em `android/app/src/main/kotlin/com/fallhub/fallhub/`, `notification_capture_platform.dart`, `inter_local_connector.dart`.

O diff grande em `colony_database.g.dart` é o Drift regenerado (schema 37).

## Como validar no merge

1. `flutter analyze` (0 erros; infos/warnings não bloqueiam) e testes do app + `colony_domain` + `colony_database`.
2. No celular: importar um CSV/OFX Inter curto → preview → aplicar.
3. Ligar o leitor (app + ajustes) → compra de teste → lançamento em segundos.
4. Desligar o leitor → lançamentos anteriores continuam.

## Próximos passos (fora desta fatia)

1. **Mais extratores** na mesma fila (agenda, tarefas, saúde, viagens) — a captura já está pronta.
2. **Formatos de push** — ampliar parsers (fatura fechada, mais bancos, textos que o Inter mudar).
3. **Dedup cruzado** — notificação vs OFX posterior ainda pode duplicar se o fingerprint não bater (`notif:…` vs `ofx:FITID`). Melhorar heurística (valor+dia+conta) se isso incomodar na prática.
4. **Furos sem push** — lembrar o usuário de reimportar OFX; opcional: e-mail/Gmail só como reconciliação.
5. **iOS** — nesta fatia só arquivo; listener equivalente estável não existe.
6. **PDF da fatura** — Inter removeu CSV de cartão em alguns fluxos; PDF ainda não é parseado.
7. **Open Finance/Pluggy** — só se o produto virar comercial; a porta `BankConnector` já existe.

Não fazer: scrape do Super App, API privada, Accessibility para abrir o Inter, executar Pix/pagamento.
