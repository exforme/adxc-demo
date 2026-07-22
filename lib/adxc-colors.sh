#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# adxc-demo color helper library
# -----------------------------------------------------------------------------

ADXC_RESET=""
ADXC_BOLD=""
ADXC_GREEN=""
ADXC_YELLOW=""
ADXC_RED=""
ADXC_CYAN=""
ADXC_BLUE=""
ADXC_GRAY=""

adxc_init_colors() {
    if [[ "${ADXC_COLOR_ENABLED:-YES}" == "YES" && -t 1 ]]; then
        ADXC_RESET=$'\033[0m'
        ADXC_BOLD=$'\033[1m'
        ADXC_GREEN=$'\033[32m'
        ADXC_YELLOW=$'\033[33m'
        ADXC_RED=$'\033[31m'
        ADXC_CYAN=$'\033[36m'
        ADXC_BLUE=$'\033[34m'
        ADXC_GRAY=$'\033[90m'
    fi
}

adxc_status_color() {
    local status="$1"

    case "${status}" in
        ACTIVE|ENABLED|HEALTHY|YES|READY|CONFIGURED)
            printf '%s' "${ADXC_GREEN}"
            ;;
        DISABLED|WARNING|WARN|UNCONFIGURED)
            printf '%s' "${ADXC_YELLOW}"
            ;;
        ARCHIVED|INFO|ATTACHED)
            printf '%s' "${ADXC_CYAN}"
            ;;
        ERROR|FAILED|NO|UNKNOWN)
            printf '%s' "${ADXC_RED}"
            ;;
        *)
            printf '%s' "${ADXC_RESET}"
            ;;
    esac
}
