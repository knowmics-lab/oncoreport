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
            mysql_install_db > /dev/null 2>&1
        fi
    fi
    if [ ! -d ${MYSQL_DATA_DIR}/${DB_NAME} ]; then
        echo "Creating users..."
        if /usr/local/bin/create_mysql_users.sh; then #  && php /oncoreport/ws/artisan migrate --seed --force # TODO: add this part
            export DB_CREATED="true"
        fi
    fi
}

if [ ! -d "/oncoreport/ws/storage/app/public/" ]; then
    mkdir -p "/oncoreport/ws/storage/app/public/"
fi
# if [ ! -d "/oncoreport/ws/storage/app/annotations/" ]; then
#     mkdir -p "/oncoreport/ws/storage/app/annotations/"
# fi
# if [ ! -d "/oncoreport/ws/storage/app/references/" ]; then
#     mkdir -p "/oncoreport/ws/storage/app/references/"
# fi
if [ ! -d "/oncoreport/ws/storage/app/tus_cache/" ]; then
    mkdir -p "/oncoreport/ws/storage/app/tus_cache/"
fi
if [ ! -d "/oncoreport/ws/storage/app/logs/" ]; then
    mkdir -p "/oncoreport/ws/storage/app/logs/"
fi

create_data_dir
create_run_dir
initialize_mysql_database

chown -R www-data:staff "/oncoreport/ws"
chmod -R 777 "/oncoreport/ws/storage/"

if [ "$DB_CREATED" = "true" ]; then
    touch "${MYSQL_DATA_DIR}/ready"
fi

echo "Starting supervisord"
exec supervisord -n