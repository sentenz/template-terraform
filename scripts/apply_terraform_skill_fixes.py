#!/usr/bin/env python3
"""One-time task-runner migration for the Terraform Skill safety protocol."""

from __future__ import annotations

from pathlib import Path

MAKEFILE = Path(__file__).resolve().parents[1] / "Makefile"

VARIABLES_OLD = """TF_ENV ?= dev
TF_STACK ?= eks
TF = terraform -chdir=environments/$(TF_ENV)/$(TF_STACK)
"""

VARIABLES_NEW = """TF_ENV ?= dev
TF_STACK ?= eks
TF_PLAN ?= terraform.tfplan
TF_DESTROY_PLAN ?= terraform.destroy.tfplan
TF_TARGET ?=

# Backward-compatible command-line alias. Ignore a generic TARGET inherited from the environment.
ifeq ($(origin TARGET),command line)
ifneq ($(strip $(TF_TARGET)),)
$(error Set only one of TF_TARGET or TARGET)
endif
TF_TARGET := $(TARGET)
endif

TF = terraform -chdir=environments/$(TF_ENV)/$(TF_STACK)
"""

PROVISIONING_BLOCK = """# Verify that the requested environment and stack exist before any state-backed operation
tf-infra-check-context:
	@if [ ! -d "environments/$(TF_ENV)/$(TF_STACK)" ]; then \\
		echo "error: Terraform stack 'environments/$(TF_ENV)/$(TF_STACK)' does not exist" >&2; \\
		exit 1; \\
	fi
	@if [ -n "$(TF_TARGET)" ] && [[ ! "$(TF_TARGET)" =~ ^[A-Za-z0-9_-]+$$ ]]; then \\
		echo "error: TF_TARGET must be a Terraform module name" >&2; \\
		exit 1; \\
	fi
.PHONY: tf-infra-check-context

# Initialize Terraform Configuration for the Target Environment
tf-infra-init:
	$(TF) init -reconfigure
.PHONY: tf-infra-init

# Validate Terraform Configuration for the Target Environment
tf-infra-validate:
	$(TF) validate
.PHONY: tf-infra-validate

# Usage: $(MAKE) tf-infra-plan TF_TARGET=<module>
#
# Generate a saved execution plan for the Target Environment with optional TF_TARGET for Module provisioning
tf-infra-plan:
	$(TF) plan -out="$(TF_PLAN)" $(if $(strip $(TF_TARGET)),-target=module.$(TF_TARGET),)
.PHONY: tf-infra-plan

# Display the exact saved plan that will be applied
tf-infra-show-plan:
	$(TF) show -no-color "$(TF_PLAN)"
.PHONY: tf-infra-show-plan

# Require environment-qualified confirmation before applying the reviewed plan artifact
tf-infra-confirm:
	@echo ""
	@read -r -p "Type 'apply $(TF_ENV)/$(TF_STACK)' to apply the reviewed plan$(if $(TF_TARGET), targeting '$(TF_TARGET)',): " confirm; \\
		if [[ "$$confirm" != "apply $(TF_ENV)/$(TF_STACK)" ]]; then \\
			echo "Aborted."; \\
			exit 1; \\
		fi
.PHONY: tf-infra-confirm

# IMPORTANT Do NOT pass -target here; the saved plan already encodes targeting.
#
# Apply the exact reviewed Terraform plan artifact
tf-infra-apply:
	$(TF) apply "$(TF_PLAN)"
.PHONY: tf-infra-apply

# Usage: $(MAKE) template-tf-infra-deploy TF_STACK=<ec2|eks> TF_TARGET=<optional_module>
#
# Deploy infrastructure from a displayed, confirmed, saved plan artifact
template-tf-infra-deploy:
	@$(MAKE) -s tf-infra-check-context
	@$(MAKE) -s tf-infra-init
	@$(MAKE) -s tf-infra-validate
	@$(MAKE) -s tf-infra-plan
	@$(MAKE) -s tf-infra-show-plan
	@$(MAKE) -s tf-infra-confirm
	@$(MAKE) -s tf-infra-apply
.PHONY: template-tf-infra-deploy

## Deploy EC2 infrastructure provisioning across environments
tf-ec2-deploy:
	@$(MAKE) -s template-tf-infra-deploy TF_STACK=ec2
.PHONY: tf-ec2-deploy

## Deploy EKS infrastructure provisioning across environments
tf-eks-deploy:
	@$(MAKE) -s template-tf-infra-deploy TF_STACK=eks
.PHONY: tf-eks-deploy

# Usage: $(MAKE) tf-infra-plan-destroy TF_TARGET=<module>
#
# Generate a saved destroy plan and display every explicit and implicit deletion
tf-infra-plan-destroy:
	@if [ -n "$(strip $(TF_TARGET))" ]; then \\
		echo "warning: targeted destroy plans can include implicit dependents; review the complete plan below" >&2; \\
	fi
	$(TF) plan -destroy -out="$(TF_DESTROY_PLAN)" $(if $(strip $(TF_TARGET)),-target=module.$(TF_TARGET),)
.PHONY: tf-infra-plan-destroy

# Display the exact saved destroy plan that will be applied
tf-infra-show-destroy-plan:
	$(TF) show -no-color "$(TF_DESTROY_PLAN)"
.PHONY: tf-infra-show-destroy-plan

# Require explicit environment-qualified confirmation after the full deletion graph is displayed
tf-infra-confirm-destroy:
	@echo ""
	@read -r -p "Type 'destroy $(TF_ENV)/$(TF_STACK)' to apply the reviewed destroy plan$(if $(TF_TARGET), targeting '$(TF_TARGET)',): " confirm; \\
		if [[ "$$confirm" != "destroy $(TF_ENV)/$(TF_STACK)" ]]; then \\
			echo "Aborted."; \\
			exit 1; \\
		fi
.PHONY: tf-infra-confirm-destroy

# IMPORTANT Do NOT run terraform destroy or pass -target here; apply only the reviewed plan artifact.
tf-infra-apply-destroy:
	$(TF) apply "$(TF_DESTROY_PLAN)"
.PHONY: tf-infra-apply-destroy

# Usage: $(MAKE) template-tf-infra-destroy TF_STACK=<ec2|eks> TF_TARGET=<optional_module>
#
# Destroy infrastructure only from a displayed, confirmed, saved destroy plan artifact
template-tf-infra-destroy:
	@$(MAKE) -s tf-infra-check-context
	@$(MAKE) -s tf-infra-init
	@$(MAKE) -s tf-infra-validate
	@$(MAKE) -s tf-infra-plan-destroy
	@$(MAKE) -s tf-infra-show-destroy-plan
	@$(MAKE) -s tf-infra-confirm-destroy
	@$(MAKE) -s tf-infra-apply-destroy
.PHONY: template-tf-infra-destroy

## Destroy EC2 infrastructure provisioning across environments using a reviewed destroy plan
tf-ec2-destroy:
	@$(MAKE) -s template-tf-infra-destroy TF_STACK=ec2
.PHONY: tf-ec2-destroy

## Destroy EKS infrastructure provisioning across environments using a reviewed destroy plan
tf-eks-destroy:
	@$(MAKE) -s template-tf-infra-destroy TF_STACK=eks
.PHONY: tf-eks-destroy

# ── Terraform Test & Analysis ────────────────────────────────────────────────────────────────────

# Unit Testing of Terraform Infrastructure Code
tf-test-unit:
	terraform -chdir=modules/aws-ec2 init -backend=false
	terraform -chdir=modules/aws-ec2 test
	terraform -chdir=modules/aws-eks init -backend=false
	terraform -chdir=modules/aws-eks test
.PHONY: tf-test-unit
"""


def main() -> None:
    text = MAKEFILE.read_text(encoding="utf-8")
    if VARIABLES_OLD not in text:
        raise SystemExit("Terraform variable block no longer matches the expected source")
    text = text.replace(VARIABLES_OLD, VARIABLES_NEW, 1)

    start_marker = "# Initialize Terraform Configuration for the Target Environment\n"
    end_marker = ".PHONY: tf-test-unit\n"
    start = text.index(start_marker)
    end = text.index(end_marker, start) + len(end_marker)
    text = f"{text[:start]}{PROVISIONING_BLOCK}{text[end:]}"

    MAKEFILE.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    main()
