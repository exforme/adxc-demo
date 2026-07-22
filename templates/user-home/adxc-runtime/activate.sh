#!/usr/bin/env bash
# adxc-demo per-user runtime activation. This file is sourced by users.
ADXC_USER_ENV="${HOME}/.adxc/env"
[[ -f "${ADXC_USER_ENV}" ]] && source "${ADXC_USER_ENV}"
ADXC_HOME="${ADXC_HOME:-/opt/adxc}"
ADXC_VERSION="unknown"
[[ -f "${ADXC_HOME}/VERSION" ]] && ADXC_VERSION="$(cat "${ADXC_HOME}/VERSION" 2>/dev/null)"
export ADXC_HOME
export PATH="${ADXC_HOME}/bin:${PATH}"
printf '============================================================\n'
printf 'adxc-demo ACTIVE\n'
printf '============================================================\n'
printf '\nVersion:\n  %s\n' "${ADXC_VERSION}"
printf '\nInstallation:\n  %s\n' "${ADXC_HOME}"
printf '\nCommands:\n  adxc\n  adxc-admin\n  adxc-cmd --list\n'
printf '============================================================\n'
