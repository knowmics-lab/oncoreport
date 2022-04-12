#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

usage() {
  echo "Usage: $0 [-n <BOOLEAN>] -1 <FIRST_FASTQ_FILE> -2 <SECOND_FASTQ_FILE> -i <INDEX_NAME> -t <NUMBER_OF_THREADS> -r <PATH_TRIM> -o <ALIGNED_OUTPUT_FILE>" 1>&2
  echo "   -n: enable/disable trimming." 1>&2
}

exit_abnormal() {
  echo "$1" 1>&2
  [[ "$2" == "true" ]] && usage
  exit "$3"
}

TRIM=true
while getopts n:1:2:i:t:r:o: flag; do
  case "${flag}" in
  n) [[ "${OPTARG}" == "false" ]] && TRIM=false ;;
  1) fastq1="${OPTARG}" ;;
  2) fastq2="${OPTARG}" ;;
  i) index="${OPTARG}" ;;
  t) threads="${OPTARG}" ;;
  r) PATH_TRIM="${OPTARG}" ;;
  o) OUTPUT_PATH="${OPTARG}" ;;
  *) exit_abnormal "Invalid Parameter ${flag}" true 101 ;;
  esac
done

FASTQ1_NAME=$(. "$ONCOREPORT_SCRIPT_PATH/pipeline/get_name.sh" "$fastq1")
if [ -n "$fastq1" ] && [ -z "$fastq2" ]; then
  echo "The FASTQ file is not paired."
  [[ "$TRIM" == "true" ]] && echo "Trimming"
  [[ "$TRIM" != "true" ]] && echo "Trimming is disabled"
  if ((threads > 7)); then
    RT=6
  else
    RT=$threads
  fi
  if [[ "$TRIM" == "true" ]]; then
    trim_galore -j "$RT" -o "$PATH_TRIM/" --dont_gzip "$fastq1" || exit_abnormal "Unable to trim input file" false 101
    FILE1="$PATH_TRIM/${FASTQ1_NAME}_trimmed.fq"
  else
    FILE1="$fastq1"
  fi
  echo "Alignment"
  bwa mem -M -t "$threads" "$ONCOREPORT_INDEXES_PATH/$index.fa" "$FILE1" | samtools view -1 - >"$OUTPUT_PATH" || exit_abnormal "Unable to align input file" false 103
elif [ -n "$fastq1" ] && [ -n "$fastq2" ]; then
  FASTQ2_NAME=$(. "$ONCOREPORT_SCRIPT_PATH/pipeline/get_name.sh" "$fastq2")
  echo "The FASTQ file is paired"
  [[ "$TRIM" == "true" ]] && echo "Trimming"
  [[ "$TRIM" != "true" ]] && echo "Trimming is disabled"
  if ((threads > 7)); then
    RT=6
  else
    RT=$threads
  fi
  FILE1="$PATH_TRIM/${FASTQ1_NAME}_val_1.fq"
  FILE2="$PATH_TRIM/${FASTQ2_NAME}_val_2.fq"
  if [[ "$TRIM" == "true" ]]; then
    trim_galore -j "$RT" --paired --dont_gzip -o "$PATH_TRIM/" "$fastq1" "$fastq2" || exit_abnormal "Unable to trim input file" false 101
  else
    cp "$fastq1" "$FILE1"
    cp "$fastq2" "$FILE2"
  fi
  echo "Running fastq-pair"
  fastq_pair "$FILE1" "$FILE2" || exit_abnormal "Unable to perform reads pairing" 102
  O_FILE1="$PATH_TRIM/${FASTQ1_NAME}_val_1.fq.paired.fq"
  O_FILE2="$PATH_TRIM/${FASTQ2_NAME}_val_2.fq.paired.fq"
  if [ ! -f "$O_FILE1" ] || [ ! -f "$O_FILE2" ]; then
    exit_abnormal "Unable to perform reads pairing" 102
  fi
  echo "Alignment"
  bwa mem -M -t "$threads" "$ONCOREPORT_INDEXES_PATH/${index}.fa" "$O_FILE1" "$O_FILE2" | samtools view -1 - >"$OUTPUT_PATH" || exit_abnormal "Unable to align input file" false 103
fi
