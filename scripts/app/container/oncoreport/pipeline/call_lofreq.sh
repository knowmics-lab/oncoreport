#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

usage() {
  echo "Usage: $0 -@ <THREADS> -i <INDEX> -t <TUMOR_BAM_FILE> -T <TUMOR_GROUP_NAME> [-n <NORMAL_BAM_FILE>] -v <RAW_VARIANTS_FILE> -p <PASS_VARIANTS_FILE>" 1>&2
}

exit_abnormal() {
  echo "$1" 1>&2
  [[ "$2" == "true" ]] && usage
  exit "$3"
}

while getopts @:i:t:T:n:v:p: flag; do
  case "${flag}" in
  @) THREADS="${OPTARG}" ;;
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
  if ((THREADS > 1)); then
    lofreq call-parallel --pp-threads "$THREADS" --call-indels -f "$ONCOREPORT_INDEXES_PATH/${INDEX}.fa" \
      -o "$RAW_VARIANTS_FILE" "$TUMOR_BAM_FILE" || exit_abnormal "Unable to call variants" false 107
  else
    lofreq call -f "$ONCOREPORT_INDEXES_PATH/${INDEX}.fa" --call-indels -o "$RAW_VARIANTS_FILE" "$TUMOR_BAM_FILE" || exit_abnormal "Unable to call variants" false 107
  fi
else
  echo "Performing tumor-vs-normal analysis"
  TMPDIR=$(mktemp -d)
  mkdir -p "$TMPDIR"
  lofreq somatic --threads "$THREADS" -t "$TUMOR_BAM_FILE" -n "$NORMAL_BAM_FILE" -f "$ONCOREPORT_INDEXES_PATH/${INDEX}.fa" \
    --call-indels -o "$TMPDIR/out_" || exit_abnormal "Unable to call variants" false 107
  [ ! -f "$TMPDIR/out_somatic_final.snvs.vcf.gz" ] && exit_abnormal "Unable to find SNV file" false 108
  [ ! -f "$TMPDIR/out_somatic_final.indels.vcf.gz" ] && exit_abnormal "Unable to find INDELS file" false 109
  bcftools concat -Ov "$TMPDIR/out_somatic_final.snvs.vcf.gz" "$TMPDIR/out_somatic_final.indels.vcf.gz" \
    -o "$RAW_VARIANTS_FILE" || exit_abnormal "Unable to concatenate SNV and INDEL files" false 110
  rm -r "$TMPDIR"
fi
echo "Selecting PASS variants"
OUT=$(mktemp --suffix=".vcf")
OUT1=$(mktemp --suffix=".vcf")
awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' "$RAW_VARIANTS_FILE" >"$OUT" || exit_abnormal "Unable to select PASS variants" false 110
java -jar "$GATK_PATH" RenameSampleInVcf -I "$OUT" -O "$OUT1" --NEW_SAMPLE_NAME "$TUMOR_GROUP_NAME" --VALIDATION_STRINGENCY "SILENT" || exit_abnormal "Unable to rename sample in VCF file" false 112
java -jar "$GATK_PATH" FixVcfHeader -I "$OUT1" -O "$PASS_VARIANTS_FILE".gz || exit_abnormal "Unable to fix final VCF file" false 113
gzip -d "$PASS_VARIANTS_FILE".gz
rm "$OUT" "$OUT1"
