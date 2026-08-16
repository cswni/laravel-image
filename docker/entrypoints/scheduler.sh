#!/bin/sh
set -e

echo "[scheduler] Iniciando scheduler Laravel..."

# Ejecutar scheduler en loop infinito
while true; do
  php artisan schedule:run --verbose --no-interaction
  sleep 60
done
