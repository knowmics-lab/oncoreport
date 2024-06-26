#!/usr/bin/env bash

SCRIPT_PATH="$(
  cd "$(dirname "$0")" >/dev/null 2>&1 || exit
  pwd -P
)"

while getopts b:t: flag; do
  case "${flag}" in
  b) ONCOREPORT_BRANCH=${OPTARG} ;;
  t) GLTRANSLATE_JSON_PATH=${OPTARG} ;;
  *) echo "Usage: $0 [-b <branch>] [-t <gl_translate_api.json>]" && exit 1 ;;
  esac
done
if [ -z "$GLTRANSLATE_JSON_PATH" ]; then
  echo "Usage: $0 [-b <branch>] [-t <gl_translate_api.json>]" && exit 1
fi
ONCOREPORT_BRANCH=${ONCOREPORT_BRANCH:-"master"}
ONCOREPORT_ORIGIN=${ONCOREPORT_ORIGIN:-"https://github.com/knowmics-lab/oncoreport.git"}

LATEST_GIT_TAG="$(git describe --tags $(git rev-list --tags --max-count=1) | cut -d'-' -f1)"
DEFAULT_VERSION="v${LATEST_GIT_TAG:-"0.0.1"}"

# Container name and version can be set with environment variables
CONTAINER_NAME=${CONTAINER_NAME:-"alaimos/oncoreport"}
CONTAINER_VERSION=${CONTAINER_VERSION:-"$DEFAULT_VERSION"}
CONTAINER_VERSION_NUMBER=$(echo "${CONTAINER_VERSION}" | cut -d'v' -f2 | tr -d '.')
CONTAINER_VERSION_NUMBER=${CONTAINER_VERSION_NUMBER:-"0"}
CONTAINER_VERSION_NUMBER=$(printf "%d" "${CONTAINER_VERSION_NUMBER}")
CONTAINER_ARCHITECTURE=${CONTAINER_ARCHITECTURE:-"amd64"}
CONTAINER_BASE_PATH=${CONTAINER_BASE_PATH:-"/support"}
DO_NOT_BUILD_DB=${DO_NOT_BUILD_DB:-"false"}

echo "Building container ${CONTAINER_NAME}:${CONTAINER_VERSION}"

if [ ! -f "/tmp/secret_drugbank" ]; then
  echo "Enter your drugbank username:"
  read -r DRUGBANK_USERNAME
  echo "Enter your drugbank password:"
  read -r -s DRUGBANK_PASSWORD
  printf '%s\n%s\n' "$DRUGBANK_USERNAME" "$DRUGBANK_PASSWORD" >/tmp/secret_drugbank
fi

DOCKER_BUILDKIT=1 docker build \
  --target=stage1_base \
  --build-arg="BASE_PATH=${CONTAINER_BASE_PATH}" \
  --build-arg="ARCHITECTURE=${CONTAINER_ARCHITECTURE}" \
  -t oncoreport_builder_stage_1 . &&
  docker run --rm \
    --mount type=bind,source="/tmp/secret_drugbank",target="/run/secrets/drugbank",readonly \
    --mount type=bind,source="${GLTRANSLATE_JSON_PATH}",target="/run/secrets/gltranslate",readonly \
    --mount type=bind,source="${SCRIPT_PATH}",target="${CONTAINER_BASE_PATH}" \
    --env ONCOREPORT_ORIGIN="https://github.com/knowmics-lab/oncoreport.git" \
    --env ONCOREPORT_BRANCH="${ONCOREPORT_BRANCH}" \
    --env BASE_PATH="${CONTAINER_BASE_PATH}" \
    --env CONTAINER_VERSION="$(echo "${CONTAINER_VERSION}" | cut -d'v' -f2)" \
    --env CONTAINER_VERSION_NUMBER="${CONTAINER_VERSION_NUMBER}" \
    --env DO_NOT_BUILD_DB="${DO_NOT_BUILD_DB}" \
    oncoreport_builder_stage_1 bash ${CONTAINER_BASE_PATH}/scripts/prepare.sh &&
  DOCKER_BUILDKIT=1 docker build \
    --build-arg="BASE_PATH=${CONTAINER_BASE_PATH}" \
    --build-arg="ARCHITECTURE=${CONTAINER_ARCHITECTURE}" \
    -t "${CONTAINER_NAME}:${CONTAINER_VERSION}" . &&
  rm -f /tmp/secret_drugbank &&
  docker rmi oncoreport_builder_stage_1

  #--target=oncoreport_final \

echo "Container ${CONTAINER_NAME}:${CONTAINER_VERSION} built successfully!"
