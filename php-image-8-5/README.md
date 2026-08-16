# Laravel FrankenPHP Docker Image (PHP 8.5)

Optimized Laravel container with FrankenPHP, configured for production and development environments.

## Features

- **PHP 8.5** with FrankenPHP
- **No Worker Mode** - Standard PHP/Laravel execution
- **All Required Extensions** - curl, gd, pdo_mysql, redis, imagick, etc.
- **Environment-based Configuration** - Production & Development modes
- **Optimized OPcache** - File cache enabled
- **Health Checks** - Built-in container health monitoring

## Quick Start

### 1. Copy your Laravel application

Place your Laravel application in the parent directory or mount it as a volume.

### 2. Configure Environment

```bash
cp .env.example ../.env
# Edit ../.env with your settings
```

### 3. Build and Run

```bash
# Build the image
docker build -t laravel-frankenphp:8.5 .

# Run with docker-compose
docker-compose up -d

# Or run directly
docker run -d \
  -p 8080:8080 \
  -v $(pwd)/../:/var/www/html \
  --env-file ../.env \
  laravel-frankenphp:8.5
```

## Environment Variables

### Application
- `APP_ENV` - Environment (production/local/development)
- `APP_DEBUG` - Debug mode (true/false)
- `APP_KEY` - Laravel encryption key

### PHP Settings
- `PHP_MEMORY_LIMIT` - Memory limit (default: 512M)
- `PHP_MAX_EXECUTION_TIME` - Max execution time (default: 60)
- `PHP_POST_MAX_SIZE` - POST size limit (default: 100M)
- `PHP_UPLOAD_MAX_FILESIZE` - Upload size limit (default: 100M)
- `PHP_TIMEZONE` - Timezone (default: UTC)

### OPcache
- `PHP_OPCACHE_ENABLE` - Enable OPcache (default: 1)
- `PHP_OPCACHE_VALIDATE_TIMESTAMPS` - Validate timestamps (0 for production, 1 for dev)

## Production vs Development

### Production Mode
```env
APP_ENV=production
APP_DEBUG=false
PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
```

Automatically runs:
- `php artisan optimize`
- `php artisan config:cache`
- `php artisan route:cache`
- `php artisan view:cache`

### Development Mode
```env
APP_ENV=local
APP_DEBUG=true
PHP_OPCACHE_VALIDATE_TIMESTAMPS=1
```

Automatically runs:
- `php artisan optimize:clear`

## PHP Extensions Included

- curl (built-in)
- gd (with freetype, jpeg, webp)
- pdo_mysql, pdo_pgsql
- redis
- imagick
- zip, intl, pcntl, exif, bcmath, opcache, sockets

## Shell Aliases

Access the container: `docker exec -it laravel-app bash`

Available aliases:
- `pa` - php artisan
- `pao` - php artisan optimize
- `paoc` - php artisan optimize:clear
- `ci` - composer install
- `cu` - composer update
- `cda` - composer dump-autoload -o

## Troubleshooting

### Check PHP Extensions
```bash
docker exec laravel-app php -m
```

### Check curl Extension
```bash
docker exec laravel-app php -r "echo extension_loaded('curl') ? 'curl OK' : 'curl MISSING';"
```

### View Logs
```bash
docker logs laravel-app
docker-compose logs -f app
```

## Building for Production

```bash
# Build optimized image
docker build -t myregistry/laravel-app:latest .

# Push to registry
docker push myregistry/laravel-app:latest
```

## License

MIT

