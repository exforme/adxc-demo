#!/usr/bin/env bash
# Disable adxc-demo activation for a user.
set -euo pipefail
TARGET_USER="${1:-}"
[[ "$(id -u)" -eq 0 ]] || { printf 'ERROR: must run as root.\n' >&2; exit 1; }
[[ -n "${TARGET_USER}" ]] || { printf 'Usage: adxc-disable-user.sh <user>\n' >&2; exit 1; }
USER_HOME="$(getent passwd "${TARGET_USER}" | awk -F: '{print $6}')"
[[ -d "${USER_HOME}" ]] || { printf 'ERROR: home not found.\n' >&2; exit 1; }
[[ -f "${USER_HOME}/.adxc/activate.sh" ]] && mv "${USER_HOME}/.adxc/activate.sh" "${USER_HOME}/.adxc/activate.sh.disabled"
BASHRC_FILE="${USER_HOME}/.bashrc"
if [[ -f "${BASHRC_FILE}" ]] && grep -qF '# >>> adxc-demo auto activation >>>' "${BASHRC_FILE}"; then
    cp "${BASHRC_FILE}" "${BASHRC_FILE}.adxc-backup.$(date '+%Y%m%d_%H%M%S')"
    sed -i '/# >>> adxc-demo auto activation >>>/,/# <<< adxc-demo auto activation <<</d' "${BASHRC_FILE}"
fi
printf 'adxc-demo disabled for user %s.\n' "${TARGET_USER}"
