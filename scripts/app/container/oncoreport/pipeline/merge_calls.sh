#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

usage() {
  echo "Usage: $0 -i <INPUT_FILE> -i <INPUT_FILE> ... -o <OUTPUT_FILE>" 1>&2
}

exit_abnormal() {
  echo "$1" 1>&2
  [[ "$2" == "true" ]] && usage
  exit "$3"
}

INPUTS=()
while getopts i:o: flag; do
  case "${flag}" in
  i) INPUTS+=("${OPTARG}") ;;
  o) OUTPUT="${OPTARG}" ;;
  *) exit_abnormal "Invalid Parameter ${flag}" true 101 ;;
  esac
done

INPUTS_COUNT=${#INPUTS[@]}
[[ "$INPUTS_COUNT" -eq 0 ]] && exit_abnormal "No input files specified" true 102

if [[ "$INPUTS_COUNT" -eq 1 ]]; then
  cp "${INPUTS[0]}" "$OUTPUT"
  exit 0
fi

INPUTS_COMPRESSED=()
for ((i = 0; i < INPUTS_COUNT; i++)); do
  IF="${INPUTS[i]}"
  bgzip -c "$IF" >"$IF.gz" || exit_abnormal "Failed to compress $IF" false 103
  bcftools index "$IF.gz" || exit_abnormal "Failed to index $IF.gz" false 104
  INPUTS_COMPRESSED+=("$IF.gz")
done

bcftools concat -a -D -O v -o "$OUTPUT" "${INPUTS_COMPRESSED[@]%.vcf}" || exit_abnormal "Failed to concatenate" false 105

for ((i = 0; i < INPUTS_COUNT; i++)); do
  IF="${INPUTS_COMPRESSED[i]}"
  [ -f "$IF" ] && rm "$IF"
  [ -f "$IF.csi" ] && rm "$IF.csi"
done
