FROM ubuntu:focal

ENV DOCKER_USER_ID 501 
ENV DOCKER_USER_GID 20

ENV BOOT2DOCKER_ID 1000
ENV BOOT2DOCKER_GID 50

ENV SUPERVISOR_VERSION 4.2.0

ENV DEBUG true

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
RUN /usr/bin/apt install -y wget unzip bowtie2 perl python3-pip curl tar samtools bedtools \
                            openjdk-8-jdk ant r-base-dev libssl-dev libxml2-dev grep tzdata \
                            libcurl4-openssl-dev rename apt-utils nano libyaml-dev \
                            python3-setuptools git apache2 php-xdebug composer php-cli \
                            libapache2-mod-php mysql-server php-mysql pwgen php-apcu php-gd \
                            php-xml php-mbstring zip php-zip php-curl php-intl && \
    apt autoremove -y && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf

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
ADD conf/apache_default                             /etc/apache2/sites-available/000-default.conf
ADD scripts/start-apache2.sh                        /usr/local/bin/start-apache2.sh
ADD scripts/start-mysqld.sh                         /usr/local/bin/start-mysqld.sh
ADD conf/supervisord-apache2.conf                   /etc/supervisor/conf.d/supervisord-apache2.conf
ADD conf/supervisord-mysqld.conf                    /etc/supervisor/conf.d/supervisord-mysqld.conf
ADD conf/supervisord.conf                           /etc/supervisor/supervisord.conf
ADD conf/mysqld_innodb.cnf                          /etc/mysql/conf.d/mysqld_innodb.cnf
# ADD conf/supervisord-worker.conf                    /etc/supervisor/conf.d/supervisord-worker.conf # Enable for production
ADD databases/Disease.txt                           /Disease.txt
ADD databases/disease_list.txt                      /disease_list.txt
ADD databases/Drug_food.txt                         /Drug_food.txt
ADD databases/hg19/pharm_database_hg19.txt          /pharm_database_hg19.txt
ADD databases/hg19/cgi_original_hg19.txt            /cgi_original_hg19.txt
ADD databases/hg38/pharm_database_hg38.txt          /pharm_database_hg38.txt
ADD databases/hg38/cgi_original_hg38.txt            /cgi_original_hg38.txt
ADD oncoreport/PrepareDatabases.R                   /PrepareDatabases.R
ADD oncoreport/MergeInfo.R                          /MergeInfo.R
ADD oncoreport/imports.R                            /imports.R
ADD oncoreport/Functions.R                          /Functions.R
ADD oncoreport/CreateReport.Rmd                     /CreateReport.Rmd
ADD oncoreport/pipeline_tumVSnormal.bash            /pipeline_tumVSnormal.bash
ADD oncoreport/pipeline_liquid_biopsy.bash          /pipeline_liquid_biopsy.bash
ADD oncoreport/setup_databases.bash                 /setup_databases.bash
ADD oncoreport/ProcessVariantTable.R                /ProcessVariantTable.R
ADD oncoreport/CreateCivicBed.R                     /CreateCivicBed.R
#ADD repo.tar.gz         /repo.tar.gz # Enable for production
#COPY genkey.sh           /genkey.sh # TODO
#COPY import_reference.sh /import_reference.sh # TODO

RUN chmod 755 /usr/local/bin/*.sh

# Install R packages
RUN /usr/bin/Rscript /usr/local/bin/installPackages.R

# Complete the setup
RUN /bin/bash /usr/local/bin/setup.sh

RUN ln -s /usr/local/bin/bootstrap.sh /bootstrap.sh

RUN /usr/bin/apt autoclean && \
    /usr/bin/apt clean && \
    rm -rf /var/lib/apt/lists/*

#Disable 3306 for production
EXPOSE 80 3306
VOLUME  [ "/oncoreport/ws" ]

CMD ["/bootstrap.sh"]
