# Dockerfile
FROM mcr.microsoft.com/devcontainers/ruby:3.2-bullseye

RUN apt-get update && \
    apt-get install -y postgresql postgresql-contrib libpq-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
