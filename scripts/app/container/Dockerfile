FROM ubuntu:focal
ENV DOCKER_USER_ID 501
ENV DOCKER_USER_GID 20
ENV BOOT2DOCKER_ID 1000
ENV BOOT2DOCKER_GID 50
ENV SUPERVISOR_VERSION 4.2.0
ENV DEBUG false
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

# Tweaks to give Apache/PHP write permissions to the app
RUN usermod -u ${BOOT2DOCKER_ID} www-data && \
    usermod -G staff www-data && \
    useradd -r mysql && \
    usermod -G staff mysql && \
    groupmod -g $(($BOOT2DOCKER_GID + 10000)) $(getent group $BOOT2DOCKER_GID | cut -d: -f1) && \
    groupmod -g ${BOOT2DOCKER_GID} staff

ENV DEBIAN_FRONTEND noninteractive

# Setup repositories
RUN /usr/bin/apt update --fix-missing && \
    /usr/bin/apt install -y perl dialog software-properties-common &&  \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 51716619E084DAB9 && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/' &&  \
    add-apt-repository ppa:ondrej/php -y && \
    /usr/bin/apt update && \
    /usr/bin/apt install -y init && \
    /usr/bin/apt dist-upgrade -y && \
    apt-get clean

# Install common packages
RUN /usr/bin/apt update --fix-missing && \
    /usr/bin/apt install -y wget unzip bowtie2 perl python3-pip curl tar samtools bedtools unixodbc \
                            openjdk-8-jdk ant r-base-dev libssl-dev libxml2-dev grep tzdata \
                            libcurl4-openssl-dev rename apt-utils nano libyaml-dev beanstalkd \
                            python3-setuptools git apache2 php-xdebug composer php-cli jq \
                            libapache2-mod-php mysql-server php-mysql pwgen php-apcu php-gd libfontconfig1-dev \
                            php-xml php-mbstring zip php-zip php-curl php-intl pigz unixodbc-dev && \
    apt autoremove -y && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    update-java-alternatives -s "java-1.8.0-openjdk-amd64"

# Fix certificate issues
RUN apt-get update && \
    apt-get install ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f;

# Install supervisor 4
RUN curl -L https://pypi.io/packages/source/s/supervisor/supervisor-${SUPERVISOR_VERSION}.tar.gz | tar xvz && \
    cd supervisor-${SUPERVISOR_VERSION}/ && \
    python3 setup.py install

# Enable mod_rewrite in apache
RUN a2enmod rewrite

# Fix JAVA_HOME issue
RUN export JAVA_HOME

# Remove pre-installed database
RUN rm -rf /var/log/mysql && rm -rf /var/lib/mysql

# Add all support files
ADD scripts/bootstrap.sh                            /usr/local/bin/
ADD scripts/installPackages.R                       /usr/local/bin/
ADD scripts/setup.sh                                /usr/local/bin/
ADD scripts/create_mysql_users.sh                   /usr/local/bin/
ADD conf/apache_default.conf                        /etc/apache2/sites-available/000-default.conf
ADD scripts/start-apache2.sh                        /usr/local/bin/start-apache2.sh
ADD scripts/start-mysqld.sh                         /usr/local/bin/start-mysqld.sh
ADD conf/supervisord-apache2.conf                   /etc/supervisor/conf.d/supervisord-apache2.conf
ADD conf/supervisord-mysqld.conf                    /etc/supervisor/conf.d/supervisord-mysqld.conf
ADD conf/supervisord-beanstalkd.conf                /etc/supervisor/conf.d/supervisord-beanstalkd.conf
ADD conf/supervisord-worker.conf                    /etc/supervisor/conf.d/supervisord-worker.conf
ADD conf/supervisord-cloud.conf                     /etc/supervisor/supervisord-cloud.conf.disabled
ADD conf/supervisord.conf                           /etc/supervisor/supervisord.conf
ADD conf/mysqld_innodb.cnf                          /etc/mysql/conf.d/mysqld_innodb.cnf
ADD databases                                       /databases
ADD oncoreport                                      /scripts
ADD html_source                                     /html_source
COPY ws.tgz                                         /ws.tgz

RUN chmod 755 /usr/local/bin/*.sh

# Install R packages
RUN /usr/bin/Rscript /usr/local/bin/installPackages.R

# Complete the setup
RUN --mount=type=secret,id=drugbank /usr/local/bin/setup.sh

RUN ln -s /usr/local/bin/bootstrap.sh /bootstrap.sh

RUN /usr/bin/apt autoclean && \
    /usr/bin/apt clean && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 80
VOLUME  [ "/oncoreport/ws" ]

CMD ["/bootstrap.sh"]
