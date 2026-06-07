FROM php:7.4-apache-bullseye

ARG BUILD_ARCH=amd64
ARG BUILD_VERSION=0.1.12
ARG RUNALYZE_REPOSITORY=https://github.com/codeproducer198/Runalyze.git
ARG RUNALYZE_REF=master

LABEL \
    io.hass.name="RUNALYZE Server" \
    io.hass.description="Self-hosted RUNALYZE Open Source server for Home Assistant" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.arch="${BUILD_ARCH}"

ENV DEBIAN_FRONTEND=noninteractive \
    COMPOSER_ALLOW_SUPERUSER=1 \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_PID_FILE=/run/apache2/apache2.pid \
    APACHE_RUN_DIR=/run/apache2 \
    APACHE_LOCK_DIR=/run/apache2 \
    RUNALYZE_DIR=/var/www/runalyze

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    libcurl4-openssl-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libonig-dev \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    mariadb-client \
    unzip \
    zip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) curl dom gd gettext intl mbstring mysqli pdo_mysql simplexml xml zip

RUN git clone --depth 1 --branch "${RUNALYZE_REF}" "${RUNALYZE_REPOSITORY}" "${RUNALYZE_DIR}" \
    && if [ ! -d "${RUNALYZE_DIR}/vendor" ]; then \
         curl -fsSL https://getcomposer.org/download/2.2.24/composer.phar -o /usr/local/bin/composer \
         && chmod +x /usr/local/bin/composer \
         && cd "${RUNALYZE_DIR}" \
         && composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader --no-scripts --ignore-platform-reqs; \
       fi \
    && rm -rf "${RUNALYZE_DIR}/.git" \
    && chown -R www-data:www-data "${RUNALYZE_DIR}"

COPY rootfs /

RUN sed -i 's/^Listen .*/Listen 8099/' /etc/apache2/ports.conf \
    && a2enmod rewrite headers expires \
    && a2dissite 000-default \
    && a2ensite runalyze \
    && chmod +x /usr/local/bin/run.sh \
    && mkdir -p /data /run/apache2 \
    && chown -R www-data:www-data "${RUNALYZE_DIR}"

EXPOSE 8099

CMD ["/usr/local/bin/run.sh"]
