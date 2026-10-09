#!/bin/sh
set -e

if [ "$(id -u)" = "0" ]; then
  mkdir -p \
    /var/www/html/storage/framework/cache \
    /var/www/html/storage/framework/sessions \
    /var/www/html/storage/framework/views \
    /var/www/html/storage/logs \
    /var/www/html/storage/app/public \
    /var/www/html/bootstrap/cache
  chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
fi

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

PHP_VER=$(php -r 'echo PHP_VERSION;' 2>/dev/null || echo "unknown")
MODE="${APP_MODE:-api}"
ENV="${APP_ENV:-local}"

echo ""
echo "  Laravel · PHP ${PHP_VER} · Swoole/Octane"
echo "  Mode: ${MODE}  Env: ${ENV}"
echo ""

CUSTOM_ENTRYPOINT="/usr/local/bin/${MODE}.sh"

if [ -f "$CUSTOM_ENTRYPOINT" ]; then
  exec sh "$CUSTOM_ENTRYPOINT"
fi

echo "No entrypoint for mode '${MODE}'; falling back to api."
exec sh /usr/local/bin/api.sh
