#!/bin/sh
# Crea auth-profiles.json en volumen nombrado (evita EPERM chmod en bind mount Windows).
# Si corre como root, crea dirs/archivo, chown a node, y ejecuta el comando como usuario node.

set -e
AGENT_AUTH_DIR="/home/node/.openclaw/agents/main/agent"

if [ "$(id -u)" = "0" ]; then
  mkdir -p "$AGENT_AUTH_DIR"
  if [ ! -f "$AGENT_AUTH_DIR/auth-profiles.json" ]; then
    cat > "$AGENT_AUTH_DIR/auth-profiles.json" << 'AUTHEOF'
{
  "profiles": {
    "openrouter:default": {
      "provider": "openrouter",
      "mode": "api_key",
      "keyRef": { "source": "env", "provider": "default", "id": "OPENROUTER_API_KEY" }
    }
  },
  "order": {
    "openrouter": ["openrouter:default"]
  }
}
AUTHEOF
  fi
  chown -R 1000:1000 /home/node/.openclaw/agents
  exec runuser -u node -- "$@"
else
  mkdir -p "$AGENT_AUTH_DIR"
  if [ ! -f "$AGENT_AUTH_DIR/auth-profiles.json" ]; then
    cat > "$AGENT_AUTH_DIR/auth-profiles.json" << 'AUTHEOF'
{
  "profiles": {
    "openrouter:default": {
      "provider": "openrouter",
      "mode": "api_key",
      "keyRef": { "source": "env", "provider": "default", "id": "OPENROUTER_API_KEY" }
    }
  },
  "order": {
    "openrouter": ["openrouter:default"]
  }
}
AUTHEOF
  fi
  exec "$@"
fi
