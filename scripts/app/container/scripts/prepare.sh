#!/usr/bin/env bash
set -e

if [ ! -f "$BASE_PATH/ws.tgz" ]; then
    mkdir "$BASE_PATH/repo"
    cd "$BASE_PATH/repo"
    echo "Cloning $ONCOREPORT_ORIGIN"
    git clone "$ONCOREPORT_ORIGIN"
    cd "$BASE_PATH/repo/oncoreport"
    if [ -n "$ONCOREPORT_BRANCH" ]; then
        git checkout "$ONCOREPORT_BRANCH"
    fi
    echo "Building oncoreport package"
    tar -zcf "$BASE_PATH/ws.tgz" ws/
    cd "$BASE_PATH"
    rm -rf "$BASE_PATH/repo"
fi

cd "$BASE_PATH"

[[ ! -f "$BASE_PATH/ws.tgz" ]] && echo "Archive not built!" && exit 1

echo "Downloading pre-buit databases"
bash "$BASE_PATH/scripts/download_databases.sh" "$BASE_PATH/databases"

if [ ! -d "$BASE_PATH/databases/hg19" ] || [ ! -d "$BASE_PATH/databases/hg38" ]; then
    [[ -d "$BASE_PATH/databases/hg19" ]] && rm -rf "$BASE_PATH/databases/hg19"
    [[ -d "$BASE_PATH/databases/hg38" ]] && rm -rf "$BASE_PATH/databases/hg38"
    echo "Building dbNSFP database"
    bash "$BASE_PATH/scripts/build_dbnsfp.sh" "$BASE_PATH/databases"
fi

[[ ! -d "$BASE_PATH/databases/hg19/dbNSFP" ]] && echo "hg19 dbNSFP database not built!" && exit 2
[[ ! -d "$BASE_PATH/databases/hg38/dbNSFP" ]] && echo "hg38 dbNSFP database not built!" && exit 3

if [ ! -f "$BASE_PATH/databases/pharm_database_hg19.txt" ] || [ ! -d "$BASE_PATH/databases/pharm_database_hg38.txt" ]; then
    rm -rf "$BASE_PATH/databases/pharm_database_hg19.txt"
    rm -rf "$BASE_PATH/databases/pharm_database_hg38.txt"
    echo "Building PharmGKB database"
    bash "$BASE_PATH/scripts/build_pharmgkb.sh" "$BASE_PATH/databases"
fi

[[ ! -f "$BASE_PATH/databases/pharm_database_hg19.txt" ]] && echo "hg19 PharmGKB database not built!" && exit 4
[[ ! -f "$BASE_PATH/databases/pharm_database_hg38.txt" ]] && echo "hg38 PharmGKB database not built!" && exit 5

# Download drugbank.xml file
DRUGBANK_VERSION="$(curl https://go.drugbank.com/releases/latest/release_notes 2>/dev/null |
    grep 'DrugBank Release Notes &mdash;' | sed 's/<[^>]*>/ /g' | awk -F'&mdash;' '{print $2}' |
    sed -e 's/^[[:space:]]*//' | cut -d' ' -f1)"
echo -e "DrugBank\t$DRUGBANK_VERSION\t$(date +%Y-%m-%d)" >>"$BASE_PATH/databases/versions.txt"

echo "Downloading DrugBank database"
DRUGBANK_USERNAME="$(head -n 1 /run/secrets/drugbank)"
DRUGBANK_PASSWORD="$(tail -n 1 /run/secrets/drugbank)"
cd /tmp
curl -Lf -o drugbank.zip -u "$DRUGBANK_USERNAME:$DRUGBANK_PASSWORD" https://go.drugbank.com/releases/latest/downloads/all-full-database
unzip drugbank.zip
mv "full database.xml" "$BASE_PATH/databases/drugbank.xml"
rm drugbank.zip
cd $BASE_PATH
[[ ! -f "$BASE_PATH/databases/drugbank.xml" ]] && echo "Unable to download drugbank.xml" && exit 6

echo "Building Agency Approvals list"
Rscript "$BASE_PATH/scripts/process_approvals.R" "$BASE_PATH/databases/drugbank.xml" "$BASE_PATH/databases" "/run/secrets/gltranslate"

