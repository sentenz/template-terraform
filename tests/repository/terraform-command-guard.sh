#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
temporary_dir="$(mktemp -d)"
trap 'rm -rf "$temporary_dir"' EXIT

terraform_stub="$temporary_dir/terraform"
command_log="$temporary_dir/commands.log"

cat > "$terraform_stub" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "${TF_STUB_LOG:?}"
STUB
chmod +x "$terraform_stub"

export TERRAFORM_BIN="$terraform_stub"
export TF_STUB_LOG="$command_log"

bash -n "$repository_root/scripts/terraform-command.sh"

make --no-print-directory --directory="$repository_root" --dry-run \
  tf-infra-init TF_ENV=stage TF_STACK=ec2 \
  | grep -Fq 'bash scripts/terraform-command.sh -chdir=environments/stage/ec2 init -reconfigure'

printf 'destroy stage/ec2\n' \
  | bash "$repository_root/scripts/terraform-command.sh" \
      -chdir=environments/stage/ec2 destroy -target=module.component_analysis

grep -Fq -- '-chdir=environments/stage/ec2 plan -destroy -out=terraform.destroy.tfplan -target=module.component_analysis' "$command_log"
grep -Fq -- '-chdir=environments/stage/ec2 show terraform.destroy.tfplan' "$command_log"
grep -Fq -- '-chdir=environments/stage/ec2 apply terraform.destroy.tfplan' "$command_log"

if printf 'destroy stage/ec2\n' \
  | bash "$repository_root/scripts/terraform-command.sh" \
      -chdir=environments/stage/ec2 destroy -auto-approve; then
  printf 'error: -auto-approve was not rejected.\n' >&2
  exit 1
fi
