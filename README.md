# infra-proxy

Stack compartido de reverse proxy para VPS con múltiples apps.

## Servicios

| Servicio | Descripción | Profile |
|----------|-------------|---------|
| **caddy** | Proxy inverso con SSL automático vía DNS-01 | siempre |
| **netdata** | Monitoreo del servidor | `monitoring` |
| **cloudflared** | Tunnel para staging sin IP pública | `staging` |

## Requisitos

- Red Docker compartida (crear solo una vez por VPS):

  ```bash
  docker network create proxy-net
  ```

- Token de Cloudflare API con permisos **Zone → DNS → Edit** (para SSL wildcard en producción).

## Setup inicial

```bash
cp .env.example .env
# Edita .env según el entorno:
#   Producción → CLOUDFLARE_API_TOKEN (sin TUNNEL_TOKEN)
#   Staging    → TUNNEL_TOKEN (CLOUDFLARE_API_TOKEN no necesario)
```

Caddy detecta automáticamente el modo:
- **`TUNNEL_TOKEN` definido** → staging (`tls internal`)
- **`TUNNEL_TOKEN` vacío** → producción (certs reales vía DNS-01)

## Configuración de apps

El Caddyfile se genera automáticamente en el entrypoint desde las variables del `.env`.
Cada app necesita un bloque `APP_N_*` completo — todas las variables son obligatorias.

```env
APPS=2

APP_1_DOMAIN=midominio.com
APP_1_BACKEND_HOST=mi-backend
APP_1_BACKEND_PORT=5000
APP_1_FRONTEND_HOST=mi-frontend
APP_1_FRONTEND_PORT=80

APP_2_DOMAIN=otrodominio.com
APP_2_BACKEND_HOST=otro-backend
APP_2_BACKEND_PORT=3000
APP_2_FRONTEND_HOST=otro-frontend
APP_2_FRONTEND_PORT=8080
```

Por cada app se genera un bloque con:
- `/api/*` → `BACKEND_HOST:BACKEND_PORT`
- `/privacy*`, `/terms*` → `BACKEND_HOST:BACKEND_PORT`
- Todo lo demás → `FRONTEND_HOST:FRONTEND_PORT`

## Despliegue

### Producción (VPS con IP pública)

```bash
docker compose up -d --build
```

Caddy obtiene y renueva certificados wildcard reales vía DNS-01 de Cloudflare.

Con monitoreo:

```bash
docker compose --profile monitoring up -d --build
```

### Staging (VPS sin IP pública)

```bash
docker compose --profile staging up -d --build
```

Levanta Caddy + cloudflared. El tunnel se conecta a Cloudflare, que termina SSL en el edge.
Caddy usa `tls internal` automáticamente al detectar `TUNNEL_TOKEN`.

Configura el public hostname en **Cloudflare Zero Trust Dashboard** → Tunnels → `infra-proxy`:
- **Service**: `HTTPS` → `infra-proxy-caddy:443`
- **No TLS Verify**: activado (Caddy usa self-signed cert)

Con monitoreo:

```bash
docker compose --profile staging --profile monitoring up -d --build
```

## Agregar una app

1. La app debe tener una red externa `proxy-net` y conectar sus contenedores a ella
2. Agrega un bloque `APP_N_*` en `.env` e incrementa `APPS`
3. Recarga Caddy:

```bash
docker compose up -d --build caddy
```

## Ayuda

```bash
docker compose logs -f                    # logs de todos los servicios
docker compose logs caddy -f              # logs solo de Caddy
docker compose --profile staging logs -f  # logs del tunnel
```
