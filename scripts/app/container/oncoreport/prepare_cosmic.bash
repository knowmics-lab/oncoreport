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

[ ! -d "$ONCOREPORT_COSMIC_PATH" ] && mkdir -p "$ONCOREPORT_COSMIC_PATH"

if [ ! -f "$ONCOREPORT_COSMIC_PATH/.env" ]; then
  if [[ -z "$COSMIC_USERNAME" ]]; then
    exit_abnormal "COSMIC username is required!" true 102
  fi

  if [[ -z "$COSMIC_PASSWORD" ]]; then
    exit_abnormal "COSMIC password is required!" true 103
  fi
fi

COSMIC_TOKEN=""
if [ -f "$ONCOREPORT_COSMIC_PATH/.env" ] && [[ -z "$COSMIC_USERNAME" ]] && [[ -z "$COSMIC_PASSWORD" ]]; then
  COSMIC_TOKEN=$(cat "$ONCOREPORT_COSMIC_PATH/.env")
else
  COSMIC_TOKEN=$(echo "${COSMIC_USERNAME}:${COSMIC_PASSWORD}" | base64)
  echo "$COSMIC_TOKEN" >"$ONCOREPORT_COSMIC_PATH/.env"
fi

if [ -z "$COSMIC_TOKEN" ]; then
  exit_abnormal "COSMIC token is empty!" true 103
fi

cosmic_download() {
  TMP_OUT=$(curl -s -H "Authorization: Basic ${COSMIC_TOKEN}" "$1")
  if echo "$TMP_OUT" | jq -e -M -r ".error" -- >/dev/null; then
    MESSAGE="$(echo "$TMP_OUT" | jq -M -r ".error")"
    echo "COSMIC token: $COSMIC_TOKEN"
    echo "Error response: $TMP_OUT"
    if [ "${MESSAGE,,}" = "not authorised" ]; then
      exit_abnormal "Unable to validate COSMIC account. Check your username and password!" false 104
    fi
    exit_abnormal "$MESSAGE" false 105
  fi
  URL="$(echo "$TMP_OUT" | jq -M -r ".url" --)"
  wget --no-verbose --show-progress --progress=bar:force:noscroll --tries=0 \
    -O "$2" "$URL" || exit_abnormal "Unable to download $2 from $1." false 106
}

