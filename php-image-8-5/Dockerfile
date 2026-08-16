FROM dunglas/frankenphp:1-php8.5-bookworm

LABEL maintainer="Carlos Andres <descarlos2013@gmail.com>"
LABEL description="Optimized Laravel FrankenPHP Image"
LABEL version="3.0"

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_NO_INTERACTION=1 \
    COMPOSER_MEMORY_LIMIT=-1 \
    PHP_MEMORY_LIMIT=512M \
    PHP_MAX_EXECUTION_TIME=60 \
    PHP_POST_MAX_SIZE=100M \
    PHP_UPLOAD_MAX_FILESIZE=100M

WORKDIR /var/www/html

# Instala extensiones PHP requeridas usando el instalador oficial
RUN apt-get update && apt-get install -y \
    bash nano htop mariadb-client procps tzdata \
    libzip-dev libpng-dev libonig-dev libxml2-dev libicu-dev zlib1g-dev curl git unzip \
    libfreetype6-dev libjpeg62-turbo-dev libmagickwand-dev libpq-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install bcmath gd pdo_mysql zip intl pcntl posix pgsql pdo_pgsql exif \
    && pecl install redis imagick \
    && docker-php-ext-enable redis imagick \
    && rm -rf /var/lib/apt/lists/* /tmp/pear ~/.pearrc

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY docker/php/php.ini /usr/local/etc/php/conf.d/99-custom.ini
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/10-opcache.ini

COPY Caddyfile /etc/caddy/Caddyfile

COPY docker/entrypoints/entrypoint.sh /usr/local/bin/docker-entrypoint
COPY docker/entrypoints/test.sh /usr/local/bin/test
COPY docker/entrypoints/test-curl.sh /usr/local/bin/test-curl
RUN chmod +x /usr/local/bin/docker-entrypoint /usr/local/bin/test /usr/local/bin/test-curl

RUN echo "alias pa='php artisan'" >> /etc/bash.bashrc \
    && echo "alias pao='php artisan optimize'" >> /etc/bash.bashrc \
    && echo "alias paoc='php artisan optimize:clear'" >> /etc/bash.bashrc \
    && echo "alias ci='composer install'" >> /etc/bash.bashrc \
    && echo "alias cu='composer update'" >> /etc/bash.bashrc \
    && echo "alias cda='composer dump-autoload -o'" >> /etc/bash.bashrc

RUN mkdir -p /var/www/html/storage /var/www/html/bootstrap/cache \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=45s --retries=3 \
    CMD curl -f http://localhost:8080/up || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]

