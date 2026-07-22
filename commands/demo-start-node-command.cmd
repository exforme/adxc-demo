#!/usr/bin/env bash
COMMAND_NAME="demo-start-node-command"
COMMAND_TYPE="single-command"
COMMAND_DESCRIPTION="Demo Start Node command implementation"
COMMAND_ENABLED="YES"
COMMAND_STATUS="ACTIVE"
COMMAND_LINE='printf "DEMO: start node command would run strmqm -x <QMGR>.\n"'
main() { eval "${COMMAND_LINE}"; }
main "$@"
