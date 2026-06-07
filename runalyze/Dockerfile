FROM debian:bookworm-slim

ARG BUILD_ARCH=amd64
ARG BUILD_VERSION=0.1.0
ARG RUNALYZE_REF=support/4.3.x

LABEL \
    io.hass.name="RUNALYZE Server" \
    io.hass.description="Self-hosted RUNALYZE Open Source server for Home Assistant" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.arch="${BUILD_ARCH}"

ENV DEBIAN_FRONTEND=noninteractive \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_PID_FILE=/run/apache2/apache2.pid \
    APACHE_RUN_DIR=/run/apache2 \
    APACHE_LOCK_DIR=/run/apache2 \
    RUNALYZE_DIR=/var/www/runalyze

RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    ca-certificates \
    curl \
    git \
    gnupg \
    mariadb-server \
    mariadb-client \
    php \
    php-cli \
    php-curl \
    php-gd \
    php-intl \
    php-mbstring \
    php-mysql \
    php-xml \
    php-zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${RUNALYZE_REF}" https://github.com/Runalyze/Runalyze.git "${RUNALYZE_DIR}" \
    && rm -rf "${RUNALYZE_DIR}/.git" \
    && chown -R www-data:www-data "${RUNALYZE_DIR}"

COPY rootfs /

RUN a2enmod rewrite headers expires \
    && a2dissite 000-default \
    && a2ensite runalyze \
    && chmod +x /usr/local/bin/run.sh \
    && mkdir -p /data /run/mysqld /run/apache2 \
    && chown -R mysql:mysql /run/mysqld \
    && chown -R www-data:www-data "${RUNALYZE_DIR}"

EXPOSE 80

CMD ["/usr/local/bin/run.sh"]
