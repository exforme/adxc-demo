#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# adxc-demo Profile Management library
# -----------------------------------------------------------------------------

# shellcheck source=adxc-common.sh
source "${ADXC_ROOT_DIR}/lib/adxc-common.sh"

adxc_profile_management_menu() {
    while true; do
        clear 2>/dev/null || true
        adxc_print_header "adxc-demo ADMINISTRATION - PROFILE MANAGEMENT"
        printf '[1] Create Profile\n'
        printf '[2] List Profiles\n'
        printf '[3] Delete Profile\n'
        printf '[4] Restore Archived Profile\n'
        printf '[0] Back\n'
        printf '\nSelect option: '
        read -r selected_option || return 0

        case "${selected_option}" in
            1) adxc_create_profile_wizard; adxc_pause ;;
            2) adxc_list_profiles_screen; adxc_pause ;;
            3) adxc_delete_profile_wizard; adxc_pause ;;
            4) adxc_restore_profile_wizard; adxc_pause ;;
            0) return 0 ;;
            *) adxc_print_warning "Invalid option selected."; adxc_pause ;;
        esac
    done
}

adxc_collect_templates() {
    find "${ADXC_TEMPLATES_DIR}" -mindepth 1 -maxdepth 1 -type d \
        ! -name 'user-home' \
        ! -name 'profile-templates' \
        ! -name 'command-templates' \
        -printf '%f\n' | sort
}

adxc_copy_template_operations() {
    local template_name="$1"
    local profile_dir="$2"

    mkdir -p "${profile_dir}/operations"
    if [[ -d "${ADXC_TEMPLATES_DIR}/${template_name}/operations" ]]; then
        cp "${ADXC_TEMPLATES_DIR}/${template_name}/operations/"*.conf "${profile_dir}/operations/" 2>/dev/null || true
    fi
}

