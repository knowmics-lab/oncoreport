#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

exit_abnormal() {
  echo "$1" 1>&2
  [[ "$2" == "true" ]] && usage
  exit "$3"
}

check_cosmic_update() {
  local COSMIC_VERSION_NUMBER="$(printf "%d" "$(tr -d 'v' <<< "$COSMIC_VERSION")")"
  if [ -f "$ONCOREPORT_COSMIC_PATH/version.txt" ]; then
    local LOCAL_COSMIC_VERSION_NUMBER="$(printf "%d" "$(cut -d$'\t' -f2 "$ONCOREPORT_COSMIC_PATH/version.txt" | tr -d 'v')")"
    echo "Container supported version: $COSMIC_VERSION_NUMBER, Local version: $LOCAL_COSMIC_VERSION_NUMBER"
    if (( COSMIC_VERSION_NUMBER > LOCAL_COSMIC_VERSION_NUMBER )); then
      echo "COSMIC update is required."
      return 1
    fi
  else
    echo "COSMIC database is not present. Update is required."
    return 2
  fi

  echo "COSMIC database is up to date."
  return 0
}

if [ ! -d "$ONCOREPORT_COSMIC_PATH/hg19" ] || [ ! -d "$ONCOREPORT_COSMIC_PATH/hg38" ]; then
  echo "COSMIC update is required."
  echo "Cleaning up old COSMIC database..."
  rm "$ONCOREPORT_COSMIC_PATH"/*.txt
  echo "Starting COSMIC update..."
  bash "$ONCOREPORT_SCRIPT_PATH/prepare_cosmic.bash" || exit_abnormal "Unable to download cosmic database!" false 105
  echo "Update completed!"
fi

echo "Checking COSMIC update..."
if ! check_cosmic_update; then
  echo "Cleaning up old COSMIC database..."
  rm -rf "$ONCOREPORT_COSMIC_PATH"/*
  echo "Starting COSMIC update..."
  bash "$ONCOREPORT_SCRIPT_PATH/prepare_cosmic.bash" || exit_abnormal "Unable to download cosmic database!" false 105
  echo "Update completed!"
fi

chmod -R 777 "$ONCOREPORT_INDEXES_PATH"
chmod -R 777 "$ONCOREPORT_COSMIC_PATH"
