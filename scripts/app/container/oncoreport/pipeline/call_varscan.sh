#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

usage() {
  echo "Usage: $0 -i <INDEX> -t <TUMOR_BAM_FILE> -T <TUMOR_GROUP_NAME> [-n <NORMAL_BAM_FILE>] -v <RAW_VARIANTS_FILE> -p <PASS_VARIANTS_FILE>" 1>&2
}

exit_abnormal() {
  echo "$1" 1>&2
  [[ "$2" == "true" ]] && usage
  exit "$3"
}

while getopts i:t:T:n:v:p: flag; do
  case "${flag}" in
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

echo "Variant Calling with LoFreq"
if [ -z "$NORMAL_BAM_FILE" ]; then
  echo "Performing tumor-only analysis"
  samtools mpileup -B -f "$ONCOREPORT_INDEXES_PATH/${INDEX}.fa" "$TUMOR_BAM_FILE" |
    java -jar "$VARSCAN_PATH" mpileup2snp --variants --p-value 0.01 --output-vcf >"$RAW_VARIANTS_FILE" || exit_abnormal "Unable to call variants" true 107
else
  echo "Performing tumor-vs-normal analysis"
  reference="$ONCOREPORT_INDEXES_PATH/${INDEX}.fa"
  TMPDIR=$(mktemp -d)
  mkdir -p "$TMPDIR"
  samtools mpileup -q 1 -f "$reference" "$TUMOR_BAM_FILE" >"$TMPDIR/tumor.mpileup"
  samtools mpileup -q 1 -f "$reference" "$NORMAL_BAM_FILE" >"$TMPDIR/normal.mpileup"
  java -jar "$VARSCAN_PATH" somatic --output-vcf "$TMPDIR/normal.mpileup" "$TMPDIR/tumor.mpileup" "$RAW_VARIANTS_FILE"
  rm -r "$TMPDIR"
fi
echo "Selecting PASS variants"
echo "Selecting PASS variants"
OUT=$(mktemp)
awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' "$RAW_VARIANTS_FILE" >"$OUT" || exit_abnormal "Unable to select PASS variants" false 111
java -jar "$PICARD_PATH" RenameSampleInVcf INPUT="$OUT" OUTPUT="$PASS_VARIANTS_FILE" \
  NEW_SAMPLE_NAME="$TUMOR_GROUP_NAME" VALIDATION_STRINGENCY="SILENT" || exit_abnormal "Unable to select PASS variants" false 111
rm "$OUT"
