# open-claw

Bot de Telegram conectado a [OpenClaw](https://openclaw.ai/) mediante la imagen Docker oficial. OpenClaw incluye canal Telegram nativo; solo hace falta configurar variables y arrancar.

## Requisitos

- Docker y Docker Compose v2
- Al menos 2 GB RAM para el contenedor
- Cuenta en Telegram y token de bot ([@BotFather](https://t.me/BotFather))
- Al menos una API key de LLM (OpenAI, Anthropic, etc.) para que el agente responda

## Configuración (solo rellenar .env)

1. **Copiar plantilla de variables**
   ```bash
   cp .env.example .env
   ```

2. **Editar `.env`** y rellenar:
   - `TELEGRAM_BOT_TOKEN`: token del bot de Telegram (BotFather).
   - `OPENCLAW_ALLOW_FROM`: tu(s) ID(s) de usuario de Telegram, separados por coma (sin espacios). Para obtener tu ID: enviar `/start` a [@userinfobot](https://t.me/userinfobot).
   - `OPENCLAW_GATEWAY_TOKEN`: token para la Control UI (opcional; si está vacío se genera uno al ejecutar el script).
   - Al menos una clave de proveedor: `OPENAI_API_KEY` y/o `ANTHROPIC_API_KEY` (y las que quieras usar).

3. **Generar la config de OpenClaw** desde `.env`:
   - **Windows (PowerShell):**
     ```powershell
     .\scripts\generate-openclaw-config.ps1
     ```
   - **Linux / macOS:**
     ```bash
     chmod +x scripts/generate-openclaw-config.sh
     ./scripts/generate-openclaw-config.sh
     ```
   Se crea `config/openclaw.json` (no versionado; ya está en `.gitignore`).

4. **Arrancar**
   ```bash
   docker compose up -d
   ```

5. **Comprobar**
   - Control UI: http://127.0.0.1:18789/ (token = valor de `OPENCLAW_GATEWAY_TOKEN` en `.env`).
   - Health: `curl -s http://127.0.0.1:18789/healthz`
   - En Telegram: abre un chat con tu bot y envía un mensaje (solo si tu ID está en `OPENCLAW_ALLOW_FROM`).

## Estructura del proyecto

- `.env.example`: plantilla de variables (copiar a `.env`).
- `config/openclaw.json.template`: plantilla de config; el script la usa para generar `config/openclaw.json`.
- `config/openclaw.json`: generado por el script; **no** se sube a git.
- `config/workspace/`: directorio de trabajo del agente.
- `scripts/generate-openclaw-config.ps1` y `.sh`: generan la config desde `.env`.
- `docker-compose.yml`: servicio OpenClaw con volumen en `./config` y puerto 18789.

## Seguridad

- No subas `.env` ni `config/openclaw.json` (contienen tokens). Ya están en `.gitignore`.
- El gateway escucha en `18789`; en un VPS, restringe acceso con firewall y revisa la [documentación de seguridad](https://docs.openclaw.ai/gateway/security) de OpenClaw.

## Referencias

- [OpenClaw – Documentación](https://docs.openclaw.ai/)
- [OpenClaw Docker](https://docs.openclaw.ai/install/docker)
- [Variables de entorno OpenClaw](https://openclawdoc.com/docs/reference/environment-variables)
