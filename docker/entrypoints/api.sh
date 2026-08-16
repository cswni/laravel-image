#!/bin/sh
set -e

# ─── ANSI Colors ──────────────────────────────────────────────────────────────
R='\033[0m'; B='\033[1m'; DIM='\033[2m'
GRN='\033[1;32m'; YLW='\033[1;33m'; CYN='\033[1;36m'; RED='\033[1;31m'; WHT='\033[1;37m'

# ─── OPcache configuration ────────────────────────────────────────────────────
OPCACHE_DIR=/usr/local/etc/php/conf.d
OPCACHE_CFG=${OPCACHE_DIR}/opcache.ini

if [ "${APP_ENV}" = "production" ]; then
    printf "  ${GRN}${B}⚡ OPcache:${R}  production profile (JIT tracing, timestamps OFF)\n"
    cp /usr/local/etc/php/opcache-production.ini "${OPCACHE_CFG}"
else
    printf "  ${YLW}${B}🔧 OPcache:${R}  development profile (timestamps ON, JIT OFF)\n"
    cp /usr/local/etc/php/opcache-development.ini "${OPCACHE_CFG}"
fi

# ─── Sanity check ─────────────────────────────────────────────────────────────
if [ ! -f /var/www/html/public/index.php ]; then
    printf "  ${RED}❌ /var/www/html/public/index.php not found — is the app volume mounted?${R}\n"
    exit 1
fi

# ─── Mode selection: local/dev → traditional (HMR-friendly), production → Octane workers ──
if [ "${APP_ENV}" = "production" ]; then
    printf "  ${GRN}${B}🚀 Starting FrankenPHP (API mode)...${R}\n"
    printf "  ${DIM}   Octane worker mode — high performance, app cached in memory${R}\n\n"
    exec php /var/www/html/artisan octane:start \
        --server=frankenphp \
        --host=0.0.0.0 \
        --port=8080 \
        --workers=auto \
        --max-requests=500
else
    printf "  ${YLW}${B}🔧 Starting FrankenPHP (traditional mode — HMR enabled)...${R}\n"
    printf "  ${DIM}   Octane skipped in ${APP_ENV:-local} env — file changes are reflected immediately${R}\n"
    printf "  ${DIM}   Set APP_ENV=production to enable Octane worker mode${R}\n\n"
    exec frankenphp run --config=/etc/caddy/Caddyfile
fi
