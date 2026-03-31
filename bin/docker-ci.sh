#!/usr/bin/env bash
# Suite de CI Rails a correr **dentro do contentor** (compose.ci.yml → ci-rails).
# Não executar no host: use `make rails-ci` na raiz do monorepo ou o workflow GitHub Actions.
set -euo pipefail
export RAILS_ENV=test
export CI=true
export COVERAGE="${COVERAGE:-true}"
export DATABASE_URL="${DATABASE_URL:-postgresql://postgres:postgres@db:5432/credito_poc_test}"

mkdir -p test-results

echo "== db:test:prepare =="
bundle exec rails db:test:prepare

echo "== rails test =="
bundle exec rails test

echo "== rubocop =="
bundle exec rubocop -f github

echo "== brakeman =="
bin/brakeman --no-pager

echo "== importmap audit =="
bin/importmap audit

if [ "${COVERAGE}" = "true" ] && [ -f coverage/.last_run.json ]; then
  echo "== coverage (line) =="
  ruby -rjson -e 'puts "Line coverage: #{JSON.parse(File.read(%q(coverage/.last_run.json)))[%q(result)][%q(line)]}%"'
fi

echo "== docker-ci.sh OK =="
