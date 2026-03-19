# Identidad del dispositivo (OpenClaw)

El archivo `device.json` contiene la **identidad criptográfica del dispositivo**: un par de claves (pública/privada) y un `deviceId` que OpenClaw usa para atestación o firma en comunicaciones con servicios.

- **No debe versionarse**: incluye la clave privada. Ya está en `.gitignore`.
- **Se genera solo**: si no existe, OpenClaw lo crea en el primer arranque.

## Regenerar la identidad (clave comprometida)

Si el repo estuvo público o sospechas que `device.json` se filtró:

1. Borra el archivo local: `config/identity/device.json`
2. Reinicia OpenClaw (p. ej. `docker compose up -d openclaw`).

En el siguiente arranque, OpenClaw generará un nuevo par de claves y un nuevo `deviceId`. El dispositivo pasará a identificarse con la nueva identidad; cualquier servicio que dependa de la anterior (p. ej. vinculación por deviceId) puede requerir reconfiguración.

`device.json.example` es solo una plantilla de estructura; los valores reales los genera el runtime.
