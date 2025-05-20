#!/bin/bash
set -e

echo ">>> Waiting for the database to be ready..."
until pg_isready -h "$DATABASE_HOST" -p 5432 -U "$DATABASE_USER"; do
  sleep 1
done

echo "Running DB setup..."
bundle exec rails db:prepare

echo ">>> Precompiling assets..."
bundle exec rails assets:precompile

echo ">>> Starting the server..."
exec "$@"