#!/bin/bash
#
# Setup the Everything as Code (XaC) environment.

# -x: print a trace (debug)
# -u: treat unset variables
# -o pipefail: return value of a pipeline
set -uo pipefail

# Include Scripts

source ./../scripts/shell/pkg.sh

# Constant Variables

# NOTE Print package version: apt-cache madison <package> | awk '{ print $3 }'
readonly -A APT_PACKAGES=(
  ["make"]=""
  ["ca-certificates"]=""
  ["snapd"]=""
)

readonly -A SNAP_PACKAGES=(
  ["terraform"]="1.9.5"
  ["terraform-docs"]="0.18.0"
)

# Control Flow Logic

function setup_xac() {
  local -i retval=0

  pkg_apt_install_list APT_PACKAGES
  ((retval |= $?))

  pkg_apt_clean
  ((retval |= $?))

  pkg_snap_install_list SNAP_PACKAGES
  ((retval |= $?))

  return "${retval}"
}

setup_xac
exit "${?}"
