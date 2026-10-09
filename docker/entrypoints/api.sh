#!/bin/sh
set -e

OPCACHE_DIR=/usr/local/etc/php/conf.d
OPCACHE_CFG=${OPCACHE_DIR}/opcache.ini

if [ "${APP_ENV}" = "production" ]; then
    echo "OPcache: production (JIT on, timestamps off)"
    cp /usr/local/etc/php/opcache-production.ini "${OPCACHE_CFG}"
else
    echo "OPcache: development (timestamps on, JIT off)"
    cp /usr/local/etc/php/opcache-development.ini "${OPCACHE_CFG}"
fi

if [ ! -f /var/www/html/public/index.php ]; then
    echo "ERROR: /var/www/html/public/index.php not found — mount or bake the app."
    exit 1
fi

# Octane workers need config cache; generate if missing (image or first boot).
if [ "${APP_ENV}" = "production" ] && [ ! -f /var/www/html/bootstrap/cache/config.php ]; then
    echo "Generating config:cache..."
    php artisan config:cache --no-interaction || echo "WARN: config:cache failed"
fi

WORKERS="${OCTANE_WORKERS:-auto}"
MAX_REQUESTS="${OCTANE_MAX_REQUESTS:-500}"
PORT="${OCTANE_PORT:-8080}"

echo "Starting Octane (Swoole) on 0.0.0.0:${PORT} workers=${WORKERS}"
exec php /var/www/html/artisan octane:start \
    --server=swoole \
    --host=0.0.0.0 \
    --port="${PORT}" \
    --workers="${WORKERS}" \
    --max-requests="${MAX_REQUESTS}"
