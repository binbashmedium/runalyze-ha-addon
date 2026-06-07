#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH=/data/options.json
RUNALYZE_DIR=/var/www/runalyze
APACHE_PORT=8099
TMP_DIR=/data/tmp

DB_HOST="core-mariadb"
DB_PORT="3306"
DB_NAME="runalyze"
DB_USER="runalyze"
DB_PASSWORD=""
DB_CREATE="false"
DB_USE_SUPERVISOR_SERVICE="false"
USER_CAN_REGISTER="true"
USER_DISABLE_ACCOUNT_ACTIVATION="true"

mkdir -p /run/apache2 "${TMP_DIR}" "${RUNALYZE_DIR}/data" "${RUNALYZE_DIR}/var/cache" "${RUNALYZE_DIR}/var/logs" "${RUNALYZE_DIR}/app/cache" "${RUNALYZE_DIR}/app/logs" "${RUNALYZE_DIR}/web/uploads"
chmod 1777 /tmp "${TMP_DIR}"
chown -R www-data:www-data "${RUNALYZE_DIR}/data" "${RUNALYZE_DIR}/var" "${RUNALYZE_DIR}/app/cache" "${RUNALYZE_DIR}/app/logs" "${RUNALYZE_DIR}/web/uploads"

if [ -f /etc/runalyze-addon-build-info ]; then
  echo "RUNALYZE add-on build info:"
  cat /etc/runalyze-addon-build-info
fi

json_value() {
  local key="$1"
  local fallback="$2"
  php -r '$data=json_decode(file_get_contents("/data/options.json"), true) ?: []; $key=$argv[1]; $fallback=$argv[2]; $value=$data[$key] ?? $fallback; if (is_bool($value)) { echo $value ? "true" : "false"; } else { echo $value; }' "$key" "$fallback"
}

json_field() {
  local file="$1"
  local field="$2"
  php -r '$data=json_decode(file_get_contents($argv[1]), true) ?: []; $field=$argv[2]; $value=$data["data"][$field] ?? $data[$field] ?? ""; if (is_bool($value)) { echo $value ? "true" : "false"; } else { echo $value; }' "$file" "$field"
}

validate_identifier() {
  local value="$1"
  local label="$2"
  if ! printf '%s' "$value" | grep -Eq '^[A-Za-z0-9_]+$'; then
    echo "Invalid ${label}: only letters, numbers and underscore are allowed." >&2
    exit 1
  fi
}

yaml_escape() {
  printf '%s' "$1" | sed "s/'/''/g"
}

mysql_run() {
  mariadb --protocol=TCP -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" "$@"
}

if [ -f "${CONFIG_PATH}" ]; then
  DB_HOST="$(json_value db_host "${DB_HOST}")"
  DB_PORT="$(json_value db_port "${DB_PORT}")"
  DB_NAME="$(json_value db_name "${DB_NAME}")"
  DB_USER="$(json_value db_user "${DB_USER}")"
  DB_PASSWORD="$(json_value db_password "${DB_PASSWORD}")"
  DB_CREATE="$(json_value db_create "${DB_CREATE}")"
  DB_USE_SUPERVISOR_SERVICE="$(json_value db_use_supervisor_service "${DB_USE_SUPERVISOR_SERVICE}")"
  USER_CAN_REGISTER="$(json_value user_can_register "${USER_CAN_REGISTER}")"
  USER_DISABLE_ACCOUNT_ACTIVATION="$(json_value user_disable_account_activation "${USER_DISABLE_ACCOUNT_ACTIVATION}")"
fi

