#!/bin/sh
set -e

mkdir -p /etc/caddy/Caddyfile.d

CADDY_MODE=${CADDY_MODE:-prod}

case "$CADDY_MODE" in
  prod|production)
    if [ -f /caddy-config/Caddyfile.prod ]; then
      cp /caddy-config/Caddyfile.prod /etc/caddy/Caddyfile.d/routes.caddy
    fi
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
    ;;
  staging)
    if [ -f /caddy-config/Caddyfile.staging ]; then
      cp /caddy-config/Caddyfile.staging /etc/caddy/Caddyfile.d/routes.caddy
    fi
    cat > /etc/caddy/Caddyfile.d/globals.caddy <<CADDYEOF
{
}
CADDYEOF
    ;;
esac

cat > /etc/caddy/Caddyfile <<CADDYEOF
import Caddyfile.d/globals.caddy
import Caddyfile.d/routes.caddy
CADDYEOF

exec caddy run --config /etc/caddy/Caddyfile
