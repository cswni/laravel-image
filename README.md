# cswni/laravel — imagen de desarrollo para Laravel

PHP 8.4 ZTS sobre Alpine con FrankenPHP y Swoole, pensada para desarrollo: el código se monta como volumen y no se empaqueta nada. Sin Node.

Extensiones: bcmath, exif, gd, intl, opcache, pcntl, sockets, zip, pdo_mysql, pdo_pgsql, pgsql, redis, swoole, imagick (opcional), xdebug (opcional). Composer incluido.

## Construir (en el servidor Linux)

```bash
make build              # cswni/laravel:8.4-dev
make build-noimagick    # sin ImageMagick, más liviana
make build-xdebug       # con Xdebug (apagado hasta XDEBUG_MODE=debug)
make verify
make size
```

## Modos (`APP_MODE`)

| Modo | Comando | Tras editar código |
|------|---------|--------------------|
| `api` | `octane:start` (frankenphp/swoole) o `frankenphp php-server` (classic) | ver abajo |
| `horizon` | `php artisan horizon` | `php artisan horizon:terminate` (compose lo reinicia) |
| `queue` | `php artisan queue:listen` | automático, un proceso por job |
| `scheduler` | `php artisan schedule:work` | automático |
| `reverb` | `php artisan reverb:start` | `php artisan reverb:restart` |

Un `command:` en compose se ejecuta tal cual en lugar del modo.

### Servidor HTTP (`OCTANE_SERVER`, modo `api`)

| Valor | Qué hace | Recarga |
|-------|----------|---------|
| `frankenphp` (defecto) | Octane con workers FrankenPHP | Automática con `OCTANE_WATCH=1` (watcher nativo, sin Node) |
| `swoole` | Octane con Swoole, igual que producción | Manual: `docker compose exec api reload` |
| `classic` | FrankenPHP sin workers | No hace falta: cada request lee el disco |

El watcher usa las rutas de `watch` en `config/octane.php` de la app. Funciona porque el código vive en el disco del servidor Linux: los archivos que sube PhpStorm por SFTP generan eventos inotify normales.

Swoole solo se carga en modo `swoole` (vía `PHP_INI_SCAN_DIR`), nunca dentro de FrankenPHP.

## Variables

| Variable | Defecto | |
|----------|---------|---|
| `APP_MODE` | `api` | `api`, `horizon`, `queue`, `scheduler`, `reverb` |
| `OCTANE_SERVER` | `frankenphp` | `frankenphp`, `swoole`, `classic` |
| `OCTANE_WATCH` | `1` | Recarga automática (solo FrankenPHP) |
| `OCTANE_WORKERS` | `2` | |
| `OCTANE_MAX_REQUESTS` | `500` | |
| `OCTANE_PORT` | `8080` | |
| `PHP_MEMORY_LIMIT` | `512M` | Se aplica al arrancar, sin rebuild |
| `QUEUE_NAMES` / `QUEUE_TRIES` / `QUEUE_TIMEOUT` | — / `1` / `60` | Modo `queue` |
| `REVERB_SERVER_PORT` / `REVERB_DEBUG` | `8080` / `0` | Modo `reverb` |
| `XDEBUG_MODE` | `off` | Con `make build-xdebug` |

## Ejemplo con Traefik

La imagen no define `HEALTHCHECK`: Traefik descarta contenedores `unhealthy`, así que el chequeo va por servicio.

```yaml
x-app: &app
  image: cswni/laravel:8.4-dev
  env_file: .env
  volumes:
    - ./:/var/www/html
  restart: unless-stopped
  networks: [traefik-net]

services:
  api:
    <<: *app
    environment:
      APP_MODE: api
      OCTANE_SERVER: frankenphp   # swoole | classic
    healthcheck:
      test: ["CMD", "wget", "-qO", "/dev/null", "http://127.0.0.1:8080/up"]
      interval: 10s
      start_period: 20s
    labels:
      - traefik.enable=true
      - traefik.http.routers.myapp.rule=Host(`myapp.dev.lan`)
      - traefik.http.services.myapp.loadbalancer.server.port=8080

  horizon:
    <<: *app
    environment: { APP_MODE: horizon }

  scheduler:
    <<: *app
    environment: { APP_MODE: scheduler }

  reverb:
    <<: *app
    environment: { APP_MODE: reverb }
    labels:
      - traefik.enable=true
      - traefik.http.routers.myapp-ws.rule=Host(`ws.myapp.dev.lan`)
      - traefik.http.services.myapp-ws.loadbalancer.server.port=8080

networks:
  traefik-net:
    external: true
```

Detrás de Traefik, la app debe confiar en el proxy (`trustProxies`) para generar URLs con el esquema y host correctos.
