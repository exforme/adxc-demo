#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# adxc-demo installer
# -----------------------------------------------------------------------------
# Performs root validation, source validation, syntax checks, backup, copy,
# ownership, permissions, optional root activation and final summary.

set -euo pipefail

ADXC_VERSION="1.0"
DEFAULT_INSTALL_DIR="/opt/adxc"
INSTALL_DIR="${DEFAULT_INSTALL_DIR}"
ACTIVATE_ROOT="NO"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_line() { printf '%s\n' '============================================================'; }
print_error() { printf 'ERROR: %s\n' "$1" >&2; }

require_root() { [[ "$(id -u)" -eq 0 ]] || { print_error "adxc-demo installation must be executed as root."; exit 1; }; }

parse_arguments() {
    for argument in "$@"; do
        case "${argument}" in
            --activate-root) ACTIVATE_ROOT="YES" ;;
            --help|-h) printf 'Usage: ./install.sh [install-dir] [--activate-root]\n'; exit 0 ;;
            /*) INSTALL_DIR="${argument}" ;;
            *) print_error "Unknown option: ${argument}"; exit 1 ;;
        esac
    done
}

validate_source_tree() {
    local required_paths=(
        "bin/adxc" "bin/adxc-admin" "bin/adxc-cmd" "bin/adxc-help" "bin/adxc-os"
        "admin/adxc-enable-user.sh" "admin/adxc-disable-user.sh"
        "lib/adxc-common.sh" "lib/adxc-colors.sh" "lib/adxc-dashboard-miqm.sh"
        "lib/adxc-operation-management.sh" "etc/adxc.conf" "install.sh" "uninstall.sh"
        "VERSION" "README.md" "MANIFEST.md"
    )
    local relative_path
    printf 'Validating installation source tree...\n'
    for relative_path in "${required_paths[@]}"; do
        [[ -e "${SOURCE_DIR}/${relative_path}" ]] || { print_error "Package corruption detected. Missing: ${relative_path}"; exit 1; }
    done
    printf 'Source tree validation completed.\n'
}

validate_shell_syntax() {
    printf 'Validating shell syntax...\n'
    local script_file
    while IFS= read -r script_file; do
        bash -n "${script_file}" || { print_error "Shell syntax failed: ${script_file#${SOURCE_DIR}/}"; exit 1; }
        printf '  OK %s\n' "${script_file#${SOURCE_DIR}/}"
    done < <(find "${SOURCE_DIR}" -type f \( -name '*.sh' -o -name '*.cmd' -o -path '*/bin/*' -o -path '*/admin/*' -o -path '*/lib/*' \) ! -path '*/logs/*' | sort)
}

backup_existing_installation() {
    [[ -d "${INSTALL_DIR}" ]] || return 0
    local backup_dir="${INSTALL_DIR}.backup.$(date '+%Y%m%d_%H%M%S')"
    printf 'Existing installation detected: %s\n' "${INSTALL_DIR}"
    printf 'Creating backup: %s\n' "${backup_dir}"
    mv "${INSTALL_DIR}" "${backup_dir}"
}

copy_source_tree() { printf 'Installing files to %s\n' "${INSTALL_DIR}"; mkdir -p "${INSTALL_DIR}"; cp -R "${SOURCE_DIR}/." "${INSTALL_DIR}/"; }

set_ownership_and_permissions() {
    printf 'Applying ownership and permissions...\n'
    chown -R root:root "${INSTALL_DIR}"
    find "${INSTALL_DIR}" -type d -exec chmod 0755 {} \;
    find "${INSTALL_DIR}" -type f -exec chmod 0644 {} \;
    find "${INSTALL_DIR}/bin" -type f -exec chmod 0755 {} \;
    find "${INSTALL_DIR}/admin" -type f -exec chmod 0755 {} \;
    find "${INSTALL_DIR}" -type f -name '*.sh' -exec chmod 0755 {} \;
    find "${INSTALL_DIR}" -type f -name '*.cmd' -exec chmod 0755 {} \;
    chmod 0755 "${INSTALL_DIR}/install.sh" "${INSTALL_DIR}/uninstall.sh"
}

create_command_symlinks() {
    local command_name
    for command_name in adxc adxc-admin adxc-help adxc-cmd adxc-os; do
        ln -sf "${INSTALL_DIR}/bin/${command_name}" "/usr/local/bin/${command_name}" 2>/dev/null || true
    done
}

activate_root_runtime() {
    [[ "${ACTIVATE_ROOT}" == "YES" ]] || return 0
    mkdir -p /root/.adxc
    cp "${INSTALL_DIR}/templates/user-home/adxc-runtime/activate.sh" /root/.adxc/activate.sh
}

print_install_summary() {
    print_line
    printf 'adxc-demo installation completed\n'
    print_line
    printf '\nVersion:\n  %s\n' "${ADXC_VERSION}"
    printf '\nInstalled location:\n  %s\n' "${INSTALL_DIR}"
    printf '\nTemplate source:\n  %s/templates/user-home/adxc-runtime\n' "${INSTALL_DIR}"
    printf '\nNext step - enable selected user:\n  %s/admin/adxc-enable-user.sh <user>\n' "${INSTALL_DIR}"
    printf '\nForce activation:\n  %s/admin/adxc-enable-user.sh --force mqm\n' "${INSTALL_DIR}"
    printf '\nUser activation after enablement:\n  source ~/.adxc/activate.sh\n  adxc\n'
    print_line
}

main() {
    parse_arguments "$@"
    require_root
    validate_source_tree
    validate_shell_syntax
    backup_existing_installation
    copy_source_tree
    set_ownership_and_permissions
    create_command_symlinks
    activate_root_runtime
    print_install_summary
}

main "$@"
