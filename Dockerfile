FROM alpine:3.17

LABEL description "Rainloop is a simple, modern & fast web-based client"

ARG RAINLOOP_VER=1.17.0

ARG PHP_VERSION=81

ARG GPG_FINGERPRINT="3B79 7ECE 694F 3B7B 70F3  11A4 ED7C 49D9 87DA 4591"

ENV UID=991 GID=991 UPLOAD_MAX_SIZE=25M LOG_TO_STDOUT=false MEMORY_LIMIT=128M

RUN apk update && apk -U upgrade \
 && apk add -t build-dependencies \
    gnupg \
    openssl \
    wget \
 && apk add \
    ca-certificates \
    nginx \
    s6 \
    su-exec \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-iconv \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-dom \
    php${PHP_VERSION}-openssl \
    php${PHP_VERSION}-json \
    php${PHP_VERSION}-zlib \
    php${PHP_VERSION}-pdo_pgsql \
    php${PHP_VERSION}-pdo_mysql \
    php${PHP_VERSION}-pdo_sqlite \
    php${PHP_VERSION}-sqlite3 \
    php${PHP_VERSION}-ldap \
    php${PHP_VERSION}-simplexml \
 && cd /tmp \
 && RAINLOOP_ZIP="rainloop-legacy-${RAINLOOP_VER}.zip" \
 && echo "https://github.com/RainLoop/rainloop-webmail/releases/download/v${RAINLOOP_VER}/${RAINLOOP_ZIP}" \
 && echo "https://github.com/RainLoop/rainloop-webmail/releases/download/v${RAINLOOP_VER}/${RAINLOOP_ZIP}.asc" \
 && wget -q -O rainloop-community-latest.zip https://github.com/RainLoop/rainloop-webmail/releases/download/v${RAINLOOP_VER}/${RAINLOOP_ZIP} \
 && wget -q -O rainloop-community-latest.zip.asc https://github.com/RainLoop/rainloop-webmail/releases/download/v${RAINLOOP_VER}/${RAINLOOP_ZIP}.asc \
 && wget -q https://www.rainloop.net/repository/RainLoop.asc \
 && gpg --import RainLoop.asc \
 && FINGERPRINT="$(LANG=C gpg --verify rainloop-community-latest.zip.asc rainloop-community-latest.zip 2>&1 \
  | sed -n "s#Primary key fingerprint: \(.*\)#\1#p")" \
 && if [ -z "${FINGERPRINT}" ]; then echo "ERROR: Invalid GPG signature!" && exit 1; fi \
 && if [ "${FINGERPRINT}" != "${GPG_FINGERPRINT}" ]; then echo "ERROR: Wrong GPG fingerprint!" && exit 1; fi \
 && mkdir /rainloop && unzip -q /tmp/rainloop-community-latest.zip -d /rainloop \
 && find /rainloop -type d -exec chmod 755 {} \; \
 && find /rainloop -type f -exec chmod 644 {} \; \
 && apk del build-dependencies \
 && rm -rf /tmp/* /var/cache/apk/* /root/.gnupg

COPY rootfs /
RUN chmod +x /usr/local/bin/run.sh /services/*/run /services/.s6-svscan/*
VOLUME /rainloop/data
EXPOSE 8888
CMD ["run.sh"]
