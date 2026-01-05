# SPDX-License-Identifier: Apache-2.0

ifneq (,$(wildcard .env))
	include .env
	export
endif

# Define Variables

SHELL := bash
.SHELLFLAGS := -euo pipefail -c
.ONESHELL:

TF_ENV ?= dev
TF_STACK ?= eks
TF = terraform -chdir=environments/$(TF_ENV)/$(TF_STACK)

# Define Targets

default: help

help:
	@awk 'BEGIN {printf "Tasks\n\tA collection of tasks used in the current project.\n\n"}'
	@awk 'BEGIN {printf "Usage\n\tmake $(shell tput -Txterm setaf 6)<task>$(shell tput -Txterm sgr0)\n\n"}' $(MAKEFILE_LIST)
	@awk '/^##/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print "$(shell tput -Txterm setaf 6)\t" substr($$1,1,index($$1,":")) "$(shell tput -Txterm sgr0)",c}1{c=0}' $(MAKEFILE_LIST) | column -s: -t
.PHONY: help

# ── Setup & Teardown ─────────────────────────────────────────────────────────────────────────────

# Prompt for credentials and cache them for the current session
permission:
	@sudo -v
.PHONY: permission

## Initialize a software development workspace with requisites
bootstrap:
	@$(MAKE) -s permission; \
	cd $(@D)/scripts && chmod +x bootstrap.sh && ./bootstrap.sh
.PHONY: bootstrap

## Install and configure all dependencies essential for development
setup:
	@$(MAKE) -s permission; \
	cd $(@D)/scripts && chmod +x setup.sh && ./setup.sh
.PHONY: setup

## Remove development artifacts and restore the host to its pre-setup state
teardown:
	@$(MAKE) -s permission; \
	cd $(@D)/scripts && chmod +x teardown.sh && ./teardown.sh
.PHONY: teardown

# ── Terraform Deploy & Destroy ───────────────────────────────────────────────────────────────────

# Initialize Terraform Configuration for the Target Environment
tf-infra-init:
	$(TF) init -reconfigure
.PHONY: tf-infra-init

# Validate Terraform Configuration for the Target Environment
tf-infra-validate:
	$(TF) validate
.PHONY: tf-infra-validate

# Usage: $(MAKE) tf-infra-plan TARGET=<module>
#
# Generate execution plan for the Target Environment with optional TARGET for Module provisioning 
tf-infra-plan:
	$(TF) plan -out=terraform.tfplan $(if $(strip $(TARGET)),-target=module.$(TARGET),)
.PHONY: tf-infra-plan

# Interactive user confirmation before proceeding with Terraform Deploy & Destroy
tf-infra-confirm:
	@echo ""
	@read -r -p "Confirm: Proceed with 'terraform apply' in '$(TF_ENV)/$(TF_STACK)'$(if $(TARGET), targeting '$(TARGET)',)? [yes $(TF_ENV)/no] " confirm; \
		if [[ "$$confirm" != "yes $(TF_ENV)" ]]; then \
			echo "Aborted."; \
			exit 1; \
		fi
.PHONY: tf-infra-confirm

# IMPORTANT Do NOT pass -target flag, the saved plan already encodes targeting.
#
# Apply Terraform Plan and Clean Artifacts
tf-infra-apply:
	$(TF) apply "terraform.tfplan"
.PHONY: tf-infra-apply

# Usage: $(MAKE) template-tf-infra-deploy TF_STACK=<ec2|eks> TARGET=<optional_module>
#
# Deploy infrastructure provisioning across environments
template-tf-infra-deploy:
	@$(MAKE) -s tf-infra-init
	@$(MAKE) -s tf-infra-validate
	# @$(MAKE) -s tf-test
	@$(MAKE) -s tf-infra-plan
	@$(MAKE) -s tf-infra-confirm
	@$(MAKE) -s tf-infra-apply
.PHONY: template-tf-infra-deploy

