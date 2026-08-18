# =============================================================================
# Stage 1 — builder
# Installs PHP, Composer, and resolves all vendor dependencies.
# Nothing from this stage leaks into the final image.
# =============================================================================
FROM alpine:3.18 AS builder

RUN apk add --no-cache \
        curl \
        php82 \
        php82-phar \
        php82-openssl \
        php82-mbstring \
        php82-json \
        php82-curl \
        php82-dom \
        php82-xml \
        php82-xmlwriter \
        php82-tokenizer \
        php82-simplexml \
        php82-ctype \
        php82-sodium \
    && ln -s /usr/bin/php82 /usr/bin/php

# Install Composer
RUN curl -sS https://getcomposer.org/installer \
    | php -- --install-dir=/usr/local/bin --filename=composer \
    && chmod +x /usr/local/bin/composer

WORKDIR /build

# [Fix 1] Copy composer manifests BEFORE the full source so vendor/ is built
# inside the container and never overwritten by a host-side vendor/ folder.
COPY lib/composer.json lib/composer.lock* lib/

# Install production dependencies only
RUN cd lib && composer install \
        --no-dev \
        --no-interaction \
        --no-progress \
        --optimize-autoloader \
        --classmap-authoritative

# Copy the full application source AFTER vendor is ready
COPY . .

# [Fix 2 — minimal] Remove only .git history; nothing else is stripped here
# so the runtime stage receives the complete application tree.
RUN rm -rf .git

# =============================================================================
# Stage 2 — runtime
# Lean production image: only runtime packages + pre-built app.
# =============================================================================
FROM alpine:3.18 AS runtime

# [Fix 3] Add php82-pdo_mysql so PDO database connections work at runtime
RUN apk add --no-cache \
        bash \
        nginx \
        redis \
        ffmpeg \
        file \
        php82 \
        php82-fpm \
        php82-fileinfo \
        php82-session \
        php82-curl \
        php82-openssl \
        php82-mbstring \
        php82-json \
        php82-gd \
        php82-dom \
        php82-pdo \
        php82-pdo_mysql \
        php82-exif \
        php82-phar \
        php82-ctype \
        php82-opcache \
        php82-sodium \
        php82-xml \
        php82-ftp \
        php82-simplexml \
        php82-pcntl \
        php82-pecl-redis \
    && ln -s /usr/bin/php82 /usr/bin/php

# Configure PHP-FPM to run as nginx user
RUN sed -i 's/nobody/nginx/g' /etc/php82/php-fpm.d/www.conf

# Tune PHP execution limits for large uploads / conversions
RUN sed -i "/max_execution_time/c\max_execution_time=3600" /etc/php82/php.ini \
 && sed -i "/max_input_time/c\max_input_time=3600"         /etc/php82/php.ini

# Nginx setup
COPY rootfs/nginx.conf /etc/nginx/http.d/default.conf
RUN mkdir -p /run/nginx /var/log/nginx

# [Fix 4] Use --chown so Nginx/PHP-FPM can read & write without Permission Denied
COPY --from=builder --chown=nginx:nginx /build /var/www

# [Fix 5] Strip Windows CRLF from entrypoint so it runs cleanly on Linux
COPY rootfs/start.sh /etc/start.sh
RUN sed -i 's/\r//' /etc/start.sh \
 && chmod +x /etc/start.sh

# Ensure the data directory exists (will be over-mounted by a volume)
RUN mkdir -p /var/www/data \
 && chown nginx:nginx /var/www/data

WORKDIR /var/www

# Persist uploaded content across container restarts
VOLUME /var/www/data

EXPOSE 80

ENTRYPOINT ["/etc/start.sh"]
