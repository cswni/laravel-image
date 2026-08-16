#!/bin/bash
# Verify all required PHP extensions are present

echo "=== Checking PHP Extensions ==="
echo ""

REQUIRED_EXTENSIONS=(
    "curl"
    "gd"
    "pdo_mysql"
    "pdo_pgsql"
    "pgsql"
    "zip"
    "intl"
    "pcntl"
    "posix"
    "exif"
    "bcmath"
    "opcache"
    "sockets"
    "redis"
    "imagick"
)

MISSING=0

for ext in "${REQUIRED_EXTENSIONS[@]}"; do
    if php -m | grep -q "^${ext}$"; then
        echo "✅ $ext"
    else
        echo "❌ $ext - MISSING"
        MISSING=$((MISSING + 1))
    fi
done

echo ""
if [ $MISSING -eq 0 ]; then
    echo "🎉 All required extensions are installed!"
    exit 0
else
    echo "⚠️  $MISSING extension(s) missing!"
    exit 1
fi

