#!/bin/bash
set -e

# Wait for database
until pg_isready -h "$DATABASE_HOST" -p 5432 -U "$DATABASE_USER"; do
  echo "Waiting for database to be ready..."
  sleep 2
done

echo "Running primary DB migrations..."
VERBOSE=true bundle exec rails db:migrate

echo "Running queue DB migrations..."
VERBOSE=true bundle exec rails db:migrate:queue

echo "Starting server..."
bundle exec puma -C config/puma.rb