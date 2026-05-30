#!/bin/sh

mkdir -p /etc/caddy/Caddyfile.d

if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
  cat > /etc/caddy/Caddyfile.d/globals.caddy <<CADDYEOF
{
    acme_dns cloudflare ${CLOUDFLARE_API_TOKEN}
}
CADDYEOF
else
  cat > /etc/caddy/Caddyfile.d/globals.caddy <<CADDYEOF
{
}
CADDYEOF
fi

cat > /etc/caddy/Caddyfile <<CADDYEOF
import Caddyfile.d/globals.caddy
import Caddyfile.d/routes.caddy
CADDYEOF

exec caddy run --config /etc/caddy/Caddyfile
