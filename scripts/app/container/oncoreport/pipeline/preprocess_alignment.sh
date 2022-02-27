#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

usage() {
  echo "Usage: $0 -g <GROUP_NAME> -t <THREADS> -i <INDEX> -b <BAM_FILE> -a <ANNOTATED_BAM> [-d <NO_DUPLICATES_BAM> -m <MARKED_DUPLICATES_FILE>] -s <SORTED_BAM> -r <RECALIBRATION_DATA_FILE> -R <RECALIBRATED_BAM> -o <REORDERED_BAM>" 1>&2
}

exit_abnormal() {
  echo "$1" 1>&2
  [[ "$2" == "true" ]] && usage
  exit "$3"
}

while getopts g:t:i:b:a:d:m:s:r:R:o: flag; do
  case "${flag}" in
  g) GROUP_NAME="${OPTARG}" ;;
  i) index="${OPTARG}" ;;
  t) threads="${OPTARG}" ;;
  b) bam="${OPTARG}" ;;
  a) annotated_bam="${OPTARG}" ;;
  d) no_duplicates_bam="${OPTARG}" ;;
  m) marked_duplicates_file="${OPTARG}" ;;
  r) recalibration_data_file="${OPTARG}" ;;
  R) recalibrated_bam="${OPTARG}" ;;
  s) sorted_bam="${OPTARG}" ;;
  o) reordered_bam="${OPTARG}" ;;
  *) exit_abnormal "Invalid Parameter ${flag}" true 101 ;;
  esac
done

[ -z "$bam" ]   && exit_abnormal "BAM file is required" true 102
[ ! -f "$bam" ] && exit_abnormal "BAM file does not exist" true 103

echo "Validating BAM"
java -jar "$PICARD_PATH" ValidateSamFile I="$bam" MODE=SUMMARY
echo "Adding Read Group"
samtools sort -@ "$threads" "$bam" -o /dev/stdout | java -jar "$GATK_PATH" AddOrReplaceReadGroups -I /dev/stdin -O "$annotated_bam" --RGID 0 --RGLB lib1 --RGPL "oncoreport" --RGPU "onco" --RGSM "$GROUP_NAME" --VALIDATION_STRINGENCY SILENT || exit_abnormal "Unable to add read group" false 104

NEXT_FILE="$annotated_bam"
if [ -n "$no_duplicates_bam" ]; then
  echo "Marking duplicates"
  if ((threads > 1)); then
    java -jar "$GATK_PATH" MarkDuplicatesSpark --input "$annotated_bam" \
      --output "$no_duplicates_bam" -M "$marked_duplicates_file" \
      --read-validation-stringency SILENT --optical-duplicate-pixel-distance 2500 \
      --spark-master "local[$threads]" || exit_abnormal "Unable to remove duplicates" false 105
  else
    java -jar "$GATK_PATH" MarkDuplicates --INPUT "$annotated_bam" \
      --OUTPUT "$no_duplicates_bam" -M "$marked_duplicates_file" --VALIDATION_STRINGENCY SILENT \
      --OPTICAL_DUPLICATE_PIXEL_DISTANCE 2500 --ASSUME_SORT_ORDER "queryname" --CREATE_INDEX true || exit_abnormal "Unable to remove duplicates" false 105
  fi
  NEXT_FILE="$no_duplicates_bam"
fi

echo "Sorting"
java -jar "$GATK_PATH" SortSam --INPUT "$NEXT_FILE" --OUTPUT /dev/stdout --SORT_ORDER "coordinate" \
  --CREATE_INDEX false --CREATE_MD5_FILE false --VALIDATION_STRINGENCY SILENT |
  java -jar "$GATK_PATH" SetNmMdAndUqTags --INPUT /dev/stdin --OUTPUT "$sorted_bam" \
    --CREATE_INDEX true --REFERENCE_SEQUENCE "$ONCOREPORT_INDEXES_PATH/${index}.fa" || exit_abnormal "Unable to sort" false 106

echo "Recalibrating Quality Scores"
java -jar "$GATK_PATH" BaseRecalibrator -R "$ONCOREPORT_INDEXES_PATH/${index}.fa" -I "$sorted_bam" \
  --use-original-qualities -O "$recalibration_data_file" \
  --known-sites "$ONCOREPORT_RECALIBRATION_PATH/${index}.vcf.gz" || exit_abnormal "Unable to compute recalibration data" false 107
java -jar "$GATK_PATH" ApplyBQSR -R "$ONCOREPORT_INDEXES_PATH/${index}.fa" -I "$sorted_bam" \
  -O "$recalibrated_bam" -bqsr "$recalibration_data_file" --static-quantized-quals 10 \
  --static-quantized-quals 20 --static-quantized-quals 30 --add-output-sam-program-record \
  --create-output-bam-md5 --use-original-qualities || exit_abnormal "Unable to apply base quality recalibration" false 108

echo "Reordering"
echo java -jar "$GATK_PATH" ReorderSam -I "$recalibrated_bam" -O "$reordered_bam" -SD "$ONCOREPORT_INDEXES_PATH/${index}.dict" -S true -U true --CREATE_INDEX true --VALIDATION_STRINGENCY SILENT
java -jar "$GATK_PATH" ReorderSam -I "$recalibrated_bam" -O "$reordered_bam" -SD "$ONCOREPORT_INDEXES_PATH/${index}.dict" \
  -S true -U true --CREATE_INDEX true --VALIDATION_STRINGENCY SILENT || exit_abnormal "Unable to reorder" false 109
