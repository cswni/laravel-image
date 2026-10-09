#!/bin/sh
set -e

APP_DIR=/var/www/html

# storage/ (bind mount in dev, named volume in prod) may be empty on first
# boot. No chown: in dev it lives on the host disk and must stay writable by
# the SFTP user.
mkdir -p \
  "${APP_DIR}/storage/framework/cache" \
  "${APP_DIR}/storage/framework/sessions" \
  "${APP_DIR}/storage/framework/views" \
  "${APP_DIR}/storage/logs" \
  "${APP_DIR}/storage/app/public" \
  "${APP_DIR}/bootstrap/cache"

# php.ini cannot read container env at runtime; write memory_limit on boot
# so PHP_MEMORY_LIMIT changes need no rebuild.
MEM="${PHP_MEMORY_LIMIT:-512M}"
printf 'memory_limit=%s\n' "${MEM}" > "${PHP_INI_DIR}/conf.d/zz-memory.ini"

# Production images ship the code, but .env and storage/ only exist at runtime,
# so caches and the public/storage link are built on boot (each container has
# its own bootstrap/cache). The prod target sets LARAVEL_OPTIMIZE=1.
if [ "${LARAVEL_OPTIMIZE:-0}" = "1" ]; then
  cd "${APP_DIR}"
  [ -e public/storage ] || ln -s ../storage/app/public public/storage
  php artisan optimize --no-interaction \
    || echo "WARN: php artisan optimize failed; running without caches." >&2
fi

# compose `command:` is passed as argv — honor it.
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

MODE="${APP_MODE:-api}"

echo ""
echo "  Laravel · PHP $(php -r 'echo PHP_VERSION;') · $(frankenphp version 2>/dev/null | cut -d' ' -f1-2)"
echo "  Mode: ${MODE}  Env: ${APP_ENV:-local}  memory_limit=${MEM}"
echo ""

case "${MODE}" in
  api|horizon|queue|scheduler|reverb)
    exec sh "/usr/local/bin/${MODE}.sh"
    ;;
  *)
    echo "Unknown APP_MODE '${MODE}' (api|horizon|queue|scheduler|reverb)." >&2
    exit 1
    ;;
esac
