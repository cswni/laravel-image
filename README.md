# cswni/laravel-swoole — lean PHP 8.4 + Swoole Octane runtime

Multi-stage Bookworm image: extensions compiled in a builder stage; final image has runtime libs only (no Node, no Composer, no FrankenPHP/Caddy, no editors).

```bash
make build          # → cswni/laravel-swoole:8.4
make verify
make size
```

## Modes (`APP_MODE`)

| Mode | Command |
|------|---------|
| `api` (default) | `php artisan octane:start --server=swoole` |
| `horizon` | `php artisan horizon` |
| `reverb` | `php artisan reverb:start` |
| `scheduler` | `schedule:run` loop |

```bash
docker run --rm -p 8080:8080 \
  -v "$(pwd)":/var/www/html \
  -e APP_MODE=api -e APP_ENV=production \
  cswni/laravel-swoole:8.4
```

Extensions: bcmath, gd, zip, intl, pcntl, posix, pgsql, pdo_pgsql, pdo_mysql, exif, opcache, sockets, redis, imagick, swoole.