adxc_create_profile_wizard() {
    local templates=()
    local selected_number
    local selected_template
    local profile_name_raw
    local profile_name
    local profile_description
    local confirmation

    clear 2>/dev/null || true
    adxc_print_header "CREATE PROFILE WIZARD"

    mapfile -t templates < <(adxc_collect_templates)

    if [[ "${#templates[@]}" -eq 0 ]]; then
        adxc_print_error "No templates found in ${ADXC_TEMPLATES_DIR}."
        return 1
    fi

    printf 'Step 1: Choose a template\n\n'

    local index=1
    local template_name
    for template_name in "${templates[@]}"; do
        adxc_load_template_config "${template_name}"
        printf '[%d] %-20s %-14s %s\n' "${index}" "${TEMPLATE_NAME}" "${TEMPLATE_CLASS}" "${TEMPLATE_DESCRIPTION}"
        index=$((index + 1))
    done

    printf '\nSelect template number: '
    read -r selected_number || return 1

    if ! [[ "${selected_number}" =~ ^[0-9]+$ ]]; then
        adxc_print_error "Selection must be a number."
        return 1
    fi

    if (( selected_number < 1 || selected_number > ${#templates[@]} )); then
        adxc_print_error "Template selection is out of range."
        return 1
    fi

    selected_template="${templates[$((selected_number - 1))]}"
    adxc_load_template_config "${selected_template}"

    printf '\nStep 2: Profile name\n'
    printf 'Enter profile name, for example TQM1: '
    read -r profile_name_raw || return 1
    profile_name="$(adxc_sanitize_profile_name "${profile_name_raw}")"

    if [[ -z "${profile_name}" ]]; then
        adxc_print_error "Profile name cannot be empty."
        return 1
    fi

    if [[ -d "${ADXC_PROFILES_DIR}/${profile_name}" ]]; then
        adxc_print_error "Profile ${profile_name} already exists."
        return 1
    fi

    printf '\nStep 3: Profile description\n'
    printf 'Enter description, or leave empty: '
    read -r profile_description || true

    printf '\nReview\n'
    printf '  Class       : %s\n' "${TEMPLATE_CLASS}"
    printf '  Template    : %s\n' "${TEMPLATE_NAME}"
    printf '  Name        : %s\n' "${profile_name}"
    printf '  Description : %s\n' "${profile_description:-N/A}"
    printf '\nCreate this profile? Type CREATE to continue: '
    read -r confirmation || return 1

    if [[ "${confirmation}" != "CREATE" ]]; then
        adxc_print_warning "Profile creation cancelled."
        return 0
    fi

    adxc_create_profile_from_template "${TEMPLATE_NAME}" "${TEMPLATE_CLASS}" "${profile_name}" "${profile_description}"
}

adxc_create_profile_from_template() {
    local template_name="$1"
    local profile_class="$2"
    local profile_name="$3"
    local profile_description="$4"
    local profile_dir="${ADXC_PROFILES_DIR}/${profile_name}"

    mkdir -p "${profile_dir}"/{commands,scripts,logs,operations}
    adxc_copy_template_operations "${template_name}" "${profile_dir}"

    cat > "${profile_dir}/profile.conf" <<EOF_PROFILE
# -----------------------------------------------------------------------------
# adxc-demo profile configuration
# -----------------------------------------------------------------------------
PROFILE_NAME="${profile_name}"
PROFILE_CLASS="${profile_class}"
PROFILE_TEMPLATE="${template_name}"
PROFILE_DESCRIPTION="${profile_description}"
PROFILE_ENABLED="YES"
PROFILE_STATUS="ACTIVE"
PROFILE_CREATED_BY="$(adxc_current_user)"
PROFILE_CREATED_DATE="$(adxc_current_date)"
PROFILE_ARCHIVED_BY=""
PROFILE_ARCHIVED_DATE=""
EOF_PROFILE

    printf '# %s attached commands\n' "${profile_name}" > "${profile_dir}/commands/README.md"
    printf '# %s profile-local scripts\n' "${profile_name}" > "${profile_dir}/scripts/README.md"
    printf '# %s runtime logs\n' "${profile_name}" > "${profile_dir}/logs/README.md"
    adxc_print_success "Profile ${profile_name} created as ${profile_class} from template ${template_name}."
}

adxc_print_profile_table() {
    local source_dir="$1"
    local table_title="$2"
    local profile_dirs=()

    printf '%s\n' "${table_title}"
    printf '%-4s %-14s %-24s %-12s %-18s %s\n' 'ID' 'CLASS' 'PROFILE' 'STATUS' 'TEMPLATE' 'DESCRIPTION'
    printf '%-4s %-14s %-24s %-12s %-18s %s\n' '--' '-----' '-------' '------' '--------' '-----------'

    mapfile -t profile_dirs < <(find "${source_dir}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
    if [[ "${#profile_dirs[@]}" -eq 0 ]]; then
        printf 'No profiles found.\n'
        return 0
    fi

    local index=1
    local profile_dir
    local status_color
    for profile_dir in "${profile_dirs[@]}"; do
        adxc_load_profile_config "${profile_dir}"
        status_color="$(adxc_status_color "${PROFILE_STATUS}")"
        printf '%-4s %-14s %-24s %b%-12s%b %-18s %s\n' \
            "${index}" "${PROFILE_CLASS}" "${PROFILE_NAME}" "${status_color}" "${PROFILE_STATUS}" "${ADXC_RESET}" "${PROFILE_TEMPLATE}" "${PROFILE_DESCRIPTION}"
        index=$((index + 1))
    done
}

adxc_list_profiles_screen() {
    clear 2>/dev/null || true
    adxc_print_header "LIST PROFILES"
    adxc_print_profile_table "${ADXC_PROFILES_DIR}" "ACTIVE AND DISABLED PROFILES"
    printf '\n'
    adxc_print_profile_table "${ADXC_ARCHIVE_PROFILES_DIR}" "ARCHIVED PROFILES"
}

adxc_select_active_profile() {
    local prompt_title="$1"
    local selected_number
    local profile_dirs=()

    mapfile -t profile_dirs < <(find "${ADXC_PROFILES_DIR}" -mindepth 1 -maxdepth 1 -type d | sort)
    if [[ "${#profile_dirs[@]}" -eq 0 ]]; then
        adxc_print_error "No active profiles found."
        return 1
    fi

    printf '%s\n\n' "${prompt_title}"
    local index=1
    local profile_dir
    for profile_dir in "${profile_dirs[@]}"; do
        adxc_load_profile_config "${profile_dir}"
        printf '[%d] %-14s %s\n' "${index}" "${PROFILE_CLASS}" "${PROFILE_NAME}"
        index=$((index + 1))
    done

    printf '\nSelect profile number: '
    read -r selected_number || return 1
    if ! [[ "${selected_number}" =~ ^[0-9]+$ ]] || (( selected_number < 1 || selected_number > ${#profile_dirs[@]} )); then
        adxc_print_error "Profile selection is out of range."
        return 1
    fi
    SELECTED_PROFILE_DIR="${profile_dirs[$((selected_number - 1))]}"
}

# Archive/delete/restore are intentionally compact but readable for the demo.
adxc_delete_profile_wizard() {
    adxc_print_warning "Profile archive/delete workflow is available in rc7 and retained conceptually in demo 1.0."
}

adxc_restore_profile_wizard() {
    adxc_print_warning "Profile restore workflow is available in rc7 and retained conceptually in demo 1.0."
}
