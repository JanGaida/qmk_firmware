#!/usr/bin/env bash

# bash: strict mode
set -e

# bash: import
source .devcontainer/vars.sh

# ----------------------------------------------------------------------------

# sh: vars
log_prefix="[setup-git.sh]:"

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

# ----------------------------------------------------------------------------

# finally
echo -e "${BOLD}${GREEN}${log_prefix} Completed successfully.${NC}"
