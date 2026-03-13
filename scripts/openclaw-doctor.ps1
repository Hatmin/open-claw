# Ejecuta openclaw doctor --fix dentro del contenedor (migra la config al esquema actual).
# Uso: .\scripts\openclaw-doctor.ps1
# Debe ejecutarse desde la raíz del proyecto (donde está docker-compose.yml).

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
docker compose run -T --rm --entrypoint openclaw openclaw doctor --fix
