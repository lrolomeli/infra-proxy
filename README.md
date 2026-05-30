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

- Token de Cloudflare API con permisos **Zone → DNS → Edit** (para SSL wildcard)

## Setup inicial

```bash
cp .env.example .env
# Edita .env con CLOUDFLARE_API_TOKEN y TUNNEL_TOKEN (staging)
```

## Despliegue

### Producción (VPS con IP pública)

```bash
docker compose up -d --build
```

SSL automático vía DNS-01. Caddy obtiene y renueva los certificados solo.

### Staging (VPS sin IP pública)

```bash
docker compose --profile staging up -d --build
```

Levanta Caddy + cloudflared. El tunnel se conecta a Cloudflare, que termina SSL en el edge.
Caddy también tiene `CLOUDFLARE_API_TOKEN` para obtener wildcard certs vía DNS-01.

Configura el public hostname en **Cloudflare Zero Trust Dashboard** → Tunnels → `infra-proxy`:
- **Service**: `HTTPS` → `infra-proxy-caddy:443`
- **No TLS Verify**: activado (para el primer boot mientras Caddy obtiene el cert)

Con monitoreo:

```bash
docker compose --profile staging --profile monitoring up -d --build
```

## Agregar una app

1. La app debe tener una red externa `proxy-net` y conectar su frontend a ella
2. Agrega el dominio en `config/Caddyfile`
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
