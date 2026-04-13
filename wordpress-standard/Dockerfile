FROM php:8.3-fpm-alpine

# ── System dependencies ──────────────────────────────────────────────
RUN apk add --no-cache \
    bash curl git unzip zip \
    openssh-server \
    nginx \
    supervisor \
    # PHP build deps
    libzip-dev icu-dev oniguruma-dev freetype-dev libjpeg-turbo-dev libpng-dev \
    libwebp-dev imagemagick-dev linux-headers \
    # Runtime deps
    nodejs npm \
    mariadb-client \
    shadow

# ── PHP extensions ───────────────────────────────────────────────────
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-install -j$(nproc) \
    pdo pdo_mysql mysqli \
    opcache \
    intl \
    zip \
    gd \
    mbstring \
    exif \
    bcmath \
    pcntl \
    sockets

# Redis extension
RUN apk add --no-cache --virtual .build-deps autoconf g++ make && \
    pecl install redis && \
    docker-php-ext-enable redis && \
    apk del .build-deps

# ImageMagick extension
RUN apk add --no-cache --virtual .build-deps autoconf g++ make && \
    pecl install imagick && \
    docker-php-ext-enable imagick && \
    apk del .build-deps

# ── PHP config (OPcache tuning) ──────────────────────────────────────
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache.ini

RUN { \
    echo 'upload_max_filesize=64M'; \
    echo 'post_max_size=64M'; \
    echo 'memory_limit=256M'; \
    echo 'max_execution_time=300'; \
    echo 'max_input_vars=3000'; \
    } > /usr/local/etc/php/conf.d/wordpress.ini

# ── Composer 2 ───────────────────────────────────────────────────────
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# ── WP-CLI ───────────────────────────────────────────────────────────
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# ── SSH setup ────────────────────────────────────────────────────────
RUN mkdir -p /var/run/sshd /root/.ssh && \
    ssh-keygen -A && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    echo "AuthorizedKeysCommand /usr/local/bin/fetch-keys.sh %u" >> /etc/ssh/sshd_config && \
    echo "AuthorizedKeysCommandUser nobody" >> /etc/ssh/sshd_config

# ── AuthorizedKeysCommand script ─────────────────────────────────────
# This script fetches SSH keys from a Git repo URL set via environment variable
# SSH_KEYS_URL should point to a raw file containing authorized public keys
COPY fetch-keys.sh /usr/local/bin/fetch-keys.sh
RUN chmod 755 /usr/local/bin/fetch-keys.sh

# ── Supervisor config (runs php-fpm + sshd) ──────────────────────────
COPY supervisord.conf /etc/supervisord.conf

# ── Working directory ────────────────────────────────────────────────
WORKDIR /var/www/html

EXPOSE 9000 22

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
