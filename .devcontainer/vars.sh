#!/usr/bin/env bash

# bash: strict mode
set -e

# ----------------------------------------------------------------------------

# bash: formatting
if [ ! -t 1 ]; then
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    WHITE=""
    BOLD=""
    ITALIC=""
    UNDERLINE=""
    NC=""
else
    RED="\033[0;31m"
    GREEN="\033[0;32m"
    YELLOW="\033[0;33m"
    BLUE="\033[0;34m"
    MAGENTA="\033[0;35m"
    CYAN="\033[0;36m"
    WHITE="\033[0;37m"
    BOLD="\033[1m"
    ITALIC="\033[3m"
    UNDERLINE="\033[4m"
    NC="\033[0m"
fi

# ----------------------------------------------------------------------------

# cfg: qmk
QMK_ROOT="/workspaces/qmk_firmware"
QMK_KEYBOARD="splitkb/halcyon/elora/rev2"
QMK_KEYMAP="default"
QMK_USER="JanGaida"
QMK_OUTPUT_ROOT="${QMK_ROOT}/.output"

# cfg: repositories
GIT_UPSTREAM_QMK_FIRMWARE="https://github.com/qmk/qmk_firmware.git"
GIT_UPSTREAM_QMK_FIRMWARE_BRANCH="master"
GIT_FORK_HALYCON_USERSPACE="https://github.com/JanGaida/qmk_userspace.git"
GIT_UPSTREAM_HALYCON_USERSPACE="https://github.com/splitkb/qmk_userspace.git"
GIT_UPSTREAM_HALYCON_USERSPACE_BRANCH="halcyon"

# cfg: git
GIT_CORE_EDITOR="nano"
GIT_UPSTREAM_NAME="upstream"

# cfg: sparse-checkout
SPARSE_FILE=".git/info/sparse-checkout"
SPARSE_KEYBOARDS_TO_KEEP=(
    "splitkb"
    "$QMK_USER"
)

# cfg: userspace
USER_SPACE_DIR="users/halcyon_userspace"
USER_SPACE_JSON="qmk.json"
USER_SPACE_EMPTY_JSON="qmk_empty.json"
USER_SPACE_MODULES=(
    #"HLC_NONE"
    #"HLC_TFT_DISPLAY"
    "HLC_ENCODER"
    "HLC_CIRQUE_TRACKPAD"
)
