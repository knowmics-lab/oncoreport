#!/bin/bash
SCRIPT_PATH="$(
    cd "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)"
CURR_DIR="$(pwd)"

function wget_progress() {
    local url="$1"
    local output="$2"
    wget --no-verbose --show-progress --progress=bar:force:noscroll "$url" -O "$output"
}

function zip_file_list() {
    unzip -l "$1" | awk -F" " '{print $4}' | grep -v "^$" | tail +3l
}

function zip_read_file() {
    unzip -p "$1" $2
}

OUTPUT_DIR="$(realpath $1)"
[[ -z "$OUTPUT_DIR" ]] && echo "Usage: $0 <output_dir>" && exit 1
DBNSFP_URL="https://dbnsfp.s3.amazonaws.com/dbNSFP4.4a.zip"
# if second argument is given, use it as the DBNSFP_URL
[[ -n "$2" ]] && DBNSFP_URL="$2"
# if third argument is given, use it as the temp directory otherwise use CURR_DIR/tmp
TEMP_DIR="$3"
[[ -z "$TEMP_DIR" ]] && TEMP_DIR="$CURR_DIR/tmp"
TEMP_DIR="$(realpath $TEMP_DIR)"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
echo "Downloading dbNSFP database"
[[ ! -f "$TEMP_DIR/dbnsfp.zip" ]] && wget_progress "$DBNSFP_URL" "$TEMP_DIR/dbnsfp.zip"
# Read file names from dbnsfp.zip without extracting
README_FILE_NAME=$(zip_file_list "$TEMP_DIR/dbnsfp.zip" | grep 'readme.txt')
CHROMOSOMES_FILE_NAMES=$(zip_file_list "$TEMP_DIR/dbnsfp.zip" | grep 'chr')
# extract version number from README
VERSION_NUMBER=$(zip_read_file "$TEMP_DIR/dbnsfp.zip" "$README_FILE_NAME" | head -n 1 | tr -d '\r\n' | cut -d' ' -f3)
# append version number to output file versions.txt in the output directory
echo -e "dbNSFP\t${VERSION_NUMBER}\t$(date +%Y-%m-%d)" >>"$OUTPUT_DIR/versions.txt"

# extract only the columns we need
echo "Extracting hg19 columns from dbNSFP database"
zip_read_file "$TEMP_DIR/dbnsfp.zip" $CHROMOSOMES_FILE_NAMES | pv |
    zcat | cut -d$'\t' -f 3,4,8,9,40,52,56,61,64,67,72,75,138 | grep -v '^ref' |
    awk 'BEGIN{OFS=FS="\t"} {tmp=$1;$1=$3;$3=tmp;tmp=$2;$2=$4;$4=tmp;print}' >hg19.txt
echo "Extracting hg38 columns from dbNSFP database"
zip_read_file "$TEMP_DIR/dbnsfp.zip" $CHROMOSOMES_FILE_NAMES | pv |
    zcat | cut -d$'\t' -f 1,2,3,4,40,52,56,61,64,67,72,75,138 | grep -v '^#chr' >hg38.txt
echo "Processing hg19 and hg38 files"
Rscript "$SCRIPT_PATH/clean_dbnsfp.R" "$TEMP_DIR/hg19.txt" "$TEMP_DIR/hg38.txt" "$TEMP_DIR/headers.txt"

mkdir -p "$TEMP_DIR/hg19"
mkdir -p "$TEMP_DIR/hg38"
# split into 50 files without cutting lines
echo "Splitting hg19 and hg38 files"
split -n l/50 "$TEMP_DIR/hg19.txt" "$TEMP_DIR/hg19/hg19_"
split -n l/50 "$TEMP_DIR/hg38.txt" "$TEMP_DIR/hg38/hg38_"
rm "$TEMP_DIR/hg19.txt"
rm "$TEMP_DIR/hg38.txt"
rm "$TEMP_DIR/dbnsfp.zip"
# add the content of headers.txt to each file
echo "Adding headers to hg19 and hg38 files"
for f in "$TEMP_DIR/hg19/hg19_"*; do cat "$TEMP_DIR/headers.txt" "$f" >"$f.tmp" && mv "$f.tmp" "$f"; done
for f in "$TEMP_DIR/hg38/hg38_"*; do cat "$TEMP_DIR/headers.txt" "$f" >"$f.tmp" && mv "$f.tmp" "$f"; done
# gzip each file
echo "Compressing hg19 and hg38 files"
gzip "$TEMP_DIR/hg19/hg19_"*
gzip "$TEMP_DIR/hg38/hg38_"*
# move to output directory
echo "Moving hg19 and hg38 files to output directory"
mkdir -p "$OUTPUT_DIR/hg19/dbNSFP"
mkdir -p "$OUTPUT_DIR/hg38/dbNSFP"
mv "$TEMP_DIR/hg19/"* "$OUTPUT_DIR/hg19/dbNSFP/"
mv "$TEMP_DIR/hg38/"* "$OUTPUT_DIR/hg38/dbNSFP/"
# cleanup
cd "$CURR_DIR"
rm -rf "$TEMP_DIR"
