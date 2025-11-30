#!/usr/bin/env bash

# bash: strict mode
set -e

# bash: import
source .devcontainer/vars.sh

# ----------------------------------------------------------------------------

# sh: vars
log_prefix="[setup-git.sh]:"
merge_conflicts=0
blocked_merge=0
error_messages=()

# git: configuration
git config --global core.editor "$GIT_CORE_EDITOR"
git config advice.addIgnoredFile false
# @see https://github.com/ohmyzsh/ohmyzsh/discussions/9849
git config --global oh-my-zsh.hide-info 1
git config --global oh-my-zsh.hide-status 1
git config --global oh-my-zsh.hide-dirty 1
# @see https://github.com/devcontainers/features/tree/main/src/common-utils#customizing-the-command-prompt
git config --global devcontainers-theme.hide-status 1

# git: sparse-checkout
git sparse-checkout init --no-cone
{
    # https://github.com/git/git/blob/879321eb0bec25779386445d65242452825155be/Documentation/git-sparse-checkout.txt#L100-L149
    echo "/*"
    echo "!/keyboards/"
    echo "!/keyboards/**"
    for kb in "${SPARSE_KEYBOARDS_TO_KEEP[@]}"; do
        echo "/keyboards/$kb"
        echo "/keyboards/$kb/**"
    done
} > "$SPARSE_FILE"
git sparse-checkout reapply

# qmk_firmware: setup upstream
if ! git remote | grep -q "$GIT_UPSTREAM_NAME"; then
    echo -e "${BOLD}${BLUE}${log_prefix} Adding ${GIT_UPSTREAM_NAME} for qmk_firmware…${NC}"
    git remote add "$GIT_UPSTREAM_NAME" "$GIT_UPSTREAM_QMK_FIRMWARE"
fi

# halcyon_userspace: setup submodule
#if ! git config --list | grep -q "^submodule\.$USER_SPACE_DIR\."; then
#    echo -e "${BOLD}${BLUE}${log_prefix} Adding halcyon_userspace submodule…${NC}"
#    git submodule add "$GIT_FORK_HALYCON_USERSPACE" "$USER_SPACE_DIR"
#fi

# halcyon_userspace: setup upstream
if [ -d "$USER_SPACE_DIR" ]; then
    (
        cd "$USER_SPACE_DIR"
        if ! git remote | grep -q "$GIT_UPSTREAM_NAME"; then
            echo -e "${BOLD}${BLUE}${log_prefix} Adding ${GIT_UPSTREAM_NAME} for halcyon_userspace…${NC}"
            git remote add "$GIT_UPSTREAM_NAME" "$GIT_UPSTREAM_HALYCON_USERSPACE"
        fi
    )
else
    error_messages+=("Directory '$USER_SPACE_DIR' does not exist.")
fi

# git: update submodules
echo -e "${BOLD}${BLUE}${log_prefix} Updating submodules…${NC}"
git submodule sync --recursive
git submodule update --init --recursive

# qmk_firmware: pull from upstream
echo -e "${BOLD}${BLUE}${log_prefix} Merging qmk_firmware ${GIT_UPSTREAM_NAME}…${NC}"
git fetch "$GIT_UPSTREAM_NAME"
git checkout "$GIT_UPSTREAM_QMK_FIRMWARE_BRANCH"
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${BOLD}${YELLOW}${log_prefix} Skipping rebase because there are local changes.${NC}"
    blocked_merge=$((blocked_merge + 1))
else
    set +e
    git merge "$GIT_UPSTREAM_NAME/$GIT_UPSTREAM_QMK_FIRMWARE_BRANCH"
    merge_exit_code=$?
    set -e
    if [ $merge_exit_code -ne 0 ]; then
        echo -e "${BOLD}${RED}${log_prefix} Merge conflict in qmk_firmware.${NC}"
        merge_conflicts=$((merge_conflicts + 1))
    fi
fi

# halcyon_userspace: pull from upstream
if [ -d "$USER_SPACE_DIR" ]; then
    (
        cd "$USER_SPACE_DIR" || exit 1
        echo -e "${BOLD}${BLUE}${log_prefix} Merging halcyon_userspace ${GIT_UPSTREAM_NAME}…${NC}"
        git fetch "$GIT_UPSTREAM_NAME"
        if [ -f .git/index.lock ]; then
            echo -e "${BOLD}${RED}${log_prefix} Removing stale index.lock${NC}"
            rm -f .git/index.lock
        fi
        git checkout "$GIT_UPSTREAM_HALYCON_USERSPACE_BRANCH"
        if [ -n "$(git status --porcelain)" ]; then
            echo -e "${BOLD}${YELLOW}${log_prefix} Skipping rebase in halcyon_userspace because there are local changes.${NC}"
            blocked_merge=$((blocked_merge + 1))
        else
            set +e
            git merge "$GIT_UPSTREAM_NAME/$GIT_UPSTREAM_HALYCON_USERSPACE_BRANCH"
            merge_exit_code=$?
            set -e
            if [ $merge_exit_code -ne 0 ]; then
                echo -e "${BOLD}${YELLOW}${log_prefix} Merge conflict in halcyon_userspace.${NC}"
                merge_conflicts=$((merge_conflicts + 1))
            fi
        fi
    )
else
    error_messages+=("Directory '$USER_SPACE_DIR' does not exist.")
fi


# ----------------------------------------------------------------------------

# MR-Conflicts?
if [ "$merge_conflicts" -gt 0 ]; then
    echo -e "${BOLD}${YELLOW}${log_prefix} Created $merge_conflicts merge conflict(s). Please resolve them manually.${NC}"
fi

# Errors?
if [ ${#error_messages[@]} -gt 0 ]; then
    echo -e "${BOLD}${RED}${log_prefix} Errors occurred:${NC}"
    for error in "${error_messages[@]}"; do
        echo -e "  - ${RED}$error${NC}"
    done
else
    if [ ${#blocked_merge[@]} -gt 0 ]; then
        echo -e "${BOLD}${GREEN}${log_prefix} Completed partially successfully.${NC}"
    else
        echo -e "${BOLD}${GREEN}${log_prefix} Completed successfully.${NC}"
    fi
fi
