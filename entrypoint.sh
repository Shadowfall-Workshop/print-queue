#!/bin/bash
set -e

# Wait for database to be ready
echo ">>> Waiting for the database to be ready..."
until pg_isready -h "$DATABASE_HOST" -p 5432 -U "$DATABASE_USER"; do
  echo "Waiting for database to be ready..."
  sleep 2
done

# Prepare database (creates if not exists + runs migrations)
echo ">>> Running primary DB migrations..."
bundle exec rails db:migrate

# Copy SolidQueue migrations (if not already copied)
echo ">>> Copying SolidQueue migrations if needed..."
mkdir -p db/queue_migrate
cp -n $(bundle show solid_queue)/db/migrate/*.rb db/queue_migrate/ || true

# Run queue-specific migrations
echo ">>> Running queue DB migrations..."
bundle exec rails db:migrate:queue --trace

# Start the application server
echo ">>> Starting server..."
bundle exec puma -C config/puma.rb