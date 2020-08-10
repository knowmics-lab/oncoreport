FROM ubuntu
RUN apt-get update --fix-missing
RUN apt-get -y install wget
RUN apt-get -y install unzip
RUN apt-get -y install bowtie2
RUN apt-get -y install perl
RUN apt-get update --fix-missing
RUN apt-get -y install python3-pip
RUN pip3 install --user --upgrade cutadapt
RUN apt-get -y install curl
RUN apt-get -y install tar
RUN apt-get -y install samtools
RUN curl -fsSL https://github.com/FelixKrueger/TrimGalore/archive/0.6.0.tar.gz -o trim_galore.tar.gz
RUN tar xvzf trim_galore.tar.gz
RUN apt-get -y install software-properties-common
# Install OpenJDK-8
RUN apt-get update && \
    apt-get install -y openjdk-8-jdk && \
    apt-get install -y ant && \
    apt-get clean;

# Fix certificate issues
RUN apt-get update && \
    apt-get install ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f;

# Setup JAVA_HOME -- useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME
RUN wget https://github.com/broadinstitute/gatk/releases/download/4.1.0.0/gatk-4.1.0.0.zip
RUN unzip gatk-4.1.0.0.zip
RUN wget https://github.com/broadinstitute/picard/releases/download/2.21.1/picard.jar
RUN apt-get -y install grep
RUN wget http://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz
RUN DEBIAN_FRONTEND=noninteractive apt install -y tzdata
RUN apt-get -y install r-base
RUN apt-get -y install pandoc
RUN apt-get -y install libxml2-dev
RUN apt-get -y install libcurl4-openssl-dev
RUN apt-get -y install libssl-dev
RUN R -e "install.packages('shiny', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('rmarkdown', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('kableExtra', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('dplyr', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('filesstrings', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('data.table', repos='http://cran.rstudio.com/')"
RUN pip3 install cython
RUN pip3 install CrossMap
RUN pip3 install CrossMap --upgrade
RUN apt-get install rename
RUN apt-get update --fix-missing
RUN wget https://civicdb.org/downloads/nightly/nightly-ClinicalEvidenceSummaries.tsv
RUN wget ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh38/archive_2.0/2020/clinvar_20200327.vcf.gz
RUN wget http://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/ncbiRefSeq.txt.gz
RUN gunzip clinvar_20200327.vcf.gz
RUN gunzip ncbiRefSeq.txt.gz
RUN mv clinvar_* clinvar_hg38.vcf
RUN mv ncbiRefSeq* ncbiRefSeq_hg38.txt
RUN wget ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/archive_2.0/2020/clinvar_20200327.vcf.gz
RUN wget http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/ncbiRefSeq.txt.gz
RUN gunzip clinvar_20200327.vcf.gz
RUN gunzip ncbiRefSeq.txt.gz
COPY Disease.txt /
COPY disease_list.txt /
COPY Drug_food.txt /
COPY pharm_databasehg19.txt /
COPY pharm_databasehg38.txt /
COPY cgi_databasehg38.txt /
COPY cgi_databasehg19.txt /
COPY Script_prep_banche_linea_di_comando.R /
COPY database_hg38.R /
COPY civic_hg38.R /
COPY merge_database.R /
COPY report_definitivo_biospia_liquida_linea_di_comando.R /
COPY Generazione_report_definitivo_docker_bl.Rmd /
COPY report_definitivo_docker_tmVSnm.R /
COPY Generazione_report_definitivo_docker_tmVSnm.Rmd /
COPY pipeline_tumVSnormal_docker.bash /
COPY pipeline_liquid_biopsy.bash /
COPY prep_banche_dati.bash /
COPY prep_banche_dati_hg38.bash /
COPY illumina_vcf.R /
COPY report_definitivo_vcf_illumina.R /
RUN apt-get -y install nano
RUN apt-get -y install apt-utils --fix-missing
ENTRYPOINT [ "bash" ]
