#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

usage() {
  echo "Usage: $0 [-H] -i <INDEX> -t <TUMOR_BAM_FILE> -T <TUMOR_GROUP_NAME> [-n <NORMAL_BAM_FILE>] -v <RAW_VARIANTS_FILE> -p <PASS_VARIANTS_FILE>" 1>&2
  echo "   -H: Use all variants. This script uses only high-confidence calls by default." 1>&2
}

exit_abnormal() {
  echo "$1" 1>&2
  [[ "$2" == "true" ]] && usage
  exit "$3"
}

HC_ONLY=true
while getopts Hi:t:T:n:v:p: flag; do
  case "${flag}" in
  H) HC_ONLY=false ;;
  i) INDEX="${OPTARG}" ;;
  t) TUMOR_BAM_FILE="${OPTARG}" ;;
  T) TUMOR_GROUP_NAME="${OPTARG}" ;;
  n) NORMAL_BAM_FILE="${OPTARG}" ;;
  v) RAW_VARIANTS_FILE="${OPTARG}" ;;
  p) PASS_VARIANTS_FILE="${OPTARG}" ;;
  *) exit_abnormal "Invalid Parameter ${flag}" true 101 ;;
  esac
done

[ -z "$TUMOR_BAM_FILE" ] && exit_abnormal "Tumor BAM file is required" true 102
[ ! -f "$TUMOR_BAM_FILE" ] && exit_abnormal "Tumor BAM file does not exist" true 103
[ -n "$NORMAL_BAM_FILE" ] && [ ! -f "$NORMAL_BAM_FILE" ] && exit_abnormal "Normal BAM file does not exist" true 104
[ -z "$RAW_VARIANTS_FILE" ] && exit_abnormal "Raw variants file is required" true 105
[ -z "$PASS_VARIANTS_FILE" ] && exit_abnormal "Pass variants file is required" true 106

echo "Variant Calling with VarScan"
reference="$ONCOREPORT_INDEXES_PATH/${INDEX}.fa"
if [ -z "$NORMAL_BAM_FILE" ]; then
  echo "Performing tumor-only analysis"
  samtools mpileup -B -f "$reference" "$TUMOR_BAM_FILE" |
    java -jar "$VARSCAN_PATH" mpileup2snp --variants --p-value 0.01 --output-vcf >"$RAW_VARIANTS_FILE" || exit_abnormal "Unable to call variants" false 107
