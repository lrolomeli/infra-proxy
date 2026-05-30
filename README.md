# infra-proxy

Stack compartido de reverse proxy para VPS con múltiples apps.

## Servicios

| Servicio | Descripción |
|----------|-------------|
| **caddy** | Proxy inverso con SSL automático (Let's Encrypt) |
| **netdata** | Monitoreo del servidor (profile: monitoring) |
| **cloudflared** | Tunnel para staging sin IP pública (profile: staging) |

## Uso

```bash
# Setup inicial
cp .env.example .env
# Edita .env con CLOUDFLARE_API_TOKEN y/o TUNNEL_TOKEN

# Producción
docker compose up -d --build

# Staging (sin IP pública, necesita tunnel)
docker compose --profile staging up -d --build

# Con monitoreo
docker compose --profile monitoring up -d --build
docker compose --profile monitoring --profile staging up -d --build
```

## Agregar una app

1. Cada app debe tener una red externa `proxy-net` y conectar su frontend a ella
2. Agrega el dominio al archivo `config/Caddyfile`
3. `docker compose up -d --build caddy`
