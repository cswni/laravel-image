#!/bin/sh
set -e

cd /var/www/html

if [ ! -f public/index.php ]; then
  echo "ERROR: public/index.php not found — mount the app at /var/www/html." >&2
  exit 1
fi

SERVER="${OCTANE_SERVER:-frankenphp}"   # frankenphp | swoole | classic
PORT="${OCTANE_PORT:-8080}"

# Classic: no workers, every request reads code from disk. No reload needed.
if [ "${SERVER}" = "classic" ]; then
  echo "FrankenPHP classic mode (no workers) on :${PORT}"
  exec frankenphp php-server --listen ":${PORT}" --root public/
fi

set -- \
  --server="${SERVER}" \
  --host=0.0.0.0 \
  --port="${PORT}" \
  --workers="${OCTANE_WORKERS:-auto}" \
  --max-requests="${OCTANE_MAX_REQUESTS:-500}"

case "${SERVER}" in
  frankenphp)
    # Native FrankenPHP watcher (no Node); paths come from config/octane.php.
    if [ "${OCTANE_WATCH:-0}" = "1" ]; then
      set -- "$@" --watch
    fi
    ;;
  swoole)
    export PHP_INI_SCAN_DIR="${PHP_INI_DIR}/conf.d:${PHP_INI_DIR}/conf.d-swoole"
    if [ "${OCTANE_WATCH:-0}" = "1" ]; then
      echo "NOTE: --watch on Swoole needs Node; skipped. Run 'reload' after edits."
    fi
    ;;
  *)
    echo "ERROR: OCTANE_SERVER must be frankenphp, swoole or classic (got '${SERVER}')." >&2
    exit 1
    ;;
esac

echo "Starting Octane (${SERVER}) on 0.0.0.0:${PORT}"
exec php artisan octane:start "$@"
