#!/bin/bash
set -e

echo "🚀 Starting FrankenPHP Laravel Container..."
echo "   Environment: ${APP_ENV:-production}"
echo "   Mode: ${APP_MODE:-api}"

# Check if Laravel application exists
if [ ! -f /var/www/html/public/index.php ]; then
    echo "❌ Laravel application not found at /var/www/html/public/index.php"
    exit 1
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true

# Configure PHP based on environment
if [ "${APP_ENV}" = "production" ]; then
    echo "📦 Production mode detected"

    # Production OPcache settings
    export PHP_OPCACHE_ENABLE=1
    export PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
    export FRANKENPHP_NUM_THREADS=${FRANKENPHP_NUM_THREADS:-8}

    # Disable FrankenPHP worker file if not set
    export FRANKENPHP_WORKER_FILE=${FRANKENPHP_WORKER_FILE:-}

    # Run Laravel optimizations if not already done
    if [ ! -f /var/www/html/bootstrap/cache/config.php ] || [ ! -f /var/www/html/bootstrap/cache/routes-v7.php ]; then
        echo "⚡ Running Laravel optimizations..."
        cd /var/www/html

        # Clear any existing cache first
        php artisan optimize:clear 2>/dev/null || true

        # Run optimizations
        php artisan config:cache
        php artisan route:cache
        php artisan view:cache
        php artisan event:cache
        php artisan icons:cache 2>/dev/null || true
        php artisan filament:optimize-clear 2>/dev/null || true

        echo "✅ Laravel optimization completed"
    else
        echo "✅ Laravel already optimized (caches found)"
    fi

elif [ "${APP_ENV}" = "local" ] || [ "${APP_ENV}" = "development" ]; then
    echo "🔧 Development mode detected"

    # Development OPcache settings - enable revalidation
    export PHP_OPCACHE_ENABLE=1
    export PHP_OPCACHE_VALIDATE_TIMESTAMPS=1
    export FRANKENPHP_NUM_THREADS=${FRANKENPHP_NUM_THREADS:-2}
    export FRANKENPHP_WORKER_FILE=""

    # Clear caches for development
    echo "🧹 Clearing Laravel caches for development..."
    cd /var/www/html
    php artisan optimize:clear 2>/dev/null || true

    echo "✅ Development environment ready"
else
    echo "⚠️  Unknown APP_ENV: ${APP_ENV}. Defaulting to production settings."
    export PHP_OPCACHE_ENABLE=1
    export PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
fi

# Display PHP & OPcache status
echo ""
echo "📊 Configuration:"
echo "   PHP Memory Limit: ${PHP_MEMORY_LIMIT:-512M}"
echo "   OPcache Enabled: ${PHP_OPCACHE_ENABLE}"
echo "   OPcache Validate Timestamps: ${PHP_OPCACHE_VALIDATE_TIMESTAMPS}"
echo "   FrankenPHP Threads: ${FRANKENPHP_NUM_THREADS:-auto}"
echo ""

# Determine which mode to run
MODE="${APP_MODE:-api}"
CUSTOM_ENTRYPOINT="/usr/local/bin/${MODE}.sh"

if [ -f "$CUSTOM_ENTRYPOINT" ]; then
    echo "🎯 Executing custom entrypoint: $CUSTOM_ENTRYPOINT"
    exec sh "$CUSTOM_ENTRYPOINT"
else
    echo "⚠️  Custom entrypoint not found for mode '$MODE'. Starting FrankenPHP..."
    exec frankenphp run --config=/etc/caddy/Caddyfile
fi

