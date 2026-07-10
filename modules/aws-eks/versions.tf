# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.13, < 7.0"
    }
  }
}
