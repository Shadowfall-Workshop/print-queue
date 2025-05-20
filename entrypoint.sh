#!/bin/bash
set -e

echo ">>> Waiting for the database to be ready..."
until pg_isready -h "$DATABASE_HOST" -p 5432 -U "$DATABASE_USER"; do
  sleep 1
done

echo ">>> Running database migrations..."
bundle exec rails db:migrate
bundle exec rails db:migrate:queue
bundle exec rails db:migrate:cable
bundle exec rails db:migrate:cache

echo ">>> Precompiling assets..."
bundle exec rails assets:precompile

echo ">>> Starting the server..."
exec "$@"