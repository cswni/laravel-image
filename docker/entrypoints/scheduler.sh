#!/bin/sh
set -e

echo "[scheduler] Starting Laravel scheduler (schedule:work)..."
exec php artisan schedule:work --verbose --no-interaction