download() {
  local COSMIC_URL="$1"
  local COSMIC_FILE="$2"
  local COSMIC_OUTPUT="$3"
  TMP_OUT=$(curl -s -H "Authorization: Basic ${COSMIC_TOKEN}" "$COSMIC_URL")
  # Check if the response is not a JSON object that is it does not start with '{'
  if [[ ! "$TMP_OUT" =~ ^\{.* ]]; then
    exit_abnormal "The COSMIC response is not a JSON object. The content of the response is $TMP_OUT" false 105
  fi
  if echo "$TMP_OUT" | jq -e -M -r ".error" -- >/dev/null; then
    MESSAGE="$(echo "$TMP_OUT" | jq -M -r ".error")"
    if [ "${MESSAGE,,}" = "not authorised" ]; then
      exit_abnormal "Unable to validate COSMIC account. Check your username and password!" false 104
    fi
    exit_abnormal "$MESSAGE" false 105
  fi
  URL="$(echo "$TMP_OUT" | jq -M -r ".url" --)"
  wget --no-verbose --show-progress --progress=bar:force:noscroll --tries=0 \
    -O "tmp.tar" "$URL" || exit_abnormal "Unable to download $COSMIC_FILE from $COSMIC_URL." false 106
  tar -xf "tmp.tar" "$COSMIC_FILE" || exit_abnormal "Unable to extract $COSMIC_FILE from $COSMIC_URL." false 107
  mv "$COSMIC_FILE" "$COSMIC_OUTPUT" || exit_abnormal "Unable to move $COSMIC_FILE to $COSMIC_OUTPUT." false 108
  rm "tmp.tar"
}

download_files() {
  local GENOME_VERSION="$1"
  local GENOME_COSMIC="$2"
  local GENOME_SMALL="${GENOME_COSMIC,,}"
  echo " - Downloading ${GENOME_VERSION} Coding Mutations..."
  download "https://cancer.sanger.ac.uk/api/mono/products/v1/downloads/scripted?path=${GENOME_SMALL}/cosmic/${COSMIC_VERSION}/VCF/Cosmic_GenomeScreensMutant_Vcf_${COSMIC_VERSION}_${GENOME_COSMIC}.tar&bucket=downloads" "Cosmic_GenomeScreensMutant_${COSMIC_VERSION}_${GENOME_COSMIC}.vcf.gz" "$ONCOREPORT_COSMIC_PATH/CosmicGenomeScreensMutant_${GENOME_VERSION}.vcf.gz"
  download "https://cancer.sanger.ac.uk/api/mono/products/v1/downloads/scripted?path=${GENOME_SMALL}/cosmic/${COSMIC_VERSION}/VCF/Cosmic_CompleteTargetedScreensMutant_Vcf_${COSMIC_VERSION}_${GENOME_COSMIC}.tar&bucket=downloads" "Cosmic_CompleteTargetedScreensMutant_${COSMIC_VERSION}_${GENOME_COSMIC}.vcf.gz" "$ONCOREPORT_COSMIC_PATH/CosmicCompleteTargetedScreensMutant_${GENOME_VERSION}.vcf.gz"
  echo " - Downloading ${GENOME_VERSION} Resistance Mutations..."
  download "https://cancer.sanger.ac.uk/api/mono/products/v1/downloads/scripted?path=${GENOME_SMALL}/cosmic/${COSMIC_VERSION}/Cosmic_ResistanceMutations_Tsv_${COSMIC_VERSION}_${GENOME_COSMIC}.tar&bucket=downloads" "Cosmic_ResistanceMutations_${COSMIC_VERSION}_${GENOME_COSMIC}.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicResistanceMutations_${GENOME_VERSION}.txt.gz"
  echo " - Downloading ${GENOME_VERSION} COSMIC Complete Mutation Data (Targeted Screens)..."
  download "https://cancer.sanger.ac.uk/api/mono/products/v1/downloads/scripted?path=${GENOME_SMALL}/cosmic/${COSMIC_VERSION}/Cosmic_CompleteTargetedScreensMutant_Tsv_${COSMIC_VERSION}_${GENOME_COSMIC}.tar&bucket=downloads" "Cosmic_CompleteTargetedScreensMutant_${COSMIC_VERSION}_${GENOME_COSMIC}.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicCompleteTargetedScreensMutantExport_${GENOME_VERSION}.tsv.gz"
  echo " - Downloading ${GENOME_VERSION} COSMIC Mutation Data (Genome Screens)..."
  download "https://cancer.sanger.ac.uk/api/mono/products/v1/downloads/scripted?path=${GENOME_SMALL}/cosmic/${COSMIC_VERSION}/Cosmic_GenomeScreensMutant_Tsv_${COSMIC_VERSION}_${GENOME_COSMIC}.tar&bucket=downloads" "Cosmic_GenomeScreensMutant_${COSMIC_VERSION}_${GENOME_COSMIC}.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicGenomeScreensMutantExport_${GENOME_VERSION}.tsv.gz"
  echo " - Downloading ${GENOME_VERSION} Classifications..."
  download "https://cancer.sanger.ac.uk/api/mono/products/v1/downloads/scripted?path=${GENOME_SMALL}/cosmic/${COSMIC_VERSION}/Cosmic_Classification_Tsv_${COSMIC_VERSION}_${GENOME_COSMIC}.tar&bucket=downloads" "Cosmic_Classification_${COSMIC_VERSION}_${GENOME_COSMIC}.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicClassification_${GENOME_VERSION}.tsv.gz"
  echo " - Downloading ${GENOME_VERSION} Samples..."
  download "https://cancer.sanger.ac.uk/api/mono/products/v1/downloads/scripted?path=${GENOME_SMALL}/cosmic/${COSMIC_VERSION}/Cosmic_Sample_Tsv_${COSMIC_VERSION}_${GENOME_COSMIC}.tar&bucket=downloads" "Cosmic_Sample_${COSMIC_VERSION}_${GENOME_COSMIC}.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicSamples_${GENOME_VERSION}.tsv.gz"
  echo " - Downloading ${GENOME_VERSION} Cancer Mutation Census..."
  download "https://cancer.sanger.ac.uk/api/mono/products/v1/downloads/scripted?path=${GENOME_COSMIC}/cmc/${COSMIC_VERSION}/CancerMutationCensus_AllData_Tsv_${COSMIC_VERSION}_${GENOME_COSMIC}.tar&bucket=downloads" "CancerMutationCensus_AllData_${COSMIC_VERSION}_${GENOME_COSMIC}.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicCancerMutationCensus_${GENOME_VERSION}.tsv.gz"
  echo " - Indexing ${GENOME_VERSION} Coding Mutations..."
  bcftools index -f "$ONCOREPORT_COSMIC_PATH/CosmicGenomeScreensMutant_${GENOME_VERSION}.vcf.gz"
  bcftools index -f "$ONCOREPORT_COSMIC_PATH/CosmicCompleteTargetedScreensMutant_${GENOME_VERSION}.vcf.gz"
  echo " - Merging ${GENOME_VERSION} Coding Mutations..."
  bcftools concat -a -O z \
    -o "$ONCOREPORT_COSMIC_PATH/CosmicCodingMuts_${GENOME_VERSION}.vcf.gz" \
    "$ONCOREPORT_COSMIC_PATH/CosmicGenomeScreensMutant_${GENOME_VERSION}.vcf.gz" \
    "$ONCOREPORT_COSMIC_PATH/CosmicCompleteTargetedScreensMutant_${GENOME_VERSION}.vcf.gz"
  [ -f "$ONCOREPORT_COSMIC_PATH/CosmicCodingMuts_${GENOME_VERSION}.vcf.gz" ] &&
    rm "$ONCOREPORT_COSMIC_PATH/CosmicGenomeScreensMutant_${GENOME_VERSION}.vcf.gz" &&
    rm "$ONCOREPORT_COSMIC_PATH/CosmicCompleteTargetedScreensMutant_${GENOME_VERSION}.vcf.gz"
  [ ! -f "$ONCOREPORT_COSMIC_PATH/CosmicCodingMuts_${GENOME_VERSION}.vcf.gz" ] &&
    exit_abnormal "Unable to merge ${GENOME_VERSION} Coding Mutations" false 109
}

preprocess_archives() {
  local GENOME="$1"
  [ -f "$ONCOREPORT_COSMIC_PATH/CompleteTargetedScreens_${GENOME}.tsv.gz" ] &&
    rm "$ONCOREPORT_COSMIC_PATH/CompleteTargetedScreens_${GENOME}.tsv.gz"
  [ -f "$ONCOREPORT_COSMIC_PATH/GenomeScreensMutant_${GENOME}.tsv.gz" ] &&
    rm "$ONCOREPORT_COSMIC_PATH/GenomeScreensMutant_${GENOME}.tsv.gz"

  echo " - Pre-processing archives..."

  echo "   - Extracting coding mutations positions and variations..."
  zcat "$ONCOREPORT_COSMIC_PATH/CosmicCodingMuts_${GENOME}.vcf.gz" |
    cut -f1,2,3,4,5 | grep -v '^#' | sort |
    uniq >"$ONCOREPORT_COSMIC_PATH/CosmicCodMutDef_${GENOME}.txt" ||
    exit_abnormal "Unable to prepare coding mutations" false 110

  echo "   - Extracting all mutations positions and variations (Targeted Screens)..."
  zcat "$ONCOREPORT_COSMIC_PATH/CosmicCompleteTargetedScreensMutantExport_${GENOME}.tsv.gz" | cut -f 1,7,11,15,16,17,19 |
    awk '(NR>1 && $1!="" && $2!="" && $3!="" && $4!="" && $5!="" && $6!="" && $7!="")' |
    awk -v OFS='\t' '{ gsub(/_ENST.*/, "", $1); gsub("p.", "", $3); print $2,$1,$3,$4,$5,$6,$7 }' |
    sort | uniq | gzip >"$ONCOREPORT_COSMIC_PATH/CompleteTargetedScreens_${GENOME}.tsv.gz"

  echo "   - Extracting all mutations positions and variations (Genome Screens)..."
  zcat "$ONCOREPORT_COSMIC_PATH/CosmicGenomeScreensMutantExport_${GENOME}.tsv.gz" | cut -f 1,7,11,15,16,17,19 |
    awk '(NR>1 && $1!="" && $2!="" && $3!="" && $4!="" && $5!="" && $6!="" && $7!="")' |
    awk -v OFS='\t' '{ gsub(/_ENST.*/, "", $1); gsub("p.", "", $3); print $2,$1,$3,$4,$5,$6,$7 }' |
    sort | uniq | gzip >"$ONCOREPORT_COSMIC_PATH/GenomeScreensMutant_${GENOME}.tsv.gz"

  echo "   - Merging all mutations positions and variations..."
  zcat "$ONCOREPORT_COSMIC_PATH/CompleteTargetedScreens_${GENOME}.tsv.gz" \
    "$ONCOREPORT_COSMIC_PATH/GenomeScreensMutant_${GENOME}.tsv.gz" | sort |
    uniq | gzip >"$ONCOREPORT_COSMIC_PATH/CosmicVariantsRaw_${GENOME}.tsv.gz"

  echo "   - Extracting mutation tiers from COSMIC CMC..."
  zcat "$ONCOREPORT_COSMIC_PATH/CosmicCancerMutationCensus_${GENOME}.tsv.gz" |
    cut -d$'\t' -f 19,58 | awk '(NR>1 && $1!="" && $2!="")' | sort | uniq |
    gzip >"$ONCOREPORT_COSMIC_PATH/tiers_${GENOME}.tsv.gz"
}

cleanup() {
  local GENOME="$1"
  rm *_${GENOME}.vcf.gz *_${GENOME}.vcf.gz.csi *_${GENOME}.tsv.gz *_${GENOME}.txt *_${GENOME}.txt.gz
}

OLD_PWD=$(pwd)
cd "$ONCOREPORT_COSMIC_PATH" || exit 107
echo "Preparing COSMIC hg19 database:"
download_files "hg19" "GRCh37"
preprocess_archives "hg19"
echo " - Processing hg19 database..."
Rscript "$ONCOREPORT_SCRIPT_PATH/PrepareCOSMIC.R" "$ONCOREPORT_COSMIC_PATH" "hg19" || exit_abnormal "Unable to process hg19 database" false 111
echo "Preparing COSMIC hg38 database:"
download_files "hg38" "GRCh38"
preprocess_archives "hg38"
echo " - Processing hg38 database..."
Rscript "$ONCOREPORT_SCRIPT_PATH/PrepareCOSMIC.R" "$ONCOREPORT_COSMIC_PATH" "hg38" || exit_abnormal "Unable to process hg38 database" false 112
echo " - Cleaning up..."
cleanup "hg19"
cleanup "hg38"
cd "$OLD_PWD" || exit 113
touch "$ONCOREPORT_COSMIC_PATH/completed"
echo "Done!"

echo -e "COSMIC\t${COSMIC_VERSION}\t$(date +%Y-%m-%d)" >"$ONCOREPORT_COSMIC_PATH/version.txt"
