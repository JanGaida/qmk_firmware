#!/usr/bin/env bash

# bash: strict mode
set -e

# cfg: editor
GIT_CORE_EDITOR="nano"

# cfg: git
GIT_UPSTREAM_NAME="upstream"

# cfg: repositories
GIT_UPSTREAM_QMK_FIRMWARE="https://github.com/qmk/qmk_firmware.git"
GIT_UPSTREAM_QMK_FIRMWARE_BRANCH="master"
GIT_FORK_HALYCON_USERSPACE="https://github.com/JanGaida/qmk_userspace.git"
GIT_UPSTREAM_HALYCON_USERSPACE="https://github.com/splitkb/qmk_userspace.git"
GIT_UPSTREAM_HALYCON_USERSPACE_BRANCH="halcyon"

# cfg: paths
HALCYON_DIR="users/halcyon_userspace"

# ----------------------------------------------------------------------------

# sh: vars
merge_conflicts=0
error_messages=()
stash_name="auto_merge_$(date +'%Y-%m-%d_%H-%M-%S')"

# bash: formatting

if [ ! -t 1 ]; then
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    NC=""
else
    RED="\033[0;31m"
    GREEN="\033[0;32m"
    YELLOW="\033[0;33m"
    BLUE="\033[1;34m"
    BOLD="\033[1m"
    NC="\033[0m"
fi

# git: configuration
git config --global core.editor "$GIT_CORE_EDITOR"
git config advice.addIgnoredFile false
# @see https://github.com/ohmyzsh/ohmyzsh/discussions/9849
git config --global oh-my-zsh.hide-info 1
git config --global oh-my-zsh.hide-status 1
git config --global oh-my-zsh.hide-dirty 1
# @see https://github.com/devcontainers/features/tree/main/src/common-utils#customizing-the-command-prompt
git config --global devcontainers-theme.hide-status 1

# git: stash changes
if ! git diff --quiet; then
    echo -e "${BOLD}${YELLOW}[setup-git.sh]: Unstaged changes detected. Stashing as '$stash_name'…${NC}"
    git stash push --include-untracked -m "$stash_name"
fi

# qmk_firmware: setup upstream
if ! git remote | grep -q "$GIT_UPSTREAM_NAME"; then
    echo -e "${BOLD}${BLUE}[setup-git.sh]: Adding ${GIT_UPSTREAM_NAME} for qmk_firmware…${NC}"
    git remote add "$GIT_UPSTREAM_NAME" "$GIT_UPSTREAM_QMK_FIRMWARE"
fi

# halcyon_userspace: setup submodule
if ! git config --list | grep -q "^submodule\.$HALCYON_DIR\."; then
    echo -e "${BOLD}${BLUE}[setup-git.sh]: Adding halcyon_userspace submodule…${NC}"
    git submodule add "$GIT_FORK_HALYCON_USERSPACE" "$HALCYON_DIR"
fi

# halcyon_userspace: setup upstream
if [ -d "$HALCYON_DIR" ]; then
    (
        cd "$HALCYON_DIR"
        if ! git remote | grep -q "$GIT_UPSTREAM_NAME"; then
            echo -e "${BOLD}${BLUE}[setup-git.sh]: Adding ${GIT_UPSTREAM_NAME} for halcyon_userspace…${NC}"
            git remote add "$GIT_UPSTREAM_NAME" "$GIT_UPSTREAM_HALYCON_USERSPACE"
        fi
    )
else
    error_messages+=("Directory '$HALCYON_DIR' does not exist.")
fi

# git: update submodules
echo -e "${BOLD}${BLUE}[setup-git.sh]: Updating submodules…${NC}"
git submodule sync --recursive
git submodule update --init --recursive

# qmk_firmware: pull from upstream
echo -e "${BOLD}${BLUE}[setup-git.sh]: Merging qmk_firmware ${GIT_UPSTREAM_NAME}…${NC}"
git fetch "$GIT_UPSTREAM_NAME"
if [ -f .git/index.lock ]; then
    echo -e "${BOLD}${RED}[setup-git.sh]: Removing stale index.lock${NC}"
    rm -f .git/index.lock
fi
git checkout "$GIT_UPSTREAM_QMK_FIRMWARE_BRANCH"
set +e
git rebase "$GIT_UPSTREAM_NAME"/"$GIT_UPSTREAM_QMK_FIRMWARE_BRANCH"
merge_exit_code=$?
set -e
if [ $merge_exit_code -ne 0 ]; then
    echo -e "${BOLD}${RED}[setup-git.sh]: Merge conflict in qmk_firmware.${NC}"
    merge_conflicts=$((merge_conflicts + 1))
fi

# halcyon_userspace: pull from upstream
if [ -d "$HALCYON_DIR" ]; then
    (
        cd "$HALCYON_DIR" || exit 1
        echo -e "${BOLD}${BLUE}[setup-git.sh]: Merging halcyon_userspace ${GIT_UPSTREAM_NAME}…${NC}"
        git fetch "$GIT_UPSTREAM_NAME"
        if [ -f .git/index.lock ]; then
            echo -e "${BOLD}${RED}[setup-git.sh]: Removing stale index.lock${NC}"
            rm -f .git/index.lock
        fi
        git checkout "$GIT_UPSTREAM_HALYCON_USERSPACE_BRANCH"
        set +e
        git rebase "$GIT_UPSTREAM_NAME"/"$GIT_UPSTREAM_HALYCON_USERSPACE_BRANCH"
        merge_exit_code=$?
        set -e
        if [ $merge_exit_code -ne 0 ]; then
            echo -e "${BOLD}${YELLOW}[setup-git.sh]: Merge conflict in halcyon_userspace.${NC}"
            merge_conflicts=$((merge_conflicts + 1))
        fi
    )
else
    error_messages+=("Directory '$HALCYON_DIR' does not exist.")
fi

# ----------------------------------------------------------------------------

# git: reapply stashed changes
if git stash list | grep -q "$stash_name"; then
    echo -e "${BOLD}${YELLOW}[setup-git.sh]: Restoring stashed changes '$stash_name'…${NC}"
    git stash apply "stash^{/$stash_name}"
fi

# MR-Conflicts?
if [ "$merge_conflicts" -gt 0 ]; then
    echo -e "${BOLD}${YELLOW}[setup-git.sh]: Created $merge_conflicts merge conflict(s). Please resolve them manually.${NC}"
fi

# Errors?
if [ ${#error_messages[@]} -gt 0 ]; then
    echo -e "${BOLD}${RED}[setup-git.sh]: Errors occurred:${NC}"
    for error in "${error_messages[@]}"; do
        echo -e "  - ${RED}$error${NC}"
    done
else
    echo -e "${BOLD}${GREEN}[setup-git.sh]: Setup completed successfully.${NC}"
fi
