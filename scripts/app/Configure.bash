#!/bin/bash

sudo apt-get update --fix-missing
sudo apt-get -y install wget
sudo apt-get -y install unzip
sudo apt-get -y install bowtie2
sudo apt-get -y install perl
sudo apt-get update --fix-missing
sudo apt-get -y install python3-pip
sudo pip3 install --user --upgrade cutadapt
sudo apt-get -y install curl
sudo apt-get -y install tar
sudo apt-get -y install samtools
sudo apt-get -y install bedtools
sudo curl -fsSL https://github.com/FelixKrueger/TrimGalore/archive/0.6.0.tar.gz -o trim_galore.tar.gz
tar xvzf trim_galore.tar.gz
sudo apt-get -y install software-properties-common

# Install OpenJDK
sudo apt-get update && \
    sudo apt-get install -y openjdk-8-jdk && \
    sudo apt-get install -y ant && \
    sudo apt-get clean;

# Fix certificate issues
sudo apt-get update && \
    sudo apt-get install ca-certificates-java && \
    sudo apt-get clean && \
    sudo update-ca-certificates -f;

# Setup JAVA_HOME -- useful for docker commandline
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
export JAVA_HOME

wget https://github.com/broadinstitute/gatk/releases/download/4.1.0.0/gatk-4.1.0.0.zip
unzip tools/gatk-4.1.0.0.zip
wget https://github.com/broadinstitute/picard/releases/download/2.21.1/picard.jar
sudo apt-get -y install grep
wget http://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz

sudo apt install -y tzdata
sudo apt-get -y install r-base
sudo apt-get -y install pandoc
sudo apt-get -y install libxml2-dev
sudo apt-get -y install libcurl4-openssl-dev
sudo apt-get -y install libssl-dev
sudo R -e "install.packages('shiny', repos='http://cran.rstudio.com/')"
sudo R -e "install.packages('rmarkdown', repos='http://cran.rstudio.com/')"
sudo R -e "install.packages('kableExtra', repos='http://cran.rstudio.com/')"
sudo R -e "install.packages('dplyr', repos='http://cran.rstudio.com/')"
sudo R -e "install.packages('filesstrings', repos='http://cran.rstudio.com/')"
sudo R -e "install.packages('data.table', repos='http://cran.rstudio.com/')"
sudo R -e "install.packages('RCurl', repos='http://cran.rstudio.com/')"
sudo R -e "install.packages('stringr', repos='http://cran.rstudio.com/')"
sudo pip3 install cython
sudo pip3 install CrossMap
sudo pip3 install CrossMap --upgrade
sudo apt-get install rename
sudo apt-get update --fix-missing
sudo apt-get -y install nano
sudo apt-get -y install apt-utils --fix-missing
