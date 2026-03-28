# Crédito POC — Infraestrutura de Mercado de Crédito

Stack financeiro com Rails 8 API · AWS-ready · BACEN-compliant

## Stack

| Camada | Tecnologia |
|--------|-----------|
| Frontend | Next.js 14 + Tailwind |
| API Gateway | NestJS + JWT/OAuth2 |
| Domínio de Recebíveis | **Rails 8 API** ← você está aqui |
| Compliance BACEN | NestJS |
| Banco principal | PostgreSQL 16 (RDS Multi-AZ em prod) |
| Cache | Redis 7 (ElastiCache em prod) |
| Background Jobs | Solid Queue (Postgres-backed) |
| Eventos | EventBridge + SQS FIFO (simulado local via Solid Queue) |

## Pré-requisitos

- Docker Desktop >= 4.x

## Setup inicial

O arquivo de stack é `compose.yml` (Docker Compose usa esse arquivo por padrão ao rodar na raiz do projeto).

```bash
git clone <repo>
cd credito-poc
cp .env.example .env
```

No `.env`, além das chaves Rails, defina **`USER_ID`** e **`GROUP_ID`** com o mesmo usuário do macOS (evita arquivos criados pelo Docker com dono errado e o Cursor não salvar):

```bash
id -u   # ex.: 501
id -g   # ex.: 20
# Edite .env: USER_ID=501 e GROUP_ID=20 (seus valores)
```

Depois:

```bash
docker compose build --no-cache app guard   # primeira vez ou após mudar USER_ID/GROUP_ID
docker compose up --build
```

**Se ainda não conseguir editar** (ex.: `app/jobs/application_job.rb` não salva no Cursor), na raiz do projeto:

```bash
./bin/fix-host-file-permissions
./bin/verify-docker-user   # UID do container deve ser igual ao `id -u` do Mac; se não, ajuste USER_ID/GROUP_ID no .env e: docker compose build --no-cache app guard
```

O script de permissões faz `chown`, `chmod u+rwX`, no macOS também `chflags nouchg` e `xattr -cr` (remove atributos que às vezes travam o editor).

Na primeira execução o `bin/docker-dev-start-web.sh` roda as migrations automaticamente.

**Gems e comandos Rails:** use sempre o container `app` (ex.: `docker compose run --rm app bundle install` se alterar o `Gemfile`). Evite `bundle`/`rails` direto no host salvo ambiente local explícito.

Acesse em: http://localhost:3000

### API REST (Rails, v1)

Base: `http://localhost:3000/api/v1`

| Resource | Example |
|----------|---------|
| Originators | `GET /api/v1/originators` |
| Receivables | `GET /api/v1/receivables` (filter: `?originator_id=1`) |
| Credit operations | `GET /api/v1/credit_operations` (`?originator_id=` / `?receivable_id=`) |
| Regulatory gaps | `GET /api/v1/regulatory_gaps` (`?credit_operation_id=`) |

JSON keys use English (e.g. `originator: { legal_name, tax_id }`, `receivable: { reference_number, amount_cents, due_on }`). `DELETE` performs a **soft delete** (see Discard above).

## Comandos do dia-a-dia

```bash
docker compose up --build          # sobe tudo (build + start)
docker compose up                  # sobe sem rebuild
docker compose down                # derruba os containers
docker compose logs -f app         # logs da aplicação

docker compose run --rm app rails c          # Rails console
docker compose run --rm app rails db:migrate # migrations
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

Reset completo (apaga volumes):

```bash
docker compose down -v
docker compose up --build
```

## Variáveis de ambiente

Copie `.env.example` para `.env`. Os valores já vêm preenchidos com defaults para dev.

| Variável | Descrição |
|----------|-----------|
| `RAILS_MASTER_KEY` | Chave de descriptografia das credentials |
| `SECRET_KEY_BASE` | Chave de sessão/tokens |
| `DATABASE_URL` | URL de conexão PostgreSQL |
| `REDIS_URL` | URL de conexão Redis |

**Nunca commite `.env`.**

## Configuração Redis

| DB | Uso |
|----|-----|
| 0 | Cache / jobs |

## Gems (domínio + dev)

| Gem | Uso |
|-----|-----|
| [discard](https://github.com/jhawthorn/discard) | Soft delete (`discarded_at`); `DELETE` na API chama `discard`, não remove a linha. Índices únicos parciais (`WHERE discarded_at IS NULL`) em `tax_id` e `(originator_id, reference_number)`. |
| [money-rails](https://github.com/RubyMoney/money-rails) | Valores monetários em `*_cents` com `Money` (`monetize`); moeda padrão **BRL** em `config/initializers/money.rb`. |
| [faker](https://github.com/faker-ruby/faker) | Dados fictícios em seeds / testes. |
| [bullet](https://github.com/flyerhzm/bullet) | Alertas de N+1 no log em **development** (`config/environments/development.rb`). |
| [guard](https://github.com/guard/guard) + [guard-minitest](https://github.com/guard/guard-minitest) | Re-roda testes ao salvar arquivos; use o serviço Compose `guard` (ver seção acima). |
| [rails-i18n](https://github.com/svenfuchs/rails-i18n) | Dados de locale para Rails (pt-BR, en, …). |
| [simplecov](https://github.com/simplecov-ruby/simplecov) | Cobertura com `bin/docker-test`: **ligada por padrão** (resumo no terminal + `coverage/index.html`). Desligar: `COVERAGE=false`. `rails test` direto não ativa SimpleCov. |

Após alterar o `Gemfile`: `docker compose run --rm app bundle install`.

Não usamos **annotate** / anotação automática de schema nos models: o gem clássico não resolve com ActiveRecord 8.x; manteremos só o que o `db/schema.rb` e o código já documentam.

## Estrutura de domínio (Rails)

```
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
    ├── sync_cerc_job.rb       # sincronização com CERC
    └── bacen_report_job.rb    # envio de relatórios regulatórios
```

## Roadmap POC

- [x] Infra Docker Compose (PostgreSQL + Redis) — `compose.yml`
- [x] Models: Originator, Receivable, CreditOperation, Compliance::RegulatoryGap
- [x] API REST v1 (English resources, see table above)
- [x] Soft delete (Discard) + money types (money-rails, BRL) + dev tooling (Faker, Bullet)
- [x] Minitest + Guard (`compose.yml` service `guard`, `bin/docker-test`)
- [x] i18n en + pt-BR (rails-i18n, locale na API) + SimpleCov (default em `bin/docker-test`)
- [ ] Serviço de cálculo de antecipação
- [ ] Compliance: mapeamento de gaps BACEN
- [ ] Dashboard Next.js
- [ ] API Gateway NestJS
- [ ] Integração EventBridge (mock local)
