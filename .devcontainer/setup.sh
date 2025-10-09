#!/usr/bin/env bash
set -e

echo "===== Detecting Codespace URL and updating Rails config ====="
if [ -n "$CODESPACE_NAME" ]; then
  HOST_URL="https://${CODESPACE_NAME}-3000.app.github.dev"
  DEV_FILE="config/environments/development.rb"

  # Replace or append the default_url_options config
  if grep -q "config.action_controller.default_url_options" "$DEV_FILE"; then
    sed -i "s|config\.action_controller\.default_url_options.*|  config.action_controller.default_url_options = { host: '${HOST_URL}' }|" "$DEV_FILE"
  else
    sed -i "/^end$/i \  # Set default host for Codespaces\n  config.action_controller.default_url_options = { host: '${HOST_URL}' }\n" "$DEV_FILE"
  fi

  echo "✅ Updated development.rb with host: ${HOST_URL}"
else
  echo "⚠️ Could not detect CODESPACE_NAME; skipping host update."
fi

echo "===== Updating system packages ====="
sudo apt-get update -y
sudo apt-get upgrade -y

echo "===== Installing PostgreSQL 16 ====="
# Add PostgreSQL APT repository for version 16
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update -y
sudo apt-get install -y postgresql-16 postgresql-client-16 libpq-dev

echo "===== Starting PostgreSQL ====="
sudo service postgresql start

echo "===== Setting up PostgreSQL user and databases ====="
# Run the same commands you'd enter manually inside the postgres shell
sudo su - postgres <<'EOF'
psql <<SQL
ALTER USER postgres WITH PASSWORD 'postgres';
CREATE DATABASE print_queue_development OWNER postgres;
CREATE DATABASE print_queue_development_cable OWNER postgres;
CREATE DATABASE print_queue_development_queue OWNER postgres;
SQL
exit
EOF

echo "===== Installing Ruby dependencies ====="
bundle install

echo "===== Running Rails setup ====="
rails db:migrate
rails assets:precompile

echo "===== Setup complete! ====="
