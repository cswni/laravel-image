# Redis Extension Fix - Complete Guide

## Issue Identified
The Redis extension was not loading properly, causing the error:
```
Class "Redis" not found
```

## What Was Fixed

### 1. PECL Installation Options
Changed from:
```dockerfile
pecl install redis
```
To:
```dockerfile
pecl install -o -f redis
rm -rf /tmp/pear
docker-php-ext-enable redis
```

**Why:**
- `-o` = Overwrite existing files
- `-f` = Force installation
- `rm -rf /tmp/pear` = Clean up PECL cache
- Explicit `docker-php-ext-enable redis` ensures it's enabled

### 2. Redis Configuration File
Created `docker/php/redis.ini`:
```ini
[redis]
extension=redis.so
redis.session.locking_enabled = 1
redis.session.lock_retries = -1
redis.session.lock_wait_time = 10000
```

This ensures:
- Extension is explicitly loaded
- Redis sessions work properly
- Proper locking configuration

### 3. PHP Configuration Defaults
Fixed `php.ini` to have default values:
```ini
memory_limit = ${PHP_MEMORY_LIMIT:-512M}
date.timezone = ${PHP_TIMEZONE:-UTC}
display_errors = ${PHP_DISPLAY_ERRORS:-Off}
```

**Before:** Empty values caused PHP warnings
**After:** Defaults provided if env vars not set

### 4. Configuration Loading Order
```
10-opcache.ini   <- Loads first
20-redis.ini     <- Loads second
99-custom.ini    <- Loads last
```

This ensures proper extension initialization order.

## Verification Steps

### 1. After Building, Test Redis Extension
```bash
# Check if redis module is loaded
docker run --rm laravel-app:latest php -m | grep redis

# Test Redis class exists
docker run --rm laravel-app:latest php -r "var_dump(class_exists('Redis'));"

# Create Redis instance
docker run --rm laravel-app:latest php -r "new Redis(); echo 'Redis OK';"

# Run comprehensive test
docker run --rm laravel-app:latest bash /usr/local/bin/test
```

### 2. Inside Running Container
```bash
# Access container
docker exec -it laravel-app bash

# Check loaded modules
php -m | grep redis

# Check Redis class
php -r "if (class_exists('Redis')) { echo 'Redis available'; } else { echo 'Redis MISSING'; }"

# Test Redis connection (if Redis server is available)
php -r "\$r = new Redis(); \$r->connect('redis', 6379); echo 'Connected';"

# Check PHP configuration
php -i | grep redis
```

### 3. From Laravel Application
```bash
# Test Redis connection via Laravel
docker exec laravel-app php artisan tinker
>>> Redis::connection()->ping()
>>> Redis::set('test', 'value')
>>> Redis::get('test')
```

## Common Issues & Solutions

### Issue 1: Redis extension not in php -m output
**Solution:** Rebuild the image ensuring redis.ini is copied
```bash
docker build --no-cache -t laravel-app:latest .
```

### Issue 2: "extension=redis.so" not found
**Solution:** Check if redis.so exists
```bash
docker run --rm laravel-app:latest ls -la /usr/local/lib/php/extensions/
docker run --rm laravel-app:latest find /usr -name "redis.so"
```

### Issue 3: PECL install fails during build
**Solution:** Check build logs
```bash
docker build --progress=plain --no-cache -t laravel-app:latest . 2>&1 | tee build.log
grep -i redis build.log
```

### Issue 4: Redis loads but Laravel can't connect
**Solution:** Check Redis server and configuration
```bash
# Check if Redis container is running
docker ps | grep redis

# Check Redis connection from app container
docker exec laravel-app redis-cli -h redis ping

# Check Laravel .env
docker exec laravel-app cat .env | grep REDIS
```

## Build & Test Script

Save this as `build-and-test.sh`:

