#!/bin/bash
SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
CURR_DIR="$(pwd)"

OUTPUT_DIR="$1"
[[ -z "$OUTPUT_DIR" ]] && echo "Usage: $0 <output_dir>" && exit 1
DBNSFP_URL="https://dbnsfp.s3.amazonaws.com/dbNSFP4.4a.zip"
# if second argument is given, use it as the DBNSFP_URL
[[ -n "$2" ]] && DBNSFP_URL="$2"
# if third argument is given, use it as the temp directory otherwise use CURR_DIR/tmp
TEMP_DIR="$3"
[[ -z "$TEMP_DIR" ]] && TEMP_DIR="$CURR_DIR/tmp"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
wget "$DBNSFP_URL" -O dbnsfp.zip
unzip dbnsfp.zip
# extract only the columns we need
pv *.chr*.gz | zcat | cut -d$'\t' -f 3,4,8,9,40,52,56,61,64,67,72,75,138 | grep -v '^ref' |
    awk 'BEGIN{OFS=FS="\t"} {tmp=$1;$1=$3;$3=tmp;tmp=$2;$2=$4;$4=tmp;print}' >hg19.txt
pv *.chr*.gz | zcat | cut -d$'\t' -f 1,2,3,4,40,52,56,61,64,67,72,75,138 | grep -v '^#chr' >hg38.txt

# TODO: clean up columns, add header, etc.
Rscript "$SCRIPT_PATH/clean_dbnsfp.R" "$TEMP_DIR/hg19.txt" "$TEMP_DIR/hg38.txt"

mkdir -p "$TEMP_DIR/hg19"
mkdir -p "$TEMP_DIR/hg38"
# split into 50 files
split -n 50 hg19.txt "$TEMP_DIR/hg19/hg19_"
split -n 50 hg38.txt "$TEMP_DIR/hg38/hg38_"
# gzip each file
gzip "$TEMP_DIR/hg19/hg19_"*
gzip "$TEMP_DIR/hg38/hg38_"*
# move to output directory
mv "$TEMP_DIR/hg19" "$OUTPUT_DIR"
mv "$TEMP_DIR/hg38" "$OUTPUT_DIR"
# cleanup
cd "$CURR_DIR"
rm -rf "$TEMP_DIR"
