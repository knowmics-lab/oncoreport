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

echo "Starting Oncoreport Setup!"

[ ! -f "$ONCOREPORT_INDEXES_PATH/completed" ] && (
  bash "$ONCOREPORT_SCRIPT_PATH/prepare_indexes.bash" || exit_abnormal "Unable to prepare indexes!" false 104
)

[ ! -f "$ONCOREPORT_COSMIC_PATH/completed" ] && (
  bash "$ONCOREPORT_SCRIPT_PATH/prepare_cosmic.bash" -u "$COSMIC_USERNAME" -p "$COSMIC_PASSWORD" || exit_abnormal "Unable to download cosmic database!" false 105
)

echo "Oncoreport setup completed!"