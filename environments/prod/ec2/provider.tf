# SPDX-License-Identifier: Apache-2.0

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = "DevOps"
    }
  }
}
