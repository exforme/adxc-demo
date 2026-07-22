#!/usr/bin/env bash
COMMAND_NAME="demo-readiness-check"
COMMAND_TYPE="external-script"
COMMAND_DESCRIPTION="Demo MIQM Cluster Readiness check"
COMMAND_ENABLED="YES"
COMMAND_STATUS="ACTIVE"
SCRIPT_PATH="scripts/miqm-cluster-readiness.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADXC_ROOT_DIR="${SCRIPT_DIR}"
source "${ADXC_ROOT_DIR}/lib/adxc-common.sh"
main() { "$(adxc_relative_to_root "${SCRIPT_PATH}")" "$@"; }
main "$@"
