#!/usr/bin/env bash

# Create Web Service Directory
mkdir -p /oncoreport/tmp || exit 100
mkdir /oncoreport/databases || exit 101
mkdir /oncoreport/scripts || exit 102
mkdir /oncoreport/ws || exit 103

# Extract web servide TODO
rm -fr /var/www/html && ln -s /oncoreport/ws/public /var/www/html

# Install other softwares
pip3 install --user --upgrade cutadapt || exit 104

# Install trim_galore
(
    cd /oncoreport/tmp/ && \
    curl -fsSL https://github.com/FelixKrueger/TrimGalore/archive/0.6.5.tar.gz -o trim_galore.tar.gz && \
    tar -zxvf trim_galore.tar.gz && \
    cp TrimGalore-0.6.5/trim_galore /usr/local/bin/
) || exit 105

# Install gatk
(
    cd /oncoreport/tmp/ && \
    wget https://github.com/broadinstitute/gatk/releases/download/4.1.0.0/gatk-4.1.0.0.zip && \
    unzip gatk-4.1.0.0.zip && \
    [ -d gatk-4.1.0.0/ ] && \
    mv gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar /usr/local/bin/
) || exit 106

# Install picard
(
    cd /oncoreport/tmp/ && \
    wget https://github.com/broadinstitute/picard/releases/download/2.21.1/picard.jar && \
    mv picard.jar /usr/local/bin/
) || exit 107

# Removes pandoc 1 and install pandoc 2
apt remove -y pandoc 
(
    cd /oncoreport/tmp/ && \
    curl -fsSL https://github.com/jgm/pandoc/releases/download/2.11.0.4/pandoc-2.11.0.4-1-amd64.deb -o pandoc.deb && \
    dpkg -i pandoc.deb
) || exit 108

# Install cython and Crossmap
pip3 install cython || exit 109
pip3 install CrossMap || exit 110
pip3 install CrossMap --upgrade  || exit 111

# Copy databases
cd /oncoreport/tmp/
(
    wget http://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz && \
    [ -f hg19ToHg38.over.chain.gz ] && \
    mv hg19ToHg38.over.chain.gz /oncoreport/databases
) || exit 112

(
    wget https://civicdb.org/downloads/nightly/nightly-ClinicalEvidenceSummaries.tsv && \
    [ -f nightly-ClinicalEvidenceSummaries.tsv ] && \
    mv nightly-ClinicalEvidenceSummaries.tsv /oncoreport/databases/civic.txt
) || exit 113

(
    wget ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh38/archive_2.0/2020/clinvar_20200327.vcf.gz && \
    [ -f clinvar_20200327.vcf.gz ] && \
    gunzip clinvar_20200327.vcf.gz && \
    [ -f clinvar_20200327.vcf ] && \
    mv clinvar_20200327.vcf /oncoreport/databases/clinvar_hg38.vcf
) || exit 114

(
    wget http://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/ncbiRefSeq.txt.gz && \
    [ -f ncbiRefSeq.txt.gz ] && \
    gunzip ncbiRefSeq.txt.gz && \
    [ -f ncbiRefSeq.txt ] && \
    mv ncbiRefSeq.txt /oncoreport/databases/ncbiRefSeq_hg38.txt
) || exit 115

(
    wget ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/archive_2.0/2020/clinvar_20200327.vcf.gz && \
    [ -f clinvar_20200327.vcf.gz ] && \
    gunzip clinvar_20200327.vcf.gz && \
    [ -f clinvar_20200327.vcf ] && \
    mv clinvar_20200327.vcf /oncoreport/databases/clinvar_hg19.vcf
) || exit 116

(
    wget http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/ncbiRefSeq.txt.gz && \
    [ -f ncbiRefSeq.txt.gz ] && \
    gunzip ncbiRefSeq.txt.gz && \
    [ -f ncbiRefSeq.txt ] && \
    mv ncbiRefSeq.txt /oncoreport/databases/ncbiRefSeq_hg19.txt
) || exit 117

mv /Disease.txt /oncoreport/databases/ || exit 118
mv /disease_list.txt /oncoreport/databases/ || exit 119
mv /Drug_food.txt /oncoreport/databases/ || exit 120
mv /pharm_database_hg19.txt /oncoreport/databases/ || exit 121
mv /cgi_original_hg19.txt /oncoreport/databases/ || exit 122
mv /pharm_database_hg38.txt /oncoreport/databases/ || exit 123
mv /cgi_original_hg38.txt /oncoreport/databases/ || exit 124

# Copy scripts
mv /PrepareDatabases.R /oncoreport/scripts || exit 125
mv /MergeInfo.R /oncoreport/scripts || exit 126
mv /imports.R /oncoreport/scripts || exit 127
mv /Functions.R /oncoreport/scripts || exit 128
mv /CreateReport.Rmd /oncoreport/scripts || exit 129
mv /pipeline_tumVSnormal.bash /oncoreport/scripts || exit 130
mv /pipeline_liquid_biopsy.bash /oncoreport/scripts || exit 131
mv /setup_databases.bash /oncoreport/scripts || exit 132
mv /ProcessVariantTable.R /oncoreport/scripts || exit 133
mv /CreateCivicBed.R /oncoreport/scripts || exit 134

# Apply MYSQL configuration fixes
apply_configuration_fixes() {
    sed 's/^log_error/# log_error/' -i /etc/mysql/mysql.conf.d/mysqld.cnf
    sed 's/^datadir\(.*\)=.*/datadir = \/oncoreport\/ws\/storage\/app\/database/' -i /etc/mysql/mysql.conf.d/mysqld.cnf
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
# cd /oncoreport/ws/ || exit 100
# mv .env.docker .env
# composer install --optimize-autoloader --no-dev
# php artisan key:generate
# php artisan storage:link

# Remove temporary directory
rm -rf /oncoreport/tmp

# Apply PHP configuration fixes
sed -i 's/post_max_size \= .M/post_max_size \= 200G/g' /etc/php/*/fpm/php.ini
sed -i 's/upload_max_filesize \= .M/upload_max_filesize \= 200G/g' /etc/php/*/fpm/php.ini

# Redirect NGINX and PHP log to docker stdout and stderr
if [ -f "/var/log/nginx/access.log" ]; then
    rm /var/log/nginx/access.log
fi
ln -s /dev/stdout /var/log/nginx/access.log

if [ -f "/var/log/nginx/error.log" ]; then
    rm /var/log/nginx/error.log
fi
ln -s /dev/stdout /var/log/nginx/error.log

if [ -f "/var/log/php7.3-fpm.log" ]; then
    rm /var/log/php7.3-fpm.log
fi
ln -s /dev/stdout /var/log/php7.3-fpm.log

# Set folder permission
chmod 755 /oncoreport/scripts/*
chmod 755 /oncoreport/databases/*
# chmod -R 777 /oncoreport/ws/bootstrap/cache
# chmod -R 777 /oncoreport/ws/storage
# chmod 755 /genkey.sh
# chmod 755 /import_reference.sh
chmod -R 755 /usr/local/bin/