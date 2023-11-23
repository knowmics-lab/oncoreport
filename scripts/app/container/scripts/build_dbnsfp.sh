#!/bin/bash
SCRIPT_PATH="$(
    cd "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)"
CURR_DIR="$(pwd)"

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
[[ ! -f "$TEMP_DIR/dbnsfp.zip" ]] && wget "$DBNSFP_URL" -O "$TEMP_DIR/dbnsfp.zip"
unzip -o "$TEMP_DIR/dbnsfp.zip"
# extract version number from README
RELEASE_DATE=$(cat "$TEMP_DIR/"*.readme.txt | head -n 4 | tail -n 1 | sed -r 's/^[[:blank:]]//g' | tr -d '\r')
VERSION_NUMBER=$(cat "$TEMP_DIR/"*.readme.txt | head -n 1 | cut -d' ' -f3 | tr -d '\r')
# append version number to output file versions.txt in the output directory
echo -e "dbNSFP\t$VERSION_NUMBER\t$RELEASE_DATE" >>"$OUTPUT_DIR/versions.txt"

# extract only the columns we need
pv "$TEMP_DIR/"*.chr*.gz | zcat | cut -d$'\t' -f 3,4,8,9,40,52,56,61,64,67,72,75,138 | grep -v '^ref' |
    awk 'BEGIN{OFS=FS="\t"} {tmp=$1;$1=$3;$3=tmp;tmp=$2;$2=$4;$4=tmp;print}' >hg19.txt
pv "$TEMP_DIR/"*.chr*.gz | zcat | cut -d$'\t' -f 1,2,3,4,40,52,56,61,64,67,72,75,138 | grep -v '^#chr' >hg38.txt

Rscript "$SCRIPT_PATH/clean_dbnsfp.R" "$TEMP_DIR/hg19.txt" "$TEMP_DIR/hg38.txt" "$TEMP_DIR/headers.txt"

mkdir -p "$TEMP_DIR/hg19"
mkdir -p "$TEMP_DIR/hg38"
# split into 50 files without cutting lines
split -n l/50 "$TEMP_DIR/hg19.txt" "$TEMP_DIR/hg19/hg19_"
split -n l/50 "$TEMP_DIR/hg38.txt" "$TEMP_DIR/hg38/hg38_"
# add the content of headers.txt to each file
for f in "$TEMP_DIR/hg19/hg19_"*; do cat "$TEMP_DIR/headers.txt" "$f" >"$f.tmp" && mv "$f.tmp" "$f"; done
for f in "$TEMP_DIR/hg38/hg38_"*; do cat "$TEMP_DIR/headers.txt" "$f" >"$f.tmp" && mv "$f.tmp" "$f"; done
# gzip each file
gzip "$TEMP_DIR/hg19/hg19_"*
gzip "$TEMP_DIR/hg38/hg38_"*
# move to output directory
mkdir -p "$OUTPUT_DIR/hg19/dbNSFP"
mkdir -p "$OUTPUT_DIR/hg38/dbNSFP"
mv "$TEMP_DIR/hg19/"* "$OUTPUT_DIR/hg19/dbNSFP/"
mv "$TEMP_DIR/hg38/"* "$OUTPUT_DIR/hg38/dbNSFP/"
# cleanup
cd "$CURR_DIR"
rm -rf "$TEMP_DIR"
