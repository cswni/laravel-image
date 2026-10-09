#!/bin/sh
set -e

cd /var/www/html

# Hostname/app config come from REVERB_* in the app's .env.
set -- --host=0.0.0.0 --port="${REVERB_SERVER_PORT:-8080}"
if [ "${REVERB_DEBUG:-0}" = "1" ]; then
  set -- "$@" --debug
fi

echo "[reverb] Starting Reverb on 0.0.0.0:${REVERB_SERVER_PORT:-8080}..."
exec php artisan reverb:start "$@"
