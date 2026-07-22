# adxc-demo 1.0

This package is a complete demo release focused on Rocky Linux validation with
2 VM multi-instance queue managers.

## Key demo goals

- Fresh install validation on Rocky Linux.
- Profile Creation validation.
- Command Creation validation.
- Dashboard validation.
- Admin Menu validation.
- Operator UAT for Dashboard, Navigation, Menus and MIQM Actions.

## Profile Operation Configuration

Operation configuration resides in:

```text
profiles/<PROFILE>/operations/
├── control.conf
├── troubleshooting.conf
├── checks.conf
└── maintenance.conf
```

Control examples:

```bash
CONTROL_START_NODE_TYPE="command"
CONTROL_START_NODE_REF="demo-start-node-command"

CONTROL_STOP_NODE_TYPE="script"
CONTROL_STOP_NODE_REF="scripts/miqm-stop-node-enhanced.sh"
```

Type can be:

```text
none
command
script
```

This allows QM1 to start through a command and QM2 to start through a script
without changing the dashboard/menu code.

## MIQM dashboard files

```text
templates/mq_miqm/dashboards/profile.dashboard
templates/mq_miqm/dashboards/control.dashboard
templates/mq_miqm/dashboards/troubleshooting.dashboard
templates/mq_miqm/dashboards/checks.dashboard
templates/mq_miqm/dashboards/maintenance.dashboard
```

## Usage examples

```bash
adxc
adxc MQ_MIQM_EXAMPLE
adxc MQ_MIQM_EXAMPLE control
adxc MQ_MIQM_EXAMPLE checks
adxc-admin
```
