#!/usr/bin/env bash
# cspell:words mkdeep

# bash: strict mode
set -eEuo pipefail

# bash: import
source .devcontainer/vars.sh

# ----------------------------------------------------------------------------

# Helper to format the target name:
#  - applies lower-case
#  - replaces '/' | '\' with '_'
sanitize() {
    tr '[:upper:]' '[:lower:]' | tr '/\\' '_' | tr -d '\r'
}

# ----------------------------------------------------------------------------

# sh: vars
log_prefix="[compile.sh]:"
time_stamp=$(date +"%Y-%m-%d/%H-%M-%S")
sanitized_keyboard=$(echo "$QMK_KEYBOARD" | sanitize)

# cmpl: prepare output
output_dir="${QMK_OUTPUT_ROOT}/${sanitized_keyboard}/${time_stamp}"
mkdir -p "$output_dir"
echo -e "${BOLD}${BLUE}${log_prefix} Output directory: ${output_dir}${NC}"

# cmpl: each module
for module in "${USER_SPACE_MODULES[@]}"; do
    # prep
    sanitized_keymap=$(echo "$QMK_KEYMAP" | sanitize)
    sanitized_module=$(echo "$module" | sanitize)
    target_name="${sanitized_keyboard}--${sanitized_keymap}--${sanitized_module}"

    # compile
    echo -e "${BOLD}${BLUE}${log_prefix} Compiling ${target_name}…${NC}"
    qmk compile \
        -kb "$QMK_KEYBOARD" \
        -km "$QMK_KEYMAP" \
        -e "${module}=1" \
        -e "TARGET=${target_name}"

    # move
    compiled_file=$(find . -maxdepth 1 -type f -name "${target_name}.uf2" | head -n 1)
    if [[ -z "$compiled_file" ]]; then
        echo -e "${BOLD}${RED}${log_prefix} Could not find ${target_name}.uf2${NC}"
    else
        mv "$compiled_file" "${output_dir}/${target_name}.uf2"
        rm -f "$compiled_file"
        echo -e "${BOLD}${GREEN}${log_prefix} Done → ${output_dir}/${target_name}.uf2${NC}"
    fi
done
echo -e "${BOLD}${GREEN}${log_prefix} All builds completed.${NC}"
exit 0