# Download the latest version of the hg19 to hg38 chain file
echo "Downloading hg19 to hg38 chain file"
CHAIN_VERSION="$(curl http://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/ 2>/dev/null |
    grep 'hg19ToHg38.over.chain.gz' | awk -F' ' '{FF=NF-2; print $FF}')"
echo -e "hg19 To hg38 Chain\t$CHAIN_VERSION\t$(date +%Y-%m-%d)" >>"$BASE_PATH/databases/versions.txt"
wget -O "$BASE_PATH/databases/hg19ToHg38.over.chain.gz" "http://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz"
[[ ! -f "$BASE_PATH/databases/hg19ToHg38.over.chain.gz" ]] && echo "Unable to download hg19ToHg38.over.chain.gz" && exit 7

# Download nightly update of the CIVIC database
echo "Downloading CIVIC database"
echo -e "CIVIC\t$(date +%Y%m%d)\t$(date +%Y-%m-%d)" >>"$BASE_PATH/databases/versions.txt"
wget -O "$BASE_PATH/databases/civic.txt" "https://civicdb.org/downloads/nightly/nightly-ClinicalEvidenceSummaries.tsv"
[[ ! -f "$BASE_PATH/databases/civic.txt" ]] && echo "Unable to download civic.txt" && exit 8

# Download the latest version of the ClinVar database for hg38 and hg19
echo "Downloading ClinVar database"
CLINVAR_VERSION="$(curl ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh38/ 2>/dev/null |
    grep 'clinvar.vcf.gz' | head -n 1 | awk -F'->' '{print $2}' | cut -d'_' -f2 | cut -d'.' -f1)"
echo -e "ClinVar\t$CLINVAR_VERSION\t$(date +%Y-%m-%d)" >>"$BASE_PATH/databases/versions.txt"
wget -O "/tmp/clinvar.vcf.gz" "ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh38/clinvar.vcf.gz"
gunzip "/tmp/clinvar.vcf.gz" && mv "/tmp/clinvar.vcf" "$BASE_PATH/databases/clinvar_hg38.vcf"
[[ ! -f "$BASE_PATH/databases/clinvar_hg38.vcf" ]] && echo "Unable to download clinvar_hg38.vcf" && exit 9

wget -O "/tmp/clinvar.vcf.gz" "ftp://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/clinvar.vcf.gz"
gunzip "/tmp/clinvar.vcf.gz" && mv "/tmp/clinvar.vcf" "$BASE_PATH/databases/clinvar_hg19.vcf"
[[ ! -f "$BASE_PATH/databases/clinvar_hg19.vcf" ]] && echo "Unable to download clinvar_hg19.vcf" && exit 10

# Download the latest version of the NCBI RefSeq database for hg38 and hg19
echo "Downloading NCBI RefSeq database"
HG38_DATE="$(curl http://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/ 2>/dev/null |
    grep 'ncbiRefSeq.txt.gz' | awk -F' ' '{FF=NF-2; print $FF}')"
HG19_DATE="$(curl http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/ 2>/dev/null |
    grep 'ncbiRefSeq.txt.gz' | awk -F' ' '{FF=NF-2; print $FF}')"
echo -e "NCBI RefSeq hg38\t$HG38_DATE\t$(date +%Y-%m-%d)" >>"$BASE_PATH/databases/versions.txt"
echo -e "NCBI RefSeq hg19\t$HG19_DATE\t$(date +%Y-%m-%d)" >>"$BASE_PATH/databases/versions.txt"
wget -O "$BASE_PATH/databases/ncbiRefSeq_hg38.txt.gz" "http://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/ncbiRefSeq.txt.gz"
gunzip "$BASE_PATH/databases/ncbiRefSeq_hg38.txt.gz"
[[ ! -f "$BASE_PATH/databases/ncbiRefSeq_hg38.txt" ]] && echo "Unable to download ncbiRefSeq_hg38.txt" && exit 11
wget -O "$BASE_PATH/databases/ncbiRefSeq_hg19.txt.gz" "http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/ncbiRefSeq.txt.gz"
gunzip "$BASE_PATH/databases/ncbiRefSeq_hg19.txt.gz"
[[ ! -f "$BASE_PATH/databases/ncbiRefSeq_hg19.txt" ]] && echo "Unable to download ncbiRefSeq_hg19.txt" && exit 12
