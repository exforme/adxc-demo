#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# adxc-demo Command Management library
# -----------------------------------------------------------------------------
# Command objects are stored once in commands/*.cmd and attached to profiles.

# shellcheck source=adxc-common.sh
source "${ADXC_ROOT_DIR}/lib/adxc-common.sh"
# shellcheck source=adxc-profile-management.sh
source "${ADXC_ROOT_DIR}/lib/adxc-profile-management.sh"

adxc_command_management_menu() {
    while true; do
        clear 2>/dev/null || true
        adxc_print_header "adxc-demo ADMINISTRATION - COMMAND MANAGEMENT"
        printf '[1] Create Command\n'
        printf '[2] List Commands\n'
        printf '[3] Attach Command\n'
        printf '[4] Retire Command\n'
        printf '[5] Restore Retired Command\n'
        printf '[0] Back\n'
        printf '\nSelect option: '
        read -r selected_option || return 0
        case "${selected_option}" in
            1) adxc_create_command_wizard; adxc_pause ;;
            2) adxc_list_commands_screen; adxc_pause ;;
            3) adxc_attach_command_wizard; adxc_pause ;;
            4) adxc_print_warning "Retire Command workflow retained for demo but not expanded in this menu."; adxc_pause ;;
            5) adxc_print_warning "Restore Command workflow retained for demo but not expanded in this menu."; adxc_pause ;;
            0) return 0 ;;
            *) adxc_print_warning "Invalid option selected."; adxc_pause ;;
        esac
    done
}

adxc_collect_command_files() {
    find "${ADXC_COMMANDS_DIR}" -mindepth 1 -maxdepth 1 -type f -name '*.cmd' -printf '%f\n' 2>/dev/null | sort
}

adxc_create_command_wizard() {
    local command_name_raw command_name command_type_selection command_type command_description command_line script_path confirmation
    clear 2>/dev/null || true
    adxc_print_header "CREATE COMMAND WIZARD"
    printf 'Command name: '
    read -r command_name_raw || return 1
    command_name="$(adxc_sanitize_name "${command_name_raw}")"
    [[ -n "${command_name}" ]] || { adxc_print_error "Command name cannot be empty."; return 1; }

    printf '\n[1] Single Command\n[2] External Script\n\nSelect command type: '
    read -r command_type_selection || return 1
    case "${command_type_selection}" in
        1) command_type="single-command" ;;
        2) command_type="external-script" ;;
        *) adxc_print_error "Invalid command type."; return 1 ;;
    esac

    printf 'Description: '
    read -r command_description || true

    if [[ "${command_type}" == "single-command" ]]; then
        printf 'Command line: '
        read -r command_line || return 1
        [[ -n "${command_line}" ]] || { adxc_print_error "Command line cannot be empty."; return 1; }
    else
        printf 'Script path: '
        read -r script_path || return 1
        [[ -n "${script_path}" ]] || { adxc_print_error "Script path cannot be empty."; return 1; }
    fi

    printf 'Type CREATE to create command: '
    read -r confirmation || return 1
    [[ "${confirmation}" == "CREATE" ]] || { adxc_print_warning "Command creation cancelled."; return 0; }

    if [[ "${command_type}" == "single-command" ]]; then
        adxc_create_single_command "${command_name}" "${command_description}" "${command_line}"
    else
        adxc_create_external_script_command "${command_name}" "${command_description}" "${script_path}"
    fi
}

adxc_create_single_command() {
    local command_name="$1" command_description="$2" command_line="$3" command_file="${ADXC_COMMANDS_DIR}/${command_name}.cmd"
    cat > "${command_file}" <<EOF_COMMAND
#!/usr/bin/env bash
COMMAND_NAME="${command_name}"
COMMAND_TYPE="single-command"
COMMAND_DESCRIPTION="${command_description}"
COMMAND_ENABLED="YES"
COMMAND_STATUS="ACTIVE"
COMMAND_CREATED_BY="$(adxc_current_user)"
COMMAND_CREATED_DATE="$(adxc_current_date)"
COMMAND_LINE='${command_line}'
main() { eval "\${COMMAND_LINE}"; }
main "\$@"
EOF_COMMAND
    chmod +x "${command_file}"
    adxc_print_success "Command ${command_name} created."
}

