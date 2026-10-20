# Terraform operations

## Execution assumptions

- Runtime: Terraform `>= 1.10.0`, matching the repository module constraints.
- State: remote S3 backends with native lockfiles and encryption.
- Entry point: GNU Make from the repository root. GNU Make loads `GNUmakefile`, which includes the existing `Makefile` and routes Terraform CLI commands through `scripts/terraform-command.sh`.
- Production changes require a reviewed plan and an independent approval outside the Terraform CLI workflow.

## Plan and apply

Run a stack-specific deployment from the repository root:

```bash
make tf-ec2-deploy TF_ENV=stage
make tf-eks-deploy TF_ENV=stage
```

The existing deployment workflow initializes and validates the selected stack, writes `terraform.tfplan`, requests confirmation, and applies that saved plan. The plan artifact may contain sensitive values and must never be committed or attached to an untrusted system.

## Destructive changes

Use the existing stack targets through the default GNU Make entry point:

```bash
make tf-ec2-destroy TF_ENV=stage
make tf-eks-destroy TF_ENV=stage
```

The Terraform command guard converts the legacy `terraform destroy` invocation into this controlled sequence:

1. `terraform plan -destroy -out=terraform.destroy.tfplan`
2. `terraform show terraform.destroy.tfplan`
3. Exact typed confirmation: `destroy <environment>/<stack>`
4. `terraform apply terraform.destroy.tfplan`

The saved destroy plan is retained when confirmation is declined or an operation fails. It is removed only after a successful apply.

`-auto-approve`, `-force`, and caller-supplied `-out` options are rejected. A targeted destroy remains available for recovery scenarios, but emits a warning because Terraform can include indirect dependencies in the plan. Every listed deletion must be reviewed before confirmation.

Do not bypass the guard with `make -f Makefile`, a direct `terraform destroy`, or an unreviewed production apply.

## Evidence and rollback

Retain the reviewed terminal output, CI logs, approval record, and backend state-version metadata. Saved plan files are sensitive and ephemeral; `.gitignore` excludes them.

A failed apply is not rolled back by replaying an older plan. Reconcile the current state with a new plan. Restore an earlier S3 object version only under an incident procedure with the state lock held, a state backup retained, and the recovery plan reviewed.
