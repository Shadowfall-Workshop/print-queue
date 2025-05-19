# Base image with Ruby 3.3
FROM mcr.microsoft.com/devcontainers/ruby:3.3

# Install PostgreSQL + Node.js + Yarn + dependencies
RUN apt-get update && apt-get install -y \
  postgresql \
  postgresql-client \
  postgresql-contrib \
  libpq-dev \
  nodejs \
  yarn \
  && rm -rf /var/lib/apt/lists/*