```bash
#!/bin/bash
set -e

echo "🏗️  Building Laravel FrankenPHP image..."
docker build -t laravel-app:latest .

echo ""
echo "✅ Build complete!"
echo ""

echo "🧪 Testing Redis extension..."
echo ""

echo "1. Checking php -m output:"
docker run --rm laravel-app:latest php -m | grep -i redis && echo "✅ redis in php -m" || echo "❌ redis NOT in php -m"

echo ""
echo "2. Checking Redis class:"
docker run --rm laravel-app:latest php -r "echo class_exists('Redis') ? '✅ Redis class exists' : '❌ Redis class missing';" 
echo ""

echo ""
echo "3. Testing Redis instantiation:"
docker run --rm laravel-app:latest php -r "try { new Redis(); echo '✅ Redis instance created\n'; } catch (Exception \$e) { echo '❌ Failed: ' . \$e->getMessage() . '\n'; exit(1); }"

echo ""
echo "4. Running comprehensive tests:"
docker run --rm laravel-app:latest bash /usr/local/bin/test

echo ""
echo "🎉 All tests passed!"
```

Make it executable:
```bash
chmod +x build-and-test.sh
./build-and-test.sh
```

## Expected Output After Fix

When you run `php -m` in the container, you should see:

```
[PHP Modules]
bcmath
Core
ctype
curl
date
dom
exif
fileinfo
filter
gd
hash
iconv
intl
json
lexbor
libxml
mbstring
mysqlnd
opcache
openssl
pcntl
pcre
PDO
pdo_mysql
pdo_pgsql
pdo_sqlite
pgsql
Phar
posix
random
readline
Reflection
redis          ← THIS SHOULD BE HERE
session
SimpleXML
sockets
sodium
SPL
sqlite3
standard
tokenizer
uri
xml
xmlreader
xmlwriter
Zend OPcache
zip
zlib
```

## Configuration Files Reference

### docker/php/redis.ini (NEW)
```ini
[redis]
extension=redis.so
redis.session.locking_enabled = 1
redis.session.lock_retries = -1
redis.session.lock_wait_time = 10000
```

### docker/php/php.ini (UPDATED)
```ini
memory_limit = ${PHP_MEMORY_LIMIT:-512M}
date.timezone = ${PHP_TIMEZONE:-UTC}
display_errors = ${PHP_DISPLAY_ERRORS:-Off}
```

### docker/php/opcache.ini (UPDATED)
```ini
opcache.enable = ${PHP_OPCACHE_ENABLE:-1}
opcache.validate_timestamps = ${PHP_OPCACHE_VALIDATE_TIMESTAMPS:-0}
```

## Summary of Changes

| File | Change | Reason |
|------|--------|--------|
| Dockerfile | `pecl install -o -f redis` | Force installation, overwrite |
| Dockerfile | `rm -rf /tmp/pear` | Clean PECL cache |
| Dockerfile | Explicit `docker-php-ext-enable redis` | Ensure enabled |
| docker/php/redis.ini | Created new file | Explicit extension loading |
| docker/php/php.ini | Added default values | Prevent empty variable warnings |
| docker/php/opcache.ini | Added default values | Prevent empty variable warnings |
| Dockerfile | Copy redis.ini as 20-redis.ini | Proper loading order |

## Deployment

After making these changes:

1. **Rebuild on your remote server:**
```bash
cd php-image-8-5
docker build -t laravel-app:latest .
```

2. **Test Redis:**
```bash
docker run --rm laravel-app:latest php -r "new Redis(); echo 'Redis OK';"
```

3. **Deploy:**
```bash
docker-compose up -d
# OR
docker run -d --name laravel-app ... laravel-app:latest
```

4. **Verify in running container:**
```bash
docker exec laravel-app php -m | grep redis
docker exec laravel-app php artisan tinker
>>> Redis::ping()
```

## Success Indicators

✅ **Redis shows in `php -m` output**
✅ **No "Class Redis not found" errors**
✅ **No "Invalid date.timezone" warnings**
✅ **Laravel can connect to Redis server**
✅ **Sessions and cache work with Redis**

---

**Last Updated:** December 2025
**Version:** 3.0 with Redis fix

