# SPDX-License-Identifier: Apache-2.0

# GNU Make loads GNUmakefile before Makefile. Keep the existing task catalog while
# routing Terraform CLI calls through the repository safety guard by default.
TF_ENV ?= stage
TF_STACK ?= eks
override TF = bash scripts/terraform-command.sh -chdir=environments/$(TF_ENV)/$(TF_STACK)

include Makefile
