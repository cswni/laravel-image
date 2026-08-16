# PHP 8.5 FrankenPHP Image - Implementation Notes

## What Was Fixed

### 1. Curl Extension Loading
The issue was NOT that curl was missing, but that **Spatie Ray was trying to call `curl_exec()` from within a namespace**. 

In the old implementation, there may have been issues with:
- Incorrect PHP configuration loading order
- Extension loading priority issues
- Missing curl.cainfo certificate configuration

### 2. Configuration Order
The new implementation uses proper configuration ordering:
- `10-opcache.ini` - Loads first
- `99-custom.ini` - Loads last (overwrites if needed)

### 3. Explicit curl Configuration
Added to `php.ini`:
```ini
[curl]
curl.cainfo = /etc/ssl/certs/ca-certificates.crt
```

This ensures curl has proper SSL certificate verification.

### 4. Simplified Caddyfile
The new Caddyfile:
- No global frankenphp block (avoids worker mode issues)
- Simple `php_server` directive
- No complex routing or worker file configuration
- Standard Laravel execution

### 5. Environment-based Configuration
All PHP settings are now environment-variable based:
- `PHP_MEMORY_LIMIT`
- `PHP_MAX_EXECUTION_TIME`
- `PHP_OPCACHE_ENABLE`
- `PHP_OPCACHE_VALIDATE_TIMESTAMPS`
- etc.

This allows the same image to work in development and production without rebuilding.

### 6. Proper Extension Installation
Extensions are installed in the correct order:
1. System dependencies
2. Configure extensions (like gd)
3. Install core extensions
4. Install PECL extensions
5. Enable extensions

### 7. Test Scripts Included
Three test scripts to verify everything works:
- `test.sh` - General PHP and extension tests
- `test-curl.sh` - Comprehensive curl testing
- Both copied into the container for easy testing

## Key Differences from Old Implementation

| Aspect | Old | New |
|--------|-----|-----|
| Caddyfile | Complex with worker config | Simple, standard |
| PHP Config | Mixed inline/file | All file-based with env vars |
| curl Config | Missing | Explicit with cert path |
| Extension Order | Random | Properly ordered |
| Entrypoint | Multiple scripts | Single unified script |
| Testing | None | Comprehensive test scripts |
| Documentation | Scattered | Centralized |

## Why This Should Work

1. **curl is in base image** - We confirmed this with `php -m`
2. **No attempt to install curl** - We don't try to compile it
3. **Proper cert configuration** - curl.cainfo explicitly set
4. **Simple Caddyfile** - No worker mode complexity
5. **Environment variables** - Easy to configure per deployment
6. **Test scripts** - Easy to verify everything works

## Deployment Steps

1. Build the image on remote server:
   ```bash
   cd php-image-8-5
   docker build -t laravel-app:latest .
   ```

2. Test the image:
   ```bash
   docker run --rm laravel-app:latest php -m | grep curl
   docker run --rm laravel-app:latest bash /usr/local/bin/docker-entrypoint test
   ```

3. Run with your Laravel app:
   ```bash
   docker run -d \
     -p 8080:8080 \
     -v /path/to/laravel:/var/www/html \
     --env-file /path/to/.env \
     laravel-app:latest
   ```

4. Check logs:
   ```bash
   docker logs -f <container-id>
   ```

## If Still Having Issues

Run the curl test inside the running container:
```bash
docker exec <container-id> bash /usr/local/bin/test-curl.sh
```

This will pinpoint exactly where the curl issue is.

## Environment Variables to Set

Minimum required in `.env`:
```env
APP_ENV=production
APP_KEY=base64:...
APP_DEBUG=false
DB_HOST=...
DB_DATABASE=...
DB_USERNAME=...
DB_PASSWORD=...
```

Optional PHP tuning:
```env
PHP_MEMORY_LIMIT=1024M
PHP_MAX_EXECUTION_TIME=120
PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
```