## Deploy EC2 infrastructure provisioning across environments
tf-ec2-deploy:
	@$(MAKE) -s template-tf-infra-deploy TF_STACK=ec2
.PHONY: tf-ec2-deploy

## Deploy EC2 infrastructure provisioning across environments
tf-eks-deploy:
	@$(MAKE) -s template-tf-infra-deploy TF_STACK=eks
.PHONY: tf-eks-deploy

# Usage: $(MAKE) template-tf-infra-destroy TF_STACK=<ec2|eks> TARGET=<optional_module>
#
# Destroy infrastructure provisioning across environments with optional TARGET
template-tf-infra-destroy:
	$(TF) destroy $(if $(strip $(TARGET)),-target=module.$(TARGET),)
.PHONY: template-tf-infra-destroy

## Destroy EC2 infrastructure provisioning across environments
tf-ec2-destroy:
	@$(MAKE) -s template-tf-infra-destroy TF_STACK=ec2
.PHONY: tf-ec2-destroy

## Destroy EKS infrastructure provisioning across environments
tf-eks-destroy:
	@$(MAKE) -s template-tf-infra-destroy TF_STACK=eks
.PHONY: tf-eks-destroy

# ── Terraform Test & Analysis ────────────────────────────────────────────────────────────────────

# Policy-as-Code compliance testing
tf-test-policy:
	sentinel test $$(find . -name "*.sentinel" -type f)
.PHONY: tf-test-policy

# Unit Testing of Terraform Infrastructure Code
tf-test-unit:
	terraform test -test-directory="tests/unit"
.PHONY: tf-test-unit

# Integration Testing of Terraform Infrastructure Code
tf-test-integration:
	terraform test -test-directory="tests/integration"
.PHONY: tf-test-integration

## Perform aggregate testing of Terraform Infrastructure Code
tf-test-infra:
	@$(MAKE) -s tf-test-policy
	@$(MAKE) -s tf-test-unit
.PHONY: tf-test-infra

## Static Analysis and Security Scanning of Terraform Code
tf-lint-infra:
	tflint --recursive
	trivy config $(@D)/ --tf-exclude-downloaded-modules
.PHONY: tf-lint-infra

## Formatting of Terraform and Sentinel Files
tf-format-infra:
	terraform fmt -recursive
	sentinel fmt -check=false $$(find . -type f -name "*.sentinel" -not -path "*/.sentinel/*")
.PHONY: tf-format-infra

# ── Terraform Miscellaneous ──────────────────────────────────────────────────────────────────────

# Usage: make tf-docs-infra <module>
#
## Documentation Generation for Terraform Modules
tf-docs-infra:
	@if [ "$(filter-out $@,$(MAKECMDGOALS))" != "" ]; then \
		terraform-docs markdown --output-file README.md "$(filter-out $@,$(MAKECMDGOALS))"; \
	else \
		terraform-docs markdown --output-file README.md .; \
	fi
.PHONY: tf-docs-infra

# Usage: $(MAKE) template-aws-ssh-connect-<instance>
#
#	NOTE Optoins to connect to an AWS EC2 instance, see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect.html
#
# Template for connecting to an AWS EC2 instance over Secure Shell (SSH)
template-aws-ssh-connect-%:
	ssh aws-$*-$(TF_ENV)
.PHONY: template-aws-ssh-connect-%

## Connect to an AWS EC2 instance for Component Analysis over SSH
aws-ssh-connect-ec2:
	@$(MAKE) template-aws-ssh-connect-ec2
.PHONY: aws-ssh-connect-ec2

# ── Secrets Manager ──────────────────────────────────────────────────────────────────────────────

SECRETS_SOPS_UID ?= sops-tf

