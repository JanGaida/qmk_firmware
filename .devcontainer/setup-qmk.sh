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
    user.overlay_dir="${USER_SPACE_DIR}" \
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

# qmk-userspace: setup
if [ -d "$USER_SPACE_DIR" ]; then
    echo -e "${BOLD}${BLUE}${log_prefix} Resting user modules…${NC}"
    (
        cd "$USER_SPACE_DIR"
        cp "$USER_SPACE_EMPTY_JSON" "$USER_SPACE_JSON"
    )
    echo -e "${BOLD}${BLUE}${log_prefix} Applying user modules…${NC}"
    for module in "${USER_SPACE_MODULES[@]}"; do
        qmk userspace-add -kb "${QMK_KEYBOARD}" -km "${QMK_KEYMAP}" -e "$module=1" \
            || echo -e "${BOLD}${RED}${log_prefix} Failed to add module ${module}…${NC}"
    done
else
    echo -e "${BOLD}${YELLOW}${log_prefix} User-space is not available…${NC}"
fi

# ----------------------------------------------------------------------------

echo -e "${BOLD}${GREEN}${log_prefix} Completed successfully.${NC}"
