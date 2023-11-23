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
  echo "$COSMIC_TOKEN" > "$ONCOREPORT_COSMIC_PATH/.env"
fi

if [ -z "$COSMIC_TOKEN" ]; then
  exit_abnormal "COSMIC token is empty!" true 103
fi

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
  wget --progress=bar:force:noscroll --tries=0 -O "$2" "$URL" || exit_abnormal "Unable to download $2 from $1." false 106
}

OLD_PWD=$(pwd)
cd "$ONCOREPORT_COSMIC_PATH" || exit 107
echo "Preparing COSMIC database:"
echo " - Downloading hg19 Coding Mutations..."
cosmic_download "https://cancer.sanger.ac.uk/cosmic/file_download/GRCh37/cosmic/${COSMIC_VERSION}/VCF/CosmicCodingMuts.vcf.gz" "$ONCOREPORT_COSMIC_PATH/CosmicCodingMuts_hg19.vcf.gz"
echo " - Downloading hg19 Resistance Mutations..."
cosmic_download "https://cancer.sanger.ac.uk/cosmic/file_download/GRCh37/cosmic/${COSMIC_VERSION}/CosmicResistanceMutations.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicResistanceMutations_hg19.txt.gz"
echo " - Downloading hg19 COSMIC Complete Mutation Data (Targeted Screens)..."
cosmic_download "https://cancer.sanger.ac.uk/cosmic/file_download/GRCh37/cosmic/${COSMIC_VERSION}/CosmicCompleteTargetedScreensMutantExport.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicCompleteTargetedScreensMutantExport_hg19.tsv.gz"
echo " - Downloading hg19 COSMIC Mutation Data (Genome Screens)..."
cosmic_download "https://cancer.sanger.ac.uk/cosmic/file_download/GRCh37/cosmic/${COSMIC_VERSION}/CosmicGenomeScreensMutantExport.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicGenomeScreensMutantExport_hg19.tsv.gz"
echo " - Pre-processing archives..."
zcat "$ONCOREPORT_COSMIC_PATH/CosmicCodingMuts_hg19.vcf.gz" | cut -f1,2,3,4,5 | grep -v '^#' | sort | uniq >"$ONCOREPORT_COSMIC_PATH/CosmicCodMutDef_hg19.txt" || exit_abnormal "Unable to prepare coding mutations" false 110

[ -f "$ONCOREPORT_COSMIC_PATH/CompleteTargetedScreens_hg19.tsv.gz" ] && rm "$ONCOREPORT_COSMIC_PATH/CompleteTargetedScreens_hg19.tsv.gz"
[ -f "$ONCOREPORT_COSMIC_PATH/GenomeScreensMutant_hg19.tsv.gz" ] && rm "$ONCOREPORT_COSMIC_PATH/GenomeScreensMutant_hg19.tsv.gz"

zcat "$ONCOREPORT_COSMIC_PATH/CosmicCompleteTargetedScreensMutantExport_hg19.tsv.gz" | cut -f 1,17,21,26,29,32 |
  awk '(NR>1 && $1!="" && $2!="" && $3!="" && $4!="" && $5!="" && $6!="")' |
  awk -v OFS='\t' '{ gsub(/_ENST.*/, "", $1); gsub("p.", "", $3); split($4, x, ":"); split(x[2], y, "-"); print $2,$1,$3,x[1],y[1],y[2],$5,$6 }' |
  sort | uniq | gzip >"$ONCOREPORT_COSMIC_PATH/CompleteTargetedScreens_hg19.tsv.gz"

zcat "$ONCOREPORT_COSMIC_PATH/CosmicGenomeScreensMutantExport_hg19.tsv.gz" | cut -f 1,18,21,26,28,31 |
  awk '(NR>1 && $1!="" && $2!="" && $3!="" && $4!="" && $5!="" && $6!="")' |
  awk -v OFS='\t' '{ gsub(/_ENST.*/, "", $1); gsub("p.", "", $3); split($4, x, ":"); split(x[2], y, "-"); print $2,$1,$3,x[1],y[1],y[2],$5,$6 }' |
  sort | uniq | gzip >"$ONCOREPORT_COSMIC_PATH/GenomeScreensMutant_hg19.tsv.gz"

zcat "$ONCOREPORT_COSMIC_PATH/CompleteTargetedScreens_hg19.tsv.gz" "$ONCOREPORT_COSMIC_PATH/GenomeScreensMutant_hg19.tsv.gz" | sort | uniq | gzip >"$ONCOREPORT_COSMIC_PATH/CosmicVariantsRaw_hg19.tsv.gz"

echo " - Downloading hg38 Coding Mutations..."
cosmic_download "https://cancer.sanger.ac.uk/cosmic/file_download/GRCh38/cosmic/${COSMIC_VERSION}/VCF/CosmicCodingMuts.vcf.gz" "$ONCOREPORT_COSMIC_PATH/CosmicCodingMuts_hg38.vcf.gz"
echo " - Downloading hg38 Resistance Mutations..."
cosmic_download "https://cancer.sanger.ac.uk/cosmic/file_download/GRCh38/cosmic/${COSMIC_VERSION}/CosmicResistanceMutations.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicResistanceMutations_hg38.txt.gz"
echo " - Downloading hg38 COSMIC Complete Mutation Data (Targeted Screens)..."
cosmic_download "https://cancer.sanger.ac.uk/cosmic/file_download/GRCh38/cosmic/${COSMIC_VERSION}/CosmicCompleteTargetedScreensMutantExport.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicCompleteTargetedScreensMutantExport_hg38.tsv.gz"
echo " - Downloading hg38 COSMIC Mutation Data (Genome Screens)..."
cosmic_download "https://cancer.sanger.ac.uk/cosmic/file_download/GRCh38/cosmic/${COSMIC_VERSION}/CosmicGenomeScreensMutantExport.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicGenomeScreensMutantExport_hg38.tsv.gz"
echo " - Pre-processing archives..."
zcat "$ONCOREPORT_COSMIC_PATH/CosmicCodingMuts_hg38.vcf.gz" | cut -f1,2,3,4,5 | grep -v '^#' | sort | uniq >"$ONCOREPORT_COSMIC_PATH/CosmicCodMutDef_hg38.txt" || exit_abnormal "Unable to prepare coding mutations" false 110

