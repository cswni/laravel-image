#!/bin/sh
set -e

cd /var/www/html

# queue:listen boots a fresh process per job, so code edits apply without reload.
set -- --tries="${QUEUE_TRIES:-1}" --timeout="${QUEUE_TIMEOUT:-60}" --no-interaction
if [ -n "${QUEUE_NAMES:-}" ]; then
  set -- "$@" --queue="${QUEUE_NAMES}"
fi

echo "[queue] Starting queue:listen..."
exec php artisan queue:listen "$@"
