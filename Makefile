# SPDX-License-Identifier: Apache-2.0

ifneq (,$(wildcard .env))
	include .env
	export
endif

# Define Variables

ENV ?= 

# Define Targets

default: help

help:
	@awk 'BEGIN {printf "TASK\n\tA centralized collection of commands and operations used in this project.\n\n"}'
	@awk 'BEGIN {printf "USAGE\n\tmake $(shell tput -Txterm setaf 6)[target]$(shell tput -Txterm sgr0)\n\n"}' $(MAKEFILE_LIST)
	@awk '/^##/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print "$(shell tput -Txterm setaf 6)\t" substr($$1,1,index($$1,":")) "$(shell tput -Txterm sgr0)",c}1{c=0}' $(MAKEFILE_LIST) | column -s: -t
.PHONY: help

## Setup the Software Development environment
setup:
	cd $(@D)/scripts && chmod +x setup.sh && ./setup.sh
.PHONY: setup

## Setup the Everything as Code (XaC) environment
setup-xac:
	cd $(@D)/scripts && chmod +x setup_xac.sh && ./setup_xac.sh
.PHONY: setup-xac

## Download the module by (re)initialize the Terraform configuration
terraform-init:
	cd environments/$(ENV) && terraform init -upgrade
.PHONY: terraform-init

## Validate Terraform configuration
terraform-validate:
	cd environments/$(ENV) && terraform validate
.PHONY: terraform-validate

## Generate an execution plan based on existing infrastructure and configuration
terraform-plan:
	cd environments/$(ENV) && terraform plan -out=tfplan
.PHONY: terraform-plan

## Execute the planned changes, respecting resource dependencies
terraform-apply:
	cd environments/$(ENV) && terraform apply "tfplan" && rm -f tfplan
.PHONY: terraform-apply

## Destroy the Terraform-managed infrastructure
terraform-destroy:
	cd environments/$(ENV) && terraform destroy -auto-approve
.PHONY: terraform-destroy

# Interactive Terraform prompt to proceed
terraform-confirm:
	@echo ""
	@read -r -p "Proceed with 'terraform' in environment '$(ENV)'? (yes/no): " confirm && \
		if [ "$$confirm" != "yes" ]; then \
			echo "Aborted!"; \
			exit 1; \
		fi
.PHONY: terraform-confirm

## Provisioning of IaC to the specified environment
terraform-deploy:
	$(MAKE) terraform-init ENV=$(ENV)
	$(MAKE) terraform-validate ENV=$(ENV)
	$(MAKE) terraform-plan ENV=$(ENV)
	$(MAKE) terraform-confirm ENV=$(ENV)
	$(MAKE) terraform-apply ENV=$(ENV)
.PHONY: terraform-deploy

## Provisioning of IaC to the development environment
terraform-deploy-dev:
	$(MAKE) terraform-deploy ENV=dev
.PHONY: terraform-deploy-dev

## Provisioning of IaC to the production environment
terraform-deploy-prod:
	$(MAKE) terraform-deploy ENV=prod
.PHONY: terraform-deploy-prod

## Provisioning of IaC to the development environment
terraform-destroy-dev:
	$(MAKE) terraform-destroy ENV=dev
.PHONY: terraform-destroy-dev

## Provisioning of IaC to the production environment
terraform-destroy-prod:
	$(MAKE) terraform-destroy ENV=prod
.PHONY: terraform-destroy-prod

## Generate documentation from Terraform modules
terraform-docs:
	terraform-docs markdown .
.PHONY: terraform-docs

## Perform scan of Infrastructure as Code (IaC) files for misconfigurations
terraform-lint:
	tflint
	trivy config $(@D)/ --tf-exclude-downloaded-modules
.PHONY: terraform-lint

## Perform formatting of Infrastructure as Code (IaC) files
terraform-format:
	terraform fmt $$(find . -name "*.tf" -type f)
	sentinel fmt $$(find . -name "*.sentinel" -type f)
.PHONY: terraform-format

## Perform compliance testing using Policy-as-Code to validate Infrastructure as Code (IaC)
terraform-test-policy:
	sentinel test $$(find . -name "*.sentinel" -type f)
.PHONY: terraform-test-policy

## Perform unit testing for Infrastructure as Code (IaC)
terraform-test-unit:
	terraform test -test-directory="tests/unit"
.PHONY: terraform-test-unit

## Perform integration testing for Infrastructure as Code (IaC)
terraform-test-integration:
	terraform test -test-directory="tests/integration"
.PHONY: terraform-test-integration

## Perform software testing for Infrastructure as Code (IaC)
terraform-test:
	$(MAKE) terraform-test-policy
	$(MAKE) terraform-test-unit
.PHONY: terraform-test

## Create a SSH session to the AWS EC2 Instance in the terminal
aws-terminal:
	ssh aws
.PHONY: aws-terminal
