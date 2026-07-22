#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# adxc-demo operation binding runtime
# -----------------------------------------------------------------------------
# Operation configuration lives in:
#   profiles/<PROFILE>/operations/<menu>.conf
#
# Each operation can be:
#   none     - intentionally unconfigured
#   command  - command object in commands/<name>.cmd
#   script   - script path, global or profile-local or absolute
# -----------------------------------------------------------------------------

# shellcheck source=adxc-common.sh
source "${ADXC_ROOT_DIR}/lib/adxc-common.sh"

adxc_load_operation_file() {
    local profile_dir="$1"
    local menu_name="$2"
    local operation_file="${profile_dir}/operations/${menu_name}.conf"

    if [[ -f "${operation_file}" ]]; then
        # shellcheck source=/dev/null
        source "${operation_file}"
    fi
}

adxc_operation_status() {
    local type_value="$1"
    local ref_value="$2"

    if [[ -z "${type_value}" || "${type_value}" == "none" || -z "${ref_value}" ]]; then
        printf '%s' "UNCONFIGURED"
    else
        printf '%s' "CONFIGURED"
    fi
}

adxc_print_operation_line() {
    local label="$1"
    local description="$2"
    local type_value="$3"
    local ref_value="$4"
    local status
    local status_color

    status="$(adxc_operation_status "${type_value}" "${ref_value}")"
    status_color="$(adxc_status_color "${status}")"

    printf '%-24s %-42s %b%s%b\n' \
        "${label}" \
        "${description}" \
        "${status_color}" \
        "${status}" \
        "${ADXC_RESET}"
}

adxc_execute_operation() {
    local profile_name="$1"
    local operation_label="$2"
    local type_value="$3"
    local ref_value="$4"
    shift 4

    if [[ -z "${type_value}" || "${type_value}" == "none" || -z "${ref_value}" ]]; then
        adxc_print_warning "Operation is not configured: ${operation_label}"
        return 0
    fi

    case "${type_value}" in
        command)
            "${ADXC_ROOT_DIR}/bin/adxc-cmd" --run "${profile_name}" "${ref_value}" "$@"
            ;;
        script)
            local resolved_script
            resolved_script="$(adxc_relative_to_root "${ref_value}")"
            if [[ ! -x "${resolved_script}" ]]; then
                adxc_print_error "Script is not executable or missing: ${resolved_script}"
                return 1
            fi
            "${resolved_script}" "$@"
            ;;
        *)
            adxc_print_error "Unsupported operation type: ${type_value}"
            return 1
            ;;
    esac
}
