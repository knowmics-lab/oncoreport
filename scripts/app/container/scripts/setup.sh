#!/usr/bin/env bash

# Create Web Service Directory
mkdir -p /oncoreport/tmp || exit 100
mv /databases /oncoreport/databases || exit 101
mv /scripts /oncoreport/scripts || exit 102
mv /html_source /oncoreport/html_source || exit 102

(
  cd /oncoreport &&
    tar -zxvf /ws.tgz &&
    rm /ws.tgz &&
    rm -fr /var/www/html &&
    ln -s /oncoreport/ws/public /var/www/html &&
    ln -s /oncoreport/scripts/genkey.sh /genkey.sh
) || exit 103

# # Install other software
# pip3 install cutadapt || exit 104

# # Install trim_galore
# (
#   cd /oncoreport/tmp/ &&
#     curl -fsSL "https://github.com/FelixKrueger/TrimGalore/archive/$TRIM_GALORE_VERSION.tar.gz" -o trim_galore.tar.gz &&
#     tar -zxvf trim_galore.tar.gz &&
#     cp "TrimGalore-$TRIM_GALORE_VERSION/trim_galore" /usr/local/bin/
# ) || exit 105

# # Install gatk
# (
#   cd /oncoreport/tmp/ &&
#     wget "https://github.com/broadinstitute/gatk/releases/download/$GATK_VERSION/gatk-$GATK_VERSION.zip" &&
#     unzip "gatk-$GATK_VERSION.zip" &&
#     [ -d "gatk-$GATK_VERSION/" ] &&
#     mv "gatk-$GATK_VERSION/gatk-package-$GATK_VERSION-local.jar" "/usr/local/bin/gatk-package-local.jar"
# ) || exit 106

# # Install picard
# (
#   cd /oncoreport/tmp/ &&
#     wget "https://github.com/broadinstitute/picard/releases/download/$PICARD_VERSION/picard.jar" &&
#     mv picard.jar /usr/local/bin/
# ) || exit 107

# # Removes pandoc 1 and install pandoc 2
# apt remove -y pandoc
# (
#   cd /oncoreport/tmp/ &&
#     curl -fsSL "https://github.com/jgm/pandoc/releases/download/$PANDOC_VERSION/pandoc-$PANDOC_VERSION-1-amd64.deb" -o pandoc.deb &&
#     dpkg -i pandoc.deb
# ) || exit 108

# (
#   cd /oncoreport/tmp/ &&
#     wget "https://github.com/dkoboldt/varscan/raw/master/VarScan.v${VARSCAN_VERSION}.jar" &&
#     mv "VarScan.v${VARSCAN_VERSION}.jar" /usr/local/bin/varscan.jar &&
#     chmod +x /usr/local/bin/varscan.jar
# ) || exit 140

# # Install cython and Crossmap
# pip3 install cython || exit 109
# pip3 install CrossMap || exit 110
# pip3 install CrossMap --upgrade || exit 111

# # Download the latest version of the hg19 to hg38 chain file
# CHAIN_VERSION="$(curl http://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/ 2>/dev/null |
#   grep 'hg19ToHg38.over.chain.gz' | awk -F' ' '{FF=NF-2; print $FF}')"
# echo -e "hg19 To hg38 Chain\t$CHAIN_VERSION\t$(date +%Y-%m-%d)" >>"/oncoreport/databases/versions.txt"
# cd /oncoreport/tmp/ || exit 99
# (
#   wget http://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz &&
#     [ -f hg19ToHg38.over.chain.gz ] &&
#     mv hg19ToHg38.over.chain.gz /oncoreport/databases
# ) || exit 112

# # Download nightly update of the CIVIC database
# echo -e "CIVIC\t$(date +%Y%m%d)\t$(date +%Y-%m-%d)" >>"/oncoreport/databases/versions.txt"
# (
#   wget https://civicdb.org/downloads/nightly/nightly-ClinicalEvidenceSummaries.tsv &&
#     [ -f nightly-ClinicalEvidenceSummaries.tsv ] &&
#     mv nightly-ClinicalEvidenceSummaries.tsv /oncoreport/databases/civic.txt
# ) || exit 113

# # Download the latest version of the ClinVar database for hg38 and hg19
# CLINVAR_VERSION="$(curl ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh38/ 2>/dev/null |
#   grep 'clinvar.vcf.gz' | head -n 1 | awk -F'->' '{print $2}' | cut -d'_' -f2 | cut -d'.' -f1)"
# echo -e "ClinVar\t$CLINVAR_VERSION\t$(date +%Y-%m-%d)" >>"/oncoreport/databases/versions.txt"

