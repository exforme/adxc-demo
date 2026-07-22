#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# adxc-demo common runtime library
# -----------------------------------------------------------------------------

set -o pipefail

ADXC_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADXC_ROOT_DIR="$(cd "${ADXC_COMMON_DIR}/.." && pwd)"
ADXC_CONFIG_FILE="${ADXC_ROOT_DIR}/etc/adxc.conf"

if [[ -f "${ADXC_CONFIG_FILE}" ]]; then
    # shellcheck source=/dev/null
    source "${ADXC_CONFIG_FILE}"
fi

ADXC_PRODUCT_NAME="${ADXC_PRODUCT_NAME:-adxc-demo}"
ADXC_VERSION="${ADXC_VERSION:-unknown}"
ADXC_PROFILES_DIR="${ADXC_ROOT_DIR}/${ADXC_PROFILES_DIR_NAME:-profiles}"
ADXC_TEMPLATES_DIR="${ADXC_ROOT_DIR}/${ADXC_TEMPLATES_DIR_NAME:-templates}"
ADXC_COMMANDS_DIR="${ADXC_ROOT_DIR}/${ADXC_COMMANDS_DIR_NAME:-commands}"
ADXC_SCRIPTS_DIR="${ADXC_ROOT_DIR}/${ADXC_SCRIPTS_DIR_NAME:-scripts}"
ADXC_ARCHIVE_PROFILES_DIR="${ADXC_ROOT_DIR}/${ADXC_ARCHIVE_PROFILES_DIR_NAME:-archive/profiles}"
ADXC_ARCHIVE_COMMANDS_DIR="${ADXC_ROOT_DIR}/${ADXC_ARCHIVE_COMMANDS_DIR_NAME:-archive/commands}"
ADXC_COLOR_ENABLED="${ADXC_COLOR_ENABLED:-YES}"

# shellcheck source=adxc-colors.sh
source "${ADXC_ROOT_DIR}/lib/adxc-colors.sh"
adxc_init_colors

adxc_print_line() { printf '%s\n' '============================================================'; }

adxc_print_header() {
    local title="$1"
    adxc_print_line
    printf '%s\n' "${title}"
    adxc_print_line
}

adxc_print_error() { printf '%bERROR%b: %s\n' "${ADXC_RED}" "${ADXC_RESET}" "$1" >&2; }
adxc_print_warning() { printf '%bWARNING%b: %s\n' "${ADXC_YELLOW}" "${ADXC_RESET}" "$1"; }
adxc_print_success() { printf '%bSUCCESS%b: %s\n' "${ADXC_GREEN}" "${ADXC_RESET}" "$1"; }

adxc_pause() {
    printf '\nPress ENTER to continue... '
    read -r _unused_input || true
}

adxc_current_user() { id -un 2>/dev/null || printf '%s' 'unknown'; }
adxc_current_date() { date '+%Y-%m-%d %H:%M:%S'; }
adxc_sanitize_name() { local raw_name="$1"; printf '%s' "${raw_name}" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_.-'; }
adxc_sanitize_profile_name() { local raw_name="$1"; printf '%s' "${raw_name}" | tr '[:lower:]' '[:upper:]' | tr -cd 'A-Z0-9_.-'; }

adxc_load_profile_config() {
    local profile_dir="$1"
    local profile_config="${profile_dir}/profile.conf"

    PROFILE_NAME=""
    PROFILE_CLASS="UNKNOWN"
    PROFILE_TEMPLATE="unknown"
    PROFILE_DESCRIPTION=""
    PROFILE_ENABLED="NO"
    PROFILE_STATUS="UNKNOWN"
    PROFILE_CREATED_BY="unknown"
    PROFILE_CREATED_DATE="unknown"
    PROFILE_ARCHIVED_BY=""
    PROFILE_ARCHIVED_DATE=""

    if [[ -f "${profile_config}" ]]; then
        # shellcheck source=/dev/null
        source "${profile_config}"
    fi

    if [[ -z "${PROFILE_NAME}" ]]; then
        PROFILE_NAME="$(basename "${profile_dir}")"
    fi
}

adxc_load_template_config() {
    local template_name="$1"
    local template_config="${ADXC_TEMPLATES_DIR}/${template_name}/template.conf"

    TEMPLATE_NAME="${template_name}"
    TEMPLATE_CLASS="UNKNOWN"
    TEMPLATE_DESCRIPTION=""
    TEMPLATE_VERSION="1.0"

    if [[ -f "${template_config}" ]]; then
        # shellcheck source=/dev/null
        source "${template_config}"
    fi
}

adxc_load_command_file() {
    local command_file="$1"

    COMMAND_NAME=""
    COMMAND_TYPE="unknown"
    COMMAND_DESCRIPTION=""
    COMMAND_ENABLED="NO"
    COMMAND_STATUS="UNKNOWN"
    COMMAND_CREATED_BY="unknown"
    COMMAND_CREATED_DATE="unknown"
    COMMAND_ARCHIVED_BY=""
    COMMAND_ARCHIVED_DATE=""
    COMMAND_LINE=""
    SCRIPT_PATH=""

    if [[ -f "${command_file}" ]]; then
        # shellcheck source=/dev/null
        source "${command_file}"
    fi

    if [[ -z "${COMMAND_NAME}" ]]; then
        COMMAND_NAME="$(basename "${command_file}" .cmd)"
    fi
}

adxc_relative_to_root() {
    local input_path="$1"

    if [[ "${input_path}" = /* ]]; then
        printf '%s' "${input_path}"
    else
        printf '%s/%s' "${ADXC_ROOT_DIR}" "${input_path}"
    fi
}

adxc_profile_dir_by_name() {
    local profile_name="$1"
    printf '%s/%s' "${ADXC_PROFILES_DIR}" "${profile_name}"
}
