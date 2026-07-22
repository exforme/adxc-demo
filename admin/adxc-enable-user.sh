#!/usr/bin/env bash
# Enable adxc-demo for a user. Supports --force to update .bashrc.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADXC_ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
FORCE_MODE="NO"
TARGET_USER=""
while [[ "${#}" -gt 0 ]]; do
    case "$1" in
        --force) FORCE_MODE="YES"; shift ;;
        *) TARGET_USER="$1"; shift ;;
    esac
done
[[ "$(id -u)" -eq 0 ]] || { printf 'ERROR: must run as root.\n' >&2; exit 1; }
[[ -n "${TARGET_USER}" ]] || { printf 'Usage: adxc-enable-user.sh [--force] <user>\n' >&2; exit 1; }
USER_HOME="$(getent passwd "${TARGET_USER}" | awk -F: '{print $6}')"
[[ -d "${USER_HOME}" ]] || { printf 'ERROR: home not found for %s\n' "${TARGET_USER}" >&2; exit 1; }
mkdir -p "${USER_HOME}/.adxc"
cp "${ADXC_ROOT_DIR}/templates/user-home/adxc-runtime/activate.sh" "${USER_HOME}/.adxc/activate.sh"
printf 'ADXC_HOME="%s"\n' "${ADXC_ROOT_DIR}" > "${USER_HOME}/.adxc/env"
chown -R "${TARGET_USER}:${TARGET_USER}" "${USER_HOME}/.adxc" 2>/dev/null || chown -R "${TARGET_USER}" "${USER_HOME}/.adxc"
if [[ "${FORCE_MODE}" == "YES" ]]; then
    BASHRC_FILE="${USER_HOME}/.bashrc"
    touch "${BASHRC_FILE}"
    if ! grep -qF '# >>> adxc-demo auto activation >>>' "${BASHRC_FILE}"; then
        cat >> "${BASHRC_FILE}" <<'EOF_BASHRC'

# >>> adxc-demo auto activation >>>
if [ -f "${HOME}/.adxc/activate.sh" ]; then
    source "${HOME}/.adxc/activate.sh"
fi
# <<< adxc-demo auto activation <<<
EOF_BASHRC
    fi
    chown "${TARGET_USER}:${TARGET_USER}" "${BASHRC_FILE}" 2>/dev/null || chown "${TARGET_USER}" "${BASHRC_FILE}"
fi
printf 'adxc-demo enabled for user %s. Force mode: %s\n' "${TARGET_USER}" "${FORCE_MODE}"
