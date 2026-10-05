# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.10.0"

  # Reusable modules declare minimum versions; deployment roots own upper bounds.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}
