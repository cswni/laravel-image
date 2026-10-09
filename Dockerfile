# syntax=docker/dockerfile:1
# Laravel dev runtime: PHP ZTS (Alpine) + FrankenPHP + Swoole.
# Code is bind-mounted, nothing is packaged. Build on the Linux dev server:
#   make build

ARG PHP_VERSION=8.4

# ─── base: PHP ZTS + FrankenPHP + extensions ─────────────────────────────────
FROM dunglas/frankenphp:1-php${PHP_VERSION}-alpine AS base

ARG WITH_IMAGICK=1

WORKDIR /var/www/html

# install-php-extensions ships with the image and removes its build deps in
# this same layer. Pin versions for reproducible builds, e.g. swoole-6.0.2.
# icu-data-full: Alpine's default ICU data is English-only (breaks es_* locales).
RUN set -eux; \
    apk add --no-cache tzdata icu-data-full; \
    install-php-extensions \
        bcmath exif gd intl opcache pcntl sockets zip \
        pdo_mysql pdo_pgsql pgsql redis swoole; \
    if [ "${WITH_IMAGICK}" = "1" ]; then install-php-extensions imagick; fi; \
    # Swoole loads only in swoole mode (api.sh / reload set PHP_INI_SCAN_DIR),
    # so it never runs inside FrankenPHP threads.
    mkdir -p "${PHP_INI_DIR}/conf.d-swoole"; \
    mv "${PHP_INI_DIR}/conf.d/docker-php-ext-swoole.ini" "${PHP_INI_DIR}/conf.d-swoole/"

COPY docker/php/app.ini     ${PHP_INI_DIR}/conf.d/zz-app.ini
COPY docker/entrypoints/    /usr/local/bin/

RUN chmod +x /usr/local/bin/*.sh /usr/local/bin/reload \
    && ln -sf /usr/local/bin/default.sh /usr/local/bin/entrypoint

EXPOSE 8080

# The parent image's healthcheck probes the Caddy admin port, which only exists
# in frankenphp mode. Traefik drops unhealthy containers, so define health
# per service in compose instead.
HEALTHCHECK NONE

ENTRYPOINT ["/usr/local/bin/entrypoint"]
# Reset the parent CMD (frankenphp run); default.sh would exec it as "$@".
CMD []

# ─── dev: bind-mounted code, Composer, opcache revalidation ──────────────────
FROM base AS dev

ARG WITH_XDEBUG=0

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY docker/php/opcache.ini ${PHP_INI_DIR}/conf.d/zz-opcache.ini

RUN if [ "${WITH_XDEBUG}" = "1" ]; then install-php-extensions xdebug; fi

ENV APP_ENV=local \
    APP_MODE=api \
    OCTANE_SERVER=frankenphp \
    OCTANE_WATCH=1 \
    OCTANE_WORKERS=2 \
    PHP_MEMORY_LIMIT=512M \
    XDEBUG_MODE=off \
    COMPOSER_ALLOW_SUPERUSER=1
