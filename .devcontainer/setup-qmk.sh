#!/usr/bin/env bash

# bash: strict mode
set -e

# bash: import
source .devcontainer/vars.sh

# ----------------------------------------------------------------------------

# sh: vars
log_prefix="[setup-qmk.sh]:"

# qmk: configs
echo -e "${BOLD}${BLUE}${log_prefix} Setting config-values…${NC}"
qmk config \
    user.keyboard="${QMK_KEYBOARD}" \
    user.keymap="${QMK_KEYMAP}" \
    user.name="${QMK_USER}" \
    general.verbose="False"

# python: requirements
echo -e "${BOLD}${BLUE}${log_prefix} Installing dependencies…${NC}"
pip3 install -r requirements.txt
pip3 install -r requirements-dev.txt

# qmk: linting
echo -e "${BOLD}${BLUE}${log_prefix} Linting…${NC}"
qmk lint

# ----------------------------------------------------------------------------

echo -e "${BOLD}${GREEN}${log_prefix} Completed successfully.${NC}"
