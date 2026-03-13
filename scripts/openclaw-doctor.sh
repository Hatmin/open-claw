#!/usr/bin/env bash
# Ejecuta openclaw doctor --fix dentro del contenedor (migra la config al esquema actual).
# Uso: ./scripts/openclaw-doctor.sh

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
docker compose run -T --rm --entrypoint openclaw openclaw doctor --fix
