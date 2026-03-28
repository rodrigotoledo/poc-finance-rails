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

```bash
git clone <repo>
cd credito-poc
cp .env.example .env   # ajuste RAILS_MASTER_KEY e SECRET_KEY_BASE se necessário
docker compose up --build
```

Na primeira execução o `bin/docker-dev-start-web.sh` roda as migrations automaticamente.

Acesse em: http://localhost:3000

## Comandos do dia-a-dia

```bash
docker compose up --build          # sobe tudo (build + start)
docker compose up                  # sobe sem rebuild
docker compose down                # derruba os containers
docker compose logs -f app         # logs da aplicação

docker compose run --rm app rails c          # Rails console
docker compose run --rm app rails db:migrate # migrations
docker compose run --rm app bash             # shell no container
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

## Estrutura de domínio (Rails)

```
app/
├── models/
│   ├── originador.rb          # empresa que antecipa recebíveis
│   ├── recebivel.rb           # título a ser antecipado
│   ├── operacao_credito.rb    # operação de antecipação
│   └── compliance/
│       └── gap_regulatorio.rb # mapeamento de gaps BACEN
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

- [x] Infra Docker Compose (PostgreSQL + Redis)
- [ ] Models: Originador, Recebivel, OperacaoCredito
- [ ] API REST de originadores
- [ ] Serviço de cálculo de antecipação
- [ ] Compliance: mapeamento de gaps BACEN
- [ ] Dashboard Next.js
- [ ] API Gateway NestJS
- [ ] Integração EventBridge (mock local)
