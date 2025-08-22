# SPDX-License-Identifier: Apache-2.0

ifneq (,$(wildcard .env))
	include .env
	export
endif

# Define Variables
SHELL := bash
.SHELLFLAGS := -euo pipefail -c

TF = terraform -chdir=environments/$(ENV)

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
	@$(MAKE) -s permission
	cd $(@D)/scripts && chmod +x bootstrap.sh && ./bootstrap.sh
.PHONY: bootstrap

## Install and configure all dependencies essential for development
setup:
	@$(MAKE) -s permission
	cd $(@D)/scripts && chmod +x setup.sh && ./setup.sh
.PHONY: setup

## Remove development artifacts and restore the host to its pre-setup state
teardown:
	@$(MAKE) -s permission
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

# Interactive User Confirmation before Terraform Apply
tf-infra-confirm:
	@echo ""
	@read -r -p "Confirm: Proceed with 'terraform apply' in '$(ENV)'$(if $(TARGET), targeting '$(TARGET)',)? [yes $(ENV)|no] " confirm; \
		if [[ "$$confirm" != "yes $(ENV)" ]]; then \
			echo "Aborted."; \
			exit 1; \
		fi
.PHONY: tf-infra-confirm

# IMPORTANT Do NOT pass -target flag, the saved plan already encodes targeting.
#
# Apply Terraform Plan and Clean Artifacts
tf-infra-apply:
	$(TF) apply "terraform.tfplan"
	rm -f environments/$(ENV)/terraform.tfplan
.PHONY: tf-infra-apply

## Deploy Infrastructure for Target Environment
tf-infra-deploy:
	@$(MAKE) -s tf-infra-init
	@$(MAKE) -s tf-infra-validate
	# @$(MAKE) -s tf-test
	@$(MAKE) -s tf-infra-plan
	@$(MAKE) -s tf-infra-confirm
	@$(MAKE) -s tf-infra-apply
.PHONY: tf-infra-deploy

## Deploy Infrastructure for Target Environment provisioning Component Analysis
tf-infra-deploy-component-analysis:
	@$(MAKE) -s tf-infra-deploy TARGET=component_analysis
.PHONY: tf-infra-deploy-component-analysis

# Usage: $(MAKE) tf-infra-destroy TARGET=<module>
#
## Destroy Infrastructure for Target Environment with optional TARGET
tf-infra-destroy:
	$(TF) destroy $(if $(strip $(TARGET)),-target=module.$(TARGET),)
.PHONY: tf-infra-destroy

## Destroy Infrastructure for Target Environment provisioning Component Analysis
tf-infra-destroy-component-analysis:
	@$(MAKE) -s tf-infra-destroy TARGET=component_analysis
.PHONY: tf-infra-destroy-component-analysis

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

# Summary: Use the key fingerprint or email to add this GPG key to your `.sops.yaml` configuration.
#
# List keys with after gteneration:
#   gpg --list-keys --keyid-format LONG
#
## Generate a new GPG key pair for use with SOPS (interactive)
crypto-sops-generate-key:
	gpg --full-generate-key
.PHONY: crypto-sops-generate-key

# Usage: make crypto-sops-encrypt <file>
#
## Encrypt File using SOPS
crypto-sops-encrypt:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make crypto-sops-encrypt <file>"; \
		exit 1; \
	fi
	@export PATH="${PATH}:$(go env GOPATH)/bin"
	sops --encrypt --in-place "$(filter-out $@,$(MAKECMDGOALS))"
.PHONY: crypto-sops-encrypt

# Usage: make crypto-sops-decrypt <file>
#
## Decrypt File using SOPS
crypto-sops-decrypt:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make crypto-sops-encrypt <file>"; \
		exit 1; \
	fi
	@export PATH="${PATH}:$(go env GOPATH)/bin"
	sops --decrypt --in-place "$(filter-out $@,$(MAKECMDGOALS))"
.PHONY: crypto-sops-decrypt

# Usage: $(MAKE) template-aws-connect-ssh-<instance>
#
#	NOTE Optoins to connect to an AWS EC2 instance, see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect.html
#
# Template for connecting to an AWS EC2 instance over Secure Shell (SSH)
template-aws-connect-ssh-%:
	ssh aws-$*-$(ENV)
.PHONY: template-aws-connect-ssh-%

## Connect to an AWS EC2 instance for Component Analysis over SSH
aws-connect-ssh-component-analysis:
	@$(MAKE) template-aws-connect-ssh-component-analysis
.PHONY: aws-connect-ssh-component-analysis

## Workflow of the Setup process
workflow-setup-execute:
	@$(MAKE) -s bootstrap
	@$(MAKE) -s setup
.PHONY: workflow-setup-execute

## Workflow of the Documentation process
workflow-docs-execute:
	@$(MAKE) -s tf-docs-infra .
	@$(MAKE) -s tf-docs-infra modules/aws-ec2
.PHONY: workflow-docs-execute
