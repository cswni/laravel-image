# Lean PHP 8.4 + Swoole runtime for Laravel Octane (api / horizon / reverb / scheduler).
# Multi-stage: compile extensions in builder, ship only runtime libs + .so in final image.
# No Node, no Composer, no FrankenPHP/Caddy, no CLI junk.

# ─── Builder ──────────────────────────────────────────────────────────────────
FROM php:8.4-cli-bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        $PHPIZE_DEPS \
        curl \
        libzip-dev \
        libpng-dev \
        libonig-dev \
        libxml2-dev \
        libicu-dev \
        zlib1g-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libwebp-dev \
        libmagickwand-dev \
        libpq-dev \
        libssl-dev \
        libbrotli-dev \
        libcurl4-openssl-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    # posix is built into php:*-cli; do not docker-php-ext-install it
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        gd \
        mbstring \
        pdo_mysql \
        pdo_pgsql \
        pgsql \
        zip \
        intl \
        pcntl \
        exif \
        opcache \
        sockets \
    && pecl install redis imagick swoole \
    && docker-php-ext-enable redis imagick swoole \
    && rm -rf /var/lib/apt/lists/* /tmp/pear ~/.pearrc

# ─── Runtime ─────────────────────────────────────────────────────────────────
FROM php:8.4-cli-bookworm AS runtime

LABEL maintainer="Carlos Andres <descarlos2013@gmail.com>"
LABEL description="Lean PHP 8.4 + Swoole Laravel Octane runtime"
LABEL version="3.0"

ENV APP_MODE=api \
    APP_ENV=production \
    PHP_MEMORY_LIMIT=512M \
    OCTANE_SERVER=swoole

WORKDIR /var/www/html

# Runtime shared libs only (no -dev headers, no editors, no Node, no Composer)
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        tzdata \
        libzip4 \
        libpng16-16 \
        libonig5 \
        libxml2 \
        libicu72 \
        zlib1g \
        libfreetype6 \
        libjpeg62-turbo \
        libwebp7 \
        libmagickwand-6.q16-6 \
        libpq5 \
        libssl3 \
        libbrotli1 \
        libcurl4 \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Compiled extensions + enable ini files from builder
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# OPcache profiles — api.sh copies the right one into conf.d at runtime
COPY docker/php/opcache-production.ini  /usr/local/etc/php/opcache-production.ini
COPY docker/php/opcache-development.ini /usr/local/etc/php/opcache-development.ini

# Mode entrypoints (APP_MODE=api|horizon|reverb|scheduler)
COPY docker/entrypoints/default.sh    /usr/local/bin/default.sh
COPY docker/entrypoints/api.sh        /usr/local/bin/api.sh
COPY docker/entrypoints/horizon.sh    /usr/local/bin/horizon.sh
COPY docker/entrypoints/reverb.sh     /usr/local/bin/reverb.sh
COPY docker/entrypoints/scheduler.sh  /usr/local/bin/scheduler.sh

RUN chmod +x \
        /usr/local/bin/default.sh \
        /usr/local/bin/api.sh \
        /usr/local/bin/horizon.sh \
        /usr/local/bin/reverb.sh \
        /usr/local/bin/scheduler.sh \
    && ln -sf /usr/local/bin/default.sh /usr/local/bin/entrypoint \
    && mkdir -p /tmp/opcache \
    && chown -R www-data:www-data /tmp/opcache

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint"]
