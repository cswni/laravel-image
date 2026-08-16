#!/bin/sh
set -e

echo "[horizon] Iniciando Laravel Horizon..."

# Ejecutar Horizon (supervisor de colas)
php artisan horizon
