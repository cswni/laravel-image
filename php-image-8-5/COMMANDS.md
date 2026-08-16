# Build & Deploy Commands

## Local Development

```bash
# Build the image
docker build -t laravel-frankenphp:8.5 .

# Run with docker-compose
docker-compose up -d

# View logs
docker-compose logs -f app

# Access container
docker exec -it laravel-app bash

# Run Laravel commands
docker exec laravel-app php artisan migrate
docker exec laravel-app php artisan db:seed
```

## Testing

```bash
# Test PHP extensions
docker run --rm laravel-frankenphp:8.5 php -m

# Run test script
docker run --rm laravel-frankenphp:8.5 bash /usr/local/bin/test.sh

# Test curl specifically
docker run --rm laravel-frankenphp:8.5 php -r "var_dump(curl_version());"
```

## Production Build

```bash
# Set environment variables
export IMAGE_NAME=laravel-app
export IMAGE_TAG=v1.0.0
export REGISTRY=myregistry.com

# Build
./build.sh

# Or manually
docker build -t myregistry.com/laravel-app:v1.0.0 .
docker push myregistry.com/laravel-app:v1.0.0
```

## Remote Server Deployment

```bash
# SSH to server
ssh user@server

# Pull image
docker pull myregistry.com/laravel-app:v1.0.0

# Stop old container
docker stop laravel-app
docker rm laravel-app

# Run new container
docker run -d \
  --name laravel-app \
  --restart unless-stopped \
  -p 8080:8080 \
  -v /path/to/laravel:/var/www/html \
  --env-file /path/to/.env \
  myregistry.com/laravel-app:v1.0.0

# Check logs
docker logs -f laravel-app
```

## Troubleshooting

### curl Extension Issues

```bash
# Check if curl is loaded
docker exec laravel-app php -m | grep curl

# Test curl functions
docker exec laravel-app php -r "echo function_exists('curl_exec') ? 'curl_exec OK' : 'curl_exec MISSING';"

# Check PHP info
docker exec laravel-app php -i | grep curl
```

### Permission Issues

```bash
# Fix storage permissions
docker exec laravel-app chown -R www-data:www-data /var/www/html/storage
docker exec laravel-app chmod -R 775 /var/www/html/storage
```

### OPcache Issues

```bash
# Clear OPcache
docker exec laravel-app php artisan optimize:clear

# Check OPcache status
docker exec laravel-app php -r "var_dump(opcache_get_status());"
```

## Environment Variables Reference

### Required
- `APP_ENV` - production/local/development
- `APP_KEY` - Laravel encryption key
- `DB_HOST`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`

### Optional PHP Settings
- `PHP_MEMORY_LIMIT=512M`
- `PHP_MAX_EXECUTION_TIME=60`
- `PHP_POST_MAX_SIZE=100M`
- `PHP_UPLOAD_MAX_FILESIZE=100M`
- `PHP_TIMEZONE=UTC`
- `PHP_OPCACHE_ENABLE=1`
- `PHP_OPCACHE_VALIDATE_TIMESTAMPS=0` (production) or `1` (dev)

### Optional
- `LOG_LEVEL=info`
- `CACHE_DRIVER=redis`
- `QUEUE_CONNECTION=redis`
- `SESSION_DRIVER=redis`

