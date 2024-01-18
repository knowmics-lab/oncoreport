FROM ubuntu:jammy as stage1_base
ARG DEBIAN_FRONTEND="noninteractive"
ARG CONTAINER_TIMEZONE="GMT"
ENV LANG en_US.UTF-8 
ENV LC_ALL en_US.UTF-8
RUN ln -snf /usr/share/zoneinfo/${CONTAINER_TIMEZONE} /etc/localtime && \
    echo ${CONTAINER_TIMEZONE} > /etc/timezone && \
    apt update --fix-missing && \
    apt install -y perl dialog software-properties-common wget locales && \
    locale-gen "${LC_ALL}" && \
    wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc && \
    add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/" && \
    add-apt-repository ppa:c2d4u.team/c2d4u4.0+ && \
    apt update && \
    apt dist-upgrade -y && \
    apt install -y wget unzip pv git curl tar unixodbc grep cmake apt-utils nano jq pwgen \
                   zip pigz libpcre16-3 libpcre2-16-0 libpcre2-32-0 libpcre2-posix3 \
                   libpcre32-3 libpcrecpp0v5 r-base r-cran-data.table r-cran-tidyr \
                   r-cran-dplyr r-cran-readr r-cran-rvest r-cran-readxl r-cran-fuzzyjoin \
                   r-cran-webchem r-cran-dbparser r-cran-googlelanguager r-cran-r.utils \
                   r-cran-ontologyindex python3-pip python3-setuptools python3 && \
    apt remove -y software-properties-common && \
    apt autoremove --purge -y && \
    apt autoclean && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

FROM stage1_base as stage2_base
ARG TRIM_GALORE_VERSION="0.6.10"
ARG GATK_VERSION="4.4.0.0"
ARG PICARD_VERSION="3.1.1"
ARG PANDOC_VERSION="3.1.9"
ARG VARSCAN_VERSION="2.4.6"
ARG SUPERVISOR_VERSION="4.2.5"
ARG ARCHITECTURE="amd64"
ENV DOCKER_USER_ID 501
ENV DOCKER_USER_GID 20
ENV BOOT2DOCKER_ID 1000
ENV BOOT2DOCKER_GID 50
ENV DEBUG false
ENV JAVA_HOME /usr/lib/jvm/java-17-openjdk-${ARCHITECTURE}/
ENV DEBIAN_FRONTEND noninteractive

RUN usermod -u ${BOOT2DOCKER_ID} www-data && \
    usermod -G staff www-data && \
    useradd -r mysql && \
    usermod -G staff mysql && \
    groupmod -g $(($BOOT2DOCKER_GID + 10000)) $(getent group $BOOT2DOCKER_GID | cut -d: -f1) && \
    groupmod -g ${BOOT2DOCKER_GID} staff && \
    apt update --fix-missing && \
    apt install -y software-properties-common &&  \
    add-apt-repository ppa:ondrej/php -y && \
    apt update && \
    apt dist-upgrade -y && \
    apt install -y init bwa samtools bedtools tabix bcftools openjdk-17-jdk \
                   ant r-base rename beanstalkd apache2 php-xdebug \
                   composer php-cli libapache2-mod-php mysql-server php-mysql \
                   php-apcu php-gd php-xml php-mbstring php-zip php-curl php-intl \
                   ca-certificates-java r-cran-shiny r-cran-rmarkdown \
                   r-cran-kableextra r-cran-rcurl r-cran-stringr r-cran-xml2 \
                   r-cran-knitr r-cran-devtools r-cran-optparse r-bioc-iranges \
                   r-cran-brew r-cran-vcfr r-cran-dt libgsl27 && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    update-java-alternatives -s "java-1.17.0-openjdk-${ARCHITECTURE}" && \
    update-ca-certificates -f && \
    curl -L https://pypi.io/packages/source/s/supervisor/supervisor-${SUPERVISOR_VERSION}.tar.gz | tar xvz && \
    cd supervisor-${SUPERVISOR_VERSION}/ && \
    python3 setup.py install && \
    mkdir -p /oncoreport/tmp/ && PW=$(pwd) && cd /oncoreport/tmp/ && \
    git clone https://github.com/linsalrob/fastq-pair.git && \
    cd fastq-pair/ && mkdir build && cd build && cmake .. && make && make install && \
    apt install -y libtool libgsl-dev libhts-dev && cd /oncoreport/tmp/ && \
    git clone https://github.com/CSB5/lofreq.git && cd lofreq && ./bootstrap && ./configure && make && make install && \
    pip3 install cutadapt && \
    pip3 install pysam && \
    curl -fsSL "https://github.com/FelixKrueger/TrimGalore/archive/$TRIM_GALORE_VERSION.tar.gz" -o trim_galore.tar.gz && \
    tar -zxvf trim_galore.tar.gz && \
    cp "TrimGalore-$TRIM_GALORE_VERSION/trim_galore" /usr/local/bin/ && \
    wget "https://github.com/broadinstitute/gatk/releases/download/$GATK_VERSION/gatk-$GATK_VERSION.zip" && \
    unzip "gatk-$GATK_VERSION.zip" && \
    [ -d "gatk-$GATK_VERSION/" ] && mv "gatk-$GATK_VERSION/gatk-package-$GATK_VERSION-local.jar" "/usr/local/bin/gatk-package-local.jar" && \
    wget "https://github.com/broadinstitute/picard/releases/download/$PICARD_VERSION/picard.jar" && \
    mv picard.jar /usr/local/bin/ && \
    apt remove -y pandoc && \
    curl -fsSL "https://github.com/jgm/pandoc/releases/download/$PANDOC_VERSION/pandoc-${PANDOC_VERSION}-1-${ARCHITECTURE}.deb" -o pandoc.deb && \
    dpkg -i pandoc.deb && \
    wget "https://github.com/dkoboldt/varscan/raw/master/VarScan.v${VARSCAN_VERSION}.jar" && \
    mv "VarScan.v${VARSCAN_VERSION}.jar" /usr/local/bin/varscan.jar && \
    chmod +x /usr/local/bin/varscan.jar && \
    cd "$PW" && rm -r /oncoreport/tmp/ && apt remove -y libgsl-dev libtool libhts-dev && \
    a2enmod rewrite && \
    rm -rf /var/log/mysql && rm -rf /var/lib/mysql && \
    apt remove -y software-properties-common && \
    apt autoremove --purge -y && \
    apt autoclean && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/bin/python3 /usr/bin/python

