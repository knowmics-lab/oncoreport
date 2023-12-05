#!/bin/bash

CURR_PATH="$(pwd)"
DATABASES_REPO_URL="https://github.com/knowmics-lab/oncoreport-data.git"

DATABASES_PATH="$(realpath $1)"
[[ -z "$DATABASES_PATH" ]] && echo "Usage: $0 <databases_path>" && exit 1

[[ -d "$DATABASES_PATH" ]] && rm -rf "$DATABASES_PATH"
cd "$DATABASES_PATH"
git clone --depth=1 --branch=main "$DATABASES_REPO_URL" "$DATABASES_PATH"
rm -rf "$DATABASES_PATH/.git"
cd "$CURR_PATH"
