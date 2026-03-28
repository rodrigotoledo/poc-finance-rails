#!/usr/bin/env bash
set -xeuo pipefail

if [[ -f ./tmp/pids/server.pid ]]; then
  rm ./tmp/pids/server.pid
fi

bundle

# Só executa setup do banco se estiver no ambiente de desenvolvimento
if [[ "${RAILS_ENV:-development}" == "development" ]]; then
  if [[ "${FORCE_DB_CREATE:-false}" == "true" ]]; then
    bin/rails db:drop || true  # Ignora erro se não existir
    bin/rails db:create
    bin/rails db:environment:set RAILS_ENV=development
    touch .db-created
  fi

  bin/rails db:migrate

  if [[ "${FORCE_DB_SEED:-false}" == "true" ]]; then
    bin/rails db:seed
    touch .db-seeded
  fi
fi

# Carrega o schema para o ambiente de test se estiver no test
if [[ "${RAILS_ENV:-development}" == "test" ]]; then
  bin/rails db:schema:load
fi

exec "./bin/dev"