if [ "${DB_USE_SUPERVISOR_SERVICE}" = "true" ]; then
  if [ -z "${SUPERVISOR_TOKEN:-}" ]; then
    echo "db_use_supervisor_service is true, but SUPERVISOR_TOKEN is not available." >&2
    exit 1
  fi
  echo "Reading MySQL service credentials from Home Assistant Supervisor"
  curl -fsS -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" -H "Content-Type: application/json" "http://supervisor/services/mysql" >"${TMP_DIR}/mysql-service.json"
  SERVICE_HOST="$(json_field "${TMP_DIR}/mysql-service.json" host)"
  SERVICE_PORT="$(json_field "${TMP_DIR}/mysql-service.json" port)"
  SERVICE_USER="$(json_field "${TMP_DIR}/mysql-service.json" username)"
  SERVICE_PASSWORD="$(json_field "${TMP_DIR}/mysql-service.json" password)"
  [ -n "${SERVICE_HOST}" ] && DB_HOST="${SERVICE_HOST}"
  [ -n "${SERVICE_PORT}" ] && DB_PORT="${SERVICE_PORT}"
  [ -n "${SERVICE_USER}" ] && DB_USER="${SERVICE_USER}"
  [ -n "${SERVICE_PASSWORD}" ] && DB_PASSWORD="${SERVICE_PASSWORD}"
  echo "Using Supervisor MySQL service user '${DB_USER}' at ${DB_HOST}:${DB_PORT}"
else
  echo "Using configured database user '${DB_USER}' at ${DB_HOST}:${DB_PORT}"
fi

echo "RUNALYZE registration config: user_can_register=${USER_CAN_REGISTER}, user_disable_account_activation=${USER_DISABLE_ACCOUNT_ACTIVATION}"

validate_identifier "${DB_NAME}" "db_name"
validate_identifier "${DB_USER}" "db_user"

if [ -z "${DB_PASSWORD}" ]; then
  echo "db_password is empty. Set db_password or enable db_use_supervisor_service." >&2
  exit 1
fi

if [ "${DB_CREATE}" = "true" ]; then
  echo "Creating RUNALYZE database on ${DB_HOST}:${DB_PORT}"
  mysql_run -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
fi

echo "Waiting for external MariaDB at ${DB_HOST}:${DB_PORT}"
for i in $(seq 1 60); do
  if mysql_run "${DB_NAME}" -e "SELECT 1" >/dev/null 2>"${TMP_DIR}/mariadb-check.err"; then
    echo "External MariaDB connection OK"
    break
  fi
  sleep 1
  if [ "$i" = "60" ]; then
    echo "Could not connect to external MariaDB as ${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}" >&2
    cat "${TMP_DIR}/mariadb-check.err" >&2 || true
    exit 1
  fi
done

cat >"${RUNALYZE_DIR}/data/config.yml" <<EOF
parameters:
  locale: de
  database_host: '$(yaml_escape "${DB_HOST}")'
  database_prefix: runalyze_
  database_port: ${DB_PORT}
  database_name: '$(yaml_escape "${DB_NAME}")'
  database_user: '$(yaml_escape "${DB_USER}")'
  database_password: '$(yaml_escape "${DB_PASSWORD}")'
  secret: '$(php -r 'echo bin2hex(random_bytes(24));')'
  update_disabled: no
  user_can_register: ${USER_CAN_REGISTER}
  user_disable_account_activation: ${USER_DISABLE_ACCOUNT_ACTIVATION}
  maintenance: false
  garmin_api_key:
  weather_proxy:
  openweathermap_api_key:
  meteostatnet_api_key:
  darksky_api_key:
  nokia_here_appid:
  nokia_here_token:
  thunderforest_api_key:
  mapbox_api_key:
  geonames_username:
  perl_path: /usr/bin/perl
  python3_path: /usr/bin/python3
  rsvg_path: /usr/bin/rsvg-convert
  inkscape_path:
  ttbin_path: ../call/perl/ttbincnv
  sqlite_mod_spatialite: libspatialite.so.5
  mail_selfmail: true
  mail_sender:
  mail_name: runalyze
  mail_localdomain: localhost
  smtp_host:
  smtp_port:
  smtp_security:
  smtp_username:
  smtp_password:
  backup_storage_period: 5
  poster_storage_period: 5
  router.request_context.host: localhost
  router.request_context.scheme: http
  router.request_context.base_url:
  osm_overpass_url: https://overpass.kumi.systems/api/interpreter
  osm_overpass_proxy:
