FROM dunglas/frankenphp:1-php8.4-bookworm

LABEL maintainer="Carlos Andres <descarlos2013@gmail.com>"

WORKDIR /var/www/html

# --- INSTALACIÓN DE NODE.JS 22 (Versión liviana) ---
# Copiamos los binarios de la imagen oficial de Node Alpine/Slim para mantenerlo ligero
COPY --from=node:22-slim /usr/local/bin /usr/local/bin
COPY --from=node:22-slim /usr/local/lib/node_modules /usr/local/lib/node_modules

# Install PHP extensions, then purge *only* -dev header packages.
# IMPORTANT: do NOT use --auto-remove here — it would cascade-remove shared
# runtime libs (e.g. libpq5, libmysqlclient) that the compiled .so extensions
# depend on at runtime, causing "could not find driver" errors.
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash nano htop mariadb-client procps tzdata \
    libzip-dev libpng-dev libonig-dev libxml2-dev libicu-dev zlib1g-dev \
    curl git unzip \
    libfreetype6-dev libjpeg62-turbo-dev libmagickwand-dev libpq-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) bcmath gd pdo_mysql zip intl pcntl posix pgsql pdo_pgsql exif \
    && pecl install redis imagick \
    && docker-php-ext-enable redis imagick \
    # Purge only the header/-dev packages; runtime .so libs remain intact
    && apt-get purge -y \
        libzip-dev libpng-dev libonig-dev libxml2-dev libicu-dev zlib1g-dev \
        libfreetype6-dev libjpeg62-turbo-dev libmagickwand-dev libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/src/php* /tmp/pear ~/.pearrc

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Caddy configuration
COPY ./Caddyfile /etc/caddy/Caddyfile

# OPcache profiles — api.sh copies the right one into conf.d at runtime
COPY docker/php/opcache-production.ini  /usr/local/etc/php/opcache-production.ini
COPY docker/php/opcache-development.ini /usr/local/etc/php/opcache-development.ini

# Copy ALL entrypoints — the dispatcher (default.sh / entrypoint) delegates to
# /usr/local/bin/${APP_MODE}.sh, so every script must be present in the image.
#   APP_MODE=api        → api.sh           (FrankenPHP web server, default)
#   APP_MODE=horizon    → horizon.sh       (Laravel Horizon queue supervisor)
#   APP_MODE=reverb     → reverb.sh        (Laravel Reverb websocket server)
#   APP_MODE=scheduler  → scheduler.sh     (Laravel task scheduler loop)
COPY docker/entrypoints/default.sh          /usr/local/bin/default.sh
COPY docker/entrypoints/default.optimized.sh /usr/local/bin/default.optimized.sh
COPY docker/entrypoints/api.sh              /usr/local/bin/api.sh
COPY docker/entrypoints/horizon.sh          /usr/local/bin/horizon.sh
COPY docker/entrypoints/reverb.sh           /usr/local/bin/reverb.sh
COPY docker/entrypoints/scheduler.sh        /usr/local/bin/scheduler.sh

# chmod + symlink entrypoint + interactive shell welcome — single layer
RUN chmod +x \
        /usr/local/bin/default.sh \
        /usr/local/bin/default.optimized.sh \
        /usr/local/bin/api.sh \
        /usr/local/bin/horizon.sh \
        /usr/local/bin/reverb.sh \
        /usr/local/bin/scheduler.sh \
    && ln -sf /usr/local/bin/default.sh /usr/local/bin/entrypoint \
    && echo '' >> /etc/bash.bashrc \
    && echo '# ─── Laravel container interactive welcome ───────────────────' >> /etc/bash.bashrc \
    && echo 'if [ -n "$PS1" ]; then' >> /etc/bash.bashrc \
    && echo '  R="\033[0m"; B="\033[1m"; DIM="\033[2m"' >> /etc/bash.bashrc \
    && echo '  CYN="\033[1;36m"; GRN="\033[1;32m"; YLW="\033[1;33m"; WHT="\033[1;37m"' >> /etc/bash.bashrc \
    && echo '  echo ""' >> /etc/bash.bashrc \
    && echo '  echo -e "${CYN}${B}  ██╗      █████╗ ██████╗  █████╗ ██╗   ██╗███████╗██╗     ${R}"' >> /etc/bash.bashrc \
    && echo '  echo -e "${CYN}${B}  ██║     ██╔══██╗██╔══██╗██╔══██╗██║   ██║██╔════╝██║     ${R}"' >> /etc/bash.bashrc \
    && echo '  echo -e "${CYN}${B}  ██║     ███████║██████╔╝███████║██║   ██║█████╗  ██║     ${R}"' >> /etc/bash.bashrc \
    && echo '  echo -e "${CYN}${B}  ██║     ██╔══██║██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██║     ${R}"' >> /etc/bash.bashrc \
    && echo '  echo -e "${CYN}${B}  ███████╗██║  ██║██║  ██║██║  ██║ ╚████╔╝ ███████╗███████╗${R}"' >> /etc/bash.bashrc \
    && echo '  echo -e "${CYN}${B}  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚══════╝${R}"' >> /etc/bash.bashrc \
    && echo '  echo ""' >> /etc/bash.bashrc \
    && echo '  echo -e "  ${DIM}⚡ FrankenPHP · PHP 8.4 · Caddy · Node.js 22${R}"' >> /etc/bash.bashrc \
    && echo '  echo ""' >> /etc/bash.bashrc \
    && echo '  echo -e "  ${WHT}${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"' >> /etc/bash.bashrc \
    && echo '  echo -e "  ${WHT}${B}  Shell Aliases${R}"' >> /etc/bash.bashrc \
    && echo '  echo -e "  ${WHT}${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"' >> /etc/bash.bashrc \
    && echo '  echo -e "    ${GRN}pa${R}   php artisan"' >> /etc/bash.bashrc \
    && echo '  echo -e "    ${GRN}ts${R}   php artisan typescript:transform"' >> /etc/bash.bashrc \
    && echo '  echo -e "    ${GRN}cu${R}   composer update"' >> /etc/bash.bashrc \
    && echo '  echo -e "  ${WHT}${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"' >> /etc/bash.bashrc \
    && echo '  echo ""' >> /etc/bash.bashrc \
    && echo 'fi' >> /etc/bash.bashrc \
    && echo "alias pa='cd /var/www/html && php artisan'" >> /etc/bash.bashrc \
    && echo "alias ts='cd /var/www/html && php artisan typescript:transform'" >> /etc/bash.bashrc \
    && echo "alias cu='cd /var/www/html && composer update'" >> /etc/bash.bashrc

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint"]
