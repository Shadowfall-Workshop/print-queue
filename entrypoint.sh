#!/bin/bash
set -e

# Wait for database
until pg_isready -h "$DATABASE_HOST" -p 5432 -U "$DATABASE_USER"; do
  echo "Waiting for database to be ready..."
  sleep 2
done

echo "Running primary DB migrations..."
bundle exec rails db:migrate

echo "Installing SolidQueue migrations if needed..."
bundle exec rails solid_queue:install:migrations

echo "Running queue DB migrations..."
bundle exec rails db:migrate:queue --trace

echo "Starting server..."
bundle exec puma -C config/puma.rb