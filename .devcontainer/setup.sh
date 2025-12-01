#!/usr/bin/env bash

# bash: strict mode
set -eEuo pipefail

# ----------------------------------------------------------------------------

# Setup git
.devcontainer/setup-git.sh

# Setup qmk
.devcontainer/setup-qmk.sh

# Update codebase
.devcontainer/update-codebase.sh
