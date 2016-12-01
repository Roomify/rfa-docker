#!/bin/bash

set -e

if [ -n "$MYSQL_PORT_3306_TCP_ADDR" ]; then
  DRUPAL_DB_HOST=$MYSQL_PORT_3306_TCP_ADDR
  echo >&2 "  Connecting to DRUPAL_DB_HOST ($DRUPAL_DB_HOST)"
fi

if [ -z "$DRUPAL_DB_HOST" ]; then
  echo >&2 'error: missing DRUPAL_DB_HOST or MYSQL_PORT_3306_TCP_ADDR environment variables'
  echo >&2 '  Did you forget to --link some_mysql_container:mysql or set an external db'
  echo >&2 '  with -e DRUPAL_DB_HOST=hostname:port?'
  exit 1
fi

: ${DRUPAL_DB_NAME:=drupal}
: ${DRUPAL_DB_USER:=drupal}
: ${DRUPAL_DB_PASSWORD:=$MYSQL_ENV_MYSQL_PASSWORD}

if [ -z "$DRUPAL_DB_PASSWORD" ]; then
  echo >&2 'error: missing required DRUPAL_DB_PASSWORD environment variable'
  echo >&2 '  Did you forget to -e DRUPAL_DB_PASSWORD=... ?'
  echo >&2
  echo >&2 '  (Also of interest might be DRUPAL_DB_USER and DRUPAL_DB_NAME.)'
  exit 1
fi

set_config() {
  key="$1"
  value="$2"
  php_escaped_value="$(php -r 'var_export($argv[1]);' "$value")"
  sed_escaped_value="$(echo "$php_escaped_value" | sed 's/[\/&]/\\&/g')"
  sed -ri "s/((['\"])$key\2\s*,\s*)(['\"]).*\3/\1$sed_escaped_value/" sites/default/settings.php
}

set_config 'DB_HOST' "$DRUPAL_DB_HOST"
set_config 'DB_USER' "$DRUPAL_DB_USER"
set_config 'DB_PASSWORD' "$DRUPAL_DB_PASSWORD"
set_config 'DB_NAME' "$DRUPAL_DB_NAME"

chown -R www-data:www-data sites

until nc -z -v -w30 ${DRUPAL_DB_HOST} 3306
do
  echo >&2 "Waiting for database connection..."
  sleep 2
done
echo >&2 "mysql ready"

# Check if the database has been imported.
echo >&2 "Checking for previously installed database..."
TABLES=$(mysql -h${DRUPAL_DB_HOST} -u${DRUPAL_DB_USER} -p${DRUPAL_DB_PASSWORD} -e 'SHOW TABLES' ${DRUPAL_DB_NAME})
if [[ ${TABLES} == '' ]]
then
  echo >&2 "Database not yet installed, importing..."
  mysql -h${DRUPAL_DB_HOST} -u${DRUPAL_DB_USER} -p${DRUPAL_DB_PASSWORD} ${DRUPAL_DB_NAME} < /var/www/html/accommodations-database.sql
  echo >&2 "Imported RfA database."
fi

echo >&2 "Starting webserver..."
exec "$@"