[ -f "$ONCOREPORT_COSMIC_PATH/CompleteTargetedScreens_hg38.tsv.gz" ] && rm "$ONCOREPORT_COSMIC_PATH/CompleteTargetedScreens_hg38.tsv.gz"
[ -f "$ONCOREPORT_COSMIC_PATH/GenomeScreensMutant_hg38.tsv.gz" ] && rm "$ONCOREPORT_COSMIC_PATH/GenomeScreensMutant_hg38.tsv.gz"

zcat "$ONCOREPORT_COSMIC_PATH/CosmicCompleteTargetedScreensMutantExport_hg38.tsv.gz" | cut -f 1,17,21,26,29,32 |
  awk '(NR>1 && $1!="" && $2!="" && $3!="" && $4!="" && $5!="" && $6!="")' |
  awk -v OFS='\t' '{ gsub(/_ENST.*/, "", $1); gsub("p.", "", $3); split($4, x, ":"); split(x[2], y, "-"); print $2,$1,$3,x[1],y[1],y[2],$5,$6 }' |
  sort | uniq | gzip >"$ONCOREPORT_COSMIC_PATH/CompleteTargetedScreens_hg38.tsv.gz"

zcat "$ONCOREPORT_COSMIC_PATH/CosmicGenomeScreensMutantExport_hg38.tsv.gz" | cut -f 1,18,21,26,28,31 |
  awk '(NR>1 && $1!="" && $2!="" && $3!="" && $4!="" && $5!="" && $6!="")' |
  awk -v OFS='\t' '{ gsub(/_ENST.*/, "", $1); gsub("p.", "", $3); split($4, x, ":"); split(x[2], y, "-"); print $2,$1,$3,x[1],y[1],y[2],$5,$6 }' |
  sort | uniq | gzip >"$ONCOREPORT_COSMIC_PATH/GenomeScreensMutant_hg38.tsv.gz"

zcat "$ONCOREPORT_COSMIC_PATH/CompleteTargetedScreens_hg38.tsv.gz" "$ONCOREPORT_COSMIC_PATH/GenomeScreensMutant_hg38.tsv.gz" | sort | uniq | gzip >"$ONCOREPORT_COSMIC_PATH/CosmicVariantsRaw_hg38.tsv.gz"

echo " - Processing hg19 database..."
Rscript "$ONCOREPORT_SCRIPT_PATH/PrepareCOSMIC.R" "$ONCOREPORT_COSMIC_PATH" "hg19" || exit_abnormal "Unable to process hg19 database" false 111
echo " - Processing hg38 database..."
Rscript "$ONCOREPORT_SCRIPT_PATH/PrepareCOSMIC.R" "$ONCOREPORT_COSMIC_PATH" "hg38" || exit_abnormal "Unable to process hg38 database" false 112
cd "$OLD_PWD" || exit 113
rm "$ONCOREPORT_COSMIC_PATH/CosmicVariantsRaw_hg19.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicVariantsRaw_hg38.tsv.gz"
touch "$ONCOREPORT_COSMIC_PATH/completed"
echo "Done!"

echo -e "COSMIC\t${COSMIC_VERSION}\t$(date +%Y-%m-%d)" >"$ONCOREPORT_COSMIC_PATH/version.txt"

rm "$ONCOREPORT_COSMIC_PATH/CompleteTargetedScreens_hg19.tsv.gz" "$ONCOREPORT_COSMIC_PATH/GenomeScreensMutant_hg19.tsv.gz"
rm "$ONCOREPORT_COSMIC_PATH/CosmicCompleteTargetedScreensMutantExport_hg19.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicGenomeScreensMutantExport_hg19.tsv.gz"
rm "$ONCOREPORT_COSMIC_PATH/CosmicCodingMuts_hg19.vcf.gz" "$ONCOREPORT_COSMIC_PATH/CosmicResistanceMutations_hg19.txt.gz"
rm "$ONCOREPORT_COSMIC_PATH/CompleteTargetedScreens_hg38.tsv.gz" "$ONCOREPORT_COSMIC_PATH/GenomeScreensMutant_hg38.tsv.gz"
rm "$ONCOREPORT_COSMIC_PATH/CosmicCompleteTargetedScreensMutantExport_hg38.tsv.gz" "$ONCOREPORT_COSMIC_PATH/CosmicGenomeScreensMutantExport_hg38.tsv.gz"
rm "$ONCOREPORT_COSMIC_PATH/CosmicCodingMuts_hg38.vcf.gz" "$ONCOREPORT_COSMIC_PATH/CosmicResistanceMutations_hg38.txt.gz"
