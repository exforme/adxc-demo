#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# adxc-demo MIQM dashboard library
# -----------------------------------------------------------------------------
# Provides the profile dashboard and operational menu screens for mq_miqm.

# shellcheck source=adxc-common.sh
source "${ADXC_ROOT_DIR}/lib/adxc-common.sh"
# shellcheck source=adxc-operations.sh
source "${ADXC_ROOT_DIR}/lib/adxc-operations.sh"

adxc_miqm_status_banner() {
    local profile_name="$1"

    # Demo-safe status line. In a real MIQM environment, this can be replaced by
    # an operation binding or enhanced script that runs dspmq -x and parses state.
    printf 'ACTIVE | QM=%s | STANDBY=<auto-detect> | HEALTH=DEMO\n' "${profile_name}"
    printf 'CH=<n/a> | DLQ=<n/a> | ERRORS=<n/a> | FAILOVER=<configured-by-profile>\n'
}

adxc_miqm_profile_dashboard() {
    local profile_name="$1"
    local profile_dir

    profile_dir="$(adxc_profile_dir_by_name "${profile_name}")"
    adxc_load_profile_config "${profile_dir}"

    adxc_print_header "PROFILE : ${PROFILE_NAME}"
    adxc_miqm_status_banner "${PROFILE_NAME}"
    printf '\n'
    printf '[1] Control             Operations affecting MQ availability\n'
    printf '[2] Troubleshooting     Diagnostics, logs and health checks\n'
    printf '[3] Checks              MQ object inspection and runtime data\n'
    printf '[4] Maintenance         Backup, export and housekeeping\n'
    printf '[5] Custom Commands     Profile-specific extensions\n'
    printf '\nUsage:\n'
    printf '  adxc %s control\n' "${PROFILE_NAME}"
    printf '  adxc %s troubleshooting\n' "${PROFILE_NAME}"
    printf '  adxc %s checks\n' "${PROFILE_NAME}"
    printf '  adxc %s maintenance\n' "${PROFILE_NAME}"
    printf '  adxc %s custom\n' "${PROFILE_NAME}"
}

adxc_miqm_control_dashboard() {
    local profile_name="$1"
    local profile_dir

    profile_dir="$(adxc_profile_dir_by_name "${profile_name}")"
    adxc_load_profile_config "${profile_dir}"
    adxc_load_operation_file "${profile_dir}" "control"

    adxc_print_header "${PROFILE_NAME} - CONTROL"
    printf 'STATUS\n\n'
    adxc_miqm_status_banner "${PROFILE_NAME}"
    printf '\nNode Control\n\n'
    printf '[1] Start Node          Start queue manager on this node\n'
    printf '[2] Stop Node           Gracefully stop active queue manager\n'
    printf '[3] Manual Failover     Trigger controlled MIQM failover\n'
    printf '\nConfiguration\n\n'
    adxc_print_operation_line "Start Node" "Profile-bound operation" "${CONTROL_START_NODE_TYPE:-none}" "${CONTROL_START_NODE_REF:-}"
    adxc_print_operation_line "Stop Node" "Profile-bound operation" "${CONTROL_STOP_NODE_TYPE:-none}" "${CONTROL_STOP_NODE_REF:-}"
    adxc_print_operation_line "Manual Failover" "Profile-bound operation" "${CONTROL_FAILOVER_TYPE:-none}" "${CONTROL_FAILOVER_REF:-}"
    printf '\n[b] Back\n[q] Exit\n'
}

