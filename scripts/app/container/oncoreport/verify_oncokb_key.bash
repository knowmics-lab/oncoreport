#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

python3 "$ONCOREPORT_SCRIPT_PATH/verify_oncokb_key.py" \
  -e "$ONCOREPORT_APP_PATH/.env_oncokb"
exit $?
