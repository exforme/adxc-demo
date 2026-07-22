#!/usr/bin/env bash
COMMAND_NAME="demo-start-node-script"
COMMAND_TYPE="external-script"
COMMAND_DESCRIPTION="Demo Start Node script implementation"
COMMAND_ENABLED="YES"
COMMAND_STATUS="ACTIVE"
SCRIPT_PATH="scripts/miqm-start-node-enhanced.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADXC_ROOT_DIR="${SCRIPT_DIR}"
source "${ADXC_ROOT_DIR}/lib/adxc-common.sh"
main() { "$(adxc_relative_to_root "${SCRIPT_PATH}")" "$@"; }
main "$@"
