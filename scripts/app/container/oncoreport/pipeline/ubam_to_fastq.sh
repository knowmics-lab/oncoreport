#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

usage() {
  echo "Usage: $0 [-p] [-s] [-t <THREADS>] -i <INPUT_FILE> -1 <OUTPUT_FILE_1> -2 <OUTPUT_FILE_2>" 1>&2
  echo "   -p: Paired-end reads; -2 parameter is required" 1>&2
  echo "   -s: Sort reads before conversion" 1>&2
}

exit_abnormal() {
  echo "$1" 1>&2
  [[ "$2" == "true" ]] && usage
  exit "$3"
}

PAIRED=false
SORT=false
THREADS=1
while getopts psi:1:2:t: flag; do
  case "${flag}" in
  p) PAIRED=true ;;
  s) SORT=true ;;
  i) INPUT="$OPTARG" ;;
  1) OUTPUT_1="$OPTARG" ;;
  2) OUTPUT_2="$OPTARG" ;;
  t) THREADS="$OPTARG" ;;
  *) exit_abnormal "Invalid Parameter ${flag}" true 101 ;;
  esac
done

[ -f "$INPUT" ] || exit_abnormal "Input file not found: $INPUT" true 101
[ -z "$OUTPUT_1" ] && exit_abnormal "Output file 1 not specified" true 102
[ "$PAIRED" == "true" ] && [ -z "$OUTPUT_2" ] && exit_abnormal "Output file 2 not specified" true 103

if [[ "$SORT" == "true" ]]; then
  echo "Sorting reads"
  samtools sort -n -O bam -@ "$THREADS" -o "$INPUT.sorted.bam" "$INPUT"
  INPUT="$INPUT.sorted.bam"
fi

echo "Converting BAM to FASTQ"
LOG="$(dirname "$OUTPUT_1")/bamToFastq.log"
if [[ "$PAIRED" == "true" ]]; then
  bamToFastq -i "$INPUT" -fq "$OUTPUT_1" -fq2 "$OUTPUT_2" 2>"$LOG" || exit_abnormal "Error converting BAM to FASTQ" true 104
else
  bamToFastq -i "$INPUT" -fq "$OUTPUT_1" 2>"$LOG" || exit_abnormal "Error converting BAM to FASTQ" true 104
fi

[[ "$SORT" == "true" ]] && [ -f "$INPUT" ] && rm "$INPUT";