adxc_create_external_script_command() {
    local command_name="$1" command_description="$2" script_path="$3" command_file="${ADXC_COMMANDS_DIR}/${command_name}.cmd"
    cat > "${command_file}" <<EOF_COMMAND
#!/usr/bin/env bash
COMMAND_NAME="${command_name}"
COMMAND_TYPE="external-script"
COMMAND_DESCRIPTION="${command_description}"
COMMAND_ENABLED="YES"
COMMAND_STATUS="ACTIVE"
COMMAND_CREATED_BY="$(adxc_current_user)"
COMMAND_CREATED_DATE="$(adxc_current_date)"
SCRIPT_PATH="${script_path}"
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"
ADXC_ROOT_DIR="\${SCRIPT_DIR}"
source "\${ADXC_ROOT_DIR}/lib/adxc-common.sh"
main() {
    local resolved_script
    resolved_script="\$(adxc_relative_to_root "\${SCRIPT_PATH}")"
    [[ -x "\${resolved_script}" ]] || { printf 'ERROR: Script is not executable or missing: %s\n' "\${resolved_script}" >&2; exit 1; }
    "\${resolved_script}" "\$@"
}
main "\$@"
EOF_COMMAND
    chmod +x "${command_file}"
    adxc_print_success "Command ${command_name} created."
}

adxc_list_commands_screen() {
    clear 2>/dev/null || true
    adxc_print_header "LIST COMMANDS"
    local command_file
    for command_file in "${ADXC_COMMANDS_DIR}"/*.cmd; do
        [[ -f "${command_file}" ]] || continue
        adxc_load_command_file "${command_file}"
        printf '%-28s %-18s %s\n' "${COMMAND_NAME}" "${COMMAND_TYPE}" "${COMMAND_DESCRIPTION}"
    done
}

adxc_select_command_file() {
    local selected_number command_files=()
    mapfile -t command_files < <(adxc_collect_command_files)
    [[ "${#command_files[@]}" -gt 0 ]] || { adxc_print_error "No commands available."; return 1; }
    local index=1 command_file_name
    for command_file_name in "${command_files[@]}"; do
        adxc_load_command_file "${ADXC_COMMANDS_DIR}/${command_file_name}"
        printf '[%d] %-24s %s\n' "${index}" "${COMMAND_NAME}" "${COMMAND_DESCRIPTION}"
        index=$((index + 1))
    done
    printf '\nSelect command number: '
    read -r selected_number || return 1
    if ! [[ "${selected_number}" =~ ^[0-9]+$ ]] || (( selected_number < 1 || selected_number > ${#command_files[@]} )); then
        adxc_print_error "Command selection is out of range."
        return 1
    fi
    SELECTED_COMMAND_FILE="${ADXC_COMMANDS_DIR}/${command_files[$((selected_number - 1))]}"
}

adxc_attach_command_wizard() {
    local profile_dir profile_name command_name link_file confirmation
    clear 2>/dev/null || true
    adxc_print_header "ATTACH COMMAND TO PROFILE"
    adxc_select_active_profile "Select profile" || return 1
    profile_dir="${SELECTED_PROFILE_DIR}"
    adxc_load_profile_config "${profile_dir}"
    profile_name="${PROFILE_NAME}"
    adxc_select_command_file || return 1
    adxc_load_command_file "${SELECTED_COMMAND_FILE}"
    command_name="${COMMAND_NAME}"
    link_file="${profile_dir}/commands/${command_name}.link"
    printf 'Type ATTACH to attach %s to %s: ' "${command_name}" "${profile_name}"
    read -r confirmation || return 1
    [[ "${confirmation}" == "ATTACH" ]] || { adxc_print_warning "Attach cancelled."; return 0; }
    cat > "${link_file}" <<EOF_LINK
COMMAND_NAME="${command_name}"
COMMAND_FILE="commands/${command_name}.cmd"
ATTACHED_BY="$(adxc_current_user)"
ATTACHED_DATE="$(adxc_current_date)"
EOF_LINK
    adxc_print_success "Attached command ${command_name} to profile ${profile_name}."
}
