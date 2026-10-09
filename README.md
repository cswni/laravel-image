# cswni/laravel — imagen PHP para Laravel

PHP 8.4 ZTS sobre Alpine con FrankenPHP y Swoole. Sin Node.

Extensiones: bcmath, exif, gd, intl, opcache, pcntl, sockets, zip, pdo_mysql, pdo_pgsql, pgsql, redis, swoole, imagick (opcional), xdebug (opcional, solo dev).

## Targets

| Imagen | Uso | Código | Composer | opcache |
|--------|-----|--------|----------|---------|
| `cswni/laravel:8.4-dev` | Desarrollo local | Bind mount, recarga con watcher | Sí | Revalida archivos, sin JIT |
| `cswni/laravel:8.4-builder` | Etapa `vendor` de la imagen de la app | — | Sí (+ git, unzip) | — |
| `cswni/laravel:8.4-prod` | Base de la imagen de la app en development, qa y production | Copiado dentro en cada deploy | No | No revalida, JIT tracing |

En desarrollo local el código sigue montado como volumen. En development, qa y production cada deploy construye una imagen nueva con el código ya dentro, a partir de `8.4-builder` y `8.4-prod`.

## Construir (en el servidor Linux)

```bash
make build-all          # dev, builder y prod
make build              # solo dev
make build-noimagick    # dev sin ImageMagick
make build-xdebug       # dev con Xdebug (apagado hasta XDEBUG_MODE=debug)
make verify-all
make size
```

## Imagen de la app en cada deploy

`8.4-prod` trae `LARAVEL_OPTIMIZE=1`: al arrancar cada contenedor crea `public/storage` si falta y ejecuta `php artisan optimize`. Se hace al arrancar y no al construir porque `.env` y `storage/` solo existen en runtime.

```dockerfile
# Dockerfile de la app (p. ej. premas-web-api)
FROM cswni/laravel:8.4-builder AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --prefer-dist --no-progress
COPY . .
# --no-scripts: package:discover needs .env/storage; Laravel builds the
# manifest on first boot instead (or run it here with a throwaway .env)
RUN composer dump-autoload --optimize --no-dev --no-scripts

FROM node:22-alpine AS assets
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
COPY --from=vendor /app/vendor ./vendor
RUN pnpm run build

FROM cswni/laravel:8.4-prod
COPY --from=vendor /app /var/www/html
COPY --from=assets /app/public/build /var/www/html/public/build
```

El stack fija `OCTANE_SERVER` (`swoole` o `frankenphp`), monta `.env` y un volumen para `storage/`.

El `.dockerignore` de la app debe excluir `.env` y `.env.*` (salvo `.env.example`). Con `APP_ENV=production`, Laravel carga `.env.production` antes que el `.env` montado si ese archivo viene dentro de la imagen.

## Modos (`APP_MODE`)

| Modo | Comando | Tras editar código |
|------|---------|--------------------|
| `api` | `octane:start` (frankenphp/swoole) o `frankenphp php-server` (classic) | ver abajo |
| `horizon` | `php artisan horizon` | `php artisan horizon:terminate` (Swarm lo reinicia) |
| `queue` | `php artisan queue:listen` | automático, un proceso por job |
| `scheduler` | `php artisan schedule:work` | automático |
| `reverb` | `php artisan reverb:start` | `php artisan reverb:restart` |

Un `command:` en el stack se ejecuta tal cual en lugar del modo.

### Servidor HTTP (`OCTANE_SERVER`, modo `api`)

| Valor | Qué hace | Recarga |
|-------|----------|---------|
| `frankenphp` (defecto) | Octane con workers FrankenPHP | Automática con `OCTANE_WATCH=1` (watcher nativo, sin Node) |
| `swoole` | Octane con Swoole, igual que producción | Manual: `reload` dentro del contenedor (ver abajo) |
| `classic` | FrankenPHP sin workers | No hace falta: cada request lee el disco |

El watcher usa las rutas de `watch` en `config/octane.php` de la app. Funciona porque el código vive en el disco del servidor Linux: los archivos que sube PhpStorm por SFTP generan eventos inotify normales.

Swoole solo se carga en modo `swoole` (vía `PHP_INI_SCAN_DIR`), nunca dentro de FrankenPHP.

## Variables

| Variable | dev / prod | |
|----------|---------|---|
| `APP_MODE` | `api` | `api`, `horizon`, `queue`, `scheduler`, `reverb` |
| `OCTANE_SERVER` | `frankenphp` | `frankenphp`, `swoole`, `classic` |
| `OCTANE_WATCH` | `1` / `0` | Recarga automática (solo FrankenPHP) |
| `OCTANE_WORKERS` | `2` / `auto` | |
| `OCTANE_MAX_REQUESTS` | `500` | |
| `OCTANE_PORT` | `8080` | |
| `PHP_MEMORY_LIMIT` | `512M` | Se aplica al arrancar, sin rebuild |
| `QUEUE_NAMES` / `QUEUE_TRIES` / `QUEUE_TIMEOUT` | — / `1` / `60` | Modo `queue` |
| `REVERB_SERVER_PORT` / `REVERB_DEBUG` | `8080` / `0` | Modo `reverb` |
| `LARAVEL_OPTIMIZE` | `0` / `1` | `php artisan optimize` y `public/storage` al arrancar |
| `XDEBUG_MODE` | `off` / — | Con `make build-xdebug` |

## Comandos dentro del contenedor

`reload` recarga los workers de Octane y `ts` ejecuta `php artisan typescript:transform`. Son comandos y no alias de shell, así que funcionan con `docker exec` sin abrir una shell. Con Swarm no hay `docker compose exec`; se entra por el nombre del contenedor:

```bash
docker exec $(docker ps -qf name=premas-api-2025_api) reload
docker exec $(docker ps -qf name=premas-api-2025_api) ts
```

## Ejemplo de stack (Swarm + Traefik)

La imagen no define `HEALTHCHECK`: Traefik descarta contenedores `unhealthy`, así que el chequeo va por servicio. `docker stack deploy -c stack.yml myapp`.

```yaml
x-app: &app
  image: cswni/laravel:8.4-dev
  env_file: .env
  volumes:
    - /var/www/myapp:/var/www/html
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
    deploy:
      labels:
        - traefik.enable=true
        - traefik.swarm.network=traefik-net
        - traefik.http.routers.myapp.rule=Host(`myapp.${BASEDOMAIN}`)
        - traefik.http.routers.myapp.entrypoints=https
        - traefik.http.routers.myapp.tls=true
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
    deploy:
      labels:
        - traefik.enable=true
        - traefik.swarm.network=traefik-net
        - traefik.http.routers.myapp-ws.rule=Host(`ws.${BASEDOMAIN}`)
        - traefik.http.routers.myapp-ws.entrypoints=https
        - traefik.http.routers.myapp-ws.tls=true
        - traefik.http.services.myapp-ws.loadbalancer.server.port=8080

networks:
  traefik-net:
    external: true
```

Detrás de Traefik, la app debe confiar en el proxy (`trustProxies`) para generar URLs con el esquema y host correctos.
