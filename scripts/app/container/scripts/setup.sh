#!/usr/bin/env bash

# Create Web Service Directory

(
  cd /oncoreport &&
    tar -zxvf /ws.tgz &&
    rm /ws.tgz &&
    rm -fr /var/www/html &&
    ln -s /oncoreport/ws/public /var/www/html &&
    ln -s /oncoreport/scripts/genkey.sh /genkey.sh
) || exit 103

# # Install cython and Crossmap
# pip3 install cython || exit 109
# pip3 install CrossMap || exit 110
# pip3 install CrossMap --upgrade || exit 111

# Apply MYSQL configuration fixes
apply_configuration_fixes() {
  sed -i 's/^log_error/# log_error/' /etc/mysql/mysql.conf.d/mysqld.cnf
  sed -i 's/.*datadir.*/datadir = \/oncoreport\/ws\/storage\/app\/database/' /etc/mysql/mysql.conf.d/mysqld.cnf
  sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
  sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
  sed -i "s/user.*/user = www-data/" /etc/mysql/mysql.conf.d/mysqld.cnf
  cat >/etc/mysql/conf.d/mysql-skip-name-resolv.cnf <<EOF
[mysqld]
skip_name_resolve
EOF
}

remove_debian_system_maint_password() {
  sed 's/password = .*/password = /g' -i /etc/mysql/debian.cnf
}

apply_configuration_fixes
remove_debian_system_maint_password

# Install the web service
(
  cd /oncoreport/ws/ &&
    mv .env.docker .env &&
    composer install --optimize-autoloader --no-dev &&
    php artisan key:generate &&
    php artisan storage:link
) || exit 139

# Apply PHP configuration fixes
sed -i 's/post_max_size \= .M/post_max_size \= 1G/g' /etc/php/*/apache2/php.ini
sed -i 's/upload_max_filesize \= .M/upload_max_filesize \= 1G/g' /etc/php/*/apache2/php.ini
sed -i "s/;date.timezone =/date.timezone = Europe\/London/g" /etc/php/*/apache2/php.ini
sed -i "s/;date.timezone =/date.timezone = Europe\/London/g" /etc/php/*/cli/php.ini
sed -i "s/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=staff/" /etc/apache2/envvars

# Set folder permission
chmod 755 /oncoreport/scripts/*
chmod 755 /oncoreport/databases/*
chmod -R 777 /oncoreport/ws/bootstrap/cache
chmod -R 777 /oncoreport/ws/storage
chmod 755 /genkey.sh
chmod -R 755 /usr/local/bin/
