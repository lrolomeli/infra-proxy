# infra-proxy

Stack compartido de reverse proxy para VPS con múltiples apps.

## Servicios

| Servicio | Descripción | Profile |
|----------|-------------|---------|
| **caddy** | Proxy inverso con SSL automático (Let's Encrypt) | siempre |
| **netdata** | Monitoreo del servidor | `monitoring` |

## Despliegue

```bash
# Setup inicial
cp .env.example .env
# Edita .env con CLOUDFLARE_API_TOKEN
```

### Producción

```bash
docker compose up -d --build
```

### Staging

El VPS de staging no tiene IP pública, usa Cloudflare Tunnel como servicio del sistema (systemd).

Asegúrate de que el tunnel apunte a `infra-proxy-caddy:80` en `~/.cloudflared/config.yml`:

```yaml
url: http://infra-proxy-caddy:80
```

Luego levanta solo Caddy:

```bash
docker compose up -d --build
```

Con monitoreo:

```bash
docker compose --profile monitoring up -d --build
```

## Agregar una app

1. Cada app debe tener una red externa `proxy-net` y conectar su frontend a ella
2. Agrega el dominio en `config/Caddyfile`
3. Recarga Caddy:

```bash
docker compose up -d --build caddy
```

## Ayuda

```bash
docker compose logs -f           # logs de todos los servicios
docker compose logs caddy -f     # logs solo de Caddy
docker exec infra-proxy-caddy caddy reload --config /etc/caddy/Caddyfile
```
