#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

usage() {
  echo "Usage: $0 -u <COSMIC_USERNAME> -p <COSMIC_PASSWORD>" 1>&2
}

exit_abnormal() {
  echo "$1" 1>&2
  [[ "$2" == "true" ]] && usage
  exit "$3"
}

while getopts u:p: flag; do
  case "${flag}" in
  u) COSMIC_USERNAME="${OPTARG}" ;;
  p) COSMIC_PASSWORD="${OPTARG}" ;;
  *) exit_abnormal "Invalid Parameter" true 101 ;;
  esac
done

if [[ -z "$COSMIC_USERNAME" ]]; then
  exit_abnormal "COSMIC username is required!" true 102
fi

if [[ -z "$COSMIC_PASSWORD" ]]; then
  exit_abnormal "COSMIC password is required!" true 103
fi

COSMIC_TOKEN=$(echo "${COSMIC_USERNAME}:${COSMIC_PASSWORD}" | base64)

cosmic_download() {
  TMP_OUT=$(curl -H "Authorization: Basic ${COSMIC_TOKEN}" "$1")
  if echo "$TMP_OUT" | jq -e -M -r ".error" -- >/dev/null; then
    MESSAGE="$(echo "$TMP_OUT" | jq -M -r ".error")"
    if [ "${MESSAGE,,}" = "not authorised" ]; then
      exit_abnormal "Unable to validate COSMIC account. Check your username and password!" false 104
    fi
    exit_abnormal "$MESSAGE" false 105
  fi
  URL="$(echo "$TMP_OUT" | jq -M -r ".url" --)"
  curl -o "$2" "$URL" || exit_abnormal "Unable to download $2 from $1." false 106
}

echo "Creating COSMIC directory"
[ ! -d "$ONCOREPORT_COSMIC_PATH" ] && mkdir -p "$ONCOREPORT_COSMIC_PATH"

OLD_PWD=$(pwd)
cd "$ONCOREPORT_COSMIC_PATH" || exit 107
echo "Preparing COSMIC database:"
echo " - Downloading hg19 Coding Mutations..."
cosmic_download "https://cancer.sanger.ac.uk/cosmic/file_download/GRCh37/cosmic/v92/VCF/CosmicCodingMuts.vcf.gz" "$ONCOREPORT_COSMIC_PATH/CosmicCodingMuts_hg19.vcf.gz"
echo " - Downloading hg19 Resistance Mutations..."
cosmic_download "https://cancer.sanger.ac.uk/cosmic/file_download/GRCh37/cosmic/v92/CosmicResistanceMutations.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicResistanceMutations_hg19.txt.gz"
echo " - Extracting archives..."
gunzip "$ONCOREPORT_COSMIC_PATH/CosmicResistanceMutations_hg19.txt.gz" || exit_abnormal "Unable to extract resistance mutations" false 108
gunzip "$ONCOREPORT_COSMIC_PATH/CosmicCodingMuts_hg19.vcf.gz" || exit_abnormal "Unable to extract coding mutations" false 109
cut -f1,2,3,4,5 "$ONCOREPORT_COSMIC_PATH/CosmicCodingMuts_hg19.vcf" >"$ONCOREPORT_COSMIC_PATH/CosmicCodMutDef_hg19.txt" || exit_abnormal "Unable to prepare coding mutations" false 110
echo " - Downloading hg38 Coding Mutations..."
cosmic_download "https://cancer.sanger.ac.uk/cosmic/file_download/GRCh38/cosmic/v92/VCF/CosmicCodingMuts.vcf.gz" "$ONCOREPORT_COSMIC_PATH/CosmicCodingMuts_hg38.vcf.gz"
echo " - Downloading hg38 Resistance Mutations..."
cosmic_download "https://cancer.sanger.ac.uk/cosmic/file_download/GRCh38/cosmic/v92/CosmicResistanceMutations.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicResistanceMutations_hg38.txt.gz"
echo " - Extracting archives..."
gunzip "$ONCOREPORT_COSMIC_PATH/CosmicResistanceMutations_hg38.txt.gz" || exit_abnormal "Unable to extract resistance mutations" false 108
gunzip "$ONCOREPORT_COSMIC_PATH/CosmicCodingMuts_hg38.vcf.gz" || exit_abnormal "Unable to extract coding mutations" false 109
cut -f1,2,3,4,5 "$ONCOREPORT_COSMIC_PATH/CosmicCodingMuts_hg38.vcf" >"$ONCOREPORT_COSMIC_PATH/CosmicCodMutDef_hg38.txt" || exit_abnormal "Unable to prepare coding mutations" false 110
echo " - Processing hg19 database..."
Rscript "$ONCOREPORT_SCRIPT_PATH/PrepareCOSMIC.R" "$ONCOREPORT_COSMIC_PATH" "hg19" || exit_abnormal "Unable to process hg19 database" false 111
echo " - Processing hg38 database..."
Rscript "$ONCOREPORT_SCRIPT_PATH/PrepareCOSMIC.R" "$ONCOREPORT_COSMIC_PATH" "hg38" || exit_abnormal "Unable to process hg38 database" false 112
cd "$OLD_PWD" || exit 113
touch "$ONCOREPORT_COSMIC_PATH/completed"
echo "Done!"
