#!/usr/bin/env bash
# Genera config/openclaw.json desde .env
# Uso: ./scripts/generate-openclaw-config.sh

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
TEMPLATE="$ROOT/config/openclaw.json.template"
OUT="$ROOT/config/openclaw.json"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "No existe .env. Copia .env.example a .env y rellena los valores." >&2
  exit 1
fi
if [[ ! -f "$TEMPLATE" ]]; then
  echo "No existe config/openclaw.json.template" >&2
  exit 1
fi

source_env() {
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    if [[ "$line" == *=* ]]; then
      key="${line%%=*}"
      key="${key%"${key##*[![:space:]]}"}"
      val="${line#*=}"
      val="${val#"${val%%[![:space:]]*}"}"
      val="${val%\"*}"
      val="${val#\"}"
      export "$key=$val"
    fi
  done < "$ENV_FILE"
}
source_env 2>/dev/null || true

# Escapar para JSON y para sed (replacement): \ " &
escape_json_sed() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/&/\\&/g'; }
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_BOT_TOKEN_ESC=$(escape_json_sed "$TELEGRAM_BOT_TOKEN")
OPENCLAW_GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-}"
if [[ -z "$OPENCLAW_GATEWAY_TOKEN" ]]; then
  if command -v uuidgen &>/dev/null; then
    OPENCLAW_GATEWAY_TOKEN="$(uuidgen)"
  else
    OPENCLAW_GATEWAY_TOKEN="$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "change-me-$(date +%s)")"
  fi
fi
GATEWAY_TOKEN_ESC=$(escape_json_sed "$OPENCLAW_GATEWAY_TOKEN")
ALLOW_FROM="${OPENCLAW_ALLOW_FROM:-}"
ALLOW_FROM_JSON="[]"
if [[ -n "$ALLOW_FROM" ]]; then
  ALLOW_FROM_JSON="[$(echo "$ALLOW_FROM" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | sed 's/^/"/;s/$/"/' | paste -sd,)]"
fi

mkdir -p "$(dirname "$OUT")"
sed -e "s|__TELEGRAM_BOT_TOKEN__|$TELEGRAM_BOT_TOKEN_ESC|g" \
    -e "s|__OPENCLAW_GATEWAY_TOKEN__|$GATEWAY_TOKEN_ESC|g" \
    -e "s|__OPENCLAW_ALLOW_FROM_JSON__|$ALLOW_FROM_JSON|g" \
    "$TEMPLATE" > "$OUT"
echo "Config generado: config/openclaw.json"
