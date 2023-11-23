#!/usr/bin/env bash

SCRIPT_PATH="$(
  cd "$(dirname "$0")" >/dev/null 2>&1 || exit
  pwd -P
)"

LATEST_GIT_TAG="$(git describe --tags $(git rev-list --tags --max-count=1) | cut -d'-' -f1)"
DEFAULT_VERSION="v${LATEST_GIT_TAG:-"v0.0.1"}"

# Container name and version can be set with environment variables
CONTAINER_NAME=${CONTAINER_NAME:-"alaimos/oncoreport"}
CONTAINER_VERSION=${CONTAINER_VERSION:-"$DEFAULT_VERSION"}

echo "Building container ${CONTAINER_NAME}:${CONTAINER_VERSION}"

[ -f "$SCRIPT_PATH/databases/cgi_original_hg19.txt" ] && rm "$SCRIPT_PATH/databases/*"

if [ ! -f "$SCRIPT_PATH/ws.tgz" ]; then
  REPO_ORIGIN="$(git ls-remote --get-url origin)"
  mkdir "$SCRIPT_PATH/repo" || exit
  cd "$SCRIPT_PATH/repo" || exit
  git clone "$REPO_ORIGIN" || exit
  cd "$SCRIPT_PATH/repo/oncoreport" || exit
  if [ -n "$1" ]; then
    git checkout "$1"
  fi
  tar -zcvf "$SCRIPT_PATH/ws.tgz" ws/
  cd "$SCRIPT_PATH" || exit
  rm -rf "$SCRIPT_PATH/repo" || exit
fi
[[ ! -f ws.tgz ]] && echo "Archive not built!" && exit

bash "$SCRIPT_PATH/scripts/download_databases.sh" "$SCRIPT_PATH/databases"

if [ ! -d "$SCRIPT_PATH/databases/hg19" ] || [ ! -d "$SCRIPT_PATH/databases/hg38" ]; then
  rm -rf "$SCRIPT_PATH/databases/hg19"
  rm -rf "$SCRIPT_PATH/databases/hg38"
  bash "$SCRIPT_PATH/scripts/build_dbnsfp.sh" "$SCRIPT_PATH/databases"
fi

[[ ! -d "$SCRIPT_PATH/databases/hg19/dbNSFP" ]] && echo "hg19 dbNSFP database not built!" && exit
[[ ! -d "$SCRIPT_PATH/databases/hg38/dbNSFP" ]] && echo "hg38 dbNSFP database not built!" && exit

if [ ! -f "$SCRIPT_PATH/databases/pharm_database_hg19.txt" ] || [ ! -d "$SCRIPT_PATH/databases/pharm_database_hg38.txt" ]; then
  rm -rf "$SCRIPT_PATH/databases/pharm_database_hg19.txt"
  rm -rf "$SCRIPT_PATH/databases/pharm_database_hg38.txt"
  bash "$SCRIPT_PATH/scripts/build_pharmgkb.sh" "$SCRIPT_PATH/databases"
fi

[[ ! -f "$SCRIPT_PATH/databases/pharm_database_hg19.txt" ]] && echo "hg19 PharmGKB database not built!" && exit
[[ ! -f "$SCRIPT_PATH/databases/pharm_database_hg38.txt" ]] && echo "hg38 PharmGKB database not built!" && exit

echo "Enter your drugbank username:"
read -r DRUGBANK_USERNAME
echo "Enter your drugbank password:"
read -r -s DRUGBANK_PASSWORD
printf '%s\n%s\n' "$DRUGBANK_USERNAME" "$DRUGBANK_PASSWORD" >/tmp/secret_drugbank

DOCKER_BUILDKIT=1 docker build --no-cache \
  --secret id=drugbank,src=/tmp/secret_drugbank \
  -t "${CONTAINER_NAME}:${CONTAINER_VERSION}" . &&
  rm "$SCRIPT_PATH/ws.tgz" &&
  rm /tmp/secret_drugbank
