# infra-proxy

Stack compartido de reverse proxy para VPS con múltiples apps.

## Servicios

| Servicio | Descripción | Profile |
|----------|-------------|---------|
| **caddy** | Proxy inverso con SSL automático (Let's Encrypt) | siempre |
| **netdata** | Monitoreo del servidor | `monitoring` |
| **cloudflared** | Tunnel para staging sin IP pública | `staging` |

## Despliegue

```bash
# Setup inicial
cp .env.example .env
# Edita .env con CLOUDFLARE_API_TOKEN y/o TUNNEL_TOKEN
```

### Producción

```bash
docker compose up -d --build
```

### Staging

Elige la opción según cómo tengas configurado el tunnel.

#### Opción A — cloudflared como servicio del sistema (systemd)

Útil si ya tienes cloudflared corriendo por fuera de Docker y no quieres migrarlo.

```bash
s docker compose up -d --build
```

Luego actualiza el archivo de configuración de tu tunnel (`~/.cloudflared/config.yml`) para que apunte a `infra-proxy-caddy:80`:

```yaml
url: http://infra-proxy-caddy:80
```

Con monitoreo:

```bash
docker compose --profile monitoring up -d --build
```

#### Opción B — cloudflared en Docker (recomendada para setups nuevos)

Infra-proxy incluye cloudflared como servicio Docker. Solo necesitas el token del tunnel.

```bash
docker compose --profile staging up -d --build
```

Con monitoreo:

```bash
docker compose --profile monitoring --profile staging up -d --build
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