# Usage: make secrets-gpg-generate SECRETS_SOPS_UID=<uid>
#
## Generate a new GPG key pair for SOPS
secrets-gpg-generate:
	@gpg --batch --quiet --passphrase '' --quick-generate-key "$(SECRETS_SOPS_UID)" ed25519 cert,sign 0
	@NEW_FPR="$$(gpg --list-keys --with-colons "$(SECRETS_SOPS_UID)" | awk -F: '/^fpr:/ {print $$10; exit}')"
	@gpg --batch --quiet --passphrase '' --quick-add-key "$${NEW_FPR}" cv25519 encrypt 0
.PHONY: secrets-gpg-generate

# Usage: make secrets-gpg-show SECRETS_SOPS_UID=<uid>
#
## Print the GPG key fingerprint for SOPS (.sops.yaml)
secrets-gpg-show:
	@FPR="$$(gpg --list-keys --with-colons "$(SECRETS_SOPS_UID)" | awk -F: '/^fpr:/ {print $$10; exit}')"; \
	if [ -z "$${FPR}" ]; then \
		echo "error: no fingerprint found for UID '$(SECRETS_SOPS_UID)'" >&2; \
		exit 1; \
	fi; \
	echo -e "UID: $(SECRETS_SOPS_UID)\nFingerprint: $${FPR}"
.PHONY: secrets-gpg-show

# Usage: make secrets-gpg-remove SECRETS_SOPS_UID=<uid>
#
## Remove an existing GPG key for SOPS (interactive)
secrets-gpg-remove:
	if ! gpg --list-keys "$(SECRETS_SOPS_UID)" >/dev/null 2>&1; then
		echo "warning: no key found for '$(SECRETS_SOPS_UID)'" >&2
		exit 0
	fi
	echo "info: deleting key for '$(SECRETS_SOPS_UID)'"
	# Delete private key first, then public key
	gpg --yes --delete-secret-keys "$(SECRETS_SOPS_UID)"
	gpg --yes --delete-keys "$(SECRETS_SOPS_UID)"
.PHONY: secrets-gpg-remove

# Usage: make secrets-sops-encrypt <files>
#
## Encrypt file using SOPS
secrets-sops-encrypt:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make secrets-sops-encrypt <files>"; \
		exit 1; \
	fi

	export PATH="$$PATH:$(shell go env GOPATH 2>/dev/null)/bin"
	@for file in $(filter-out $@,$(MAKECMDGOALS)); do \
		if [ -f "$$file" ]; then \
			sops --encrypt --in-place "$$file"; \
		else \
			echo "Skipping (not found): $$file" >&2; \
		fi; \
	done
.PHONY: secrets-sops-encrypt

# Usage: make secrets-sops-decrypt <files>
#
## Decrypt file using SOPS
secrets-sops-decrypt:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make secrets-sops-encrypt <files>"; \
		exit 1; \
	fi

	export PATH="$$PATH:$(shell go env GOPATH 2>/dev/null)/bin"
	@for file in $(filter-out $@,$(MAKECMDGOALS)); do \
		if [ -f "$$file" ]; then \
			sops --decrypt --in-place "$$file"; \
		else \
			echo "Skipping (not found): $$file" >&2; \
		fi; \
	done
.PHONY: secrets-sops-decrypt

# Usage: make secrets-sops-view <file>
#
## View a file encrypted with SOPS
secrets-sops-view:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make secrets-sops-view <file>"; \
		exit 1; \
	fi

	export PATH="$$PATH:$(shell go env GOPATH 2>/dev/null)/bin"
	sops --decrypt "$(filter-out $@,$(MAKECMDGOALS))"
.PHONY: secrets-sops-view

# ── Workflows ────────────────────────────────────────────────────────────────────────────────────

## Workflow of the Setup process
workflow-execute-setup:
	@$(MAKE) -s bootstrap
	@$(MAKE) -s setup
.PHONY: workflow-execute-setup

## Workflow of the Documentation process
workflow-execute-docs:
	@$(MAKE) -s tf-docs-infra modules/aws-ec2
	@$(MAKE) -s tf-docs-infra modules/aws-eks
.PHONY: workflow-execute-docs