FROM stage1_base as stage1_support
ARG BASE_PATH="/support"
ARG ONCOREPORT_ORIGIN="https://github.com/knowmics-lab/oncoreport.git"
ARG ONCOREPORT_BRANCH="master"
COPY . ${BASE_PATH}
RUN --mount=type=secret,id=drugbank --mount=type=secret,id=gltranslate bash ${BASE_PATH}/scripts/prepare.sh

FROM stage2_base as oncoreport_final
ARG BASE_PATH="/support"
ENV ONCO_BASE "/oncoreport"
COPY . ${BASE_PATH}

RUN mkdir -p "${ONCO_BASE}" && mkdir -p "/etc/supervisor/conf.d/" && \
    mv "${BASE_PATH}/scripts/bootstrap.sh" /usr/local/bin/ && \
    mv "${BASE_PATH}/scripts/setup.sh" /usr/local/bin/ && \
    mv "${BASE_PATH}/scripts/create_mysql_users.sh" /usr/local/bin/ && \
    mv "${BASE_PATH}/conf/apache_default.conf" /etc/apache2/sites-available/000-default.conf && \
    mv "${BASE_PATH}/scripts/start-apache2.sh" /usr/local/bin/start-apache2.sh && \
    mv "${BASE_PATH}/scripts/start-mysqld.sh" /usr/local/bin/start-mysqld.sh && \
    mv "${BASE_PATH}/conf/supervisord-apache2.conf" /etc/supervisor/conf.d/supervisord-apache2.conf && \
    mv "${BASE_PATH}/conf/supervisord-mysqld.conf" /etc/supervisor/conf.d/supervisord-mysqld.conf && \
    mv "${BASE_PATH}/conf/supervisord-beanstalkd.conf" /etc/supervisor/conf.d/supervisord-beanstalkd.conf && \
    mv "${BASE_PATH}/conf/supervisord-worker.conf" /etc/supervisor/conf.d/supervisord-worker.conf && \
    mv "${BASE_PATH}/conf/supervisord-cloud.conf" /etc/supervisor/supervisord-cloud.conf.disabled && \
    mv "${BASE_PATH}/conf/supervisord.conf" /etc/supervisor/supervisord.conf && \
    mv "${BASE_PATH}/conf/mysqld_innodb.cnf" /etc/mysql/conf.d/mysqld_innodb.cnf && \
    mv "${BASE_PATH}/databases" "${ONCO_BASE}/databases" && \
    mv "${BASE_PATH}/oncoreport" "${ONCO_BASE}/scripts" && \
    mv "${BASE_PATH}/html_source" "${ONCO_BASE}/html_source" && \
    mv "${BASE_PATH}/ws.tgz" /ws.tgz && \
    chmod 755 /usr/local/bin/*.sh && \
    rm -rf "${BASE_PATH}" && \
    ln -s /usr/local/bin/bootstrap.sh /bootstrap.sh && \
    bash /usr/local/bin/setup.sh && \
    rm -rf /usr/local/bin/setup.sh

EXPOSE 80
VOLUME [ "${ONCO_BASE}/ws/storage" ]

CMD ["/bootstrap.sh"]

#libssl-dev libxml2-dev libcurl4-openssl-dev libyaml-dev libfontconfig1-dev unixodbc-dev
#Rscript /installPackages.R "stage2" && 
#apt remove -y r-base-dev libssl-dev libxml2-dev libcurl4-openssl-dev libyaml-dev libfontconfig1-dev unixodbc-dev && \