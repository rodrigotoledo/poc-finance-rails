# Crédito POC — Serviço Rails (API)

Este README cobre **setup local**, **Docker**, **API REST**, importações e **comandos** do serviço em `credito-poc/`.

Para **visão de produto**, **arquitetura alvo** (Next.js + mobile → Rails) e **roadmap**, use o README da raiz: **[../README.md](../README.md)**.

---

## Stack (este serviço)

| Camada | Tecnologia |
| ------ | ---------- |
| Frontend | Next.js 15 + Tailwind |
| Domínio de Recebíveis | **Rails 8 API** ← você está aqui |
| Banco principal | PostgreSQL 16 (RDS Multi-AZ em prod) |
| Cache | Redis 7 (ElastiCache em prod) |
| Background Jobs | Sidekiq (Redis-backed) |
| Eventos | Redis pub/sub (SSE no Next) |

## Pré-requisitos

- Docker Desktop >= 4.x

## Regra: só Docker (sem bundle/rails/npm no host)

**Não instale nem execute** Ruby gems, Rails, Rake, migrations ou Postgres “à mão” no macOS/Linux. Use **sempre** Docker (e a infra em `poc-finance-base/compose.infra.yml`), por exemplo:

| No host (evitar) | Com Docker (usar) |
| --------------- | ----------------------------------------- |
| `bundle install` | `docker compose run --rm app bundle install` |
| `rails db:migrate` | `docker compose run --rm app rails db:migrate` |
| `rails db:seed` | `docker compose run --rm app rails db:seed` |
| `rails c` | `docker compose run --rm app rails c` |

Na primeira subida, o script de arranque em contentor já aplica migrations quando adequado.

## Setup inicial

Postgres e Redis estão em `poc-finance-base/compose.infra.yml` na **raiz** do monorepo; este diretório tem só os serviços Rails (`app`, `sidekiq`, `guard`) em `compose.yml`.

**Opção A — a partir da raiz do repositório** (`poc-financer/`), só Rails + infra:

```bash
git clone <repo>
cd poc-financer/poc-finance-rails
cp .env.example .env
cd ..
docker compose -f poc-finance-rails/compose.yml -f poc-finance-base/compose.infra.yml up --build
```

**Opção B — a partir deste diretório** (`poc-finance-rails/`), para não repetir `-f` em todo o lado:

```bash
cd poc-finance-rails
cp .env.example .env
docker compose -f compose.standalone.yml up --build
docker compose build --no-cache app guard   # primeira vez ou após mudar USER_ID/GROUP_ID
docker compose up --build
```

Os exemplos abaixo assumem que você está usando `compose.standalone.yml` (ou equivalente na raiz com `-f`).

No `.env`, além das chaves Rails, defina **`USER_ID`** e **`GROUP_ID`** com o mesmo usuário do macOS (evita arquivos criados pelo Docker com dono errado e o Cursor não salvar):

```bash
id -u   # ex.: 501
id -g   # ex.: 20
# Edite .env: USER_ID=501 e GROUP_ID=20 (seus valores)
```

**Stack completo (Rails + Next + infra)** na raiz: `docker compose up --build` (ver [compose.yml](../compose.yml) no repositório).

**Se ainda não conseguir editar** (ex.: `app/jobs/application_job.rb` não salva no Cursor), na raiz do projeto:

```bash
./bin/fix-host-file-permissions
./bin/verify-docker-user   # UID do container deve ser igual ao `id -u` do Mac; se não, ajuste USER_ID/GROUP_ID no .env e: docker compose build --no-cache app guard  (com COMPOSE_FILE como no setup)
```

O script de permissões faz `chown`, `chmod u+rwX`, no macOS também `chflags nouchg` e `xattr -cr` (remove atributos que às vezes travam o editor).

Na primeira execução o `bin/docker-dev-start-web.sh` roda as migrations automaticamente.

**Gems e comandos Rails:** use **apenas** o container `app` (ex.: `docker compose run --rm app bundle install` após alterar o `Gemfile`). **Não** use `bundle`/`rails`/`rake` no host — não faz parte do fluxo suportado deste repositório.

Acesse em: `http://localhost:3000`

### API REST (Rails, v1)

Base: `http://localhost:3000/api/v1`

| Resource | Example |
| -------- | ------- |
| Originators | `GET /api/v1/originators` |
| Receivables | `GET /api/v1/receivables` (filter: `?originator_id=1`) |
| Credit operations | `GET /api/v1/credit_operations` (`?originator_id=` / `?receivable_id=`) |
| Regulatory gaps | `GET /api/v1/regulatory_gaps` (`?credit_operation_id=`) |
| Imports | `POST /api/v1/imports` · `GET /api/v1/imports` · `GET /api/v1/imports/:id` |