# (
#   wget "https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh38/clinvar.vcf.gz" &&
#     [ -f "clinvar.vcf.gz" ] &&
#     gunzip "clinvar.vcf.gz" &&
#     [ -f "clinvar.vcf" ] &&
#     mv "clinvar.vcf" /oncoreport/databases/clinvar_hg38.vcf
# ) || exit 114

# (
#   wget "https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/clinvar.vcf.gz" &&
#     [ -f "clinvar.vcf.gz" ] &&
#     gunzip "clinvar.vcf.gz" &&
#     [ -f "clinvar.vcf" ] &&
#     mv "clinvar.vcf" /oncoreport/databases/clinvar_hg19.vcf
# ) || exit 116

# # Download the latest version of the NCBI RefSeq database for hg38 and hg19
# HG38_DATE="$(curl http://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/ 2>/dev/null |
#   grep 'ncbiRefSeq.txt.gz' | awk -F' ' '{FF=NF-2; print $FF}')"
# HG19_DATE="$(curl http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/ 2>/dev/null |
#   grep 'ncbiRefSeq.txt.gz' | awk -F' ' '{FF=NF-2; print $FF}')"
# echo -e "NCBI RefSeq hg38\t$HG38_DATE\t$(date +%Y-%m-%d)" >>"/oncoreport/databases/versions.txt"
# echo -e "NCBI RefSeq hg19\t$HG19_DATE\t$(date +%Y-%m-%d)" >>"/oncoreport/databases/versions.txt"

# (
#   wget http://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/ncbiRefSeq.txt.gz &&
#     [ -f ncbiRefSeq.txt.gz ] &&
#     gunzip ncbiRefSeq.txt.gz &&
#     [ -f ncbiRefSeq.txt ] &&
#     mv ncbiRefSeq.txt /oncoreport/databases/ncbiRefSeq_hg38.txt
# ) || exit 115

# (
#   wget http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/ncbiRefSeq.txt.gz &&
#     [ -f ncbiRefSeq.txt.gz ] &&
#     gunzip ncbiRefSeq.txt.gz &&
#     [ -f ncbiRefSeq.txt ] &&
#     mv ncbiRefSeq.txt /oncoreport/databases/ncbiRefSeq_hg19.txt
# ) || exit 117

# # Download drugbank.xml file
# DRUGBANK_VERSION="$(curl https://go.drugbank.com/releases/latest/release_notes 2>/dev/null |
#   grep 'DrugBank Release Notes &mdash;' | sed 's/<[^>]*>/ /g' | awk -F'&mdash;' '{print $2}' |
#   sed -e 's/^[[:space:]]*//' | cut -d' ' -f1)"
# echo -e "DrugBank\t$DRUGBANK_VERSION\t$(date +%Y-%m-%d)" >>"/oncoreport/databases/versions.txt"

# DRUGBANK_USERNAME="$(head -n 1 /run/secrets/drugbank)"
# DRUGBANK_PASSWORD="$(tail -n 1 /run/secrets/drugbank)"
# (
#   cd /oncoreport/tmp/ &&
#     curl -Lf -o drugbank.zip -u "$DRUGBANK_USERNAME:$DRUGBANK_PASSWORD" https://go.drugbank.com/releases/latest/downloads/all-full-database &&
#     unzip drugbank.zip &&
#     mv "full database.xml" /oncoreport/databases/drugbank.xml &&
#     rm drugbank.zip
# ) || exit 134
# [[ ! -f /oncoreport/databases/drugbank.xml ]] && echo "Unable to download drugbank.xml" && exit 134

# Build database files
(
  cd /oncoreport/databases &&
    Rscript /oncoreport/scripts/get_drug.R /oncoreport/databases &&
    Rscript /oncoreport/scripts/CreateCivicBed.R /oncoreport/databases &&
    CrossMap.py bed /oncoreport/databases/hg19ToHg38.over.chain.gz /oncoreport/databases/civic_bed.bed /oncoreport/databases/civic_bed_hg38.bed &&
    Rscript /oncoreport/scripts/PrepareDatabases_build.R /oncoreport/databases hg19 &&
    Rscript /oncoreport/scripts/PrepareDatabases_build.R /oncoreport/databases hg38 &&
    Rscript /oncoreport/scripts/doi_parser.R -c /oncoreport/databases/civic.txt -g /oncoreport/databases/cgi_database_hg19.txt -d /oncoreport/databases/diseases_map.txt -o /oncoreport/databases/Disease.txt -p /oncoreport/databases/do_parents.tsv &&
    rm /oncoreport/databases/drugbank.xml
) || exit 138

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

# Remove temporary directory
rm -rf /oncoreport/tmp

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
