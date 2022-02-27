#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

usage() {
  echo "Usage: $0 -i <INDEX> -t <TUMOR_BAM_FILE> -T <TUMOR_GROUP_NAME> [-n <NORMAL_BAM_FILE> -N <NORMAL_GROUP_NAME>] -v <RAW_VARIANTS_FILE> -f <FILTERED_VARIANTS_FILE> -p <PASS_VARIANTS_FILE> [-d <1/0: ENABLE DOWNSAMPLE>]" 1>&2
}

exit_abnormal() {
  echo "$1" 1>&2
  [[ "$2" == "true" ]] && usage
  exit "$3"
}

while getopts @:i:t:T:n:N:v:f:p:d: flag; do
  case "${flag}" in
  i) INDEX="${OPTARG}" ;;
  t) TUMOR_BAM_FILE="${OPTARG}" ;;
  T) TUMOR_GROUP_NAME="${OPTARG}" ;;
  n) NORMAL_BAM_FILE="${OPTARG}" ;;
  N) NORMAL_GROUP_NAME="${OPTARG}" ;;
  v) RAW_VARIANTS_FILE="${OPTARG}" ;;
  f) FILTERED_VARIANTS_FILE="${OPTARG}" ;;
  p) PASS_VARIANTS_FILE="${OPTARG}" ;;
  d) DOWNSAMPLE="${OPTARG}" ;;
  *) exit_abnormal "Invalid Parameter ${flag}" true 101 ;;
  esac
done

[ -z "$TUMOR_BAM_FILE" ] && exit_abnormal "Tumor BAM file is required" true 102
[ ! -f "$TUMOR_BAM_FILE" ] && exit_abnormal "Tumor BAM file does not exist" true 103
[ -n "$NORMAL_BAM_FILE" ] && [ ! -f "$NORMAL_BAM_FILE" ] && exit_abnormal "Normal BAM file does not exist" true 104
[ -z "$RAW_VARIANTS_FILE" ] && exit_abnormal "Raw variants file is required" true 105
[ -z "$FILTERED_VARIANTS_FILE" ] && exit_abnormal "Filtered variants file is required" true 106
[ -z "$PASS_VARIANTS_FILE" ] && exit_abnormal "Pass variants file is required" true 107

echo "Variant Calling with Mutect2"
if [ -z "$NORMAL_BAM_FILE" ]; then
  echo "Performing tumor-only analysis"
  if [ "$DOWNSAMPLE" == "1" ]; then
    java -jar "$GATK_PATH" Mutect2 -R "$ONCOREPORT_INDEXES_PATH/${INDEX}.fa" -I "$TUMOR_BAM_FILE" \
      -tumor "$TUMOR_GROUP_NAME" -O "$RAW_VARIANTS_FILE" || exit_abnormal "Unable to call variants" false 108
  else
    java -jar "$GATK_PATH" Mutect2 -R "$ONCOREPORT_INDEXES_PATH/${INDEX}.fa" -I "$TUMOR_BAM_FILE" \
      -tumor "$TUMOR_GROUP_NAME" -O "$RAW_VARIANTS_FILE" --max-suspicious-reads-per-alignment-start 0 \
      --max-reads-per-alignment-start 0 || exit_abnormal "Unable to call variants" false 109
  fi
else
  echo "Performing tumor-vs-normal analysis"
  if [ "$DOWNSAMPLE" == "1" ]; then
    java -jar "$GATK_PATH" Mutect2 -R "$ONCOREPORT_INDEXES_PATH/${INDEX}.fa" -I "$TUMOR_BAM_FILE" \
      -tumor "$TUMOR_GROUP_NAME" -I "$NORMAL_BAM_FILE" -normal "$NORMAL_GROUP_NAME" \
      -O "$RAW_VARIANTS_FILE" || exit_abnormal "Unable to call variants" false 109
  else
    java -jar "$GATK_PATH" Mutect2 -R "$ONCOREPORT_INDEXES_PATH/${INDEX}.fa" -I "$TUMOR_BAM_FILE" \
      -tumor "$TUMOR_GROUP_NAME" -I "$NORMAL_BAM_FILE" -normal "$NORMAL_GROUP_NAME" \
      -O "$RAW_VARIANTS_FILE" --max-suspicious-reads-per-alignment-start 0 \
      --max-reads-per-alignment-start 0 || exit_abnormal "Unable to call variants" false 109
  fi
fi
echo "Filtering variants"
java -jar "$GATK_PATH" FilterMutectCalls -R "$ONCOREPORT_INDEXES_PATH/${INDEX}.fa" -V "$RAW_VARIANTS_FILE" \
  -O "$FILTERED_VARIANTS_FILE" --stats "${RAW_VARIANTS_FILE}.stats" || exit_abnormal "Unable to filter variants" false 110
echo "Selecting PASS variants"
awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' "$FILTERED_VARIANTS_FILE" >"$PASS_VARIANTS_FILE" || exit_abnormal "Unable to select PASS variants" false 111
