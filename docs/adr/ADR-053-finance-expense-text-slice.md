# ADR-053: Trecho de texto que marca despesa

## Status
Aceito

## Contexto
O leitor de notificações (ADR-011) transforma pushes em lançamentos do ledger com uma lista fixa de palavras (`compra`, `pix`, `cartão`…) e o nome do pacote do banco. Qualquer aviso do banco que tenha um valor vira movimentação, inclusive limite, marketing e boleto. O usuário precisa dizer, no módulo de finanças, qual pedaço de texto identifica uma despesa.

## Decisão
Por perfil, uma lista de trechos (`finance_expense_markers`, schema 47). Cada linha é um trecho.

- Lista vazia: o extrator continua com a detecção automática de hoje.
- Lista preenchida: uma notificação só vira **despesa** (saída) se o título ou o corpo contiver algum trecho. A comparação ignora maiúsculas e acentos.
- Entrada (Pix recebido, estorno, cashback) continua na detecção automática e não vira despesa por causa do trecho.
- Sem valor parseável, não há lançamento. OTP continua descartado antes do trecho.
- O trecho vale para notificações novas. Lançamentos já gravados não são reescritos.
- Lançamento manual não passa por esse filtro.
- O export JSON curado não lista a tabela. O backup SQLite (ADR-051) leva o arquivo inteiro.

## Consequências
- Trocar o trecho não apaga o extrato. Avisos que não casam ficam na lista de capturas, sem linha no ledger.
- Um trecho curto demais (menos de 2 caracteres) não é salvo.
