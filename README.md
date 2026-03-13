# open-claw

Bot de Telegram conectado a [OpenClaw](https://openclaw.ai/) mediante la imagen Docker oficial. OpenClaw incluye canal Telegram nativo; solo hace falta configurar variables y arrancar.

## Requisitos

- Docker y Docker Compose v2
- Al menos 2 GB RAM para el contenedor
- Cuenta en Telegram y token de bot ([@BotFather](https://t.me/BotFather))
- API key de OpenRouter (recomendado) o de otro proveedor LLM para que el agente responda

## Configuración (solo rellenar .env)

1. **Copiar plantilla de variables**
   ```bash
   cp .env.example .env
   ```

2. **Editar `.env`** y rellenar:
   - `TELEGRAM_BOT_TOKEN`: token del bot de Telegram (BotFather).
   - `OPENCLAW_ALLOW_FROM`: tu(s) ID(s) de usuario de Telegram, separados por coma (sin espacios). Para obtener tu ID: enviar `/start` a [@userinfobot](https://t.me/userinfobot).
   - `OPENCLAW_GATEWAY_TOKEN`: token para la Control UI (opcional; si está vacío se genera uno al ejecutar el script).
   - **LLM:** por defecto solo **OpenRouter** (`OPENROUTER_API_KEY`). Una sola key da acceso a Claude, GPT, etc.

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
- `scripts/docker-entrypoint.sh`: crea `auth-profiles.json` en un volumen interno (evita error de permisos en Windows).
- `docker-compose.yml`: servicio OpenClaw; `./config` montado y volumen nombrado `openclaw-agents` para el estado del agente (permisos correctos en todos los SO).

## Si el contenedor no arranca (config inválida)

Si ves *"identity was moved; use agents.list[].identity"* o *"agent was moved; use agents.defaults"*, ejecuta el doctor para migrar la config al esquema actual:

- **Windows:** `.\scripts\openclaw-doctor.ps1`
- **Linux/macOS:** `./scripts/openclaw-doctor.sh`

O directamente: `docker compose run -T --rm --entrypoint openclaw openclaw doctor --fix`

Luego reinicia: `docker compose up -d openclaw`.

## Añadir otros proveedores (Anthropic, OpenAI, etc.)

Si más adelante quieres usar API keys directas además de OpenRouter:

1. Añade la variable al `.env` (ej. `ANTHROPIC_API_KEY=sk-ant-...`).
2. El estado del agente (incl. `auth-profiles.json`) está en el volumen nombrado `openclaw-agents`. Para añadir otro proveedor, ejecuta una vez algo como:  
   `docker compose run --rm --entrypoint openclaw openclaw models auth add --agent main --provider anthropic`  
   (o usa la Control UI si permite gestionar auth). También puedes copiar el contenido de `scripts/docker-entrypoint.sh` y añadir el nuevo perfil al JSON que se genera, luego recrear el volumen (borrar contenedor y volumen `openclaw-agents`) para que el entrypoint regenere el archivo.
3. Reinicia el contenedor.

Solo incluye perfiles para los que tengas key en `.env`; si falta la variable, OpenClaw no arranca.

## Instalación en VPS (Linux)

En un servidor Linux (Ubuntu/Debian u otra distro):

1. **Requisitos en el servidor:** Docker y Docker Compose v2, al menos 2 GB RAM.
   ```bash
   # Ejemplo Ubuntu/Debian: Docker + Compose plugin
   sudo apt update && sudo apt install -y docker.io docker-compose-plugin
   sudo usermod -aG docker $USER
   # Cerrar sesión y volver a entrar (o newgrp docker)
   ```

2. **Clonar o subir el proyecto** en la VPS (por ejemplo en `~/open-claw`).

3. **Seguir desde el paso 1 de "Configuración"** (copiar `.env.example` a `.env`, rellenar variables). En Linux usa el script bash:
   ```bash
   chmod +x scripts/generate-openclaw-config.sh
   ./scripts/generate-openclaw-config.sh
   docker compose up -d
   ```

4. **Control UI:** desde fuera accedes con `http://IP_DE_LA_VPS:18789`. Define un `OPENCLAW_GATEWAY_TOKEN` fuerte en `.env` (el token protege la Control UI).

5. **Firewall:** si abres el puerto 18789 para acceder a la Control UI, restringe por IP o usa túnel SSH en lugar de exponer el puerto a todo Internet:
   ```bash
   # Ejemplo: abrir solo 18789 (ufw)
   sudo ufw allow 22
   sudo ufw allow 18789/tcp
   sudo ufw enable
   ```
   Mejor aún: no abras 18789 y usa `ssh -L 18789:127.0.0.1:18789 user@vps` para acceder a la Control UI por túnel.

6. **Si necesitas recrear el volumen del agente** (permisos, estado corrupto):
   ```bash
   docker compose down
   docker volume rm open-claw_openclaw-agents 2>/dev/null || true
   docker compose up -d
   ```

El bot de Telegram no requiere que expongas puertos públicos: el contenedor hace conexiones salientes a los servidores de Telegram. Solo necesitas abrir 18789 si quieres usar la Control UI desde fuera (y en ese caso, refuerza el token y el firewall).

## Seguridad

- No subas `.env` ni `config/openclaw.json` (contienen tokens). Ya están en `.gitignore`.
- El gateway escucha en `18789`; en un VPS, restringe acceso con firewall y revisa la [documentación de seguridad](https://docs.openclaw.ai/gateway/security) de OpenClaw.

## Referencias

- [OpenClaw – Documentación](https://docs.openclaw.ai/)
- [OpenClaw Docker](https://docs.openclaw.ai/install/docker)
- [Variables de entorno OpenClaw](https://openclawdoc.com/docs/reference/environment-variables)