JSON keys use English (e.g. `originator: { legal_name, tax_id }`, `receivable: { reference_number, amount_cents, due_on }`). `DELETE` performs a **soft delete** (see Discard above).

### Importação em lote (CSV / XLSX)

Envie um ficheiro **CSV** ou **XLSX** com recebíveis para processamento assíncrono em background.

#### Leitura do ficheiro (CSV vs XLSX)

- **CSV:** biblioteca padrão **`CSV`** (`CSV.read` com `headers: true` e `liberal_parsing: true`), depois cada linha vira um `Hash` com chaves string (nomes das colunas).
- **XLSX:** gem **[Roo](https://github.com/roo-rb/roo)** — **`Roo::Excelx`** abre a folha, lê a primeira linha como cabeçalhos e as restantes como linhas de dados, também normalizadas para hashes com chaves string. Não se usa parsing manual de XML nem `float` para dinheiro.
- **Valores monetários (`amount` na folha):** no job de chunk, **`BigDecimal`** converte o texto (vírgula ou ponto como separador decimal) para **centavos** antes de atribuir a `amount_cents`; erros de parse caem em `rescue` e a linha falha com validação segura, sem `Float` intermédio.
- **Persistência:** cada linha válida passa por **`Receivable`** + **money-rails** (`monetize :amount_cents`) e validações Active Record, como qualquer criação pela API.

Os exemplos em `lib/samples/*.xlsx` são gerados com **[caxlsx](https://github.com/caxlsx/caxlsx)** (`rake samples:generate`); a importação lê esses ficheiros com Roo.

#### Como os “batches” e chunks funcionam

- O registro do lote na API é o model **`ImportBatch`** (metadados, contadores, erros amostrados).
- O job **`ProcessImportFileJob`** (fila `imports`) lê o ficheiro (CSV ou XLSX conforme acima), calcula o total de linhas e reparte as linhas em **fatias de 1.000** com **`Enumerable#each_slice`** — **chunking em memória** sobre um array de hashes, **não** é `ActiveRecord::Relation#in_batches` nem `find_in_batches` (esses servem para percorrer **linhas já gravadas no PostgreSQL** em blocos).
- Cada fatia vira um **`ImportChunkJob`** enfileirado à parte; vários chunks podem correr em paralelo (Sidekiq), e o batch agrega `processed_rows` / `failed_rows` / `row_errors` quando cada chunk termina.

**Memória:** o conteúdo é **materializado em memória** após a leitura (lista completa de linhas antes do slice). Ficheiros muito grandes aumentam o uso de RAM; evolução natural: **streaming** de CSV e/ou leitura incremental no XLSX, enfileirando chunks sem carregar o ficheiro inteiro de uma vez.

**Colunas esperadas:**

| Coluna | Obrigatório | Exemplo |
| ------ | ----------- | ------- |
| `originator_tax_id` | não* | `12345678000195` |
| `reference_number` | sim | `RECV-2025-000001` |
| `amount` | sim | `1500.00` |
| `due_on` | sim | `2025-12-31` |
| `status` | não | `pending` (default) |

\* Se omitido, usa o `originator_id` passado na requisição.

**Iniciar uma importação:**

```bash
# CSV
curl -X POST http://localhost:3000/api/v1/imports \
     -F "file=@lib/samples/receivables_batch_1.csv" \
     -F "originator_id=1"

# XLSX
curl -X POST http://localhost:3000/api/v1/imports \
     -F "file=@lib/samples/receivables_batch_1.xlsx" \
     -F "originator_id=1"
```

**Consultar status do lote:**

```bash
curl http://localhost:3000/api/v1/imports/1
```

Resposta:

```json
{
  "id": 1,
  "filename": "receivables_batch_1.csv",
  "file_type": "csv",
  "originator_id": 1,
  "status": "processing",
  "total_rows": 10000,
  "processed_rows": 3000,
  "failed_rows": 47,
  "error_sample": [
    { "row": 12, "errors": ["Status is not included in the list"] },
    { "row": 305, "errors": ["Amount cents must be greater than 0"] }
  ],
  "created_at": "2025-03-28T00:00:00.000Z",
  "updated_at": "2025-03-28T00:00:10.000Z"
}
```

**Listar todos os lotes:**

```bash
curl http://localhost:3000/api/v1/imports
```

**Status possíveis:** `pending` → `processing` → `completed` / `failed`

**Testes automatizados:** `test/models/import_batch_test.rb`, `test/jobs/process_import_file_job_test.rb`, `test/jobs/import_chunk_job_test.rb`, `test/controllers/api/v1/imports_controller_test.rb`. Nos testes de integração que enfileiram `ProcessImportFileJob` → `ImportChunkJob`, a fila é esvaziada com `drain_enqueued_jobs` (ver `test/support/active_job_drain.rb`), porque `perform_enqueued_jobs` só processa um nível por invocação no adapter `:test`.

**Arquivos de amostra** em `lib/samples/` (5 CSV + 5 XLSX, 10.000 linhas cada, com erros intencionais para exercitar a pipeline):

| Arquivo | Tipo de erro injetado | Taxa |
| ------- | --------------------- | ---- |
| `receivables_batch_1.*` | Status inválido | ~5 % |
| `receivables_batch_2.*` | Amount ausente / data mal formada | ~10 % |
| `receivables_batch_3.*` | `reference_number` ausente | ~3 % |
| `receivables_batch_4.*` | Amount negativo ou não-numérico | ~15 % |
| `receivables_batch_5.*` | Originator desconhecido / linha em branco | ~5 % |

Para regenerar os arquivos de amostra (com `COMPOSE_FILE` exportado em `credito-poc/`):

```bash
docker compose run --rm app rake samples:generate
```

**Teste em massa (bulk test):**

Sobe os originators de amostra (se não existirem), envia todos os 10 arquivos para a API e faz polling do status até todos os batches terminarem:

```bash
# app deve estar rodando em outro terminal: docker compose up
docker compose run --rm app rake imports:bulk_test
```

Saída esperada:

```text
------------------------------------------------------------------------------------------
  Bulk import test
  API: http://app:3000
  Samples dir: /app/lib/samples
------------------------------------------------------------------------------------------
Ensuring sample originators exist...
  12345678000195  ->  #1 Sample Originator 1
  ...

Uploading 10 files to http://app:3000/api/v1/imports ...

  [01] receivables_batch_1.csv              -> batch #1  (status: pending)
  [02] receivables_batch_1.xlsx             -> batch #2  (status: pending)
  ...

  ID     File                                      Status       Total  Processed    Failed
  --------...
  1      receivables_batch_1.csv                   PROCESSING   10000       5000       247
  ...
```

### Painel de jobs (Mission Control)

O processamento assíncrono roda em Sidekiq (container `sidekiq` no Compose).

Para depuração local, use logs:

```bash
docker compose logs -f sidekiq
```

## Comandos do dia-a-dia

Na pasta `poc-finance-rails/`, use `compose.standalone.yml` para incluir Postgres e Redis.

```bash
docker compose up --build          # sobe tudo (build + start)
docker compose up                  # sobe sem rebuild
docker compose down                # derruba os containers
docker compose logs -f app         # logs da aplicação
docker compose logs -f sidekiq     # logs do Sidekiq

docker compose run --rm app rails c          # Rails console
docker compose run --rm app rails db:migrate # migrations
docker compose run --rm app rails db:seed    # seeds
docker compose run --rm app bundle install   # após mudar Gemfile
docker compose run --rm app bash             # shell no container
docker compose run --rm app bin/docker-test  # Minitest + SimpleCov (resumo no terminal + HTML em coverage/)
docker compose run --rm -e COVERAGE=false app bin/docker-test  # sem cobertura (mais rápido)
```

### i18n (en + pt-BR)

- **Locales:** `en` (padrão) e `pt-BR` — `config/application.rb`.
- **Traduções Rails (errors, datas, etc.):** gem **rails-i18n**; mensagens de modelo customizadas em `config/locales/models.en.yml` e `models.pt-BR.yml`.
- **API:** `Api::V1::BaseController` usa `LocaleFromRequest`. Ordem de resolução:
  1. **`?lang=`** — se o valor existir em `I18n.available_locales` (ex.: `pt-br`, `pt-BR`, `en`), usa; se for passado mas **inválido** (ex.: `fr`), a requisição fica em **`en`** (ignora `Accept-Language`).
  2. **`?locale=`** — mesmo critério de match, sem forçar `en` em valor inválido (compatibilidade).
  3. Cabeçalho **`Accept-Language`**.
  4. Padrão **`en`**.
  `errors.full_messages` seguem o locale efetivo.
- Novas strings: só chaves I18n nos YAML (sem texto solto em Ruby para mensagens ao usuário).

### Guard (Minitest contínuo ao salvar)

O serviço `guard` usa `LISTEN_GEM_POLLING` para file watching em volumes Docker no macOS. Código e gems ficam no volume montado (`.:/app`); o banco de teste é `credito_poc_test` via `DATABASE_URL` no serviço.

```bash
docker compose up guard
# outro terminal, shell no mesmo container (enquanto o Guard está rodando):
docker compose exec guard bash
```

Forçar recriação do banco e seed:

```bash
FORCE_DB_CREATE=true FORCE_DB_SEED=true docker compose up --build
```

Reset completo (apaga volumes de Postgres/Redis deste projeto; use o mesmo `COMPOSE_FILE`):

```bash
docker compose down -v
docker compose up --build
```

## Variáveis de ambiente

Copie `.env.example` para `.env`. Os valores já vêm preenchidos com defaults para dev.

| Variável | Descrição |
| -------- | --------- |
| `RAILS_MASTER_KEY` | Chave de descriptografia das credentials |
| `SECRET_KEY_BASE` | Chave de sessão/tokens |
| `DATABASE_URL` | URL de conexão PostgreSQL |
| `REDIS_URL` | URL de conexão Redis |

**Nunca commite `.env`.**

## Configuração Redis

| DB | Uso |
| -- | --- |
| 0 | Cache / jobs / Sidekiq (Rails) |
| 1 | Reservado (futuro) |

## Gems (domínio + dev)

| Gem | Uso |
| --- | --- |
| [discard](https://github.com/jhawthorn/discard) | Soft delete (`discarded_at`); `DELETE` na API chama `discard`, não remove a linha. Índices únicos parciais (`WHERE discarded_at IS NULL`) em `tax_id` e `(originator_id, reference_number)`. |
| [money-rails](https://github.com/RubyMoney/money-rails) | Valores monetários em `*_cents` com `Money` (`monetize`); moeda padrão **BRL** em `config/initializers/money.rb`. |
| [faker](https://github.com/faker-ruby/faker) | Dados fictícios em seeds / testes. |
| [bullet](https://github.com/flyerhzm/bullet) | Alertas de N+1 no log em **development** (`config/environments/development.rb`). |
| [guard](https://github.com/guard/guard) + [guard-minitest](https://github.com/guard/guard-minitest) | Re-roda testes ao salvar arquivos; use o serviço Compose `guard` (ver seção acima). |
| [rails-i18n](https://github.com/svenfuchs/rails-i18n) | Dados de locale para Rails (pt-BR, en, …). |
| [simplecov](https://github.com/simplecov-ruby/simplecov) | Cobertura com `bin/docker-test`: **ligada por padrão** (resumo no terminal + `coverage/index.html`). Desligar: `COVERAGE=false`. `rails test` direto não ativa SimpleCov. |
| [csv](https://github.com/ruby/csv) | Leitura de CSV na importação (`ProcessImportFileJob`); gem explícita no Ruby 4+. |
| [roo](https://github.com/roo-rb/roo) | Leitura de **XLSX** na importação via `Roo::Excelx`. |
| [caxlsx](https://github.com/caxlsx/caxlsx) | Geração dos XLSX de exemplo em `lib/samples/` (`rake samples:generate`). |

Após alterar o `Gemfile`: `docker compose run --rm app bundle install`.

Não usamos **annotate** / anotação automática de schema nos models: o gem clássico não resolve com ActiveRecord 8.x; manteremos só o que o `db/schema.rb` e o código já documentam.

## Estrutura de domínio (Rails)

```text
app/
├── models/
│   ├── originator.rb          # counterparty / originator (receivables market)
│   ├── receivable.rb          # receivable title
│   ├── credit_operation.rb    # credit / advance operation
│   └── compliance/
│       └── regulatory_gap.rb  # regulatory gap tracking (BACEN, etc.)
├── services/
│   ├── antecipacao/
│   │   ├── calculator_service.rb
│   │   └── eligibility_service.rb
│   └── bacen/
│       └── report_service.rb
└── jobs/
    ├── application_job.rb
    ├── process_import_file_job.rb  # lê CSV (stdlib) ou XLSX (Roo::Excelx), fatia linhas, enfileira chunks
    └── import_chunk_job.rb         # grava recebíveis por chunk (BigDecimal → centavos, validações AR)
```

## Roadmap POC

- [x] Infra Docker Compose (PostgreSQL + Redis) — `compose.yml`
- [x] Models: Originator, Receivable, CreditOperation, Compliance::RegulatoryGap
- [x] API REST v1 (English resources, see table above)
- [x] Soft delete (Discard) + money types (money-rails, BRL) + dev tooling (Faker, Bullet)
- [x] Minitest + Guard (`compose.yml` service `guard`, `bin/docker-test`)
- [x] i18n en + pt-BR (rails-i18n, locale na API) + SimpleCov (default em `bin/docker-test`)
- [x] Importação CSV/XLSX (Roo `Excelx`, CSV stdlib, BigDecimal para `amount`, jobs Solid Queue)
- [ ] Serviço de cálculo de antecipação
- [ ] Compliance: mapeamento de gaps BACEN
- [ ] Dashboard Next.js
- [ ] Integração EventBridge (mock local)
