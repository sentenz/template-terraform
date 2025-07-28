#!/bin/bash
#
# Install and configure all dependencies essential for development.

# -x: print a trace (debug)
# -u: treat unset variables
# -o pipefail: return value of a pipeline
set -uo pipefail

# Include Scripts

source ./../scripts/shell/pkg.sh

# Constant Variables

readonly -A SNAP_PACKAGES=(
  ["terraform"]=""
  ["terraform-docs"]=""
  ["trivy"]=""
)

readonly -A GO_PACKAGES=(
  ["github.com/terraform-linters/tflint"]="v0.57.0"
  ["go.mozilla.org/sops/cmd/sops"]="3.4.0"
)

# Control Flow Logic

function setup() {
  local -i retval=0

  pkg_snap_install_list SNAP_PACKAGES
  ((retval |= $?))

  # TODO Implement `pkg_snap_clean` script function
  # pkg_snap_clean
  # ((retval |= $?))

  pkg_go_install_list GO_PACKAGES
  ((retval |= $?))

  pkg_go_clean
  ((retval |= $?))

  return "${retval}"
}

setup
exit "${?}"
