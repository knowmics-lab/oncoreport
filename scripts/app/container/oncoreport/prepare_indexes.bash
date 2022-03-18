#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

cleanup() {
  [ -f "$ONCOREPORT_INDEXES_PATH/hg19.tar.bz2" ] && rm "$ONCOREPORT_INDEXES_PATH/hg19.tar.bz2"
  [ -f "$ONCOREPORT_INDEXES_PATH/hg38.tar.bz2" ] && rm "$ONCOREPORT_INDEXES_PATH/hg38.tar.bz2"
}

exit_abnormal() {
  echo "$1" 1>&2
  exit "$2"
}

echo "Preparing indexes:"
echo " - Creating index directory"
[ ! -d "$ONCOREPORT_INDEXES_PATH" ] && mkdir -p "$ONCOREPORT_INDEXES_PATH"
OLD_PWD=$(pwd)
cd "$ONCOREPORT_INDEXES_PATH" || exit 101
cleanup
echo " - Downloading hg19 genome package..."
wget --progress=bar:force:noscroll "https://oncoreport.s3.eu-central-1.amazonaws.com/indexes/hg19.tar.bz2" -P "$ONCOREPORT_INDEXES_PATH" || exit_abnormal "Unable to download hg19 package" 102
tar -jxvf hg19.tar.bz2 || exit_abnormal "Unable to extract index" 103
echo " - Downloading hg38 genome package..."
wget --progress=bar:force:noscroll "https://oncoreport.s3.eu-central-1.amazonaws.com/indexes/hg38.tar.bz2" -P "$ONCOREPORT_INDEXES_PATH" || exit_abnormal "Unable to download hg38 package" 102
tar -jxvf hg38.tar.bz2 || exit_abnormal "Unable to extract index" 103
echo " - Creating base recalibration directory"
[ ! -d "$ONCOREPORT_RECALIBRATION_PATH" ] && mkdir -p "$ONCOREPORT_RECALIBRATION_PATH"
cd "$ONCOREPORT_RECALIBRATION_PATH" || exit 101
echo " - Downloading hg19 recalibration package..."
wget --progress=bar:force:noscroll "https://oncoreport.s3.eu-central-1.amazonaws.com/base_recalibration/hg19.vcf.gz" -P "$ONCOREPORT_RECALIBRATION_PATH" || exit_abnormal "Unable to download hg19 package" 104
wget --progress=bar:force:noscroll "https://oncoreport.s3.eu-central-1.amazonaws.com/base_recalibration/hg19.vcf.gz.tbi" -P "$ONCOREPORT_RECALIBRATION_PATH" || exit_abnormal "Unable to download hg19 package index" 105
echo " - Downloading hg38 recalibration package..."
wget --progress=bar:force:noscroll "https://oncoreport.s3.eu-central-1.amazonaws.com/base_recalibration/hg38.vcf.gz" -P "$ONCOREPORT_RECALIBRATION_PATH" || exit_abnormal "Unable to download hg38 package" 104
wget --progress=bar:force:noscroll "https://oncoreport.s3.eu-central-1.amazonaws.com/base_recalibration/hg38.vcf.gz.tbi" -P "$ONCOREPORT_RECALIBRATION_PATH" || exit_abnormal "Unable to download hg38 package index" 105
echo " - Cleaning up..."
cleanup
cd "$OLD_PWD" || exit 106
chown -R www-data:staff "$ONCOREPORT_INDEXES_PATH"
chmod -R 777 "$ONCOREPORT_INDEXES_PATH"
chown -R www-data:staff "$ONCOREPORT_RECALIBRATION_PATH"
chmod -R 777 "$ONCOREPORT_RECALIBRATION_PATH"
touch "$ONCOREPORT_INDEXES_PATH/completed"
echo "Done!"
