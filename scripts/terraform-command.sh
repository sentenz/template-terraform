#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

terraform_bin="${TERRAFORM_BIN:-terraform}"
destroy_plan_file="${TF_DESTROY_PLAN_FILE:-terraform.destroy.tfplan}"
args=("$@")
command_index=-1

for index in "${!args[@]}"; do
  if [[ "${args[$index]}" != -* ]]; then
    command_index=$index
    break
  fi
done

if (( command_index < 0 )) || [[ "${args[$command_index]}" != "destroy" ]]; then
  exec "$terraform_bin" "${args[@]}"
fi

global_args=("${args[@]:0:command_index}")
destroy_args=("${args[@]:command_index+1}")
working_dir=""

for arg in "${global_args[@]}"; do
  if [[ "$arg" == -chdir=* ]]; then
    working_dir="${arg#-chdir=}"
    break
  fi
done

if [[ -z "$working_dir" ]]; then
  printf 'error: guarded destroy requires Terraform -chdir=<environment>/<stack>.\n' >&2
  exit 2
fi

for arg in "${destroy_args[@]}"; do
  case "$arg" in
    -auto-approve|-force|-out|-out=*)
      printf 'error: destructive option %q is not permitted by the repository guard.\n' "$arg" >&2
      exit 2
      ;;
    -target=*)
      printf 'warning: targeted destroy is exceptional; review every explicit and implicit dependent in the displayed plan.\n' >&2
      ;;
  esac
done

context="${working_dir#environments/}"
confirmation="destroy ${context}"

printf 'Creating saved destroy plan for %s.\n' "$context"
"$terraform_bin" "${global_args[@]}" plan -destroy -out="$destroy_plan_file" "${destroy_args[@]}"

printf '\nReview every deletion and replacement in the saved plan before continuing.\n'
"$terraform_bin" "${global_args[@]}" show "$destroy_plan_file"

printf '\nType "%s" to apply the reviewed destroy plan: ' "$confirmation"
IFS= read -r answer
if [[ "$answer" != "$confirmation" ]]; then
  printf 'Destroy aborted; saved plan retained at %s/%s for review.\n' "$working_dir" "$destroy_plan_file" >&2
  exit 1
fi

"$terraform_bin" "${global_args[@]}" apply "$destroy_plan_file"

if [[ "$destroy_plan_file" = /* ]]; then
  rm -f -- "$destroy_plan_file"
else
  rm -f -- "$working_dir/$destroy_plan_file"
fi
