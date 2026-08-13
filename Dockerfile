# Stage 1 — builder
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

# Copy composer manifests BEFORE the full source so vendor/ is built
COPY lib/composer.json lib/composer.lock* lib/

# Install production dependencies only
RUN cd lib && composer install \
        --no-dev \
        --no-interaction \
        --no-progress \
        --optimize-autoloader \
        --classmap-authoritative

# Copy the full application
COPY . .

# Remove .git history
RUN rm -rf .git

# Stage 2 — runtime
FROM alpine:3.18 AS runtime

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
COPY docker/rootfs/nginx.conf /etc/nginx/http.d/default.conf
RUN mkdir -p /run/nginx /var/log/nginx

# Use --chown so Nginx/PHP-FPM can read & write without Permission Denied
COPY --from=builder --chown=nginx:nginx /build /var/www

# Strip Windows CRLF from entrypoint
COPY docker/rootfs/start.sh /etc/start.sh
RUN sed -i 's/\r//' /etc/start.sh \
 && chmod +x /etc/start.sh

RUN mkdir -p /var/www/data \
 && chown nginx:nginx /var/www/data

WORKDIR /var/www

VOLUME /var/www/data

EXPOSE 80

ENTRYPOINT ["/etc/start.sh"]
