# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.79.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.4"
    }
  }
}