adxc_miqm_troubleshooting_dashboard() {
    local profile_name="$1"
    local profile_dir

    profile_dir="$(adxc_profile_dir_by_name "${profile_name}")"
    adxc_load_profile_config "${profile_dir}"
    adxc_load_operation_file "${profile_dir}" "troubleshooting"

    adxc_print_header "${PROFILE_NAME} - TROUBLESHOOTING"
    printf 'Logs\n\n'
    printf '[1] Queue Manager Logs      Logs per queue manager\n'
    printf '[2] FDC Files               IBM MQ FDC collection\n'
    printf '\nAnalysis\n\n'
    printf '[3] Error Scan              Search MQ logs for errors\n'
    printf '[4] MQ Diagnostics          Diagnostic command or script\n'
    printf '\nConfiguration\n\n'
    adxc_print_operation_line "Logs" "Profile-bound operation" "${TROUBLESHOOT_LOGS_TYPE:-none}" "${TROUBLESHOOT_LOGS_REF:-}"
    adxc_print_operation_line "FDC" "Profile-bound operation" "${TROUBLESHOOT_FDC_TYPE:-none}" "${TROUBLESHOOT_FDC_REF:-}"
    adxc_print_operation_line "Error Scan" "Profile-bound operation" "${TROUBLESHOOT_ERROR_SCAN_TYPE:-none}" "${TROUBLESHOOT_ERROR_SCAN_REF:-}"
    adxc_print_operation_line "MQ Diagnostics" "Profile-bound operation" "${TROUBLESHOOT_MQ_DIAGNOSTICS_TYPE:-none}" "${TROUBLESHOOT_MQ_DIAGNOSTICS_REF:-}"
    printf '\n[b] Back\n[q] Exit\n'
}

adxc_miqm_checks_dashboard() {
    local profile_name="$1"
    local profile_dir

    profile_dir="$(adxc_profile_dir_by_name "${profile_name}")"
    adxc_load_profile_config "${profile_dir}"
    adxc_load_operation_file "${profile_dir}" "checks"

    adxc_print_header "${PROFILE_NAME} - CHECKS"
    printf '[1] Queue Manager Status    Queue manager runtime state\n'
    printf '[2] Channels Running        Channel runtime validation\n'
    printf '[3] Listener Status         Listener availability\n'
    printf '[4] Queues With Messages    Non-SYSTEM queues with messages\n'
    printf '[5] Cluster Status          Active, standby and QM state\n'
    printf '[6] Cluster Readiness       Validate failover readiness\n'
    printf '\nConfiguration\n\n'
    adxc_print_operation_line "QM Status" "Profile-bound operation" "${CHECK_QM_STATUS_TYPE:-none}" "${CHECK_QM_STATUS_REF:-}"
    adxc_print_operation_line "Channels" "Profile-bound operation" "${CHECK_CHANNELS_TYPE:-none}" "${CHECK_CHANNELS_REF:-}"
    adxc_print_operation_line "Listeners" "Profile-bound operation" "${CHECK_LISTENERS_TYPE:-none}" "${CHECK_LISTENERS_REF:-}"
    adxc_print_operation_line "Queues" "Profile-bound operation" "${CHECK_QUEUES_TYPE:-none}" "${CHECK_QUEUES_REF:-}"
    adxc_print_operation_line "Cluster Status" "Profile-bound operation" "${CHECK_CLUSTER_STATUS_TYPE:-none}" "${CHECK_CLUSTER_STATUS_REF:-}"
    adxc_print_operation_line "Cluster Readiness" "Profile-bound operation" "${CHECK_CLUSTER_READINESS_TYPE:-none}" "${CHECK_CLUSTER_READINESS_REF:-}"
    printf '\n[b] Back\n[q] Exit\n'
}

adxc_miqm_maintenance_dashboard() {
    local profile_name="$1"
    local profile_dir

    profile_dir="$(adxc_profile_dir_by_name "${profile_name}")"
    adxc_load_profile_config "${profile_dir}"
    adxc_load_operation_file "${profile_dir}" "maintenance"

    adxc_print_header "${PROFILE_NAME} - MAINTENANCE"
    printf '[1] Backup                 Backup, export and save operations\n'
    printf '[2] Log Cleanup            Housekeeping for logs\n'
    printf '\nConfiguration\n\n'
    adxc_print_operation_line "Backup" "Profile-bound operation" "${MAINT_BACKUP_TYPE:-none}" "${MAINT_BACKUP_REF:-}"
    adxc_print_operation_line "Log Cleanup" "Profile-bound operation" "${MAINT_LOG_CLEANUP_TYPE:-none}" "${MAINT_LOG_CLEANUP_REF:-}"
    printf '\n[b] Back\n[q] Exit\n'
}

adxc_miqm_custom_dashboard() {
    local profile_name="$1"

    adxc_print_header "${profile_name} - CUSTOM COMMANDS"
    "${ADXC_ROOT_DIR}/bin/adxc-cmd" --profile "${profile_name}"
}
