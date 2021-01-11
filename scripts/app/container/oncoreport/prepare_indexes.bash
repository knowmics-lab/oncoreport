#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

cleanup() {
  [ -f "$ONCOREPORT_INDEXES_PATH/hg19.zip" ] && rm "$ONCOREPORT_INDEXES_PATH/hg19.zip"
  [ -f "$ONCOREPORT_INDEXES_PATH/hg19.fa.gz" ] && rm "$ONCOREPORT_INDEXES_PATH/hg19.fa.gz"
  [ -f "$ONCOREPORT_INDEXES_PATH/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bowtie_index.tar.gz" ] && rm "$ONCOREPORT_INDEXES_PATH/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bowtie_index.tar.gz"
  [ -f "$ONCOREPORT_INDEXES_PATH/hg38.fa.gz" ] && rm "$ONCOREPORT_INDEXES_PATH/hg38.fa.gz"
}

exit_abnormal() {
  echo "$1" 1>&2
  exit "$2"
}

echo "Creating index directory"
[ ! -d "$ONCOREPORT_INDEXES_PATH" ] && mkdir -p "$ONCOREPORT_INDEXES_PATH"

OLD_PWD=$(pwd)
cd "$ONCOREPORT_INDEXES_PATH" || exit 101
cleanup
echo "Downloading hg19 bowtie index..."
wget "https://genome-idx.s3.amazonaws.com/bt/hg19.zip" -P "$ONCOREPORT_INDEXES_PATH" || exit_abnormal "Unable to download index" 102
unzip "$ONCOREPORT_INDEXES_PATH/hg19.zip" || exit_abnormal "Unable to extract index" 103
echo "Downloading hg19 sequence..."
wget "http://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz" -P "$ONCOREPORT_INDEXES_PATH" || exit_abnormal "Unable to download sequence" 104
gunzip "$ONCOREPORT_INDEXES_PATH/hg19.fa.gz" || exit_abnormal "Unable to extract sequence" 105
echo "Building hg19 sequence dictionary..."
java -jar "$PICARD_PATH" CreateSequenceDictionary REFERENCE="$ONCOREPORT_INDEXES_PATH/hg19.fa" OUTPUT="$ONCOREPORT_INDEXES_PATH/hg19.dict" || exit_abnormal "Unable to build dictionary" 106
echo "Building hg19 sequence samtools index..."
samtools faidx "$ONCOREPORT_INDEXES_PATH/hg19.fa" || exit_abnormal "Unable to build index" 107
echo "Downloading hg38 bowtie index..."
# TODO https://genome-idx.s3.amazonaws.com/bt/GRCh38_noalt_as.zip
wget "ftp://ftp.ncbi.nlm.nih.gov/genomes/archive/old_genbank/Eukaryotes/vertebrates_mammals/Homo_sapiens/GRCh38/seqs_for_alignment_pipelines/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bowtie_index.tar.gz" -P "$ONCOREPORT_INDEXES_PATH" || exit_abnormal "Unable to download index" 102
tar -zxvf "$ONCOREPORT_INDEXES_PATH/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bowtie_index.tar.gz" || exit_abnormal "Unable to extract index" 103
echo "Downloading hg38 sequence..."
wget http://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz -P "$ONCOREPORT_INDEXES_PATH" || exit_abnormal "Unable to download sequence" 104
gunzip "$ONCOREPORT_INDEXES_PATH/hg38.fa.gz" || exit_abnormal "Unable to extract sequence" 105
echo "Renaming files..."
rename -d 's/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bowtie_index/hg38/g' "$ONCOREPORT_INDEXES_PATH"/* || exit_abnormal "Unable to rename files" 108
echo "Building hg38 sequence dictionary..."
java -jar "$PICARD_PATH" CreateSequenceDictionary REFERENCE="$ONCOREPORT_INDEXES_PATH/hg38.fa" OUTPUT="$ONCOREPORT_INDEXES_PATH/hg38.dict" || exit_abnormal "Unable to build dictionary" 106
echo "Building hg38 sequence samtools index..."
samtools faidx "$ONCOREPORT_INDEXES_PATH/hg38.fa" || exit_abnormal "Unable to build index" 107
echo "Cleaning up..."
cleanup
touch "$ONCOREPORT_INDEXES_PATH/completed"
cd "$OLD_PWD" || exit 102