else
  echo "Performing tumor-vs-normal analysis"
  TMPDIR=$(mktemp -d)
  mkdir -p "$TMPDIR"
  samtools mpileup -B -q 1 -f "$reference" "$NORMAL_BAM_FILE" "$TUMOR_BAM_FILE" |
    java -jar "$VARSCAN_PATH" somatic --output-snp "$TMPDIR/output.snp.vcf" --output-indel "$TMPDIR/output.indel.vcf" \
      --output-vcf --mpileup --somatic-p-value 0.05 || exit_abnormal "Unable to call variants" false 107

  [ ! -f "$TMPDIR/output.snp.vcf" ] && exit_abnormal "Unable to find SNPs output file" false 108
  [ ! -f "$TMPDIR/output.indel.vcf" ] && exit_abnormal "Unable to find INDELs output file" false 109

  java -jar "$VARSCAN_PATH" processSomatic "$TMPDIR/output.snp.vcf" || exit_abnormal "Unable to process SNPs" false 110
  java -jar "$VARSCAN_PATH" processSomatic "$TMPDIR/output.indel.vcf" || exit_abnormal "Unable to process INDELs" false 111

  echo "Preparing raw variant call file"
  if [[ "$HC_ONLY" == "true" ]]; then
    python3 "$ONCOREPORT_SCRIPT_PATH/pipeline/append_type.py" "$TMPDIR/output.snp.Somatic.hc.vcf" "$TMPDIR/snp.Somatic.vcf" "Somatic" "TUMOR" || exit_abnormal "Unable to pre-process Somatic SNP VCF files" false 112
    python3 "$ONCOREPORT_SCRIPT_PATH/pipeline/append_type.py" "$TMPDIR/output.snp.Germline.hc.vcf" "$TMPDIR/snp.Germline.vcf" "Germline" "TUMOR" || exit_abnormal "Unable to pre-process Germline SNP VCF files" false 113
    python3 "$ONCOREPORT_SCRIPT_PATH/pipeline/append_type.py" "$TMPDIR/output.snp.LOH.hc.vcf" "$TMPDIR/snp.LOH.vcf" "LOH" "TUMOR" || exit_abnormal "Unable to pre-process LOH SNP VCF files" false 114
    python3 "$ONCOREPORT_SCRIPT_PATH/pipeline/append_type.py" "$TMPDIR/output.indel.Somatic.hc.vcf" "$TMPDIR/indel.Somatic.vcf" "Somatic" "TUMOR" || exit_abnormal "Unable to pre-process Somatic INDEL VCF files" false 115
    python3 "$ONCOREPORT_SCRIPT_PATH/pipeline/append_type.py" "$TMPDIR/output.indel.Germline.hc.vcf" "$TMPDIR/indel.Germline.vcf" "Germline" "TUMOR" || exit_abnormal "Unable to pre-process Germline INDEL VCF files" false 116
    python3 "$ONCOREPORT_SCRIPT_PATH/pipeline/append_type.py" "$TMPDIR/output.indel.LOH.hc.vcf" "$TMPDIR/indel.LOH.vcf" "LOH" "TUMOR" || exit_abnormal "Unable to pre-process LOH INDEL VCF files" false 117
  else
    python3 "$ONCOREPORT_SCRIPT_PATH/pipeline/append_type.py" "$TMPDIR/output.snp.Somatic.vcf" "$TMPDIR/snp.Somatic.vcf" "Somatic" "TUMOR" || exit_abnormal "Unable to pre-process Somatic SNP VCF files" false 112
    python3 "$ONCOREPORT_SCRIPT_PATH/pipeline/append_type.py" "$TMPDIR/output.snp.Germline.vcf" "$TMPDIR/snp.Germline.vcf" "Germline" "TUMOR" || exit_abnormal "Unable to pre-process Germline SNP VCF files" false 113
    python3 "$ONCOREPORT_SCRIPT_PATH/pipeline/append_type.py" "$TMPDIR/output.snp.LOH.vcf" "$TMPDIR/snp.LOH.vcf" "LOH" "TUMOR" || exit_abnormal "Unable to pre-process LOH SNP VCF files" false 114
    python3 "$ONCOREPORT_SCRIPT_PATH/pipeline/append_type.py" "$TMPDIR/output.indel.Somatic.vcf" "$TMPDIR/indel.Somatic.vcf" "Somatic" "TUMOR" || exit_abnormal "Unable to pre-process Somatic INDEL VCF files" false 115
    python3 "$ONCOREPORT_SCRIPT_PATH/pipeline/append_type.py" "$TMPDIR/output.indel.Germline.vcf" "$TMPDIR/indel.Germline.vcf" "Germline" "TUMOR" || exit_abnormal "Unable to pre-process Germline INDEL VCF files" false 116
    python3 "$ONCOREPORT_SCRIPT_PATH/pipeline/append_type.py" "$TMPDIR/output.indel.LOH.vcf" "$TMPDIR/indel.LOH.vcf" "LOH" "TUMOR" || exit_abnormal "Unable to pre-process LOH INDEL VCF files" false 117
  fi
  bash "$ONCOREPORT_SCRIPT_PATH/pipeline/merge_calls.sh" -o "$RAW_VARIANTS_FILE" -i "$TMPDIR/snp.Somatic.vcf" \
    -i "$TMPDIR/snp.Germline.vcf" -i "$TMPDIR/snp.LOH.vcf" -i "$TMPDIR/indel.Somatic.vcf" \
    -i "$TMPDIR/indel.Germline.vcf" -i "$TMPDIR/indel.LOH.vcf" || exit_abnormal_code "Unable to concatenate variant calls" 118
  rm -r "$TMPDIR"
fi
echo "Selecting PASS variants"
OUT=$(mktemp)
awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' "$RAW_VARIANTS_FILE" >"$OUT" || exit_abnormal "Unable to select PASS variants" false 119
java -jar "$GATK_PATH" RenameSampleInVcf -I "$OUT" -O "$PASS_VARIANTS_FILE" --NEW_SAMPLE_NAME "$TUMOR_GROUP_NAME" --VALIDATION_STRINGENCY "SILENT" || exit_abnormal "Unable to select PASS variants" false 120
rm "$OUT"
