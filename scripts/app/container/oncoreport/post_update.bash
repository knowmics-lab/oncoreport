#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

exit_abnormal() {
  echo "$1" 1>&2
  [[ "$2" == "true" ]] && usage
  exit "$3"
}

if [ ! -d "$ONCOREPORT_COSMIC_PATH/hg19" ] || [ ! -d "$ONCOREPORT_COSMIC_PATH/hg38" ]; then
  echo "COSMIC update is required."
  echo "Cleaning up old COSMIC database..."
  rm "$ONCOREPORT_COSMIC_PATH"/*.txt
  echo "Starting COSMIC update..."
  bash "$ONCOREPORT_SCRIPT_PATH/prepare_cosmic.bash" || exit_abnormal "Unable to download cosmic database!" false 105
  echo "Update completed!"
fi

chmod -R 777 "$ONCOREPORT_INDEXES_PATH"
chmod -R 777 "$ONCOREPORT_COSMIC_PATH"
