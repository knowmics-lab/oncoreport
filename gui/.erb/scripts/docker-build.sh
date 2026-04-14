#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCKER_OUT="$PROJECT_DIR/release/build-docker"

mkdir -p "$DOCKER_OUT"

docker run --rm \
  --env-file <(env | grep -iE 'DEBUG|NODE_|ELECTRON_|YARN_|NPM_|CI|CIRCLE|TRAVIS_TAG|TRAVIS|TRAVIS_REPO_|TRAVIS_BUILD_|TRAVIS_BRANCH|TRAVIS_PULL_REQUEST_|APPVEYOR_|CSC_|GH_|GITHUB_|BT_|AWS_|STRIP|BUILD_') \
  --env ELECTRON_CACHE="/root/.cache/electron" \
  --env ELECTRON_BUILDER_CACHE="/root/.cache/electron-builder" \
  -v ${PROJECT_DIR}:/project \
  -v "${DOCKER_OUT}:/project/release/build-docker" \
  -v ${PWD##*/}-node-modules:/project/node_modules \
  -v ~/.cache/electron:/root/.cache/electron \
  -v ~/.cache/electron-builder:/root/.cache/electron-builder \
  -w /project \
  electronuserland/builder:wine \
  bash -c "
    npm install
    npm run package:linux-win
  "

echo "Docker build complete. Output in $DOCKER_OUT"