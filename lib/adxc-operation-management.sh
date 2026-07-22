#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# adxc-demo Operation Configuration Management
# -----------------------------------------------------------------------------

# shellcheck source=adxc-common.sh
source "${ADXC_ROOT_DIR}/lib/adxc-common.sh"
# shellcheck source=adxc-profile-management.sh
source "${ADXC_ROOT_DIR}/lib/adxc-profile-management.sh"
# shellcheck source=adxc-command-management.sh
source "${ADXC_ROOT_DIR}/lib/adxc-command-management.sh"

adxc_operation_management_menu() {
    while true; do
        clear 2>/dev/null || true
        adxc_print_header "adxc-demo ADMINISTRATION - OPERATION CONFIGURATION"
        printf '[1] List Profile Operations\n'
        printf '[2] Configure Control Operation\n'
        printf '[3] Clear Control Operation\n'
        printf '[0] Back\n'
        printf '\nSelect option: '
        read -r selected_option || return 0
        case "${selected_option}" in
            1) adxc_operation_list_profile; adxc_pause ;;
            2) adxc_operation_configure_control; adxc_pause ;;
            3) adxc_operation_clear_control; adxc_pause ;;
            0) return 0 ;;
            *) adxc_print_warning "Invalid option selected."; adxc_pause ;;
        esac
    done
}

adxc_operation_select_control_key() {
    local selected
    printf '[1] Start Node\n'
    printf '[2] Stop Node\n'
    printf '[3] Manual Failover\n'
    printf '\nSelect operation: '
    read -r selected || return 1
    case "${selected}" in
        1) OP_KEY="CONTROL_START_NODE" ;;
        2) OP_KEY="CONTROL_STOP_NODE" ;;
        3) OP_KEY="CONTROL_FAILOVER" ;;
        *) adxc_print_error "Invalid operation."; return 1 ;;
    esac
}

adxc_operation_update_value() {
    local file="$1" key="$2" type_value="$3" ref_value="$4"
    python3 - "$file" "$key" "$type_value" "$ref_value" <<'PY_UPDATE'
from pathlib import Path
import sys
path = Path(sys.argv[1])
key = sys.argv[2]
type_value = sys.argv[3]
ref_value = sys.argv[4]
text = path.read_text() if path.exists() else ""
updates = {key + "_TYPE": type_value, key + "_REF": ref_value}
for name, value in updates.items():
    lines = []
    found = False
    for line in text.splitlines():
        if line.startswith(name + "="):
            lines.append(f'{name}="{value}"')
            found = True
        else:
            lines.append(line)
    if not found:
        lines.append(f'{name}="{value}"')
    text = "\n".join(lines) + "\n"
path.write_text(text)
PY_UPDATE
}

adxc_operation_list_profile() {
    adxc_select_active_profile "Select profile" || return 1
    local profile_dir="${SELECTED_PROFILE_DIR}"
    adxc_load_profile_config "${profile_dir}"
    clear 2>/dev/null || true
    adxc_print_header "OPERATIONS : ${PROFILE_NAME}"
    for file in "${profile_dir}/operations"/*.conf; do
        [[ -f "${file}" ]] || continue
        printf '\n%s\n' "$(basename "${file}")"
        grep -E '_(TYPE|REF)=' "${file}" || true
    done
}

adxc_operation_configure_control() {
    local profile_dir operation_file implementation script_path
    adxc_select_active_profile "Select profile" || return 1
    profile_dir="${SELECTED_PROFILE_DIR}"
    adxc_load_profile_config "${profile_dir}"
    operation_file="${profile_dir}/operations/control.conf"
    adxc_operation_select_control_key || return 1
    printf '\n[1] Attach Command\n[2] Attach Script\n[3] Leave Unconfigured\n\nSelect implementation: '
    read -r implementation || return 1
    case "${implementation}" in
        1)
            adxc_select_command_file || return 1
            adxc_load_command_file "${SELECTED_COMMAND_FILE}"
            adxc_operation_update_value "${operation_file}" "${OP_KEY}" "command" "${COMMAND_NAME}"
            adxc_print_success "Configured ${OP_KEY} as command ${COMMAND_NAME}."
            ;;
        2)
            printf 'Script path: '
            read -r script_path || return 1
            adxc_operation_update_value "${operation_file}" "${OP_KEY}" "script" "${script_path}"
            adxc_print_success "Configured ${OP_KEY} as script ${script_path}."
            ;;
        3)
            adxc_operation_update_value "${operation_file}" "${OP_KEY}" "none" ""
            adxc_print_success "Left ${OP_KEY} unconfigured."
            ;;
        *) adxc_print_error "Invalid implementation."; return 1 ;;
    esac
}

adxc_operation_clear_control() {
    local profile_dir operation_file
    adxc_select_active_profile "Select profile" || return 1
    profile_dir="${SELECTED_PROFILE_DIR}"
    operation_file="${profile_dir}/operations/control.conf"
    adxc_operation_select_control_key || return 1
    adxc_operation_update_value "${operation_file}" "${OP_KEY}" "none" ""
    adxc_print_success "Cleared ${OP_KEY}."
}
