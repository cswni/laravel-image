#!/bin/sh
echo "📡 Iniciando Reverb en modo debug"
exec php artisan reverb:start --debug --port=8080 --host=0.0.0.0 --hostname=reverb
