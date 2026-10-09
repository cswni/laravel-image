# syntax=docker/dockerfile:1
# Laravel runtime: PHP ZTS (Alpine) + FrankenPHP + Swoole. Targets:
#   dev     — code bind-mounted, watcher on, Composer      (make build)
#   builder — Composer for the vendor stage of app images (make build-builder)
#   prod    — base for app images built on every deploy   (make build-prod)

ARG PHP_VERSION=8.4

FROM dunglas/frankenphp:1-php${PHP_VERSION}-alpine AS php

# ─── swoole: compiled by hand to choose its features ─────────────────────────
# install-php-extensions enables every DB hook (Firebird alone adds ~30 MB of
# libfbclient) plus ssh2/sqlite/zstd. Octane needs none of them.
FROM php AS swoole

ARG SWOOLE_VERSION=6.2.3

RUN set -eux; \
    apk add --no-cache $PHPIZE_DEPS linux-headers \
        openssl-dev curl-dev c-ares-dev brotli-dev postgresql-dev; \
    # --enable-sockets needs the sockets extension headers
    docker-php-ext-install sockets; \
    mkdir -p /usr/src/swoole /out; \
    cd /usr/src/swoole; \
    curl -fsSL "https://pecl.php.net/get/swoole-${SWOOLE_VERSION}.tgz" | tar xz --strip-components=1; \
    phpize; \
    ./configure \
        --enable-sockets \
        --enable-mysqlnd \
        --enable-swoole-curl \
        --enable-cares \
        --enable-brotli \
        --enable-swoole-pgsql; \
    make -j"$(nproc)"; \
    # unstripped swoole.so is ~50 MB of debug symbols
    strip --strip-unneeded modules/swoole.so; \
    cp modules/swoole.so /out/

# ─── imagick: built against the core ImageMagick libs only ───────────────────
# install-php-extensions pulls every coder (PDF → ghostscript 62 MB,
# HEIC → x265/aom 28 MB, SVG → librsvg/cairo/pango).
FROM php AS imagick

ARG IMAGICK_VERSION=3.8.0

RUN set -eux; \
    apk add --no-cache $PHPIZE_DEPS imagemagick-dev; \
    mkdir -p /usr/src/imagick /out; \
    cd /usr/src/imagick; \
    curl -fsSL "https://pecl.php.net/get/imagick-${IMAGICK_VERSION}.tgz" | tar xz --strip-components=1; \
    phpize; \
    ./configure; \
    make -j"$(nproc)"; \
    strip --strip-unneeded modules/imagick.so; \
    cp modules/imagick.so /out/

# ─── base: PHP ZTS + FrankenPHP + extensions ─────────────────────────────────
FROM php AS base

ARG WITH_IMAGICK=1

WORKDIR /var/www/html

# Copied straight to their final path: a COPY to /tmp + mv stores each .so
# twice (once per layer). Loaded by absolute path from the ini files below.
COPY --from=swoole  /out/swoole.so  /usr/local/lib/php/extensions-extra/
COPY --from=imagick /out/imagick.so /usr/local/lib/php/extensions-extra/

# install-php-extensions removes its build deps in this same layer.
# icu-data-full: Alpine's default ICU data is English-only (breaks es_* locales).
RUN set -eux; \
    apk add --no-cache tzdata icu-data-full c-ares brotli-libs libpq; \
    install-php-extensions \
        bcmath exif gd intl opcache pcntl sockets zip \
        pdo_mysql pdo_pgsql pgsql redis; \
    # Swoole loads only in swoole mode (api.sh / reload set PHP_INI_SCAN_DIR),
    # so it never runs inside FrankenPHP threads.
    mkdir -p "${PHP_INI_DIR}/conf.d-swoole"; \
    echo 'extension=/usr/local/lib/php/extensions-extra/swoole.so' \
        > "${PHP_INI_DIR}/conf.d-swoole/docker-php-ext-swoole.ini"; \
    if [ "${WITH_IMAGICK}" = "1" ]; then \
        # imagemagick: png/gif/bmp coders; jpeg and webp are separate packages
        apk add --no-cache imagemagick imagemagick-jpeg imagemagick-webp; \
        echo 'extension=/usr/local/lib/php/extensions-extra/imagick.so' \
            > "${PHP_INI_DIR}/conf.d/docker-php-ext-imagick.ini"; \
    else \
        rm /usr/local/lib/php/extensions-extra/imagick.so; \
    fi; \
    php -m > /dev/null

COPY docker/php/app.ini     ${PHP_INI_DIR}/conf.d/zz-app.ini
COPY docker/entrypoints/    /usr/local/bin/
COPY docker/bin/            /usr/local/bin/

RUN chmod +x /usr/local/bin/*.sh /usr/local/bin/reload /usr/local/bin/ts \
    && ln -sf /usr/local/bin/default.sh /usr/local/bin/entrypoint

EXPOSE 8080

# The parent image's healthcheck probes the Caddy admin port, which only exists
# in frankenphp mode. Traefik drops unhealthy containers, so define health
# per service in the stack instead.
HEALTHCHECK NONE

ENTRYPOINT ["/usr/local/bin/entrypoint"]
# Reset the parent CMD (frankenphp run); default.sh would exec it as "$@".
CMD []

# ─── builder: vendor stage of app images (composer install --no-dev) ────────
# Never shipped: the app Dockerfile copies vendor/ out of it into a prod image.
FROM base AS builder

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# git/unzip: fallback for packages without a dist archive
RUN apk add --no-cache git unzip

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_NO_INTERACTION=1

# ─── dev: bind-mounted code, Composer, opcache revalidation ──────────────────
FROM base AS dev

ARG WITH_XDEBUG=0

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY docker/php/opcache-dev.ini ${PHP_INI_DIR}/conf.d/zz-opcache.ini

RUN if [ "${WITH_XDEBUG}" = "1" ]; then install-php-extensions xdebug; fi

ENV APP_ENV=local \
    APP_MODE=api \
    OCTANE_SERVER=frankenphp \
    OCTANE_WATCH=1 \
    OCTANE_WORKERS=2 \
    PHP_MEMORY_LIMIT=512M \
    XDEBUG_MODE=off \
    COMPOSER_ALLOW_SUPERUSER=1

# ─── prod: runtime for app images built on every deploy ──────────────────────
# App Dockerfiles do `FROM cswni/laravel:8.4-prod` and COPY the code in.
# No Composer, no watcher; opcache never re-reads files.
FROM base AS prod

COPY docker/php/opcache-prod.ini ${PHP_INI_DIR}/conf.d/zz-opcache.ini

ENV APP_ENV=production \
    APP_MODE=api \
    OCTANE_SERVER=frankenphp \
    OCTANE_WATCH=0 \
    OCTANE_WORKERS=auto \
    LARAVEL_OPTIMIZE=1 \
    PHP_MEMORY_LIMIT=512M
