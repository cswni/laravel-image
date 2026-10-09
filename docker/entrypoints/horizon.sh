#!/bin/sh
set -e

cd /var/www/html

# Workers keep code in memory: after editing jobs run `php artisan horizon:terminate`
# and let the compose restart policy bring Horizon back.
echo "[horizon] Starting Laravel Horizon..."
exec php artisan horizon
