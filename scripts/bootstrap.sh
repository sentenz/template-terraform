#!/bin/bash
#
# Initialize a software development workspace with requisites.

# -x: print a trace (debug)
# -u: treat unset variables
# -o pipefail: return value of a pipeline
set -uo pipefail

# Include Scripts

source ./../scripts/shell/pkg.sh

# Constant Variables

readonly -A APT_PACKAGES=(
  ["make"]=""
  ["git"]=""
  ["jq"]=""
  ["bash"]=""
  ["ca-certificates"]=""
  ["snapd"]=""
  ["python3-pip"]=""
  ["go"]=""
)

readonly -A SNAP_PACKAGES=(
  ["awscli"]=""
  ["task"]=""
)

# Control Flow Logic

function bootstrap() {
  local -i retval=0

  pkg_apt_install_list APT_PACKAGES
  ((retval |= $?))

  pkg_snap_install_list SNAP_PACKAGES
  ((retval |= $?))

  pkg_apt_clean
  ((retval |= $?))

  return "${retval}"
}

bootstrap
exit "${?}"
