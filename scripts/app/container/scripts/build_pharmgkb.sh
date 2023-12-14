#!/bin/bash
SCRIPT_PATH="$(
    cd "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)"
CURR_DIR="$(pwd)"
PHARMGKB_VARIANTS_URL="https://api.pharmgkb.org/v1/download/file/data/variantAnnotations.zip"
DBSNP_BASE="ftp://ftp.ncbi.nih.gov/snp/latest_release/VCF"
DBSNP_HG19_URL="$DBSNP_BASE/GCF_000001405.25.gz"
DBSNP_HG38_URL="$DBSNP_BASE/GCF_000001405.40.gz"
GENOME_BASE="ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405"
HG19_CHROM_URL="$GENOME_BASE/GCF_000001405.25_GRCh37.p13/GCF_000001405.25_GRCh37.p13_assembly_report.txt"
HG38_CHROM_URL="$GENOME_BASE/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_assembly_report.txt"

function process_chromosomes() {
    local assembly_report_file="$1"
    local chrom_map_file="$2"
    grep -e '^[^#]' "$assembly_report_file" | awk 'BEGIN{OFS=FS="\t"} { print $7, $10 }' >"$chrom_map_file"
}

function process_variants() {
    local vcf_file="$1"
    local output_prefix="$2"
    local output_dir="$(dirname "$output_prefix")"
    mkdir -p "$output_dir"
    pv "$vcf_file" | zcat | grep -v '^#' | cut -d$'\t' -f1-5 | split -l 10000000 - "$output_prefix"
    rm "$vcf_file"
    # gzip "$output_dir"/*
    # rm "$vcf_file"
    # mkdir -p "$output_dir"
    # split -n l/100 "$vcf_file.tmp" "$output_prefix"
    # rm "$vcf_file.tmp"
    # gzip "$output_dir"/*
}

function wget_progress() {
    local url="$1"
    local output="$2"
    wget --no-verbose --show-progress --progress=bar:force:noscroll "$url" -O "$output"
}

OUTPUT_DIR="$(realpath $1)"
[[ -z "$OUTPUT_DIR" ]] && echo "Usage: $0 <output_dir> [<temp_dir>]" && exit 1
# if second argument is given, use it as the temp directory otherwise use CURR_DIR/tmp
TEMP_DIR="$2"
[[ -z "$TEMP_DIR" ]] && TEMP_DIR="$CURR_DIR/tmp"
TEMP_DIR="$(realpath $TEMP_DIR)"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
echo "Downloading PharmGKB variants"
[ ! -f "$TEMP_DIR/variantAnnotations.zip" ] && wget_progress "$PHARMGKB_VARIANTS_URL" "$TEMP_DIR/variantAnnotations.zip"
echo "Extracting Annotations"
unzip -o "$TEMP_DIR/variantAnnotations.zip" -d "$TEMP_DIR"
echo "Extracting version date"
RELEASE_DATE=$(cat "$TEMP_DIR/"CREATED_*.txt | cut -d' ' -f 3 | tr -d '\r')
echo -e "PharmGKB\t$RELEASE_DATE\t$(date +%Y-%m-%d)" >>"$OUTPUT_DIR/versions.txt"

echo "Processing genome hg19"
[ ! -f "$TEMP_DIR/hg19_chrom.txt" ] && wget_progress "$HG19_CHROM_URL" "$TEMP_DIR/hg19_chrom.txt"
[ ! -f "$TEMP_DIR/dbsnp_hg19.vcf.gz" ] && wget_progress "$DBSNP_HG19_URL" "$TEMP_DIR/dbsnp_hg19.vcf.gz"
echo " - Extracting chromosome names"
process_chromosomes "$TEMP_DIR/hg19_chrom.txt" "$TEMP_DIR/hg19_chrnames.tsv"
echo " - Extracting variants"
process_variants "$TEMP_DIR/dbsnp_hg19.vcf.gz" "$TEMP_DIR/dbsnp_hg19/variants_"
echo " - Processing PharmGKB variants for hg19"
Rscript "$SCRIPT_PATH/process_pharmgkb.R" "$TEMP_DIR/var_pheno_ann.tsv" \
        "$TEMP_DIR/hg19_chrnames.tsv" "$TEMP_DIR/dbsnp_hg19" "$OUTPUT_DIR/hg19/pharm_database.rds"
rm -rf "$TEMP_DIR/dbsnp_hg19" "$TEMP_DIR/hg19_chrnames.tsv" "$TEMP_DIR/hg19_chrom.txt"

echo "Processing genome hg38"
[ ! -f "$TEMP_DIR/hg38_chrom.txt" ] && wget_progress "$HG38_CHROM_URL" "$TEMP_DIR/hg38_chrom.txt"
[ ! -f "$TEMP_DIR/dbsnp_hg38.vcf.gz" ] && wget_progress "$DBSNP_HG38_URL" "$TEMP_DIR/dbsnp_hg38.vcf.gz"
echo " - Extracting chromosome names"
process_chromosomes "$TEMP_DIR/hg38_chrom.txt" "$TEMP_DIR/hg38_chrnames.tsv"
echo " - Extracting variants"
process_variants "$TEMP_DIR/dbsnp_hg38.vcf.gz" "$TEMP_DIR/dbsnp_hg38/variants_"
echo " - Processing PharmGKB variants for hg38"
Rscript "$SCRIPT_PATH/process_pharmgkb.R" "$TEMP_DIR/var_pheno_ann.tsv" \
        "$TEMP_DIR/hg38_chrnames.tsv" "$TEMP_DIR/dbsnp_hg38" "$OUTPUT_DIR/hg38/pharm_database.rds"
rm -rf "$TEMP_DIR/dbsnp_hg38" "$TEMP_DIR/hg38_chrnames.tsv" "$TEMP_DIR/hg38_chrom.txt"
echo "Done"

# cleanup
cd "$CURR_DIR"
rm -rf "$TEMP_DIR"
