#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH=/data/options.json
MYSQL_DATA=/data/mysql
INIT_MARKER=/data/.runalyze_db_initialized
RUNALYZE_DIR=/var/www/runalyze
APACHE_PORT=8099

DB_NAME="runalyze"
DB_USER="runalyze"
DB_PASSWORD="change_me"
DB_ROOT_PASSWORD="change_me_root"

if [ -f "${CONFIG_PATH}" ]; then
  DB_NAME="$(php -r 'echo json_decode(file_get_contents("/data/options.json"), true)["db_name"] ?? "runalyze";')"
  DB_USER="$(php -r 'echo json_decode(file_get_contents("/data/options.json"), true)["db_user"] ?? "runalyze";')"
  DB_PASSWORD="$(php -r 'echo json_decode(file_get_contents("/data/options.json"), true)["db_password"] ?? "change_me";')"
  DB_ROOT_PASSWORD="$(php -r 'echo json_decode(file_get_contents("/data/options.json"), true)["db_root_password"] ?? "change_me_root";')"
fi

mkdir -p /run/mysqld /run/apache2 "${MYSQL_DATA}"
chown -R mysql:mysql /run/mysqld "${MYSQL_DATA}"

if [ ! -d "${MYSQL_DATA}/mysql" ]; then
  echo "Initializing MariaDB data directory"
  mariadb-install-db --user=mysql --datadir="${MYSQL_DATA}" --skip-test-db >/dev/null
  rm -f "${INIT_MARKER}"
fi

cat >/etc/mysql/mariadb.conf.d/99-runalyze.cnf <<EOF
[mysqld]
datadir=${MYSQL_DATA}
bind-address=127.0.0.1
socket=/run/mysqld/mysqld.sock
skip-networking=0
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

[client]
socket=/run/mysqld/mysqld.sock
EOF

mysqld_safe --datadir="${MYSQL_DATA}" --socket=/run/mysqld/mysqld.sock --pid-file=/run/mysqld/mysqld.pid &
MYSQL_PID=$!

for i in $(seq 1 60); do
  if mariadb-admin ping --socket=/run/mysqld/mysqld.sock --silent; then
    break
  fi
  sleep 1
  if [ "$i" = "60" ]; then
    echo "MariaDB did not start in time" >&2
    exit 1
  fi
done

if [ ! -f "${INIT_MARKER}" ]; then
  mariadb --socket=/run/mysqld/mysqld.sock <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL
  touch "${INIT_MARKER}"
else
  echo "MariaDB was already initialized, keeping existing database and users."
fi

mkdir -p "${RUNALYZE_DIR}/app/cache" "${RUNALYZE_DIR}/app/logs" "${RUNALYZE_DIR}/var" "${RUNALYZE_DIR}/web/uploads"
chown -R www-data:www-data "${RUNALYZE_DIR}/app/cache" "${RUNALYZE_DIR}/app/logs" "${RUNALYZE_DIR}/var" "${RUNALYZE_DIR}/web/uploads"

cat >/data/database.txt <<EOF
Database host: 127.0.0.1
Database port: 3306
Database name: ${DB_NAME}
Database user: ${DB_USER}
Database password: ${DB_PASSWORD}
EOF
chmod 600 /data/database.txt

echo "RUNALYZE database settings written to /data/database.txt"
echo "Starting Apache on port ${APACHE_PORT}"

apache2ctl -D FOREGROUND &
APACHE_PID=$!

for i in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${APACHE_PORT}/" >/tmp/runalyze-healthcheck.html 2>/tmp/runalyze-healthcheck.err; then
    echo "RUNALYZE web server is reachable on port ${APACHE_PORT}"
    break
  fi
  if ! kill -0 "${APACHE_PID}" 2>/dev/null; then
    echo "Apache stopped unexpectedly" >&2
    cat /tmp/runalyze-healthcheck.err 2>/dev/null || true
    exit 1
  fi
  sleep 1
  if [ "$i" = "30" ]; then
    echo "Apache is running, but RUNALYZE did not return HTTP 2xx within 30 seconds." >&2
    echo "Last healthcheck error:" >&2
    cat /tmp/runalyze-healthcheck.err 2>/dev/null || true
  fi
done

trap 'apache2ctl stop || true; mariadb-admin --socket=/run/mysqld/mysqld.sock -uroot -p"${DB_ROOT_PASSWORD}" shutdown || true; kill ${MYSQL_PID} || true' TERM INT
wait "${APACHE_PID}"
