#!/usr/bin/env bash

# bash: strict mode
set -e

# bash: import
source .devcontainer/vars.sh

# ----------------------------------------------------------------------------

# sh: vars
log_prefix="[update-codebase.sh]:"

# git: update submodules
echo -e "${BOLD}${BLUE}${log_prefix} Updating submodules…${NC}"
git submodule sync --recursive
git submodule update --init --recursive

# halcyon-module: copy
echo -e "${BOLD}${BLUE}${log_prefix} Copying halcyon modules…${NC}"
mkdir -p "$HALCYON_MODULE_TARGET_DIR"
find "${HALCYON_MODULE_SOURCE_DIR}/." -type f -print0 | while IFS= read -r -d '' file; do
    filename=$(basename "$file")  # Extrahiere nur den Dateinamen
    rel_path="${file#${HALCYON_MODULE_SOURCE_DIR}/}"
    dest_path="${HALCYON_MODULE_TARGET_DIR}/${rel_path}"
    mkdir -p "$(dirname "$dest_path")"
    cp "$file" "$dest_path"
    echo "Copied: '$filename' → '$rel_path'"
done

# halcyon-module: git-info
echo -e "${BOLD}${BLUE}${log_prefix} Creating version file for halcyon modules…${NC}"
(
    cd "$HALCYON_MODULE_SOURCE_DIR" || exit 1
    {
        echo "commit: $(git rev-parse HEAD 2>/dev/null || echo 'unknown')"
        echo "branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
        echo "remote: $(git config --get remote.origin.url 2>/dev/null || echo 'none')"
        echo "timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    } > "${HALCYON_MODULE_INFO_ROOT}/${HALCYON_MODULE_INFO_FILE}"
    echo "Created: '${HALCYON_MODULE_INFO_FILE}' → '${HALCYON_MODULE_TARGET_DIR}/${HALCYON_MODULE_INFO_FILE}'"
)

# ----------------------------------------------------------------------------

echo -e "${BOLD}${GREEN}${log_prefix} Completed successfully.${NC}"
