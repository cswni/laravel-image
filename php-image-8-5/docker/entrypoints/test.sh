#!/bin/bash
# Test script to verify PHP extensions and configuration

echo "=== PHP Version ==="
php -v
echo ""

echo "=== PHP Extensions ==="
php -m
echo ""

echo "=== Critical Extensions Check ==="
CRITICAL_EXTS=("curl" "gd" "pdo_mysql" "redis" "opcache" "zip" "intl")
MISSING=0

for ext in "${CRITICAL_EXTS[@]}"; do
    if php -m | grep -q "^${ext}$"; then
        echo "✅ $ext"
    else
        echo "❌ $ext - MISSING"
        MISSING=$((MISSING + 1))
    fi
done

echo ""

if [ $MISSING -eq 0 ]; then
    echo "✅ All critical extensions loaded!"
else
    echo "⚠️  $MISSING extension(s) missing!"
    exit 1
fi

echo ""
echo "=== Redis Extension Test ==="
php -r "if (class_exists('Redis')) { echo '✅ Redis class available' . PHP_EOL; \$r = new Redis(); echo '✅ Redis instance created' . PHP_EOL; } else { echo '❌ Redis class NOT available' . PHP_EOL; exit(1); }"

echo ""
echo "=== curl Extension Test ==="
php -r "if (function_exists('curl_version')) { \$v = curl_version(); echo '✅ curl works: ' . \$v['version'] . PHP_EOL; } else { echo '❌ curl_version() not available' . PHP_EOL; exit(1); }"

echo ""
echo "=== OPcache Status ==="
php -r "echo opcache_get_status() ? '✅ OPcache enabled' : '⚠️  OPcache disabled'; echo PHP_EOL;"

echo ""
echo "=== PHP Configuration ==="
php -i | grep -E "(memory_limit|max_execution_time|upload_max_filesize|post_max_size|opcache.enable)"

echo ""
echo "=== Test Complete ==="

