#!/bin/sh
set -e

cd /var/www/html

# Each scheduled task runs in a new process, so code edits apply automatically.
echo "[scheduler] Starting schedule:work..."
exec php artisan schedule:work --no-interaction
