# SPDX-License-Identifier: Apache-2.0

ifneq (,$(wildcard .env))
	include .env
	export
endif

# Define Targets

default: help

help:
	@awk 'BEGIN {printf "Task\n\tA collection of tasks used in current project.\n\n"}'
	@awk 'BEGIN {printf "Usage\n\tmake $(shell tput -Txterm setaf 6)[target]$(shell tput -Txterm sgr0)\n\n"}' $(MAKEFILE_LIST)
	@awk '/^##/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print "$(shell tput -Txterm setaf 6)\t" substr($$1,1,index($$1,":")) "$(shell tput -Txterm sgr0)",c}1{c=0}' $(MAKEFILE_LIST) | column -s: -t
.PHONY: help

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

# Policy-as-Code compliance testing
tf-infra-test-policy:
	sentinel test $$(find . -name "*.sentinel" -type f)
.PHONY: tf-infra-test-policy

# Unit Testing of Terraform Infrastructure Code
tf-infra-test-unit:
	terraform test -test-directory="tests/unit"
.PHONY: tf-infra-test-unit

# Integration Testing of Terraform Infrastructure Code
tf-infra-test-integration:
	terraform test -test-directory="tests/integration"
.PHONY: tf-infra-test-integration

## Perform aggregate testing of Terraform Infrastructure Code
tf-infra-test:
	@$(MAKE) -s tf-infra-test-policy
	@$(MAKE) -s tf-infra-test-unit
.PHONY: tf-infra-test

# Initialize Terraform Configuration for the Target Environment
tf-infra-init:
	cd environments/$(ENV) && terraform init
.PHONY: tf-infra-init

# Validate Terraform Configuration for the Target Environment
tf-infra-validate:
	cd environments/$(ENV) && terraform validate
.PHONY: tf-infra-validate

# Generate Execution Plan for the Target Environment
tf-infra-plan:
	cd environments/$(ENV) && terraform plan -out=tfplan
.PHONY: tf-infra-plan

# Interactive User Confirmation before Terraform Apply
tf-infra-confirm:
	@echo ""
	@read -r -p "Proceed with 'terraform apply' in environment '$(ENV)'? (yes/no): " confirm && \
		if [ "$$confirm" != "yes" ]; then \
			echo "Aborted!"; \
			exit 1; \
		fi
.PHONY: tf-infra-confirm

# Apply Terraform Plan and Clean Artifacts
tf-infra-apply:
	cd environments/$(ENV) && terraform apply "tfplan" && rm -f tfplan
.PHONY: tf-infra-apply

## Provisioning of IaC to the specified environment
tf-infra-deploy:
	@$(MAKE) -s tf-infra-init
	@$(MAKE) -s tf-infra-validate
	# @$(MAKE) -s tf-infra-test
	@$(MAKE) -s tf-infra-plan
	@$(MAKE) -s tf-infra-confirm
	@$(MAKE) -s tf-infra-apply
.PHONY: tf-infra-deploy

## Destroy Infrastructure for Target Environment
tf-infra-destroy:
	cd environments/$(ENV) && terraform destroy
.PHONY: tf-infra-destroy

## Static Analysis and Security Scanning of Terraform Code
lint-tf-config:
	tflint --recursive
	trivy config $(@D)/ --tf-exclude-downloaded-modules
.PHONY: lint-tf-config

## Formatting of Terraform and Sentinel Files
format-tf-config:
	terraform fmt -recursive
	sentinel fmt -check=false $$(find . -type f -name "*.sentinel" -not -path "*/.sentinel/*")
.PHONY: format-tf-config

# Usage: make docs-tf-module <module>
#
## Documentation Generation for Terraform Modules
docs-tf-module:
	@if [ "$(filter-out $@,$(MAKECMDGOALS))" != "" ]; then \
		terraform-docs markdown --output-file README.md "$(filter-out $@,$(MAKECMDGOALS))"; \
	else \
		terraform-docs markdown --output-file README.md .; \
	fi
.PHONY: docs-tf-module

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

## SSH Terminal Session to AWS EC2 Instance
aws-terminal-connect:
	# ssh -i ~/.ssh/aws ec2-user@ec2-35-156-122-248.eu-central-1.compute.amazonaws.com
	ssh aws-$(ENV)
.PHONY: aws-terminal-connect

## Workflow of the Setup process
workflow-setup-execute:
	@$(MAKE) -s bootstrap
	@$(MAKE) -s setup
.PHONY: workflow-setup-execute

## Workflow of the Documentation process
workflow-docs-execute:
	@$(MAKE) -s docs-tf-module .
	@$(MAKE) -s docs-tf-module modules/aws-ec2
.PHONY: workflow-docs-execute
