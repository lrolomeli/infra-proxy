#!/bin/sh
set -e

mkdir -p /etc/caddy/Caddyfile.d

# ── Detect mode: staging if TUNNEL_TOKEN is set, otherwise prod ─────────────
if [ -n "$TUNNEL_TOKEN" ]; then
  IS_STAGING=1
else
  IS_STAGING=0
fi

# ── Validate APPS ────────────────────────────────────────────────────────────
if [ -z "$APPS" ] || [ "$APPS" -le 0 ] 2>/dev/null; then
  echo "ERROR: APPS must be a positive number" >&2
  exit 1
fi

# ── Generate routes.caddy ────────────────────────────────────────────────────
: > /etc/caddy/Caddyfile.d/routes.caddy

i=1
while [ "$i" -le "$APPS" ]; do
  eval "DOMAIN=\${APP_${i}_DOMAIN:-}"
  eval "BACKEND_HOST=\${APP_${i}_BACKEND_HOST:-}"
  eval "BACKEND_PORT=\${APP_${i}_BACKEND_PORT:-}"
  eval "FRONTEND_HOST=\${APP_${i}_FRONTEND_HOST:-}"
  eval "FRONTEND_PORT=\${APP_${i}_FRONTEND_PORT:-}"

  if [ -z "$DOMAIN" ]; then echo "ERROR: APP_${i}_DOMAIN is required" >&2; exit 1; fi
  if [ -z "$BACKEND_HOST" ] && [ -z "$FRONTEND_HOST" ]; then
    echo "ERROR: APP_${i} needs at least BACKEND_HOST or FRONTEND_HOST" >&2; exit 1
  fi
  if [ -n "$BACKEND_HOST" ] && [ -z "$BACKEND_PORT" ]; then
    echo "ERROR: APP_${i}_BACKEND_PORT required when BACKEND_HOST is set" >&2; exit 1
  fi
  if [ -n "$FRONTEND_HOST" ] && [ -z "$FRONTEND_PORT" ]; then
    echo "ERROR: APP_${i}_FRONTEND_PORT required when FRONTEND_HOST is set" >&2; exit 1
  fi

  {
    echo "${DOMAIN}, *.${DOMAIN} {"
    if [ "$IS_STAGING" = "1" ]; then
      echo "    tls internal"
    fi
    if [ -n "$BACKEND_HOST" ]; then
      echo "    handle_path /api/* {"
      echo "        reverse_proxy ${BACKEND_HOST}:${BACKEND_PORT} {"
      echo "            header_up Host {http.request.host}"
      echo "        }"
      echo "    }"
      echo "    handle /privacy* {"
      echo "        reverse_proxy ${BACKEND_HOST}:${BACKEND_PORT} {"
      echo "            header_up Host {http.request.host}"
      echo "        }"
      echo "    }"
      echo "    handle /terms* {"
      echo "        reverse_proxy ${BACKEND_HOST}:${BACKEND_PORT} {"
      echo "            header_up Host {http.request.host}"
      echo "        }"
      echo "    }"
    fi
    if [ -n "$FRONTEND_HOST" ]; then
      echo "    handle {"
      echo "        reverse_proxy ${FRONTEND_HOST}:${FRONTEND_PORT}"
      echo "    }"
    fi
    echo "}"
    echo ""
  } >> /etc/caddy/Caddyfile.d/routes.caddy

  i=$((i + 1))
done

# ── ACME DNS config ─────────────────────────────────────────────────────────
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

# ── Main Caddyfile ───────────────────────────────────────────────────────────
cat > /etc/caddy/Caddyfile <<CADDYEOF
import Caddyfile.d/globals.caddy
import Caddyfile.d/routes.caddy
CADDYEOF

exec caddy run --config /etc/caddy/Caddyfile
