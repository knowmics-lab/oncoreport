FROM ubuntu:focal as prepare
COPY . /support
ARG ONCOREPORT_ORIGIN https://github.com/knowmics-lab/oncoreport.git 
ARG ONCOREPORT_BRANCH master
RUN --mount=type=secret,id=drugbank --mount=type=secret,id=gltranslate bash /support/scripts/prepare.sh

FROM ubuntu:focal as oncoreport
ENV DOCKER_USER_ID 501
ENV DOCKER_USER_GID 20
ENV BOOT2DOCKER_ID 1000
ENV BOOT2DOCKER_GID 50
ENV SUPERVISOR_VERSION 4.2.0
ENV DEBUG false
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

ENV DEBIAN_FRONTEND noninteractive

# Copy support files from previous build stage
COPY --from=prepare /support /support

RUN usermod -u ${BOOT2DOCKER_ID} www-data && \
    usermod -G staff www-data && \
    useradd -r mysql && \
    usermod -G staff mysql && \
    groupmod -g $(($BOOT2DOCKER_GID + 10000)) $(getent group $BOOT2DOCKER_GID | cut -d: -f1) && \
    groupmod -g ${BOOT2DOCKER_GID} staff && \
    apt update --fix-missing && \
    apt install -y perl dialog software-properties-common &&  \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 51716619E084DAB9 && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/' &&  \
    add-apt-repository ppa:ondrej/php -y && \
    apt update && \
    apt install -y init && \
    apt dist-upgrade -y && \
    apt update --fix-missing && \
    apt install -y wget unzip bwa perl python3-pip curl tar samtools bedtools unixodbc tabix bcftools \
                   openjdk-8-jdk ant r-base grep tzdata cmake rename apt-utils nano beanstalkd \
                   python3-setuptools git apache2 php-xdebug composer php-cli jq python \
                   libapache2-mod-php mysql-server php-mysql pwgen php-apcu php-gd \
                   php-xml php-mbstring zip php-zip php-curl php-intl pigz ca-certificates-java \
                   libpcre16-3 libpcre2-16-0 libpcre2-32-0 libpcre2-posix2 libpcre32-3 libpcrecpp0v5 \
                   r-base-dev libssl-dev libxml2-dev libcurl4-openssl-dev libyaml-dev libfontconfig1-dev \
                   unixodbc-dev && \
    apt autoremove -y && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    update-java-alternatives -s "java-1.8.0-openjdk-amd64" && \
    update-ca-certificates -f && \
    curl -L https://pypi.io/packages/source/s/supervisor/supervisor-${SUPERVISOR_VERSION}.tar.gz | tar xvz && \
    cd supervisor-${SUPERVISOR_VERSION}/ && \
    python3 setup.py install && \
    mkdir -p /oncoreport/tmp/ && PW=$(pwd) && cd /oncoreport/tmp/ && \
    git clone https://github.com/linsalrob/fastq-pair.git && \
    cd fastq-pair/ && mkdir build && cd build && cmake .. && make && make install && \
    apt install -y libtool libgsl-dev libhts-dev && cd /oncoreport/tmp/ && \
    git clone https://github.com/CSB5/lofreq.git && cd lofreq && ./bootstrap && ./configure && make && make install && \
    cd "$PW" && rm -r /oncoreport/tmp/ && apt remove -y libgsl-dev libtool libhts-dev && \
    a2enmod rewrite && \
    export JAVA_HOME && \
    rm -rf /var/log/mysql && rm -rf /var/lib/mysql && \
    mv /support/scripts/bootstrap.sh /usr/local/bin/ && \
    mv /support/scripts/installPackages.R /usr/local/bin/ && \
    mv /support/scripts/setup.sh /usr/local/bin/ && \
    mv /support/scripts/create_mysql_users.sh /usr/local/bin/ && \
    mv /support/conf/apache_default.conf /etc/apache2/sites-available/000-default.conf && \
    mv /support/scripts/start-apache2.sh /usr/local/bin/start-apache2.sh && \
    mv /support/scripts/start-mysqld.sh /usr/local/bin/start-mysqld.sh && \
    mv /support/conf/supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf && \
    mv /support/conf/supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf && \
    mv /support/conf/supervisord-beanstalkd.conf /etc/supervisor/conf.d/supervisord-beanstalkd.conf && \
    mv /support/conf/supervisord-worker.conf /etc/supervisor/conf.d/supervisord-worker.conf && \
    mv /support/conf/supervisord-cloud.conf /etc/supervisor/supervisord-cloud.conf.disabled && \
    mv /support/conf/supervisord.conf /etc/supervisor/supervisord.conf && \
    mv /support/conf/mysqld_innodb.cnf /etc/mysql/conf.d/mysqld_innodb.cnf && \
    mv /support/databases /databases && \
    mv /support/oncoreport /scripts && \
    mv /support/html_source /html_source && \
    mv /support/ws.tgz /ws.tgz && \
    chmod 755 /usr/local/bin/*.sh && \
    rm -rf /support && \
    /usr/bin/Rscript /usr/local/bin/installPackages.R && \
    apt remove -y r-base-dev libssl-dev libxml2-dev libcurl4-openssl-dev libyaml-dev libfontconfig1-dev unixodbc-dev && \
    apt remove -y software-properties-common && \
    apt autoclean && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/local/bin/bootstrap.sh /bootstrap.sh

# Complete the setup
RUN --mount=type=secret,id=drugbank /usr/local/bin/setup.sh

EXPOSE 80
VOLUME  [ "/oncoreport/ws" ]

CMD ["/bootstrap.sh"]
