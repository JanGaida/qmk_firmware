#!/usr/bin/env bash

# bash: strict mode
set -eEuo pipefail

# ----------------------------------------------------------------------------

# Git Setup
.devcontainer/setup-git.sh

# QMK Configs
.devcontainer/setup-qmk.sh

