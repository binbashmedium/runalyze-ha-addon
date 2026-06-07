#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH=/data/options.json
MYSQL_DATA=/data/mysql
RUNALYZE_DIR=/var/www/runalyze

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

mariadb --socket=/run/mysqld/mysqld.sock <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

if [ -d "${RUNALYZE_DIR}/var" ]; then
  chown -R www-data:www-data "${RUNALYZE_DIR}/var"
fi
if [ -d "${RUNALYZE_DIR}/data" ]; then
  chown -R www-data:www-data "${RUNALYZE_DIR}/data"
fi

cat >/data/database.txt <<EOF
Database host: 127.0.0.1
Database port: 3306
Database name: ${DB_NAME}
Database user: ${DB_USER}
Database password: ${DB_PASSWORD}
EOF
chmod 600 /data/database.txt

echo "RUNALYZE database settings written to /data/database.txt"
echo "Open the add-on web UI and use these settings in the RUNALYZE installer if prompted."

apache2ctl -D FOREGROUND &
APACHE_PID=$!

trap 'apache2ctl stop || true; mariadb-admin --socket=/run/mysqld/mysqld.sock -uroot -p"${DB_ROOT_PASSWORD}" shutdown || true; kill ${MYSQL_PID} || true' TERM INT
wait "${APACHE_PID}"
