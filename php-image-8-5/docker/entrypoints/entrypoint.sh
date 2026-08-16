#!/bin/bash
set -e

echo "🚀 Laravel FrankenPHP Container Starting"
echo "   Environment: ${APP_ENV:-production}"
echo "   Debug: ${APP_DEBUG:-false}"

if [ ! -f /var/www/html/public/index.php ]; then
    echo "❌ Laravel application not found"
    exit 1
fi

chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true

export PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-512M}
export PHP_MAX_EXECUTION_TIME=${PHP_MAX_EXECUTION_TIME:-60}
export PHP_POST_MAX_SIZE=${PHP_POST_MAX_SIZE:-100M}
export PHP_UPLOAD_MAX_FILESIZE=${PHP_UPLOAD_MAX_FILESIZE:-100M}
export PHP_TIMEZONE=${PHP_TIMEZONE:-UTC}
export LOG_LEVEL=${LOG_LEVEL:-INFO}

if [ "${APP_ENV}" = "production" ]; then
    echo "📦 Production mode"
    export PHP_OPCACHE_ENABLE=1
    export PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
    export PHP_DISPLAY_ERRORS=Off

    cd /var/www/html

    if [ ! -f bootstrap/cache/config.php ]; then
        echo "⚡ Running optimizations"
        php artisan optimize:clear 2>/dev/null || true
        php artisan config:cache
        php artisan route:cache
        php artisan view:cache
        php artisan event:cache 2>/dev/null || true
        echo "✅ Optimizations complete"
    fi
else
    echo "🔧 Development mode"
    export PHP_OPCACHE_ENABLE=1
    export PHP_OPCACHE_VALIDATE_TIMESTAMPS=1
    export PHP_DISPLAY_ERRORS=On

    cd /var/www/html
    php artisan optimize:clear 2>/dev/null || true
fi

echo ""
echo "📊 PHP Configuration:"
echo "   Memory: ${PHP_MEMORY_LIMIT}"
echo "   Max Execution: ${PHP_MAX_EXECUTION_TIME}s"
echo "   OPcache: ${PHP_OPCACHE_ENABLE}"
echo "   OPcache Validation: ${PHP_OPCACHE_VALIDATE_TIMESTAMPS}"
echo ""

php -v
echo ""
echo "📦 PHP Extensions:"
php -m | grep -E "(curl|gd|pdo_mysql|pdo_postgres|redis|imagick|opcache|zip|intl)" || echo "Extensions loading..."
echo ""

exec "$@"

