#!/bin/sh

mkdir -p /etc/caddy/Caddyfile.d

if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
  cat > /etc/caddy/Caddyfile.d/globals.caddy <<CADDYEOF
{
    acme_dns cloudflare ${CLOUDFLARE_API_TOKEN}
}
CADDYEOF
else
  # Sin token → Cloudflare Tunnel termina SSL en el edge.
  # Desactivamos auto-HTTPS para evitar bucle de redirects.
  cat > /etc/caddy/Caddyfile.d/globals.caddy <<CADDYEOF
{
    auto_https off
}
CADDYEOF
fi

cat > /etc/caddy/Caddyfile <<CADDYEOF
import Caddyfile.d/globals.caddy
import Caddyfile.d/routes.caddy
CADDYEOF

exec caddy run --config /etc/caddy/Caddyfile