EOF
chown www-data:www-data "${RUNALYZE_DIR}/data/config.yml"
chmod 600 "${RUNALYZE_DIR}/data/config.yml"

cat >/data/database.txt <<EOF
Database host: ${DB_HOST}
Database port: ${DB_PORT}
Database name: ${DB_NAME}
Database user: ${DB_USER}
Database password source: $([ "${DB_USE_SUPERVISOR_SERVICE}" = "true" ] && echo "supervisor mysql service" || echo "configured option")
EOF
chmod 600 /data/database.txt

echo "RUNALYZE database settings written to /data/database.txt"
TABLE_COUNT="$(mysql_run "${DB_NAME}" -N -B -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}' AND table_name LIKE 'runalyze_%';" 2>/dev/null || echo 0)"
echo "RUNALYZE table count before initialization: ${TABLE_COUNT}"

if [ "${TABLE_COUNT}" = "0" ]; then
  if [ -f "${RUNALYZE_DIR}/inc/install/structure.sql" ]; then
    echo "Importing RUNALYZE initial schema from inc/install/structure.sql"
    mysql_run "${DB_NAME}" < "${RUNALYZE_DIR}/inc/install/structure.sql"
  else
    echo "Missing ${RUNALYZE_DIR}/inc/install/structure.sql, cannot initialize empty database." >&2
    exit 1
  fi

  if [ -f "${RUNALYZE_DIR}/inc/install/MySQLEvents.sql" ]; then
    echo "Importing RUNALYZE MySQL events if permitted"
    mysql_run "${DB_NAME}" < "${RUNALYZE_DIR}/inc/install/MySQLEvents.sql" || echo "MySQL events import failed or EVENT privilege missing, continuing."
  fi

  TABLE_COUNT_AFTER="$(mysql_run "${DB_NAME}" -N -B -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}' AND table_name LIKE 'runalyze_%';" 2>/dev/null || echo 0)"
  echo "RUNALYZE table count after initial schema import: ${TABLE_COUNT_AFTER}"
else
  echo "RUNALYZE database already contains tables, skipping initial schema import"
fi

echo "Starting Apache on port ${APACHE_PORT}"
apache2ctl -D FOREGROUND &
APACHE_PID=$!

for i in $(seq 1 30); do
  HTTP_STATUS="$(curl -sS -o "${TMP_DIR}/runalyze-healthcheck.html" -w "%{http_code}" "http://127.0.0.1:${APACHE_PORT}/" 2>"${TMP_DIR}/runalyze-healthcheck.err" || true)"
  if [ "${HTTP_STATUS}" -ge 200 ] && [ "${HTTP_STATUS}" -lt 300 ]; then
    echo "RUNALYZE web server is reachable on port ${APACHE_PORT}"
    break
  fi
  sleep 1
  if [ "$i" = "30" ]; then
    echo "Apache is running, but RUNALYZE returned HTTP ${HTTP_STATUS} within 30 seconds." >&2
    echo "Last healthcheck response body, first 200 lines:" >&2
    sed -n '1,200p' "${TMP_DIR}/runalyze-healthcheck.html" >&2 || true
    echo "RUNALYZE internal logs, last 200 lines:" >&2
    find "${RUNALYZE_DIR}" -path '*/var/logs/*' -type f -exec sh -c 'echo "--- $1 ---" >&2; tail -n 200 "$1" >&2' sh {} \; 2>/dev/null || true
    find "${RUNALYZE_DIR}" -path '*/app/logs/*' -type f -exec sh -c 'echo "--- $1 ---" >&2; tail -n 200 "$1" >&2' sh {} \; 2>/dev/null || true
  fi
done

trap 'apache2ctl stop || true' TERM INT
wait "${APACHE_PID}"
