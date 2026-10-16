#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Validating Docker Compose configuration..."
docker compose config >/dev/null

echo "Pulling application images..."
docker compose pull

echo "Starting services..."
docker compose up -d --remove-orphans

echo
echo "Service status:"
docker compose ps

echo
echo "Running public health checks..."
./scripts/health-check.sh
