#!/usr/bin/env bash
set -e

[[ $DEBUG == true ]] && set -x

MYSQL_DATA_DIR="/oncoreport/ws/storage/app/database"
MYSQL_USER="www-data"
MYSQL_GROUP="staff"
MYSQL_RUN_DIR="/var/run/mysqld"
DB_NAME="oncoreport"

create_data_dir() {
  if [ ! -d ${MYSQL_DATA_DIR} ]; then
    mkdir -p ${MYSQL_DATA_DIR}
  fi
  chmod -R 0777 ${MYSQL_DATA_DIR}
  chown -R ${MYSQL_USER}:${MYSQL_GROUP} ${MYSQL_DATA_DIR}
}

create_run_dir() {
  if [ ! -d ${MYSQL_RUN_DIR} ]; then
    mkdir -p ${MYSQL_RUN_DIR}
  fi
  chmod -R 0775 ${MYSQL_RUN_DIR}
  chown -R ${MYSQL_USER}:${MYSQL_GROUP} ${MYSQL_RUN_DIR}
  if [ -e ${MYSQL_RUN_DIR}/mysqld.sock ]; then
    rm ${MYSQL_RUN_DIR}/mysqld.sock
  fi
  rm -rf ${MYSQL_RUN_DIR}/mysqld.sock.lock
}

initialize_mysql_database() {
  # initialize MySQL data directory
  if [ ! -d ${MYSQL_DATA_DIR}/mysql ]; then
    echo "Installing database..."
    mysqld --initialize-insecure
    if [ $? -ne 0 ]; then
      mysql_install_db >/dev/null 2>&1
    fi
  fi
  if [ ! -d ${MYSQL_DATA_DIR}/${DB_NAME} ]; then
    echo "Creating users..."
    if /usr/local/bin/create_mysql_users.sh; then
      export DB_CREATED="true"
    fi
  fi
}

[ ! -d "/oncoreport/ws/storage/app/public/" ] && mkdir -p "/oncoreport/ws/storage/app/public/"
[ ! -d "/oncoreport/ws/storage/app/tus_cache/" ] && mkdir -p "/oncoreport/ws/storage/app/tus_cache/"
[ ! -d "/oncoreport/ws/storage/app/logs/" ] && mkdir -p "/oncoreport/ws/storage/app/logs/"

if [[ "$CLOUD_ENV" == "true" ]]; then
  echo "Starting Oncoreport Webservice in Cloud Mode"
  [ ! -f /etc/supervisor/supervisord.conf.disabled ] && mv /etc/supervisor/supervisord.conf /etc/supervisor/supervisord.conf.disabled
  [ -f /etc/supervisor/supervisord-cloud.conf.disabled ] && mv /etc/supervisor/supervisord-cloud.conf.disabled /etc/supervisor/supervisord.conf
  [ -f /oncoreport/ws/.env ] && mv /oncoreport/ws/.env /oncoreport/ws/.env.disabled
  [ -f /oncoreport/ws/.env.cloud ] && mv /oncoreport/ws/.env.cloud /oncoreport/ws/.env
  [ -f /genkey.sh ] && rm /genkey.sh

  if [ ! -f "/oncoreport/ws/storage/app/.migrated" ] && [[ "$DEBUG" != "true" ]]; then
    touch "/oncoreport/ws/storage/app/.migrated" &&
      php /oncoreport/ws/artisan migrate --seed --force &&
      php /oncoreport/ws/artisan first:boot
  fi

else
  echo "Starting Oncoreport Webservice in Local Mode"
  create_data_dir
  create_run_dir
  initialize_mysql_database
fi

chown -R www-data:staff "/oncoreport/ws"
chmod -R 777 "/oncoreport/ws/storage/"

[ "$DB_CREATED" = "true" ] && touch "${MYSQL_DATA_DIR}/ready"

[ -f /var/run/apache2/apache2.pid ] && rm -f /var/run/apache2/apache2.pid

echo "Starting supervisord"
exec supervisord -n
