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
#   Producción → CLOUDFLARE_API_TOKEN
#   Staging    → TUNNEL_TOKEN (CADDY_MODE=staging, sin token de Cloudflare)
```

La variable `CADDY_MODE` define qué configuración usa Caddy:

| `CADDY_MODE` | Caddyfile | TLS | `CLOUDFLARE_API_TOKEN` |
|---|---|---|---|
| `prod` (default) | `config/Caddyfile.prod` | Wildcard real vía DNS-01 | Requerido |
| `staging` | `config/Caddyfile.staging` | `tls internal` (self-signed) | No necesario |

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
Caddy usa `tls internal` — no necesita `CLOUDFLARE_API_TOKEN`.

Configura el public hostname en **Cloudflare Zero Trust Dashboard** → Tunnels → `infra-proxy`:
- **Service**: `HTTPS` → `infra-proxy-caddy:443`
- **No TLS Verify**: activado (Caddy usa self-signed cert)

Con monitoreo:

```bash
docker compose --profile staging --profile monitoring up -d --build
```

## Agregar una app

1. La app debe tener una red externa `proxy-net` y conectar su frontend a ella
2. Agrega el dominio en `config/Caddyfile.prod` (producción) o `config/Caddyfile.staging` (staging)
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
