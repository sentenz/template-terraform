#!/bin/bash
#
# Setup the Software Development environment.

# -x: print a trace (debug)
# -u: treat unset variables
# -o pipefail: return value of a pipeline
set -uo pipefail

# Constant Variables

readonly -a SCRIPTS=(
  setup_xac.sh
)

# Control Flow Logic

function setup() {
  local -i retval=0
  local -i result=0

  for script in "${SCRIPTS[@]}"; do
    chmod +x "${script}"
    ./"${script}"
    ((result = $?))
    ((retval |= "${result}"))
  done

  return "${retval}"
}

setup
exit "${?}"
