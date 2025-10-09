#!/bin/bash
set -e

echo "===== Installing gems ====="
bundle check || bundle install

echo "===== Updating apt packages ====="
sudo apt update -y
sudo apt upgrade -y

echo "===== Installing PostgreSQL if missing ====="
if ! command -v psql &> /dev/null; then
    sudo apt install -y postgresql postgresql-contrib libpq-dev
fi

echo "===== Starting PostgreSQL ====="
sudo service postgresql start

echo "===== Setting up PostgreSQL user ====="
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='postgres';" | grep -q 1 || \
    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';"

echo "===== Creating databases ====="
DBS=("print_queue_development" "print_queue_development_cable" "print_queue_development_queue")
for db in "${DBS[@]}"; do
    if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$db"; then
        sudo -u postgres createdb -O postgres "$db"
        echo "Created database $db"
    else
        echo "Database $db already exists"
    fi
done

echo "===== Running Rails setup ====="
rails db:create db:migrate

echo "===== Precompiling assets ====="
rails assets:precompile

echo "===== Setup complete! ====="
